import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';
import '../../models/carwash_model.dart';
import 'user_management_screen.dart';

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
        length: 4, // 4 Tabs: Metrics, Pending, Active, Rejected
        child: Scaffold(
          appBar: AppBar(
            title: const Text('داشبورد ادمین'),
            backgroundColor: AppColors.adminAppBar,
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'مدیریت کاربران',
                icon: const Icon(Icons.people_alt_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                  );
                },
              ),
              
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
              // FIX: isScrollable is false so tabs space out evenly across the screen width
              isScrollable: false, 
              tabs: [
                // Fulfilling User Story 4.1: Admin Dashboard Metrics [cite: 76]
                Tab(text: "آمار", icon: Text("📊", style: TextStyle(fontSize: 18))), 
                Tab(text: "جدید", icon: Text("⏳", style: TextStyle(fontSize: 18))),
                Tab(text: "فعال", icon: Text("✅", style: TextStyle(fontSize: 18))),
                Tab(text: "رد شده", icon: Text("❌", style: TextStyle(fontSize: 18))),
              ],
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: const TabBarView(
                children: [
                  _DashboardMetricsTab(), // Real data metrics 
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
// TAB 0: Dashboard Metrics Overview (User Story 4.1) [cite: 75]
// -----------------------------------------------------------------------------
class _DashboardMetricsTab extends StatefulWidget {
  const _DashboardMetricsTab();

  @override
  State<_DashboardMetricsTab> createState() => _DashboardMetricsTabState();
}

class _DashboardMetricsTabState extends State<_DashboardMetricsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Calls Task-B5.10 backend logic via the provider [cite: 81]
      Provider.of<AdminProvider>(context, listen: false).fetchAdminStats(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.adminStats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = provider.adminStats ?? {
          "total_users": 0,
          "active_carwashes": 0,
          "completed_orders": 0
        };

        return RefreshIndicator(
          onRefresh: () => provider.fetchAdminStats(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "خلاصه وضعیت پلتفرم",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 20),
              
              // Metric Cards for Total Users, Active Carwashes, Total Orders Completed [cite: 78]
              _buildStatCard(
                "کل کاربران", 
                stats["total_users"].toString(), 
                "👥", 
                Colors.blue
              ),
              _buildStatCard(
                "کارواش‌های فعال", 
                stats["active_carwashes"].toString(), 
                "🚿", 
                Colors.green
              ),
              _buildStatCard(
                "سفارش‌های تکمیل شده", 
                stats["completed_orders"].toString(), 
                "🛍️", 
                Colors.orange
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, String iconChar, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              // Use text emoji to ensure visibility despite Chrome CSP issues
              child: Text(iconChar, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  Text(
                    value, 
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
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
              return CarwashApplicationCard(
                carwash: carwash, 
                isPending: false, 
                isActiveTab: true
              );
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
              return CarwashApplicationCard(
                carwash: carwash,
                isPending: false,
                isRejectedTab: true,
              );
            },
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// SHARED WIDGET: Carwash Card (Pending/Approved/Rejected)
// -----------------------------------------------------------------------------
class CarwashApplicationCard extends StatelessWidget {
  final CarwashModel carwash;
  final bool isPending;
  final bool isActiveTab; 
  final bool isRejectedTab;

  const CarwashApplicationCard({
    super.key,
    required this.carwash,
    required this.isPending,
    this.isActiveTab = false,
    this.isRejectedTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context, listen: false);

    Color statusColor;
    String statusText;
    if (isPending) {
      statusColor = Colors.orange;
      statusText = "در انتظار";
    } else if (isRejectedTab) {
      statusColor = Colors.red;
      statusText = "رد شده";
    } else {
      statusColor = Colors.green;
      statusText = "فعال";
    }

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
                Expanded(
                  child: Text(
                    carwash.businessName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, carwash.address),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.phone, carwash.phoneNumber),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
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

                const SizedBox(width: 8),

                if (isPending) ...[
                  Expanded(
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
                    child: CustomButton(
                      text: 'تایید',
                      onPressed: () => provider.manageRequest(carwash.id!, "approve"),
                      color: AppColors.success,
                      textColor: Colors.white,
                      height: 40,
                    ),
                  ),
                ],

                if (isActiveTab) ...[
                  IconButton(
                    tooltip: "تعلیق (رد کردن)",
                    icon: const Icon(Icons.block, color: Colors.orange),
                    onPressed: () => _showRejectDialog(context, provider),
                  ),
                  IconButton(
                    tooltip: "حذف کامل",
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _showDeleteDialog(context, provider),
                  ),
                ],

                if (isRejectedTab) ...[
                   IconButton(
                    tooltip: "حذف کامل",
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _showDeleteDialog(context, provider),
                  ),
                ]
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
                const Text('ساعات کاری:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  void _showRejectDialog(BuildContext context, AdminProvider provider) {
    final TextEditingController reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تعلیق / رد درخواست", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("لطفاً دلیل را بنویسید:", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(hintText: "مثلاً: عکس پروانه کسب ناخوانا است...", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("انصراف", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(ctx);
              provider.manageRequest(carwash.id!, "reject", reason: reasonCtrl.text);
            },
            child: const Text("تایید", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("حذف کامل کارواش", textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          "آیا مطمئن هستید؟\nاین کار غیرقابل برگشت است.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("انصراف")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteCarwash(carwash.id!); 
            },
            child: const Text("حذف", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}