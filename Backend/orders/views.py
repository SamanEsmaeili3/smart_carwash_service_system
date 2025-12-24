from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404

from .models import Order, OrderService
from .serializers import OrderDraftSerializer, OrderOwnerSerializer, OrderHistorySerializer
from carwash.models import CarwashProfile, CarwashService
from accounts.models import CustomerProfile

from django.utils.dateparse import parse_datetime

# Task-B2.18: Prepare Order (Calculate Price & Create Draft)
class OrderPrepareView(generics.CreateAPIView):
    serializer_class = OrderDraftSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        carwash_id = request.data.get('carwash_id')
        service_ids = request.data.get('service_ids', [])

        if not carwash_id or not service_ids:
            return Response(
                {"error": "Please provide 'carwash_id' and a list of 'service_ids'."}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            customer = request.user.customerprofile
        except AttributeError:
             return Response({"error": "Only customers can book orders."}, status=status.HTTP_403_FORBIDDEN)

        carwash = get_object_or_404(CarwashProfile, pk=carwash_id)

        order = Order.objects.create(
            customer=customer,
            carwash=carwash,
            status=Order.Status.PENDING, 
            total_price=0 
        )

        total_price = 0

        for s_id in service_ids:
            try:
                service = CarwashService.objects.get(id=s_id, carwash=carwash)
                
                OrderService.objects.create(
                    order=order,
                    service=service,
                    price_at_time_of_order=service.price,
                    quantity=1 
                )
                
                total_price += service.price
                
            except CarwashService.DoesNotExist:
                continue

        order.total_price = total_price
        order.save()

        serializer = self.get_serializer(order)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
# NEW: Finalize Booking with Professional Date Parsing
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def finalize_order(request, pk):
    try:
        # Ensure user owns the order
        order = Order.objects.get(pk=pk, customer=request.user.customerprofile)
    except Order.DoesNotExist:
        return Response({"error": "Order not found"}, status=status.HTTP_404_NOT_FOUND)

    # 1. Get the raw ISO string (e.g., "2023-12-25T14:30:00")
    time_str = request.data.get('scheduled_time')
    
    if not time_str:
        return Response({"error": "Scheduled time is required."}, status=status.HTTP_400_BAD_REQUEST)

    # 2. Parse into Python datetime object
    scheduled_dt = parse_datetime(time_str)
    
    if scheduled_dt is None:
        return Response({"error": "Invalid date format. Use ISO 8601."}, status=status.HTTP_400_BAD_REQUEST)

    # 3. Update Order
    order.scheduled_time = scheduled_dt
    order.status = Order.Status.SUBMITTED # Move from PENDING to SUBMITTED
    order.save()

    return Response({
        "message": "Order confirmed successfully!",
        "order_id": order.id,
        "status": order.status,
        "scheduled_time": order.scheduled_time
    }, status=status.HTTP_200_OK)

# 1. LIST ORDERS (The "Kitchen" View)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def carwash_orders_list(request):
    try:
        # Get the carwash profile associated with the logged-in user
        carwash_profile = request.user.carwashprofile
    except Exception:
        return Response({"error": "You are not a carwash owner."}, status=403)

    # Fetch orders: Filter by this carwash, and exclude 'PENDING' (drafts)
    # We want SUBMITTED (New), ACCEPTED (Active), etc.
    orders = Order.objects.filter(
        carwash=carwash_profile
    ).exclude(
        status=Order.Status.PENDING
    ).order_by('-scheduled_time') # Show newest appointments first

    serializer = OrderOwnerSerializer(orders, many=True)
    return Response(serializer.data)

# 2. MANAGE ORDER (Accept/Reject/Complete)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def manage_order_status(request, pk):
    try:
        carwash_profile = request.user.carwashprofile
        order = Order.objects.get(pk=pk, carwash=carwash_profile)
    except Order.DoesNotExist:
        return Response({"error": "Order not found."}, status=404)
    except Exception:
        return Response({"error": "Unauthorized"}, status=403)

    new_status = request.data.get('status')
    
    # Simple State Machine Validation
    valid_transitions = {
        'SUBMITTED': ['ACCEPTED', 'CANCELLED'], # New -> Accept or Reject
        'ACCEPTED': ['IN_SERVICE', 'CANCELLED'],
        'IN_SERVICE': ['COMPLETE'],
        'EN_ROUTE': ['IN_SERVICE']
    }

    current_status = order.status
    
    # Check if the transition is allowed (Optional but professional)
    # allowed_next = valid_transitions.get(current_status, [])
    # if new_status not in allowed_next:
    #    return Response({"error": f"Cannot go from {current_status} to {new_status}"}, status=400)

    # Apply Change
    if new_status in Order.Status.values:
        order.status = new_status
        order.save()
        return Response({"message": f"Order updated to {new_status}"})
    else:
        return Response({"error": "Invalid Status"}, status=400)
    
# 3. CUSTOMER ORDER HISTORY (My Bookings)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customer_orders_list(request):
    try:
        # Ensure the user has a customer profile
        customer_profile = request.user.customerprofile
    except Exception:
        return Response({"error": "Only customers have order history."}, status=403)

    # Fetch orders for this customer, sorted by newest first
    orders = Order.objects.filter(
        customer=customer_profile
    ).order_by('-created_at')

    serializer = OrderHistorySerializer(orders, many=True)
    return Response(serializer.data)