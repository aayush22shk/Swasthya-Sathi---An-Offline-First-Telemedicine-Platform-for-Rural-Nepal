import 'package:flutter/material.dart';

/// Chat screen – unlocked only after successful eSewa payment.
class ChatScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String avatarUrl;

  const ChatScreen({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.avatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'Hello! I have reviewed your appointment details. How can I help you today?',
      isDoctor: true,
      time: _now(-2),
    ),
  ];

  static String _now([int minutesAgo = 0]) {
    final t = DateTime.now().subtract(Duration(minutes: minutesAgo));
    final h = t.hour > 12 ? t.hour - 12 : t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isDoctor: false, time: _now()));
    });
    _controller.clear();
    _scrollToBottom();

    // Simulate doctor reply after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: _doctorReply(text),
          isDoctor: true,
          time: _now(),
        ));
      });
      _scrollToBottom();
    });
  }

  String _doctorReply(String userMsg) {
    final lower = userMsg.toLowerCase();
    if (lower.contains('pain') || lower.contains('hurt')) {
      return 'I understand you are experiencing pain. Can you describe the location and severity on a scale of 1–10?';
    } else if (lower.contains('fever') || lower.contains('temperature')) {
      return 'Please measure your temperature and share the reading. Are you also experiencing chills or sweating?';
    } else if (lower.contains('thank')) {
      return 'You are welcome! Please do not hesitate to reach out if you have any further concerns. Take care!';
    } else if (lower.contains('medicine') || lower.contains('medication')) {
      return 'I will review your current medications. Can you share the names and dosages of any medicines you are currently taking?';
    } else {
      return 'Thank you for sharing that. I will need a bit more information to give you the best advice. Could you elaborate further?';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Payment success banner
          _buildPaymentSuccessBanner(),
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) => _buildBubble(_messages[i]),
            ),
          ),
          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A), size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              widget.avatarUrl,
              width: 38,
              height: 38,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 38,
                height: 38,
                color: const Color(0xFFEFF6FF),
                child: const Icon(Icons.person,
                    color: Color(0xFF0072FF), size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.doctorName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const Text('Online',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.video_call_rounded,
              color: Color(0xFF0072FF), size: 26),
          onPressed: () {},
          tooltip: 'Video Call',
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded,
              color: Color(0xFF64748B), size: 22),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildPaymentSuccessBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: Color(0xFF059669), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Payment successful via eSewa. Consultation session is now active.',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF065F46),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isDoctor = msg.isDoctor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isDoctor ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isDoctor) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                widget.avatarUrl,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person,
                      color: Color(0xFF0072FF), size: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isDoctor
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDoctor
                        ? Colors.white
                        : const Color(0xFF0072FF),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isDoctor
                          ? Radius.zero
                          : const Radius.circular(16),
                      bottomRight: isDoctor
                          ? const Radius.circular(16)
                          : Radius.zero,
                    ),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 6,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDoctor
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(msg.time,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          if (!isDoctor) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file_rounded,
                color: Color(0xFF94A3B8)),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 14),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(fontSize: 14),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0072FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color(0xFF0072FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isDoctor;
  final String time;
  const _ChatMessage(
      {required this.text, required this.isDoctor, required this.time});
}
