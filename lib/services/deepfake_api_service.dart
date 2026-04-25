import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import 'auth_api_service.dart';

class DeepfakeApiResult {
  final int? scanId;
  final int? userId;
  final String fileName;
  final String result;
  final double confidence;
  final DateTime createdAt;

  const DeepfakeApiResult({
    this.scanId,
    this.userId,
    required this.fileName,
    required this.result,
    required this.confidence,
    required this.createdAt,
  });

  factory DeepfakeApiResult.fromJson(Map<String, dynamic> json) {
    return DeepfakeApiResult(
      scanId: json['scan_id'] as int?,
      userId: json['user_id'] as int?,
      fileName: (json['file_name'] ?? '').toString(),
      result: (json['result'] ?? 'Unknown').toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toHistoryPayload() {
    return {
      'file_name': fileName,
      'result': result,
      'confidence': confidence,
    };
  }

  String get createdAtLabel {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

class DeepfakeApiService {
  final http.Client _client = http.Client();
  final AuthApiService _authApiService = AuthApiService();

  Future<DeepfakeApiResult> analyzeImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final headers = await _authApiService.getAuthHeaders();
    final authHeader = headers['Authorization'];
    if (authHeader == null || authHeader.isEmpty) {
      throw Exception('الرجاء تسجيل الدخول أولًا');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/deepfake/analyze'),
    )
      ..headers['Authorization'] = authHeader
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('فشل تحليل الصورة: $body');
    }

    return DeepfakeApiResult.fromJson(
      jsonDecode(body) as Map<String, dynamic>,
    );
  }

  Future<DeepfakeApiResult> saveScan({
    required DeepfakeApiResult result,
  }) async {
    final headers = await _authApiService.getAuthHeaders();
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/deepfake/history'),
      headers: headers,
      body: jsonEncode(result.toHistoryPayload()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('فشل حفظ سجل الفحص: ${response.body}');
    }

    return DeepfakeApiResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<DeepfakeApiResult>> getHistory() async {
    final headers = await _authApiService.getAuthHeaders();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/deepfake/history'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('فشل جلب سجل الفحوصات: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];

    return decoded
        .map((item) => DeepfakeApiResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearHistory() async {
    final headers = await _authApiService.getAuthHeaders();
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/deepfake/history'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('فشل مسح سجل الفحوصات: ${response.body}');
    }
  }
}
