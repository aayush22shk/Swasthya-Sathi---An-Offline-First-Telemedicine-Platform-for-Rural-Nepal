enum MessageType { text, prescription, diagnosis }

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderRole; // 'doctor' | 'patient'
  final String? senderName;
  final MessageType messageType;
  final String? messageContent;
  final String? referenceId; // points to conv_prescription or diagnosis_result
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    this.senderName,
    required this.messageType,
    this.messageContent,
    this.referenceId,
    required this.createdAt,
  });

  bool get isDoctor => senderRole == 'doctor';

  String get formattedTime {
    final t = createdAt.toLocal();
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  factory MessageModel.fromJson(Map<String, dynamic> j) {
    final typeStr = (j['message_type'] as String? ?? 'text');
    final type = typeStr == 'prescription'
        ? MessageType.prescription
        : typeStr == 'diagnosis'
            ? MessageType.diagnosis
            : MessageType.text;
    return MessageModel(
      id: j['id'] as String,
      conversationId: j['conversation_id'] as String,
      senderId: j['sender_id'] as String,
      senderRole: j['sender_role'] as String,
      senderName: j['sender_name'] as String?,
      messageType: type,
      messageContent: j['message_content'] as String?,
      referenceId: j['reference_id'] as String?,
      createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_role': senderRole,
        'sender_name': senderName,
        'message_type': messageType.name,
        'message_content': messageContent,
        'reference_id': referenceId,
        'created_at': createdAt.toIso8601String(),
      };
}
