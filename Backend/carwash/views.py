from django.shortcuts import render
from rest_framework import generics, status, views
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated
from rest_framework.exceptions import NotFound
from accounts.models import User
from .serializers import (
    CarwashApplicationSerializer, 
    CarwashProfileAdminSerializer, 
    CarwashProfileUpdateSerializer,
    CarwashServiceSerializer,
    CarwashListSerializer
)
from .models import CarwashProfile, CarwashService
import math
from .serializers import CarwashSearchSerializer


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

# User Story 1.5: Edit & Delete Service (Retrieve, Update, Destroy)
# This replaces the old DeleteView to support Editing too!
class CarwashServiceDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = CarwashServiceSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        try:
            # Ensure owner can only edit/delete their OWN services
            return CarwashService.objects.filter(carwash=self.request.user.carwashprofile)
        except AttributeError:
            return CarwashService.objects.none()

# --- NEW: Sprint 2 Task-B2.9 (Customer sees Approved Carwashes) ---
class CustomerCarwashListView(generics.ListAPIView):
    """
    API view for Customers to see a list of ALL Approved carwashes.
    """
    serializer_class = CarwashListSerializer
    permission_classes = [IsAuthenticated] 

    def get_queryset(self):
        return CarwashProfile.objects.filter(status=CarwashProfile.Status.APPROVED)
    
import math
from .serializers import CarwashSearchSerializer

# --- NEW: Sprint 3 Task-B2.5 & B2.6 (Search with Distance Calculation) ---
class CarwashSearchView(generics.ListAPIView):
    serializer_class = CarwashSearchSerializer
    permission_classes = [AllowAny] # Open for all users

    def get_queryset(self):
        # 1. Get User's Location from URL (e.g., ?lat=35.7&lon=51.4)
        try:
            user_lat = float(self.request.query_params.get('lat', 0))
            user_lon = float(self.request.query_params.get('lon', 0))
        except ValueError:
            # If no location provided, just return approved carwashes unsorted
            return CarwashProfile.objects.filter(status=CarwashProfile.Status.APPROVED)

        # Get all approved carwashes
        carwashes = list(CarwashProfile.objects.filter(status=CarwashProfile.Status.APPROVED))

        # 2. Calculate Distance for each carwash
        for carwash in carwashes:
            # Note: Your model uses DecimalField, so we convert to float for math
            carwash.distance_km = self.calculate_distance(
                user_lat, user_lon, 
                float(carwash.latitude), float(carwash.longitude)
            )

        # 3. Sort by Distance (Closest first)
        carwashes.sort(key=lambda x: x.distance_km)

        return carwashes

    def calculate_distance(self, lat1, lon1, lat2, lon2):
        # Haversine formula
        R = 6371 # Earth radius in km
        dLat = math.radians(lat2 - lat1)
        dLon = math.radians(lon2 - lon1)
        a = (math.sin(dLat / 2) * math.sin(dLat / 2) +
             math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
             math.sin(dLon / 2) * math.sin(dLon / 2))
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return R * c