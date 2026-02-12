from django.shortcuts import render
from rest_framework import generics, status, views
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAdminUser
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.mail import send_mail
from django.conf import settings
from django.db import models

from .serializers import (
    CustomerRegistrationSerializer, 
    CustomTokenObtainPairSerializer, 
    PasswordResetRequestSerializer, 
    PasswordResetConfirmSerializer,
    AdminUserListSerializer,
    VehicleSerializer,
    CustomerProfileSerializer
)
from .models import User, OTPRequest
from .models import Vehicle, CustomerProfile
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

# Sprint 5 imports for Admin Stats
from carwash.models import CarwashProfile
from orders.models import Order

# ---------------------------------------------------------
# SECTION 1: REGISTRATION & AUTH
# ---------------------------------------------------------

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
             return Response({'error': 'کد تأیید منقضی شده است. لطفاً کد جدید دریافت کنید.'}, status=status.HTTP_400_BAD_REQUEST)

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


# ---------------------------------------------------------
# SECTION 2: PASSWORD RESET
# ---------------------------------------------------------

# View 1: Request a reset (send code to email)
class RequestPasswordResetView(generics.GenericAPIView):
    serializer_class = PasswordResetRequestSerializer
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data['email']
        
        # 1. Code generation
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

        # 1. Checking the code
        otp_record = OTPRequest.objects.filter(email=email).last()
        
        if not otp_record:
             return Response({'error': 'No reset request found.'}, status=status.HTTP_404_NOT_FOUND)
        
        if otp_record.code != code:
            return Response({'error': 'Invalid code.'}, status=status.HTTP_400_BAD_REQUEST)
            
        if not otp_record.is_valid():
            return Response({'error': 'کد تأیید منقضی شده است. لطفاً کد جدید دریافت کنید.'}, status=status.HTTP_400_BAD_REQUEST)

        # 2. Change password
        try:
            user = User.objects.get(email=email)
            user.set_password(new_password)
            user.is_active = True
            user.save()
            
            otp_record.delete() 

            return Response({'message': 'Password has been reset successfully.'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)


# ---------------------------------------------------------
# SECTION 3: ADMIN DASHBOARD (Sprint 5)
# ---------------------------------------------------------

# [Task-B5.10] User Story 4.1: Admin Dashboard Metrics
class AdminStatsView(views.APIView):
    """
    Returns counts for Total Users, Active Carwashes, and Completed Orders.
    """
    permission_classes = [IsAdminUser]

    def get(self, request):
        # Count only standard customers, not owners or admins
        total_customers = User.objects.filter(
            is_carwash_owner=False, 
            is_staff=False, 
            is_superuser=False
        ).count()
        
        # Active carwashes are those that are APPROVED 
        active_carwashes = CarwashProfile.objects.filter(
            status=CarwashProfile.Status.APPROVED
        ).count()
        
        # Total orders that reached the COMPLETE status 
        completed_orders = Order.objects.filter(
            status='COMPLETE'
        ).count()

        return Response({
            "total_users": total_customers,
            "active_carwashes": active_carwashes,
            "completed_orders": completed_orders
        }, status=status.HTTP_200_OK)
    

class AdminUserListView(generics.ListAPIView):
    serializer_class = AdminUserListSerializer
    permission_classes = [IsAdminUser]

    def get_queryset(self):
        queryset = User.objects.filter(is_customer=True, is_superuser=False, is_staff=False)
        
        search_query = self.request.query_params.get('search', None)
        if search_query:
            queryset = queryset.filter(
                models.Q(email__icontains=search_query) | 
                models.Q(customerprofile__full_name__icontains=search_query) |
                models.Q(customerprofile__phone_number__icontains=search_query)
            )
        return queryset


class AdminUserBanView(views.APIView):
    permission_classes = [IsAdminUser]

    def post(self, request, pk):
        try:
            user = User.objects.get(pk=pk)
            user.is_active = not user.is_active
            user.save()
            
            status_msg = "Activated" if user.is_active else "Banned"
            return Response(
                {"message": f"User {status_msg} successfully", "is_active": user.is_active},
                status=status.HTTP_200_OK
            )
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)


# ---------------------------------------------------------
# SECTION 4: CUSTOMER VEHICLES CRUD
# ---------------------------------------------------------

class CustomerVehicleViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing customer vehicles.
    
    Provides CRUD operations for vehicles belonging to the authenticated customer.
    """
    serializer_class = VehicleSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """
        Filter vehicles to only show those belonging to the current customer.
        """
        try:
            customer = self.request.user.customerprofile
        except (AttributeError, CustomerProfile.DoesNotExist):
            return Vehicle.objects.none()
        return Vehicle.objects.filter(customer=customer)

    def perform_create(self, serializer):
        """
        Create a new vehicle and associate it with the current customer.
        """
        try:
            customer = self.request.user.customerprofile
        except (AttributeError, CustomerProfile.DoesNotExist):
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('فقط مشتریان می‌توانند خودرو اضافه کنند.')

        # Ensure license_plate uniqueness is handled by model validator/migration
        serializer.save(customer=customer)

    def create(self, request, *args, **kwargs):
        """
        Create a new vehicle with error handling.
        """
        serializer = self.get_serializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

        self.perform_create(serializer)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


# ---------------------------------------------------------
# SECTION 5: CUSTOMER PROFILE VIEWS
# ---------------------------------------------------------

class CustomerProfileView(generics.RetrieveUpdateAPIView):
    """
    View for retrieving and updating customer profile.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = CustomerProfileSerializer
    
    def get_object(self):
        try:
            return self.request.user.customerprofile
        except CustomerProfile.DoesNotExist:
            return None


# ---------------------------------------------------------
# SECTION 6: ADDITIONAL AUTH VIEWS (If needed)
# ---------------------------------------------------------

# Note: Add any additional views below as needed