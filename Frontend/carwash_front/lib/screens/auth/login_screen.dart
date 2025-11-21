import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    // [Task-F15] & [Task-F16]
    bool success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      // [Task-F17] Navigation based on Role
      switch (auth.user?.role) {
        case UserRole.admin:
          Navigator.pushReplacementNamed(context, '/admin');
          break;
        case UserRole.carwash:
          Navigator.pushReplacementNamed(context, '/carwash');
          break;
        case UserRole.customer:
        default:
          Navigator.pushReplacementNamed(context, '/customer');
          break;
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'خطا در ورود'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.watch<AuthProvider>().status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.water_drop, size: 60, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                "کارواش پرو",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 40),

              CustomInput(
                label: "ایمیل",
                hint: "example@email.com",
                icon: Icons.email,
                controller: _emailController,
              ),
              CustomInput(
                label: "رمز عبور",
                hint: "******",
                icon: Icons.lock,
                controller: _passwordController,
                isPassword: true,
              ),

              const SizedBox(height: 24),
              CustomButton(
                text: "ورود",
                onPressed: _handleLogin,
                isLoading: isLoading,
              ),

              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: const Text(
                  "ثبت‌نام مشتری جدید",
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/apply'),
                child: const Text(
                  "ثبت درخواست کارواش",
                  style: TextStyle(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
