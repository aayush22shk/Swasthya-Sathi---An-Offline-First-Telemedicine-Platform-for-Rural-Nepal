import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/message_model.dart';
import '../../../models/conv_prescription_model.dart';
import '../../../models/diagnosis_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/conversation_service.dart';
import '../../../services/conv_prescription_service.dart';
import '../../../services/diagnosis_service.dart';
import 'prescription_detail_screen.dart';
import 'diagnosis_detail_screen.dart';
import '../../skin_analysis/view/skin_analysis_result_screen.dart';
import '../../../models/skin_analysis_model.dart';
import '../../../services/offline_sync_queue_service.dart';

/// Patient-side persistent chat screen.
/// Shows conversation history with the doctor including prescription & diagnosis cards (read-only).
class ChatScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String avatarUrl;

  // New conversation-based params (preferred)
  final String? conversationId;

  // Legacy consultation-based params (kept for backward compat — ignored if conversationId provided)
  final String? consultationId;
  final String? appointmentId;
  final String? patientId;
  final String? patientName;

  // For getting/creating a conversation when conversationId not yet known
  final String? doctorEntityId; // doctors.id UUID

  const ChatScreen({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.avatarUrl,
    this.conversationId,
    this.consultationId,
    this.appointmentId,
    this.patientId,
    this.patientName,
    this.doctorEntityId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ConversationService _convService = ConversationService();
  final ConvPrescriptionService _rxService = ConvPrescriptionService();
  final DiagnosisService _dxService = DiagnosisService();

  final List<MessageModel> _messages = [];
  String? _activeConversationId;
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    setState(() { _isLoading = true; _error = null; });

    // 1. Determine conversation ID
    if (widget.conversationId != null && widget.conversationId!.isNotEmpty) {
      _activeConversationId = widget.conversationId;
    } else if (widget.doctorEntityId != null && widget.doctorEntityId!.isNotEmpty) {
      try {
        final conv = await _convService.getOrCreate(doctorId: widget.doctorEntityId!);
        _activeConversationId = conv.id;
      } catch (e) {
        if (mounted) setState(() { _error = 'Could not connect to chat: $e'; _isLoading = false; });
        return;
      }
    }

    if (_activeConversationId == null) {
      if (mounted) setState(() { _error = 'No conversation ID available.'; _isLoading = false; });
      return;
    }

    // 2. Load history
    await _fetchMessages();
    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
      _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _fetchMessages(silent: true);
      });
    }
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (_activeConversationId == null) return;
    try {
      final msgs = await _convService.getMessages(_activeConversationId!);
      if (!mounted) return;
      if (msgs.length != _messages.length) {
        setState(() {
          _messages
            ..clear()
            ..addAll(msgs);
        });
        if (!silent) _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _isSending || _activeConversationId == null) return;

    _ctrl.clear();
    setState(() => _isSending = true);

    final me = AuthService().currentUser;
    final optimistic = MessageModel(
      id: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _activeConversationId!,
      senderId: me?.id ?? '',
      senderRole: 'patient',
      senderName: me?.fullName ?? 'You',
      messageType: MessageType.text,
      messageContent: text,
      createdAt: DateTime.now(),
    );

    setState(() => _messages.add(optimistic));
    _scrollToBottom();

    try {
      final saved = await _convService.sendMessage(_activeConversationId!, text);
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == optimistic.id);
          if (idx >= 0) _messages[idx] = saved;
        });
      }
    } catch (_) {
      // Offline fallback: enqueue to sync queue
      await OfflineSyncQueueService().enqueue(
        endpoint: '/api/v1/conversations/$_activeConversationId/messages',
        payload: {'message_content': text},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline: message queued for auto-sync.'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF64748B),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFEFF6FF),
              backgroundImage: widget.avatarUrl.isNotEmpty ? NetworkImage(widget.avatarUrl) : null,
              child: widget.avatarUrl.isEmpty
                  ? Text(
                      widget.doctorName.isNotEmpty ? widget.doctorName[0].toUpperCase() : 'D',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0072FF)),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.doctorName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text(widget.specialty,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0072FF)))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Color(0xFFF59E0B)),
                              const SizedBox(height: 12),
                              Text(_error!, textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFF64748B))),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _initChat,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _messages.isEmpty
                        ? const Center(
                            child: Text('No messages yet. Ask your doctor a question!',
                                style: TextStyle(color: Color(0xFF64748B))))
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) => _buildBubble(_messages[i]),
                          ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(MessageModel msg) {
    switch (msg.messageType) {
      case MessageType.prescription:
        return _PatientPrescriptionBubble(
          msg: msg,
          rxService: _rxService,
          onTap: (rx) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PrescriptionDetailScreen(prescription: rx)),
          ),
        );
      case MessageType.diagnosis:
        return _PatientDiagnosisBubble(
          msg: msg,
          dxService: _dxService,
          onTap: (dx) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DiagnosisDetailScreen(diagnosis: dx)),
          ),
        );
      case MessageType.text:
        final isMe = msg.senderRole == 'patient';
        return _PatientTextBubble(msg: msg, isMe: isMe, doctorName: widget.doctorName);
    }
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _ctrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration.collapsed(
                  hintText: _activeConversationId == null
                      ? 'Connecting...'
                      : 'Type your message to ${widget.doctorName}...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
                enabled: _activeConversationId != null,
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
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0072FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0072FF).withValues(alpha: 0.3),
                    blurRadius: 8, offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isSending
                  ? const Center(
                      child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Patient-side bubble widgets
// =============================================================================

class _PatientTextBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final String doctorName;

  const _PatientTextBubble({required this.msg, required this.isMe, required this.doctorName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFEFF6FF),
              child: Text(
                doctorName.isNotEmpty ? doctorName[0].toUpperCase() : 'D',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0072FF)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      msg.senderName ?? doctorName,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0072FF)),
                    ),
                  ),
                if (msg.messageContent?.contains('[AI Skin Screening]') == true) ...[
                  Container(
                    width: 270,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.document_scanner_rounded, size: 16, color: Color(0xFF0D9488)),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'AI Skin Screening Shared',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          msg.messageContent ?? '',
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), height: 1.3),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.visibility_outlined, size: 14),
                            label: const Text('View Full Report & Guidance', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              final parts = msg.messageContent?.split('shared my ');
                              final cond = (parts != null && parts.length > 1)
                                  ? parts[1].split(' image').first
                                  : 'Skin Condition';
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SkinAnalysisResultScreen(
                                    analysis: SkinAnalysisModel.fromCondition(cond),
                                    isDoctorView: false,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF0072FF) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      msg.messageContent ?? '',
                      style: TextStyle(
                        fontSize: 14, height: 1.4,
                        color: isMe ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(msg.formattedTime, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _PatientPrescriptionBubble extends StatefulWidget {
  final MessageModel msg;
  final ConvPrescriptionService rxService;
  final void Function(ConvPrescriptionModel) onTap;

  const _PatientPrescriptionBubble({required this.msg, required this.rxService, required this.onTap});

  @override
  State<_PatientPrescriptionBubble> createState() => _PatientPrescriptionBubbleState();
}

class _PatientPrescriptionBubbleState extends State<_PatientPrescriptionBubble> {
  ConvPrescriptionModel? _rx;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.msg.referenceId != null) {
      widget.rxService.getById(widget.msg.referenceId!).then((rx) {
        if (mounted) setState(() { _rx = rx; _loading = false; });
      }).catchError((_) { if (mounted) setState(() => _loading = false); });
    } else {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Flexible(
            child: GestureDetector(
              onTap: _rx == null ? null : () => widget.onTap(_rx!),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.4)),
                ),
                child: _loading
                    ? const Row(children: [
                        SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669))),
                        SizedBox(width: 10),
                        Text('Loading...', style: TextStyle(color: Color(0xFF059669))),
                      ])
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.medication_rounded, color: Color(0xFF059669), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _rx?.title ?? 'Prescription from your doctor',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF059669)),
                          ]),
                          if (_rx != null) ...[
                            const SizedBox(height: 6),
                            Text('${_rx!.medicines.length} medicine(s) · Tap to view details',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _PatientDiagnosisBubble extends StatefulWidget {
  final MessageModel msg;
  final DiagnosisService dxService;
  final void Function(DiagnosisModel) onTap;

  const _PatientDiagnosisBubble({required this.msg, required this.dxService, required this.onTap});

  @override
  State<_PatientDiagnosisBubble> createState() => _PatientDiagnosisBubbleState();
}

class _PatientDiagnosisBubbleState extends State<_PatientDiagnosisBubble> {
  DiagnosisModel? _dx;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.msg.referenceId != null) {
      widget.dxService.getById(widget.msg.referenceId!).then((dx) {
        if (mounted) setState(() { _dx = dx; _loading = false; });
      }).catchError((_) { if (mounted) setState(() => _loading = false); });
    } else {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Flexible(
            child: GestureDetector(
              onTap: _dx == null ? null : () => widget.onTap(_dx!),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: _loading
                    ? const Row(children: [
                        SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B))),
                        SizedBox(width: 10),
                        Text('Loading...', style: TextStyle(color: Color(0xFFF59E0B))),
                      ])
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.assignment_rounded, color: Color(0xFFF59E0B), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _dx?.title ?? 'Diagnosis results',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFF59E0B)),
                          ]),
                          if (_dx?.description != null) ...[
                            const SizedBox(height: 6),
                            Text(_dx!.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF78350F))),
                          ],
                          const SizedBox(height: 4),
                          const Text('Tap to view full report',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
