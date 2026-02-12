import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class RatingScreen extends StatelessWidget {
  final int orderId;

  const RatingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Service'),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false, // Prevents back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_half, size: 80, color: Colors.amber),
              const SizedBox(height: 24),
              Text(
                'Thank you for your order!',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please rate your experience for order #${orderId}.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Placeholder for rating widgets
              const Text(
                '[Rating widgets will be here]',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to the home screen or order history
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/customer/home', 
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: const Text('Submit Rating', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
