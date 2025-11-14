from django.contrib import admin
from .models import CarwashProfile, Driver, CarwashService

admin.site.register(CarwashProfile)
admin.site.register(Driver)
admin.site.register(CarwashService)