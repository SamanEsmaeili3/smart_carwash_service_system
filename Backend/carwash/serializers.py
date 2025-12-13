from rest_framework import serializers
from django.db.models import Min, Avg
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
            'license_photo_url', 
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

    class Meta:
        model = CarwashProfile
        fields = [
            'business_name', 
            'address', 
            'phone_number',
            'working_hours',
            'latitude',
            'longitude',
            'license_photo_url',
            'gallery_photos',
            'new_password', 
        ]

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
            user.save()
            
        return instance

# Sprint 2 Task-B2.4: Service Serializer (Simple)
class CarwashServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = CarwashService
        fields = ['id', 'service_name', 'description', 'price']

# ---------------------------------------------------------
# SECTION 3: CUSTOMER & SEARCH (Sprint 3 Features)
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
            'license_photo_url',
            'gallery_photos',
        ]

# Sprint 3 Task-B2.8 (Search with REAL Rating & Price)
class CarwashSearchSerializer(serializers.ModelSerializer):
    min_price = serializers.SerializerMethodField()
    distance = serializers.SerializerMethodField()
    rating = serializers.SerializerMethodField() # Calculated from DB

    class Meta:
        model = CarwashProfile
        fields = [
            'id', 
            'business_name', 
            'address', 
            'latitude', 
            'longitude', 
            'license_photo_url', 
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
        # Calculate Average Rating from 'Rating' table
        avg_rating = Rating.objects.filter(order__carwash=obj).aggregate(Avg('carwash_rating'))['carwash_rating__avg']
        if avg_rating:
            return round(avg_rating, 1)
        return 0 

# Sprint 3 Task-B2.16 (Full Profile with Services List)
class CarwashFullProfileSerializer(serializers.ModelSerializer):
    """
    Shows EVERYTHING about a carwash:
    - Basic Info
    - List of Services (Crucial for Booking)
    - Rating
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
            'license_photo_url',
            'gallery_photos',
            'services', # <-- Shows the menu
            'rating',
        ]

    def get_rating(self, obj):
        avg_rating = Rating.objects.filter(order__carwash=obj).aggregate(Avg('carwash_rating'))['carwash_rating__avg']
        return round(avg_rating, 1) if avg_rating else 0