import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';

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
    // Fetch profile data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false)
          .fetchCarwashProfile(widget.carwashId);
    });
  }

  void _onContinuePressed() async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    
    // Call API to create order draft
    final orderId = await provider.prepareOrder();

    if (orderId != null && mounted) {
      // Navigate to Time Selection (Placeholder for next story)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("سفارش $orderId ایجاد شد. رفتن به انتخاب زمان..."),
          backgroundColor: AppColors.success,
        ),
      );
      // Navigator.pushNamed(context, '/select_time', arguments: orderId);
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
          // 1. Loading State
          if (provider.isLoadingProfile) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error State
          if (provider.profileError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.profileError!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: () => provider.fetchCarwashProfile(widget.carwashId),
                    child: const Text("تلاش مجدد"),
                  )
                ],
              ),
            );
          }

          final profile = provider.profile;
          if (profile == null) return const Center(child: Text("اطلاعات یافت نشد"));

          // 3. Main Content
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // --- Header Image & Info ---
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(profile.businessName, style: const TextStyle(fontSize: 16)),
                      background: profile.licensePhotoUrl.isNotEmpty && 
                                  profile.licensePhotoUrl.startsWith('http')
                          ? Image.network(
                              profile.licensePhotoUrl, // Using license photo as placeholder if no gallery
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(color: Colors.grey),
                            )
                          : Container(color: Colors.grey),
                    ),
                  ),

                  // --- Info Section ---
                  SliverToBoxAdapter(
                    child: Padding(
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
                          const Divider(height: 30),
                          const Text(
                            "انتخاب سرویس‌ها",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Services List (Checkboxes) ---
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = profile.services[index];
                        final isSelected = provider.selectedServiceIds.contains(service.id);

                        return CheckboxListTile(
                          title: Text(service.serviceName),
                          subtitle: Text(service.description),
                          secondary: Text(
                            "${service.price}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          value: isSelected,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            // Convert price to double for calculation logic
                            provider.toggleService(service.id!, service.price.toDouble());
                          },
                        );
                      },
                      childCount: profile.services.length,
                    ),
                  ),
                  
                  // Extra space for the bottom sheet
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),

              // --- Bottom Sheet (Total Price & Continue) ---
              if (provider.selectedServiceIds.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("مبلغ قابل پرداخت", style: TextStyle(color: Colors.grey)),
                            Text(
                              "${provider.localTotalPrice.toInt()} تومان",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}