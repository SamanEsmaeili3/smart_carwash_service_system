import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../providers/booking_provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';

class TimeSelectionScreen extends StatefulWidget {
  final int orderId;

  const TimeSelectionScreen({super.key, required this.orderId});

  @override
  State<TimeSelectionScreen> createState() => _TimeSelectionScreenState();
}

class _TimeSelectionScreenState extends State<TimeSelectionScreen> {
  List<Map<String, dynamic>> _slots = [];
  int _selectedIndex = -1;
  bool _isSubmitting = false;
  
  // Debug variables to show you what is happening
  String _statusMessage = "در حال بررسی...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateSlots();
    });
  }

  void _generateSlots() {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final profile = provider.profile;

    if (profile == null) {
      setState(() => _statusMessage = "خطا: اطلاعات کارواش یافت نشد");
      return;
    }

    List<Map<String, dynamic>> tempSlots = [];
    final now = DateTime.now();
    bool todayFound = false;

    // Loop for the next 7 days
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      
      // Jalali Date
      final jalaliDate = Jalali.fromDateTime(date);
      final formatter = jalaliDate.formatter;
      final dateLabel = '${formatter.wN}، ${formatter.d} ${formatter.mN}';
      
      String dayKey = _getDayKey(date.weekday); // e.g. "Friday"

      // -----------------------------------------------------------
      // ✅ FIX: Case Insensitive Lookup (Friday, friday, FRIDAY)
      // -----------------------------------------------------------
      String? hours;
      profile.workingHours.forEach((key, value) {
        if (key.toString().toLowerCase() == dayKey.toLowerCase()) {
          hours = value.toString();
        }
      });

      // Debugging for Today
      if (i == 0) {
        if (hours == null || hours == "Closed") {
          _statusMessage = "وضعیت امروز ($dayKey): بسته است (Closed)";
        } else {
          _statusMessage = "وضعیت امروز ($dayKey): باز ($hours)";
          todayFound = true;
        }
      }

      if (hours == null || hours == "Closed") continue;

      try {
        final parts = hours!.split('-');
        if (parts.length != 2) continue;
        
        final openTime = _parseTime(parts[0]);
        final closeTime = _parseTime(parts[1]);

        var currentSlot = DateTime(
          date.year, date.month, date.day, openTime.hour, openTime.minute
        );
        
        // Define closing time fully
        var closingDateTime = DateTime(
          date.year, date.month, date.day, closeTime.hour, closeTime.minute
        );

        while (currentSlot.isBefore(closingDateTime)) {
          // ---------------------------------------------------------
          // ✅ FIX: Ensure we only show FUTURE times for Today
          // ---------------------------------------------------------
          if (currentSlot.isAfter(now)) {
             tempSlots.add({
              'displayTime': _formatTimeOfDay(TimeOfDay.fromDateTime(currentSlot)),
              'displayDate': dateLabel, 
              'isoTime': currentSlot.toIso8601String(), 
            });
          } else if (i == 0) {
            // If we are in the loop for today, but time is past
            _statusMessage = "امروز باز است، اما نوبت‌های نمانده (ساعت گذشته)";
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
      "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
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

  void _submitOrder() async {
    if (_selectedIndex == -1) return;

    setState(() => _isSubmitting = true);
    final provider = Provider.of<BookingProvider>(context, listen: false);
    
    try {
      final selectedSlot = _slots[_selectedIndex];
      final String isoTime = selectedSlot['isoTime'];

      bool success = await provider.finalizeOrder(widget.orderId, isoTime);

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/booking_success');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطا: ${e.toString()}"),
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
          // --- DEBUG / STATUS HEADER ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.amber.shade100,
            width: double.infinity,
            child: Text(
              _statusMessage,
              style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),
          
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
                const SizedBox(height: 8),
                Text(
                  "لطفاً یکی از زمان‌های خالی را انتخاب کنید:",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            child: _slots.isEmpty 
              ? const Center(
                  child: Text(
                    "زمانی برای رزرو موجود نیست",
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.grey.shade300,
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
                                color: isSelected ? AppColors.primary : Colors.black87,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  slot['displayDate'],
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.calendar_today_outlined, 
                                  size: 18,
                                  color: isSelected ? AppColors.primary : Colors.grey,
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
                color: _selectedIndex != -1 ? AppColors.success : Colors.grey.shade300,
                textColor: _selectedIndex != -1 ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}