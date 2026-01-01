import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/driver_model.dart';
import '../services/error_handler.dart'; // Assuming you have this

class DriverProvider with ChangeNotifier {
  // Use Dio for Multipart requests
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://my-project-api.liara.run/api', // <--- CHECK YOUR BASE URL
    connectTimeout: const Duration(seconds: 10),
  ));

  List<DriverModel> _drivers = [];
  bool _isLoading = false;
  String? _error;

  List<DriverModel> get drivers => _drivers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Helper to get Token ---
  Future<String?> _getToken() async {
    return ""; 
  }

  // 1. Fetch Drivers
  Future<void> fetchDrivers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await _dio.get(
        '/carwash/drivers/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        _drivers = data.map((json) => DriverModel.fromJson(json)).toList();
      }
    } catch (e) {
      _error = "خطا در دریافت لیست رانندگان";
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Add Driver (with Photo)
  Future<bool> addDriver(DriverModel driver, File? photoFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      
      // Create FormData
      FormData formData = FormData.fromMap({
        'full_name': driver.fullName,
        'national_id': driver.nationalId,
        'phone_number': driver.phoneNumber,
        'address': driver.address ?? '',
      });

      // Attach Photo if exists
      if (photoFile != null) {
        formData.files.add(MapEntry(
          'personnel_photo',
          await MultipartFile.fromFile(photoFile.path),
        ));
      }

      await _dio.post(
        '/carwash/drivers/',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      await fetchDrivers(); // Refresh list
      return true;
    } catch (e) {
      _error = "خطا در ثبت راننده";
      print(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Delete Driver
  Future<bool> deleteDriver(int id) async {
    try {
      final token = await _getToken();
      await _dio.delete(
        '/carwash/drivers/$id/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _drivers.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = "خطا در حذف راننده";
      return false;
    }
  }
}