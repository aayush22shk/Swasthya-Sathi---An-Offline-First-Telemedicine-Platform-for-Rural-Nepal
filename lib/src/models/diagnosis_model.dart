class DiagnosisModel {
  final String id;
  final String conversationId;
  final String doctorId;
  final String patientId;
  final String title;
  final String? description;
  final String? findings;
  final String? recommendedTreatment;
  final String? additionalNotes;
  final String? doctorName;
  final String? patientName;
  final DateTime createdAt;

  const DiagnosisModel({
    required this.id,
    required this.conversationId,
    required this.doctorId,
    required this.patientId,
    required this.title,
    this.description,
    this.findings,
    this.recommendedTreatment,
    this.additionalNotes,
    this.doctorName,
    this.patientName,
    required this.createdAt,
  });

  factory DiagnosisModel.fromJson(Map<String, dynamic> j) => DiagnosisModel(
        id: j['id'] as String,
        conversationId: j['conversation_id'] as String,
        doctorId: j['doctor_id'] as String,
        patientId: j['patient_id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        findings: j['findings'] as String?,
        recommendedTreatment: j['recommended_treatment'] as String?,
        additionalNotes: j['additional_notes'] as String?,
        doctorName: j['doctor_name'] as String?,
        patientName: j['patient_name'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );
}
