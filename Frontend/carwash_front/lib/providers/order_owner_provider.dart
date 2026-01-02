import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../constants/api_constants.dart';
import '../models/order_owner_model.dart';

class OrderOwnerProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  // Orders State
  List<OrderOwnerModel> _orders = [];
  bool _isLoadingOrders = false;
  String? _ordersError;

  // Drivers State
  List<DriverModel> _availableDrivers = [];
  bool _isLoadingDrivers = false;
  String? _driversError;

  // Action State
  bool _isUpdatingStatus = false;
  bool _isAssigningDriver = false;
  String? _lastStatusUpdateError;

  // Getters
  List<OrderOwnerModel> get orders => _orders;
  bool get isLoadingOrders => _isLoadingOrders;
  String? get ordersError => _ordersError;
  List<DriverModel> get availableDrivers => _availableDrivers;
  bool get isLoadingDrivers => _isLoadingDrivers;
  String? get driversError => _driversError;
  bool get isUpdatingStatus => _isUpdatingStatus;
  bool get isAssigningDriver => _isAssigningDriver;
  String? get lastStatusUpdateError => _lastStatusUpdateError;

  // Fetch incoming orders (The Kitchen)
  Future<void> fetchOrders() async {
    _isLoadingOrders = true;
    _ordersError = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.ownerOrdersList, auth: true);

      if (response is List) {
        _orders = response.map((e) => OrderOwnerModel.fromJson(e)).toList();
      } else {
        _orders = [];
      }
    } catch (e) {
      _ordersError = ErrorHandler.getErrorMessage(e);
      print("Error fetching orders: $_ordersError");
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  // Change order status (Accept/Reject/etc.)
  Future<bool> updateOrderStatus(int orderId, String status) async {
    _isUpdatingStatus = true;
    _lastStatusUpdateError = null;
    notifyListeners();

    try {
      await _api.post('${ApiConstants.ownerOrderStatus}$orderId/status/', {
        'status': status,
      }, auth: true);

      // Refresh orders list after status update
      await fetchOrders();
      return true;
    } catch (e) {
      _lastStatusUpdateError = ErrorHandler.getErrorMessage(e);
      print("Error updating order status: $_lastStatusUpdateError");
      return false;
    } finally {
      _isUpdatingStatus = false;
      notifyListeners();
    }
  }

  // Get available drivers
  Future<void> fetchAvailableDrivers() async {
    _isLoadingDrivers = true;
    _driversError = null;
    notifyListeners();

    try {
      final response = await _api.get(
        ApiConstants.ownerDriversList,
        auth: true,
      );

      if (response is List) {
        _availableDrivers =
            response.map((e) => DriverModel.fromJson(e)).toList();
      } else {
        _availableDrivers = [];
      }
    } catch (e) {
      _driversError = ErrorHandler.getErrorMessage(e);
      print("Error fetching drivers: $_driversError");
    } finally {
      _isLoadingDrivers = false;
      notifyListeners();
    }
  }

  // Assign driver to order
  Future<bool> assignDriverToOrder(int orderId, int driverId) async {
    _isAssigningDriver = true;
    notifyListeners();

    try {
      await _api.post(
        '${ApiConstants.ownerAssignDriver}$orderId/assign-driver/',
        {'driver_id': driverId},
        auth: true,
      );

      // Refresh orders list after assignment
      await fetchOrders();
      return true;
    } catch (e) {
      print("Error assigning driver: ${ErrorHandler.getErrorMessage(e)}");
      return false;
    } finally {
      _isAssigningDriver = false;
      notifyListeners();
    }
  }

  // Clear errors
  void clearOrdersError() {
    _ordersError = null;
    notifyListeners();
  }

  void clearDriversError() {
    _driversError = null;
    notifyListeners();
  }
}
