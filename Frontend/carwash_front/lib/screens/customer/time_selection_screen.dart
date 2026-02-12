import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/booking_provider.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';
import '../../constants/app_colors.dart';
import '../../services/error_handler.dart';
import '../../widgets/custom_button.dart';

class TimeSelectionScreen extends StatefulWidget {
  final int orderId;

  const TimeSelectionScreen({super.key, required this.orderId});

  @override
  State<TimeSelectionScreen> createState() => _TimeSelectionScreenState();
}

class _TimeSelectionScreenState extends State<TimeSelectionScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _slots = [];
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoadingVehicles = false;
  int _selectedIndex = -1;
  Map<String, dynamic>? _selectedVehicle;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Force refresh data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateSlots();
      _loadVehicles();
    });
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoadingVehicles = true);

    List<Map<String, dynamic>> vehicles = [];
    Map<String, dynamic>? selected;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastVehicleId = prefs.getInt('last_vehicle_id');

      final res = await _api.get(ApiConstants.customerVehicles, auth: true);
      if (res is List) {
        vehicles = res.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      if (_selectedVehicle != null) {
        final match = vehicles.firstWhere(
          (v) => v['id'] == _selectedVehicle!['id'],
          orElse: () => <String, dynamic>{},
        );
        if (match.isNotEmpty) selected = match;
      }

      if (selected == null && lastVehicleId != null) {
        final match = vehicles.firstWhere(
          (v) => v['id'] == lastVehicleId,
          orElse: () => <String, dynamic>{},
        );
        if (match.isNotEmpty) selected = match;
      }
    } catch (e) {
      if (mounted) {
        final msg = ErrorHandler.getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _selectedVehicle = selected;
          _isLoadingVehicles = false;
        });
      }
    }
  }

  Future<void> _persistSelectedVehicle(Map<String, dynamic> vehicle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = vehicle['id'];
      if (id is int) {
        await prefs.setInt('last_vehicle_id', id);
      }
    } catch (_) {
      // Ignore persistence errors
    }
  }

  void _generateSlots() {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final profile = provider.profile;

    if (profile == null) return;

    List<Map<String, dynamic>> tempSlots = [];
    final now = DateTime.now();

    // ---------------------------------------------------------
    // 1. LIMIT TO ONLY TODAY (Loop runs once: i=0)
    // ---------------------------------------------------------
    for (int i = 0; i < 1; i++) {
      final date = now.add(Duration(days: i));

      // Jalali Date Conversion
      final jalaliDate = Jalali.fromDateTime(date);
      final formatter = jalaliDate.formatter;
      final dateLabel = '${formatter.wN}، ${formatter.d} ${formatter.mN}';

      String dayKey = _getDayKey(date.weekday);

      // -----------------------------------------------------------
      // 2. ROBUST KEY CHECK (Case Insensitive)
      // -----------------------------------------------------------
      String? hours;
      profile.workingHours.forEach((key, value) {
        if (key.toString().toLowerCase() == dayKey.toLowerCase()) {
          hours = value.toString();
        }
      });

      if (hours == null || hours == "Closed") continue;

      try {
        final parts = hours!.split('-');
        if (parts.length != 2) continue;

        final openTime = _parseTime(parts[0]);
        final closeTime = _parseTime(parts[1]);

        var currentSlot = DateTime(
          date.year,
          date.month,
          date.day,
          openTime.hour,
          openTime.minute,
        );

        var closingDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          closeTime.hour,
          closeTime.minute,
        );

        while (currentSlot.isBefore(closingDateTime)) {
          // ---------------------------------------------------------
          // 3. FILTER: Only show FUTURE times for Today
          // ---------------------------------------------------------
          if (currentSlot.isAfter(now)) {
            tempSlots.add({
              'displayTime': _formatTimeOfDay(
                TimeOfDay.fromDateTime(currentSlot),
              ),
              'displayDate': dateLabel,
              'isoTime': currentSlot.toIso8601String(),
            });
          }
          // Increment by 1 hour
          currentSlot = currentSlot.add(const Duration(hours: 1));
        }
      } catch (e) {
        print("Error parsing hours: $e");
      }
    }

    setState(() {
      _slots = tempSlots;
    });
  }

  String _getDayKey(int weekday) {
    const days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    return days[weekday - 1];
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.trim().split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

    Widget _buildVehicleSection() {
    if (_isLoadingVehicles) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_vehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هیچ خودرویی ثبت نشده است',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, '/customer/vehicles');
                await _loadVehicles();
              },
              icon: const Icon(Icons.add),
              label: const Text('افزودن خودرو'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedVehicle != null)
          Text(
            'خودرو انتخاب‌شده: ${_selectedVehicle!['make']} ${_selectedVehicle!['model']} - ${_selectedVehicle!['license_plate']}',
            style: TextStyle(color: Colors.grey.shade800),
          )
        else
          const Text(
            'لطفاً یک خودرو انتخاب کنید',
            style: TextStyle(color: Colors.grey),
          ),
        const SizedBox(height: 10),
        SizedBox(
          height: 128,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth < 360 ? 200.0 : 240.0;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _vehicles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final v = _vehicles[index];
                  final isSelected =
                      _selectedVehicle != null &&
                      _selectedVehicle!['id'] == v['id'];
                  return InkWell(
                    onTap: () async {
                      setState(() => _selectedVehicle = v);
                      await _persistSelectedVehicle(v);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: cardWidth,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.primary.withOpacity(0.08)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
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
                                  '${v['make']} ${v['model']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildVehicleDetailRow(
                            label: 'پلاک',
                            value: v['license_plate']?.toString() ?? '-',
                            icon: Icons.confirmation_number_outlined,
                          ),
                          const SizedBox(height: 6),
                          _buildVehicleDetailRow(
                            label: 'رنگ',
                            value: v['color']?.toString() ?? '-',
                            icon: Icons.palette_outlined,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              await Navigator.pushNamed(context, '/customer/vehicles');
              await _loadVehicles();
            },
            child: const Text('مدیریت خودروها'),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleDetailRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ),
      ],
    );
  }



  String? _extractApiError(dynamic raw) {
    if (raw == null) return null;
    if (raw is String && raw.trim().isNotEmpty) return raw;
    try {
      return jsonEncode(raw);
    } catch (_) {
      return raw.toString();
    }
  }

  void _submitOrder() async {
    if (_selectedIndex == -1) return;
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفا یک خودرو انتخاب کنید.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final dynamic rawVehicleId = _selectedVehicle!['id'];
    int? vehicleId;
    if (rawVehicleId is int) {
      vehicleId = rawVehicleId;
    } else if (rawVehicleId is String) {
      vehicleId = int.tryParse(rawVehicleId);
    }
    if (vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('شناسه خودرو نامعتبر است. لطفا دوباره انتخاب کنید.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = Provider.of<BookingProvider>(context, listen: false);

    try {
      final selectedSlot = _slots[_selectedIndex];
      final String isoTime = selectedSlot['isoTime'];

      bool success = await provider.finalizeOrder(
        widget.orderId,
        isoTime,
        vehicleId: vehicleId,
      );

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/booking_success');
      }
    } catch (e) {
      if (mounted) {
        String msg;
        if (e is ApiException) {
          msg = _extractApiError(e.raw) ?? e.message;
        } else {
          msg = ErrorHandler.getErrorMessage(e);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطا: $msg"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("انتخاب زمان"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey.shade50,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "رزرو نوبت قطعی",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                const Text(
                  'انتخاب خودرو',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildVehicleSection(),
                const SizedBox(height: 12),
                Text(
                  "لطفاً یکی از زمان‌های خالی امروز را انتخاب کنید:",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _slots.isEmpty
                    ? const Center(
                      child: Text(
                        "نوبتی برای امروز باقی نمانده است",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _slots.length,
                      itemBuilder: (context, index) {
                        final slot = _slots[index];
                        final isSelected = _selectedIndex == index;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedIndex = index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.primary.withOpacity(0.1)
                                      : Colors.white,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  slot['displayTime'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isSelected
                                            ? AppColors.primary
                                            : Colors.black87,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      slot['displayDate'],
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 18,
                                      color:
                                          isSelected
                                              ? AppColors.primary
                                              : Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: "تایید و پرداخت",
                onPressed: _selectedIndex != -1 ? _submitOrder : null,
                isLoading: _isSubmitting,
                color:
                    _selectedIndex != -1
                        ? AppColors.success
                        : Colors.grey.shade300,
                textColor:
                    _selectedIndex != -1 ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
