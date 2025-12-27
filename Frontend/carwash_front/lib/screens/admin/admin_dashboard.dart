import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';
import '../../models/carwash_model.dart';

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
    // We remove the ChangeNotifierProvider creation here because 
    // it's best practice to provide it higher up or let the tabs manage fetching.
    // However, for this specific structure, we can wrap the scaffold or just use the existing provider.
    // Assuming AdminProvider is provided in main.dart or a parent. 
    // If not, we can wrap this widget. Let's wrap it to be safe.
    
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(), // Don't fetch immediately here, tabs will fetch.
      child: DefaultTabController(
        length: 2, // Two tabs: Pending & Approved
        child: Scaffold(
          appBar: AppBar(
            title: const Text('داشبورد ادمین'),
            backgroundColor: AppColors.adminAppBar,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: "درخواست‌های جدید", icon: Icon(Icons.hourglass_empty)),
                Tab(text: "کارواش‌های فعال", icon: Icon(Icons.check_circle_outline)),
              ],
            ),
          ),
          body: const Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: TabBarView(
                children: [
                  _PendingListTab(),  // Tab 1
                  _ApprovedListTab(), // Tab 2
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: Pending Requests
// -----------------------------------------------------------------------------
class _PendingListTab extends StatefulWidget {
  const _PendingListTab();

  @override
  State<_PendingListTab> createState() => _PendingListTabState();
}

class _PendingListTabState extends State<_PendingListTab> {
  @override
  void initState() {
    super.initState();
    // Fetch pending list when this tab loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchPendingCarwashes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.pendingList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _buildErrorState(provider.error!, () => provider.fetchPendingCarwashes());
        }

        if (provider.pendingList.isEmpty) {
          return const Center(child: Text('هیچ درخواست جدیدی وجود ندارد.'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchPendingCarwashes(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 20),
            itemCount: provider.pendingList.length,
            itemBuilder: (context, index) {
              final carwash = provider.pendingList[index];
              // Pass isPending: true to show Approve/Reject buttons
              return CarwashApplicationCard(carwash: carwash, isPending: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(error, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          CustomButton(
            text: 'تلاش مجدد',
            onPressed: onRetry,
            width: 200,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: Approved Carwashes
// -----------------------------------------------------------------------------
class _ApprovedListTab extends StatefulWidget {
  const _ApprovedListTab();

  @override
  State<_ApprovedListTab> createState() => _ApprovedListTabState();
}

class _ApprovedListTabState extends State<_ApprovedListTab> {
  @override
  void initState() {
    super.initState();
    // Fetch approved list when this tab loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchApprovedCarwashes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.approvedList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // We reuse the error variable, but usually you'd want separate error states per list.
        // For simplicity, we assume the provider manages one error state nicely.
        if (provider.error != null) {
             return Center(child: Text(provider.error!));
        }

        if (provider.approvedList.isEmpty) {
          return const Center(child: Text('هیچ کارواش فعالی یافت نشد.'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchApprovedCarwashes(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 20),
            itemCount: provider.approvedList.length,
            itemBuilder: (context, index) {
              final carwash = provider.approvedList[index];
              // Pass isPending: false to hide buttons
              return CarwashApplicationCard(carwash: carwash, isPending: false);
            },
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// SHARED WIDGET: Carwash Card
// -----------------------------------------------------------------------------
class CarwashApplicationCard extends StatelessWidget {
  final CarwashModel carwash;
  final bool isPending; // [NEW] Flag to toggle buttons

  const CarwashApplicationCard({
    super.key, 
    required this.carwash,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isPending ? Colors.orange : Colors.green),
                  ),
                  child: Text(
                    isPending ? "در انتظار" : "فعال",
                    style: TextStyle(
                      color: isPending ? Colors.orange : Colors.green,
                      fontSize: 12, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
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
                // Info Button (Always Visible)
                Expanded(
                  flex: 1, 
                  child: CustomButton(
                    onPressed: () => _showDetailsDialog(context),
                    color: AppColors.textSub.withAlpha(30),
                    textColor: AppColors.textMain,
                    height: 40,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.textMain, size: 18),
                        SizedBox(width: 4),
                        Text("جزئیات", style: TextStyle(color: AppColors.textMain)),
                      ],
                    ),
                  ),
                ),
                
                // Only show Approve/Reject if Pending
                if (isPending) ...[
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

  void _showDetailsDialog(BuildContext context) {
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
                Text('نام کارواش: ${carwash.businessName}'),
                const SizedBox(height: 8),
                Text('آدرس: ${carwash.address}'),
                const SizedBox(height: 8),
                Text('تلفن: ${carwash.phoneNumber}'),
                const SizedBox(height: 8),
                Text('ایمیل: ${carwash.contactEmail}'),
                const SizedBox(height: 8),

                // LOCATION
                Text(
                  'مکان: ${carwash.latitude.toStringAsFixed(4)}, ${carwash.longitude.toStringAsFixed(4)}',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),

                const SizedBox(height: 8),
                const Divider(),
                const Text(
                  'ساعات کاری:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                // WORKING HOURS
                ...orderedDays.map((engDay) {
                  final time = carwash.workingHours[engDay];
                  if (time == null) return const SizedBox();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(persianDays[engDay] ?? engDay),
                        Text(
                          time == "Closed" ? "تعطیل" : time,
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
  }
}