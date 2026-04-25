import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/constants/report_type_ids.dart';
import '../../models/report_category.dart';
import '../../services/incidents_api_service.dart';
import 'report_submit_success_screen.dart';

class ReportFormScreen extends StatefulWidget {
  final ReportCategory category;

  const ReportFormScreen({super.key, required this.category});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final IncidentsApiService _apiService = IncidentsApiService();

  static const Color bgColor = Color(0xFF0B1220);
  static const Color cardColor = Color(0xFF111827);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color blue = Color(0xFF2563EB);

  late final Map<String, TextEditingController> _controllers;
  final List<PlatformFile> _selectedEvidenceFiles = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.category.fields)
        field.key: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _valueOf(String key) => _controllers[key]?.text.trim() ?? '';

  Future<void> _pickEvidenceFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );

    if (result == null) return;

    setState(() {
      _selectedEvidenceFiles.addAll(result.files);
    });
  }

  void _removeEvidenceAt(int index) {
    setState(() {
      _selectedEvidenceFiles.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final created = await _apiService.createIncident(
        title: widget.category.title,
        description: _valueOf('details'),
        reportTypeId: ReportTypeIds.fromCategoryId(widget.category.id),
      );

      for (final file in _selectedEvidenceFiles) {
  if (file.bytes != null) {
    await _apiService.uploadEvidence(
      incidentId: created.incidentId,
      bytes: file.bytes!,
      fileName: file.name,
    );
  }
}

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReportSubmitSuccessScreen(
            categoryTitle: widget.category.title,
            incidentId: created.displayId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ:\n$e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
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

  Widget _buildEvidenceSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الأدلة (اختياري)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: _pickEvidenceFiles,
            icon: const Icon(Icons.attach_file),
            label: const Text('اختيار ملفات'),
          ),

          const SizedBox(height: 10),

          ..._selectedEvidenceFiles.asMap().entries.map((entry) {
            final i = entry.key;
            final file = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.name,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeEvidenceAt(i),
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(widget.category.title,
            style: const TextStyle(color: Colors.white)),
      ),
      body: Form(
  key: _formKey,
  child: ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _card(
        child: Text(
          widget.category.description,
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
      ),

      const SizedBox(height: 20),

      ...widget.category.fields.map(
        (field) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: _controllers[field.key],
            maxLines: field.maxLines,
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (field.required && (value == null || value.trim().isEmpty)) {
                return 'هذا الحقل مطلوب';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.hint,
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),

      const SizedBox(height: 10),
      _buildEvidenceSection(),

      const SizedBox(height: 20),

      SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(
            _isSubmitting ? 'جاري الإرسال...' : 'إرسال البلاغ',
          ),
        ),
      ),
    ],
  ),
),
    );
  }
}
