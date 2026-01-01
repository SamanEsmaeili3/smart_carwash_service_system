import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../../models/driver_model.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';
import '../../constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart'; 

class DriversManagementScreen extends StatefulWidget {
  const DriversManagementScreen({super.key});

  @override
  State<DriversManagementScreen> createState() =>
      _DriversManagementScreenState();
}

class _DriversManagementScreenState extends State<DriversManagementScreen> {
  final ApiService _api = ApiService();
  List<Driver> drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DriverProvider>(context, listen: false);
      if (provider.drivers.isEmpty) {
        provider.fetchDrivers();
      }
    });
  }

  Future<void> _loadDrivers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(ApiConstants.drivers, auth: true);
      if (response is List) {
        setState(() {
          drivers = response.map((e) => Driver.fromJson(e)).toList();
        });
      }
    } catch (e) {
      _showError('خطا در بارگذاری راننده‌ها: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddDriverDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AddDriverDialog(
            onDriverAdded: () {
              _loadDrivers();
              Navigator.pop(context);
            },
          ),
    );
  }

  void _showEditDriverDialog(Driver driver) {
    showDialog(
      context: context,
      builder:
          (context) => EditDriverDialog(
            driver: driver,
            onDriverUpdated: () {
              _loadDrivers();
              Navigator.pop(context);
            },
          ),
    );
  }

  void _deleteDriver(int driverId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('حذف راننده'),
            content: const Text(
              'آیا مطمئن هستید که می‌خواهید این راننده را حذف کنید؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('انصراف'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _api.delete(
                      '${ApiConstants.drivers}$driverId/',
                      auth: true,
                    );
                    _showSuccess('راننده با موفقیت حذف شد');
                    _loadDrivers();
                  } catch (e) {
                    _showError('خطا در حذف راننده');
                  }
                },
                child: const Text(
                  'حذف',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت رانندگان'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDriverDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: Consumer<DriverProvider>(
        builder: (context, driverProvider, child) {
          
          if (driverProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (driverProvider.drivers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'هیچ راننده‌ای ثبت نشده است',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddDriverDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('اضافه کردن راننده'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => driverProvider.fetchDrivers(), 
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: driverProvider.drivers.length, 
              itemBuilder: (context, index) {
                final driver = driverProvider.drivers[index];
                return DriverCard(
                  driver: driver,
                  onEdit: () => _showEditDriverDialog(driver),
                  onDelete: () => _deleteDriver(driver.id!),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// --- Driver Card Widget ---
class DriverCard extends StatelessWidget {
  final Driver driver;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DriverCard({
    super.key,
    required this.driver,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Driver Photo
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: driver.personnelPhotoUrl != null
                  ? NetworkImage(_fixImageUrl(driver.personnelPhotoUrl!))
                  : null,
              
              child: driver.personnelPhotoUrl == null 
                  ? Icon(Icons.person, size: 40, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            // Driver Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'کد ملی: ${driver.nationalId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تلفن: ${driver.phoneNumber}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          driver.status == 'AVAILABLE'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(driver.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color:
                            driver.status == 'AVAILABLE'
                                ? Colors.green
                                : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton(
              itemBuilder:
                  (context) => [
                    PopupMenuItem(onTap: onEdit, child: const Text('ویرایش')),
                    PopupMenuItem(
                      onTap: onDelete,
                      child: const Text(
                        'حذف',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'AVAILABLE':
        return 'در دسترس';
      case 'BUSY':
        return 'مشغول';
      case 'INACTIVE':
        return 'غیرفعال';
      default:
        return status;
    }
  }
}

// --- Add Driver Dialog ---
class AddDriverDialog extends StatefulWidget {
  final VoidCallback onDriverAdded;

  const AddDriverDialog({super.key, required this.onDriverAdded});

  @override
  State<AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.drivers}'),
      );

      // Add headers
      final prefs = await _getSharedPreferences();
      String? token = prefs.getString('access_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add fields
      request.fields['full_name'] = _nameController.text.trim();
      request.fields['national_id'] = _nationalIdController.text.trim();
      request.fields['phone_number'] = _phoneController.text.trim();
      if (_addressController.text.trim().isNotEmpty) {
        request.fields['address'] = _addressController.text.trim();
      }

      // Add image if selected
      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'personnel_photo',
            _selectedImage!.path,
          ),
        );
      }

      final response = await request.send();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('راننده با موفقیت اضافه شد'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onDriverAdded();
      } else {
        throw Exception('خطا: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<dynamic> _getSharedPreferences() async {
    return await SharedPreferencesHelper.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'اضافه کردن راننده جدید',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                // Image Picker
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child:
                          _selectedImage != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.camera_alt, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'انتخاب عکس',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Name Input
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'نام و نام خانوادگی',
                    hintText: 'نام کامل راننده',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'نام را وارد کنید';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // National ID Input
                TextFormField(
                  controller: _nationalIdController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'کد ملی',
                    hintText: '۱۲۳۴۵۶۷۸۹۰',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'کد ملی را وارد کنید';
                    }
                    if (value!.length != 10) {
                      return 'کد ملی باید ۱۰ رقم باشد';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Phone Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'شماره تلفن',
                    hintText: '۰۹۱۲۳۴۵۶۷۸۹',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'شماره تلفن را وارد کنید';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Address Input
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'آدرس (اختیاری)',
                    hintText: 'آدرس محل سکونت',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text('اضافه کردن'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                        ),
                        child: const Text('انصراف'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Edit Driver Dialog ---
class EditDriverDialog extends StatefulWidget {
  final Driver driver;
  final VoidCallback onDriverUpdated;

  const EditDriverDialog({
    super.key,
    required this.driver,
    required this.onDriverUpdated,
  });

  @override
  State<EditDriverDialog> createState() => _EditDriverDialogState();
}

class _EditDriverDialogState extends State<EditDriverDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isLoading = false;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driver.fullName);
    _phoneController = TextEditingController(text: widget.driver.phoneNumber);
    _addressController = TextEditingController(
      text: widget.driver.address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    setState(() => _isLoading = true);

    try {
      await _api.patch('${ApiConstants.drivers}${widget.driver.id}/', {
        'full_name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      }, auth: true);

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('راننده با موفقیت ویرایش شد'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onDriverUpdated();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ویرایش اطلاعات راننده',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // Name Input
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'نام و نام خانوادگی',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Phone Input
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'شماره تلفن',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Address Input
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'آدرس',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text('ذخیره'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                      ),
                      child: const Text('انصراف'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper for SharedPreferences
class SharedPreferencesHelper {
  static Future<dynamic> getInstance() async {
    return await SharedPreferences.getInstance();
  }
}

String _fixImageUrl(String url) {
  if (url.isEmpty) return "";
  if (url.startsWith('https://')) return url;
  if (url.startsWith('http://')) return url.replaceFirst('http://', 'https://');

  String path = url;
  if (!path.startsWith('/media')) {
    if (path.startsWith('/')) {
      path = '/media$path';
    } else {
      path = '/media/$path';
    }
  }

  return 'https://my-project-api.liara.run$path';
}