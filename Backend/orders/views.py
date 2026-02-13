from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404

from .models import Order, OrderService, Payment
from .serializers import OrderDraftSerializer, OrderOwnerSerializer, OrderHistorySerializer, RatingSerializer
from carwash.models import CarwashProfile, CarwashService, Driver
from accounts.models import Vehicle
from carwash.serializers import DriverSelectionSerializer 

from django.utils import timezone
from django.utils.dateparse import parse_datetime



# Task-B2.18: Prepare Order (Calculate Price & Create Draft)
class OrderPrepareView(generics.CreateAPIView):
    serializer_class = OrderDraftSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        carwash_id = request.data.get('carwash_id')
        service_ids = request.data.get('service_ids', [])
        details_text = request.data.get('details', '')

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
            total_price=0,
            details=details_text
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
    vehicle_id = request.data.get('vehicle_id')
    
    if not time_str:
        return Response({"error": "زمان رزرو الزامی است."}, status=status.HTTP_400_BAD_REQUEST)

    # 2. Parse into Python datetime object
    scheduled_dt = parse_datetime(time_str)
    
    if scheduled_dt is None:
        return Response({"error": "فرمت تاریخ نامعتبر است. از فرمت ISO استفاده کنید."}, status=status.HTTP_400_BAD_REQUEST)

    # 3. Optionally attach vehicle (ensure the vehicle belongs to this customer)
    if vehicle_id:
        try:
            vehicle = Vehicle.objects.get(pk=vehicle_id, customer=request.user.customerprofile)
            order.vehicle = vehicle
        except Vehicle.DoesNotExist:
            return Response({"error": "خودرو یافت نشد یا به این مشتری تعلق ندارد."}, status=status.HTTP_400_BAD_REQUEST)

    # 4. Update Order
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
    
    # Enforce driver assignment requirement: orders must be assigned to a driver 
    # before status can change (except SUBMITTED -> ACCEPTED/CANCELLED)
    statuses_requiring_driver = ['IN_SERVICE', 'COMPLETE']
    transitions_allowing_no_driver = [
        ('SUBMITTED', 'ACCEPTED'),
        ('SUBMITTED', 'CANCELLED'),
        ('ACCEPTED', 'CANCELLED'),
    ]
    
    # Check if this transition requires a driver
    transition_key = (current_status, new_status)
    requires_driver = new_status in statuses_requiring_driver or \
                      (current_status == 'ACCEPTED' and new_status == 'IN_SERVICE')
    
    if requires_driver and transition_key not in transitions_allowing_no_driver:
        if not order.driver:
            return Response({
                "error": "Order must be assigned to a driver before status can be changed. Please assign a driver first."
            }, status=400)

    # Apply Change
    if new_status in Order.Status.values:
        order.status = new_status
        order.save()

        # When the order reaches COMPLETE ("return car to customer"),
        # the assigned driver becomes available for new incoming orders.
        if new_status == Order.Status.COMPLETE and order.driver:
            if order.driver.status != Driver.Status.AVAILABLE:
                order.driver.status = Driver.Status.AVAILABLE
                order.driver.save(update_fields=["status"])

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

# [NEW] 4. Get Available Drivers for Owner
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_my_drivers(request):
    try:
        carwash_profile = request.user.carwashprofile
    except Exception:
        return Response({"error": "Unauthorized"}, status=403)

    # Get drivers for this carwash (optional: filter by status='AVAILABLE')
    drivers = Driver.objects.filter(carwash=carwash_profile)
    serializer = DriverSelectionSerializer(drivers, many=True)
    return Response(serializer.data)

# [NEW] 5. Assign Driver to Order
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def assign_driver_to_order(request, order_id):
    try:
        carwash_profile = request.user.carwashprofile
        order = Order.objects.get(pk=order_id, carwash=carwash_profile)
    except Order.DoesNotExist:
        return Response({"error": "Order not found"}, status=404)
    except Exception:
        return Response({"error": "Unauthorized"}, status=403)

    driver_id = request.data.get('driver_id')
    if not driver_id:
        return Response({"error": "Driver ID is required"}, status=400)

    try:
        driver = Driver.objects.get(pk=driver_id, carwash=carwash_profile)
    except Driver.DoesNotExist:
        return Response({"error": "Driver not found or belongs to another carwash"}, status=404)

    # Update Order
    order.driver = driver
    order.status = 'EN_ROUTE' # Automatically update status to En Route (or Accepted)
    order.save()

    # Update Driver Status (Optional but recommended)
    driver.status = 'BUSY'
    driver.save()

    return Response({
        "message": f"Driver {driver.full_name} assigned to Order #{order.id}",
        "order_status": order.status
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def initiate_payment(request, order_id):
    try:
        order = Order.objects.get(pk=order_id, customer=request.user.customerprofile)
    except Order.DoesNotExist:
        return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

    if order.status != Order.Status.COMPLETE:
        return Response({"error": "Payment can only be initiated for completed orders."}, status=status.HTTP_400_BAD_REQUEST)

    # Create a new payment record
    payment = Payment.objects.create(
        order=order,
        amount=order.total_price,
        status=Payment.Status.PENDING
    )

    return Response({
        "message": "Payment initiated successfully.",
        "payment_id": payment.id,
        "total_price": order.total_price
    }, status=status.HTTP_201_CREATED)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def verify_payment(request, order_id, payment_id):
    try:
        order = Order.objects.get(pk=order_id, customer=request.user.customerprofile)
        payment = Payment.objects.get(pk=payment_id, order=order)
    except Order.DoesNotExist:
        return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)
    except Payment.DoesNotExist:
        return Response({"error": "Payment record not found."}, status=status.HTTP_404_NOT_FOUND)

    # In a real scenario, you'd verify with a payment gateway here.
    # For this MVP, we'll just simulate a successful payment.

    payment.status = Payment.Status.SUCCESSFUL
    payment.transaction_id = f'txn_{payment.id}_{order.id}' # Mock transaction ID
    payment.paid_at = timezone.now()
    payment.save()

    order.status = Order.Status.PAID
    order.save()

    return Response({
        "message": "Payment successful!",
        "order_status": order.status,
        "payment_status": payment.status
    }, status=status.HTTP_200_OK)
    
# Task-B5.5: Submit Review API
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def submit_review(request):
    serializer = RatingSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        serializer.save()
        return Response({
            "message": "امتیاز شما با موفقیت ثبت شد.",
            "data": serializer.data
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
