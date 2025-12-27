import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../constants/api_constants.dart';
import '../models/carwash_model.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  // Lists for our two tabs
  List<CarwashModel> _pendingList = [];
  List<CarwashModel> _approvedList = []; 
  List<CarwashModel> _rejectedList = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CarwashModel> get pendingList => _pendingList;
  List<CarwashModel> get approvedList => _approvedList;
  List<CarwashModel> get rejectedList => _rejectedList; // [NEW]
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Fetch PENDING Requests ---
  Future<void> fetchPendingCarwashes() async {
    await _fetchList(status: 'pending');
  }

  // --- Fetch APPROVED Carwashes ---
  Future<void> fetchApprovedCarwashes() async {
    await _fetchList(status: 'approved');
  }

  // [NEW] Fetch Rejected
  Future<void> fetchRejectedCarwashes() async => await _fetchList(status: 'rejected');

  // Helper method to fetch lists based on status
  Future<void> _fetchList({required String status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Calls: /api/carwash/admin/list/?status=pending (or approved)
      // Note: We append the query param manually here
      final String endpoint = '${ApiConstants.adminPending}?status=$status';
      
      final response = await _api.get(endpoint, auth: true);
      
      final List<CarwashModel> data = (response as List)
          .map((e) => CarwashModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (status == 'approved') {
        _approvedList = data;
      } else if (status == 'rejected') { // [NEW]
        _rejectedList = data;
      } else {
        _pendingList = data;
      }
    } catch (e) {
      print("Error fetching $status carwashes: $e");
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Approve / Reject Action ---
  Future<bool> manageRequest(int id, String action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.post('${ApiConstants.adminManage}$id/', {
        "action": action,
      }, auth: true);

      // Optimistic Update: Remove from pending list immediately
      _pendingList.removeWhere((item) => item.id == id);
      
      // If approved, we might want to refresh the approved list later, 
      // but strictly speaking, simply removing it from pending is enough for now.
      
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}