import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';

class LocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLon;

  const LocationPickerScreen({
    super.key,
    this.initialLat = 35.7594, // پیش‌فرض تهران
    this.initialLon = 51.4103,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final MapController _mapController;
  late LatLng _currentCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = LatLng(widget.initialLat, widget.initialLon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ۱. نقشه
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                if (position.center != null) {
                  _currentCenter = position.center!;
                }
              },
            ),
            children: [
              TileLayer(
                // Use standard OpenStreetMap instead of CartoCDN
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // OSM does not use subdomains like {s}, so we remove that line
                userAgentPackageName: 'com.carwash.app.pro',
              ),
            ],
          ),

          // ۲. پین وسط صفحه (ثابت)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 40,
              ), // کمی بالاتر برای دیده شدن نوک پین
              child: Icon(
                Icons.location_on,
                size: 50,
                color: AppColors.primary,
              ),
            ),
          ),

          // ۳. هدر بازگشت
          Positioned(
            top: 50,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ۴. دکمه تایید پایین صفحه
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: CustomButton(
              text: "تایید موقعیت و جستجو",
              color: AppColors.primary,
              onPressed: () {
                // برگرداندن مختصات انتخاب شده به صفحه قبل
                Navigator.pop(context, _currentCenter);
              },
            ),
          ),
        ],
      ),
    );
  }
}
