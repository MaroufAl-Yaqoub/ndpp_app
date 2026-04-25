import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/incident_report.dart';
import '../../services/incidents_api_service.dart';
import 'report_details_screen.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final IncidentsApiService _apiService = IncidentsApiService();

  static const Color bgColor = Color(0xFF0B1220);
  static const Color cardColor = Color(0xFF111827);
  static const Color cyan = Color(0xFF06B6D4);

  late Future<List<IncidentReport>> _futureReports;

  @override
  void initState() {
    super.initState();
    _futureReports = _apiService.getIncidents();
  }

  Future<void> _reload() async {
    setState(() {
      _futureReports = _apiService.getIncidents();
    });
    await _futureReports;
  }

  Color _statusColor(String key) {
    switch (key) {
      case 'RESOLVED':
        return const Color(0xFF22C55E);
      case 'UNDER_REVIEW':
      case 'IN_ANALYSIS':
        return const Color(0xFFF59E0B);
      case 'REJECTED':
      case 'CLOSED':
        return const Color(0xFFEF4444);
      default:
        return cyan;
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

  Widget _emptyState() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.inbox, size: 50, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 12),
              Text(
                'لا يوجد بلاغات بعد',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('بلاغاتي', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<IncidentReport>>(
        future: _futureReports,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'خطأ:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: _emptyState(),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                final statusLabel =
                    MockData.statusLabel(report.statusKey);
                final color = _statusColor(report.statusKey);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReportDetailsScreen(report: report),
                        ),
                      );
                    },
                    child: _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  report.categoryTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text(
                            report.summary,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),

                          if (report.suspiciousUrl != null &&
                              report.suspiciousUrl!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              report.suspiciousUrl!,
                              style: const TextStyle(
                                color: cyan,
                                fontSize: 13,
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Text(
                                report.displayId,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                report.createdAtLabel,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}