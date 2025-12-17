import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../models/carwash_model.dart';

class SearchProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<CarwashModel> _results = [];
  bool _isLoading = false;
  String? _error;

  // Filter States
  double _minRating = 0.0;
  double _minPrice = 0.0;

  // Default Location (Tehran) - In real app, get this from Geolocation
  double _lat = 35.759432;
  double _lon = 51.410376;

  // Getters
  List<CarwashModel> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get minRating => _minRating;
  double get minPrice => _minPrice;

  // Setters for UI to update filters
  void setRatingFilter(double value) {
    _minRating = value;
    notifyListeners();
  }

  void setPriceFilter(double value) {
    _minPrice = value;
    notifyListeners();
  }

  void setLocation(double lat, double lon) {
    _lat = lat;
    _lon = lon;
  }

  /// Execute Search (User Story 1)
  Future<void> searchCarwashes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Prepare Query Params
      final Map<String, String> queryParams = {
        'lat': _lat.toString(),
        'lon': _lon.toString(),
      };

      // Add optional filters if set
      if (_minRating > 0) {
        queryParams['min_rating'] = _minRating.toInt().toString();
      }
      if (_minPrice > 0) {
        queryParams['min_price'] = _minPrice.toInt().toString();
      }

      // Call API
      final response = await _api.getWithParams(
        ApiConstants.search,
        queryParams,
        auth: true,
      );

      // Parse List
      if (response is List) {
        _results = response.map((e) => CarwashModel.fromJson(e)).toList();
      } else {
        _results = [];
      }
    } catch (e) {
      _error = "خطا در جستجو: $e";
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
