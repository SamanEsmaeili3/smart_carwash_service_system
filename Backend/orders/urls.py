from django.urls import path
from .views import OrderPrepareView, finalize_order, carwash_orders_list, manage_order_status

urlpatterns = [
    path('prepare/', OrderPrepareView.as_view(), name='order-prepare'),
    path('<int:pk>/finalize/', finalize_order, name='order-finalize'),
    path('owner/list/', carwash_orders_list, name='owner-order-list'),
    path('owner/<int:pk>/status/', manage_order_status, name='owner-order-status'),
]