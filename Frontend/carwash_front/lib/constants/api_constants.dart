//import 'dart:io';
import 'package:flutter/foundation.dart';

// class ApiConstants {
//   // Automatic detection of server address (for Android emulator 10.0.2.2 and other locales 127.0.0.1)
//   static String get baseUrl {
//     // 1. Check if the application is running in a web browser.
//     if (kIsWeb) {
//       // If on web, use localhost which is accessible directly from the browser context.
//       return 'http://127.0.0.1:8000';
//     }

//     // 2. If not on web (i.e., running on Mobile/Desktop), use Platform checks.
//     // The dart:io library is fully supported here and will not throw an error.
//     if (Platform.isAndroid) {
//       // Crucial for Android Emulators to reach the host machine.
//       return 'http://10.0.2.2:8000';
//     }

//     // Default URL for iOS Simulator, Windows/macOS desktop, etc.
//     return 'http://127.0.0.1:8000';
//   }

//   // Auth Endpoints
//   static const String login = '/api/token/';
//   static const String register = '/api/accounts/register/';
//   static const String refreshToken = '/api/token/refresh/';

//   // Carwash Endpoints
//   static const String apply = '/api/carwash/apply/';

//   // Admin Endpoints
//   static const String adminPending = '/api/carwash/admin/pending/';
//   static const String adminManage = '/api/carwash/admin/manage/'; // + <id>/
// }


import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String baseUrl = 'https://my-project-api.liara.run';


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