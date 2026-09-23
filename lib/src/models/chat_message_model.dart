/// Chat message from the backend `chat_messages` table.
class ChatMessageModel {
  final String id;
  final String consultationId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'patient' | 'doctor'
  final String? message;
  final String? attachmentUrl;
  final DateTime sentAt;

  const ChatMessageModel({
    required this.id,
    required this.consultationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    this.message,
    this.attachmentUrl,
    required this.sentAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      consultationId: json['consultation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'User',
      senderRole: json['sender_role']?.toString() ?? 'patient',
      message: json['message']?.toString(),
      attachmentUrl: json['attachment_url']?.toString(),
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  bool get isDoctor => senderRole == 'doctor';

  String get formattedTime {
    final h = sentAt.hour > 12 ? sentAt.hour - 12 : (sentAt.hour == 0 ? 12 : sentAt.hour);
    final m = sentAt.minute.toString().padLeft(2, '0');
    final period = sentAt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}
