import 'package:flutter/material.dart';

class CarwashSignUpScreen extends StatefulWidget {
  const CarwashSignUpScreen({super.key});

  @override
  State<CarwashSignUpScreen> createState() => _CarwashSignUpScreenState();
}

class _CarwashSignUpScreenState extends State<CarwashSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  //controllers
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _workingHoursController = TextEditingController();

  bool _acceptedTerms = false;

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('قوانین را بپذیرید')));
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رمز عبورها یکسان نیستند')),
        );
        return;
      }

      // show successful dialog
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("درخواست ثبت شد"),
              content: const Text(
                "درخواست شما با موفقیت دریافت شد و پس از بررسی (حداکثر ۴۸ ساعت) نتیجه اطلاع داده می‌شود.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx); //close dialog
                    Navigator.pop(context); //return to login page
                    //Todo: correct navigations, store auth token and login with that user
                  },
                  child: const Text(
                    "متوجه شدم",
                    style: TextStyle(color: Colors.purple),
                  ),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          //Header (Purple part)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            color: Colors.purple.shade600,
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
                    const Expanded(
                      child: Text(
                        "ثبت کارواش جدید",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 40.0, top: 8),
                  child: Text(
                    "اطلاعات کسب و کار خود را وارد کنید",
                    style: TextStyle(color: Colors.purpleAccent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // --- Form ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Part1: Owner information
                    _buildSectionTitle("اطلاعات مالک"),
                    _buildInputCard(
                      "نام و نام خانوادگی مالک",
                      "نام کامل",
                      Icons.person,
                      _ownerNameController,
                    ),
                    _buildInputCard(
                      "ایمیل مالک",
                      "example@email.com",
                      Icons.email,
                      _ownerEmailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildInputCard(
                      "شماره تماس مالک",
                      "09123456789",
                      Icons.phone_android,
                      _ownerPhoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildInputCard(
                      "رمز عبور",
                      "حداقل ۸ کاراکتر",
                      Icons.lock,
                      _passwordController,
                      isPassword: true,
                    ),
                    _buildInputCard(
                      "تکرار رمز عبور",
                      "تکرار رمز",
                      Icons.lock,
                      _confirmPasswordController,
                      isPassword: true,
                    ),

                    const SizedBox(height: 24),

                    //Part2: business information
                    _buildSectionTitle("اطلاعات کسب و کار"),
                    _buildInputCard(
                      "نام کارواش",
                      "نام کارواش شما",
                      Icons.store,
                      _businessNameController,
                    ),
                    _buildInputCard(
                      "آدرس کامل",
                      "آدرس دقیق کارواش",
                      Icons.map,
                      _businessAddressController,
                      maxLines: 3,
                    ),
                    _buildInputCard(
                      "شماره تماس کارواش",
                      "021...",
                      Icons.phone,
                      _businessPhoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildInputCard(
                      "ساعات کاری",
                      "مثال: ۸ صبح تا ۸ شب",
                      Icons.access_time,
                      _workingHoursController,
                    ),

                    const SizedBox(height: 16),

                    //Part3: upload documents images
                    //Todo: complete this part
                    Row(
                      children: [
                        Expanded(child: _buildUploadBox("تصویر پروانه کسب")),
                        const SizedBox(width: 16),
                        Expanded(child: _buildUploadBox("کارت ملی مالک")),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // rules
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          activeColor: Colors.purple.shade600,
                          onChanged:
                              (value) =>
                                  setState(() => _acceptedTerms = value!),
                        ),
                        Expanded(
                          child: Wrap(
                            children: [
                              Text(
                                "با ثبت کارواش، ",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  "قوانین و مقررات",
                                  style: TextStyle(
                                    color: Colors.purple.shade600,
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

                    // send button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _handleSubmit,
                        child: const Text(
                          "ارسال درخواست",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Yellow notification box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade50,
                        border: Border.all(color: Colors.yellow.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.yellow.shade800,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "درخواست شما پس از بررسی توسط تیم ما، حداکثر ظرف ۴۸ ساعت بررسی و نتیجه از طریق ایمیل اطلاع داده می‌شود.",
                              style: TextStyle(
                                color: Colors.yellow.shade900,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 16),
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            TextFormField(
              controller: controller,
              obscureText: isPassword,
              keyboardType: keyboardType,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              validator:
                  (value) =>
                      (value == null || value.isEmpty)
                          ? ''
                          : null, // Only to make the border red if it is empty
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadBox(String title) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.shade200,
          style: BorderStyle.solid,
        ), // In Flutter, Dotted Border requires a package, here we put Solid
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            color: Colors.blue.shade400,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 28),
            ),
            child: Text(
              "انتخاب فایل",
              style: TextStyle(fontSize: 10, color: Colors.blue.shade600),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "JPG, PNG",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
