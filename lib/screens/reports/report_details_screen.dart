// ReportDetailsScreen (FINAL VERSION)

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../data/mock_data.dart';
import '../../models/incident_analysis.dart';
import '../../models/incident_report.dart';
import '../../models/incident_update.dart';
import '../../services/incidents_api_service.dart';

class ReportDetailsScreen extends StatefulWidget {
  final IncidentReport report;

  const ReportDetailsScreen({
    super.key,
    required this.report,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  final IncidentsApiService _apiService = IncidentsApiService();

  static const Color bgColor = Color(0xFF0B1220);
  static const Color cardColor = Color(0xFF111827);

  late Future<_ReportDetailsData> _future;
  bool _isAnalyzing = false;
  bool _isUploadingEvidence = false;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_ReportDetailsData> _loadData() async {
    final details = await _apiService.getIncidentById(widget.report.incidentId);
    final updates =
        await _apiService.getIncidentUpdates(widget.report.incidentId);

    IncidentAnalysis? analysis;

    try {
      analysis =
          await _apiService.getLatestAnalysis(widget.report.incidentId);
    } catch (_) {
      // 🔥 أهم إصلاح: لا تكسر الشاشة
      analysis = null;
    }

    return _ReportDetailsData(
      report: details,
      updates: updates,
      analysis: analysis,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  // ✅ Upload (Web-safe)
  Future<void> _uploadEvidence() async {
    setState(() => _isUploadingEvidence = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true, // 🔥 مهم
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      if (file.bytes == null) {
        throw Exception('فشل قراءة الملف');
      }

      await _apiService.uploadEvidence(
        incidentId: widget.report.incidentId,
        bytes: file.bytes!,
        fileName: file.name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفع الدليل بنجاح')),
      );

      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل رفع الدليل:\n$e')),
      );
    } finally {
      setState(() => _isUploadingEvidence = false);
    }
  }

  // ✅ AI Analyze
  Future<void> _analyzeIncident() async {
    setState(() => _isAnalyzing = true);

    try {
      await _apiService.analyzeIncident(widget.report.incidentId);
      await _refresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحليل البلاغ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التحليل:\n$e')),
      );
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Smart Analysis UI
  Widget _buildAnalysisCard(IncidentAnalysis? analysis) {
    if (analysis == null) {
      return _card(
        child: Column(
          children: [
            const Text(
              'لا يوجد تحليل بعد',
              style: TextStyle(color: Colors.orange),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeIncident,
              icon: const Icon(Icons.auto_awesome),
              label: Text(_isAnalyzing
                  ? 'جاري التحليل...'
                  : 'تحليل البلاغ بالذكاء الاصطناعي'),
            ),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('التصنيف', analysis.predictedLabel),
          _infoRow('الثقة', analysis.confidenceLabel),
          _infoRow('الخطورة', analysis.riskLabel),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _isAnalyzing ? null : _analyzeIncident,
            child: const Text('إعادة التحليل'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdates(List<IncidentUpdate> updates) {
    if (updates.isEmpty) {
      return _card(child: const Text('لا توجد تحديثات'));
    }

    return Column(
      children: updates.map((u) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _card(
            child: ListTile(
              title: Text(
                MockData.statusLabel(u.statusKey ?? ''),
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                u.note ?? '',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('تفاصيل البلاغ',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<_ReportDetailsData>(
        future: _future,
        builder: (context, snapshot) {
          // 🔥 تحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔥 خطأ
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'خطأ:\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          // 🔥 لا بيانات
          if (!snapshot.hasData) {
            return const Center(child: Text('لا توجد بيانات'));
          }

          final data = snapshot.data!;
          final report = data.report;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow('رقم البلاغ', report.displayId),
                    _infoRow(
                        'الحالة', MockData.statusLabel(report.statusKey)),
                    _infoRow('التاريخ', report.createdAtLabel),
                    const SizedBox(height: 10),
                    Text(
                      report.description,
                      style:
                          TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed:
                          _isUploadingEvidence ? null : _uploadEvidence,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_isUploadingEvidence
                          ? 'جاري الرفع...'
                          : 'رفع دليل'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _sectionTitle('تحليل البلاغ'),
              const SizedBox(height: 12),
              _buildAnalysisCard(data.analysis),

              const SizedBox(height: 20),
              _sectionTitle('سجل التحديثات'),
              const SizedBox(height: 12),
              _buildUpdates(data.updates),
            ],
          );
        },
      ),
    );
  }
}

class _ReportDetailsData {
  final IncidentReport report;
  final List<IncidentUpdate> updates;
  final IncidentAnalysis? analysis;

  const _ReportDetailsData({
    required this.report,
    required this.updates,
    required this.analysis,
  });
}