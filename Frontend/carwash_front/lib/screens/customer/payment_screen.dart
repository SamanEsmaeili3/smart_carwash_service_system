import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../constants/app_colors.dart';
import '../../services/error_handler.dart';
import 'rating_screen.dart'; // Assuming a rating screen exists

class PaymentScreen extends StatefulWidget {
  final int orderId;
  final double totalPrice;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.totalPrice,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Future<void> _processPayment() async {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    try {
      // 1. Initiate Payment
      final paymentId = await bookingProvider.initiatePayment(widget.orderId);
      if (!mounted) return;

      if (paymentId != null) {
        // 2. Verify Payment (mocking success)
        final success = await bookingProvider.verifyPayment(
          widget.orderId,
          paymentId,
        );
        if (!mounted) return;

        if (success) {
          // 3. Navigate to Rating Screen on Success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('پرداخت با موفقیت انجام شد'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RatingScreen(orderId: widget.orderId),
            ),
          );
        } else {
          throw Exception('تایید پرداخت ناموفق بود.');
        }
      } else {
        throw Exception('شروع فرآیند پرداخت انجام نشد.');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = ErrorHandler.getErrorMessage(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تکمیل پرداخت'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWide ? 32 : 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 520 : 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.credit_card,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'مبلغ قابل پرداخت',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.totalPrice.toStringAsFixed(0)} تومان',
                        style: Theme.of(
                          context,
                        ).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      bookingProvider.isProcessingPayment
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                            onPressed: _processPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text(
                              'پرداخت',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
