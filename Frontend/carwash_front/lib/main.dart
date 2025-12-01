import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'package:carwash_front/providers/carwash_profile_provider.dart';
import 'package:carwash_front/providers/carwash_service_provider.dart';

import 'screens/landing_page.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/customer_signup_screen.dart';
import 'screens/auth/carwash_application_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/customer/customer_home.dart';
import 'screens/carwash/carwash_home_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => CarwashServiceProvider()),
        ChangeNotifierProvider(create: (_) => CarwashProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'کارواش پرو',
      debugShowCheckedModeBanner: false,
      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fa', 'IR')],
      locale: const Locale('fa', 'IR'),

      // Theme
      theme: ThemeData(
        fontFamily: 'Vazir',
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: false, // برای استایل کلاسیک‌تر شبیه Tailwind
      ),

      // Routes
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/landing': (context) => const LandingPage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const CustomerSignupScreen(),
        '/apply': (context) => const CarwashApplicationScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/customer': (context) => const CustomerHome(),
        '/carwash': (context) => const CarwashHomeScreen(),
      },
    );
  }
}
