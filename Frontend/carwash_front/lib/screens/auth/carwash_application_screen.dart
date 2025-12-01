import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/auth_provider.dart';
import '../../models/carwash_model.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';
import '../map_picker_screen.dart';

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

  // --- 🕒 NEW: Time Picker Logic ---
  Future<void> _selectTime(TextEditingController controller) async {
    // Parse current text to set initial time, or default to 09:00
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
        // Force 24-hour format and custom colors
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.secondary, // Header background color
                onPrimary: Colors.white, // Header text color
                onSurface: AppColors.textMain, // Body text color
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      // Format to HH:mm (e.g., 08:05 instead of 8:5)
      final String formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      setState(() {
        controller.text = formattedTime;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً قوانین را بپذیرید')),
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
        "Friday": "Closed",
      };

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

      final auth = Provider.of<AuthProvider>(context, listen: false);
      bool success = await auth.applyForCarwash(model.toJson());

      if (success && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  "درخواست ثبت شد",
                  textAlign: TextAlign.center,
                ),
                content: const Text(
                  "درخواست شما با موفقیت دریافت شد.\nنتیجه بررسی و رمز عبور حساب کاربری، به ایمیل شما ارسال خواهد شد.",
                  textAlign: TextAlign.center,
                ),
                actions: [
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "متوجه شدم",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                        validator:
                            (v) =>
                                (v == null || !v.contains('@'))
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
                                    "انتخاب روی نقشه",
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
                      // --- 🕒 NEW: Working Hours Section ---
                      _buildSectionTitle("ساعات کاری", Icons.access_time),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomInput(
                              label: "شروع",
                              hint: "09:00",
                              icon: Icons.wb_sunny_outlined,
                              controller: _openTimeCtrl,
                              readOnly: true, // Prevent keyboard
                              onTap:
                                  () =>
                                      _selectTime(_openTimeCtrl), // Open Picker
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomInput(
                              label: "پایان",
                              hint: "21:00",
                              icon: Icons.nightlight_round,
                              controller: _closeTimeCtrl,
                              readOnly: true, // Prevent keyboard
                              onTap:
                                  () => _selectTime(
                                    _closeTimeCtrl,
                                  ), // Open Picker
                            ),
                          ),
                        ],
                      ),

                      // -------------------------------------
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
}
