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
  
  Map<String, dynamic>? _adminStats;

  List<dynamic> _usersList = [];
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CarwashModel> get pendingList => _pendingList;
  List<CarwashModel> get approvedList => _approvedList;
  List<CarwashModel> get rejectedList => _rejectedList;
  Map<String, dynamic>? get adminStats => _adminStats;
  
  List<dynamic> get usersList => _usersList;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- 1. Fetch Aggregated Metrics (User Story 4.1) ---
  Future<void> fetchAdminStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("AdminProvider: Fetching dashboard metrics..."); 
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

  // --- 2. Fetch Carwash Lists ---
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

  // --- 3. Manage Carwash Request (Approve / Reject) ---
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

  // --- 4. Delete Carwash ---
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
      await fetchAdminStats(); 

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

  // --- 5. [Sprint 5] User Management Methods ---
  Future<void> fetchUsers({String? query}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String endpoint = '/api/accounts/admin/users/';
      if (query != null && query.isNotEmpty) {
        endpoint += '?search=$query';
      }
      
      print("AdminProvider: Fetching users from $endpoint");
      final response = await _api.get(endpoint, auth: true);
      
      _usersList = response as List<dynamic>;
      
    } catch (e) {
      print("Error fetching users: $e");
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleUserBan(int userId) async {
    try {
      print("AdminProvider: Toggling ban for user $userId");
      final response = await _api.post('/api/accounts/admin/users/$userId/ban/', {}, auth: true);
      
      final index = _usersList.indexWhere((u) => u['id'] == userId);
      if (index != -1) {
        _usersList[index]['is_active'] = response['is_active'];
        notifyListeners(); 
      }
      return true;
    } catch (e) {
      print("Error banning user: $e");
      _error = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}