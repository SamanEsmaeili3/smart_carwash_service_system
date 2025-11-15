from django.urls import path
from .views import CarwashApplicationView

urlpatterns = [
    # /api/carwash/apply/
    path('apply/', CarwashApplicationView.as_view(), name='carwash-apply'),
]