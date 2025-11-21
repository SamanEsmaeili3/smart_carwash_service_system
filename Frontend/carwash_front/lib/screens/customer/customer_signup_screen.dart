import 'package:flutter/material.dart';

class CustomerSignupScreen extends StatefulWidget {
  const CustomerSignupScreen({super.key});

  @override
  State<CustomerSignupScreen> createState() => _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends State<CustomerSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // controllers for receiving a text
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptedTerms = false;

  void _handleSignup() {
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
      //TODO: place server connection logic(Provider)
      //for now we just show a message and return
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ثبت‌نام با موفقیت انجام شد')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          //Header(blue part above the screen)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            color: Colors.blue.shade600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "ثبت‌نام مشتری",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 40.0, top: 8),
                  child: Text(
                    "اطلاعات خود را برای ایجاد حساب کاربری وارد کنید",
                    style: TextStyle(color: Colors.blueAccent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          //signup Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
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

                    //  rule checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          activeColor: Colors.blue.shade600,
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
                                onTap: () {}, // لینک قوانین
                                child: Text(
                                  "قوانین و مقررات",
                                  style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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

                    // signup button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _handleSignup,
                        child: const Text(
                          "ثبت‌نام",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // لینک ورود
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "قبلاً حساب کاربری دارید؟ ",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            "وارد شوید",
                            style: TextStyle(
                              color: Colors.blue.shade600,
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
            ),
          ),
        ],
      ),
    );
  }

  //helper widget to simulate card form of input
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              obscureText: isPassword,
              keyboardType: keyboardType,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
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
