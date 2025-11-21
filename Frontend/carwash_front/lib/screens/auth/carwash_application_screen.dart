import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/carwash_model.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';

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
  //TODO remove static clock and location controllers
  //clock controllers
  final _openTimeCtrl = TextEditingController(text: "09:00");
  final _closeTimeCtrl = TextEditingController(text: "21:00");

  //Location controllers
  final _latCtrl = TextEditingController(text: "35.759432");
  final _lngCtrl = TextEditingController(text: "51.410376");

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _openTimeCtrl.dispose();
    _closeTimeCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      //1. create clock format
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

      //2.convert locations
      double lat = double.tryParse(_latCtrl.text.trim()) ?? 0.0;
      double lng = double.tryParse(_lngCtrl.text.trim()) ?? 0.0;

      //3. create model
      final model = CarwashModel(
        businessName: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        contactEmail: _emailCtrl.text.trim(),
        workingHours: workingHoursMap,
        licensePhotoUrl: "https://example.com/license.jpg",
        latitude: lat,
        longitude: lng,
      );

      //4. send to server
      final auth = Provider.of<AuthProvider>(context, listen: false);
      bool success = await auth.applyForCarwash(model.toJson());

      if (success && mounted) {
        // Display success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ثبت‌نام با موفقیت انجام شد'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // *** Main change: redirect to the car wash home page ***
        // Use pushNamedAndRemoveUntil to prevent the user from returning to the registration page with the back button
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/carwash',
          (route) => false,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("درخواست ثبت کارواش"),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "اطلاعات پایه",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              CustomInput(
                label: "نام کسب و کار",
                hint: "کارواش نمونه",
                icon: Icons.store,
                controller: _nameCtrl,
              ),
              CustomInput(
                label: "آدرس",
                hint: "تهران...",
                icon: Icons.map,
                controller: _addressCtrl,
              ),
              CustomInput(
                label: "تلفن تماس",
                hint: "021...",
                icon: Icons.phone,
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              CustomInput(
                label: "ایمیل مالک",
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

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              const Text(
                "ساعات کاری",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CustomInput(
                      label: "شروع",
                      hint: "09:00",
                      icon: Icons.access_time,
                      controller: _openTimeCtrl,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomInput(
                      label: "پایان",
                      hint: "21:00",
                      icon: Icons.access_time_filled,
                      controller: _closeTimeCtrl,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),

              const Text(
                "موقعیت مکانی",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CustomInput(
                      label: "عرض (Lat)",
                      hint: "35.xxx",
                      icon: Icons.location_on,
                      controller: _latCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomInput(
                      label: "طول (Lng)",
                      hint: "51.xxx",
                      icon: Icons.location_on_outlined,
                      controller: _lngCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              CustomButton(
                text: "ارسال نهایی و ورود",
                onPressed: _submit,
                isLoading: isLoading,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
