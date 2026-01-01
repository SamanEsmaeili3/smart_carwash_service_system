import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/driver_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverProvider with ChangeNotifier {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://my-project-api.liara.run/api',
      connectTimeout: const Duration(seconds: 20),
    ),
  );

  List<Driver> _drivers = [];
  bool _isLoading = false;
  String? _error;

  List<Driver> get drivers => _drivers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access') ??
        prefs.getString('token') ??
        prefs.getString('access_token');
  }

  Future<void> fetchDrivers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final response = await _dio.get(
        '/carwash/drivers/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        _drivers = data.map((json) => Driver.fromJson(json)).toList();
      }
    } catch (e) {
      _error = "خطا در دریافت اطلاعات. لطفا مجدد وارد شوید.";
      print("Fetch Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addDriver(Driver driver, XFile? photoFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      Map<String, dynamic> map = {
        'full_name': driver.fullName,
        'national_id': driver.nationalId,
        'phone_number': driver.phoneNumber,
        'address': driver.address ?? '',
      };

      FormData formData = FormData.fromMap(map);

      if (photoFile != null) {
        final bytes = await photoFile.readAsBytes();

        formData.files.add(
          MapEntry(
            'personnel_photo',
            MultipartFile.fromBytes(bytes, filename: photoFile.name),
          ),
        );
      }

      await _dio.post(
        '/carwash/drivers/',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      await fetchDrivers();
      return true;
    } catch (e) {
      if (e is DioException) {
        print("Upload Error: ${e.response?.data}");
        _error = "خطا: ${e.response?.data ?? e.message}";
      } else {
        _error = "خطا در برقراری ارتباط";
        print(e);
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      _error = "خطا در حذف";
      return false;
    }
  }

  Future<bool> editDriver(int id, Driver driver, XFile? photoFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();

      // ساخت دیتا
      Map<String, dynamic> map = {
        'full_name': driver.fullName,
        'national_id': driver.nationalId,
        'phone_number': driver.phoneNumber,
        'address': driver.address ?? '',
      };

      FormData formData = FormData.fromMap(map);

      if (photoFile != null) {
        final bytes = await photoFile.readAsBytes();
        formData.files.add(
          MapEntry(
            'personnel_photo',
            MultipartFile.fromBytes(bytes, filename: photoFile.name),
          ),
        );
      }

      await _dio.patch(
        '/carwash/drivers/$id/',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      await fetchDrivers();
      return true;
    } catch (e) {
      if (e is DioException) {
        _error = "خطا در ویرایش: ${e.response?.data}";
      } else {
        _error = "خطا در ویرایش راننده";
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
