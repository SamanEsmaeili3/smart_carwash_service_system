from django.shortcuts import render
from rest_framework import generics, status, views
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAdminUser
from accounts.models import User
from .serializers import CarwashApplicationSerializer, CarwashProfileAdminSerializer
from .models import CarwashProfile

# User Story 1.2: Carwash Registration Application
# Task-B7: Create a public API View
class CarwashApplicationView(generics.CreateAPIView):
    """
    API view for a new Carwash Owner to submit their application.
    This is public (no auth required).
    """
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
# Task-B8: Create Admin-only API View
class AdminPendingCarwashListView(generics.ListAPIView):
    """
    API view for Admins to list all carwash applications
    with 'Pending' status.
    """
    serializer_class = CarwashProfileAdminSerializer
    permission_classes = [IsAdminUser]

    def get_queryset(self):
        return CarwashProfile.objects.filter(status=CarwashProfile.Status.PENDING)
    
# User Story 4.1: Admin Approves Carwash
# Task-B9 & B10: Approval/Rejection Logic
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
            
            if User.objects.filter(email=profile.contact_email).exists():
                return Response(
                    {"error": "A user with this email already exists."}, 
                    status=status.HTTP_400_BAD_REQUEST
                )

            password = User.objects.make_random_password()
            new_user = User.objects.create_user(
                email=profile.contact_email,
                password=password,
                is_carwash_owner=True 
            )
            
            profile.user = new_user
            profile.status = CarwashProfile.Status.APPROVED
            profile.save()
            
            return Response(
                {"message": f"Carwash {profile.business_name} approved.", "created_user_email": new_user.email}, 
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