class EvidenceUploadResult {
  final int evidenceId;
  final int incidentId;
  final String filename;
  final String contentType;
  final String? storagePath;

  const EvidenceUploadResult({
    required this.evidenceId,
    required this.incidentId,
    required this.filename,
    required this.contentType,
    this.storagePath,
  });

  factory EvidenceUploadResult.fromJson(Map<String, dynamic> json) {
    return EvidenceUploadResult(
      evidenceId: json['evidence_id'] as int? ?? 0,
      incidentId: json['incident_id'] as int? ?? 0,
      filename: (json['filename'] ?? '').toString(),
      contentType: (json['content_type'] ?? '').toString(),
      storagePath: json['storage_path']?.toString(),
    );
  }
}
