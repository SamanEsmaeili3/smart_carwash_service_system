import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';

class CustomerSignupScreen extends StatefulWidget {
  const CustomerSignupScreen({super.key});
  @override
  State<CustomerSignupScreen> createState() => _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends State<CustomerSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController(); // Optional, backend doesn't require it yet
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      if (_passCtrl.text != _confirmPassCtrl.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('رمز عبور یکسان نیست')));
        return;
      }

      final auth = Provider.of<AuthProvider>(context, listen: false);
      // [Task-F3]
      bool success = await auth.registerCustomer(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
        _nameController.text.trim(), // <--- Added Name
        _phoneController.text.trim(), // <--- Added Phone
      );

      if (success && mounted) {
        // [Task-F4] & [Task-F5] Login & Navigate
        await auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
        if (mounted) Navigator.pushReplacementNamed(context, '/customer');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'خطا'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.watch<AuthProvider>().status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ثبت‌نام مشتری"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomInput(
                label: "ایمیل",
                hint: "email@example.com",
                icon: Icons.email,
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              // [Task-F2] Validation is inside CustomInput or check manually
              CustomInput(
                label: "رمز عبور",
                hint: "***",
                icon: Icons.lock,
                controller: _passCtrl,
                isPassword: true,
              ),
              CustomInput(
                label: "تکرار رمز",
                hint: "***",
                icon: Icons.lock,
                controller: _confirmPassCtrl,
                isPassword: true,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: "ثبت‌نام",
                onPressed: _signup,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
