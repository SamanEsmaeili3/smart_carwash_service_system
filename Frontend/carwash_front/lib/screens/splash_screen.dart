// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2)); //show logo
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool isLoggedIn = await auth.tryAutoLogin();
    if (!mounted) return;

    if (isLoggedIn) {
      switch (auth.user?.role) {
        case UserRole.admin:
          Navigator.pushReplacementNamed(context, '/admin');
          break;
        case UserRole.carwash:
          Navigator.pushReplacementNamed(context, '/carwash');
          break;
        default:
          Navigator.pushReplacementNamed(context, '/customer');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Your brand color
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(height: 20),
                      CircularProgressIndicator(color: Colors.white),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
