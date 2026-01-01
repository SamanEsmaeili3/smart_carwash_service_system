import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';
import 'verify_otp_screen.dart';

class CustomerSignupScreen extends StatefulWidget {
  const CustomerSignupScreen({super.key});

  @override
  State<CustomerSignupScreen> createState() => _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends State<CustomerSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Defined Controllers ---
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptedTerms = false;

  // [Task-F3] Signup Logic
  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً قوانین و مقررات را بپذیرید')),
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رمز عبور و تکرار آن یکسان نیستند')),
        );
        return;
      }

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final email = _emailController.text.trim();

      bool success = await auth.registerCustomer(
        email,
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _phoneController.text.trim(),
      );

      if (success && mounted) {
        // Navigate to OTP verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    VerifyOtpScreen(email: email, userType: 'customer'),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'خطا در ثبت‌نام'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // --- TERMS & CONDITIONS MODAL ---
  void _showTermsDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "قوانین و مقررات",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 400, // Limit width for desktop
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "۱. تعهدات کاربر\n"
                      "کاربران موظف هستند اطلاعات صحیح وارد کنند. مسئولیت اشتباه در آدرس بر عهده کاربر است.\n\n"
                      "۲. حریم خصوصی\n"
                      "اطلاعات تماس شما نزد ما محفوظ است و تنها برای هماهنگی کارواش استفاده می‌شود.\n\n"
                      "۳. پرداخت\n"
                      "هزینه خدمات باید پس از اتمام کار یا به صورت آنلاین پرداخت شود.\n\n"
                      "۴. لغو سفارش\n"
                      "لغو سفارش تا ۱ ساعت قبل از زمان رزرو رایگان است.",
                      style: TextStyle(height: 1.8),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("متوجه شدم"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.watch<AuthProvider>().status == AuthStatus.loading;
    final isDesktop = MediaQuery.of(context).size.width > 650;

    return Scaffold(
      // Match Login Screen Theme
      backgroundColor: AppColors.primaryLight,

      // Standard AppBar handles the Back Arrow correctly in RTL
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primary), // Blue arrow
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Center(
            // --- FIX 1: ConstrainedBox to fix stretching ---
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Container(
                padding:
                    isDesktop
                        ? const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 40,
                        )
                        : const EdgeInsets.all(0),
                decoration:
                    isDesktop
                        ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade900.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        )
                        : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header Text
                    const Text(
                      "ثبت‌نام مشتری",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // --- FIX 2: Better Contrast for Subtitle ---
                    Text(
                      "اطلاعات خود را برای ایجاد حساب کاربری وارد کنید",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            Colors.grey.shade600, // Darker grey for readability
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Signup Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildInputCard(
                            "نام و نام خانوادگی",
                            "نام کامل خود را وارد کنید",
                            Icons.person_outline,
                            _nameController,
                          ),
                          _buildInputCard(
                            "ایمیل",
                            "example@email.com",
                            Icons.mail_outline,
                            _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _buildInputCard(
                            "شماره تلفن",
                            "09123456789",
                            Icons.phone_android,
                            _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          _buildInputCard(
                            "آدرس",
                            "آدرس خود را وارد کنید",
                            Icons.location_on_outlined,
                            _addressController,
                            maxLines: 3,
                          ),
                          _buildInputCard(
                            "رمز عبور",
                            "حداقل ۸ کاراکتر",
                            Icons.lock_outline,
                            _passwordController,
                            isPassword: true,
                          ),
                          _buildInputCard(
                            "تکرار رمز عبور",
                            "رمز عبور را دوباره وارد کنید",
                            Icons.lock_outline,
                            _confirmPasswordController,
                            isPassword: true,
                          ),

                          const SizedBox(height: 16),

                          // Rules checkbox with Link
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptedTerms,
                                activeColor: AppColors.primary,
                                onChanged:
                                    (value) =>
                                        setState(() => _acceptedTerms = value!),
                              ),
                              Expanded(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      "با ثبت‌نام، ",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap:
                                          _showTermsDialog, // --- FIX 3: Opens Dialog ---
                                      child: Text(
                                        "قوانین و مقررات",
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      " را می‌پذیرم",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Signup button
                          CustomButton(
                            text: "ایجاد حساب",
                            onPressed: _handleSignup,
                            isLoading: isLoading,
                          ),

                          const SizedBox(height: 16),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "قبلاً حساب کاربری دارید؟ ",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              GestureDetector(
                                onTap:
                                    () => Navigator.pop(
                                      context,
                                    ), // Goes back to Login/Landing
                                child: const Text(
                                  "وارد شوید",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
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

  Widget _buildInputCard(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12), // Slightly rounder
              border: Border.all(
                color: Colors.grey.shade300,
              ), // Added border for better visibility
            ),
            child: TextFormField(
              controller: controller,
              obscureText: isPassword,
              keyboardType: keyboardType,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'این فیلد الزامی است';
                }
                if (isPassword && value.length < 8) {
                  return 'رمز عبور باید حداقل ۸ کاراکتر باشد';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
