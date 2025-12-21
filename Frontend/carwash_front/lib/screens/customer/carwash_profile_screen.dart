import 'package:carwash_front/services/utiles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../models/carwash_model.dart'; // Ensure this is imported for the type

class CarwashProfileScreen extends StatefulWidget {
  final int carwashId;

  const CarwashProfileScreen({super.key, required this.carwashId});

  @override
  State<CarwashProfileScreen> createState() => _CarwashProfileScreenState();
}

class _CarwashProfileScreenState extends State<CarwashProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(
        context,
        listen: false,
      ).fetchCarwashProfile(widget.carwashId);
    });
  }

  void _onContinuePressed() async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final orderId = await provider.prepareOrder();

    if (orderId != null && mounted) {
      // ✅ NAVIGATE TO TIME SELECTION
      Navigator.pushNamed(context, '/select_time', arguments: orderId);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("خطا در ایجاد سفارش. لطفا دوباره تلاش کنید."),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingProfile) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.profileError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.profileError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        () => provider.fetchCarwashProfile(widget.carwashId),
                    child: const Text("تلاش مجدد"),
                  ),
                ],
              ),
            );
          }

          final profile = provider.profile;
          if (profile == null) {
            return const Center(child: Text("اطلاعات یافت نشد"));
          }

          // --- RESPONSIVE LAYOUT BUILDER ---
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return _buildWebLayout(context, provider, profile);
              } else {
                return _buildMobileLayout(context, provider, profile);
              }
            },
          );
        },
      ),
    );
  }

  // ==========================
  // 📱 MOBILE LAYOUT
  // ==========================
  Widget _buildMobileLayout(
    BuildContext context,
    BookingProvider provider,
    CarwashModel profile,
  ) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  profile.businessName,
                  style: const TextStyle(fontSize: 16),
                ),
                background: _buildCarwashImage(profile.licensePhotoUrl),
              ),
            ),
            SliverToBoxAdapter(child: _buildInfoSection(profile)),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildServiceItem(profile.services[index], provider);
              }, childCount: profile.services.length),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        if (provider.selectedServiceIds.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSummary(provider, isWeb: false),
          ),
      ],
    );
  }

  // ==========================
  // 💻 WEB LAYOUT
  // ==========================
  Widget _buildWebLayout(
    BuildContext context,
    BookingProvider provider,
    CarwashModel profile,
  ) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Left Column: Content (Scrollable) ---
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: _buildCarwashImage(profile.licensePhotoUrl),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Title & Info
                    Text(
                      profile.businessName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoSection(profile),
                    const Divider(height: 40),

                    // 3. Services
                    const Text(
                      "انتخاب سرویس‌ها",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: profile.services.length,
                      itemBuilder: (context, index) {
                        return _buildServiceItem(
                          profile.services[index],
                          provider,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // --- Right Column: Sticky Summary Card ---
            const SizedBox(width: 32),
            Expanded(
              flex: 1,
              child: Column(
                children: [_buildBottomSummary(provider, isWeb: true)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================
  // 🧩 REUSABLE WIDGETS
  // ==========================

  Widget _buildCarwashImage(String url) {
    return (url.isNotEmpty && url.startsWith('http'))
        ? Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
            );
          },
        )
        : Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.store, size: 50, color: Colors.grey),
          ),
        );
  }

  Widget _buildInfoSection(CarwashModel profile) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(profile.address)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(profile.phoneNumber),
            ],
          ),
          // Only show divider here on mobile, web handles it differently
        ],
      ),
    );
  }

  Widget _buildServiceItem(dynamic service, BookingProvider provider) {
    final isSelected = provider.selectedServiceIds.contains(service.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          "${formatMoney(service.price)}", // Assuming you handle 'تومان' inside formatMoney or add it here
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        subtitle: Text(service.description),
        secondary: Text(
          service.serviceName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        value: isSelected,
        activeColor: AppColors.primary,
        onChanged: (val) {
          provider.toggleService(service.id!, service.price.toDouble());
        },
      ),
    );
  }

  Widget _buildBottomSummary(BookingProvider provider, {required bool isWeb}) {
    if (!isWeb) {
      // Mobile Style: Bottom Sheet
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "مبلغ قابل پرداخت",
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  "${formatMoney(provider.localTotalPrice)} تومان",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 150,
              child: CustomButton(
                text: "ادامه",
                isLoading: provider.isSubmittingOrder,
                onPressed: _onContinuePressed,
              ),
            ),
          ],
        ),
      );
    } else {
      // Web Style: Sticky Card
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "خلاصه سفارش",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("تعداد سرویس:"),
                Text("${provider.selectedServiceIds.length}"),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("مبلغ کل:"),
                Text(
                  "${formatMoney(provider.localTotalPrice)} تومان",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: "ثبت سفارش و ادامه",
              isLoading: provider.isSubmittingOrder,
              onPressed:
                  provider.selectedServiceIds.isNotEmpty
                      ? _onContinuePressed
                      : null,
            ),
          ],
        ),
      );
    }
  }
}
