from rest_framework import serializers
from .models import Order, OrderService
from carwash.models import CarwashService

class OrderServiceSerializer(serializers.ModelSerializer):
    service_name = serializers.CharField(source='service.service_name', read_only=True)
    
    class Meta:
        model = OrderService
        fields = ['service_name', 'price_at_time_of_order', 'quantity']

class OrderDraftSerializer(serializers.ModelSerializer):
    # Serializer automatically handles ISO 8601 format (e.g., "2025-12-25T14:00:00Z")
    scheduled_time = serializers.DateTimeField(required=False)

    service_ids = serializers.ListField(
        child=serializers.IntegerField(), write_only=True
    )
    carwash_id = serializers.IntegerField(write_only=True)

    order_services = OrderServiceSerializer(many=True, read_only=True)
    
    class Meta:
        model = Order
        fields = ['id', 'carwash_id', 'service_ids', 'total_price', 'status', 'created_at', 'order_services', 'scheduled_time']
        read_only_fields = ['id', 'total_price', 'status', 'created_at', 'order_services']