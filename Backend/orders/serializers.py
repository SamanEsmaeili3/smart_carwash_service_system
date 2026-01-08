from rest_framework import serializers
from .models import Order, OrderService, Rating
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
        fields = ['id', 'carwash_id', 'service_ids', 'total_price', 'status', 'created_at', 'order_services', 'scheduled_time', 'details']
        read_only_fields = ['id', 'total_price', 'status', 'created_at', 'order_services']

class OrderOwnerSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone_number', read_only=True)
    customer_email = serializers.CharField(source='customer.user.email', read_only=True)
    customer = CustomerProfileSerializer(read_only=True)
    vehicle_plate = serializers.SerializerMethodField()
    vehicle_info = serializers.SerializerMethodField()
    services_list = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = [
            'id', 'customer_name', 'customer_phone', 'customer_email', 'customer', 'vehicle_plate', 'vehicle_info',
            'scheduled_time', 'total_price', 'status', 
            'services_list', 'created_at', 'details'
        ]
    
    def get_vehicle_plate(self, obj):
        if obj.vehicle:
            return obj.vehicle.license_plate
        return None
    
    def get_vehicle_info(self, obj):
        if obj.vehicle:
            return f"{obj.vehicle.make} {obj.vehicle.model} ({obj.vehicle.color})"
        return None

    def get_services_list(self, obj):
        return [f"{os.service.service_name}" for os in obj.order_services.all()]
    
class OrderHistorySerializer(serializers.ModelSerializer):
    carwash_name = serializers.CharField(source='carwash.business_name', read_only=True)
    carwash_image = serializers.CharField(source='carwash.license_photo_url', read_only=True) 
    services_text = serializers.SerializerMethodField()
    # ADDED: Boolean field to tell the frontend if this order has been rated
    has_rating = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = [
            'id', 
            'carwash_name', 
            'carwash_image',
            'scheduled_time', 
            'total_price', 
            'status', 
            'services_text',
            'has_rating',
            'created_at'
        ]

    def get_services_text(self, obj):
        services = [os.service.service_name for os in obj.order_services.all()]
        return ", ".join(services)

    def get_has_rating(self, obj):
        # Checks for the existence of the OneToOne relation from the Order model
        return hasattr(obj, 'rating')
    
class RatingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Rating
        fields = ['order', 'carwash_rating', 'carwash_comment', 'driver_rating', 'driver_comment']

    def validate_order(self, value):
        # Check if the order is already rated (OneToOneField protection)
        if Rating.objects.filter(order=value).exists():
            raise serializers.ValidationError("این سفارش قبلاً امتیازدهی شده است.")
        
        request = self.context.get('request')
        if value.customer.user != request.user:
            raise serializers.ValidationError("شما اجازه ثبت امتیاز برای این سفارش را ندارید.")
            
        # Ensure status is COMPLETE as per Sprint 5 AC
        if value.status != 'COMPLETE':
             raise serializers.ValidationError("فقط برای سفارش‌های تکمیل شده می‌توانید نظر ثبت کنید.")
             
        return value