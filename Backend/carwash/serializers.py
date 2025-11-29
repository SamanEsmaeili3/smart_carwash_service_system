from rest_framework import serializers
from .models import CarwashProfile, Driver, CarwashService

# Task-B6: Create CarwashApplicationSerializer
class CarwashApplicationSerializer(serializers.ModelSerializer):
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
        ]
        
    def create(self, validated_data):
        validated_data['status'] = CarwashProfile.Status.PENDING
        carwash_profile = CarwashProfile.objects.create(**validated_data)
        return carwash_profile

# Task-B8: Admin Serializer
class CarwashProfileAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = CarwashProfile
        fields = '__all__'

# Sprint 2 Task-B2.2: Carwash Owner Profile Update
class CarwashProfileUpdateSerializer(serializers.ModelSerializer):
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
        ]

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