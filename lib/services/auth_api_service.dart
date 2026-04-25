import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';

class AuthApiService {
  final http.Client _client = http.Client();

  // 🔐 Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['detail'] ?? 'فشل تسجيل الدخول');
      }

      final token = data['access_token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      return data;
    } on TimeoutException {
      throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // 🔑 Get Token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 🔐 Authorization Header (مهم جدًا لكل API)
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('الرجاء تسجيل الدخول أولاً');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // 🚪 Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}