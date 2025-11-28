from django.db import models
from django.conf import settings

# --- 5. CarwashProfile Model (Table 4: CarwashProfile) ---
class CarwashProfile(models.Model):
    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        APPROVED = 'APPROVED', 'Approved'
        REJECTED = 'REJECTED', 'Rejected'

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    business_name = models.CharField(max_length=255)
    address = models.CharField(max_length=255)
    
    # --- FIX: Increased digits to handle high-precision GPS coordinates ---
    latitude = models.DecimalField(max_digits=20, decimal_places=15)
    longitude = models.DecimalField(max_digits=20, decimal_places=15)
    # ----------------------------------------------------------------------
    
    phone_number = models.CharField(max_length=20)
    working_hours = models.JSONField(default=dict) 
    license_photo_url = models.URLField(max_length=1024, blank=True)
    gallery_photos = models.JSONField(default=list)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    contact_email = models.EmailField(
        max_length=255, 
        unique=True, 
        help_text="The email for the carwash owner, will be used to create their user account upon approval."
    )

    def __str__(self):
        return self.business_name

# --- 6. Driver Model (Table 5: Driver) ---
class Driver(models.Model):
    class ValidationStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        APPROVED = 'APPROVED', 'Approved'
        REJECTED = 'REJECTED', 'Rejected'

    carwash = models.ForeignKey(CarwashProfile, on_delete=models.CASCADE, related_name='drivers')
    full_name = models.CharField(max_length=255)
    license_scan_url = models.URLField(max_length=1024, blank=True) 
    validation_status = models.CharField(max_length=10, choices=ValidationStatus.choices, default=ValidationStatus.PENDING)

    def __str__(self):
        return f"{self.full_name} ({self.carwash.business_name})"

# --- 7. CarwashService Model (Table 6: CarwashService) ---
class CarwashService(models.Model):
    carwash = models.ForeignKey(CarwashProfile, on_delete=models.CASCADE, related_name='services')
    service_name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return f"{self.service_name} - {self.carwash.business_name}"