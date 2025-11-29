from django.urls import path
from .views import (
    CarwashApplicationView, 
    AdminPendingCarwashListView,
    AdminCarwashApprovalView,
    CarwashProfileUpdateView  
)

urlpatterns = [
    # /api/carwash/apply/
    path('apply/', CarwashApplicationView.as_view(), name='carwash-apply'),
    
    # /api/carwash/admin/pending/
    path('admin/pending/', AdminPendingCarwashListView.as_view(), name='admin-pending-list'),
    
    # /api/carwash/admin/manage/<pk>/
    path('admin/manage/<int:pk>/', AdminCarwashApprovalView.as_view(), name='admin-manage-carwash'), 
    
    # --- NEW: Sprint 2 Task-B2.3 ---
    # /api/carwash/profile/me/
    path('profile/me/', CarwashProfileUpdateView.as_view(), name='carwash-profile-update'),
]