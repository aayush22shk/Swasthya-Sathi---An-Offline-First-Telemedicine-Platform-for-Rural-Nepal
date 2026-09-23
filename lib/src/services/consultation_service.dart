import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/chat_message_model.dart';
import 'auth_service.dart';

class ConsultationService {
  ConsultationService._internal();
  static final ConsultationService _instance = ConsultationService._internal();
  factory ConsultationService() => _instance;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Start or join a consultation session for an appointment
  Future<Map<String, dynamic>> startConsultation(String appointmentId, {String? videoRoomId}) async {
    final token = AuthService().currentUser?.token;
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required.');
    }

    final payload = {
      'appointment_id': appointmentId,
      if (videoRoomId != null && videoRoomId.isNotEmpty) 'video_room_id': videoRoomId,
    };

    final response = await http
        .post(
          Uri.parse(ApiConstants.consultations),
          headers: _headers(token),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body['data'] as Map<String, dynamic>? ?? body;
    }
    throw Exception(body['message'] ?? 'Failed to start consultation session.');
  }

  /// Get consultation details
  Future<Map<String, dynamic>> getConsultation(String consultationId) async {
    final token = AuthService().currentUser?.token;
    if (token == null || token.isEmpty) throw Exception('Authentication required.');

    final response = await http
        .get(
          Uri.parse(ApiConstants.consultationById(consultationId)),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body['data'] as Map<String, dynamic>? ?? body;
    }
    throw Exception(body['message'] ?? 'Failed to fetch consultation.');
  }

  /// Fetch messages for a consultation
  Future<List<ChatMessageModel>> getMessages(String consultationId, {int limit = 100, int offset = 0}) async {
    final token = AuthService().currentUser?.token;
    if (token == null || token.isEmpty) return [];

    try {
      final uri = Uri.parse(ApiConstants.consultationMessages(consultationId)).replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data['messages'] is List) {
          list = data['messages'] as List;
        }
        return list
            .map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Send a chat message in a consultation
  Future<ChatMessageModel> sendMessage(
    String consultationId, {
    String? message,
    String? attachmentUrl,
  }) async {
    final token = AuthService().currentUser?.token;
    if (token == null || token.isEmpty) throw Exception('Authentication required.');

    final payload = {
      if (message != null && message.isNotEmpty) 'message': message,
      if (attachmentUrl != null && attachmentUrl.isNotEmpty) 'attachment_url': attachmentUrl,
    };

    final response = await http
        .post(
          Uri.parse(ApiConstants.consultationMessages(consultationId)),
          headers: _headers(token),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return ChatMessageModel.fromJson(data);
    }
    throw Exception(body['message'] ?? 'Failed to send message.');
  }
}
