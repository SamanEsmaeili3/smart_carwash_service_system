import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';
import '../../constants/app_colors.dart';
import '../../services/error_handler.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(ApiConstants.customerVehicles, auth: true);
      if (res is List) {
        _vehicles = res.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _vehicles = [];
      }
    } catch (e) {
      final msg = ErrorHandler.getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _persistLastVehicleId(dynamic id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (id is int) {
        await prefs.setInt('last_vehicle_id', id);
      } else if (id is String) {
        final parsed = int.tryParse(id);
        if (parsed != null) {
          await prefs.setInt('last_vehicle_id', parsed);
        }
      }
    } catch (_) {
      // Ignore persistence errors
    }
  }

  Future<void> _showAddDialog() async {
    final _make = TextEditingController();
    final _model = TextEditingController();
    final _color = TextEditingController();
    final _plate = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('افزودن خودرو جدید'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _make,
                    decoration: const InputDecoration(labelText: 'برند'),
                  ),
                  TextField(
                    controller: _model,
                    decoration: const InputDecoration(labelText: 'مدل'),
                  ),
                  TextField(
                    controller: _color,
                    decoration: const InputDecoration(labelText: 'رنگ'),
                  ),
                  TextField(
                    controller: _plate,
                    decoration: const InputDecoration(labelText: 'پلاک'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Local validation (Persian messages)
                  if (_make.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لطفاً برند خودرو را وارد کنید'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (_model.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لطفاً مدل خودرو را وارد کنید'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (_color.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لطفاً رنگ خودرو را وارد کنید'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (_plate.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لطفاً پلاک خودرو را وارد کنید'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    final created = await _api.post(ApiConstants.customerVehicles, {
                      'make': _make.text.trim(),
                      'model': _model.text.trim(),
                      'color': _color.text.trim(),
                      'license_plate': _plate.text.trim(),
                    }, auth: true);

                    if (created is Map && created['id'] != null) {
                      await _persistLastVehicleId(created['id']);
                    }

                    Navigator.pop(context, true);
                  } catch (e) {
                    final msg = ErrorHandler.getErrorMessage(e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: const Text('ذخیره'),
              ),
            ],
          ),
    );

    if (result == true) {
      await _fetchVehicles();
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> vehicle) async {
    final _make = TextEditingController(text: vehicle['make']?.toString() ?? '');
    final _model = TextEditingController(
      text: vehicle['model']?.toString() ?? '',
    );
    final _color = TextEditingController(
      text: vehicle['color']?.toString() ?? '',
    );
    final _plate = TextEditingController(
      text: vehicle['license_plate']?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ویرایش خودرو'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _make,
                    decoration: const InputDecoration(labelText: 'برند'),
                  ),
                  TextField(
                    controller: _model,
                    decoration: const InputDecoration(labelText: 'مدل'),
                  ),
                  TextField(
                    controller: _color,
                    decoration: const InputDecoration(labelText: 'رنگ'),
                  ),
                  TextField(
                    controller: _plate,
                    decoration: const InputDecoration(labelText: 'پلاک'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_make.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لطفاً برند خودرو را وارد کنید'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (_model.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لطفاً مدل خودرو را وارد کنید'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (_color.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لطفاً رنگ خودرو را وارد کنید'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (_plate.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لطفاً پلاک خودرو را وارد کنید'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    await _api.patch(
                      '${ApiConstants.customerVehicles}${vehicle['id']}/',
                      {
                        'make': _make.text.trim(),
                        'model': _model.text.trim(),
                        'color': _color.text.trim(),
                        'license_plate': _plate.text.trim(),
                      },
                      auth: true,
                    );

                    Navigator.pop(context, true);
                  } catch (e) {
                    final msg = ErrorHandler.getErrorMessage(e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: const Text('ذخیره'),
              ),
            ],
          ),
    );

    if (result == true) {
      await _fetchVehicles();
    }
  }

  Future<void> _deleteVehicle(int id) async {
    try {
      await _api.delete('${ApiConstants.customerVehicles}$id/', auth: true);
      await _fetchVehicles();
    } catch (e) {
      final msg = ErrorHandler.getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  
  Widget _buildHeader(double maxWidth) {
    final isCompact = maxWidth < 520;
    final actionButton = ElevatedButton.icon(
      onPressed: _showAddDialog,
      icon: const Icon(Icons.add),
      label: const Text('افزودن خودرو'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const StadiumBorder(),
      ),
    );

    final title = const Text(
      'مدیریت خودروها',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );

    final subtitle = const Text(
      'خودروهای ثبت‌شده شما برای نوبت‌گیری سریع‌تر.',
      style: TextStyle(color: Colors.white70, height: 1.4),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2B6CE8), Color(0xFF5DA3FF)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child:
            isCompact
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 6),
                    subtitle,
                    const SizedBox(height: 12),
                    actionButton,
                  ],
                )
                : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          const SizedBox(height: 6),
                          subtitle,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    actionButton,
                  ],
                ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هنوز خودرویی اضافه نکرده‌اید.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'برای شروع، یک خودرو اضافه کنید.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('افزودن خودرو'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color),
      splashRadius: 20,
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle, {required bool compact}) {
    final title = '${vehicle['make']} ${vehicle['model']}';
    final plate = vehicle['license_plate']?.toString() ?? '-';
    final color = vehicle['color']?.toString() ?? '-';

    return InkWell(
      onTap: () async {
        await _persistLastVehicleId(vehicle['id']);
        if (mounted) {
          Navigator.pop(context, vehicle);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildActionIcon(
                  icon: Icons.edit,
                  tooltip: 'ویرایش',
                  color: AppColors.primary,
                  onPressed: () => _showEditDialog(vehicle),
                ),
                _buildActionIcon(
                  icon: Icons.delete_outline,
                  tooltip: 'حذف',
                  color: Colors.redAccent,
                  onPressed: () => _confirmDelete(vehicle),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  label: 'پلاک',
                  value: plate,
                ),
                _buildInfoChip(
                  label: 'رنگ',
                  value: color,
                ),
              ],
            ),
            if (compact) ...[
              const SizedBox(height: 10),
              Text(
                'برای انتخاب این خودرو لمس کنید.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> vehicle) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder:
              (c) => AlertDialog(
                title: const Text('حذف خودرو'),
                content: const Text(
                  'آیا از حذف این خودرو مطمئن هستید؟',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('خیر'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('بله'),
                  ),
                ],
              ),
        ) ??
        false;

    if (ok) {
      _deleteVehicle(vehicle['id'] as int);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('خودروهای من'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchVehicles,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final crossAxisCount =
                        maxWidth >= 1100 ? 3 : (maxWidth >= 720 ? 2 : 1);

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader(maxWidth)),
                        if (_vehicles.isEmpty)
                          SliverToBoxAdapter(child: _buildEmptyState())
                        else if (crossAxisCount == 1)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final v = _vehicles[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildVehicleCard(
                                      v,
                                      compact: true,
                                    ),
                                  );
                                },
                                childCount: _vehicles.length,
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final v = _vehicles[index];
                                  return _buildVehicleCard(
                                    v,
                                    compact: false,
                                  );
                                },
                                childCount: _vehicles.length,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.6,
                                  ),
                            ),
                          ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 24),
                        ),
                      ],
                    );
                  },
                ),
              ),
    );
  }
}
