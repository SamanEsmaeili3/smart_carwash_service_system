import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/search_provider.dart';
import '../../constants/app_colors.dart';
import '../../models/carwash_model.dart';
import 'carwash_profile_screen.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  @override
  void initState() {
    super.initState();
    // اجرای جستجو بلافاصله پس از باز شدن صفحه
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false).searchCarwashes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "لیست کارواش ها",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: "فیلترها",
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Consumer<SearchProvider>(
        builder: (context, provider, child) {
          // ۱. حالت لودینگ
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // ۲. حالت خطا
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "خطا در دریافت اطلاعات",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => provider.searchCarwashes(),
                    child: const Text("تلاش مجدد"),
                  ),
                ],
              ),
            );
          }

          // ۳. لیست خالی
          if (provider.results.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "کارواشی با این مشخصات یافت نشد.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // ۴. نمایش لیست نتایج
          return RefreshIndicator(
            onRefresh: () => provider.searchCarwashes(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.results.length,
              itemBuilder: (context, index) {
                return _CarwashResultCard(carwash: provider.results[index]);
              },
            ),
          );
        },
      ),
    );
  }

  // --- منوی فیلترها (Bottom Sheet) ---
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<SearchProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "فیلترها",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (provider.minPrice > 0 || provider.minRating > 0)
                        TextButton(
                          onPressed: () {
                            provider.setPriceFilter(0);
                            provider.setRatingFilter(0);
                            provider.searchCarwashes();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "حذف فیلترها",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // فیلتر امتیاز
                  Text(
                    "حداقل امتیاز: ${provider.minRating.toInt()}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: provider.minRating,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: provider.minRating.toInt().toString(),
                    activeColor: Colors.amber,
                    onChanged: (val) => provider.setRatingFilter(val),
                  ),

                  const SizedBox(height: 16),

                  // فیلتر قیمت
                  Text(
                    "حداقل قیمت سرویس پایه: ${provider.minPrice.toInt()} تومان",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: provider.minPrice,
                    min: 0,
                    max: 500000,
                    divisions: 10,
                    label: provider.minPrice.toInt().toString(),
                    activeColor: AppColors.primary,
                    onChanged: (val) => provider.setPriceFilter(val),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        provider.searchCarwashes(); // اعمال فیلتر و جستجو
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "اعمال فیلتر",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// --- ویجت کارت نمایش کارواش ---
class _CarwashResultCard extends StatelessWidget {
  final CarwashModel carwash;

  const _CarwashResultCard({required this.carwash});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // هدایت به صفحه پروفایل و رزرو
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CarwashProfileScreen(carwashId: carwash.id!),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- بخش تصویر (با هندلینگ خطا) ---
            SizedBox(
              height: 150,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child:
                    (carwash.licensePhotoUrl.isNotEmpty &&
                            carwash.licensePhotoUrl.startsWith('http'))
                        ? Image.network(
                          carwash.licensePhotoUrl,
                          fit: BoxFit.cover,
                          // اگر عکس لود نشد (404 و غیره)
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                          // نمایش لودینگ تا زمان دانلود عکس
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image, color: Colors.grey),
                              ),
                            );
                          },
                        )
                        // اگر لینکی وجود نداشت
                        : Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.store,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
              ),
            ),

            // --- بخش اطلاعات ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        carwash.businessName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      // نمایش امتیاز (اگر در مدل وجود داشت، اینجا قرار دهید)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              "4.5",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          carwash.address,
                          style: const TextStyle(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
