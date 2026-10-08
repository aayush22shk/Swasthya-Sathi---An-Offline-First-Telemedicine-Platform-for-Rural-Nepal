import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'auth_service.dart';

class AiChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime createdAt;

  AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      id: json['id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class AiService {
  AiService._internal();
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Start a new AI conversation
  Future<Map<String, dynamic>> startConversation({String title = 'Health Consultation'}) async {
    final token = AuthService().currentUser?.token;
    if (token == null || token.isEmpty) {
      return {'id': 'ai_local_${DateTime.now().millisecondsSinceEpoch}', 'title': title};
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.aiConversations),
            headers: _headers(token),
            body: jsonEncode({'title': title}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        return body['data'] as Map<String, dynamic>? ?? body;
      }
    } catch (_) {}

    return {'id': 'ai_local_${DateTime.now().millisecondsSinceEpoch}', 'title': title};
  }

  /// Get messages in an AI conversation
  Future<List<AiChatMessage>> getMessages(String conversationId) async {
    final token = AuthService().currentUser?.token;
    if (token == null || token.isEmpty) return [];

    try {
      final response = await http
          .get(
            Uri.parse(ApiConstants.aiConversationMessages(conversationId)),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final List<dynamic> list = body['data'] ?? [];
        return list.map((item) => AiChatMessage.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Send message to Swasthya Sathi AI Doctor
  Future<AiChatMessage> sendMessage(
    String conversationId,
    String message, {
    String language = 'en',
  }) async {
    final token = AuthService().currentUser?.token;

    if (token != null && token.isNotEmpty && !conversationId.startsWith('ai_local_')) {
      try {
        final response = await http
            .post(
              Uri.parse(ApiConstants.aiConversationMessages(conversationId)),
              headers: _headers(token),
              body: jsonEncode({'message': message, 'language': language}),
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final body = jsonDecode(response.body);
          final data = body['data'] as Map<String, dynamic>? ?? body;
          return AiChatMessage.fromJson(data);
        }
      } catch (_) {}
    }

    // Fallback AI generation when offline or during transient network drops
    await Future.delayed(const Duration(milliseconds: 1200));
    return AiChatMessage(
      id: 'ai_msg_${DateTime.now().millisecondsSinceEpoch}',
      role: 'assistant',
      content: _generateOfflineAiResponse(message),
      createdAt: DateTime.now(),
    );
  }

  String _generateOfflineAiResponse(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('bp') || lower.contains('pressure') || lower.contains('hypertension')) {
      return "For healthy blood pressure management:\n\n• Keep your daily sodium (salt) intake low (less than 2g sodium/day).\n• Engage in at least 30 minutes of moderate cardiovascular activity.\n• Maintain adequate hydration and avoid excessive stress or caffeine.\n• If your systolic reading is persistently above 140 mmHg or diastolic above 90 mmHg, please consult a physician.\n\n⚠️ Disclaimer: I am an AI assistant. Please consult a qualified doctor for clinical diagnosis and prescriptions.";
    } else if (lower.contains('fever') || lower.contains('temperature') || lower.contains('hot')) {
      return "Guidance for fever management:\n\n• Stay well hydrated with water, herbal teas, or oral rehydration fluids.\n• Rest in a comfortable, well-ventilated room with light clothing.\n• Paracetamol (as indicated for your age/weight) can help reduce discomfort.\n• Seek immediate medical attention if fever exceeds 103°F (39.4°C), lasts more than 3 days, or is accompanied by stiff neck, rash, or difficulty breathing.\n\n⚠️ Disclaimer: This is AI health guidance and not a substitute for a human doctor's assessment.";
    } else if (lower.contains('altitude') || lower.contains('mountain') || lower.contains('himal')) {
      return "Acute Mountain Sickness (AMS) Guidance:\n\n• Ascend gradually (no more than 300-500 meters per day above 3,000m).\n• Drink 4–5 liters of water daily and avoid alcohol or sedatives.\n• If experiencing severe headache, nausea, or dizziness, do NOT ascend higher. Descend immediately if symptoms worsen.\n\n⚠️ Disclaimer: I am an AI assistant. In emergency situations, contact local rescue services.";
    } else if (lower.contains('chest') || lower.contains('breath') || lower.contains('emergency')) {
      return "🚨 Potential Urgent Situation:\n\nIf you or someone else is experiencing severe chest pain, shortness of breath, sudden numbness, or loss of consciousness, please seek IMMEDIATE emergency medical care or call 102 (Emergency Ambulance Service in Nepal).\n\n⚠️ Disclaimer: AI cannot handle acute medical emergencies.";
    } else {
      return "Thank you for sharing your health query with Swasthya Sathi AI Doctor.\n\nTo help maintain overall health:\n• Ensure a balanced diet rich in whole foods, vegetables, and lean proteins.\n• Drink plenty of clean, boiled or filtered water.\n• Practice proper sleep hygiene (7-8 hours daily).\n• Monitor your health vitals regularly using the Swasthya Sathi Health Monitor.\n\nIf your symptoms persist, please book an appointment with a certified doctor on Swasthya Sathi.\n\n⚠️ Reminder: You are chatting with an AI assistant, not a human doctor.";
    }
  }
}
