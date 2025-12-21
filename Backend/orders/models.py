from django.db import models
from django.conf import settings
from accounts.models import CustomerProfile, Vehicle # Import models from other apps
from carwash.models import CarwashProfile, Driver, CarwashService # Import models from other apps

# --- 8. Order Model (Table 7: Order) ---
class Order(models.Model):
    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        SUBMITTED = 'SUBMITTED', 'Submitted'
        ACCEPTED = 'ACCEPTED', 'Accepted'
        EN_ROUTE = 'EN_ROUTE', 'En Route'
        IN_SERVICE = 'IN_SERVICE', 'In Service'
        COMPLETE = 'COMPLETE', 'Complete'
        CANCELLED = 'CANCELLED', 'Cancelled'

    customer = models.ForeignKey(CustomerProfile, on_delete=models.SET_NULL, null=True, related_name='orders')
    carwash = models.ForeignKey(CarwashProfile, on_delete=models.SET_NULL, null=True, related_name='orders')
    vehicle = models.ForeignKey(Vehicle, on_delete=models.SET_NULL, null=True, related_name='orders')
    driver = models.ForeignKey(Driver, on_delete=models.SET_NULL, null=True, blank=True, related_name='orders')
    
    scheduled_time = models.DateTimeField(null=True, blank=True)

    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    total_price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Order {self.id} for {self.customer.full_name}"

# --- 9. OrderService Model (Table 8: OrderService - Junction Table) ---
class OrderService(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='order_services')
    service = models.ForeignKey(CarwashService, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)
    price_at_time_of_order = models.DecimalField(max_digits=10, decimal_places=2) # Snapshot of the price

    class Meta:
        # Ensures a service is not added twice to the same order
        unique_together = ('order', 'service') 

    def __str__(self):
        return f"{self.service.service_name} (x{self.quantity}) for Order {self.order.id}"

# --- 10. Rating Model (Table 9: Rating) ---
class Rating(models.Model):
    # Use OneToOneField to ensure one rating per order
    order = models.OneToOneField(Order, on_delete=models.CASCADE, primary_key=True, related_name='rating')
    
    carwash_rating = models.IntegerField(choices=[(1, '1'), (2, '2'), (3, '3'), (4, '4'), (5, '5')])
    carwash_comment = models.TextField(blank=True)
    
    driver_rating = models.IntegerField(choices=[(1, '1'), (2, '2'), (3, '3'), (4, '4'), (5, '5')])
    driver_comment = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Rating for Order {self.order.id}"

# --- 11. Payment Model (Table 10: Payment) ---
class Payment(models.Model):
    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        SUCCESSFUL = 'SUCCESSFUL', 'Successful'
        FAILED = 'FAILED', 'Failed'
    
    # Use OneToOneField to ensure one payment per order
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='payment')
    
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    transaction_id = models.CharField(max_length=100, blank=True)
    payment_method = models.CharField(max_length=50, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    paid_at = models.DateTimeField(null=True, blank=True) # Set when payment is successful

    def __str__(self):
        return f"Payment for Order {self.order.id} - {self.status}"