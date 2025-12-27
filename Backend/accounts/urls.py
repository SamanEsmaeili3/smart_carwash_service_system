from django.urls import path
from .views import CustomerRegistrationView, CustomTokenObtainPairView, VerifyOTPView 

urlpatterns = [
    path('register/', CustomerRegistrationView.as_view(), name='customer-register'),
    path('auth/verify-otp/', VerifyOTPView.as_view(), name='verify-otp'), 
]