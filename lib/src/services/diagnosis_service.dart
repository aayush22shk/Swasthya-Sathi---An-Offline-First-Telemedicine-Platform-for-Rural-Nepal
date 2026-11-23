import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/diagnosis_model.dart';

class DiagnosisService {
  DiagnosisService._internal();
  static final DiagnosisService _instance = DiagnosisService._internal();
  factory DiagnosisService() => _instance;

  static String get _base =>
      kIsWeb ? 'http://localhost:5000/api/v1' : 'http://10.10.9.4:5000/api/v1';

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  String _token() {
    final t = AuthService().currentUser?.token;
    if (t == null || t.isEmpty) throw Exception('Not authenticated.');
    return t;
  }

  Future<DiagnosisModel> create({
    required String conversationId,
    required String title,
    String? description,
    String? findings,
    String? recommendedTreatment,
    String? additionalNotes,
  }) async {
    final token = _token();
    final res = await http.post(
      Uri.parse('$_base/diagnosis-results'),
      headers: _headers(token),
      body: jsonEncode({
        'conversation_id': conversationId,
        'title': title,
        'description': description,
        'findings': findings,
        'recommended_treatment': recommendedTreatment,
        'additional_notes': additionalNotes,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 201 && body['success'] == true) {
      return DiagnosisModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to create diagnosis.');
  }

  Future<DiagnosisModel> getById(String id) async {
    final token = _token();
    final res = await http.get(
      Uri.parse('$_base/diagnosis-results/$id'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return DiagnosisModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to load diagnosis.');
  }

  Future<List<DiagnosisModel>> getByPatient(String patientId) async {
    final token = _token();
    final res = await http.get(
      Uri.parse('$_base/diagnosis-results/patient/$patientId'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return (body['data'] as List)
          .map((item) => DiagnosisModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
