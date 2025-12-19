import 'dart:convert';
import 'package:carwash_front/services/error_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders({bool auth = false}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      // --- DEBUG PRINT ---
      // print("DEBUG: Token used: $token");
      // -------------------

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // --- متد مدیریت پاسخ‌ها و خطاها ---
  dynamic _handleResponse(http.Response response) {
    // اگر کد وضعیت بین 200 تا 299 باشد (موفقیت)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // مدیریت کد 204 (No Content) یا بادی خالی (مخصوصاً برای DELETE)
      if (response.body.isEmpty) {
        return true;
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      // اگر کد خطا بود (400, 401, 500, ...)، کلاس ErrorHandler پیام فارسی مناسب را تولید می‌کند
      String errorMessage = ErrorHandler.getErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  // --- GET ---
  Future<dynamic> get(String endpoint, {bool auth = true}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(auth: auth);

    try {
      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      // خطای شبکه یا خطایی که از _handleResponse پرتاب شده را مدیریت می‌کنیم
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // --- POST ---
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool auth = false,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(auth: auth);

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // --- PUT ---
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? data,
    bool auth = false,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(auth: auth);

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: data != null ? jsonEncode(data) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // --- PATCH ---
  Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> data, {
    bool auth = false,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(auth: auth);

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // --- DELETE ---
  Future<dynamic> delete(String endpoint, {bool auth = false}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(auth: auth);

    try {
      final response = await http.delete(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // --- GET with Query Params (Search) ---
  Future<dynamic> getWithParams(
    String endpoint,
    Map<String, dynamic> queryParams, {
    bool auth = true,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}$endpoint',
    ).replace(queryParameters: queryParams);

    final headers = await _getHeaders(auth: auth);

    try {
      // print("🔍 Searching: $uri");
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }
}
