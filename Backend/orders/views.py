from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404

from .models import Order, OrderService
from .serializers import OrderDraftSerializer
from carwash.models import CarwashProfile, CarwashService
from accounts.models import CustomerProfile

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