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
    this.initialLat = 35.7546, // میدان ونک
    this.initialLon = 51.4090, // میدان ونک
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

    // مقدار اولیه نقشه = میدان ونک
    _currentCenter = LatLng(widget.initialLat, widget.initialLon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 1️⃣ نقشه
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16.0, // زوم مناسب برای میدان
              onPositionChanged: (position, hasGesture) {
                if (position.center != null) {
                  _currentCenter = position.center!;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.carwash.app.pro',
              ),
            ],
          ),

          /// 2️⃣ پین ثابت وسط
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(
                Icons.location_on,
                size: 50,
                color: AppColors.primary,
              ),
            ),
          ),

          /// 3️⃣ دکمه بازگشت
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

          /// 4️⃣ تایید موقعیت
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: CustomButton(
              text: "تایید موقعیت و جستجو",
              color: AppColors.primary,
              onPressed: () {
                Navigator.pop(context, _currentCenter);
              },
            ),
          ),
        ],
      ),
    );
  }
}
