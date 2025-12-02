import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../models/carwash_model.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<CarwashModel> _pendingList = [];
  bool _isLoading = false;
  String? _error;

  List<CarwashModel> get pendingList => _pendingList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // [Task-F11]
  Future<void> fetchPendingCarwashes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.adminPending, auth: true);
      final List<dynamic> data = response;
      _pendingList =
          data
              .map((e) => CarwashModel.fromJson(e as Map<String, dynamic>))
              .toList();
    } catch (e) {
      print("Error happened fetching carwashes: $e");
      _error = _error = "خطا در بارگذاری اطلاعات";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // [Task-F13]
  Future<bool> manageRequest(int id, String action) async {
    try {
      await _api.post('${ApiConstants.adminManage}$id/', {
        "action": action,
      }, auth: true);

      // Optimistic Update: Remove from local list
      _pendingList.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _error = "خطا در بارگذاری اطلاعات";
      notifyListeners();
      return false;
    }
  }
}
