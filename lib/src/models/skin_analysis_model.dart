class SkinPredictionItem {
  final String classKey;
  final String conditionName;
  final String nepaliName;
  final double confidence;
  final double confidencePct;

  const SkinPredictionItem({
    required this.classKey,
    required this.conditionName,
    required this.nepaliName,
    required this.confidence,
    required this.confidencePct,
  });

  factory SkinPredictionItem.fromJson(Map<String, dynamic> j) {
    return SkinPredictionItem(
      classKey: j['class_key'] as String? ?? 'unknown',
      conditionName: j['condition_name'] as String? ?? 'Skin Condition',
      nepaliName: j['nepali_name'] as String? ?? '',
      confidence: (j['confidence'] as num?)?.toDouble() ?? 0.0,
      confidencePct: (j['confidence_pct'] as num?)?.toDouble() ??
          (((j['confidence'] as num?)?.toDouble() ?? 0.0) * 100),
    );
  }

  Map<String, dynamic> toJson() => {
        'class_key': classKey,
        'condition_name': conditionName,
        'nepali_name': nepaliName,
        'confidence': confidence,
        'confidence_pct': confidencePct,
      };
}

class SkinAnalysisModel {
  final String? id;
  final String? patientId;
  final String imageUrl;
  final String predictedCondition;
  final double confidenceScore;
  final List<SkinPredictionItem> topPredictions;
  final bool isUncertain;
  final String? uncertaintyReason;
  final String urgencyLevel;
  final String description;
  final List<String> symptoms;
  final String adviceEn;
  final String adviceNe;
  final String modelVersion;
  final bool isSharedWithDoctor;
  final String? doctorId;
  final String? doctorName;
  final String? doctorNotes;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  SkinAnalysisModel({
    this.id,
    this.patientId,
    required this.imageUrl,
    required this.predictedCondition,
    required this.confidenceScore,
    required this.topPredictions,
    this.isUncertain = false,
    this.uncertaintyReason,
    this.urgencyLevel = 'medium',
    this.description = '',
    this.symptoms = const [],
    this.adviceEn = '',
    this.adviceNe = '',
    this.modelVersion = 'mobilenetv3_nepal_v1',
    this.isSharedWithDoctor = false,
    this.doctorId,
    this.doctorName,
    this.doctorNotes,
    this.reviewedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SkinAnalysisModel.fromJson(Map<String, dynamic> j) {
    final topList = (j['top_predictions'] as List? ?? [])
        .map((x) => SkinPredictionItem.fromJson(x as Map<String, dynamic>))
        .toList();

    return SkinAnalysisModel(
      id: j['id']?.toString(),
      patientId: j['patient_id']?.toString(),
      imageUrl: j['image_url'] as String? ?? '',
      predictedCondition: j['predicted_condition'] as String? ?? 'Unspecified Condition',
      confidenceScore: (j['confidence_score'] as num?)?.toDouble() ?? 0.0,
      topPredictions: topList,
      isUncertain: j['is_uncertain'] as bool? ?? false,
      uncertaintyReason: j['uncertainty_reason'] as String?,
      urgencyLevel: j['urgency_level'] as String? ?? 'medium',
      description: j['description'] as String? ?? '',
      symptoms: (j['symptoms'] as List?)?.map((s) => s.toString()).toList() ?? [],
      adviceEn: j['clinical_advice_en'] as String? ?? j['advice_en'] as String? ?? '',
      adviceNe: j['clinical_advice_ne'] as String? ?? j['advice_ne'] as String? ?? '',
      modelVersion: j['model_version'] as String? ?? 'mobilenetv3_nepal_v1',
      isSharedWithDoctor: j['is_shared_with_doctor'] as bool? ?? false,
      doctorId: j['doctor_id']?.toString(),
      doctorName: j['doctor_name'] as String?,
      doctorNotes: j['doctor_notes'] as String?,
      reviewedAt: j['reviewed_at'] != null ? DateTime.tryParse(j['reviewed_at'].toString()) : null,
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  /// Creates a fallback or sample model for a known condition name or key
  factory SkinAnalysisModel.fromCondition(String conditionName, {String? id, String? imageUrl, double confidence = 0.88}) {
    return SkinAnalysisModel(
      id: id ?? 'skin_${DateTime.now().millisecondsSinceEpoch}',
      imageUrl: imageUrl ?? '',
      predictedCondition: conditionName,
      confidenceScore: confidence,
      topPredictions: [
        SkinPredictionItem(
          classKey: conditionName.toLowerCase().replaceAll(' ', '_'),
          conditionName: conditionName,
          nepaliName: '',
          confidence: confidence,
          confidencePct: confidence * 100,
        ),
      ],
      urgencyLevel: 'medium',
      description: 'Dermatological screening result for $conditionName.',
      adviceEn: 'Keep skin clean and hydrated. Consult doctor for clinical evaluation.',
      adviceNe: 'छाला सफा र सुक्खा राख्नुहोस्। विशेषज्ञ डाक्टरसँग परामर्श लिनुहोस्।',
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (patientId != null) 'patient_id': patientId,
        'image_url': imageUrl,
        'predicted_condition': predictedCondition,
        'confidence_score': confidenceScore,
        'top_predictions': topPredictions.map((x) => x.toJson()).toList(),
        'is_uncertain': isUncertain,
        'uncertainty_reason': uncertaintyReason,
        'urgency_level': urgencyLevel,
        'description': description,
        'symptoms': symptoms,
        'clinical_advice_en': adviceEn,
        'clinical_advice_ne': adviceNe,
        'model_version': modelVersion,
        'is_shared_with_doctor': isSharedWithDoctor,
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'doctor_notes': doctorNotes,
        'reviewed_at': reviewedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
