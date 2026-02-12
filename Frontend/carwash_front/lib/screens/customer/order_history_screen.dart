import 'package:carwash_front/screens/customer/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:intl/intl.dart';
import '../../providers/booking_provider.dart';
import '../../constants/app_colors.dart';
import '../../models/order_history_model.dart';
import '../../services/api_service.dart';

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
        title: const Text(
          "سفارش‌های من",
          style: TextStyle(color: Colors.black),
        ),
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
            return const Center(child: Text("شما هنوز سفارشی ثبت نکرده‌اید."));
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
      case 'PENDING':
        return "در انتظار";
      case 'SUBMITTED':
        return "در انتظار تایید";
      case 'ACCEPTED':
        return "تایید شده";
      case 'EN_ROUTE':
        return "راننده در راه است";
      case 'IN_SERVICE':
        return "در حال انجام";
      case 'COMPLETE':
      case 'COMPLETED':
        return "تکمیل شده";
      case 'REJECTED':
        return "رد شده";
      case 'CANCELLED':
        return "لغو شده";
      default:
        return status;
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
    final bool isCompleted =
        order.status.toUpperCase() == 'COMPLETE' ||
        order.status.toUpperCase() == 'COMPLETED';

    final bool showRatingButton = isCompleted && !order.hasRating;

    final jalali = Jalali.fromDateTime(order.scheduledTime);
    final f = jalali.formatter;
    final String timeStr =
        '${order.scheduledTime.hour.toString().padLeft(2, '0')}:${order.scheduledTime.minute.toString().padLeft(2, '0')}';
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
                  backgroundImage:
                      (order.carwashImage.isNotEmpty)
                          ? NetworkImage(order.carwashImage)
                          : null,
                  child:
                      (order.carwashImage.isEmpty)
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
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                if (showRatingButton)
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => _showRatingDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Text(
                            "★",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          SizedBox(width: 4),
                          Text("ثبت امتیاز", style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (order.status.toUpperCase() == 'COMPLETE' ||
                order.status.toUpperCase() == 'COMPLETED')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => PaymentScreen(
                                orderId: order.id,
                                totalPrice: order.totalPrice,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Pay Now",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            // --- Show Customer Review if already rated ---
            if (order.hasRating)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "امتیاز ثبت شده شما:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "★" * (order.carwashRating ?? 0),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (order.carwashComment != null &&
                        order.carwashComment!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          order.carwashComment!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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

  Widget _buildStarRating(
    String label,
    int currentRating,
    Function(int) onRatingChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return InkWell(
              onTap: () => onRatingChanged(index + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  index < currentRating ? "★" : "☆",
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 44,
                    height: 1.0,
                  ),
                ),
              ),
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
      title: Text(
        "امتیاز به ${widget.order.carwashName}",
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStarRating(
              "امتیاز کارواش",
              _carwashRating,
              (val) => setState(() => _carwashRating = val),
            ),
            const SizedBox(height: 16),
            _buildStarRating(
              "امتیاز راننده",
              _driverRating,
              (val) => setState(() => _driverRating = val),
            ),
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
          onPressed:
              _isSubmitting
                  ? null
                  : () async {
                    setState(() => _isSubmitting = true);

                    try {
                      final api = ApiService();
                      await api.post('/api/order/reviews/submit/', {
                        "order": widget.order.id,
                        "carwash_rating": _carwashRating,
                        "carwash_comment": _commentCtrl.text,
                        "driver_rating": _driverRating,
                        "driver_comment": "",
                      }, auth: true);

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("امتیاز شما با موفقیت ثبت شد"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Provider.of<BookingProvider>(
                          context,
                          listen: false,
                        ).fetchOrderHistory();
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("خطا در ثبت امتیاز: ${e.toString()}"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text("ثبت نظر"),
        ),
      ],
    );
  }
}