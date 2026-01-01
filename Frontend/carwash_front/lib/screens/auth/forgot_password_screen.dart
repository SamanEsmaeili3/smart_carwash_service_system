import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleRequestReset() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ایمیل خود را وارد کنید')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = await auth.requestPasswordReset(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  ResetPasswordScreen(email: _emailController.text.trim()),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'خطا در درخواست بازنشانی رمز'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فراموشی رمز عبور'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 30),
              // Title
              const Text(
                'بازنشانی رمز عبور',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                'ایمیل خود را وارد کنید. کد تأیید برای تعیین رمز جدید برای شما ارسال خواهد شد',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Email Input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'آدرس ایمیل',
                  hintText: 'example@email.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Submit Button
              CustomButton(
                text: 'درخواست کد تأیید',
                onPressed: _isLoading ? null : _handleRequestReset,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
              // Go Back
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'بازگشت',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
