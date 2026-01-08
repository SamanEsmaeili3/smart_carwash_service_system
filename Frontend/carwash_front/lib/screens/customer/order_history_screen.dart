import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../providers/booking_provider.dart';
import '../../constants/app_colors.dart';
import '../../models/order_history_model.dart';
import '../../widgets/custom_button.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).fetchOrderHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("سفارش‌های من", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingHistory) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.history.isEmpty) {
            return const Center(
              child: Text("شما هنوز سفارشی ثبت نکرده‌اید."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.history.length,
            itemBuilder: (ctx, index) {
              return _OrderHistoryCard(order: provider.history[index]);
            },
          );
        },
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final OrderHistoryModel order;

  const _OrderHistoryCard({required this.order});

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'SUBMITTED':
        return Colors.orange;
      case 'ACCEPTED':
      case 'IN_SERVICE':
      case 'EN_ROUTE':
        return Colors.blue;
      case 'COMPLETE':
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return "در انتظار";
      case 'SUBMITTED': return "در انتظار تایید";
      case 'ACCEPTED': return "تایید شده";
      case 'EN_ROUTE': return "راننده در راه است";
      case 'IN_SERVICE': return "در حال انجام";
      case 'COMPLETE':
      case 'COMPLETED': return "تکمیل شده";
      case 'REJECTED': return "رد شده";
      case 'CANCELLED': return "لغو شده";
      default: return status;
    }
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ReviewDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = order.status.toUpperCase() == 'COMPLETE' || 
                             order.status.toUpperCase() == 'COMPLETED';

    final jalali = Jalali.fromDateTime(order.scheduledTime);
    final f = jalali.formatter;
    final String timeStr = '${order.scheduledTime.hour.toString().padLeft(2, '0')}:${order.scheduledTime.minute.toString().padLeft(2, '0')}';
    final String dateStr = '${f.wN}، ${f.d} ${f.mN} ${f.yyyy} - ساعت $timeStr';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: (order.carwashImage.isNotEmpty)
                      ? NetworkImage(order.carwashImage)
                      : null,
                  child: (order.carwashImage.isEmpty)
                      ? const Icon(Icons.local_car_wash)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.carwashName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(order.status)),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              order.servicesText,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${order.totalPrice.toInt()} تومان",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
                if (isCompleted)
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () => _showRatingDialog(context),
                      icon: const Icon(Icons.star_rounded, size: 18),
                      label: const Text("ثبت امتیاز", style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Internal Review Dialog Widget ---
class _ReviewDialog extends StatefulWidget {
  final OrderHistoryModel order;
  const _ReviewDialog({required this.order});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _carwashRating = 5;
  int _driverRating = 5;
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;

  Widget _buildStarRating(String label, int currentRating, Function(int) onRatingChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the stars
          children: List.generate(5, (index) {
            return IconButton(
              // Use star_rounded for a filled star and star_outline_rounded for empty
              icon: Icon(
                index < currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber, // This makes it yellow/gold
                size: 40, // Increased size for better visibility
              ),
              onPressed: () => onRatingChanged(index + 1),
              padding: EdgeInsets.zero, // Reduce padding to fit 5 stars easily
              constraints: const BoxConstraints(), // Helps with spacing in small dialogs
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("امتیاز به ${widget.order.carwashName}", 
        textAlign: TextAlign.center, 
        style: const TextStyle(fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStarRating("امتیاز کارواش", _carwashRating, (val) => setState(() => _carwashRating = val)),
            const SizedBox(height: 16),
            _buildStarRating("امتیاز راننده", _driverRating, (val) => setState(() => _driverRating = val)),
            const SizedBox(height: 16),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "نظر شما در مورد این سرویس...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("انصراف", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _isSubmitting ? null : () async {
            setState(() => _isSubmitting = true);
            // Logic for submitting to backend Task-B5.5
            // await provider.submitReview(widget.order.id, _carwashRating, _driverRating, _commentCtrl.text);
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("امتیاز شما با موفقیت ثبت شد"), backgroundColor: Colors.green),
              );
            }
          },
          child: _isSubmitting 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text("ثبت نظر"),
        ),
      ],
    );
  }
}