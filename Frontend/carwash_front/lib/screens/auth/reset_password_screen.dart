import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً کد تأیید را وارد کنید')),
      );
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً رمز عبور جدید را وارد کنید')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز عبور و تکرار آن یکسان نیستند')),
      );
      return;
    }

    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز عبور باید حداقل ۸ حرف باشد')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = await auth.confirmPasswordReset(
      widget.email,
      _codeController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رمز عبور شما با موفقیت بازنشانی شد'),
          backgroundColor: Colors.green,
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'خطا در بازنشانی رمز عبور'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعیین رمز جدید'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Title
              const Center(
                child: Text(
                  'رمز جدید را تعیین کنید',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              // Code Input
              const Text(
                'کد تأیید',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 5,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: '00000',
                  hintStyle: TextStyle(
                    color: Colors.grey[300],
                    letterSpacing: 8,
                  ),
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
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 20),
              // Password Input
              const Text(
                'رمز عبور جدید',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  hintText: 'رمز عبور جدید را وارد کنید',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
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
              const SizedBox(height: 20),
              // Confirm Password Input
              const Text(
                'تأیید رمز عبور',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'رمز عبور را دوباره وارد کنید',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(
                        () => _showConfirmPassword = !_showConfirmPassword,
                      );
                    },
                  ),
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
                text: 'بازنشانی رمز عبور',
                onPressed: _isLoading ? null : _handleResetPassword,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
