from django.urls import path
from .views import CustomerRegistrationView, CustomTokenObtainPairView, VerifyOTPView, RequestPasswordResetView, ResetPasswordView

urlpatterns = [
    path('register/', CustomerRegistrationView.as_view(), name='customer-register'),
    path('auth/verify-otp/', VerifyOTPView.as_view(), name='verify-otp'), 
    path('auth/password-reset/request/', RequestPasswordResetView.as_view(), name='password-reset-request'),
    path('auth/password-reset/confirm/', ResetPasswordView.as_view(), name='password-reset-confirm'),
]