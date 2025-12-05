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
          backgroundColor: AppColors.adminAppBar,
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'درخواست های در انتظار',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.fetchPendingCarwashes(),
                    child: ListView.builder(
                      itemCount: provider.pendingList.length,
                      itemBuilder: (context, index) {
                        final carwash = provider.pendingList[index];
                        return CarwashApplicationCard(carwash: carwash);
                      },
                    ),
                  ),
                ),
              ],
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
            const SizedBox(height: 2),
            Text('آدرس: ${carwash.address}'),
            const SizedBox(height: 2),
            Text('تلفن: ${carwash.phoneNumber}'),
            const SizedBox(height: 4),
            const Divider(), // Horizontal line
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'تایید',
                    onPressed:
                        () => provider.manageRequest(carwash.id!, "approve"),
                    color: AppColors.success,
                    textColor: Colors.white,
                    height: 32,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: 'رد',
                    onPressed:
                        () => provider.manageRequest(carwash.id!, "reject"),
                    color: Colors.white,
                    textColor: AppColors.error,
                    borderColor: AppColors.error,
                    height: 32,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 0,
                  child: CustomButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(carwash.businessName),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: <Widget>[
                                  Text('نام کارواش: ${carwash.businessName}'),
                                  Text('آدرس: ${carwash.address}'),
                                  Text('تلفن: ${carwash.phoneNumber}'),
                                  Text('ایمیل: ${carwash.contactEmail}'),
                                  Text('وضعیت: ${carwash.status ?? "N/A"}'),
                                  Text(
                                    'مکان: ${carwash.latitude}، ${carwash.longitude}',
                                  ),
                                  Text(
                                    'آدرس عکس پروانه: ${carwash.licensePhotoUrl}',
                                  ),
                                  const Divider(),
                                  const Text('ساعات کاری:'),
                                  ...carwash.workingHours.entries.map((entry) {
                                    return Text('${entry.key}: ${entry.value}');
                                  }),
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('بستن'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    color: AppColors.textSub.withAlpha(26),
                    textColor: AppColors.textMain,
                    height: 32,
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColors.textMain,
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
