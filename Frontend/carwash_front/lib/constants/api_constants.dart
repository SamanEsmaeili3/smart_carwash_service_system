import 'dart:io';

class ApiConstants {
  // Automatic detection of server address (for Android emulator 10.0.2.2 and other locales 127.0.0.1)
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  // Auth Endpoints
  static const String login = '/api/token/';
  static const String register = '/api/accounts/register/';
  static const String refreshToken = '/api/token/refresh/';

  // Carwash Endpoints
  static const String apply = '/api/carwash/apply/';

  // Admin Endpoints
  static const String adminPending = '/api/carwash/admin/pending/';
  static const String adminManage = '/api/carwash/admin/manage/'; // + <id>/
}
