import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, error }

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  UserModel? _user;
  String? _userRole; // Store user role for OTP verification

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  String? get userRole => _userRole;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // [Task-F15] & [Task-F16] & [Task-F17]
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _api.post(ApiConstants.login, {
        "email": email,
        "password": password,
      });

      final prefs = await SharedPreferences.getInstance();
      String accessToken = response['access'];
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', response['refresh']);

      // Decode token to get role
      Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);

      // Add email to decoded map manually for our model logic if needed
      decodedToken['email'] = email;

      _user = UserModel.fromToken(decodedToken);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      // فقط از ErrorHandler استفاده کن
      final errorMsg = ErrorHandler.getErrorMessage(e);
      _setError(errorMsg);
      return false;
    }
  }

  // [Task-F3]
  Future<bool> registerCustomer(
    String email,
    String password,
    String fullName,
    String phone,
  ) async {
    _setLoading(true);
    try {
      await _api.post(ApiConstants.register, {
        "email": email,
        "password": password,
        "full_name": fullName,
        "phone_number": phone,
      });
      _setLoading(false);
      return true;
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e);
      _setError(errorMsg);
      return false;
    }
  }

  // [Task-F8]
  // نیاز به import 'dart:io'; و 'package:dio/dio.dart'; داری (اگه نداری بالا اضافه کن)

  // [Task-F8] - Updated for File Upload
  Future<bool> applyForCarwash(
    Map<String, dynamic> data, 
    File? licenseFile, 
    File? ownershipFile
  ) async {
    _setLoading(true);
    try {
      final formData = FormData.fromMap(data);

      if (licenseFile != null) {
        String fileName = "license_${DateTime.now().millisecondsSinceEpoch}.jpg";
        formData.files.add(MapEntry(
          'license_image', 
          await MultipartFile.fromFile(licenseFile.path, filename: fileName),
        ));
      }

      if (ownershipFile != null) {
        String fileName = "ownership_${DateTime.now().millisecondsSinceEpoch}.jpg";
        formData.files.add(MapEntry(
          'ownership_image', 
          await MultipartFile.fromFile(ownershipFile.path, filename: fileName),
        ));
      }

      await _api.post(ApiConstants.apply, formData);
      
      _setLoading(false);
      return true;
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e);
      _setError(errorMsg);
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _user = null;
    _status = AuthStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  // Checking the token when starting the app (Splash Screen)
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    if (token == null || JwtDecoder.isExpired(token)) {
      return false;
    }

    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      _user = UserModel.fromToken(decodedToken);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      print("Error in auto login: ${ErrorHandler.getErrorMessage(e)}");
      return false;
    }
  }

  // Refresh token method
  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) return false;

      final response = await _api.post(ApiConstants.refreshToken, {
        "refresh": refreshToken,
      });

      final newAccessToken = response['access'];
      await prefs.setString('access_token', newAccessToken);
      return true;
    } catch (e) {
      print("Error refreshing token: ${ErrorHandler.getErrorMessage(e)}");
      return false;
    }
  }

  void _setLoading(bool val) {
    _status = val ? AuthStatus.loading : AuthStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _status = AuthStatus.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.initial;
    }
    notifyListeners();
  }

  // [Task-OTP] Verify OTP and handle registration completion
  Future<bool> verifyOtp(String email, String code) async {
    _setLoading(true);
    try {
      final response = await _api.post(ApiConstants.verifyOtp, {
        "email": email,
        "code": code,
      }, auth: false);

      String? role = response['role'];
      _userRole = role;

      if (role == 'customer') {
        // Customer: Save tokens and authenticate
        final prefs = await SharedPreferences.getInstance();
        String accessToken = response['access'];
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', response['refresh']);

        // Decode token to get user details
        Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
        decodedToken['email'] = email;

        _user = UserModel.fromToken(decodedToken);
        _status = AuthStatus.authenticated;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else if (role == 'carwash_owner') {
        // Carwash owner: No tokens, just mark as verified
        _status = AuthStatus.initial;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        // Unknown role
        throw Exception('نقش کاربر نامشخص است');
      }
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e);
      _setError(errorMsg);
      return false;
    }
  }

  // [Task-Forgot-Password] Request password reset code
  Future<bool> requestPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _api.post(ApiConstants.passwordResetRequest, {
        "email": email,
      }, auth: false);
      _setLoading(false);
      return true;
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e);
      _setError(errorMsg);
      return false;
    }
  }

  // [Task-Forgot-Password] Confirm password reset with code
  Future<bool> confirmPasswordReset(
    String email,
    String code,
    String newPassword,
  ) async {
    _setLoading(true);
    try {
      await _api.post(ApiConstants.passwordResetConfirm, {
        "email": email,
        "code": code,
        "new_password": newPassword,
      }, auth: false);
      _setLoading(false);
      return true;
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e);
      _setError(errorMsg);
      return false;
    }
  }
}
