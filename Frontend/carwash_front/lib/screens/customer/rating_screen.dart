import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class RatingScreen extends StatelessWidget {
  final int orderId;

  const RatingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت امتیاز'),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false, // Prevents back button
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
                    children: [
                      const Icon(
                        Icons.star_half,
                        size: 80,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'از ثبت سفارش شما سپاسگزاریم',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لطفاً تجربه خود را برای سفارش شماره $orderId ثبت کنید.',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // Placeholder for rating widgets
                      const Text(
                        '[ابزار ثبت امتیاز در این بخش قرار می‌گیرد]',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate back to the home screen or order history
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/customer/home',
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'ثبت امتیاز',
                            style: TextStyle(color: Colors.white),
                          ),
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
