import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../constants/api_constants.dart';
import '../models/carwash_model.dart';

class SearchProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<CarwashModel> _results = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  double _minRating = 0.0;
  double _minPrice = 0.0;
  double _radius = 15.0;
  String _searchQuery = '';

  // Default Location (Tehran)
  double _lat = 35.7544;
  double _lon = 51.4105;

  // Getters
  List<CarwashModel> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get minRating => _minRating;
  double get minPrice => _minPrice;
  double get radius => _radius;
  String get searchQuery => _searchQuery;
  double get lat => _lat;
  double get lon => _lon;

  // Setters
  void setRatingFilter(double value) {
    _minRating = value;
    notifyListeners();
  }

  void setPriceFilter(double value) {
    _minPrice = value;
    notifyListeners();
  }

  void setRadius(double value) {
    _radius = value;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
  }

  void clearFilters() {
    _minRating = 0.0;
    _minPrice = 0.0;
    _radius = 15.0;
    _searchQuery = '';
    notifyListeners();
  }

  void updateUserLocation(double newLat, double newLon) {
    _lat = newLat;
    _lon = newLon;
    notifyListeners();

    // Auto-search on location change
    searchCarwashes();
  }

  Future<void> searchCarwashes({String? query}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (query != null) {
      _searchQuery = query;
    }

    try {
      final Map<String, String> queryParams = {
        'lat': _lat.toString(),
        'lon': _lon.toString(),
        'radius': _radius.toInt().toString(),
      };

      if (_minRating > 0) {
        queryParams['min_rating'] = _minRating.toInt().toString();
      }
      if (_minPrice > 0) {
        queryParams['min_price'] = _minPrice.toInt().toString();
      }
      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }

      final response = await _api.getWithParams(
        ApiConstants.search,
        queryParams,
        auth: true,
      );

      if (response is List) {
        _results = response.map((e) => CarwashModel.fromJson(e)).toList();
      } else {
        _results = [];
      }
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      print("Search error: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset search results
  void resetResults() {
    _results = [];
    notifyListeners();
  }
}
