from django.shortcuts import render
from rest_framework import generics, status, views
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated
from rest_framework.exceptions import NotFound
from django.db.models import Avg, Min, Q 
import math
from django.core.mail import send_mail  
from django.conf import settings        
from accounts.models import User, OTPRequest
from .models import CarwashProfile, CarwashService
from orders.models import Rating

# Import all serializers
from .serializers import (
    CarwashApplicationSerializer, 
    CarwashProfileAdminSerializer, 
    CarwashProfileUpdateSerializer,
    CarwashServiceSerializer,
    CarwashListSerializer,
    CarwashSearchSerializer,     
    CarwashFullProfileSerializer 
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
            
# User Story 4.1: Admin Approves Carwash
class AdminCarwashApprovalView(views.APIView):
    """
    API view for Admins to Approve or Reject a pending carwash application.
    """
    permission_classes = [IsAdminUser]

    def post(self, request, pk, *args, **kwargs):
        try:
            profile = CarwashProfile.objects.get(pk=pk)
        except CarwashProfile.DoesNotExist:
            return Response({"error": "Profile not found."}, status=status.HTTP_404_NOT_FOUND)

        if profile.status != CarwashProfile.Status.PENDING:
            return Response(
                {"error": f"Profile is already {profile.status}."}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        action = request.data.get('action') # e.g., {"action": "approve"}
        rejection_reason = request.data.get('rejection_reason', 'دلیلی ذکر نشده است.')

        if action == "approve":
            user = profile.user
            
            if not user:
                 return Response(
                    {"error": "This application has no linked user. Cannot approve automatically."}, 
                    status=status.HTTP_400_BAD_REQUEST
                )

            user.is_active = True
            user.save()
            
            profile.status = CarwashProfile.Status.APPROVED
            profile.save()
            
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
                print(f"✅ Email sent to {user.email}")
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
            # 1. Update Status
            profile.status = CarwashProfile.Status.REJECTED
            profile.save()
            
            # 2. Send Rejection Email
            user = profile.user
            if user and user.email:
                try:
                    subject = '❌ درخواست ثبت کارواش رد شد'
                    message = f"""
                    سلام {profile.business_name} عزیز،
                    
                    متاسفانه درخواست ثبت‌نام شما در سامانه «کارواش پرو» تایید نشد.
                    
                    دلیل رد درخواست:
                    {rejection_reason}
                    
                    در صورت رفع مشکل، می‌توانید مجددا درخواست دهید.
                    با احترام، تیم پشتیبانی.
                    """
                    send_mail(
                        subject=subject,
                        message=message,
                        from_email=settings.EMAIL_HOST_USER,
                        recipient_list=[user.email],
                        fail_silently=False,
                    )
                    print(f"✅ Rejection email sent to {user.email}")
                except Exception as e:
                    print(f"❌ Failed to send rejection email: {e}")
                        
            return Response({"message": "Rejected successfully."}, status=status.HTTP_200_OK)

        else:
            return Response({"error": "Invalid action."}, status=status.HTTP_400_BAD_REQUEST)

# ---------------------------------------------------------
# SECTION 3: CARWASH OWNER PANEL (Sprint 2)
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
    Advanced search for carwashes.
    Features:
    1. Search by Business Name or Service Name.
    2. Filter by Price Range (min/max).
    3. Filter by Minimum Average Rating.
    4. Calculate distance and sort by Proximity or Rating.
    """
    serializer_class = CarwashSearchSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        # 1. Extract query parameters from the URL
        search_query = self.request.query_params.get('search')
        lat_param = self.request.query_params.get('lat')
        lon_param = self.request.query_params.get('lon')
        radius_param = self.request.query_params.get('radius') # NEW: Radius in KM
        min_price = self.request.query_params.get('min_price')
        max_price = self.request.query_params.get('max_price')
        min_rating = self.request.query_params.get('min_rating')
        service_name = self.request.query_params.get('service_name') 

        # 2. Start with all approved carwash profiles
        queryset = CarwashProfile.objects.filter(status=CarwashProfile.Status.APPROVED)

        # 2. Apply Filters (Price & Service Name)
        # 3. Apply Combined Search (Business Name OR Service Name)
        if search_query:
            queryset = queryset.filter(
                Q(business_name__icontains=search_query) | 
                # ✅ FIX: Changed 'name' to 'service_name' to match your Model
                Q(services__service_name__icontains=search_query)
            ).distinct()

        # 4. Apply Price Filters
        if min_price:
            queryset = queryset.filter(services__price__gte=min_price).distinct()
        
        if max_price:
            queryset = queryset.filter(services__price__lte=max_price).distinct()

        # 5. Process results for Rating and Distance calculations
        carwashes = list(queryset)
        final_results = []

        user_lat = float(lat_param) if lat_param else None
        user_lon = float(lon_param) if lon_param else None

        # Set default radius to 15.0 KM if not provided, or use user input
        search_radius = float(radius_param) if radius_param else 15.0

        for carwash in carwashes:
            # A) Calculate Real-time Average Rating from Rating table
            avg = Rating.objects.filter(order__carwash=carwash).aggregate(Avg('carwash_rating'))['carwash_rating__avg']
            carwash.rating_val = avg if avg else 0 
            
            # B) Filter based on Min Rating (if provided)
            if min_rating and carwash.rating_val < float(min_rating):
                continue

            # C) Calculate Distance (Haversine Formula)
            if user_lat and user_lon:
                dist = self.calculate_distance(
                    user_lat, user_lon, 
                    float(carwash.latitude), float(carwash.longitude)
                )

                # [NEW] Radius Filter: Skip carwashes that are too far
                if dist > search_radius:
                    continue
                
                carwash.distance_km = dist
            else:
                carwash.distance_km = 0 

            final_results.append(carwash)

        # 6. Sorting Logic
        if user_lat and user_lon:
            # Sort by proximity: Closest first
            final_results.sort(key=lambda x: x.distance_km)
        else:
            # Sort by rating: Highest first
            final_results.sort(key=lambda x: x.rating_val, reverse=True)

        return final_results

    def calculate_distance(self, lat1, lon1, lat2, lon2):
        """
        Calculates the great-circle distance between two points 
        on the Earth's surface using the Haversine formula.
        """
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