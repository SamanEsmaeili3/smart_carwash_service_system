import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ErrorHandler {
  /// این متد خروجی ریسپانس یا اکسپشن را می‌گیرد و متن فارسی برمی‌گرداند
  static String getErrorMessage(dynamic error) {
    if (error is http.Response) {
      return _handleHttpResponse(error);
    } else if (error is SocketException) {
      return 'عدم دسترسی به اینترنت. لطفاً اتصال خود را بررسی کنید.';
    } else if (error is FormatException) {
      return 'فرمت داده‌های دریافتی صحیح نیست.';
    } else if (error.toString().contains("Timeout")) {
      return 'زمان انتظار به پایان رسید. سرعت اینترنت پایین است.';
    } else {
      return 'خطای ناشناخته‌ای رخ داده است.';
    }
  }

  static String _handleHttpResponse(http.Response response) {
    // // ۱. تلاش برای خواندن پیام خطای خاص از سمت سرور (اگر بکند پیام بفرستد)
    // try {
    //   final body = jsonDecode(utf8.decode(response.bodyBytes));
    //   // معمولاً بکندها پیام را در کلیدهایی مثل 'detail', 'message', یا 'error' می‌گذارند
    //   if (body is Map) {
    //     if (body.containsKey('detail')) return body['detail'];
    //     if (body.containsKey('message')) return body['message'];
    //     if (body.containsKey('error')) return body['error'];

    //     // برای خطاهای فرم (مثل جنگو) که آرایه برمی‌گرداند: {"email": ["Invalid..."]}
    //     if (body.values.first is List) {
    //       return (body.values.first as List).first.toString();
    //     }
    //   }
    // } catch (_) {
    //   // اگر نتوانست جیسون را پارس کند، به سراغ کدهای استاندارد می‌رود
    // }

    // ۲. اگر پیام خاصی از سرور نیامد، بر اساس کد وضعیت پیام می‌دهیم
    switch (response.statusCode) {
      case 400:
        return 'درخواست نامعتبر است. ورودی‌ها را بررسی کنید.';
      case 401:
        return 'لطفاً مجدد وارد حساب کاربری خود شوید.';
      case 403:
        return 'شما مجوز دسترسی به این بخش را ندارید.';
      case 404:
        return 'اطلاعات مورد نظر یافت نشد.';
      case 409:
        return 'این اطلاعات قبلاً ثبت شده است.';
      case 422:
        return 'اطلاعات وارد شده معتبر نیست.';
      case 429:
        return 'تعداد درخواست‌ها زیاد است. لطفاً صبر کنید.';
      case 500:
        return 'خطای سمت سرور. تیم فنی در حال بررسی است.';
      case 503:
        return 'سرویس موقتاً در دسترس نیست.';
      default:
        return 'خطای ارتباط با سرور (کد ${response.statusCode})';
    }
  }
}
