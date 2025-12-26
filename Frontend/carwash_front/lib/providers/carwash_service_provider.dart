import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../constants/api_constants.dart';
import '../models/carwash_service_model.dart';

class CarwashServiceProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<CarwashServiceModel> _services = [];
  bool _isLoading = false;
  String? _error;

  List<CarwashServiceModel> get services => _services;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.services, auth: true);

      List<dynamic> listData = [];

      if (response is Map<String, dynamic> && response.containsKey('results')) {
        listData = response['results'];
      } else if (response is List) {
        listData = response;
      } else {
        throw Exception(
          ErrorHandler.getErrorMessage("ساختار پاسخ سرور ناشناخته است"),
        );
      }

      _services =
          listData
              .map((json) {
                try {
                  return CarwashServiceModel.fromJson(json);
                } catch (e) {
                  print(
                    "Error parsing item: ${ErrorHandler.getErrorMessage(e)}",
                  );
                  return null;
                }
              })
              .whereType<CarwashServiceModel>()
              .toList();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addService(CarwashServiceModel service) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.post(ApiConstants.services, service.toJson(), auth: true);
      await fetchServices();
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteService(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.delete('${ApiConstants.services}$id/', auth: true);
      _services.removeWhere((item) => item.id == id);
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateService(int id, CarwashServiceModel service) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.put(
        '${ApiConstants.services}$id/',
        data: service.toJson(),
        auth: true,
      );

      int index = _services.indexWhere((s) => s.id == id);
      if (index != -1) {
        _services[index] = service;
      }

      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return false;
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
