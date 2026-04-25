import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/deepfake_api_service.dart';

class DeepfakeScreen extends StatefulWidget {
  const DeepfakeScreen({super.key});

  @override
  State<DeepfakeScreen> createState() => _DeepfakeScreenState();
}

class _DeepfakeScreenState extends State<DeepfakeScreen> {
  final DeepfakeApiService _apiService = DeepfakeApiService();



  static const Color bgColor = Color(0xFF0B1220);
  static const Color cardColor = Color(0xFF111827);
  static const Color blue = Color(0xFF2563EB);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);

  bool _isAnalyzing = false;
  bool _isLoadingHistory = true;
  DeepfakeApiResult? _latestResult;
  String? _errorMessage;

  List<DeepfakeApiResult> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _apiService.getHistory();

      if (!mounted) return;

      setState(() {
        _history = history;
        _latestResult = history.isNotEmpty ? history.first : null;
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    await _apiService.clearHistory();

    if (!mounted) return;

    setState(() {
      _history = [];
      _latestResult = null;
    });
  }

 Future<void> _pickAndAnalyzeImage() async {
  setState(() {
    _isAnalyzing = true;
    _errorMessage = null;
  });

  try {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.image,
    );

    if (result == null || result.files.isEmpty) {
      setState(() => _isAnalyzing = false);
      return;
    }

    final file = result.files.first;

    final analysis = await _apiService.analyzeImage(
      bytes: file.bytes!,
      fileName: file.name,
    );

    final saved = await _apiService.saveScan(
      result: analysis,
    );

    if (!mounted) return;

    setState(() {
      _latestResult = saved;
      _history.insert(0, saved);
    });
  } catch (e) {
    setState(() => _errorMessage = e.toString());
  } finally {
    setState(() => _isAnalyzing = false);
  }
}

  bool _isSuspicious(String result) {
    final value = result.toLowerCase();
    return value.contains('fake') ||
        value.contains('ai') ||
        value.contains('generated');
  }

  Color _resultColor(String result) =>
      _isSuspicious(result) ? danger : success;

  IconData _resultIcon(String result) =>
      _isSuspicious(result) ? Icons.warning_amber : Icons.verified;

  String _confidenceLabel(double c) =>
      '${(c * 100).toStringAsFixed(0)}%';

  Widget _buildLatestResult() {
    final latest = _latestResult;

    if (latest == null) {
      return _emptyCard('لم يتم إجراء تحليل بعد');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(
            _resultIcon(latest.result),
            size: 56,
            color: _resultColor(latest.result),
          ),
          const SizedBox(height: 12),
          Text(
            latest.result,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _resultColor(latest.result),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence: ${_confidenceLabel(latest.confidence)}',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 6),
          Text(
            latest.fileName,
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return _emptyCard('لا يوجد سجل فحوصات');
    }

    return Column(
      children: _history.map((scan) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: _cardDecoration(),
            child: ListTile(
              leading: Icon(
                _resultIcon(scan.result),
                color: _resultColor(scan.result),
              ),
              title: Text(
                scan.fileName,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${scan.result} • ${_confidenceLabel(scan.confidence)}',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              trailing: Text(
                scan.createdAtLabel,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withOpacity(0.6)),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'Deepfake Detection',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _history.isEmpty ? null : _clearHistory,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [blue, cyan],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.smart_toy, color: Colors.white, size: 42),
                  const SizedBox(height: 10),
                  const Text(
                    'AI Deepfake Scanner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed:
                        _isAnalyzing ? null : _pickAndAnalyzeImage,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(
                      _isAnalyzing
                          ? 'Analyzing...'
                          : 'Upload & Analyze',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: blue,
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Latest Result',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),
            _buildLatestResult(),

            const SizedBox(height: 24),

            const Text(
              'History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),
            _buildHistory(),
          ],
        ),
      ),
    );
  }
}