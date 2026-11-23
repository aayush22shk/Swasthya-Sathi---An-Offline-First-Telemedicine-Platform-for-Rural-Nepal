class ConversationModel {
  final String id;
  final String doctorId;
  final String patientId;
  final String? doctorName;
  final String? patientName;
  final String? patientPhoto;
  final String? doctorPhoto;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    this.doctorName,
    this.patientName,
    this.patientPhoto,
    this.doctorPhoto,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> j) => ConversationModel(
        id: j['id'] as String,
        doctorId: j['doctor_id'] as String,
        patientId: j['patient_id'] as String,
        doctorName: j['doctor_name'] as String?,
        patientName: j['patient_name'] as String?,
        patientPhoto: j['patient_photo'] as String?,
        doctorPhoto: j['doctor_photo'] as String?,
        lastMessage: j['last_message'] as String?,
        lastMessageAt: j['last_message_at'] != null
            ? DateTime.parse(j['last_message_at'] as String).toLocal()
            : null,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        updatedAt: DateTime.parse(j['updated_at'] as String).toLocal(),
      );
}
