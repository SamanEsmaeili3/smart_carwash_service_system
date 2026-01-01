import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../constants/api_constants.dart';
import '../models/carwash_model.dart';
import '../models/order_draft_model.dart';
import '../models/order_history_model.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  // Profile State
  CarwashModel? _profile;
  bool _isLoadingProfile = false;
  String? _profileError;

  // Selection State (User Story 2.4)
  final Set<int> _selectedServiceIds = {};
  double _localTotalPrice = 0.0;
  bool _isSubmittingOrder = false;

  // History State
  List<OrderHistoryModel> _history = [];
  bool _isLoadingHistory = false;

  // Getters
  CarwashModel? get profile => _profile;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get profileError => _profileError;
  Set<int> get selectedServiceIds => _selectedServiceIds;
  double get localTotalPrice => _localTotalPrice;
  bool get isSubmittingOrder => _isSubmittingOrder;
  List<OrderHistoryModel> get history => _history;
  bool get isLoadingHistory => _isLoadingHistory;

  // --- Task: Fetch Carwash Profile (User Story 2.3) ---
  Future<void> fetchCarwashProfile(int id) async {
    _isLoadingProfile = true;
    _profileError = null;
    _selectedServiceIds.clear();
    _localTotalPrice = 0.0;
    notifyListeners();

    try {
      final response = await _api.get('${ApiConstants.carwashProfile}$id/');
      _profile = CarwashModel.fromJson(response);
    } catch (e) {
      _profileError = ErrorHandler.getErrorMessage(e);
      print("Error fetching profile: $_profileError");
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  // --- Task: Toggle Service Selection (User Story 2.4) ---
  void toggleService(int serviceId, double price) {
    if (_selectedServiceIds.contains(serviceId)) {
      _selectedServiceIds.remove(serviceId);
      _localTotalPrice -= price;
    } else {
      _selectedServiceIds.add(serviceId);
      _localTotalPrice += price;
    }

    if (_localTotalPrice < 0) _localTotalPrice = 0;
    notifyListeners();
  }

  // --- Task: Prepare Order / Submit to Backend (User Story 2.4) ---
  Future<int?> prepareOrder() async {
    if (_profile == null || _selectedServiceIds.isEmpty) return null;

    _isSubmittingOrder = true;
    notifyListeners();

    try {
      final Map<String, dynamic> body = {
        "carwash_id": _profile!.id,
        "service_ids": _selectedServiceIds.toList(),
      };

      final response = await _api.post(
        ApiConstants.prepareOrder,
        body,
        auth: true,
      );

      final draft = OrderDraftResponse.fromJson(response);
      return draft.orderId;
    } catch (e) {
      print("Error preparing order: ${ErrorHandler.getErrorMessage(e)}");
      rethrow; // پرتاب خطا برای مدیریت در UI
    } finally {
      _isSubmittingOrder = false;
      notifyListeners();
    }
  }

  // NEW: Finalize Order (Sprint 4)
  Future<bool> finalizeOrder(int orderId, String isoTime) async {
    _isSubmittingOrder = true;
    notifyListeners();

    try {
      await _api.post('/api/order/$orderId/finalize/', {
        "scheduled_time": isoTime,
      }, auth: true);
      return true;
    } catch (e) {
      print("Finalize Error: ${ErrorHandler.getErrorMessage(e)}");
      rethrow;
    } finally {
      _isSubmittingOrder = false;
      notifyListeners();
    }
  }

  // Fetch Order History
  Future<void> fetchOrderHistory() async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.orderHistory, auth: true);

      if (response is List) {
        _history = response.map((e) => OrderHistoryModel.fromJson(e)).toList();
      } else {
        _history = [];
      }
    } catch (e) {
      print("Error fetching history: ${ErrorHandler.getErrorMessage(e)}");
      rethrow;
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  // Clear selection
  void clearSelection() {
    _selectedServiceIds.clear();
    _localTotalPrice = 0.0;
    notifyListeners();
  }

  // Clear profile error
  void clearProfileError() {
    _profileError = null;
    notifyListeners();
  }
}
