import 'package:carwash_front/providers/customer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Position? _currentPosition;

  final MapController _mapController = MapController();
  final PopupController _popupController = PopupController();
  CarwashMarker? _selectedCarwashMarker;

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سرویس موقعیت یاب غیر فعال است!')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مجوز های مکانی رد شده اند!')),
        );
        return;
      }
    }

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در موقعیت یابی خطایی پیش آمد!')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _currentPosition = position;
    });

    // automatically trigger search after getting location
    _searchNearby();
  }

  List<LatLng> _getCarwashCoordinates(List<dynamic> carwashes) {
    return carwashes.map((d) {
      final m = d as Map<String, dynamic>;
      return LatLng(
        double.parse(m['latitude'].toString()),
        double.parse(m['longitude'].toString()),
      );
    }).toList();
  }

  void _fitCarwashes(List<dynamic> carwashes) {
    if (carwashes.isEmpty) return;

    final coords = _getCarwashCoordinates(carwashes);

    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: coords,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  void _fitUser() {
    if (_currentPosition == null) return;

    _mapController.move(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      15,
    );
  }

  void _searchNearby() async {
    if (_currentPosition == null) {
      // Handle case where location is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ابتدا موقعیت خود را دریافت کنید.')),
      );
      return;
    }
    final provider = Provider.of<CustomerProvider>(context, listen: false);

    await provider.searchCarwashes(
      lat: _currentPosition!.latitude,
      lon: _currentPosition!.longitude,
    );

    if (!mounted) return;

    // Fit carwashes AFTER data arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitCarwashes(provider.carwashes);
    });
  }

  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   appBar: AppBar(
    //     title: const Text('جست و جوی کارواش'),
    //     actions: [
    //       IconButton(
    //         icon: Icon(_isMapView ? Icons.list : Icons.map),
    //         onPressed: () {
    //           setState(() {
    //             _isMapView = !_isMapView;
    //           });
    //         },
    //       ),
    //     ],
    //   ),
    //   body:
    // );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: _determinePosition,
            child: const Text("دریافت مکان و جست و جو"),
          ),
        ),
        if (_currentPosition != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
            ),
          ),
        Expanded(
          child: Expanded(
            child: Stack(
              children: [
                _buildMapView(),

                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    children: [
                      _circleButton(icon: Icons.my_location, onTap: _fitUser),
                      const SizedBox(height: 10),
                      _circleButton(
                        icon: Icons.car_repair,
                        onTap: () {
                          final carwashes =
                              context.read<CustomerProvider>().carwashes;
                          _fitCarwashes(carwashes);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(14),
        elevation: 6,
      ),
      onPressed: onTap,
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _buildMapView() {
    final provider = Provider.of<CustomerProvider>(context);
    final carwashMarkers = provider.carwashes.map(
      (dynamic d) => _buildCarwashMarker(d as Map<String, dynamic>),
    );
    final markers = carwashMarkers.map((m) => m.marker).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter:
            _currentPosition != null
                ? LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                )
                : const LatLng(35.715298, 51.404343),
        initialZoom: 13,
        onTap: (_, __) {
          _popupController.hideAllPopups();
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
        ),

        /// Markers
        MarkerLayer(
          markers: [
            if (_currentPosition != null)
              Marker(
                width: 60,
                height: 60,
                point: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 36,
                ),
              ),
            ...markers,
          ],
        ),

        /// Popup layer
        PopupMarkerLayer(
          options: PopupMarkerLayerOptions(
            popupController: _popupController,
            markers: markers,
            popupDisplayOptions: PopupDisplayOptions(
              builder: (context, marker) {
                final selected = _selectedCarwashMarker;
                if (selected == null) {
                  return const SizedBox.shrink();
                }
                return _buildCarwashPopup(selected.data);
              },
            ),
          ),
        ),
      ],
    );
  }

  CarwashMarker _buildCarwashMarker(Map<String, dynamic> carwash) {
    late final CarwashMarker carwashMarker;

    final marker = Marker(
      width: 140,
      height: 90,
      point: LatLng(
        double.parse(carwash['latitude'].toString()),
        double.parse(carwash['longitude'].toString()),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCarwashMarker = carwashMarker;
          });
          _popupController.showPopupsOnlyFor([carwashMarker.marker]);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: Text(
                carwash['business_name'],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.location_on, color: Colors.red, size: 40),
          ],
        ),
      ),
    );

    carwashMarker = CarwashMarker(marker: marker, data: carwash);
    return carwashMarker;
  }

  Widget _buildCarwashPopup(Map<String, dynamic> carwash) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              carwash['business_name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text('📍 ${carwash['address']}'),
            Text('⭐ امتیاز: ${carwash['rating']}'),
            Text('💰 حداقل قیمت: ${carwash['min_price']}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate or show details
              },
              child: const Text('مشاهده جزئیات'),
            ),
          ],
        ),
      ),
    );
  }
}

class CarwashMarker {
  final Marker marker;
  final Map<String, dynamic> data;

  CarwashMarker({required this.marker, required this.data});
}
