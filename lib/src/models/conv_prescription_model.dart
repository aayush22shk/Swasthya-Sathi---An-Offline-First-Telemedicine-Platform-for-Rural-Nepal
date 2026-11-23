class MedicineItem {
  final String? id;
  final String medicineName;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? instructions;

  const MedicineItem({
    this.id,
    required this.medicineName,
    this.dosage,
    this.frequency,
    this.duration,
    this.instructions,
  });

  factory MedicineItem.fromJson(Map<String, dynamic> j) => MedicineItem(
        id: j['id'] as String?,
        medicineName: j['medicine_name'] as String,
        dosage: j['dosage'] as String?,
        frequency: j['frequency'] as String?,
        duration: j['duration'] as String?,
        instructions: j['instructions'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'medicine_name': medicineName,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        'instructions': instructions,
      };
}

class ConvPrescriptionModel {
  final String id;
  final String conversationId;
  final String doctorId;
  final String patientId;
  final String? title;
  final String? additionalInstructions;
  final String? doctorName;
  final String? patientName;
  final List<MedicineItem> medicines;
  final DateTime createdAt;

  const ConvPrescriptionModel({
    required this.id,
    required this.conversationId,
    required this.doctorId,
    required this.patientId,
    this.title,
    this.additionalInstructions,
    this.doctorName,
    this.patientName,
    required this.medicines,
    required this.createdAt,
  });

  factory ConvPrescriptionModel.fromJson(Map<String, dynamic> j) => ConvPrescriptionModel(
        id: j['id'] as String,
        conversationId: j['conversation_id'] as String,
        doctorId: j['doctor_id'] as String,
        patientId: j['patient_id'] as String,
        title: j['title'] as String?,
        additionalInstructions: j['additional_instructions'] as String?,
        doctorName: j['doctor_name'] as String?,
        patientName: j['patient_name'] as String?,
        medicines: (j['medicines'] as List? ?? [])
            .map((m) => MedicineItem.fromJson(m as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );
}
