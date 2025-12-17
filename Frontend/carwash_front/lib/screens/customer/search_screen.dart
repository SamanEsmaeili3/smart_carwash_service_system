import 'package:carwash_front/providers/customer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _isMapView = false;
  Position? _currentPosition;

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location services are disabled. Please enable it.'),
        ),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied, we cannot request permissions.',
          ),
        ),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });

    // automatically trigger search after getting location
    _searchNearby();
  }

  void _searchNearby() {
    if (_currentPosition != null) {
      Provider.of<CustomerProvider>(context, listen: false).searchCarwashes(
        lat: _currentPosition!.latitude,
        lon: _currentPosition!.longitude,
      );
    } else {
      // Handle case where location is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please get your location first.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Carwashes'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _determinePosition,
              child: const Text("Get Current Location & Search"),
            ),
          ),
          if (_currentPosition != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'LAT: ${_currentPosition!.latitude}, LON: ${_currentPosition!.longitude}',
              ),
            ),
          Expanded(child: _isMapView ? _buildMapView() : _buildListView()),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.carwashes.isEmpty) {
          return const Center(child: Text('No carwashes found nearby.'));
        }

        return ListView.builder(
          itemCount: provider.carwashes.length,
          itemBuilder: (context, index) {
            final carwash = provider.carwashes[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(carwash['business_name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Address: ${carwash['address']}'),
                    Text('Rating: ${carwash['rating']}'),
                    Text('Min Price: ${carwash['min_price']}'),
                  ],
                ),
                trailing: Text('${carwash['distance']} km'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapView() {
    final provider = Provider.of<CustomerProvider>(context);
    final carwashes = provider.carwashes;

    return FlutterMap(
      options: MapOptions(
        initialCenter:
            _currentPosition != null
                ? LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                )
                : const LatLng(35.715298, 51.404343), // Tehran
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers:
              carwashes.map((carwash) {
                return Marker(
                  width: 80.0,
                  height: 80.0,
                  point: LatLng(carwash['latitude'], carwash['longitude']),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
