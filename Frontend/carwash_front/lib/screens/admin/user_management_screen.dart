import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../constants/app_colors.dart';
import 'dart:async'; 

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchUsers();
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<AdminProvider>(context, listen: false).fetchUsers(query: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت کاربران'),
        backgroundColor: AppColors.adminAppBar,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'جستجو (نام، ایمیل، موبایل)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          // User List
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (provider.usersList.isEmpty) {
                  return const Center(child: Text("کاربری یافت نشد."));
                }

                return ListView.builder(
                  itemCount: provider.usersList.length,
                  itemBuilder: (context, index) {
                    final user = provider.usersList[index];
                    final isActive = user['is_active'] ?? true;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive ? Colors.blue.shade100 : Colors.red.shade100,
                          child: Icon(
                            Icons.person,
                            color: isActive ? Colors.blue : Colors.red,
                          ),
                        ),
                        title: Text(user['full_name'] ?? 'بدون نام'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email']),
                            Text(user['phone_number'] ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: isActive ? "مسدود کردن کاربر" : "فعال‌سازی مجدد",
                          icon: Icon(
                            isActive ? Icons.block : Icons.check_circle_outline,
                            color: isActive ? Colors.red : Colors.green,
                          ),
                          onPressed: () => _showBanDialog(context, provider, user['id'], isActive),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBanDialog(BuildContext context, AdminProvider provider, int userId, bool isActive) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isActive ? "مسدود کردن کاربر" : "فعال‌سازی کاربر"),
        content: Text(isActive 
          ? "آیا مطمئن هستید که می‌خواهید دسترسی این کاربر را قطع کنید؟" 
          : "آیا دسترسی این کاربر مجدداً برقرار شود؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("انصراف")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.toggleUserBan(userId);
            },
            child: Text(isActive ? "مسدود شود" : "فعال شود"),
          ),
        ],
      ),
    );
  }
}