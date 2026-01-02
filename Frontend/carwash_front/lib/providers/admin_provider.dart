import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../constants/api_constants.dart';
import '../models/carwash_model.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<CarwashModel> _pendingList = [];
  List<CarwashModel> _approvedList = []; 
  List<CarwashModel> _rejectedList = [];
  
  bool _isLoading = false;
  String? _error;

  List<CarwashModel> get pendingList => _pendingList;
  List<CarwashModel> get approvedList => _approvedList;
  List<CarwashModel> get rejectedList => _rejectedList;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Fetch Methods ---
  Future<void> fetchPendingCarwashes() async => await _fetchList(status: 'pending');
  Future<void> fetchApprovedCarwashes() async => await _fetchList(status: 'approved');
  Future<void> fetchRejectedCarwashes() async => await _fetchList(status: 'rejected');

  Future<void> _fetchList({required String status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final String endpoint = '${ApiConstants.adminPending}?status=$status';
      print("AdminProvider: Fetching $status list from $endpoint"); // DEBUG LOG

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
      print("AdminProvider: Loaded ${data.length} items for $status"); // DEBUG LOG

    } catch (e) {
      print("AdminProvider Error: $e"); // DEBUG LOG
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Manage Request (Approve / Reject / Suspend) ---
  Future<bool> manageRequest(int id, String action, {String? reason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("AdminProvider: Sending $action request for ID $id..."); // DEBUG LOG
      
      final Map<String, dynamic> body = { "action": action };
      if (reason != null && reason.isNotEmpty) {
        body['rejection_reason'] = reason;
      }

      await _api.post('${ApiConstants.adminManage}$id/', body, auth: true);
      
      print("AdminProvider: $action successful. Refreshing lists..."); // DEBUG LOG

      // ✅ FORCE REFRESH: Reload data from server to ensure it actually changed
      await fetchPendingCarwashes();
      await fetchApprovedCarwashes();
      await fetchRejectedCarwashes();

      return true;
    } catch (e) {
      print("AdminProvider Error ($action): $e"); // DEBUG LOG
      _error = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- DELETE CARWASH ---
  Future<bool> deleteCarwash(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("AdminProvider: Deleting carwash ID $id..."); // DEBUG LOG
      
      // Call Delete API
      await _api.delete('${ApiConstants.adminDelete}$id/', auth: true);

      print("AdminProvider: Delete successful. Refreshing lists..."); // DEBUG LOG

      // ✅ FORCE REFRESH: Reload data from server to ensure it is GONE
      // We purposefully reload ALL lists to ensure it's removed from everywhere
      await fetchPendingCarwashes();
      await fetchApprovedCarwashes();
      await fetchRejectedCarwashes();

      return true;
    } catch (e) {
      print("AdminProvider Delete Error: $e"); // DEBUG LOG
      _error = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}