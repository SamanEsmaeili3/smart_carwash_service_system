import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/carwash_service_provider.dart';
import '../../providers/carwash_profile_provider.dart';
import '../../models/carwash_service_model.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';

class CarwashHomeScreen extends StatefulWidget {
  const CarwashHomeScreen({super.key});

  @override
  State<CarwashHomeScreen> createState() => _CarwashHomeScreenState();
}

class _CarwashHomeScreenState extends State<CarwashHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch services when screen loads (API: GET /api/carwash/services/)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CarwashServiceProvider>(
        context,
        listen: false,
      ).fetchServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? "مدیریت سرویس‌ها" : "پروفایل و تنظیمات",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.secondary, // Purple for Carwash Panel
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _selectedIndex == 0 ? const _ServicesTab() : const _ProfileTab(),
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                onPressed: () => _showAddServiceSheet(context),
                backgroundColor: AppColors.secondary,
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.secondary,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "سرویس‌ها"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "پروفایل"),
        ],
      ),
    );
  }

  // --- Add Service Modal (API: POST /api/carwash/services/) ---
  void _showAddServiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full screen height for keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: const _AddServiceForm(),
          ),
    );
  }
}

// ==========================================
// TAB 1: SERVICES LIST
// ==========================================
class _ServicesTab extends StatelessWidget {
  const _ServicesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<CarwashServiceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.services.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.services.isEmpty) {
          return const Center(child: Text("هنوز سرویسی ثبت نکرده‌اید."));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchServices(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.services.length,
            itemBuilder: (ctx, index) {
              final service = provider.services[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    service.serviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        service.description,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${service.price} تومان",
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    onPressed:
                        () => _confirmDelete(context, provider, service.id!),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    CarwashServiceProvider provider,
    int id,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("حذف سرویس"),
            content: const Text("آیا از حذف این سرویس مطمئن هستید؟"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("انصراف"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  // API: DELETE /api/carwash/services/<id>/
                  await provider.deleteService(id);
                },
                child: const Text("حذف", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}

// ==========================================
// TAB 2: PROFILE & PASSWORD UPDATE
// ==========================================
class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<CarwashProfileProvider>(
        context,
        listen: false,
      );

      // API: PATCH /api/carwash/profile/me/
      final success = await provider.updateProfile(
        businessName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : null,
        phoneNumber: _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : null,
        address: _addressCtrl.text.isNotEmpty ? _addressCtrl.text : null,
        newPassword: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("اطلاعات با موفقیت بروزرسانی شد"),
            backgroundColor: AppColors.success,
          ),
        );
        _passwordCtrl.clear(); // Clear password after success
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? "خطا در بروزرسانی"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<CarwashProfileProvider>().isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ویرایش اطلاعات کارواش",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            CustomInput(
              label: "نام جدید کسب و کار",
              hint: "خالی بگذارید اگر تغییری ندارد",
              icon: Icons.store,
              controller: _nameCtrl,
            ),
            CustomInput(
              label: "شماره تماس جدید",
              hint: "خالی بگذارید اگر تغییری ندارد",
              icon: Icons.phone,
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
            ),
            CustomInput(
              label: "آدرس جدید",
              hint: "خالی بگذارید اگر تغییری ندارد",
              icon: Icons.map,
              controller: _addressCtrl,
              maxLines: 2,
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            const Text(
              "تغییر رمز عبور (اختیاری)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            CustomInput(
              label: "رمز عبور جدید",
              hint: "فقط اگر قصد تغییر دارید پر کنید",
              icon: Icons.lock,
              controller: _passwordCtrl,
              isPassword: true,
              validator: (v) {
                if (v != null && v.isNotEmpty && v.length < 8)
                  return "رمز عبور باید حداقل ۸ رقم باشد";
                return null;
              },
            ),

            const SizedBox(height: 24),
            CustomButton(
              text: "ذخیره تغییرات",
              onPressed: _updateProfile,
              isLoading: isLoading,
              color: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ADD SERVICE FORM WIDGET
// ==========================================
class _AddServiceForm extends StatefulWidget {
  const _AddServiceForm();

  @override
  State<_AddServiceForm> createState() => _AddServiceFormState();
}

class _AddServiceFormState extends State<_AddServiceForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<CarwashServiceProvider>(
        context,
        listen: false,
      );

      final newService = CarwashServiceModel(
        serviceName: _nameCtrl.text,
        description: _descCtrl.text,
        price: int.parse(_priceCtrl.text),
      );

      // API: POST /api/carwash/services/
      final success = await provider.addService(newService);

      if (success && mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("سرویس جدید اضافه شد"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<CarwashServiceProvider>().isLoading;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "افزودن سرویس جدید",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),
          CustomInput(
            label: "نام سرویس",
            hint: "مثال: روشویی نانو",
            icon: Icons.cleaning_services,
            controller: _nameCtrl,
          ),
          CustomInput(
            label: "توضیحات",
            hint: "توضیحات کوتاه",
            icon: Icons.description,
            controller: _descCtrl,
          ),
          CustomInput(
            label: "قیمت (تومان)",
            hint: "150000",
            icon: Icons.attach_money,
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            validator:
                (v) =>
                    (v == null || int.tryParse(v) == null)
                        ? "قیمت معتبر وارد کنید"
                        : null,
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: "افزودن",
            onPressed: _submit,
            isLoading: isLoading,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}
