from django.shortcuts import render
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from .serializers import CustomerRegistrationSerializer

# User Story 1.1: Customer Signup
class CustomerRegistrationView(generics.CreateAPIView):
    """
    API view for customer registration.
    """
    serializer_class = CustomerRegistrationSerializer
    permission_classes = [AllowAny] 

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        headers = self.get_success_headers(serializer.data)
                
        return Response(
            {"message": "Customer registered successfully."}, 
            status=status.HTTP_201_CREATED, 
            headers=headers
        )