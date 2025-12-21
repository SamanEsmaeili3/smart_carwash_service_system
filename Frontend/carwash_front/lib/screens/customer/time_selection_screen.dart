import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  DateTime? _selectedDateTime;
  bool _isLoading = false;

  // Generate 3 days of "Smart Slots" starting from tomorrow
  List<DateTime> _generateSlots() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final dayAfter = now.add(const Duration(days: 2));

    return [
      // Tomorrow Slots
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0), // 10:00 AM
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 0), // 02:00 PM
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 16, 0), // 04:00 PM
      
      // Day After Slots
      DateTime(dayAfter.year, dayAfter.month, dayAfter.day, 09, 0), // 09:00 AM
      DateTime(dayAfter.year, dayAfter.month, dayAfter.day, 11, 0), // 11:00 AM
    ];
  }

  void _onConfirm() async {
    if (_selectedDateTime == null) return;

    setState(() => _isLoading = true);
    final provider = Provider.of<BookingProvider>(context, listen: false);
    
    // Send ISO 8601 String to backend (Professional Format)
    // toIso8601String() sends: "2025-12-22T14:00:00.000"
    final success = await provider.finalizeOrder(
      widget.orderId, 
      _selectedDateTime!.toIso8601String()
    );
    
    setState(() => _isLoading = false);

    if (success && mounted) {
      // Navigate to Success
      Navigator.pushReplacementNamed(context, '/booking_success');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("خطا در ثبت نهایی. لطفا دوباره تلاش کنید.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = _generateSlots();
    // Date formatter
    final dateFormat = DateFormat('EEEE, d MMMM'); // e.g., Monday, 23 December
    final timeFormat = DateFormat('HH:mm'); // e.g., 14:00

    return Scaffold(
      appBar: AppBar(
        title: const Text("انتخاب زمان"),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "رزرو نوبت قطعی",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "لطفاً یکی از زمان‌های خالی را انتخاب کنید:",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: slots.length,
                itemBuilder: (ctx, index) {
                  final slotDate = slots[index];
                  final isSelected = _selectedDateTime == slotDate;
                  
                  return Card(
                    elevation: 0,
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        width: 1.5
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => setState(() => _selectedDateTime = slotDate),
                      leading: Icon(
                        Icons.calendar_today, 
                        color: isSelected ? AppColors.primary : Colors.grey
                      ),
                      title: Text(
                        dateFormat.format(slotDate),
                        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          timeFormat.format(slotDate),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: "تایید و پرداخت",
                onPressed: _selectedDateTime != null ? _onConfirm : null,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}