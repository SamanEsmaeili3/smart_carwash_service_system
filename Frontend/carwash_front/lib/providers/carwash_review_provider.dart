import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../models/review_model.dart';

class CarwashReviewProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;

  Future<void> fetchReviews() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/api/carwash/reviews/', auth: true);
      List<dynamic> listData = (response is Map && response.containsKey('results')) 
          ? response['results'] : response;
      _reviews = listData.map((e) => ReviewModel.fromJson(e)).toList();
    } catch (e) {
      print("Review fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}