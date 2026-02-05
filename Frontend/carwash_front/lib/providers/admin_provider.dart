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
  
  // NEW: State for User Story 4.1 metrics [cite: 75, 83]
  Map<String, dynamic>? _adminStats;
  
  bool _isLoading = false;
  String? _error;

  List<CarwashModel> get pendingList => _pendingList;
  List<CarwashModel> get approvedList => _approvedList;
  List<CarwashModel> get rejectedList => _rejectedList;
  
  // NEW: Getter for the Dashboard cards [cite: 78, 83]
  Map<String, dynamic>? get adminStats => _adminStats;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- NEW: Fetch Aggregated Metrics (User Story 4.1) ---
  // Implements [Task-F5.9] to fetch real data for the Dashboard 
  Future<void> fetchAdminStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("AdminProvider: Fetching dashboard metrics..."); 
      // This calls the GET /api/admin/stats/ endpoint 
      final response = await _api.get('/api/accounts/admin/stats/', auth: true);
      
      _adminStats = response as Map<String, dynamic>;
      print("AdminProvider: Dashboard stats loaded successfully"); 

    } catch (e) {
      print("AdminProvider Metrics Error: $e"); 
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      print("AdminProvider: Fetching $status list from $endpoint"); 

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
      print("AdminProvider: Loaded ${data.length} items for $status"); 

    } catch (e) {
      print("AdminProvider Error: $e"); 
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
      print("AdminProvider: Sending $action request for ID $id..."); 
      
      final Map<String, dynamic> body = { "action": action };
      if (reason != null && reason.isNotEmpty) {
        body['rejection_reason'] = reason;
      }

      await _api.post('${ApiConstants.adminManage}$id/', body, auth: true);
      
      print("AdminProvider: $action successful. Refreshing lists..."); 

      // Force refresh data and metrics to ensure Dashboard is accurate 
      await fetchPendingCarwashes();
      await fetchApprovedCarwashes();
      await fetchRejectedCarwashes();
      await fetchAdminStats(); 

      return true;
    } catch (e) {
      print("AdminProvider Error ($action): $e"); 
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
      print("AdminProvider: Deleting carwash ID $id..."); 
      
      await _api.delete('${ApiConstants.adminDelete}$id/', auth: true);

      print("AdminProvider: Delete successful. Refreshing lists and stats..."); 

      await fetchPendingCarwashes();
      await fetchApprovedCarwashes();
      await fetchRejectedCarwashes();
      await fetchAdminStats(); // Sync metrics after deletion 

      return true;
    } catch (e) {
      print("AdminProvider Delete Error: $e"); 
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