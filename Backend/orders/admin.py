from django.contrib import admin
from .models import Order, OrderService, Rating, Payment

admin.site.register(Order)
admin.site.register(OrderService)
admin.site.register(Rating)
admin.site.register(Payment)