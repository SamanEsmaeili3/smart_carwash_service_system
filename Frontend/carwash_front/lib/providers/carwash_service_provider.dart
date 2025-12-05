import 'package:flutter/material.dart';
import '../services/api_service.dart';
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

      // لاگ کردن پاسخ سرور برای اطمینان
      print("🔍 RAW SERVER RESPONSE: $response");

      List<dynamic> listData = [];

      // ۱. بررسی سناریوی صفحه‌بندی (Pagination)
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        print("ℹ️ Data is Paginated (inside 'results')");
        listData = response['results'];
      }
      // ۲. بررسی سناریوی لیست مستقیم
      else if (response is List) {
        print("ℹ️ Data is a direct List");
        listData = response;
      } else {
        throw Exception(
          "ساختار پاسخ سرور ناشناخته است: ${response.runtimeType}",
        );
      }

      // ۳. تبدیل امن به مدل
      _services =
          listData
              .map((json) {
                try {
                  return CarwashServiceModel.fromJson(json);
                } catch (e) {
                  print("❌ Error parsing item: $json \nError: $e");
                  // در صورت خطا در یک آیتم، آن را نادیده می‌گیریم تا کل لیست خراب نشود
                  return null;
                }
              })
              .whereType<CarwashServiceModel>()
              .toList(); // حذف آیتم‌های نال (خطا دار)

      print("✅ Successfully loaded ${_services.length} services.");
    } catch (e) {
      print("❌ Error inside fetchServices: $e");
      _error = "خطا در بارگذاری سرویس‌ها";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addService(CarwashServiceModel service) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post(ApiConstants.services, service.toJson(), auth: true);

      // بلافاصله لیست را رفرش می‌کنیم
      await fetchServices();

      return true;
    } catch (e) {
      print("Error adding service: $e");
      _error = "خطا در افزودن سرویس";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteService(int id) async {
    try {
      await _api.delete('${ApiConstants.services}$id/', auth: true);
      _services.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = "خطا در حذف سرویس";
      notifyListeners();
      return false;
    }
  }
}
