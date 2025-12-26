import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';

class CustomerProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<dynamic> _carwashes = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get carwashes => _carwashes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch the list (supports search query)
  Future<void> searchCarwashes({
    String? query,
    double? lat,
    double? lon,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String endpoint = '/api/carwash/search/?';
      if (lat != null && lon != null) {
        endpoint += 'lat=$lat&lon=$lon&';
      }

      final response = await _api.get(endpoint, auth: false);

      if (response is List) {
        _carwashes = response;
      } else {
        _carwashes = [];
      }
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      print("Search Error: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
