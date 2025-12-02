import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';
import '../../models/carwash_model.dart';
import '../../providers/auth_provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider()..fetchPendingCarwashes(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('داشبورد ادمین'),
          backgroundColor: AppColors.primary,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        body: Consumer<AdminProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.pendingList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${provider.error}'),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'تلاش مجدد',
                      onPressed: () => provider.fetchPendingCarwashes(),
                    ),
                  ],
                ),
              );
            }

            if (provider.pendingList.isEmpty) {
              return const Center(child: Text('هیچ کارواشی در انتظار نیست.'));
            }

            return RefreshIndicator(
              onRefresh: () => provider.fetchPendingCarwashes(),
              child: ListView.builder(
                itemCount: provider.pendingList.length,
                itemBuilder: (context, index) {
                  final carwash = provider.pendingList[index];
                  return CarwashApplicationCard(carwash: carwash);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class CarwashApplicationCard extends StatelessWidget {
  final CarwashModel carwash;

  const CarwashApplicationCard({super.key, required this.carwash});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              carwash.businessName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('آدرس: ${carwash.address}'),
            const SizedBox(height: 8),
            Text('ایمیل: ${carwash.contactEmail}'),
            const SizedBox(height: 8),
            Text('تلفن: ${carwash.phoneNumber}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  width: 120,
                  text: 'رد',
                  onPressed:
                      () => provider.manageRequest(carwash.id!, "reject"),
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                CustomButton(
                  width: 120,
                  text: 'تایید',
                  onPressed:
                      () => provider.manageRequest(carwash.id!, "approve"),
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
