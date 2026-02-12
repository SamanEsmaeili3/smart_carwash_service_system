import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/error_handler.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _api.get(ApiConstants.customerProfile, auth: true);
      if (res is Map) {
        _profile = Map<String, dynamic>.from(res);
      } else {
        _profile = null;
      }
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('پروفایل'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final authProvider = Provider.of<AuthProvider>(context);
          final email = authProvider.user?.email ?? '';
          final fullName =
              (_profile?['full_name']?.toString().trim().isNotEmpty ?? false)
                  ? _profile!['full_name'].toString()
                  : 'کاربر گرامی';
          final phone = _profile?['phone_number']?.toString().trim() ?? '';
          final displayPhone = phone.isNotEmpty ? phone : 'ثبت نشده';
          final displayError =
              (_error != null &&
                      (_error!.toLowerCase().contains('<!doctype') ||
                          _error!.toLowerCase().contains('<html') ||
                          _error!.toLowerCase().contains('<head')))
                  ? 'پاسخ نامعتبر از سرور. لطفاً آدرس سرور را بررسی کنید.'
                  : _error;

          final content = RefreshIndicator(
            onRefresh: _fetchProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayError != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displayError,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          TextButton(
                            onPressed: _fetchProfile,
                            child: const Text('تلاش مجدد'),
                          ),
                        ],
                      ),
                    ),
                  _buildInfoCard(fullName, email, displayPhone),
                  const SizedBox(height: 16),
                  const Text(
                    'دسترسی‌های سریع',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildActionCard(
                        title: 'سفارش‌های من',
                        icon: Icons.history,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pushNamed(context, '/customer/history');
                        },
                        width: isWide ? 260 : double.infinity,
                      ),
                      _buildActionCard(
                        title: 'خودروهای من',
                        icon: Icons.directions_car,
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.pushNamed(context, '/customer/vehicles');
                        },
                        width: isWide ? 260 : double.infinity,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

          if (!isWide) return content;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: content,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String fullName, String email, String phone) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.email, 'ایمیل', email),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, 'تلفن', phone),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
