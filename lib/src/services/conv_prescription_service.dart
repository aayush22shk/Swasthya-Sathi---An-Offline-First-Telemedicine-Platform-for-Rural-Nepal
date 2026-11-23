import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/conv_prescription_model.dart';

class ConvPrescriptionService {
  ConvPrescriptionService._internal();
  static final ConvPrescriptionService _instance = ConvPrescriptionService._internal();
  factory ConvPrescriptionService() => _instance;

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

  Future<ConvPrescriptionModel> create({
    required String conversationId,
    String? title,
    String? additionalInstructions,
    required List<Map<String, dynamic>> medicines,
  }) async {
    final token = _token();
    final res = await http.post(
      Uri.parse('$_base/conv-prescriptions'),
      headers: _headers(token),
      body: jsonEncode({
        'conversation_id': conversationId,
        'title': title,
        'additional_instructions': additionalInstructions,
        'medicines': medicines,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 201 && body['success'] == true) {
      return ConvPrescriptionModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to create prescription.');
  }

  Future<ConvPrescriptionModel> getById(String id) async {
    final token = _token();
    final res = await http.get(
      Uri.parse('$_base/conv-prescriptions/$id'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return ConvPrescriptionModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to load prescription.');
  }

  Future<List<ConvPrescriptionModel>> getByPatient(String patientId) async {
    final token = _token();
    final res = await http.get(
      Uri.parse('$_base/conv-prescriptions/patient/$patientId'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return (body['data'] as List)
          .map((item) => ConvPrescriptionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
