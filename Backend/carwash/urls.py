from django.urls import path
from .views import (
    CarwashApplicationView, 
    AdminPendingCarwashListView,
    AdminCarwashApprovalView,
    CarwashProfileUpdateView,
    CarwashServiceListCreateView, # <-- ویو جدید
    CarwashServiceDeleteView      # <-- ویو جدید
)

urlpatterns = [
    # --- Public ---
    # /api/carwash/apply/
    path('apply/', CarwashApplicationView.as_view(), name='carwash-apply'),
    
    # --- Admin ---
    # /api/carwash/admin/pending/
    path('admin/pending/', AdminPendingCarwashListView.as_view(), name='admin-pending-list'),
    
    # /api/carwash/admin/manage/<pk>/
    path('admin/manage/<int:pk>/', AdminCarwashApprovalView.as_view(), name='admin-manage-carwash'), 
    
    # --- Carwash Owner ---
    # /api/carwash/profile/me/
    path('profile/me/', CarwashProfileUpdateView.as_view(), name='carwash-profile-update'),

    # --- NEW: Services (Menu) ---
    # /api/carwash/services/ (GET list, POST create)
    path('services/', CarwashServiceListCreateView.as_view(), name='carwash-service-list-create'),
    
    # /api/carwash/services/<pk>/ (DELETE)
    path('services/<int:pk>/', CarwashServiceDeleteView.as_view(), name='carwash-service-delete'),
]