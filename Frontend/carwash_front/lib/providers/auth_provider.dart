import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_service.dart';
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
      notifyListeners();
      return true;
    } catch (e) {
      _setError(
        "نام کاربری یا رمز عبور اشتباه است و یا کاربری با این مشخصات موجود نمی باشد",
      );
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
        "full_name": fullName, // must match Django serializer
        "phone_number": phone, // must match Django serializer
      });
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
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
      _setError("کارواش با این مشخصات موجود است، ورورد را امتحان کنید");
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _user = null;
    _status = AuthStatus.initial;
    notifyListeners();
  }

  // Checking the token when starting the app (Splash Screen)
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    if (token == null || JwtDecoder.isExpired(token)) {
      return false;
    }

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    _user = UserModel.fromToken(decodedToken);
    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }

  void _setLoading(bool val) {
    _status = val ? AuthStatus.loading : AuthStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg.replaceAll('Exception:', '').trim();
    _status = AuthStatus.error;
    notifyListeners();
  }
}