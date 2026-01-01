from django.shortcuts import render
from rest_framework import generics, status, views
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.mail import send_mail
from django.conf import settings
from .serializers import CustomerRegistrationSerializer, CustomTokenObtainPairSerializer, PasswordResetRequestSerializer, PasswordResetConfirmSerializer
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
                        
            if user.is_customer:
                user.is_active = True
                user.save()
                otp_record.delete()
                refresh = RefreshToken.for_user(user)
                return Response({
                    'message': 'Account verified successfully!',
                    'role': 'customer',
                    'access': str(refresh.access_token),
                    'refresh': str(refresh),
                }, status=status.HTTP_200_OK)

            elif user.is_carwash_owner:
                otp_record.delete()
                
                return Response({
                    'message': 'Email verified. Please wait for Admin approval.',
                    'role': 'carwash_owner'
                }, status=status.HTTP_200_OK)
            
            else:
                 otp_record.delete()
                 return Response({'message': 'Verified.'}, status=status.HTTP_200_OK)

        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

# Login View
class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

# View 1: Request a reset (send code to email)
class RequestPasswordResetView(generics.GenericAPIView):
    serializer_class = PasswordResetRequestSerializer
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data['email']
        
        # 1. Code generation (we use the same logic as before)
        otp = OTPRequest(email=email)
        otp.generate_code()

        # 2. Send Email
        try:
            send_mail(
                subject='بازیابی رمز عبور - کارواش پرو',
                message=f'کد بازیابی شما: {otp.code}\nاین کد تا ۲ دقیقه اعتبار دارد.',
                from_email=settings.EMAIL_HOST_USER,
                recipient_list=[email],
                fail_silently=False,
            )
        except Exception as e:
            return Response({"error": "Failed to send email."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return Response({"message": "Password reset code sent to your email."}, status=status.HTTP_200_OK)


# View 2: Register a new password (confirm code + change password)
class ResetPasswordView(generics.GenericAPIView):
    serializer_class = PasswordResetConfirmSerializer
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']
        code = serializer.validated_data['code']
        new_password = serializer.validated_data['new_password']

        # 1. Checking the code (just like registering)
        otp_record = OTPRequest.objects.filter(email=email).last()
        
        if not otp_record:
             return Response({'error': 'No reset request found.'}, status=status.HTTP_404_NOT_FOUND)
        
        if otp_record.code != code:
            return Response({'error': 'Invalid code.'}, status=status.HTTP_400_BAD_REQUEST)
            
        if not otp_record.is_valid():
            return Response({'error': 'Code expired.'}, status=status.HTTP_400_BAD_REQUEST)

        # 2. Change password
        try:
            user = User.objects.get(email=email)
            user.set_password(new_password)
            # Ensure user is active after password reset so they can login immediately
            user.is_active = True
            user.save()
            
            otp_record.delete() # Clear invalid code

            return Response({'message': 'Password has been reset successfully.'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)