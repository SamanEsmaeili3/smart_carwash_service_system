import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../constants/app_colors.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Default location (Tehran)
      Provider.of<CustomerProvider>(context, listen: false)
          .searchCarwashes(lat: 35.6892, lon: 51.3890);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerProvider>(context);
    final carwashes = provider.carwashes;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // 1. Center the content for Desktop/Web
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Max width for web
          child: SafeArea(
            child: Column(
              children: [
                // --- HEADER ---
                _buildHeader(context),

                // --- LIST ---
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : carwashes.isEmpty
                          ? const Center(child: Text("هیچ کارواشی یافت نشد."))
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 16, bottom: 80),
                              itemCount: carwashes.length,
                              itemBuilder: (ctx, index) {
                                final item = carwashes[index];
                                return _buildCarwashCard(item);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: BottomNavigationBar(
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            currentIndex: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.search), label: "جستجو"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "پروفایل"),
            ],
            onTap: (index) {},
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final UserModel? user = authProvider.user;

    String displayName = "کاربر گرامی";
    if (user != null && user.email.isNotEmpty) {
      displayName = user.email.split('@')[0];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                   Provider.of<AuthProvider>(context, listen: false).logout();
                   Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "کارواش پرو",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  Text(
                    "سلام، $displayName",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const TextField(
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "جستجوی کارواش...",
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.filter_list, color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarwashCard(dynamic item) {
    String name = item['business_name'] ?? 'نامشخص';
    String address = item['address'] ?? '';
    double rating = double.tryParse(item['rating'].toString()) ?? 0.0;
    String distanceText = item['distance'] != null ? "${item['distance']} km" : "";
    
    // Price formatting
    String minPrice = "0";
    if (item['min_price'] != null) {
      double priceVal = double.tryParse(item['min_price'].toString()) ?? 0.0;
      minPrice = priceVal.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: item['license_photo_url'] != null && item['license_photo_url'].toString().isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(item['license_photo_url']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item['license_photo_url'] == null || item['license_photo_url'].toString().isEmpty
                ? const Center(child: Icon(Icons.store, size: 40, color: Colors.grey))
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text("باز", style: TextStyle(color: Colors.green, fontSize: 12)),
                    ),
                    Expanded(
                      child: Text(
                        name,
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (distanceText.isNotEmpty)
                      Text("($distanceText)", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text("$rating", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        address,
                        textAlign: TextAlign.end,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("رزرو نوبت", style: TextStyle(color: Colors.white)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("شروع قیمت از", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(
                          "$minPrice تومان",
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}