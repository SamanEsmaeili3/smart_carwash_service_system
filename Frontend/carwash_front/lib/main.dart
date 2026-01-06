import 'package:carwash_front/providers/booking_provider.dart';
import 'package:carwash_front/providers/search_provider.dart';
import 'package:carwash_front/screens/customer/customer_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'package:carwash_front/providers/carwash_profile_provider.dart';
import 'package:carwash_front/providers/carwash_service_provider.dart';
import 'providers/customer_provider.dart';

import 'screens/landing_page.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/customer_signup_screen.dart';
import 'screens/auth/carwash_application_screen.dart';
import 'screens/auth/verify_otp_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/carwash/carwash_home_screen.dart';
import 'screens/carwash/drivers_management_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/customer/time_selection_screen.dart';
import 'screens/customer/order_history_screen.dart';
import 'providers/driver_provider.dart';
import 'providers/order_owner_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => CarwashServiceProvider()),
        ChangeNotifierProvider(create: (_) => CarwashProfileProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => OrderOwnerProvider()),
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
        useMaterial3: false,
      ),

      // Routes
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/landing': (context) => const LandingPage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const CustomerSignupScreen(),
        '/apply': (context) => const CarwashApplicationScreen(),
        '/verify-otp': (context) => const VerifyOtpScreen(email: ''),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/customer': (context) => const CustomerHomeScreen(),
        '/carwash': (context) => const CarwashHomeScreen(),
        '/drivers': (context) => const DriversManagementScreen(),

        // --- NEW SPRINT 4 ROUTES ---
        '/select_time': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          // Safety check: ensure we received an ID
          if (args is int) {
            return TimeSelectionScreen(orderId: args);
          }
          // Fallback if no ID passed (should not happen in normal flow)
          return const Scaffold(
            body: Center(child: Text("Error: No Order ID provided")),
          );
        },

        '/booking_success':
            (context) => Scaffold(
              backgroundColor: Colors.green,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "رزرو با موفقیت انجام شد!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed:
                          () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/customer',
                            (r) => false,
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "بازگشت به خانه",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        '/customer/history': (context) => const OrderHistoryScreen(),
      },
    );
  }
}
