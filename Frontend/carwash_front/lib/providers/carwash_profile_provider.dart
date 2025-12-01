import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class CarwashProfileProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Update Profile (supports optional password change)
  /// PDF: You can send 'new_password' optionally.
  Future<bool> updateProfile({
    String? businessName,
    String? address,
    String? phoneNumber,
    String? newPassword, // Optional field per PDF
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Prepare the body with only non-null values (Partial Update)
    final Map<String, dynamic> body = {};
    if (businessName != null) body['business_name'] = businessName;
    if (address != null) body['address'] = address;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (newPassword != null && newPassword.isNotEmpty) {
      body['new_password'] = newPassword; // The PDF specific field
    }

    try {
      // PDF: Method PUT / PATCH -> URL: /api/carwash/profile/me/
      await _api.patch(ApiConstants.profileMe, body, auth: true);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
