import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final String? userType; // 'customer' or 'carwash_owner'

  const VerifyOtpScreen({super.key, required this.email, this.userType});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  late TextEditingController _otpController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleVerifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً کد تأیید را وارد کنید')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = await auth.verifyOtp(
      _emailController.text.trim(),
      _otpController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Check user role from auth provider
      String? role = auth.userRole;

      if (role == 'customer') {
        // Customer: Redirect to dashboard
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/customer',
          (route) => false,
        );
      } else if (role == 'carwash_owner') {
        // Carwash owner: Show message and redirect to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ایمیل شما تأیید شد. پس از بررسی و تأیید توسط مدیریت، حساب شما فعال خواهد شد.',
            ),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.green,
          ),
        );
        // Redirect to login after 3 seconds
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } else {
        // Unknown role
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/landing',
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'خطا در تأیید کد'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تأیید ایمیل'),
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
                  Icons.mail_outline,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 30),
              // Title
              const Text(
                'کد تأیید را وارد کنید',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                'کد تأیید ۵ رقمی به آدرس ایمیل شما ارسال شده است',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Email Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      widget.email,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // OTP Input
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 5,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 10,
                ),
                decoration: InputDecoration(
                  hintText: '00000',
                  hintStyle: TextStyle(
                    color: Colors.grey[300],
                    letterSpacing: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
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
              const SizedBox(height: 40),
              // Verify Button
              CustomButton(
                text: 'تأیید کد',
                onPressed: _isLoading ? null : _handleVerifyOtp,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              // Resend Code Option
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement resend OTP functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('کد تأیید دوباره ارسال شد')),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('دوباره ارسال کد'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
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
