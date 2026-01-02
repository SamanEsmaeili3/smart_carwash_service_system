import 'package:carwash_front/services/utiles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../providers/carwash_service_provider.dart';
import '../../providers/carwash_profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/order_owner_provider.dart';
import '../../models/carwash_service_model.dart';
import '../../models/driver_model.dart';
import '../../models/order_owner_model.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';

// Shared Status Utilities
class _OrderStatusUtils {
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'EN_ROUTE':
        return Colors.purple;
      case 'IN_SERVICE':
        return Colors.indigo;
      case 'COMPLETE':
        return Colors.green;
      case 'REJECTED':
      case 'CANCELLED':
        return Colors.red;
      case 'PENDING':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  static String getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'در انتظار';
      case 'SUBMITTED':
        return 'در انتظار تایید';
      case 'ACCEPTED':
        return 'تایید شده';
      case 'REJECTED':
        return 'رد شده';
      case 'EN_ROUTE':
        return 'در راه به کارواش';
      case 'IN_SERVICE':
        return 'در حال سرویس دهی';
      case 'COMPLETE':
        return 'بازگرداندن خودرو به مشتری';
      case 'CANCELLED':
        return 'لغو شده';
      default:
        return status;
    }
  }
}

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

  String get _appBarTitle {
    const titles = [
      "مدیریت سرویس‌ها",
      "مدیریت رانندگان",
      "پروفایل و تنظیمات",
      "سفارش‌های ورودی",
    ];
    return titles[_selectedIndex.clamp(0, titles.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            Provider.of<AuthProvider>(context, listen: false).logout();
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _getBody(),
        ),
      ),
      floatingActionButton:
          _selectedIndex < 2
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
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.secondary,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Fetch orders when switching to orders tab
            if (index == 3) {
              Provider.of<OrderOwnerProvider>(
                context,
                listen: false,
              ).fetchOrders();
            }
            // Fetch profile when switching to profile tab
            if (index == 2) {
              Provider.of<CarwashProfileProvider>(
                context,
                listen: false,
              ).fetchProfile();
            }
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "سرویس‌ها"),
          BottomNavigationBarItem(
            icon: Icon(Icons.drive_eta),
            label: "رانندگان",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "پروفایل"),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "سفارش‌ها",
          ),
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
      case 3:
        return const _OrdersTab();
      default:
        return _ServicesTab(onEdit: _showAddServiceSheet);
    }
  }

  void _showAddServiceSheet(
    BuildContext context, {
    CarwashServiceModel? serviceToEdit,
  }) {
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
              child: _AddServiceForm(serviceToEdit: serviceToEdit),
            ),
          ),
        );
      },
    );
  }

  void _showAddDriverSheet(BuildContext context, {Driver? driverToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: _AddDriverForm(driverToEdit: driverToEdit),
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
                        onPressed:
                            () => onEdit?.call(context, serviceToEdit: service),
                      ),
                      // --- EXISTING DELETE BUTTON ---
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed:
                            () =>
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

  // Working hours controllers for each day
  final Map<String, TextEditingController> _workingHoursControllers = {};

  // ✅ FIX: Keys MUST be Capitalized (Saturday, not saturday) to match Booking Logic
  final Map<String, bool> _openDays = {
    'Saturday': false,
    'Sunday': false,
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
  };

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for all days
    for (final day in _openDays.keys) {
      _workingHoursControllers[day] = TextEditingController();
    }
    // Fetch profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    for (final ctrl in _workingHoursControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final provider = Provider.of<CarwashProfileProvider>(
      context,
      listen: false,
    );

    final success = await provider.fetchProfile();
    if (success && provider.currentProfile != null && mounted) {
      final profile = provider.currentProfile!;

      // Pre-fill basic info
      _nameCtrl.text = profile['business_name']?.toString() ?? '';
      _phoneCtrl.text = profile['phone_number']?.toString() ?? '';
      _addressCtrl.text = profile['address']?.toString() ?? '';

      // Pre-fill working hours
      final workingHours = profile['working_hours'];
      if (workingHours is Map) {
        workingHours.forEach((day, hours) {
          // ✅ FIX: Convert any saved lowercase keys to Title Case for UI
          String dayKey = day.toString();
          if (dayKey.isNotEmpty) {
            dayKey =
                dayKey[0].toUpperCase() + dayKey.substring(1).toLowerCase();
          }

          if (_workingHoursControllers.containsKey(dayKey)) {
            _workingHoursControllers[dayKey]!.text = hours.toString();
            // If text is not empty and not "Closed", mark as open
            _openDays[dayKey] =
                (hours.toString().isNotEmpty && hours.toString() != "Closed");
          }
        });
      }

      setState(() => _isInitialized = true);
    } else if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<CarwashProfileProvider>(
        context,
        listen: false,
      );

      // Build working hours map
      final Map<String, String> workingHours = {};
      for (final entry in _openDays.entries) {
        // If day is checked and has time, send time. Else send "Closed".
        if (entry.value) {
          final hours = _workingHoursControllers[entry.key]!.text.trim();
          if (hours.isNotEmpty) {
            workingHours[entry.key] = hours;
          } else {
            // If checked but no time set, default to 09:00-21:00
            workingHours[entry.key] = "09:00-21:00";
          }
        } else {
          workingHours[entry.key] = "Closed";
        }
      }

      final success = await provider.updateProfile(
        businessName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : null,
        phoneNumber: _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : null,
        address: _addressCtrl.text.isNotEmpty ? _addressCtrl.text : null,
        newPassword: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
        workingHours: workingHours.isNotEmpty ? workingHours : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("اطلاعات و ساعات کاری با موفقیت بروزرسانی شد"),
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

  String _getDayName(String dayKey) {
    // ✅ FIX: Keys here must also match the Capitalized keys above
    const dayNames = {
      'Saturday': 'شنبه',
      'Sunday': 'یکشنبه',
      'Monday': 'دوشنبه',
      'Tuesday': 'سه‌شنبه',
      'Wednesday': 'چهارشنبه',
      'Thursday': 'پنج‌شنبه',
      'Friday': 'جمعه',
    };
    return dayNames[dayKey] ?? dayKey;
  }

  Future<void> _selectTime(BuildContext context, String dayKey) async {
    final controller = _workingHoursControllers[dayKey]!;
    final currentTime = controller.text;

    // Parse existing time if available (format: "09:00-18:00")
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    if (currentTime.isNotEmpty && currentTime.contains('-')) {
      final parts = currentTime.split('-');
      if (parts.length == 2) {
        final startParts = parts[0].trim().split(':');
        final endParts = parts[1].trim().split(':');
        if (startParts.length == 2 && endParts.length == 2) {
          startTime = TimeOfDay(
            hour: int.tryParse(startParts[0]) ?? 9,
            minute: int.tryParse(startParts[1]) ?? 0,
          );
          endTime = TimeOfDay(
            hour: int.tryParse(endParts[0]) ?? 18,
            minute: int.tryParse(endParts[1]) ?? 0,
          );
        }
      }
    }

    // Show time picker for start time
    final pickedStart = await showTimePicker(
      context: context,
      initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0),
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

    if (pickedStart != null) {
      if (!context.mounted) return;
      // Show time picker for end time
      final pickedEnd = await showTimePicker(
        context: context,
        initialTime: endTime ?? const TimeOfDay(hour: 18, minute: 0),
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

      if (pickedEnd != null) {
        final startStr =
            '${pickedStart.hour.toString().padLeft(2, '0')}:${pickedStart.minute.toString().padLeft(2, '0')}';
        final endStr =
            '${pickedEnd.hour.toString().padLeft(2, '0')}:${pickedEnd.minute.toString().padLeft(2, '0')}';
        controller.text = '$startStr-$endStr';
        setState(() => _openDays[dayKey] = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CarwashProfileProvider>();
    final isLoading = provider.isLoading;
    final isLoadingProfile = provider.isLoadingProfile;

    if (isLoadingProfile && !_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "اطلاعات عمومی",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            CustomInput(
              label: "نام کسب و کار",
              hint:
                  "نام فعلی: ${provider.currentProfile?['business_name'] ?? 'نامشخص'}",
              icon: Icons.store,
              controller: _nameCtrl,
            ),
            CustomInput(
              label: "شماره تماس",
              hint:
                  "شماره فعلی: ${provider.currentProfile?['phone_number'] ?? 'نامشخص'}",
              icon: Icons.phone,
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
            ),
            CustomInput(
              label: "آدرس",
              hint:
                  "آدرس فعلی: ${provider.currentProfile?['address'] ?? 'نامشخص'}",
              icon: Icons.map,
              controller: _addressCtrl,
              maxLines: 2,
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // --- WORKING HOURS UI ---
            const Text(
              "ساعات کاری و روزهای فعالیت",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),

            ..._openDays.keys.map((dayKey) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _openDays[dayKey],
                            onChanged: (value) {
                              setState(() {
                                _openDays[dayKey] = value ?? false;
                                if (!_openDays[dayKey]!) {
                                  _workingHoursControllers[dayKey]!.clear();
                                } else {
                                  // Auto fill if empty when checking
                                  if (_workingHoursControllers[dayKey]!
                                      .text
                                      .isEmpty) {
                                    _workingHoursControllers[dayKey]!.text =
                                        "09:00-21:00";
                                  }
                                }
                              });
                            },
                          ),
                          Text(
                            _getDayName(dayKey),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (_openDays[dayKey]!) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _workingHoursControllers[dayKey],
                                decoration: InputDecoration(
                                  labelText: "ساعات کاری (مثال: 09:00-21:00)",
                                  hintText: "09:00-18:00",
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.access_time),
                                    onPressed:
                                        () => _selectTime(context, dayKey),
                                  ),
                                ),
                                readOnly: true,
                                onTap: () => _selectTime(context, dayKey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            const Text(
              "تغییر رمز عبور (اختیاری)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: "ذخیره تغییرات",
                onPressed: _updateProfile,
                isLoading: isLoading,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddServiceForm extends StatefulWidget {
  final CarwashServiceModel? serviceToEdit; // NEW: Optional service for editing

  const _AddServiceForm({this.serviceToEdit});

  @override
  State<_AddServiceForm> createState() => _AddServiceFormState();
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
      _priceCtrl.text = widget.serviceToEdit!.price.toString().replaceAll(
        RegExp(r'\.0$'),
        '',
      );
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<CarwashServiceProvider>(
        context,
        listen: false,
      );

      String cleanPriceStr = _priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
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
        id: widget.serviceToEdit?.id,
        serviceName: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: finalPrice,
      );

      final success =
          widget.serviceToEdit == null
              ? await provider.addService(serviceData)
              : await provider.updateService(
                widget.serviceToEdit!.id!,
                serviceData,
              );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.serviceToEdit == null
                  ? "سرویس با موفقیت ثبت شد"
                  : "سرویس با موفقیت ویرایش شد",
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

// ==========================================
// TAB 2: DRIVERS LIST (UPDATED)
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
        if (provider.isLoading && provider.drivers.isEmpty)
          return const Center(child: CircularProgressIndicator());

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
                  backgroundImage:
                      driver.personnelPhotoUrl != null
                          ? NetworkImage(driver.personnelPhotoUrl!)
                          : null,
                  child:
                      driver.personnelPhotoUrl == null
                          ? const Icon(Icons.person, color: AppColors.secondary)
                          : null,
                ),
                title: Text(
                  driver.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "کدملی: ${driver.nationalId}\nتماس: ${driver.phoneNumber}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        final state =
                            context
                                .findAncestorStateOfType<
                                  _CarwashHomeScreenState
                                >();
                        state?._showAddDriverSheet(
                          context,
                          driverToEdit: driver,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed:
                          () => _confirmDelete(context, provider, driver.id!),
                    ),
                  ],
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
      builder:
          (ctx) => AlertDialog(
            title: const Text("حذف راننده"),
            content: const Text("آیا مطمئن هستید؟"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("خیر"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  provider.deleteDriver(id);
                },
                child: const Text(
                  "بله، حذف شود",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}

// ==========================================
// FORM: ADD / EDIT DRIVER
// ==========================================
class _AddDriverForm extends StatefulWidget {
  final Driver? driverToEdit;

  const _AddDriverForm({this.driverToEdit});

  @override
  State<_AddDriverForm> createState() => _AddDriverFormState();
}

class _AddDriverFormState extends State<_AddDriverForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _nationalIdCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;

  XFile? _imageFile;
  Uint8List? _pickedImageBytes;

  @override
  void initState() {
    super.initState();
    final d = widget.driverToEdit;
    _nameCtrl = TextEditingController(text: d?.fullName ?? '');
    _nationalIdCtrl = TextEditingController(text: d?.nationalId ?? '');
    _phoneCtrl = TextEditingController(text: d?.phoneNumber ?? '');
    _addressCtrl = TextEditingController(text: d?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _pickedImageBytes = bytes;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<DriverProvider>(context, listen: false);

      final driverData = Driver(
        id: widget.driverToEdit?.id,
        fullName: _nameCtrl.text,
        nationalId: _nationalIdCtrl.text,
        phoneNumber: _phoneCtrl.text,
        address: _addressCtrl.text,
      );

      final success =
          widget.driverToEdit == null
              ? await provider.addDriver(driverData, _imageFile)
              : await provider.editDriver(
                widget.driverToEdit!.id!,
                driverData,
                _imageFile,
              );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.driverToEdit == null
                  ? "راننده افزوده شد"
                  : "ویرایش موفقیت‌آمیز بود",
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? "خطا در عملیات"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _fixImageUrl(String url) {
    if (url.isEmpty) return "";

    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }

    if (url.startsWith('https://')) {
      return url;
    }

    return 'https://my-project-api.liara.run$url';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<DriverProvider>().isLoading;
    final isEditing = widget.driverToEdit != null;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? "ویرایش اطلاعات راننده" : "افزودن راننده جدید",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                  image:
                      _pickedImageBytes != null
                          ? DecorationImage(
                            image: MemoryImage(_pickedImageBytes!),
                            fit: BoxFit.cover,
                          )
                          : (widget.driverToEdit?.personnelPhotoUrl != null
                              ? DecorationImage(
                                image: NetworkImage(
                                  _fixImageUrl(
                                    widget.driverToEdit!.personnelPhotoUrl!,
                                  ),
                                ),
                                fit: BoxFit.cover,
                              )
                              : null),
                ),
                child:
                    (_pickedImageBytes == null &&
                            widget.driverToEdit?.personnelPhotoUrl == null)
                        ? const Icon(
                          Icons.add_a_photo,
                          size: 30,
                          color: Colors.grey,
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "تصویر پرسنلی",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 16),
            CustomInput(
              label: "نام و نام خانوادگی",
              hint: "مثال: علی رضایی",
              icon: Icons.person,
              controller: _nameCtrl,
            ),
            CustomInput(
              label: "کد ملی",
              hint: "مثال: 0012345678",
              icon: Icons.badge,
              controller: _nationalIdCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return "کد ملی الزامی است";
                if (v.length != 10) return "کد ملی باید ۱۰ رقم باشد";
                return null;
              },
            ),
            CustomInput(
              label: "شماره تماس",
              hint: "مثال: 0912...",
              icon: Icons.phone,
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) return "شماره تماس الزامی است";
                if (v.length != 11) return "شماره تماس باید ۱۱ رقم باشد";
                if (!v.startsWith("09")) return "شماره باید با 09 شروع شود";
                return null;
              },
            ),
            CustomInput(
              label: "آدرس",
              hint: "آدرس سکونت",
              icon: Icons.location_on,
              controller: _addressCtrl,
              maxLines: 2,
            ),

            const SizedBox(height: 20),
            CustomButton(
              text: isEditing ? "ذخیره تغییرات" : "ثبت راننده",
              onPressed: _submit,
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
// TAB 4: ORDERS (The Kitchen) - Sprint 4
// ==========================================
class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  String _filterType = 'all'; // 'all' or 'accepted'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderOwnerProvider>(context, listen: false).fetchOrders();
    });
  }

  List<OrderOwnerModel> _getFilteredOrders(List<OrderOwnerModel> orders) {
    if (_filterType == 'accepted') {
      return orders
          .where((order) => order.status.toUpperCase() == 'ACCEPTED')
          .toList();
    }
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderOwnerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingOrders && provider.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredOrders = _getFilteredOrders(provider.orders);

        return Column(
          children: [
            _OrderFilterSidebar(
              currentFilter: _filterType,
              onFilterChanged: (filter) => setState(() => _filterType = filter),
            ),
            Expanded(
              child:
                  filteredOrders.isEmpty
                      ? _EmptyOrdersState(
                        filterType: _filterType,
                        onRefresh: () => provider.fetchOrders(),
                      )
                      : RefreshIndicator(
                        onRefresh: () => provider.fetchOrders(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredOrders.length,
                          itemBuilder:
                              (ctx, index) =>
                                  _OrderCard(order: filteredOrders[index]),
                        ),
                      ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  final String filterType;
  final VoidCallback onRefresh;

  const _EmptyOrdersState({required this.filterType, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            filterType == 'accepted'
                ? "سفارش تایید شده‌ای وجود ندارد"
                : "هنوز سفارشی ثبت نشده است",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text("بروزرسانی"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Order Filter Sidebar
class _OrderFilterSidebar extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterChanged;

  const _OrderFilterSidebar({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: AppColors.secondary),
          const SizedBox(width: 12),
          const Text(
            'فیلتر:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                _FilterChip(
                  label: 'همه سفارش‌ها',
                  isSelected: currentFilter == 'all',
                  onTap: () => onFilterChanged('all'),
                ),
                const SizedBox(width: 12),
                _FilterChip(
                  label: 'سفارش‌های تایید شده',
                  isSelected: currentFilter == 'accepted',
                  onTap: () => onFilterChanged('accepted'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// Order Card Widget
class _OrderCard extends StatefulWidget {
  final OrderOwnerModel order;

  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  String? _customerName;
  String? _customerPhone;
  bool _isLoadingCustomerInfo = false;

  @override
  void initState() {
    super.initState();
    _fetchCustomerInfo();
  }

  Future<void> _fetchCustomerInfo() async {
    setState(() => _isLoadingCustomerInfo = true);

    final provider = Provider.of<OrderOwnerProvider>(context, listen: false);
    final customerInfo = await provider.fetchOrderCustomerInfo(widget.order.id);

    if (mounted && customerInfo != null) {
      setState(() {
        _customerName = customerInfo['customer_name'];
        _customerPhone = customerInfo['customer_phone'];
        _isLoadingCustomerInfo = false;
      });
    } else if (mounted) {
      // Fallback to order data if API fails
      setState(() {
        _customerName = widget.order.customerName;
        _customerPhone = widget.order.customerPhone;
        _isLoadingCustomerInfo = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final persianMonths = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];
    return '${dateTime.day} ${persianMonths[dateTime.month - 1]} ${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _OrderStatusUtils.getStatusColor(widget.order.status);
    final displayName = _customerName ?? widget.order.customerName;
    final displayPhone = _customerPhone ?? widget.order.customerPhone;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'سفارش #${widget.order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    _OrderStatusUtils.getStatusText(widget.order.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Customer Info Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'اطلاعات مشتری',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                            _isLoadingCustomerInfo
                                ? const SizedBox(
                                  height: 15,
                                  width: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                            _isLoadingCustomerInfo
                                ? const SizedBox(
                                  height: 13,
                                  width: 100,
                                  child: LinearProgressIndicator(),
                                )
                                : Text(
                                  displayPhone,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                ),
                      ),
                    ],
                  ),
                  if (widget.order.customerEmail != null &&
                      widget.order.customerEmail!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.order.customerEmail!,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.order.vehiclePlate != null &&
                      widget.order.vehiclePlate!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'پلاک: ${widget.order.vehiclePlate}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.order.vehicleInfo != null &&
                      widget.order.vehicleInfo!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        widget.order.vehicleInfo!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Scheduled Time
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(widget.order.scheduledTime),
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Services List
            if (widget.order.servicesList.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.cleaning_services,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'سرویس‌ها:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    widget.order.servicesList
                        .map(
                          (service) => Chip(
                            label: Text(
                              service,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: AppColors.secondary.withOpacity(
                              0.1,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),
            ],
            // Total Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'مبلغ کل:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${formatMoney(widget.order.totalPrice)} تومان',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 24),
            _OrderActions(order: widget.order),
          ],
        ),
      ),
    );
  }
}

class _OrderActions extends StatefulWidget {
  final OrderOwnerModel order;

  const _OrderActions({required this.order});

  @override
  State<_OrderActions> createState() => _OrderActionsState();
}

class _OrderActionsState extends State<_OrderActions> {
  bool _isProcessing = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isProcessing = true);
    final provider = Provider.of<OrderOwnerProvider>(context, listen: false);

    final success = await provider.updateOrderStatus(widget.order.id, status);

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'وضعیت سفارش به ${_OrderStatusUtils.getStatusText(status)} تغییر یافت',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final errorMessage =
            provider.lastStatusUpdateError ?? 'خطا در تغییر وضعیت';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _assignDriver() async {
    final provider = Provider.of<OrderOwnerProvider>(context, listen: false);

    // Fetch available drivers first
    await provider.fetchAvailableDrivers();

    if (provider.availableDrivers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('راننده‌ای در دسترس نیست'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Show driver selection dialog
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (ctx) => _DriverSelectionDialog(
              orderId: widget.order.id,
              drivers: provider.availableDrivers,
            ),
      );
    }
  }

  void _showStatusChangeDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => _StatusChangeDialog(
            currentStatus: widget.order.status,
            onStatusChanged: (newStatus) {
              Navigator.pop(ctx);
              _updateStatus(newStatus);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAccept = widget.order.status.toUpperCase() == 'SUBMITTED';
    final canAssignDriver = [
      'ACCEPTED',
      'EN_ROUTE',
    ].contains(widget.order.status.toUpperCase());

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        if (canAccept) ...[
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _updateStatus('ACCEPTED'),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('تایید'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : () => _updateStatus('REJECTED'),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('رد'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
        if (canAssignDriver)
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _assignDriver,
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('انتصاب راننده'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        if (widget.order.status.toUpperCase() == 'ACCEPTED')
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : () => _updateStatus('IN_SERVICE'),
            icon: const Icon(Icons.build, size: 18),
            label: const Text('شروع سرویس'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: BorderSide(color: AppColors.secondary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        if (widget.order.status.toUpperCase() == 'IN_SERVICE')
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _updateStatus('COMPLETE'),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('تکمیل سفارش'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        // Change Status Button - Always available
        OutlinedButton.icon(
          onPressed: _isProcessing ? null : _showStatusChangeDialog,
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('تغییر وضعیت'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondary,
            side: BorderSide(color: AppColors.secondary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }
}

// Status Change Dialog
class _StatusChangeDialog extends StatelessWidget {
  final String currentStatus;
  final Function(String) onStatusChanged;

  const _StatusChangeDialog({
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Only show the three main statuses for service workflow
    final allStatuses = ['EN_ROUTE', 'IN_SERVICE', 'COMPLETE'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تغییر وضعیت سفارش',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'وضعیت فعلی: ${_OrderStatusUtils.getStatusText(currentStatus)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allStatuses.length,
                itemBuilder: (ctx, index) {
                  final status = allStatuses[index];
                  final isCurrentStatus =
                      status.toUpperCase() == currentStatus.toUpperCase();
                  final statusColor = _OrderStatusUtils.getStatusColor(status);

                  return ListTile(
                    enabled: !isCurrentStatus,
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color:
                            isCurrentStatus
                                ? statusColor
                                : statusColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          _OrderStatusUtils.getStatusText(status),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCurrentStatus ? statusColor : null,
                            fontSize: 15,
                          ),
                        ),
                        if (isCurrentStatus) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor, width: 1),
                            ),
                            child: Text(
                              'فعلی',
                              style: TextStyle(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      status,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing:
                        isCurrentStatus
                            ? Icon(
                              Icons.check_circle,
                              color: statusColor,
                              size: 20,
                            )
                            : Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                    onTap:
                        isCurrentStatus ? null : () => onStatusChanged(status),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('انصراف'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Driver Selection Dialog
class _DriverSelectionDialog extends StatelessWidget {
  final int orderId;
  final List<DriverModel> drivers;

  const _DriverSelectionDialog({required this.orderId, required this.drivers});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'انتخاب راننده',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  drivers.isEmpty
                      ? const Center(child: Text('راننده‌ای در دسترس نیست'))
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: drivers.length,
                        itemBuilder: (ctx, index) {
                          final driver = drivers[index];
                          final isAvailable =
                              driver.status.toUpperCase() == 'AVAILABLE';

                          return ListTile(
                            enabled: isAvailable,
                            leading: CircleAvatar(
                              backgroundColor:
                                  isAvailable
                                      ? AppColors.success.withOpacity(0.2)
                                      : Colors.grey[300],
                              child: Icon(
                                Icons.person,
                                color:
                                    isAvailable
                                        ? AppColors.success
                                        : Colors.grey,
                              ),
                            ),
                            title: Text(
                              driver.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isAvailable ? null : Colors.grey,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver.phoneNumber,
                                  style: TextStyle(
                                    color:
                                        isAvailable
                                            ? Colors.grey[600]
                                            : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isAvailable
                                            ? AppColors.success.withOpacity(0.1)
                                            : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isAvailable ? 'در دسترس' : 'مشغول',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          isAvailable
                                              ? AppColors.success
                                              : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing:
                                isAvailable
                                    ? Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: AppColors.secondary,
                                    )
                                    : null,
                            onTap:
                                isAvailable
                                    ? () async {
                                      final provider =
                                          Provider.of<OrderOwnerProvider>(
                                            context,
                                            listen: false,
                                          );

                                      final success = await provider
                                          .assignDriverToOrder(
                                            orderId,
                                            driver.id,
                                          );

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        if (success) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'راننده ${driver.fullName} به سفارش اختصاص یافت',
                                              ),
                                              backgroundColor:
                                                  AppColors.success,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'خطا در اختصاص راننده',
                                              ),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                    : null,
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('انصراف'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
