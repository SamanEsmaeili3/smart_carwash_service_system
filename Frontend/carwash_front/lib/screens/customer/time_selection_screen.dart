import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart'; // Import for Persian Date
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
  // We will store slots as a simple Map to hold display strings and the actual ISO value
  List<Map<String, dynamic>> _slots = [];
  int _selectedIndex = -1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Generate slots after the widget is built to access Provider safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateSlots();
    });
  }

  void _generateSlots() {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final profile = provider.profile;

    if (profile == null) return;

    List<Map<String, dynamic>> tempSlots = [];
    final now = DateTime.now();

    // ---------------------------------------------------------
    // 1. FIX: LIMIT TO ONLY TODAY (Loop runs once for i=0)
    // ---------------------------------------------------------
    for (int i = 0; i < 1; i++) {
      final date = now.add(Duration(days: i));
      
      // Convert to Persian Date (Jalali)
      final jalaliDate = Jalali.fromDateTime(date);
      final formatter = jalaliDate.formatter;
      
      // Example: "شنبه، ۱۴ دی"
      final dateLabel = '${formatter.wN}، ${formatter.d} ${formatter.mN}';
      
      // Get day name in English for checking working hours logic (e.g., "Saturday")
      String dayKey = _getDayKey(date.weekday);

      // Check if open this day
      String? hours = profile.workingHours[dayKey];
      if (hours == null || hours == "Closed") continue;

      // Parse hours string like "09:00-21:00"
      try {
        final parts = hours.split('-');
        if (parts.length != 2) continue;
        
        final openTime = _parseTime(parts[0]);
        final closeTime = _parseTime(parts[1]);

        // Start generating slots from opening time
        var currentSlot = openTime;
        
        // Loop while the slot start hour is before closing hour
        while (currentSlot.hour < closeTime.hour) {
          // Create a DateTime object for this specific slot
          final slotDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            currentSlot.hour,
            currentSlot.minute,
          );

          // ---------------------------------------------------------
          // 2. FILTER: Don't show past hours for Today
          // ---------------------------------------------------------
          if (slotDateTime.isAfter(now)) {
             tempSlots.add({
              'displayTime': currentSlot.format(context), // e.g. "14:00"
              'displayDate': dateLabel, // e.g. "شنبه، ۱۴ دی"
              'isoTime': slotDateTime.toIso8601String(), // For backend
            });
          }

          // Increment by 1 hour (Change to 2 if you want 2-hour slots)
          currentSlot = currentSlot.replacing(hour: currentSlot.hour + 1);
        }
      } catch (e) {
        print("Error parsing hours: $e");
      }
    }

    setState(() {
      _slots = tempSlots;
    });
  }

  // Helper to convert Gregorian weekday number (1=Mon...7=Sun) to API Key
  String _getDayKey(int weekday) {
    const days = [
      "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
    ];
    return days[weekday - 1];
  }

  // Helper to parse "09:00" to TimeOfDay
  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.trim().split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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
                  "لطفاً یکی از زمان‌های خالی امروز را انتخاب کنید:",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            child: _slots.isEmpty 
              ? const Center(
                  child: Text(
                    "زمانی برای امروز موجود نیست",
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
                            // Time
                            Text(
                              slot['displayTime'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primary : Colors.black87,
                              ),
                            ),
                            // Persian Date Label
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
          // Bottom Bar
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