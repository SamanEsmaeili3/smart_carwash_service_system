from rest_framework import serializers
from .models import CarwashProfile

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
        ]
        
    def create(self, validated_data):
        validated_data['status'] = CarwashProfile.Status.PENDING
        carwash_profile = CarwashProfile.objects.create(**validated_data)
        return carwash_profile