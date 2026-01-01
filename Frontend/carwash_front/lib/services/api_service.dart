import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'package:carwash_front/services/error_handler.dart';

class ApiService {
  // تنظیمات اولیه Dio (جایگزین http Client)
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // نگهداری درخواست‌های فعال برای امکان کنسل کردن (مشابه قبل)
  final Map<String, CancelToken> _activeTokens = {};

  // --- متد کمکی برای ساخت هدر و آپشن‌ها ---
  Future<Options> _getOptions({bool auth = false, dynamic data}) async {
    final Map<String, dynamic> headers = {};

    // 1. تنظیم توکن
    if (auth) {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    // 2. نکته حیاتی: اگر دیتا از نوع فایل (FormData) بود، نباید Content-Type جیسون باشه!
    // دیو خودش Boundary رو تنظیم می‌کنه، پس هدر جیسون رو پاک می‌کنیم.
    if (data is FormData) {
      headers.remove('Content-Type'); 
    }

    return Options(headers: headers);
  }

  // --- متد اصلی اجرای درخواست با مدیریت خطا ---
  Future<dynamic> _executeRequest(
    Future<Response> Function(CancelToken? cancelToken) requestFn, {
    String? requestId,
  }) async {
    CancelToken? cancelToken;

    // ایجاد توکن کنسلی اگر شناسه درخواست داده شده باشد
    if (requestId != null) {
      cancelToken = CancelToken();
      _activeTokens[requestId] = cancelToken;
    }

    try {
      final response = await requestFn(cancelToken);
      // دیو به صورت خودکار JSON رو پارس میکنه، پس نیازی به jsonDecode نیست
      return response.data;
    } on DioException catch (e) {
      // اگر ارور از سمت سرور یا شبکه بود
      if (CancelToken.isCancel(e)) {
        throw Exception('درخواست لغو شد');
      }
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      // سایر ارورها
      throw Exception(ErrorHandler.getErrorMessage(e));
    } finally {
      // پاکسازی توکن
      if (requestId != null) {
        _activeTokens.remove(requestId);
      }
    }
  }

  // --- لغو درخواست ---
  void cancelRequest(String requestId) {
    if (_activeTokens.containsKey(requestId)) {
      _activeTokens[requestId]!.cancel("Cancelled by user");
      _activeTokens.remove(requestId);
    }
  }

  // --- GET ---
  Future<dynamic> get(
    String endpoint, {
    bool auth = true,
    String? requestId,
    Map<String, dynamic>? queryParams,
  }) async {
    return _executeRequest(
      (cancelToken) async {
        final options = await _getOptions(auth: auth);
        return _dio.get(
          endpoint,
          queryParameters: queryParams,
          options: options,
          cancelToken: cancelToken,
        );
      },
      requestId: requestId,
    );
  }

  // --- POST (سازگار با فایل و JSON) ---
  Future<dynamic> post(
    String endpoint,
    dynamic data, {
    bool auth = false,
    String? requestId,
  }) async {
    return _executeRequest(
      (cancelToken) async {
        // پاس دادن دیتا به getOptions برای تشخیص FormData
        final options = await _getOptions(auth: auth, data: data);
        
        return _dio.post(
          endpoint,
          data: data, // اینجا خود دیتا رو میفرستیم (jsonEncode نمیخواد)
          options: options,
          cancelToken: cancelToken,
        );
      },
      requestId: requestId,
    );
  }

  // --- PUT (سازگار با فایل و JSON) ---
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    bool auth = false,
    String? requestId,
  }) async {
    return _executeRequest(
      (cancelToken) async {
        final options = await _getOptions(auth: auth, data: data);
        
        return _dio.put(
          endpoint,
          data: data,
          options: options,
          cancelToken: cancelToken,
        );
      },
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
    return _executeRequest(
      (cancelToken) async {
        final options = await _getOptions(auth: auth);
        return _dio.patch(
          endpoint,
          data: data,
          options: options,
          cancelToken: cancelToken,
        );
      },
      requestId: requestId,
    );
  }

  // --- DELETE ---
  Future<dynamic> delete(
    String endpoint, {
    bool auth = false,
    String? requestId,
  }) async {
    return _executeRequest(
      (cancelToken) async {
        final options = await _getOptions(auth: auth);
        return _dio.delete(
          endpoint,
          options: options,
          cancelToken: cancelToken,
        );
      },
      requestId: requestId,
    );
  }

  // --- GET with Query Params (پشتیبانی از متد قدیمی) ---
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
      queryParams: queryParams,
    );
  }
}