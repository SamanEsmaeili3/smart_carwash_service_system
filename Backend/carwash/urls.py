from django.urls import path
from .views import (
    CarwashApplicationView, 
    AdminPendingCarwashListView,
    AdminCarwashApprovalView  
)
urlpatterns = [
    # /api/carwash/apply/
    path('apply/', CarwashApplicationView.as_view(), name='carwash-apply'),
    # /api/carwash/admin/pending/
    path('admin/pending/', AdminPendingCarwashListView.as_view(), name='admin-pending-list'),
    # /api/carwash/admin/manage/1/ (1 is the profile ID)
    path('admin/manage/<int:pk>/', AdminCarwashApprovalView.as_view(), name='admin-manage-carwash'), 
]