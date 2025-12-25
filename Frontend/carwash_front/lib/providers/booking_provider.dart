import 'package:flutter/material.dart';
import '../services/api_service.dart';
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
  // --- Booking State (User Story 2.4 - NEW) ---
  final Set<int> _selectedServiceIds = {};
  double _localTotalPrice = 0.0;
  bool _isSubmittingOrder = false;

  // Getters
  CarwashModel? get profile => _profile;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get profileError => _profileError;
  Set<int> get selectedServiceIds => _selectedServiceIds;
  double get localTotalPrice => _localTotalPrice;
  bool get isSubmittingOrder => _isSubmittingOrder;

  // --- Task: Fetch Carwash Profile (User Story 2.3) ---
  Future<void> fetchCarwashProfile(int id) async {
    _isLoadingProfile = true;
    _profileError = null;
    _selectedServiceIds.clear(); // Reset selection when entering new profile
    _localTotalPrice = 0.0;
    notifyListeners();

    try {
      // GET /api/carwash/profile/{id}/
      final response = await _api.get('${ApiConstants.carwashProfile}$id/');
      _profile = CarwashModel.fromJson(response);
    } catch (e) {
      _profileError = "خطا در دریافت اطلاعات کارواش";
      print("Error fetching profile: $e");
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
    // Avoid negative prices (just in case)
    if (_localTotalPrice < 0) _localTotalPrice = 0;

    notifyListeners();
  }

  // --- Task: Prepare Order / Submit to Backend (User Story 2.4) ---
  // Returns Order ID on success, null on failure
  Future<int?> prepareOrder() async {
    if (_profile == null || _selectedServiceIds.isEmpty) return null;

    _isSubmittingOrder = true;
    notifyListeners();

    try {
      // Body: { "carwash_id": 13, "service_ids": [4, 5] }
      final Map<String, dynamic> body = {
        "carwash_id": _profile!.id,
        "service_ids": _selectedServiceIds.toList(),
      };

      // POST /api/order/prepare/
      final response = await _api.post(
        ApiConstants.prepareOrder,
        body,
        auth: true, // Requires Token
      );

      final draft = OrderDraftResponse.fromJson(response);
      return draft.orderId;
    } catch (e) {
      print("Error preparing order: $e");
      return null; // Handle error in UI
    } finally {
      _isSubmittingOrder = false;
      notifyListeners();
    }
  }
  // NEW: Finalize Order (Sprint 4)
  Future<bool> finalizeOrder(int orderId, String isoTime) async {
    try {
      await _api.post(
        '/api/order/$orderId/finalize/', 
        {"scheduled_time": isoTime}, // Sending proper ISO string
        auth: true
      );
      return true;
    } catch (e) {
      print("Finalize Error: $e");
      return false;
    }
  }

  // [NEW] History State
  List<OrderHistoryModel> _history = [];
  bool _isLoadingHistory = false;

  List<OrderHistoryModel> get history => _history;
  bool get isLoadingHistory => _isLoadingHistory;

  Future<void> fetchOrderHistory() async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.orderHistory, auth: true);
      
      if (response is List) {
        _history = response.map((e) => OrderHistoryModel.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error fetching history: $e");
      // Handle error cleanly
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }
}
