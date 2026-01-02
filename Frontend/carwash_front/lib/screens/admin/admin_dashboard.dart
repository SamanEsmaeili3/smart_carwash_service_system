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
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(),
      child: DefaultTabController(
        length: 3, // 3 Tabs: Pending, Active, Rejected
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
                Tab(text: "جدید", icon: Icon(Icons.hourglass_empty)),
                Tab(text: "فعال", icon: Icon(Icons.check_circle_outline)),
                Tab(text: "رد شده", icon: Icon(Icons.cancel_outlined)),
              ],
            ),
          ),
          // Removed 'const' to prevent build errors
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: const TabBarView(
                children: [
                  _PendingListTab(),
                  _ApprovedListTab(),
                  _RejectedListTab(),
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
              return CarwashApplicationCard(carwash: carwash, isPending: false);
            },
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: Rejected Carwashes
// -----------------------------------------------------------------------------
class _RejectedListTab extends StatefulWidget {
  const _RejectedListTab();

  @override
  State<_RejectedListTab> createState() => _RejectedListTabState();
}

class _RejectedListTabState extends State<_RejectedListTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchRejectedCarwashes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.rejectedList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.rejectedList.isEmpty) {
          return const Center(child: Text('هیچ کارواش رد شده‌ای وجود ندارد.'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchRejectedCarwashes(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 20),
            itemCount: provider.rejectedList.length,
            itemBuilder: (context, index) {
              final carwash = provider.rejectedList[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 1,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.block, color: Colors.white),
                  ),
                  title: Text(
                    carwash.businessName,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text("وضعیت: رد شده"),
                  trailing: const Icon(Icons.cancel, color: Colors.red),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// SHARED WIDGET: Carwash Card (Pending/Approved)
// -----------------------------------------------------------------------------
class CarwashApplicationCard extends StatelessWidget {
  final CarwashModel carwash;
  final bool isPending;

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
                      fontWeight: FontWeight.bold,
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

            Row(
              children: [
                // Info Button
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

                // Approve/Reject Buttons (Only if Pending)
                if (isPending) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'رد',
                      onPressed: () => _showRejectDialog(context, provider),
                      color: Colors.white,
                      textColor: AppColors.error,
                      borderColor: AppColors.error,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                            fontWeight: FontWeight.bold,
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

  // Function to show the input dialog
  void _showRejectDialog(BuildContext context, AdminProvider provider) {
    final TextEditingController reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "دلیل رد درخواست",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "لطفاً دلیل رد کردن این کارواش را بنویسید. این متن برای کاربر ایمیل خواهد شد.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                hintText: "مثلاً: عکس پروانه کسب ناخوانا است...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Cancel
            child: const Text("انصراف", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              // 1. Close Dialog
              Navigator.pop(ctx);
              
              // 2. Call Provider with the text
              provider.manageRequest(
                carwash.id!, 
                "reject", 
                reason: reasonCtrl.text
              );
            },
            child: const Text("تایید و رد کردن", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}