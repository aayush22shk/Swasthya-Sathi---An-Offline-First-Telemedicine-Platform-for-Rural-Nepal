import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ConversationService {
  ConversationService._internal();
  static final ConversationService _instance = ConversationService._internal();
  factory ConversationService() => _instance;

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

  // ── List all conversations for the authenticated user ──────────────────────
  Future<List<ConversationModel>> listConversations() async {
    final token = _token();
    final res = await http.get(
      Uri.parse('$_base/conversations'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return (body['data'] as List)
          .map((j) => ConversationModel.fromJson(j))
          .toList();
    }
    throw Exception(body['message'] ?? 'Failed to load conversations.');
  }

  // ── Get or create a conversation ───────────────────────────────────────────
  // For doctor: pass patientId (patients.id UUID)
  // For patient: pass doctorId (doctors.id UUID)
  Future<ConversationModel> getOrCreate({String? patientId, String? doctorId}) async {
    final token = _token();
    final Map<String, dynamic> body = {};
    if (patientId != null) body['patient_id'] = patientId;
    if (doctorId != null) body['doctor_id'] = doctorId;

    final res = await http.post(
      Uri.parse('$_base/conversations'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    final responseBody = jsonDecode(res.body);
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return ConversationModel.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to get/create conversation.');
  }

  // ── Load messages for a conversation ──────────────────────────────────────
  Future<List<MessageModel>> getMessages(String conversationId, {int limit = 100}) async {
    final token = _token();
    final res = await http.get(
      Uri.parse('$_base/conversations/$conversationId/messages?limit=$limit'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return (body['data'] as List)
          .map((j) => MessageModel.fromJson(j))
          .toList();
    }
    throw Exception(body['message'] ?? 'Failed to load messages.');
  }

  // ── Send a text message (REST fallback when socket unavailable) ────────────
  Future<MessageModel> sendMessage(String conversationId, String content) async {
    final token = _token();
    final res = await http.post(
      Uri.parse('$_base/conversations/$conversationId/messages'),
      headers: _headers(token),
      body: jsonEncode({'content': content}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 201 && body['success'] == true) {
      return MessageModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to send message.');
  }
}
