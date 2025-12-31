import 'package:carwash_front/services/utiles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/carwash_service_provider.dart';
import '../../providers/carwash_profile_provider.dart';
import '../../models/carwash_service_model.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart'; 
import 'dart:io'; 
import 'package:image_picker/image_picker.dart'; 
import '../../providers/driver_provider.dart'; 
import '../../models/driver_model.dart'; 


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
    // Fetch services when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CarwashServiceProvider>(
        context,
        listen: false,
      ).fetchServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    String title = "مدیریت سرویس‌ها";
    if (_selectedIndex == 1) title = "مدیریت رانندگان";
    if (_selectedIndex == 2) title = "پروفایل و تنظیمات";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            Provider.of<AuthProvider>(context, listen: false).logout();
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _getBody(), 
        ),
      ),
      floatingActionButton: _selectedIndex < 2
          ? FloatingActionButton(
              onPressed: () {
                if (_selectedIndex == 0) _showAddServiceSheet(context);
                if (_selectedIndex == 1) _showAddDriverSheet(context); 
              },
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
          BottomNavigationBarItem(icon: Icon(Icons.drive_eta), label: "رانندگان"), 
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "پروفایل"),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _ServicesTab(onEdit: _showAddServiceSheet);
      case 1:
        return const _DriversTab(); 
      case 2:
        return const _ProfileTab();
      default:
        return _ServicesTab(onEdit: _showAddServiceSheet);
    }
  }

  // --- MODIFIED: Accepts optional serviceToEdit ---
  void _showAddServiceSheet(BuildContext context, {CarwashServiceModel? serviceToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              // Pass the service to the form
              child: _AddServiceForm(serviceToEdit: serviceToEdit),
            ),
          ),
        );
      },
    );
  }

  void _showAddDriverSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: const _AddDriverForm(), 
        );
      },
    );
  }
}

// ==========================================
// TAB 1: SERVICES LIST
// ==========================================
class _ServicesTab extends StatelessWidget {
  // Add a callback so we can tell the parent to open the modal
  final Function(BuildContext, {CarwashServiceModel? serviceToEdit})? onEdit;
  
  const _ServicesTab({this.onEdit});

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
                        "${formatMoney(service.price)} تومان",
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- NEW EDIT BUTTON ---
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          if (onEdit != null) {
                            onEdit!(context, serviceToEdit: service);
                          }
                        },
                      ),
                      // --- EXISTING DELETE BUTTON ---
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () =>
                            _confirmDelete(context, provider, service.id!),
                      ),
                    ],
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
      builder: (ctx) => AlertDialog(
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
// (KEEP THIS PART THE SAME AS YOUR ORIGINAL CODE - NO CHANGES NEEDED HERE)
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

      final success = await provider.updateProfile(
        businessName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : null,
        phoneNumber: _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : null,
        address: _addressCtrl.text.isNotEmpty ? _addressCtrl.text : null,
        newPassword:
            _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("اطلاعات با موفقیت بروزرسانی شد"),
            backgroundColor: AppColors.success,
          ),
        );
        _passwordCtrl.clear();
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
                if (v != null && v.isNotEmpty && v.length < 8) {
                  return "رمز عبور باید حداقل ۸ رقم باشد";
                }
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
// ADD / EDIT SERVICE FORM WIDGET
// ==========================================
class _AddServiceForm extends StatefulWidget {
  final CarwashServiceModel? serviceToEdit; // NEW: Optional service for editing

  const _AddServiceForm({this.serviceToEdit});

  @override
  State<_AddServiceForm> createState() => _AddServiceFormState();
}

// ==========================================
// TAB 2: DRIVERS LIST (NEW SECTION)
// ==========================================
class _DriversTab extends StatefulWidget {
  const _DriversTab();

  @override
  State<_DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends State<_DriversTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DriverProvider>(context, listen: false).fetchDrivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        
        if (provider.drivers.isEmpty) {
          return const Center(child: Text("راننده‌ای ثبت نشده است."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.drivers.length,
          itemBuilder: (ctx, index) {
            final driver = provider.drivers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
                  backgroundImage: driver.personnelPhoto != null 
                      ? NetworkImage(driver.personnelPhoto!) 
                      : null,
                  child: driver.personnelPhoto == null 
                      ? const Icon(Icons.person, color: AppColors.secondary) 
                      : null,
                ),
                title: Text(driver.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("کدملی: ${driver.nationalId}\nتماس: ${driver.phoneNumber}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, provider, driver.id!),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, DriverProvider provider, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("حذف راننده"),
        content: const Text("آیا مطمئن هستید؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("خیر")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteDriver(id);
            },
            child: const Text("بله، حذف شود", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// FORM: ADD DRIVER WIDGET
// ==========================================
class _AddDriverForm extends StatefulWidget {
  const _AddDriverForm();

  @override
  State<_AddDriverForm> createState() => _AddDriverFormState();
}

class _AddDriverFormState extends State<_AddDriverForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  File? _imageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<DriverProvider>(context, listen: false);
      
      final newDriver = DriverModel(
        fullName: _nameCtrl.text,
        nationalId: _nationalIdCtrl.text,
        phoneNumber: _phoneCtrl.text,
        address: _addressCtrl.text,
      );

      final success = await provider.addDriver(newDriver, _imageFile);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("راننده با موفقیت افزوده شد"), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<DriverProvider>().isLoading;

    return Form(
      key: _formKey,
      child: SingleChildScrollView( 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("افزودن راننده جدید", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null 
                    ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey) 
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text("تصویر پرسنلی (اختیاری)", style: TextStyle(fontSize: 12, color: Colors.grey)),
            
            const SizedBox(height: 16),
            CustomInput(label: "نام و نام خانوادگی", icon: Icons.person, controller: _nameCtrl),
            CustomInput(
              label: "کد ملی", 
              icon: Icons.badge, 
              controller: _nationalIdCtrl, 
              keyboardType: TextInputType.number,
              validator: (v) => (v != null && v.length == 10) ? null : "کد ملی باید ۱۰ رقم باشد",
            ),
            CustomInput(
              label: "شماره تماس", 
              icon: Icons.phone, 
              controller: _phoneCtrl, 
              keyboardType: TextInputType.phone
            ),
            CustomInput(label: "آدرس", icon: Icons.location_on, controller: _addressCtrl, maxLines: 2),
            
            const SizedBox(height: 20),
            CustomButton(
              text: "ثبت راننده", 
              onPressed: _submit, 
              isLoading: isLoading, 
              color: AppColors.secondary
            ),
          ],
        ),
      ),
    );
  }
}

class _AddServiceFormState extends State<_AddServiceForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // NEW: If we are editing, pre-fill the fields!
    if (widget.serviceToEdit != null) {
      _nameCtrl.text = widget.serviceToEdit!.serviceName;
      _descCtrl.text = widget.serviceToEdit!.description;
      // Convert double price to string, removing ".0" if it's a clean integer
      _priceCtrl.text = widget.serviceToEdit!.price.toString().replaceAll(RegExp(r'\.0$'), '');
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<CarwashServiceProvider>(
        context,
        listen: false,
      );

      String cleanPriceStr =
          _priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
      double finalPrice = double.tryParse(cleanPriceStr) ?? 0.0;

      if (finalPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("قیمت نامعتبر است"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final serviceData = CarwashServiceModel(
        id: widget.serviceToEdit?.id, // Keep ID if editing
        serviceName: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: finalPrice,
      );

      bool success;
      // NEW: Check if we are Adding or Updating
      if (widget.serviceToEdit == null) {
        // --- ADD MODE ---
        success = await provider.addService(serviceData);
      } else {
        // --- EDIT MODE ---
        // Force unwrap ID because we know it exists in edit mode
        success = await provider.updateService(widget.serviceToEdit!.id!, serviceData);
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.serviceToEdit == null 
                ? "سرویس با موفقیت ثبت شد" 
                : "سرویس با موفقیت ویرایش شد"
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<CarwashServiceProvider>().isLoading;
    // Dynamic Title and Button Text
    final isEditing = widget.serviceToEdit != null;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isEditing ? "ویرایش سرویس" : "افزودن سرویس جدید",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),
          CustomInput(
            label: "نام سرویس",
            hint: "مثال: روشویی",
            icon: Icons.cleaning_services,
            controller: _nameCtrl,
          ),
          CustomInput(
            label: "توضیحات",
            hint: "توضیحات...",
            icon: Icons.description,
            controller: _descCtrl,
          ),
          CustomInput(
            label: "قیمت",
            hint: "150000",
            icon: Icons.attach_money,
            controller: _priceCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.isEmpty) return "قیمت الزامی است";
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: isEditing ? "ذخیره تغییرات" : "افزودن",
            onPressed: _submit,
            isLoading: isLoading,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

