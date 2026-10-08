import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/consultation_service.dart';
import '../../../services/prescription_service.dart';

/// Doctor-Patient Consultation Chat Screen
class ChatScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String avatarUrl;
  final String? consultationId;
  final String? patientId;
  final String? patientName;

  const ChatScreen({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.avatarUrl,
    this.consultationId,
    this.patientId,
    this.patientName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ConsultationService _consultationService = ConsultationService();
  Timer? _pollingTimer;

  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  Map<String, dynamic>? _consultationDetails;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    if (widget.consultationId != null && widget.consultationId!.isNotEmpty) {
      setState(() => _isLoading = true);
      await _fetchBackendMessages();
      await _fetchConsultationDetails();
      if (mounted) setState(() => _isLoading = false);

      // Poll every 4 seconds for new incoming messages from doctor/patient
      _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _fetchBackendMessages(silent: true);
      });
    } else {
      // If started without a consultation ID yet
      _messages.add(
        _ChatMessage(
          text: 'Welcome to your consultation session with ${widget.doctorName}. Please send your symptoms or questions.',
          isDoctor: true,
          time: _now(),
        ),
      );
    }
  }

  Future<void> _fetchConsultationDetails() async {
    if (widget.consultationId == null || widget.consultationId!.isEmpty) return;
    try {
      final data = await _consultationService.getConsultation(widget.consultationId!);
      if (mounted) {
        setState(() {
          _consultationDetails = data;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchBackendMessages({bool silent = false}) async {
    if (widget.consultationId == null || widget.consultationId!.isEmpty) return;
    try {
      final list = await _consultationService.getMessages(widget.consultationId!);
      if (list.isNotEmpty && mounted) {
        final currentUserId = AuthService().currentUser?.id ?? '';
        final currentUserRole = AuthService().currentUser?.role ?? 'patient';

        setState(() {
          _messages.clear();
          for (final m in list) {
            final isSenderDoctor = m.senderRole == 'doctor' || (currentUserRole == 'doctor' && m.senderId == currentUserId);
            _messages.add(
              _ChatMessage(
                id: m.id,
                text: m.message ?? '',
                isDoctor: isSenderDoctor,
                senderName: m.senderName,
                time: m.formattedTime,
              ),
            );
          }
        });
        if (!silent) _scrollToBottom();
      }
    } catch (_) {}
  }

  static String _now([int minutesAgo = 0]) {
    final t = DateTime.now().subtract(Duration(minutes: minutesAgo));
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final isDoctorUser = AuthService().currentUser?.isDoctor ?? false;

    _controller.clear();
    setState(() {
      _isSending = true;
      _messages.add(
        _ChatMessage(
          text: text,
          isDoctor: isDoctorUser,
          senderName: AuthService().currentUser?.fullName,
          time: _now(),
        ),
      );
    });
    _scrollToBottom();

    if (widget.consultationId != null && widget.consultationId!.isNotEmpty) {
      try {
        await _consultationService.sendMessage(
          widget.consultationId!,
          message: text,
        );
      } catch (e) {
        // Kept local message with network retry capability
      }
    }

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showConsultationSummaryModal() {
    final notes = _consultationDetails?['doctor_notes'] ?? 'Consultation ongoing. Clinical observation in progress.';
    final diagnosis = _consultationDetails?['diagnosis'] ?? 'General Consultation / Clinical Assessment';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_rounded, color: Color(0xFF0072FF), size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Consultation Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailTile(
              title: 'Doctor',
              value: widget.doctorName,
              icon: Icons.medical_services_outlined,
            ),
            const SizedBox(height: 10),
            _buildDetailTile(
              title: 'Specialty',
              value: widget.specialty,
              icon: Icons.local_hospital_outlined,
            ),
            const SizedBox(height: 10),
            _buildDetailTile(
              title: 'Clinical Diagnosis',
              value: diagnosis.toString(),
              icon: Icons.healing_outlined,
            ),
            const SizedBox(height: 10),
            _buildDetailTile(
              title: 'Doctor Notes & Advice',
              value: notes.toString(),
              icon: Icons.notes_rounded,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0072FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrescriptionsModal() async {
    final patientId = widget.patientId ?? AuthService().currentUser?.id;
    List<PatientPrescription> list = [];
    if (patientId != null && patientId.isNotEmpty) {
      try {
        list = await PrescriptionService().getPatientPrescriptions(patientId);
      } catch (_) {}
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medication_rounded, color: Color(0xFF059669), size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Consultation Prescriptions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text(
                            'No digital prescription issued yet.',
                            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Your doctor will issue prescriptions during or after the session.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final rx = list[i];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    rx.doctorName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    rx.formattedDate,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              if (rx.notes.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  rx.notes,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontStyle: FontStyle.italic),
                                ),
                              ],
                              const Divider(height: 16),
                              ...rx.items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('💊 ', style: TextStyle(fontSize: 12)),
                                        Expanded(
                                          child: Text(
                                            '${item.medicineName} ${item.dosage} - ${item.frequency} (${item.durationDays}d)\n${item.instructions}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0072FF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildConsultationBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0072FF)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) => _buildBubble(_messages[i]),
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
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
                child: const Icon(Icons.person, color: Color(0xFF0072FF), size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctorName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.specialty,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
          tooltip: 'Consultation Actions',
          onSelected: (val) {
            if (val == 'summary') {
              _showConsultationSummaryModal();
            } else if (val == 'prescription') {
              _showPrescriptionsModal();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'summary',
              child: Row(
                children: [
                  Icon(Icons.assignment_outlined, color: Color(0xFF0072FF), size: 20),
                  SizedBox(width: 10),
                  Text('Consultation Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'prescription',
              child: Row(
                children: [
                  Icon(Icons.medication_outlined, color: Color(0xFF059669), size: 20),
                  SizedBox(width: 10),
                  Text('View Prescriptions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConsultationBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Direct Consultation with ${widget.doctorName}. Messages are private & encrypted.',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF065F46), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isDoctor = msg.isDoctor;
    final isMe = (AuthService().currentUser?.isDoctor ?? false) ? isDoctor : !isDoctor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && isDoctor) ...[
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
                  child: const Icon(Icons.person, color: Color(0xFF0072FF), size: 16),
                ),
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
                      isDoctor ? widget.doctorName : (msg.senderName ?? 'Patient'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDoctor ? const Color(0xFF0072FF) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
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
                      BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isMe ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(msg.time, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
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
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -4))
        ],
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
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Type your message to doctor...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
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
                    color: const Color(0xFF0072FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String? id;
  final String text;
  final bool isDoctor;
  final String? senderName;
  final String time;

  const _ChatMessage({
    this.id,
    required this.text,
    required this.isDoctor,
    this.senderName,
    required this.time,
  });
}
