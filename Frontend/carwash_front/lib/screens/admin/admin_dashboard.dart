import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';
import '../../models/carwash_model.dart';
import '../../providers/auth_provider.dart';

final List<String> orderedDays = [
  'Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'
];

final Map<String, String> persianDays = {
  'Saturday': 'شنبه',
  'Sunday': 'یک‌شنبه',
  'Monday': 'دوشنبه',
  'Tuesday': 'سه‌شنبه',
  'Wednesday': 'چهارشنبه',
  'Thursday': 'پنج‌شنبه',
  'Friday': 'جمعه',
};

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
          centerTitle: true, // Center title looks better
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
        // -------------------------------------------------------------
        // 💡 RESPONSIVE FIX: Center the content and limit width
        // -------------------------------------------------------------
        body: Center(
          child: ConstrainedBox(
            // Limit width to 800px. On phones, it will just use full width.
            constraints: const BoxConstraints(maxWidth: 800), 
            child: Consumer<AdminProvider>(
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
                          width: 200, // Fixed width for error button
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
                      padding: EdgeInsets.all(16.0), // Increased padding
                      child: Text(
                        'درخواست های در انتظار',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => provider.fetchPendingCarwashes(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
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
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Better margin
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  carwash.businessName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                // Status badge could go here
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, carwash.address),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.phone_outlined, carwash.phoneNumber),
            
            const SizedBox(height: 12),
            const Divider(), 
            const SizedBox(height: 12),
            
            // Buttons Row
            Row(
              children: [
                // Info Button
                Expanded(
                  flex: 1, // Takes less space
                  child: CustomButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              carwash.businessName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: <Widget>[
                                  // ... Name, Address, Phone ...
                                  Text('نام کارواش: ${carwash.businessName}'),
                                  const SizedBox(height: 8),
                                  Text('آدرس: ${carwash.address}'),
                                  const SizedBox(height: 8),
                                  Text('تلفن: ${carwash.phoneNumber}'),
                                  const SizedBox(height: 8),
                                  Text('ایمیل: ${carwash.contactEmail}'),
                                  const SizedBox(height: 8),

                                  // 1. CLEANER LOCATION
                                  Text(
                                    'مکان: ${carwash.latitude.toStringAsFixed(4)}, ${carwash.longitude.toStringAsFixed(4)}',
                                    textDirection: TextDirection.ltr, // Keeps numbers aligned correctly
                                    textAlign: TextAlign.right,
                                  ),

                                  const SizedBox(height: 8),
                                  const Divider(),
                                  const Text(
                                    'ساعات کاری:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),

                                  // 2. SORTED & TRANSLATED DAYS
                                  // Iterate through our ORDERED list, not the random map keys
                                  ...orderedDays.map((engDay) {
                                    // Get the value from the carwash data
                                    final time = carwash.workingHours[engDay];
                                    if (time == null) return const SizedBox(); // Skip if missing

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(persianDays[engDay] ?? engDay), // Persian Name
                                          Text(
                                            time == "Closed" ? "تعطیل" : time, // Persian Status
                                            style: TextStyle(
                                              color: time == "Closed" ? Colors.red : Colors.green[700],
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('بستن'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    color: AppColors.textSub.withAlpha(30),
                    textColor: AppColors.textMain,
                    height: 40, // Smaller height for card buttons
                    child: const Icon(Icons.info_outline, color: AppColors.textMain),
                  ),
                ),
                const SizedBox(width: 8),
                // Reject Button
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: 'رد',
                    onPressed: () => provider.manageRequest(carwash.id!, "reject"),
                    color: Colors.white,
                    textColor: AppColors.error,
                    borderColor: AppColors.error,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 8),
                // Approve Button
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: 'تایید',
                    onPressed: () => provider.manageRequest(carwash.id!, "approve"),
                    color: AppColors.success,
                    textColor: Colors.white,
                    height: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for cleaner UI
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSub),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textMain),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}