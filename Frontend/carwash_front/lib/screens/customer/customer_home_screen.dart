import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/search_provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../models/carwash_model.dart';
import 'carwash_profile_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final MapController _mapController = MapController();

  bool _isMapView = false; // Only used for Mobile

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false).searchCarwashes();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String value) {
    final provider = Provider.of<SearchProvider>(context, listen: false);
    provider.setSearchQuery(value);
    provider.searchCarwashes();
  }

  void _onClearSearch() {
    _searchCtrl.clear();
    final provider = Provider.of<SearchProvider>(context, listen: false);
    provider.setSearchQuery('');
    provider.searchCarwashes();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint: 800px
        bool isWideScreen = constraints.maxWidth > 800;

        return Scaffold(
          backgroundColor: AppColors.background,
          // Hide FAB on Web (Split view doesn't need toggle)
          floatingActionButton:
              isWideScreen
                  ? null
                  : FloatingActionButton.extended(
                    onPressed: () {
                      setState(() {
                        _isMapView = !_isMapView;
                      });
                    },
                    backgroundColor: AppColors.primary,
                    icon: Icon(
                      _isMapView ? Icons.list : Icons.map,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isMapView ? "مشاهده لیست" : "مشاهده روی نقشه",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          body: SafeArea(
            child:
                isWideScreen
                    ? _buildWebLayout() // Split View
                    : _buildMobileLayout(), // Toggle View
          ),
        );
      },
    );
  }

  // --- 📱 MOBILE LAYOUT (Toggle Map/List) ---
  Widget _buildMobileLayout() {
    final searchProvider = Provider.of<SearchProvider>(context);
    final results = searchProvider.results;

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child:
              searchProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : searchProvider.error != null
                  ? _buildErrorState(searchProvider)
                  : results.isEmpty
                  ? _buildEmptyState(searchProvider)
                  : _isMapView
                  ? _buildMapView(searchProvider)
                  : _buildListView(searchProvider),
        ),
      ],
    );
  }

  // --- 💻 WEB LAYOUT (Split Screen) ---
  Widget _buildWebLayout() {
    final searchProvider = Provider.of<SearchProvider>(context);
    final results = searchProvider.results;

    return Row(
      children: [
        // Left Side: Sidebar (Header + List)
        SizedBox(
          width: 400, // Fixed width for sidebar
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child:
                    searchProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : searchProvider.error != null
                        ? _buildErrorState(searchProvider)
                        : results.isEmpty
                        ? _buildEmptyState(searchProvider)
                        : _buildListView(searchProvider),
              ),
            ],
          ),
        ),
        // Right Side: Map (Takes remaining space)
        Expanded(
          child: Stack(
            children: [
              _buildMapView(searchProvider),
              // Shadow to separate map from sidebar
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(5, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 🗺️ MAP WIDGET ---
  Widget _buildMapView(SearchProvider provider) {
    final userLocation = LatLng(35.759432, 51.410376); // Default Center

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: userLocation, initialZoom: 13.0),
      children: [
        TileLayer(
          // Use standard OpenStreetMap instead of CartoCDN
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // OSM does not use subdomains like {s}, so we remove that line
          userAgentPackageName: 'com.carwash.app.pro',
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: userLocation,
              color: Colors.blue.withOpacity(0.1),
              borderColor: Colors.blue,
              borderStrokeWidth: 2,
              radius: provider.radius * 1000,
              useRadiusInMeter: true,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            // User Location
            Marker(
              point: userLocation,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 30,
              ),
            ),
            // Carwash Markers
            ...provider.results.map((carwash) {
              return Marker(
                point: LatLng(carwash.latitude, carwash.longitude),
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () {
                    _showCarwashPreview(context, carwash);
                  },
                  child: const Icon(
                    Icons.local_car_wash,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  // --- 📋 LIST WIDGET ---
  Widget _buildListView(SearchProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.searchCarwashes(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 80),
        itemCount: provider.results.length,
        itemBuilder: (ctx, index) {
          return _CarwashResultCard(carwash: provider.results[index]);
        },
      ),
    );
  }

  // --- 🏠 HEADER WIDGET ---
  Widget _buildHeader(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    String displayName =
        user != null && user.email.isNotEmpty
            ? user.email.split('@')[0]
            : "کاربر گرامی";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
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
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
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
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "سلام، $displayName",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppColors.primary),
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
            child: TextField(
              controller: _searchCtrl,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearchSubmitted,
              onChanged: (val) {
                setState(() {});
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "جستجوی سرویس (مثلاً روشویی...)",
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchCtrl.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: _onClearSearch,
                        )
                        : IconButton(
                          icon: const Icon(
                            Icons.filter_list,
                            color: AppColors.primary,
                          ),
                          onPressed: () => _showFilterBottomSheet(context),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS (Empty, Error, BottomSheets) ---

  Widget _buildEmptyState(SearchProvider provider) {
    if (provider.searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              "سرویسی با عنوان \"${provider.searchQuery}\" یافت نشد.",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton(
              onPressed: _onClearSearch,
              child: const Text("نمایش همه کارواش‌ها"),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "در شعاع ${provider.radius.toInt()} کیلومتری کارواشی یافت نشد.",
            style: const TextStyle(color: Colors.grey),
          ),
          TextButton(
            onPressed: () {
              provider.setRadius(50);
              provider.searchCarwashes();
            },
            child: const Text("افزایش شعاع جستجو"),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(SearchProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "خطا در دریافت اطلاعات",
            style: TextStyle(color: Colors.red),
          ),
          TextButton(
            onPressed: () => provider.searchCarwashes(),
            child: const Text("تلاش مجدد"),
          ),
        ],
      ),
    );
  }

  // Updated to handle Web/Desktop dialogs vs Mobile BottomSheet
  void _showFilterBottomSheet(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    if (isWideScreen) {
      showDialog(
        context: context,
        builder:
            (ctx) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: _buildFilterContent(context),
              ),
            ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_buildFilterContent(context)],
            ),
          );
        },
      );
    }
  }

  // Refactored filter content to reuse in Dialog and BottomSheet
  Widget _buildFilterContent(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "فیلترها",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "شعاع جستجو",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${provider.radius.toInt()} km",
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ),
            Slider(
              value: provider.radius,
              min: 5,
              max: 100,
              divisions: 19,
              label: "${provider.radius.toInt()} km",
              onChanged: (val) => provider.setRadius(val),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "حداقل امتیاز",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${provider.minRating.toInt()}",
                  style: const TextStyle(color: Colors.amber),
                ),
              ],
            ),
            Slider(
              value: provider.minRating,
              min: 0,
              max: 5,
              divisions: 5,
              activeColor: Colors.amber,
              label: provider.minRating.toInt().toString(),
              onChanged: (val) => provider.setRatingFilter(val),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  provider.searchCarwashes();
                  Navigator.pop(context);
                },
                child: const Text(
                  "اعمال فیلتر",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCarwashPreview(BuildContext context, CarwashModel carwash) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [_CarwashResultCard(carwash: carwash)],
          ),
        );
      },
    );
  }
}

// --- CARD COMPONENT ---
class _CarwashResultCard extends StatelessWidget {
  final CarwashModel carwash;

  const _CarwashResultCard({required this.carwash});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                          errorBuilder:
                              (ctx, err, stack) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                        : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.store,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              carwash.rating != null
                                  ? carwash.rating!.toStringAsFixed(1)
                                  : "جدید",
                              style: const TextStyle(
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          carwash.address,
                          textAlign: TextAlign.end,
                          style: const TextStyle(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => CarwashProfileScreen(
                                  carwashId: carwash.id!,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "رزرو نوبت",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
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
