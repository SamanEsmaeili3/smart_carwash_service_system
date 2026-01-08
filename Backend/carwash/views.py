from django.shortcuts import render, get_object_or_404
from rest_framework import generics, status, views, permissions
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from rest_framework.exceptions import NotFound
from django.db.models import Avg, Min, Q 
import math
from django.core.mail import send_mail  
from django.conf import settings        
from accounts.models import User, OTPRequest
from .models import CarwashProfile, CarwashService, Driver
from orders.models import Rating

# Import all serializers
from .serializers import (
    CarwashApplicationSerializer, 
    CarwashProfileAdminSerializer, 
    CarwashProfileUpdateSerializer,
    CarwashServiceSerializer,
    CarwashListSerializer,
    CarwashSearchSerializer,     
    CarwashFullProfileSerializer,
    DriverSerializer,
    DriverSelectionSerializer
)

# ---------------------------------------------------------
# SECTION 1: REGISTRATION & AUTH (Sprint 1)
# ---------------------------------------------------------

# User Story 1.2: Carwash Registration Application (Updated with OTP)
class CarwashApplicationView(generics.CreateAPIView):
    serializer_class = CarwashApplicationSerializer
    permission_classes = [AllowAny] 

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # 1. Creating Profiles and Users (by Serializer)
        carwash_profile = serializer.save()
        user = carwash_profile.user 

        # 2. Generate OTP code for user
        otp = OTPRequest(email=user.email)
        otp.generate_code()

        # 3. Send confirmation email
        try:
            send_mail(
                subject='کد تایید حساب کاربری - کارواش پرو',
                message=f'کد تایید شما: {otp.code}\n\nتوجه: پس از تایید ایمیل، حساب شما باید توسط مدیریت بررسی و تایید شود.',
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

        # 4. Reply to Front (to redirect to OTP page)
        headers = self.get_success_headers(serializer.data)
        return Response(
            {
                "message": "Application submitted. Verification code sent to your email.",
                "email": user.email,
                "role": "carwash_owner" 
            }, 
            status=status.HTTP_201_CREATED, 
            headers=headers
        )

# ---------------------------------------------------------
# SECTION 2: ADMIN PANEL (Sprint 1 & 2)
# ---------------------------------------------------------
    
# User Story 4.1: Admin List View (Flexible)
class AdminCarwashListView(generics.ListAPIView):
    serializer_class = CarwashProfileAdminSerializer
    permission_classes = [IsAdminUser]

    def get_queryset(self):
        # Default to PENDING if no status is provided
        status_param = self.request.query_params.get('status', 'pending').upper()
        
        if status_param == 'APPROVED':
            return CarwashProfile.objects.filter(status=CarwashProfile.Status.APPROVED)
        elif status_param == 'REJECTED':
            return CarwashProfile.objects.filter(status=CarwashProfile.Status.REJECTED)
        else:
            return CarwashProfile.objects.filter(status=CarwashProfile.Status.PENDING)
            
# User Story 4.1: Admin Approves/Rejects/Suspends Carwash
class AdminCarwashApprovalView(views.APIView):
    """
    API view for Admins to Approve or Reject/Suspend a carwash application.
    """
    permission_classes = [IsAdminUser]

    def post(self, request, pk, *args, **kwargs):
        try:
            profile = CarwashProfile.objects.get(pk=pk)
        except CarwashProfile.DoesNotExist:
            return Response({"error": "Profile not found."}, status=status.HTTP_404_NOT_FOUND)

        action = request.data.get('action') # e.g., {"action": "approve"} or {"action": "reject"}
        rejection_reason = request.data.get('rejection_reason', 'دلیلی ذکر نشده است.')

        if action == "approve":
            # Can only approve if not already approved
            if profile.status == CarwashProfile.Status.APPROVED:
                return Response({"error": "Profile is already approved."}, status=status.HTTP_400_BAD_REQUEST)

            user = profile.user
            if not user:
                 return Response({"error": "This application has no linked user. Cannot approve automatically."}, status=status.HTTP_400_BAD_REQUEST)

            # Activate User & Approve Profile
            user.is_active = True
            user.save()
            
            profile.status = CarwashProfile.Status.APPROVED
            profile.save()
            
            # Send Approval Email
            try:
                subject = '🎉 تبریک! کارواش شما تایید شد'
                message = f"""
                سلام {profile.business_name} عزیز،
                
                درخواست ثبت‌نام شما در سامانه «کارواش پرو» بررسی و تایید شد.
                اکنون حساب کاربری شما فعال است.
                
                نام کاربری (ایمیل): {user.email}
                
                می‌توانید وارد پنل خود شده و خدماتتان را تعریف کنید.
                موفق باشید.
                """
                send_mail(
                    subject=subject,
                    message=message,
                    from_email=settings.EMAIL_HOST_USER,
                    recipient_list=[user.email],
                    fail_silently=False,
                )
                print(f"✅ Approval email sent to {user.email}")
            except Exception as e:
                print(f"❌ Failed to send email: {e}")
            
            return Response(
                {
                    "message": f"Carwash {profile.business_name} approved, user activated, and email sent.",
                    "created_user_email": user.email
                }, 
                status=status.HTTP_200_OK
            )

        elif action == "reject":
            # Allow Rejecting/Suspending ANY status (except already rejected)
            if profile.status == CarwashProfile.Status.REJECTED:
                return Response({"error": "Profile is already rejected."}, status=status.HTTP_400_BAD_REQUEST)

            # 1. Update Status to REJECTED (Suspended)
            profile.status = CarwashProfile.Status.REJECTED
            profile.save()
            
            # 2. Send Rejection/Suspension Email
            user = profile.user
            if user and user.email:
                try:
                    subject = '❌ وضعیت حساب کارواش: تعلیق/رد شده'
                    message = f"""
                    سلام {profile.business_name} عزیز،
                    
                    وضعیت حساب کاربری شما به «رد شده/معلق» تغییر یافت.
                    
                    دلیل:
                    {rejection_reason}
                    
                    در صورت رفع مشکل، می‌توانید مجددا درخواست دهید یا با پشتیبانی تماس بگیرید.
                    با احترام، تیم پشتیبانی.
                    """
                    send_mail(
                        subject=subject,
                        message=message,
                        from_email=settings.EMAIL_HOST_USER,
                        recipient_list=[user.email],
                        fail_silently=False,
                    )
                    print(f"✅ Rejection/Suspension email sent to {user.email}")
                except Exception as e:
                    print(f"❌ Failed to send rejection email: {e}")
                        
            return Response({"message": "Rejected/Suspended successfully."}, status=status.HTTP_200_OK)

        else:
            return Response({"error": "Invalid action."}, status=status.HTTP_400_BAD_REQUEST)


# ---------------------------------------------------------
# SECTION 3: CARWASH OWNER PANEL (Sprint 2 & 5)
# ---------------------------------------------------------

# User Story 2.1: Carwash Owner updates profile
class CarwashProfileUpdateView(generics.RetrieveUpdateAPIView):
    serializer_class = CarwashProfileUpdateSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        try:
            return self.request.user.carwashprofile
        except AttributeError:
            raise NotFound("You do not have a carwash profile.")

# User Story 2.4: Manage Services (List & Create)
class CarwashServiceListCreateView(generics.ListCreateAPIView):
    serializer_class = CarwashServiceSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        try:
            return CarwashService.objects.filter(carwash=self.request.user.carwashprofile)
        except AttributeError:
            return CarwashService.objects.none()

    def perform_create(self, serializer):
        try:
            serializer.save(carwash=self.request.user.carwashprofile)
        except AttributeError:
             raise NotFound("You do not have a carwash profile to add services to.")

# User Story 1.5: Edit & Delete Service
class CarwashServiceDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = CarwashServiceSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        try:
            # Ensure owner can only edit/delete their OWN services
            return CarwashService.objects.filter(carwash=self.request.user.carwashprofile)
        except AttributeError:
            return CarwashService.objects.none()

# User Story 5.4 & 5.5: Owner Reputation Management [cite: 42, 54]
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def carwash_reviews_list(request):
    """
    Task-B5.7: Returns a list of text reviews for the owner panel[cite: 54].
    """
    try:
        carwash_profile = request.user.carwashprofile
    except Exception:
        return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)

    # Fetch all ratings linked to orders for this carwash
    reviews = Rating.objects.filter(order__carwash=carwash_profile).order_by('-created_at')
    
    # Import locally to avoid potential circular dependencies
    from orders.serializers import RatingSerializer
    serializer = RatingSerializer(reviews, many=True)
    return Response(serializer.data)

# Task-B5.8: Driver performance stats [cite: 55]
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def carwash_driver_stats(request):
    """
    Returns average ratings and review counts for each driver in this carwash[cite: 55].
    """
    try:
        carwash_profile = request.user.carwashprofile
    except Exception:
        return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)

    drivers = Driver.objects.filter(carwash=carwash_profile)
    
    # Efficiently use denormalized model fields for fast response
    data = [{
        "id": d.id,
        "name": d.full_name,
        "avg_rating": float(d.average_rating), # Uses the pre-calculated field
        "total_reviews": d.review_count         # Uses the pre-calculated field
    } for d in drivers]
    
    return Response(data)

# ---------------------------------------------------------
# SECTION 4: CUSTOMER & SEARCH (Sprint 3)
# ---------------------------------------------------------

# Sprint 2 Task-B2.9 (Simple List)
class CustomerCarwashListView(generics.ListAPIView):
    """
    API view for Customers to see a list of ALL Approved carwashes (Simple view).
    """
    serializer_class = CarwashListSerializer
    permission_classes = [IsAuthenticated] 

    def get_queryset(self):
        return CarwashProfile.objects.filter(status=CarwashProfile.Status.APPROVED)

# Sprint 3 Task-B2.5 & B2.10 (Advanced Search with Filters & Distance)
class CarwashSearchView(generics.ListAPIView):
    """
    Advanced search optimized for speed. Uses denormalized average_rating
    on the profile model instead of recalculating on every request.
    """
    serializer_class = CarwashSearchSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        # 1. Extract query parameters
        search_query = self.request.query_params.get('search')
        lat_param = self.request.query_params.get('lat')
        lon_param = self.request.query_params.get('lon')
        radius_param = self.request.query_params.get('radius')
        min_price = self.request.query_params.get('min_price')
        max_price = self.request.query_params.get('max_price')
        min_rating = self.request.query_params.get('min_rating')

        # 2. Base Filter
        queryset = CarwashProfile.objects.filter(status=CarwashProfile.Status.APPROVED)

        # 3. Apply Search and Price Filters
        if search_query:
            queryset = queryset.filter(
                Q(business_name__icontains=search_query) | 
                Q(services__service_name__icontains=search_query)
            ).distinct()

        if min_price:
            queryset = queryset.filter(services__price__gte=min_price).distinct()
        
        if max_price:
            queryset = queryset.filter(services__price__lte=max_price).distinct()

        # 4. Filter by pre-calculated average_rating (The FAST way)
        if min_rating:
            queryset = queryset.filter(average_rating__gte=min_rating)

        # 5. Distance and Sorting Logic
        carwashes = list(queryset)
        final_results = []

        user_lat = float(lat_param) if lat_param else None
        user_lon = float(lon_param) if lon_param else None
        search_radius = float(radius_param) if radius_param else 15.0

        for carwash in carwashes:
            # Distance Calculation
            if user_lat and user_lon:
                dist = self.calculate_distance(
                    user_lat, user_lon, 
                    float(carwash.latitude), float(carwash.longitude)
                )

                if dist > search_radius:
                    continue
                
                carwash.distance_km = dist
            else:
                carwash.distance_km = 0 

            final_results.append(carwash)

        # 6. Sorting Logic
        if user_lat and user_lon:
            final_results.sort(key=lambda x: x.distance_km)
        else:
            # Sort by highest rating first using the fast model field
            final_results.sort(key=lambda x: x.average_rating, reverse=True)

        return final_results

    def calculate_distance(self, lat1, lon1, lat2, lon2):
        R = 6371 # Earth's radius in kilometers
        dLat = math.radians(lat2 - lat1)
        dLon = math.radians(lon2 - lon1)
        a = (math.sin(dLat / 2) * math.sin(dLat / 2) +
             math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
             math.sin(dLon / 2) * math.sin(dLon / 2))
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return R * c

# Sprint 3 Task-B2.15 (Single Carwash Full Profile)
class CarwashProfileDetailView(generics.RetrieveAPIView):
    """
    GET /api/carwash/profile/<id>/
    Returns FULL details including Service Menu (for Booking).
    """
    serializer_class = CarwashFullProfileSerializer
    permission_classes = [AllowAny] 
    queryset = CarwashProfile.objects.filter(status=CarwashProfile.Status.APPROVED)
    lookup_field = 'pk'

# Custom Permission: Only Carwash Owners can access these views
class IsCarwashOwnerUser(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_carwash_owner)

# API: List all drivers & Add a new driver
class DriverListCreateView(generics.ListCreateAPIView):
    serializer_class = DriverSerializer
    permission_classes = [IsCarwashOwnerUser]

    def get_queryset(self):
        try:
            return Driver.objects.filter(carwash=self.request.user.carwashprofile)
        except Exception:
            return Driver.objects.none()

    def perform_create(self, serializer):
        serializer.save(carwash=self.request.user.carwashprofile)

# API: Retrieve, Update, or Delete a specific driver
class DriverDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = DriverSerializer
    permission_classes = [IsCarwashOwnerUser]

    def get_queryset(self):
        try:
            return Driver.objects.filter(carwash=self.request.user.carwashprofile)
        except Exception:
            return Driver.objects.none()

# ---------------------------------------------------------
# SECTION 5: ADMIN DELETE (Added for Cleanup)
# ---------------------------------------------------------
class AdminCarwashDeleteView(views.APIView):
    """
    Permanently deletes a carwash profile and its associated user.
    """
    permission_classes = [IsAdminUser]

    def delete(self, request, pk, *args, **kwargs):
        try:
            profile = CarwashProfile.objects.get(pk=pk)
            user = profile.user
            
            # Delete the profile first
            profile.delete()
            
            # Then delete the user account to prevent orphans
            if user:
                user.delete()
                
            return Response({"message": "Carwash deleted successfully"}, status=status.HTTP_204_NO_CONTENT)
        except CarwashProfile.DoesNotExist:
            return Response({"error": "Carwash not found"}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)