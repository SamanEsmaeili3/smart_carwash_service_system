from django.shortcuts import render
from rest_framework import generics, status, views
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.mail import send_mail
from django.conf import settings

from .serializers import CustomerRegistrationSerializer, CustomTokenObtainPairSerializer
from .models import User, OTPRequest

# User Story 1.1: Customer Signup (Modified for OTP)
class CustomerRegistrationView(generics.CreateAPIView):
    """
    API view for customer registration using OTP verification.
    """
    serializer_class = CustomerRegistrationSerializer
    permission_classes = [AllowAny] 

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        user.is_active = False
        user.save()

        otp = OTPRequest(email=user.email)
        otp.generate_code()

        try:
            send_mail(
                subject='کد تایید حساب کاربری - کارواش پرو',
                message=f'کد تایید شما: {otp.code}',
                from_email=settings.EMAIL_HOST_USER,
                recipient_list=[user.email],
                fail_silently=False,
            )
        except Exception as e:
            user.delete() 
            return Response(
                {"error": "Failed to send email. Please try again."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        return Response(
            {
                "message": "Registration successful. Verification code sent to your email.",
                "email": user.email
            }, 
            status=status.HTTP_201_CREATED
        )

# View to Verify OTP 
class VerifyOTPView(views.APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        code = request.data.get('code')

        if not email or not code:
            return Response({'error': 'Email and Code are required.'}, status=status.HTTP_400_BAD_REQUEST)

        otp_record = OTPRequest.objects.filter(email=email).last()

        if not otp_record:
            return Response({'error': 'No OTP request found for this email.'}, status=status.HTTP_404_NOT_FOUND)

        if otp_record.code != code:
            return Response({'error': 'Invalid code.'}, status=status.HTTP_400_BAD_REQUEST)

        if not otp_record.is_valid():
             return Response({'error': 'Code expired.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(email=email)
            user.is_active = True
            user.save()
            
            otp_record.delete() 
            refresh = RefreshToken.for_user(user)
            
            return Response({
                'message': 'Account verified successfully!',
                'access': str(refresh.access_token),
                'refresh': str(refresh),
            }, status=status.HTTP_200_OK)

        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

# Login View
class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer