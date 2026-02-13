import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../models/financials_model.dart';
import '../constants/api_constants.dart';

class FinancialsProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _error;
  FinancialSummary? _financialSummary;

  bool get isLoading => _isLoading;
  String? get error => _error;
  FinancialSummary? get financialSummary => _financialSummary;

  Future<void> fetchFinancials() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.financials, auth: true);
      _financialSummary = FinancialSummary.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
