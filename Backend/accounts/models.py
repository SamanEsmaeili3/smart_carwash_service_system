from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.conf import settings
from django.utils import timezone
import random
import string

# --- 1. Custom User Manager ---
class CustomUserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_customer', False)
        extra_fields.setdefault('is_carwash_owner', False)
        
        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')
            
        return self.create_user(email, password, **extra_fields)

# --- 2. Custom User Model ---
class User(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    is_customer = models.BooleanField(default=False)
    is_carwash_owner = models.BooleanField(default=False)

    objects = CustomUserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []

    def __str__(self):
        return self.email

# --- 3. CustomerProfile Model ---
class CustomerProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, primary_key=True)
    full_name = models.CharField(max_length=255)
    phone_number = models.CharField(max_length=20)

    def __str__(self):
        return self.full_name

# --- 4. Vehicle Model ---
class Vehicle(models.Model):
    customer = models.ForeignKey(CustomerProfile, on_delete=models.CASCADE, related_name='vehicles')
    make = models.CharField(max_length=100)
    model = models.CharField(max_length=100)
    license_plate = models.CharField(max_length=20, unique=True)
    color = models.CharField(max_length=50)

    def __str__(self):
        return f"{self.make} {self.model} ({self.license_plate})"

# --- 5. OTP Request Model  ---
class OTPRequest(models.Model):
    email = models.EmailField()
    code = models.CharField(max_length=5)
    created_at = models.DateTimeField(auto_now_add=True)

    def is_valid(self):
        return self.created_at >= timezone.now() - timezone.timedelta(minutes=2)

    def generate_code(self):
        self.code = ''.join(random.choices(string.digits, k=5))
        self.save()