import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders({bool auth = false}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      String? token = await _storage.read(key: 'access_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {bool auth = false}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(auth: auth);

    try {
      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool auth = false,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(auth: auth);

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      // Attempt to extract a clean error message from the server
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(body['detail'] ?? body['message'] ?? body.toString());
      } catch (_) {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    }
  }

  Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> data, {
    bool auth = false,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(auth: auth);

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  Future<dynamic> delete(String endpoint, {bool auth = false}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(auth: auth);

    try {
      final response = await http.delete(url, headers: headers);

      // 204 No Content is common for DELETE, but 200 is also possible
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return true; // Handle empty body
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          throw Exception(body['detail'] ?? body['message'] ?? body.toString());
        } catch (_) {
          throw Exception('Error ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }
}
