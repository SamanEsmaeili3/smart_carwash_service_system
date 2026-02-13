import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class ErrorHandler {
  /// این متد هر نوع خطایی را دریافت کرده و متن فارسی مناسب برمی‌گرداند
  static String getErrorMessage(dynamic error) {
    // Handle DioException specifically to extract error from response body
    if (error is DioException) {
      if (error.response != null && error.response!.data != null) {
        try {
          final data = error.response!.data;
          if (data is Map<String, dynamic>) {
            // Try to extract error message from common fields
            if (data.containsKey('error')) {
              return _parseErrorMessage(data['error'].toString());
            }
            if (data.containsKey('message')) {
              return _parseErrorMessage(data['message'].toString());
            }
            if (data.containsKey('detail')) {
              return _parseErrorMessage(data['detail'].toString());
            }
          } else if (data is String) {
            return _parseErrorMessage(data);
          }
        } catch (_) {
          // If parsing fails, fall through to default handling
        }
      }
      // If no response body, use status code or default message
      if (error.response != null) {
        return _handleDioResponse(error.response!);
      }
      return _parseErrorMessage(error.toString());
    }

    // اگر خطا یک Exception یا String مستقیم باشد
    if (error is String) {
      return _parseErrorMessage(error);
    }

    if (error is Exception) {
      return _parseErrorMessage(error.toString());
    }

    if (error is http.Response) {
      return _handleHttpResponse(error);
    }

    if (error is SocketException) {
      return 'عدم دسترسی به اینترنت. لطفاً اتصال خود را بررسی کنید.';
    }

    if (error is TimeoutException) {
      return 'زمان انتظار به پایان رسید. سرعت اینترنت پایین است یا سرور پاسخ نمی‌دهد.';
    }

    if (error is FormatException) {
      return 'فرمت داده‌های دریافتی از سرور صحیح نیست.';
    }

    if (error is http.ClientException) {
      if (error.toString().contains('Failed host lookup')) {
        return 'سرور در دسترس نیست. لطفاً اتصال اینترنت را بررسی کنید.';
      }
      return 'خطا در ارتباط با سرور: ${error.message}';
    }

    // پیش‌فرض برای سایر خطاها
    return 'خطای ناشناخته‌ای رخ داده است. لطفاً دوباره تلاش کنید.';
  }

  /// استخراج پیام خطا از متن خطا
  static String _parseErrorMessage(String error) {
    final String lowerError = error.toLowerCase();

    // خطاهای رایج شبکه
    if (lowerError.contains('socket') || lowerError.contains('network')) {
      return 'عدم دسترسی به اینترنت. لطفاً اتصال خود را بررسی کنید.';
    }

    if (lowerError.contains('timeout') || lowerError.contains('timed out')) {
      return 'زمان انتظار به پایان رسید. سرعت اینترنت پایین است.';
    }

    if (lowerError.contains('failed host lookup')) {
      return 'سرور در دسترس نیست. لطفاً اتصال اینترنت را بررسی کنید.';
    }

    // خطاهای احراز هویت - با پیام‌های مختلف
    if (lowerError.contains('unauthorized') ||
        lowerError.contains('401') ||
        lowerError.contains('no active account') ||
        lowerError.contains('invalid credentials') ||
        lowerError.contains('unable to log in') ||
        lowerError.contains('authentication failed')) {
      return 'ایمیل یا رمز عبور اشتباه است';
    }

    if (lowerError.contains('forbidden') || lowerError.contains('403')) {
      return 'شما مجوز دسترسی به این بخش را ندارید.';
    }

    // خطاهای اعتبارسنجی داده
    if (lowerError.contains('already exists') ||
        lowerError.contains('duplicate') ||
        lowerError.contains('user with this email')) {
      return 'این ایمیل قبلاً ثبت شده است.';
    }

    if (lowerError.contains('invalid') ||
        lowerError.contains('not valid') ||
        lowerError.contains('validation error')) {
      return 'اطلاعات وارد شده معتبر نیست.';
    }

    // خطاهای سرور
    if (lowerError.contains('internal server error') ||
        lowerError.contains('500')) {
      return 'خطای سمت سرور. لطفاً بعداً تلاش کنید.';
    }

    if (lowerError.contains('no active account found')) {
      return 'ایمیل یا رمز عبور اشتباه است';
    }

    // حذف بخش‌های اضافی از پیام خطا
    String cleanError =
        error
            .replaceAll('Exception:', '')
            .replaceAll('Error:', '')
            .replaceAll(RegExp(r'^\s*'), '')
            .replaceAll(RegExp(r'\s*$'), '')
            .trim();

    // اگر پیام خطا طولانی است، خلاصه‌اش کن
    if (cleanError.length > 100) {
      cleanError = '${cleanError.substring(0, 100)}...';
    }

    if (cleanError.isEmpty) {
      return 'خطای ناشناخته‌ای رخ داده است.';
    }

    if (_hasPersian(cleanError)) {
      return cleanError;
    }

    if (!_hasLatin(cleanError)) {
      return 'خطا: $cleanError';
    }

    return 'خطایی رخ داده است. لطفاً دوباره تلاش کنید.';
  }

  static bool _hasPersian(String text) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(text);

  static bool _hasLatin(String text) => RegExp(r'[A-Za-z]').hasMatch(text);

  /// مدیریت پاسخ HTTP با کد خطا
  static String _handleHttpResponse(http.Response response) {
    // ابتدا سعی می‌کنیم پیام خطا را از بدنه پاسخ استخراج کنیم
    try {
      if (response.body.isNotEmpty) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));

        if (body is Map<String, dynamic>) {
          // الگوهای رایج پیام خطا در APIها
          if (body.containsKey('detail')) {
            final detail = body['detail'].toString();
            return _parseErrorMessage(detail);
          }
          if (body.containsKey('message')) {
            final message = body['message'].toString();
            return _parseErrorMessage(message);
          }
          if (body.containsKey('error')) {
            final error = body['error'].toString();
            return _parseErrorMessage(error);
          }
          if (body.containsKey('errors')) {
            final errors = body['errors'];
            if (errors is Map && errors.isNotEmpty) {
              return _parseErrorMessage(errors.values.first.toString());
            }
          }

          // برای خطاهای جنگو REST Framework
          if (body.containsKey('non_field_errors') &&
              body['non_field_errors'] is List &&
              (body['non_field_errors'] as List).isNotEmpty) {
            return _parseErrorMessage(
              (body['non_field_errors'] as List).first.toString(),
            );
          }

          // برای خطاهای احراز هویت خاص
          for (final key in body.keys) {
            if (body[key] is List && (body[key] as List).isNotEmpty) {
              return _parseErrorMessage((body[key] as List).first.toString());
            }
          }
        }

        // اگر بدنه JSON است اما ساختار نامشخص
        return _parseErrorMessage(response.body);
      }
    } catch (_) {
      // اگر نتوانستیم JSON را پارس کنیم، ادامه می‌دهیم
    }

    // اگر پیام خاصی از سرور نیامد، بر اساس کد وضعیت پیام می‌دهیم
    switch (response.statusCode) {
      case 400:
        return 'درخواست نامعتبر است. لطفاً ورودی‌ها را بررسی کنید.';
      case 401:
        return 'ایمیل یا رمز عبور اشتباه است';
      case 403:
        return 'شما مجوز دسترسی به این بخش را ندارید.';
      case 404:
        return 'اطلاعات مورد نظر یافت نشد.';
      case 409:
        return 'این اطلاعات قبلاً ثبت شده است.';
      case 422:
        return 'اطلاعات وارد شده معتبر نیست.';
      case 429:
        return 'تعداد درخواست‌ها زیاد است. لطفاً چند لحظه صبر کنید.';
      case 500:
        return 'خطای سمت سرور. تیم فنی در حال بررسی است.';
      case 502:
      case 503:
      case 504:
        return 'سرویس موقتاً در دسترس نیست. لطفاً چند دقیقه دیگر تلاش کنید.';
      default:
        if (response.statusCode >= 500) {
          return 'خطای سرور (کد ${response.statusCode}). لطفاً بعداً تلاش کنید.';
        } else if (response.statusCode >= 400) {
          return 'خطای کلاینت (کد ${response.statusCode}). لطفاً ورودی‌ها را بررسی کنید.';
        }
        return 'خطای ارتباط با سرور (کد ${response.statusCode})';
    }
  }

  /// Handle Dio Response errors
  static String _handleDioResponse(Response response) {
    // Try to extract error from response data
    if (response.data != null) {
      try {
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('error')) {
            return _parseErrorMessage(data['error'].toString());
          }
          if (data.containsKey('message')) {
            return _parseErrorMessage(data['message'].toString());
          }
          if (data.containsKey('detail')) {
            return _parseErrorMessage(data['detail'].toString());
          }
        }
      } catch (_) {
        // If parsing fails, continue to status code handling
      }
    }

    // Fall back to status code based messages
    switch (response.statusCode) {
      case 400:
        return 'درخواست نامعتبر است. لطفاً ورودی‌ها را بررسی کنید.';
      case 401:
        return 'ایمیل یا رمز عبور اشتباه است';
      case 403:
        return 'شما مجوز دسترسی به این بخش را ندارید.';
      case 404:
        return 'اطلاعات مورد نظر یافت نشد.';
      case 409:
        return 'این اطلاعات قبلاً ثبت شده است.';
      case 422:
        return 'اطلاعات وارد شده معتبر نیست.';
      case 429:
        return 'تعداد درخواست‌ها زیاد است. لطفاً چند لحظه صبر کنید.';
      case 500:
        return 'خطای سمت سرور. تیم فنی در حال بررسی است.';
      case 502:
      case 503:
      case 504:
        return 'سرویس موقتاً در دسترس نیست. لطفاً چند دقیقه دیگر تلاش کنید.';
      default:
        if (response.statusCode != null) {
          if (response.statusCode! >= 500) {
            return 'خطای سرور (کد ${response.statusCode}). لطفاً بعداً تلاش کنید.';
          } else if (response.statusCode! >= 400) {
            return 'خطای کلاینت (کد ${response.statusCode}). لطفاً ورودی‌ها را بررسی کنید.';
          }
        }
        return 'خطای ارتباط با سرور';
    }
  }
}
