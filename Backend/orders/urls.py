from django.urls import path
from .views import OrderPrepareView, finalize_order, carwash_orders_list, manage_order_status, customer_orders_list

urlpatterns = [
    # Customer Routes
    path('prepare/', OrderPrepareView.as_view(), name='order-prepare'),
    path('<int:pk>/finalize/', finalize_order, name='order-finalize'),
    path('history/', customer_orders_list, name='customer-order-history'), # <--- NEW ROUTE

    # Owner Routes
    path('owner/list/', carwash_orders_list, name='owner-order-list'),
    path('owner/<int:pk>/status/', manage_order_status, name='owner-order-status'),
]