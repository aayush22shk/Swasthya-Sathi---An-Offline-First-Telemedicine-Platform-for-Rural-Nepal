import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../services/auth_service.dart';

// ─── MODELS ──────────────────────────────────────────────────────────────────

class BPReading {
  final String id;
  final int systolic;
  final int diastolic;
  final int? heartRate;
  final DateTime measuredAt;
  final String measurementContext;

  BPReading({
    required this.id,
    required this.systolic,
    required this.diastolic,
    this.heartRate,
    required this.measuredAt,
    required this.measurementContext,
  });

  factory BPReading.fromJson(Map<String, dynamic> j) => BPReading(
        id: j['id'] ?? '',
        systolic: j['systolic'] ?? 0,
        diastolic: j['diastolic'] ?? 0,
        heartRate: j['heart_rate'],
        measuredAt: DateTime.parse(j['measured_at']),
        measurementContext: j['measurement_context'] ?? 'manual',
      );

  Map<String, dynamic> toJson() => {
        'systolic': systolic,
        'diastolic': diastolic,
        if (heartRate != null) 'heart_rate': heartRate,
        'measured_at': measuredAt.toIso8601String(),
        'measurement_context': measurementContext,
      };

  String get bpLabel => '$systolic / $diastolic';
  String get category {
    if (systolic >= 180 || diastolic >= 120) return 'Crisis';
    if (systolic >= 140 || diastolic >= 90) return 'High (Stage 2)';
    if (systolic >= 130 || diastolic >= 80) return 'High (Stage 1)';
    if (systolic >= 120 && systolic < 130 && diastolic < 80) return 'Elevated';
    return 'Normal';
  }
}

class GlucoseReading {
  final String id;
  final double glucoseValue;
  final String unit;
  final String measurementType;
  final DateTime measuredAt;

  GlucoseReading({
    required this.id,
    required this.glucoseValue,
    required this.unit,
    required this.measurementType,
    required this.measuredAt,
  });

  factory GlucoseReading.fromJson(Map<String, dynamic> j) => GlucoseReading(
        id: j['id'] ?? '',
        glucoseValue: double.tryParse(j['glucose_value'].toString()) ?? 0,
        unit: j['unit'] ?? 'mg/dl',
        measurementType: j['measurement_type'] ?? 'random',
        measuredAt: DateTime.parse(j['measured_at']),
      );

  String get displayValue => '${glucoseValue.toStringAsFixed(0)} $unit';
  String get typeLabel => switch (measurementType) {
    'fasting' => 'Fasting',
    'before_meal' => 'Before Meal',
    'after_meal' => 'After Meal',
    'bedtime' => 'Bedtime',
    _ => 'Random',
  };
}

class WeightReading {
  final String id;
  final double weightKg;
  final DateTime measuredAt;

  WeightReading({required this.id, required this.weightKg, required this.measuredAt});

  factory WeightReading.fromJson(Map<String, dynamic> j) => WeightReading(
        id: j['id'] ?? '',
        weightKg: double.tryParse(j['weight_kg'].toString()) ?? 0,
        measuredAt: DateTime.parse(j['measured_at']),
      );
}

class HealthAnalysis {
  final String id;
  final String analysisType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, dynamic> result;
  final DateTime generatedAt;

  HealthAnalysis({
    required this.id,
    required this.analysisType,
    required this.periodStart,
    required this.periodEnd,
    required this.result,
    required this.generatedAt,
  });

  factory HealthAnalysis.fromJson(Map<String, dynamic> j) => HealthAnalysis(
        id: j['id'] ?? '',
        analysisType: j['analysis_type'] ?? 'comprehensive',
        periodStart: DateTime.parse(j['period_start']),
        periodEnd: DateTime.parse(j['period_end']),
        result: Map<String, dynamic>.from(j['result'] ?? {}),
        generatedAt: DateTime.parse(j['generated_at']),
      );

  Map<String, dynamic>? get bloodPressure => result['blood_pressure'];
  Map<String, dynamic>? get glucose => result['glucose'];
  Map<String, dynamic>? get weight => result['weight'];
  List<dynamic> get flags => result['flags'] ?? [];
}

class AIExplanation {
  final String summary;
  final List<Map<String, dynamic>> observations;
  final List<Map<String, dynamic>> recommendations;
  final List<String> questionsForClinician;
  final String? safetyMessage;
  final String? disclaimer;

  AIExplanation({
    required this.summary,
    required this.observations,
    required this.recommendations,
    required this.questionsForClinician,
    this.safetyMessage,
    this.disclaimer,
  });

  factory AIExplanation.fromJson(Map<String, dynamic> j) => AIExplanation(
        summary: j['summary'] ?? '',
        observations: List<Map<String, dynamic>>.from(j['observations'] ?? []),
        recommendations: List<Map<String, dynamic>>.from(j['recommendations'] ?? []),
        questionsForClinician: List<String>.from(j['questions_for_clinician'] ?? []),
        safetyMessage: j['safety_message'],
        disclaimer: j['disclaimer'],
      );
}

// ─── SERVICE ─────────────────────────────────────────────────────────────────

class HealthService {
  final AuthService _auth = AuthService();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_auth.currentUser?.token != null) 'Authorization': 'Bearer ${_auth.currentUser!.token}',
      };

  dynamic _body(http.Response res) {
    final decoded = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded['data'];
    throw Exception(decoded['message'] ?? 'Request failed (${res.statusCode})');
  }

  // ── Blood Pressure ────────────────────────────────────────────────────────

  Future<BPReading> addBPReading({
    required int systolic,
    required int diastolic,
    int? heartRate,
    required DateTime measuredAt,
    String measurementContext = 'manual',
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.healthBP),
      headers: _headers,
      body: jsonEncode({
        'systolic': systolic,
        'diastolic': diastolic,
        ...?heartRate != null ? {'heart_rate': heartRate} : null,
        'measured_at': measuredAt.toIso8601String(),
        'measurement_context': measurementContext,
      }),
    );
    return BPReading.fromJson(_body(res));
  }

  Future<List<BPReading>> getBPHistory({int limit = 30}) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.healthBP}?limit=$limit'),
      headers: _headers,
    );
    final data = _body(res) as List;
    return data.map((j) => BPReading.fromJson(j)).toList();
  }

  // ── Glucose ───────────────────────────────────────────────────────────────

  Future<GlucoseReading> addGlucoseReading({
    required double glucoseValue,
    String unit = 'mg/dl',
    String measurementType = 'random',
    required DateTime measuredAt,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.healthGlucose),
      headers: _headers,
      body: jsonEncode({
        'glucose_value': glucoseValue,
        'unit': unit,
        'measurement_type': measurementType,
        'measured_at': measuredAt.toIso8601String(),
      }),
    );
    return GlucoseReading.fromJson(_body(res));
  }

  Future<List<GlucoseReading>> getGlucoseHistory({int limit = 30}) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.healthGlucose}?limit=$limit'),
      headers: _headers,
    );
    final data = _body(res) as List;
    return data.map((j) => GlucoseReading.fromJson(j)).toList();
  }

  // ── Weight ────────────────────────────────────────────────────────────────

  Future<WeightReading> addWeightReading({
    required double weightKg,
    required DateTime measuredAt,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.healthWeight),
      headers: _headers,
      body: jsonEncode({'weight_kg': weightKg, 'measured_at': measuredAt.toIso8601String()}),
    );
    return WeightReading.fromJson(_body(res));
  }

  Future<List<WeightReading>> getWeightHistory({int limit = 30}) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.healthWeight}?limit=$limit'),
      headers: _headers,
    );
    final data = _body(res) as List;
    return data.map((j) => WeightReading.fromJson(j)).toList();
  }

  // ── Health Analysis ───────────────────────────────────────────────────────

  Future<HealthAnalysis> generateAnalysis({String period = '30d'}) async {
    final res = await http.post(
      Uri.parse(ApiConstants.healthAnalysisSummary),
      headers: _headers,
      body: jsonEncode({'period': period}),
    );
    return HealthAnalysis.fromJson(_body(res));
  }

  // ── AI Explanation ────────────────────────────────────────────────────────

  Future<AIExplanation> getAIExplanation({String? analysisId, String language = 'en'}) async {
    final res = await http.post(
      Uri.parse(ApiConstants.aiExplain),
      headers: _headers,
      body: jsonEncode({
        ...?analysisId != null ? {'analysis_id': analysisId} : null,
        'language': language,
      }),
    );
    return AIExplanation.fromJson(_body(res));
  }
}
