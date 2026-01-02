import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/auth_provider.dart';
import '../../models/carwash_model.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';
import '../map_picker_screen.dart';
import 'verify_otp_screen.dart';
import 'dart:io'; 
import 'package:image_picker/image_picker.dart'; 

class CarwashApplicationScreen extends StatefulWidget {
  const CarwashApplicationScreen({super.key});
  @override
  State<CarwashApplicationScreen> createState() =>
      _CarwashApplicationScreenState();
}

class _CarwashApplicationScreenState extends State<CarwashApplicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Password Controllers
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // Clock controllers
  final _openTimeCtrl = TextEditingController(text: "09:00");
  final _closeTimeCtrl = TextEditingController(text: "21:00");

  File? _licenseImage;
  File? _ownershipImage;
  final ImagePicker _picker = ImagePicker();

  // Location State (Default: Tehran)
  LatLng _selectedLocation = const LatLng(35.7594, 51.4103);

  bool _acceptedTerms = false;

  Future<void> _pickImage(bool isLicense) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        if (isLicense) {
          _licenseImage = File(photo.path);
        } else {
          _ownershipImage = File(photo.path);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _openTimeCtrl.dispose();
    _closeTimeCtrl.dispose();
    super.dispose();
  }

  // --- 🕒 Time Picker Logic ---
  Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay initialTime = const TimeOfDay(hour: 9, minute: 0);
    if (controller.text.contains(':')) {
      final parts = controller.text.split(':');
      initialTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.secondary,
                onPrimary: Colors.white,
                onSurface: AppColors.textMain,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      final String formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        controller.text = formattedTime;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      // 1. Check Terms
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً قوانین را بپذیرید')),
        );
        return;
      }

      // 2. Check Password Match
      if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رمز عبور و تکرار آن یکسان نیستند')),
        );
        return;
      }

      if (_licenseImage == null || _ownershipImage == null) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً مدارک (جواز و سند) را بارگذاری کنید')),
        );
        return;
      }

      String workingTime =
          "${_openTimeCtrl.text.trim()}-${_closeTimeCtrl.text.trim()}";

      Map<String, String> workingHoursMap = {
        "Saturday": workingTime,
        "Sunday": workingTime,
        "Monday": workingTime,
        "Tuesday": workingTime,
        "Wednesday": workingTime,
        "Thursday": workingTime,
        "Friday": workingTime,
      };

      final model = CarwashModel(
        businessName: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        contactEmail: _emailCtrl.text.trim(),
        workingHours: workingHoursMap,
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        password: _passwordCtrl.text.trim(), // Sending Password
      );

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final email = _emailCtrl.text.trim();
      bool success = await auth.applyForCarwash(
        model.toJson(), 
        _licenseImage, 
        _ownershipImage
      );

      if (success && mounted) {
        // Navigate to OTP verification screen for carwash owner
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    VerifyOtpScreen(email: email, userType: 'carwash_owner'),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Now shows the REAL error from AuthProvider
            content: Text(auth.errorMessage ?? 'خطا در ثبت درخواست'),
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
    final isDesktop = MediaQuery.of(context).size.width > 650;

    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.secondary),
        title: const Text(
          "ثبت کارواش جدید",
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                padding:
                    isDesktop
                        ? const EdgeInsets.all(40)
                        : const EdgeInsets.all(0),
                decoration:
                    isDesktop
                        ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.shade900.withOpacity(0.05),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        )
                        : null,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("اطلاعات پایه", Icons.info_outline),
                      const SizedBox(height: 16),

                      CustomInput(
                        label: "نام کسب و کار",
                        hint: "کارواش نمونه",
                        icon: Icons.store,
                        controller: _nameCtrl,
                        // NEW: Validate Name Length
                        validator:
                            (v) =>
                                (v == null || v.length < 3)
                                    ? 'نام کسب و کار باید حداقل ۳ حرف باشد'
                                    : null,
                      ),
                      CustomInput(
                        label: "تلفن تماس",
                        hint: "0912...",
                        icon: Icons.phone,
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        // NEW: Validate Iranian Mobile Format
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'شماره تلفن الزامی است';
                          }
                          final phoneRegex = RegExp(r'^09[0-9]{9}$');
                          if (!phoneRegex.hasMatch(v)) {
                            return 'شماره موبایل معتبر نیست (مثال: ۰۹۱۲۳۴۵۶۷۸۹)';
                          }
                          return null;
                        },
                      ),
                      CustomInput(
                        label: "ایمیل مالک (نام کاربری)",
                        hint: "example@mail.com",
                        icon: Icons.email,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        // NEW: Validate Email Format
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'ایمیل الزامی است';
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(v)) {
                            return 'فرمت ایمیل صحیح نیست';
                          }
                          return null;
                        },
                      ),

                      // --- Password Fields ---
                      CustomInput(
                        label: "رمز عبور",
                        hint: "حداقل ۸ کاراکتر",
                        icon: Icons.lock_outline,
                        controller: _passwordCtrl,
                        isPassword: true,
                        validator:
                            (v) =>
                                (v != null && v.length < 8)
                                    ? 'رمز عبور کوتاه است'
                                    : null,
                      ),
                      CustomInput(
                        label: "تکرار رمز عبور",
                        hint: "تکرار رمز",
                        icon: Icons.lock_outline,
                        controller: _confirmPasswordCtrl,
                        isPassword: true,
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      _buildSectionTitle("موقعیت و زمان", Icons.map),
                      const SizedBox(height: 16),

                      CustomInput(
                        label: "آدرس دقیق",
                        hint: "تهران، خیابان...",
                        icon: Icons.location_city,
                        controller: _addressCtrl,
                        maxLines: 2,
                      ),

                      // MAP PICKER
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "موقعیت روی نقشه",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                    textDirection: TextDirection.ltr,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (ctx) => MapPickerScreen(
                                          initialLat:
                                              _selectedLocation.latitude,
                                          initialLng:
                                              _selectedLocation.longitude,
                                        ),
                                  ),
                                );

                                if (result != null && result is LatLng) {
                                  setState(() {
                                    _selectedLocation = result;
                                  });
                                }
                              },
                              child: const Text(
                                "انتخاب",
                                style: TextStyle(color: AppColors.secondary),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        "ساعات کاری",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: CustomInput(
                              label: "شروع",
                              hint: "09:00",
                              icon: Icons.wb_sunny_outlined,
                              controller: _openTimeCtrl,
                              readOnly: true,
                              onTap: () => _selectTime(_openTimeCtrl),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomInput(
                              label: "پایان",
                              hint: "21:00",
                              icon: Icons.nightlight_round,
                              controller: _closeTimeCtrl,
                              readOnly: true,
                              onTap: () => _selectTime(_closeTimeCtrl),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      _buildSectionTitle("مدارک هویتی", Icons.folder_shared_outlined),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildUploadBox(
                              title: "جواز کسب",
                              image: _licenseImage,
                              onTap: () => _pickImage(true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildUploadBox(
                              title: "سند/اجاره‌نامه",
                              image: _ownershipImage,
                              onTap: () => _pickImage(false),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            activeColor: AppColors.secondary,
                            onChanged:
                                (value) =>
                                    setState(() => _acceptedTerms = value!),
                          ),
                          const Expanded(
                            child: Text(
                              "قوانین و شرایط همکاری را می‌پذیرم",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      CustomButton(
                        text: "ارسال درخواست ثبت",
                        onPressed: _submit,
                        isLoading: isLoading,
                        color: AppColors.secondary,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadBox({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(image, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, 
                       size: 32, color: AppColors.secondary),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "انتخاب فایل",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
      ),
    );
  }
}
