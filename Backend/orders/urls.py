from django.urls import path
from .views import OrderPrepareView, finalize_order

urlpatterns = [
    path('prepare/', OrderPrepareView.as_view(), name='order-prepare'),
    path('<int:pk>/finalize/', finalize_order, name='order-finalize'),
]