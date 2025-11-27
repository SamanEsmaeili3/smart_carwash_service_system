import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart'; // For coordinates
import '../../providers/auth_provider.dart';
import '../../models/carwash_model.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';
import '../map_picker_screen.dart'; // Import your new map screen

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
  
  // Clock controllers
  final _openTimeCtrl = TextEditingController(text: "09:00");
  final _closeTimeCtrl = TextEditingController(text: "21:00");

  // Location State (Default: Tehran)
  LatLng _selectedLocation = const LatLng(35.7594, 51.4103);

  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _openTimeCtrl.dispose();
    _closeTimeCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً قوانین را بپذیرید')),
        );
        return;
      }

      // 1. create clock format
      String workingTime =
          "${_openTimeCtrl.text.trim()}-${_closeTimeCtrl.text.trim()}";

      Map<String, String> workingHoursMap = {
        "Saturday": workingTime,
        "Sunday": workingTime,
        "Monday": workingTime,
        "Tuesday": workingTime,
        "Wednesday": workingTime,
        "Thursday": workingTime,
        "Friday": "Closed",
      };

      // 2. create model (Using REAL map coordinates)
      final model = CarwashModel(
        businessName: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        contactEmail: _emailCtrl.text.trim(),
        workingHours: workingHoursMap,
        licensePhotoUrl: "https://example.com/license.jpg",
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      );

      // 3. send to server
      final auth = Provider.of<AuthProvider>(context, listen: false);
      bool success = await auth.applyForCarwash(model.toJson());

      if (success && mounted) {
        // Success Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("درخواست ثبت شد", textAlign: TextAlign.center),
            content: const Text(
              "درخواست شما با موفقیت دریافت شد.\nنتیجه بررسی و رمز عبور حساب کاربری، به ایمیل شما ارسال خواهد شد.",
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false); // Go to Landing
                  },
                  child: const Text("متوجه شدم", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'خطا در ثبت درخواست'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().status == AuthStatus.loading;
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
          style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                padding: isDesktop 
                    ? const EdgeInsets.all(40)
                    : const EdgeInsets.all(0),
                decoration: isDesktop 
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.shade900.withOpacity(0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        )
                      ]
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
                      ),
                      CustomInput(
                        label: "تلفن تماس",
                        hint: "021...",
                        icon: Icons.phone,
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                      ),
                      CustomInput(
                        label: "ایمیل مالک (جهت دریافت رمز عبور)",
                        hint: "example@mail.com",
                        icon: Icons.email,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@'))
                              ? 'ایمیل معتبر نیست'
                              : null,
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      _buildSectionTitle("موقعیت مکانی", Icons.map),
                      const SizedBox(height: 16),
                      
                      CustomInput(
                        label: "آدرس دقیق",
                        hint: "تهران، خیابان...",
                        icon: Icons.location_city,
                        controller: _addressCtrl,
                        maxLines: 2,
                      ),

                      // --- MAP PICKER (Moved Here) ---
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
                            const Icon(Icons.location_on, color: AppColors.secondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("انتخاب روی نقشه", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    "${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}",
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    textDirection: TextDirection.ltr, // Keep numbers readable
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                // Open Map Screen
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => MapPickerScreen(
                                      initialLat: _selectedLocation.latitude,
                                      initialLng: _selectedLocation.longitude,
                                    ),
                                  ),
                                );

                                // Update if user confirmed
                                if (result != null && result is LatLng) {
                                  setState(() {
                                    _selectedLocation = result;
                                  });
                                }
                              }, 
                              child: const Text("انتخاب", style: TextStyle(color: AppColors.secondary)),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      const Text("ساعات کاری", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: CustomInput(
                              label: "شروع",
                              hint: "09:00",
                              icon: Icons.wb_sunny_outlined,
                              controller: _openTimeCtrl,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomInput(
                              label: "پایان",
                              hint: "21:00",
                              icon: Icons.nightlight_round,
                              controller: _closeTimeCtrl,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Rules
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            activeColor: AppColors.secondary,
                            onChanged: (value) =>
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
}