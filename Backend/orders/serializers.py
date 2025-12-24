from rest_framework import serializers
from .models import Order, OrderService
from carwash.models import CarwashService
from accounts.serializers import CustomerProfileSerializer 

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

class OrderOwnerSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone_number', read_only=True)
    # If you have vehicle logic working:
    # vehicle_plate = serializers.CharField(source='vehicle.plate_number', read_only=True)
    
    services_list = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = [
            'id', 'customer_name', 'customer_phone', 
            'scheduled_time', 'total_price', 'status', 
            'services_list', 'created_at'
        ]

    def get_services_list(self, obj):
        # Return a list of strings like ["Basic Wash (x1)", "Wax (x1)"]
        return [f"{os.service.service_name}" for os in obj.order_services.all()]
    