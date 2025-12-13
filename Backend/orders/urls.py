from django.urls import path
from .views import OrderPrepareView

urlpatterns = [
    # POST /api/order/prepare/
    path('prepare/', OrderPrepareView.as_view(), name='order-prepare'),
]