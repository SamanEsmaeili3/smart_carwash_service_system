from django.urls import path
from .views import OrderPrepareView, finalize_order, carwash_orders_list, manage_order_status, customer_orders_list, get_my_drivers, assign_driver_to_order, get_order_customer_info

urlpatterns = [
    # Customer Routes
    path('prepare/', OrderPrepareView.as_view(), name='order-prepare'),
    path('<int:pk>/finalize/', finalize_order, name='order-finalize'),
    path('history/', customer_orders_list, name='customer-order-history'), # <--- NEW ROUTE

    # Owner Routes
    path('owner/list/', carwash_orders_list, name='owner-order-list'),
    path('owner/<int:pk>/status/', manage_order_status, name='owner-order-status'),
    
    # Driver Assignment Routes
    path('owner/drivers/', get_my_drivers, name='owner-drivers-list'),
    path('owner/<int:order_id>/assign-driver/', assign_driver_to_order, name='owner-assign-driver'),
    
    # Customer Info Route
    path('owner/<int:order_id>/customer-info/', get_order_customer_info, name='owner-order-customer-info'),
]