from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.conf import settings

# --- 1. Custom User Manager ---
# This manager handles creating users and superusers
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
        extra_fields.setdefault('is_customer', False) # Superuser is not a customer
        extra_fields.setdefault('is_carwash_owner', False) # Superuser is not a carwash owner
        
        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')
            
        return self.create_user(email, password, **extra_fields)

# --- 2. Custom User Model (Table 1: User) ---
# This is our main authentication table
class User(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False) # The "Admin" flag

    # Our custom role flags
    is_customer = models.BooleanField(default=False)
    is_carwash_owner = models.BooleanField(default=False)

    # Set the manager
    objects = CustomUserManager()

    # Set the email field as the unique identifier
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = [] # No other fields required for createsuperuser

    def __str__(self):
        return self.email

# --- 3. CustomerProfile Model (Table 2: CustomerProfile) ---
class CustomerProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, primary_key=True)
    full_name = models.CharField(max_length=255)
    phone_number = models.CharField(max_length=20)

    def __str__(self):
        return self.full_name

# --- 4. Vehicle Model (Table 3: Vehicle) ---
class Vehicle(models.Model):
    customer = models.ForeignKey(CustomerProfile, on_delete=models.CASCADE, related_name='vehicles')
    make = models.CharField(max_length=100)
    model = models.CharField(max_length=100)
    license_plate = models.CharField(max_length=20, unique=True)
    color = models.CharField(max_length=50)

    def __str__(self):
        return f"{self.make} {self.model} ({self.license_plate})"