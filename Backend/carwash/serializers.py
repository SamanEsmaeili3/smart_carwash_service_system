from rest_framework import serializers
from django.db.models import Min
from accounts.models import User
from .models import CarwashProfile, Driver, CarwashService
from orders.models import Rating, Order

# ---------------------------------------------------------
# SECTION 1: REGISTRATION & AUTH
# ---------------------------------------------------------

# Task-B6: Create CarwashApplicationSerializer (Updated for Sprint 2 - Password included)
class CarwashApplicationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, style={'input_type': 'password'})

    class Meta:
        model = CarwashProfile
        fields = [
            'business_name', 
            'address', 
            'phone_number',
            'contact_email',
            'working_hours',
            'license_image',      
            'ownership_image', 
            'latitude',
            'longitude',
            'password', 
        ]
        
    def create(self, validated_data):
        password = validated_data.pop('password')
        email = validated_data.get('contact_email')

        # Check if user already exists
        if User.objects.filter(email=email).exists():
            raise serializers.ValidationError({"contact_email": "User with this email already exists."})

        # Create inactive user
        user = User.objects.create_user(
            email=email,
            password=password,
            is_carwash_owner=True,
            is_active=False 
        )

        validated_data['status'] = CarwashProfile.Status.PENDING
        carwash_profile = CarwashProfile.objects.create(user=user, **validated_data)
        
        return carwash_profile

# ---------------------------------------------------------
# SECTION 2: ADMIN & OWNER PANELS
# ---------------------------------------------------------

# Task-B8: Admin Serializer
class CarwashProfileAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = CarwashProfile
        fields = '__all__'

# Sprint 2 Task-B2.2: Carwash Owner Profile Update (Address, Hours, Password)
class CarwashProfileUpdateSerializer(serializers.ModelSerializer):
    new_password = serializers.CharField(write_only=True, required=False, style={'input_type': 'password'})
    average_rating = serializers.FloatField(read_only=True)
    review_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = CarwashProfile
        fields = [
            'business_name', 
            'address', 
            'phone_number',
            'working_hours',
            'latitude',
            'longitude',
            'license_image',
            'gallery_photos',
            'new_password', 
            'average_rating',
            'review_count',
        ]
        
        read_only_fields = ['user', 'status', 'average_rating', 'review_count']

    def update(self, instance, validated_data):
        password = validated_data.pop('new_password', None)
        
        # Update standard fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Update password if provided
        if password:
            user = instance.user
            user.set_password(password)
            # Ensure user remains active after password change
            user.is_active = True
            user.save()
            
        return instance

# Sprint 2 Task-B2.4: Service Serializer (Simple)
class CarwashServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = CarwashService
        fields = ['id', 'service_name', 'description', 'price']

# ---------------------------------------------------------
# SECTION 3: CUSTOMER & SEARCH (Sprint 3 & 5 Features)
# ---------------------------------------------------------

# Sprint 2 Task-B2.8 (Simple List for Customers)
class CarwashListSerializer(serializers.ModelSerializer):
    class Meta:
        model = CarwashProfile
        fields = [
            'id',
            'business_name',
            'address',
            'phone_number',
            'working_hours',
            'latitude',
            'longitude',
            'license_image',
            'gallery_photos',
            'average_rating', # Included for visibility
        ]

# Sprint 3 Task-B2.8 (Updated for Sprint 5: Fast Rating & Price)
class CarwashSearchSerializer(serializers.ModelSerializer):
    min_price = serializers.SerializerMethodField()
    distance = serializers.SerializerMethodField()
    rating = serializers.SerializerMethodField() # FAST: Now uses model field

    class Meta:
        model = CarwashProfile
        fields = [
            'id', 
            'business_name', 
            'address', 
            'latitude', 
            'longitude', 
            'license_image', 
            'min_price', 
            'distance', 
            'rating'
        ]

    def get_min_price(self, obj):
        # Find the cheapest service price
        minimum = obj.services.aggregate(Min('price'))['price__min']
        return minimum if minimum else 0

    def get_distance(self, obj):
        # Calculated in Views (Haversine logic)
        if hasattr(obj, 'distance_km'):
            return round(obj.distance_km, 1) 
        return None

    def get_rating(self, obj):
        # Optimized: Returns pre-calculated average from model 
        return float(round(obj.average_rating, 1)) if obj.average_rating else 0.0

# Sprint 3 Task-B2.16 (Full Profile with Services List)
class CarwashFullProfileSerializer(serializers.ModelSerializer):
    """
    Shows EVERYTHING about a carwash:
    - Basic Info
    - List of Services (Crucial for Booking)
    - Rating (Optimized)
    """
    services = CarwashServiceSerializer(many=True, read_only=True) 
    rating = serializers.SerializerMethodField()

    class Meta:
        model = CarwashProfile
        fields = [
            'id',
            'business_name',
            'address',
            'phone_number',
            'working_hours',
            'latitude',
            'longitude',
            'license_image',
            'gallery_photos',
            'services', 
            'rating',
            'review_count',
        ]

    def get_rating(self, obj):
        # Optimized: Returns pre-calculated average from model 
        return float(round(obj.average_rating, 1)) if obj.average_rating else 0.0
    
# Simple Driver Serializer for Selection (Updated for Rating Badge)
class DriverSelectionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Driver
        fields = ['id', 'full_name', 'phone_number', 'status', 'average_rating']

# ---------------------------------------------------------
# SECTION 4: DRIVER MANAGEMENT (Sprint 4 & 5)
# ---------------------------------------------------------

class DriverSerializer(serializers.ModelSerializer):
    average_rating = serializers.FloatField(read_only=True)
    review_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Driver
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'status', 'average_rating', 'review_count', 'carwash']


# Sprint 5 Serializer for Reviews 
class CarwashReviewSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(source='order.id', read_only=True)
    customer_name = serializers.CharField(source='order.customer.full_name', read_only=True)
    service_names = serializers.SerializerMethodField()
    date = serializers.DateTimeField(source='created_at', format="%Y-%m-%d")

    class Meta:
        model = Rating
        fields = ['id', 'customer_name', 'service_names', 'carwash_rating', 'carwash_comment', 'driver_rating', 'date']

    def get_service_names(self, obj):
        try:
            return [os.service.service_name for os in obj.order.order_services.all()]
        except:
            return []

# ---------------------------------------------------------
# SECTION 5: FINANCIALS (Sprint 5)
# ---------------------------------------------------------

# Task-B5.9: Serializer for a single transaction
class FinancialTransactionSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)
    completed_at = serializers.DateTimeField(source='updated_at', format="%Y-%m-%d %H:%M", read_only=True)
    
    class Meta:
        model = Order
        fields = ['id', 'customer_name', 'total_price', 'completed_at']

# Task-B5.9: Serializer for the financial summary
class FinancialSummarySerializer(serializers.Serializer):
    total_earnings = serializers.DecimalField(max_digits=12, decimal_places=2)
    transactions = FinancialTransactionSerializer(many=True, read_only=True)