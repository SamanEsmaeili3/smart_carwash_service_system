import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../constants/api_constants.dart';

class CarwashProfileProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Update Profile (supports optional password change)
  Future<bool> updateProfile({
    String? businessName,
    String? address,
    String? phoneNumber,
    String? newPassword,
    Map<String, String>? workingHours, 
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final Map<String, dynamic> body = {};
    if (businessName != null) body['business_name'] = businessName;
    if (address != null) body['address'] = address;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (newPassword != null && newPassword.isNotEmpty) {
      body['new_password'] = newPassword;
    }
    if (workingHours != null) { // <--- ADD THIS BLOCK
      body['working_hours'] = workingHours;
    }

    try {
      await _api.patch(ApiConstants.profileMe, body, auth: true);
      return true;
    } catch (e) {
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
