import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/evidence_upload_result.dart';
import 'auth_api_service.dart';

class EvidenceApiService {
  final AuthApiService _authApiService = AuthApiService();

  Future<EvidenceUploadResult> uploadEvidence({
    required int incidentId,
    required List<int> bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('الملف فارغ ولا يمكن رفعه');
    }

    final headers = await _authApiService.getAuthHeaders();
    final authHeader = headers['Authorization'];
    if (authHeader == null || authHeader.isEmpty) {
      throw Exception('الرجاء تسجيل الدخول أولًا');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/incidents/evidence'),
    )
      ..headers['Authorization'] = authHeader
      ..fields['incident_id'] = incidentId.toString()
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final decoded = _tryDecode(body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('فشل رفع الدليل: ${_extractError(decoded, body)}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('استجابة غير متوقعة من الخادم');
    }

    return EvidenceUploadResult.fromJson(decoded);
  }

  dynamic _tryDecode(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  String _extractError(dynamic decoded, String fallback) {
    if (decoded is Map<String, dynamic>) {
      final detail = decoded['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return fallback.isEmpty ? 'خطأ غير معروف' : fallback;
  }
}
