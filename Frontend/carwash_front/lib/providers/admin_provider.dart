import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../constants/api_constants.dart';
import '../models/carwash_model.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  // Lists for our tabs
  List<CarwashModel> _pendingList = [];
  List<CarwashModel> _approvedList = []; 
  List<CarwashModel> _rejectedList = [];
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CarwashModel> get pendingList => _pendingList;
  List<CarwashModel> get approvedList => _approvedList;
  List<CarwashModel> get rejectedList => _rejectedList;
  
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

  // --- Fetch REJECTED Carwashes ---
  Future<void> fetchRejectedCarwashes() async {
    await _fetchList(status: 'rejected');
  }

  // Helper method to fetch lists based on status
  Future<void> _fetchList({required String status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Calls: /api/carwash/admin/list/?status=pending
      final String endpoint = '${ApiConstants.adminPending}?status=$status';
      
      final response = await _api.get(endpoint, auth: true);
      
      final List<CarwashModel> data = (response as List)
          .map((e) => CarwashModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (status == 'approved') {
        _approvedList = data;
      } else if (status == 'rejected') {
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

  // Handle Approve / Reject (Suspend)
  Future<bool> manageRequest(int id, String action, {String? reason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Prepare Payload
      final Map<String, dynamic> body = {
        "action": action,
      };
      
      // If there is a reason (for rejection/suspension), add it
      if (reason != null && reason.isNotEmpty) {
        body['rejection_reason'] = reason;
      }

      await _api.post('${ApiConstants.adminManage}$id/', body, auth: true);

      // Optimistic Update: Remove from lists locally so UI updates instantly
      // If we approved it, move from pending/rejected to approved (or just refresh)
      // For simplicity, we just remove it from current views and let the user refresh to see it in the new tab
      _pendingList.removeWhere((item) => item.id == id);
      _approvedList.removeWhere((item) => item.id == id); 
      // If suspending (rejecting), it technically goes to rejected list
      
      // Ideally, trigger a fetch for the specific tab, but removing is visually faster
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // [NEW] DELETE CARWASH (Permanently)
  Future<bool> deleteCarwash(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Assuming your API endpoint is /api/carwash/admin/delete/{id}/
      // Ensure ApiConstants.adminDelete is defined in your constants file!
      await _api.delete('${ApiConstants.adminDelete}$id/', auth: true);

      // Remove from ALL lists locally
      _pendingList.removeWhere((item) => item.id == id);
      _approvedList.removeWhere((item) => item.id == id);
      _rejectedList.removeWhere((item) => item.id == id);

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