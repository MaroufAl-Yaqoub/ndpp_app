import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/incident_analysis.dart';
import '../models/incident_report.dart';
import '../models/incident_update.dart';
import 'auth_api_service.dart';

class IncidentsApiService {
  final http.Client _client = http.Client();
  final AuthApiService _authApiService = AuthApiService();

  Future<List<IncidentReport>> getIncidents() async {
    final headers = await _authApiService.getAuthHeaders();
    final response = await _client.get(
      Uri.parse(ApiConfig.incidents()),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('فشل في جلب البلاغات');
    }

    final data = jsonDecode(response.body) as List;
    return data
        .map((e) => IncidentReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<IncidentReport> getIncidentById(int incidentId) async {
    final headers = await _authApiService.getAuthHeaders();
    final response = await _client.get(
      Uri.parse(ApiConfig.incidentById(incidentId)),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('فشل في جلب تفاصيل البلاغ: ${response.body}');
    }

    return IncidentReport.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<IncidentUpdate>> getIncidentUpdates(int incidentId) async {
    final headers = await _authApiService.getAuthHeaders();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/incidents/$incidentId/updates'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('فشل في جلب تحديثات البلاغ');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];

    return decoded
        .map((e) => IncidentUpdate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<IncidentReport> createIncident({
    required String title,
    required String description,
    required int reportTypeId,
    String? suspiciousUrl,
    String? suspiciousMessage,
    String? platform,
    String? deviceType,
    String? note,
  }) async {
    final headers = await _authApiService.getAuthHeaders();
    final response = await _client.post(
      Uri.parse(ApiConfig.incidents()),
      headers: headers,
      body: jsonEncode({
        "title": title,
        "description": description,
        "report_type_id": reportTypeId,
        "incident_date": DateTime.now().toIso8601String(),
        if (suspiciousUrl != null && suspiciousUrl.isNotEmpty) "suspicious_url": suspiciousUrl,
        if (suspiciousMessage != null && suspiciousMessage.isNotEmpty) "suspicious_message": suspiciousMessage,
        if (platform != null && platform.isNotEmpty) "platform": platform,
        if (deviceType != null && deviceType.isNotEmpty) "device_type": deviceType,
        if (note != null && note.isNotEmpty) "note": note,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('فشل في إرسال البلاغ: ${response.body}');
    }

    return IncidentReport.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> analyzeIncident(int incidentId) async {
    final headers = await _authApiService.getAuthHeaders();
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/incidents/$incidentId/analyze'),
      headers: headers,
      body: jsonEncode({
        'note': 'AI analysis requested from Flutter app',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('فشل تحليل البلاغ: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<IncidentAnalysis?> getLatestAnalysis(int incidentId) async {
  final headers = await _authApiService.getAuthHeaders();

  final response = await _client.get(
    Uri.parse('${ApiConfig.baseUrl}/incidents/$incidentId/analysis'),
    headers: headers,
  );

  // ✅ أهم إصلاح
  if (response.statusCode == 404) {
    return null;
  }

  if (response.statusCode != 200) {
    throw Exception('فشل جلب نتيجة التحليل');
  }

  return IncidentAnalysis.fromJson(
    jsonDecode(response.body),
  );
}

  Future<void> uploadEvidence({
    required int incidentId,
    required List<int> bytes,
    required String fileName,
  }) async {
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
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('فشل رفع الملف: $body');
    }
  }
}
