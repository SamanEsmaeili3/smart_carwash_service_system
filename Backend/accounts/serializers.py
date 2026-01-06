from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import authenticate
from django.utils.translation import gettext_lazy as _
from .models import User, CustomerProfile

class CustomerRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    full_name = serializers.CharField(required=False, allow_blank=True)
    phone_number = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = User
        fields = ['email', 'password', 'full_name', 'phone_number'] 

    def create(self, validated_data):
        # Extract customer profile fields
        full_name = validated_data.pop('full_name', '')
        phone_number = validated_data.pop('phone_number', '')
        
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            is_customer=True  
        )
        CustomerProfile.objects.create(
            user=user,
            full_name=full_name,
            phone_number=phone_number
        )
        return user
    
class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = 'email'
    
    def validate(self, attrs):
        # The parent class expects the username_field name in attrs
        # Since frontend sends 'email' and username_field is 'email', it should work
        # But let's ensure the mapping is correct
        data = super().validate(attrs)
        
        # After parent validate, self.user should be set
        # Ensure user is active
        if hasattr(self, 'user') and self.user and not self.user.is_active:
            raise serializers.ValidationError(
                {'email': _('This account is inactive. Please contact support.')}
            )
        
        return data
    
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)

        token['email'] = user.email
        
        if user.is_staff:
            token['role'] = 'admin'
        elif user.is_carwash_owner:
            token['role'] = 'carwash'
        else:
            token['role'] = 'customer'

        return token
    
class CustomerProfileSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(source='user.email', read_only=True)

    class Meta:
        model = CustomerProfile
        # MATCHES YOUR MODEL EXACTLY:
        fields = ['email', 'full_name', 'phone_number']

class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        if not User.objects.filter(email=value).exists():
            raise serializers.ValidationError("User with this email does not exist.")
        return value

class PasswordResetConfirmSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(max_length=5)
    new_password = serializers.CharField(write_only=True, min_length=8)