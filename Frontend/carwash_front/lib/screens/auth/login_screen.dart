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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 650;

    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      
      // --- NEW: ADDING THE BACK BUTTON HERE ---
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Invisible background
        elevation: 0, // No shadow
        iconTheme: const IconThemeData(color: AppColors.primary), // Blue Arrow
      ),
      // ----------------------------------------

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550), 
              child: Container(
                padding: isDesktop 
                    ? const EdgeInsets.symmetric(horizontal: 50, vertical: 40)
                    : const EdgeInsets.all(0),
                decoration: isDesktop 
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade900.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        )
                      ]
                    )
                  : null,
                
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded, 
                        size: 48,
                        color: AppColors.primary
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      "کارواش پرو",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMain,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "به حساب کاربری خود وارد شوید",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    
                    const SizedBox(height: 30),

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
                    
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
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

                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("یا", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),

                    const SizedBox(height: 20),
                    
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 10,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/signup'),
                          child: const Text(
                            "ثبت‌نام مشتری",
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
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