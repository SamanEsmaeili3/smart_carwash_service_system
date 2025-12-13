from django.shortcuts import render
from rest_framework import generics, status, views
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated
from rest_framework.exceptions import NotFound
from django.db.models import Avg, Min, Q 
import math

from accounts.models import User
from .models import CarwashProfile, CarwashService
from orders.models import Rating

# Import all serializers (Old and New)
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

# User Story 1.2: Carwash Registration Application
class CarwashApplicationView(generics.CreateAPIView):
    serializer_class = CarwashApplicationSerializer
    permission_classes = [AllowAny] 

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(
            {"message": "Thank you for applying, we will review your application."}, 
            status=status.HTTP_201_CREATED, 
            headers=headers
        )

# ---------------------------------------------------------
# SECTION 2: ADMIN PANEL (Sprint 1 & 2)
# ---------------------------------------------------------
    
# User Story 4.1: Admin sees pending carwashes
class AdminPendingCarwashListView(generics.ListAPIView):
    serializer_class = CarwashProfileAdminSerializer
    permission_classes = [IsAdminUser]

    def get_queryset(self):
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
            
            return Response(
                {
                    "message": f"Carwash {profile.business_name} approved and user activated.",
                    "created_user_email": user.email
                }, 
                status=status.HTTP_200_OK
            )

        elif action == "reject":
            profile.status = CarwashProfile.Status.REJECTED
            profile.save()
            return Response(
                {"message": f"Carwash {profile.business_name} rejected."}, 
                status=status.HTTP_200_OK
            )

        else:
            return Response(
                {"error": "Action 'approve' or 'reject' required."}, 
                status=status.HTTP_400_BAD_REQUEST
            )

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
    serializer_class = CarwashSearchSerializer
    permission_classes = [AllowAny] # Open for all users

    def get_queryset(self):
        # 1. Get query parameters from URL
        lat_param = self.request.query_params.get('lat')
        lon_param = self.request.query_params.get('lon')
        min_price = self.request.query_params.get('min_price')
        max_price = self.request.query_params.get('max_price')
        min_rating = self.request.query_params.get('min_rating')

        # Start with all approved carwashes
        queryset = CarwashProfile.objects.filter(status=CarwashProfile.Status.APPROVED)

        # 2. Apply Price Filter (on Services)
        if min_price:
            # Filter carwashes that have at least one service with price >= min_price
            queryset = queryset.filter(services__price__gte=min_price).distinct()
        
        if max_price:
            # Filter carwashes that have at least one service with price <= max_price
            queryset = queryset.filter(services__price__lte=max_price).distinct()

        # Prepare final list for output
        carwashes = list(queryset)
        final_results = []

        user_lat = float(lat_param) if lat_param else None
        user_lon = float(lon_param) if lon_param else None

        for carwash in carwashes:
            # A) Calculate Real Average Rating from Rating table
            avg = Rating.objects.filter(order__carwash=carwash).aggregate(Avg('carwash_rating'))['carwash_rating__avg']
            carwash.rating_val = avg if avg else 0 # Temporary storage for sorting
            
            # Filter based on Rating (if requested)
            if min_rating and carwash.rating_val < float(min_rating):
                continue

            # B) Calculate Distance (Haversine)
            if user_lat and user_lon:
                carwash.distance_km = self.calculate_distance(
                    user_lat, user_lon, 
                    float(carwash.latitude), float(carwash.longitude)
                )
            else:
                carwash.distance_km = 0 

            final_results.append(carwash)

        # 3. Sort Results
        if user_lat and user_lon:
            # If user location is provided, sort by distance (Closest first)
            final_results.sort(key=lambda x: x.distance_km)
        else:
            # If no location, sort by Rating (Highest first)
            final_results.sort(key=lambda x: x.rating_val, reverse=True)

        return final_results

    def calculate_distance(self, lat1, lon1, lat2, lon2):
        R = 6371 # Earth radius in km
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