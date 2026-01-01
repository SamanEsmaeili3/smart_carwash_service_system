import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/driver_model.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../constants/api_constants.dart';

enum DriverStatus { initial, loading, success, error }

class DriverProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  DriverStatus _status = DriverStatus.initial;
  String? _errorMessage;
  List<Driver> _drivers = [];

  DriverStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<Driver> get drivers => _drivers;
  bool get isLoading => _status == DriverStatus.loading;

  Future<void> fetchDrivers() async {
    _setLoading(true);
    try {
      final response = await _api.get(ApiConstants.drivers, auth: true);

      if (response is List) {
        _drivers = response.map((json) => Driver.fromJson(json)).toList();
        _status = DriverStatus.success;
        _errorMessage = null;
      }
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e);
      _setError(errorMsg);
    }
  }

  Future<bool> addDriver(Driver driver, XFile? photoFile) async {
    _setLoading(true);
    try {
      final formData = await _buildFormData(driver, photoFile: photoFile);
      await _api.post(ApiConstants.drivers, formData, auth: true);
      await fetchDrivers();
      return true;
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e);
      _setError(errorMsg);
      return false;
    }
  }

  Future<bool> deleteDriver(int id) async {
    _setLoading(true);
    try {
      await _api.delete('${ApiConstants.drivers}$id/', auth: true);
      _drivers.removeWhere((d) => d.id == id);
      _status = DriverStatus.success;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e);
      _setError(errorMsg);
      return false;
    }
  }

  Future<bool> editDriver(int id, Driver driver, XFile? photoFile) async {
    _setLoading(true);
    try {
      final formData = await _buildFormData(driver, photoFile: photoFile);
      await _api.put('${ApiConstants.drivers}$id/', data: formData, auth: true);
      await fetchDrivers();
      return true;
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e);
      _setError(errorMsg);
      return false;
    }
  }

  Future<Map<String, dynamic>> _buildFormData(
    Driver driver, {
    XFile? photoFile,
  }) async {
    final map = <String, dynamic>{
      'full_name': driver.fullName,
      'national_id': driver.nationalId,
      'phone_number': driver.phoneNumber,
      'address': driver.address ?? '',
    };

    if (photoFile != null) {
      final bytes = await photoFile.readAsBytes();
      map['personnel_photo'] = bytes;
      map['personnel_photo_filename'] = photoFile.name;
    }

    return map;
  }

  void _setLoading(bool val) {
    _status = val ? DriverStatus.loading : DriverStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String errorMsg) {
    _status = DriverStatus.error;
    _errorMessage = errorMsg;
    notifyListeners();
  }
}
