from django.shortcuts import render
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from .serializers import CarwashApplicationSerializer

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