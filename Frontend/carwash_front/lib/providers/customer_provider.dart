import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/carwash_service_model.dart'; // We can reuse models or make a new one

class CustomerProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<dynamic> _carwashes = [];
  bool _isLoading = false;

  List<dynamic> get carwashes => _carwashes;
  bool get isLoading => _isLoading;

  // Fetch the list (supports search query)
  Future<void> searchCarwashes({String? query, double? lat, double? lon}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Build URL: /api/carwash/search/?lat=...&lon=...
      String endpoint = '/carwash/search/?';
      if (lat != null && lon != null) {
        endpoint += 'lat=$lat&lon=$lon&';
      }
      // If we implemented text search in backend, we'd add &q=$query here

      final response = await _api.get(endpoint, auth: false); // Public API

      if (response is List) {
        _carwashes = response;
      }
    } catch (e) {
      print("Search Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}