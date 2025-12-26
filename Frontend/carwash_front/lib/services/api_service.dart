import 'dart:async';
import 'dart:convert';
import 'package:carwash_front/services/error_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  // --- تنظیمات Timeout ---
  static const Duration _timeoutDuration = Duration(seconds: 30);

  // --- نگهداری کلاینت‌های فعال برای امکان لغو ---
  final Map<String, http.Client> _activeClients = {};

  Future<Map<String, String>> _getHeaders({bool auth = false}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // --- متد اصلی مدیریت پاسخ‌ها ---
  dynamic _handleResponse(http.Response response) {
    try {
      // اگر کد وضعیت بین 200 تا 299 باشد (موفقیت)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // مدیریت کد 204 (No Content) یا بادی خالی
        if (response.statusCode == 204 || response.body.isEmpty) {
          return true;
        }

        // تلاش برای پارس JSON
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return decoded;
      } else {
        // استفاده از ErrorHandler برای تولید پیام خطای فارسی
        return Future.error(Exception(ErrorHandler.getErrorMessage(response)));
      }
    } catch (e) {
      // اگر خطای پارس JSON رخ داد
      return Future.error(Exception('خطا در پردازش پاسخ سرور'));
    }
  }

  // --- متد کمکی برای اجرای درخواست با مدیریت خطا ---
  Future<dynamic> _executeRequest(
    Future<http.Response> Function() requestFn, {
    String? requestId,
  }) async {
    final client = http.Client();

    // ثبت کلاینت برای امکان لغو
    if (requestId != null) {
      _activeClients[requestId] = client;
    }

    try {
      // اجرای درخواست با timeout
      final response = await requestFn().timeout(_timeoutDuration);
      return _handleResponse(response);
    } on TimeoutException catch (_) {
      throw Exception(ErrorHandler.getErrorMessage('Timeout'));
    } on http.ClientException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      // مدیریت سایر خطاها
      throw Exception(ErrorHandler.getErrorMessage(e));
    } finally {
      // پاک‌سازی کلاینت
      if (requestId != null) {
        _activeClients.remove(requestId);
      }
      client.close();
    }
  }

  // --- لغو درخواست خاص ---
  void cancelRequest(String requestId) {
    if (_activeClients.containsKey(requestId)) {
      _activeClients[requestId]!.close();
      _activeClients.remove(requestId);
    }
  }

  // --- GET ---
  Future<dynamic> get(
    String endpoint, {
    bool auth = true,
    String? requestId,
    Map<String, String>? queryParams,
  }) async {
    final headers = await _getHeaders(auth: auth);

    // ساخت URL با پارامترهای کوئری
    Uri url;
    if (queryParams != null && queryParams.isNotEmpty) {
      url = Uri.parse(
        '${ApiConstants.baseUrl}$endpoint',
      ).replace(queryParameters: queryParams);
    } else {
      url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    }

    return _executeRequest(
      () => http.get(url, headers: headers),
      requestId: requestId,
    );
  }

  // --- POST ---
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool auth = false,
    String? requestId,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(auth: auth);

    return _executeRequest(
      () => http.post(url, headers: headers, body: jsonEncode(data)),
      requestId: requestId,
    );
  }

  // --- PUT ---
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? data,
    bool auth = false,
    String? requestId,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(auth: auth);

    return _executeRequest(
      () => http.put(
        url,
        headers: headers,
        body: data != null ? jsonEncode(data) : null,
      ),
      requestId: requestId,
    );
  }

  // --- PATCH ---
  Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> data, {
    bool auth = false,
    String? requestId,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(auth: auth);

    return _executeRequest(
      () => http.patch(url, headers: headers, body: jsonEncode(data)),
      requestId: requestId,
    );
  }

  // --- DELETE ---
  Future<dynamic> delete(
    String endpoint, {
    bool auth = false,
    String? requestId,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(auth: auth);

    return _executeRequest(
      () => http.delete(url, headers: headers),
      requestId: requestId,
    );
  }

  // --- GET with Query Params (Search) - سازگار با نسخه قبلی ---
  Future<dynamic> getWithParams(
    String endpoint,
    Map<String, dynamic> queryParams, {
    bool auth = true,
    String? requestId,
  }) async {
    return get(
      endpoint,
      auth: auth,
      requestId: requestId,
      queryParams: queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }
}
