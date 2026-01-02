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
  String _debugMessage = ""; // To help us see what's wrong

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

    // 1. Safety Check: Is profile loaded?
    if (profile == null) {
      setState(() => _debugMessage = "خطا: اطلاعات کارواش بارگذاری نشده است (Profile is null)");
      return;
    }

    List<Map<String, dynamic>> tempSlots = [];
    final now = DateTime.now();

    // 2. Loop for Today (and maybe tomorrow for safety)
    // We check 2 days just in case you are testing late at night
    for (int i = 0; i < 2; i++) {
      final date = now.add(Duration(days: i));
      
      // Jalali Date
      final jalaliDate = Jalali.fromDateTime(date);
      final formatter = jalaliDate.formatter;
      final dateLabel = '${formatter.wN}، ${formatter.d} ${formatter.mN}';
      
      String dayKey = _getDayKey(date.weekday); // e.g. "Friday"

      // 3. ROBUST HOUR CHECKING (Case Insensitive)
      // Checks: "Friday", "friday", "FRIDAY"
      String? hours = profile.workingHours[dayKey] ?? 
                      profile.workingHours[dayKey.toLowerCase()] ?? 
                      profile.workingHours[dayKey.toUpperCase()];

      // Debugging logic
      if (i == 0) { // If today
        print("Checking $dayKey: Hours found = $hours");
        if (hours == null || hours == "Closed") {
             _debugMessage = "کارواش امروز ($dayKey) بسته است یا ساعات کاری ثبت نشده.";
        }
      }

      if (hours == null || hours == "Closed") continue;

      try {
        final parts = hours.split('-');
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
        
        final closingDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          closeTime.hour,
          closeTime.minute,
        );

        while (currentSlot.isBefore(closingDateTime)) {
          // 4. Time Check: Must be in the future
          if (currentSlot.isAfter(now)) {
             tempSlots.add({
              'displayTime': _formatTimeOfDay(TimeOfDay.fromDateTime(currentSlot)),
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
      if (_slots.isEmpty && _debugMessage.isEmpty) {
        _debugMessage = "نوبتی برای امروز باقی نمانده است (زمان گذشته است)";
      }
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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _debugMessage.isNotEmpty ? _debugMessage : "زمانی موجود نیست",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
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