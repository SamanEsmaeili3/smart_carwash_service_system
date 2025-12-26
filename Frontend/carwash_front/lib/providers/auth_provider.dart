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

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
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
  Future<bool> applyForCarwash(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _api.post(ApiConstants.apply, data);
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
}
