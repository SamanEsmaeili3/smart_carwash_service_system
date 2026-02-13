from django.urls import path
from .views import (
    CarwashApplicationView,
    AdminCarwashListView,
    AdminCarwashApprovalView,
    CarwashProfileUpdateView,
    CarwashServiceListCreateView,
    CarwashServiceDetailView,
    CustomerCarwashListView,
    CarwashSearchView,
    CarwashProfileDetailView,
    DriverListCreateView,
    DriverDetailView,
    AdminCarwashDeleteView,
    CarwashReviewsListView,
    FinancialsView
)

urlpatterns = [
    # --- Public ---
    # /api/carwash/apply/ (POST)
    path('apply/', CarwashApplicationView.as_view(), name='carwash-apply'),
    
    # /api/carwash/list/ (GET - For Customers)
    path('list/', CustomerCarwashListView.as_view(), name='carwash-list-public'),

    # --- Admin ---
    # [UPDATED] /api/carwash/admin/list/ (GET) - Handles ?status=pending OR ?status=approved
    path('admin/list/', AdminCarwashListView.as_view(), name='admin-carwash-list'),
    
    # /api/carwash/admin/manage/<pk>/ (POST)
    path('admin/manage/<int:pk>/', AdminCarwashApprovalView.as_view(), name='admin-manage-carwash'),
    path('admin/delete/<int:pk>/', AdminCarwashDeleteView.as_view(), name='admin-delete-carwash'),

    # --- Carwash Owner ---
    # /api/carwash/profile/me/ (PUT)
    path('profile/me/', CarwashProfileUpdateView.as_view(), name='carwash-profile-update'),
    path('financials/', FinancialsView.as_view(), name='carwash-financials'),

    # --- Services (Menu) ---
    # /api/carwash/services/ (GET list, POST create)
    path('services/', CarwashServiceListCreateView.as_view(), name='carwash-service-list-create'),
    
    # /api/carwash/services/<pk>/ (GET, PUT, PATCH, DELETE)
    path('services/<int:pk>/', CarwashServiceDetailView.as_view(), name='carwash-service-detail'),
    
    # Search
    path('search/', CarwashSearchView.as_view(), name='carwash-search'),

    # Sprint 3 Task-B2.15 ---
    # /api/carwash/profile/5/
    path('profile/<int:pk>/', CarwashProfileDetailView.as_view(), name='carwash-profile-detail-public'),

    # --- Driver Management ---
    # /api/carwash/drivers/ (GET list, POST create)
    path('drivers/', DriverListCreateView.as_view(), name='driver-list-create'),
    
    # /api/carwash/drivers/<pk>/ (GET, PUT, DELETE)
    path('drivers/<int:pk>/', DriverDetailView.as_view(), name='driver-detail'),

    path('reviews/', CarwashReviewsListView.as_view(), name='carwash-reviews-list'),
]