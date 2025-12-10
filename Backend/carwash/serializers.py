from rest_framework import serializers
from .models import CarwashProfile, Driver, CarwashService
from accounts.models import User
from django.db import transaction

# Task-B6: Create CarwashApplicationSerializer
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

        with transaction.atomic():
            if User.objects.filter(email=email).exists():
                raise serializers.ValidationError({"contact_email": "User with this email already exists."})

            user = User.objects.create_user(
                email=email,
                password=password,
                is_carwash_owner=True,
                is_active=False 
            )

            validated_data['status'] = CarwashProfile.Status.PENDING
            carwash_profile = CarwashProfile.objects.create(user=user, **validated_data)
        
            return carwash_profile

# Task-B8: Admin Serializer
class CarwashProfileAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = CarwashProfile
        fields = '__all__'

# Sprint 2 Task-B2.2: Carwash Owner Profile Update
class CarwashProfileUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for Carwash Owners to update their own profile info.
    Also allows changing the password.
    """
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

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if password:
            user = instance.user
            user.set_password(password) 
            user.save()

        return instance

# Sprint 2 Task-B2.4: Service Serializer
class CarwashServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = CarwashService
        fields = ['id', 'service_name', 'description', 'price']

# --- NEW: Sprint 2 Task-B2.8 (Public List for Customers) ---
class CarwashListSerializer(serializers.ModelSerializer):
    """
    Serializer for Customers to see the list of carwashes.
    Shows only public info (No email, no status, no user info).
    """
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