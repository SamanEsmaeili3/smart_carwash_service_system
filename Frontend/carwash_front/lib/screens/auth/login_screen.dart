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
    bool success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
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
    final isLoading = context.watch<AuthProvider>().status == AuthStatus.loading;
    
    // Check screen size
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.primaryLight, // Light blue background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450), // Stop stretching!
              child: Container(
                // Add Card styling for Desktop feel
                padding: isDesktop ? const EdgeInsets.all(40) : const EdgeInsets.all(0),
                decoration: isDesktop 
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ]
                    )
                  : null, // No decoration on mobile (clean look)
                
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded, 
                        size: 60, 
                        color: AppColors.primary
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      "کارواش پرو",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900, // Extra Bold
                        color: AppColors.textMain,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "به حساب کاربری خود وارد شوید",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    
                    const SizedBox(height: 40),

                    CustomInput(
                      label: "ایمیل",
                      hint: "example@email.com",
                      icon: Icons.email_outlined,
                      controller: _emailController,
                    ),
                    CustomInput(
                      label: "رمز عبور",
                      hint: "******",
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      isPassword: true,
                    ),

                    const SizedBox(height: 8),
                    
                    // Forget Password Link (Placeholder)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          "رمز عبور را فراموش کردید؟",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    CustomButton(
                      text: "ورود",
                      onPressed: _handleLogin,
                      isLoading: isLoading,
                    ),

                    const SizedBox(height: 24),
                    
                    // Divider for aesthetics
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("یا", style: TextStyle(color: Colors.grey.shade400)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),

                    const SizedBox(height: 24),
                    
                    // Action Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/signup'),
                          child: const Text(
                            "ثبت‌نام مشتری",
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(height: 20, width: 1, color: Colors.grey.shade300),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/apply'),
                          child: const Text(
                            "ثبت کارواش",
                            style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}