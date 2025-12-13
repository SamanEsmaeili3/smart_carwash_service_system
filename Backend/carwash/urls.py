from django.urls import path
from .views import (
    CarwashApplicationView, 
    AdminPendingCarwashListView,
    AdminCarwashApprovalView,
    CarwashProfileUpdateView,
    CarwashServiceListCreateView,
    CarwashServiceDetailView, 
    CustomerCarwashListView,
    CarwashSearchView,
    CarwashProfileDetailView
)

urlpatterns = [
    # --- Public ---
    # /api/carwash/apply/ (POST)
    path('apply/', CarwashApplicationView.as_view(), name='carwash-apply'),
    
    # /api/carwash/list/ (GET - For Customers) 
    path('list/', CustomerCarwashListView.as_view(), name='carwash-list-public'),

    # --- Admin ---
    # /api/carwash/admin/pending/ (GET)
    path('admin/pending/', AdminPendingCarwashListView.as_view(), name='admin-pending-list'),
    
    # /api/carwash/admin/manage/<pk>/ (POST)
    path('admin/manage/<int:pk>/', AdminCarwashApprovalView.as_view(), name='admin-manage-carwash'), 
    
    # --- Carwash Owner ---
    # /api/carwash/profile/me/ (PUT)
    path('profile/me/', CarwashProfileUpdateView.as_view(), name='carwash-profile-update'),

    # --- Services (Menu) ---
    # /api/carwash/services/ (GET list, POST create)
    path('services/', CarwashServiceListCreateView.as_view(), name='carwash-service-list-create'),
    
    # /api/carwash/services/<pk>/ (GET, PUT, PATCH, DELETE)
    # Handles Editing and Deleting in one URL
    path('services/<int:pk>/', CarwashServiceDetailView.as_view(), name='carwash-service-detail'),
    
    path('search/', CarwashSearchView.as_view(), name='carwash-search'),

    # Sprint 3 Task-B2.15 ---
    # /api/carwash/profile/5/ 
    path('profile/<int:pk>/', CarwashProfileDetailView.as_view(), name='carwash-profile-detail-public'),
]