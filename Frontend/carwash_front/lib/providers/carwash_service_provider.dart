import 'package:carwash_front/models/carwash_service_model.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class CarwashServiceProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<CarwashServiceModel> _services = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CarwashServiceModel> get services => _services;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch list of services (GET)
  Future<void> fetchServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // PDF: GET /api/carwash/services/
      final response = await _api.get(ApiConstants.services, auth: true);

      final List<dynamic> data = response;
      _services =
          data.map((json) => CarwashServiceModel.fromJson(json)).toList();
    } catch (e) {
      _error = "خظا در بارگذاری اطلاعات. لطفا دوباره تلاش کنید";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new service (POST)
  Future<bool> addService(CarwashServiceModel service) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // PDF: POST /api/carwash/services/
      final response = await _api.post(
        ApiConstants.services,
        service.toJson(),
        auth: true,
      );

      // Add the newly created service to the local list (to avoid refreshing)
      // Assuming the backend returns the created object with an ID
      _services.add(CarwashServiceModel.fromJson(response));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = "افزودن سرویس با خطا موجه شد. لطفا دوباره تلاش کنید";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a service (DELETE)
  Future<bool> deleteService(int id) async {
    // We don't set global loading here to avoid blocking the whole UI,
    // usually handled locally in the UI or via optimistic updates.
    try {
      // PDF: DELETE /api/carwash/services/<id>/
      await _api.delete('${ApiConstants.services}$id/', auth: true);

      // Optimistic Update: Remove from local list immediately
      _services.removeWhere((item) => item.id == id);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }
}
