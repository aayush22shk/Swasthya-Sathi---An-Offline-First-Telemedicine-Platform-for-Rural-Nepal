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
import '../../skin_analysis/view/skin_analysis_upload_screen.dart';
import '../../skin_analysis/view/skin_analysis_result_screen.dart';
import '../../../models/skin_analysis_model.dart';
import '../../../cds/clinical_briefing_card.dart';
import '../../../cds/longitudinal_summary_service.dart';
import '../../../cds/medical_terminology_service.dart';
import '../../../services/offline_sync_queue_service.dart';

/// Doctor-side persistent chat screen with Prescription & Diagnosis attachments.
class DoctorChatScreen extends StatefulWidget {
  /// Preferred: direct conversation ID (UUID from conversations table).
  /// Provide this OR [patientEntityId] to resolve the conversation.
  final String? conversationId;

  /// Alternative: patients.id UUID — the screen will call getOrCreate to resolve the conversation.
  final String? patientEntityId;

  final String patientId;      // patients.id (UUID) — also used for display
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientLocation;
  final String? avatarUrl;

  const DoctorChatScreen({
    super.key,
    this.conversationId,
    this.patientEntityId,
    required this.patientId,
    required this.patientName,
    this.patientAge = 0,
    this.patientGender = 'Unknown',
    this.patientLocation = 'Nepal',
    this.avatarUrl,
  });

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ConversationService _convService = ConversationService();
  final ConvPrescriptionService _rxService = ConvPrescriptionService();
  final DiagnosisService _dxService = DiagnosisService();

  final List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _resolvedConvId; // resolved from widget.conversationId OR getOrCreate
  LongitudinalSummary? _clinicalSummary;

  String get _convId => _resolvedConvId ?? widget.conversationId ?? '';
  Timer? _pollingTimer;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    MedicalTerminologyService().initialize();
    OfflineSyncQueueService().loadQueue();
    _initChat();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────
  Future<void> _initChat() async {
    setState(() => _isLoading = true);

    // 1. Resolve conversation ID
    if (widget.conversationId != null && widget.conversationId!.isNotEmpty) {
      _resolvedConvId = widget.conversationId;
    } else if (widget.patientEntityId != null && widget.patientEntityId!.isNotEmpty) {
      try {
        final conv = await _convService.getOrCreate(patientId: widget.patientEntityId!);
        _resolvedConvId = conv.id;
      } catch (_) {}
    } else {
      // Fallback: use patientId as patients.id to create conversation
      try {
        final conv = await _convService.getOrCreate(patientId: widget.patientId);
        _resolvedConvId = conv.id;
      } catch (_) {}
    }

    // 2. Load history
    await _fetchMessages();
    _loadClinicalSummary();
    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
      _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _fetchMessages(silent: true);
      });
    }
  }

  Future<void> _loadClinicalSummary() async {
    try {
      final dxList = await _dxService.getByPatient(widget.patientId);
      final rxList = await _rxService.getByPatient(widget.patientId);
      if (mounted) {
        setState(() {
          _clinicalSummary = LongitudinalSummaryService.generateSummary(
            patientId: widget.patientId,
            diagnoses: dxList,
            prescriptions: rxList,
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    final convId = _convId;
    if (convId.isEmpty) return;
    try {
      final msgs = await _convService.getMessages(convId);
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

  // ── Send text ──────────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    _msgCtrl.clear();
    setState(() => _isSending = true);

    final me = AuthService().currentUser;
    final optimistic = MessageModel(
      id: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _convId,
      senderId: me?.id ?? '',
      senderRole: 'doctor',
      senderName: me?.fullName ?? 'Doctor',
      messageType: MessageType.text,
      messageContent: text,
      createdAt: DateTime.now(),
    );

    setState(() => _messages.add(optimistic));
    _scrollToBottom();

    try {
      final saved = await _convService.sendMessage(_convId, text);
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == optimistic.id);
          if (idx >= 0) _messages[idx] = saved;
        });
      }
    } catch (_) {
      // Offline fallback: enqueue to sync queue
      await OfflineSyncQueueService().enqueue(
        endpoint: '/api/v1/conversations/$_convId/messages',
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

  // ── Attachment bottom sheet ────────────────────────────────────────────────
  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medication_rounded, color: Color(0xFF059669)),
              ),
              title: const Text('Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Issue medicines for the patient'),
              onTap: () {
                // ignore: use_build_context_synchronously
                                       Navigator.pop(ctx);
                _showPrescriptionDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_rounded, color: Color(0xFFF59E0B)),
              ),
              title: const Text('Diagnosis Results', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Share clinical findings & treatment plan'),
              onTap: () {
                // ignore: use_build_context_synchronously
                                       Navigator.pop(ctx);
                _showDiagnosisDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF0D9488)),
              ),
              title: const Text('Skin Analysis Screenings', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Review patient-shared skin photographs & findings'),
              onTap: () {
                // ignore: use_build_context_synchronously
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SkinAnalysisUploadScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Prescription dialog ────────────────────────────────────────────────────
  void _showPrescriptionDialog() {
    final titleCtrl = TextEditingController();
    final instructionsCtrl = TextEditingController();
    final List<Map<String, TextEditingController>> medicines = [
      _newMedControllers(),
    ];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(ctx).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _sheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    const Icon(Icons.medication_rounded, color: Color(0xFF059669)),
                    const SizedBox(width: 10),
                    const Text('New Prescription',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Medicine'),
                      onPressed: () => setS(() => medicines.add(_newMedControllers())),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _inputField(titleCtrl, 'Prescription Title (optional)', maxLines: 1),
                      const SizedBox(height: 10),
                      const Text(
                        'Nepal Essential Medicines (Quick Fill):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final med in MedicalTerminologyService().medicines.take(8))
                              Padding(
                                padding: const EdgeInsets.only(right: 6, bottom: 8),
                                child: ActionChip(
                                  avatar: const Icon(Icons.medication_outlined, size: 14, color: Color(0xFF059669)),
                                  label: Text(med.name, style: const TextStyle(fontSize: 12)),
                                  backgroundColor: const Color(0xFFF0FDF4),
                                  side: BorderSide(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                                  onPressed: () {
                                    setS(() {
                                      final target = medicines.last;
                                      target['name']!.text = med.name;
                                      target['dosage']!.text = med.defaultDosage;
                                      target['freq']!.text = med.defaultFrequency;
                                      target['duration']!.text = med.defaultDuration;
                                      target['instructions']!.text = '${med.nepaliUsage} (${med.category})';
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...medicines.asMap().entries.map((e) {
                        final i = e.key;
                        final m = e.value;
                        return _medicineCard(m, i, medicines.length > 1,
                            () => setS(() => medicines.removeAt(i)));
                      }),
                      const SizedBox(height: 12),
                      _inputField(instructionsCtrl, 'Additional Instructions', maxLines: 3),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  setS(() => isSaving = true);
                                  try {
                                    final meds = medicines.map((m) => {
                                      'medicine_name': m['name']!.text.trim(),
                                      'dosage': m['dosage']!.text.trim(),
                                      'frequency': m['freq']!.text.trim(),
                                      'duration': m['duration']!.text.trim(),
                                      'instructions': m['instructions']!.text.trim(),
                                    }).where((m) => (m['medicine_name'] as String).isNotEmpty).toList();

                                    if (meds.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Add at least one medicine.')));
                                      setS(() => isSaving = false);
                                      return;
                                    }

                                    final _ = await _rxService.create(
                                      conversationId: _convId,
                                      title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
                                      additionalInstructions: instructionsCtrl.text.trim().isEmpty
                                          ? null : instructionsCtrl.text.trim(),
                                      medicines: meds,
                                    );

                                    if (mounted) {
                                      // ignore: use_build_context_synchronously
                                       Navigator.pop(ctx);
                                      await _fetchMessages();
                                      _loadClinicalSummary();
                                      _scrollToBottom();
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')));
                                    }
                                    setS(() => isSaving = false);
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Send Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, TextEditingController> _newMedControllers() => {
    'name': TextEditingController(),
    'dosage': TextEditingController(),
    'freq': TextEditingController(),
    'duration': TextEditingController(),
    'instructions': TextEditingController(),
  };

  Widget _medicineCard(Map<String, TextEditingController> m, int i, bool canDelete, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Medicine ${i + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669))),
              const Spacer(),
              if (canDelete)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _inputField(m['name']!, 'Medicine Name *', maxLines: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _inputField(m['dosage']!, 'Dosage (e.g. 500mg)', maxLines: 1)),
              const SizedBox(width: 8),
              Expanded(child: _inputField(m['freq']!, 'Frequency (e.g. 2×/day)', maxLines: 1)),
            ],
          ),
          const SizedBox(height: 8),
          _inputField(m['duration']!, 'Duration (e.g. 7 days)', maxLines: 1),
          const SizedBox(height: 8),
          _inputField(m['instructions']!, 'Special Instructions', maxLines: 2),
        ],
      ),
    );
  }

  // ── Diagnosis dialog ───────────────────────────────────────────────────────
  void _showDiagnosisDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final findingsCtrl = TextEditingController();
    final treatmentCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(ctx).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _sheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_rounded, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 10),
                    const Text('Diagnosis Results',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _inputField(titleCtrl, 'Diagnosis Title *', maxLines: 1),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Common Conditions (ICD-11 Quick Select):',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final cond in MedicalTerminologyService().conditions.take(8))
                              Padding(
                                padding: const EdgeInsets.only(right: 6, bottom: 8),
                                child: ActionChip(
                                  avatar: const Icon(Icons.local_hospital_outlined, size: 14, color: Color(0xFFD97706)),
                                  label: Text('${cond.name} (${cond.code})', style: const TextStyle(fontSize: 12)),
                                  backgroundColor: const Color(0xFFFEF3C7),
                                  side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                                  onPressed: () {
                                    setS(() {
                                      titleCtrl.text = '${cond.name} [${cond.code}]';
                                      if (descCtrl.text.isEmpty) {
                                        descCtrl.text = '${cond.nepali} (${cond.category})';
                                      }
                                      if (findingsCtrl.text.isEmpty && cond.symptoms.isNotEmpty) {
                                        findingsCtrl.text = 'Key features: ${cond.symptoms.join(", ")}';
                                      }
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _inputField(descCtrl, 'Description / Summary', maxLines: 3),
                      const SizedBox(height: 12),
                      _inputField(findingsCtrl, 'Clinical Findings', maxLines: 4),
                      const SizedBox(height: 12),
                      _inputField(treatmentCtrl, 'Recommended Treatment', maxLines: 3),
                      const SizedBox(height: 12),
                      _inputField(notesCtrl, 'Additional Notes', maxLines: 2),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (titleCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Title is required.')));
                                    return;
                                  }
                                  setS(() => isSaving = true);
                                  try {
                                    await _dxService.create(
                                      conversationId: _convId,
                                      title: titleCtrl.text.trim(),
                                      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                      findings: findingsCtrl.text.trim().isEmpty ? null : findingsCtrl.text.trim(),
                                      recommendedTreatment: treatmentCtrl.text.trim().isEmpty ? null : treatmentCtrl.text.trim(),
                                      additionalNotes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                    );
                                    if (mounted) {
                                      // ignore: use_build_context_synchronously
                                       Navigator.pop(ctx);
                                      await _fetchMessages();
                                      _loadClinicalSummary();
                                      _scrollToBottom();
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')));
                                    }
                                    setS(() => isSaving = false);
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Send Diagnosis', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────
  Widget _sheetHandle() => Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40, height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _inputField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0072FF)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
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
              backgroundImage: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                  ? Text(
                      widget.patientName.isNotEmpty ? widget.patientName[0].toUpperCase() : 'P',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0072FF)),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.patientName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text(
                    '${widget.patientGender} · ${widget.patientAge > 0 ? "${widget.patientAge} yrs · " : ""}${widget.patientLocation}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
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
          if (_clinicalSummary != null)
            ClinicalBriefingCard(summary: _clinicalSummary!),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0072FF)))
                : _messages.isEmpty
                    ? const Center(
                        child: Text('No messages yet. Start the conversation!',
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
        return _PrescriptionBubble(
          msg: msg,
          rxService: _rxService,
          onTap: (rx) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PrescriptionDetailScreen(prescription: rx)),
          ),
        );
      case MessageType.diagnosis:
        return _DiagnosisBubble(
          msg: msg,
          dxService: _dxService,
          onTap: (dx) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DiagnosisDetailScreen(diagnosis: dx)),
          ),
        );
      case MessageType.text:
        return _TextBubble(msg: msg, myRole: 'doctor', otherName: widget.patientName);
    }
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: Row(
        children: [
          // Plus button
          GestureDetector(
            onTap: _showAttachmentSheet,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0072FF).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.add_rounded, color: Color(0xFF0072FF), size: 22),
            ),
          ),
          const SizedBox(width: 10),
          // Message input
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _msgCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(fontSize: 14),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button
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
// Shared bubble widgets
// =============================================================================

class _TextBubble extends StatelessWidget {
  final MessageModel msg;
  final String myRole;
  final String otherName;

  const _TextBubble({required this.msg, required this.myRole, required this.otherName});

  @override
  Widget build(BuildContext context) {
    final isMe = msg.senderRole == myRole;
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
                (msg.senderName?.isNotEmpty == true ? msg.senderName![0] : otherName.isNotEmpty ? otherName[0] : '?').toUpperCase(),
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
                      msg.senderName ?? otherName,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
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
                                'AI Skin Screening Report',
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
                            label: const Text('Review Analysis & Notes', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
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
                                    isDoctorView: true,
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

class _PrescriptionBubble extends StatefulWidget {
  final MessageModel msg;
  final ConvPrescriptionService rxService;
  final void Function(ConvPrescriptionModel) onTap;

  const _PrescriptionBubble({required this.msg, required this.rxService, required this.onTap});

  @override
  State<_PrescriptionBubble> createState() => _PrescriptionBubbleState();
}

class _PrescriptionBubbleState extends State<_PrescriptionBubble> {
  ConvPrescriptionModel? _rx;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.msg.referenceId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final rx = await widget.rxService.getById(widget.msg.referenceId!);
      if (mounted) setState(() { _rx = rx; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
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
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.08),
                      blurRadius: 8, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _loading
                    ? const Row(children: [
                        SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669))),
                        SizedBox(width: 10),
                        Text('Loading prescription...', style: TextStyle(color: Color(0xFF059669))),
                      ])
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.medication_rounded, color: Color(0xFF059669), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _rx?.title ?? widget.msg.messageContent ?? 'Prescription',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, color: Color(0xFF059669), fontSize: 14),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF059669)),
                            ],
                          ),
                          if (_rx != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${_rx!.medicines.length} medicine${_rx!.medicines.length != 1 ? "s" : ""} · Tap to view',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            if (_rx!.medicines.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              ..._rx!.medicines.take(2).map((m) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.circle, size: 5, color: Color(0xFF059669)),
                                    const SizedBox(width: 6),
                                    Text('${m.medicineName}${m.dosage != null ? " · ${m.dosage}" : ""}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
                                  ],
                                ),
                              )),
                              if (_rx!.medicines.length > 2)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2, left: 11),
                                  child: Text('+${_rx!.medicines.length - 2} more',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ),
                            ],
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

class _DiagnosisBubble extends StatefulWidget {
  final MessageModel msg;
  final DiagnosisService dxService;
  final void Function(DiagnosisModel) onTap;

  const _DiagnosisBubble({required this.msg, required this.dxService, required this.onTap});

  @override
  State<_DiagnosisBubble> createState() => _DiagnosisBubbleState();
}

class _DiagnosisBubbleState extends State<_DiagnosisBubble> {
  DiagnosisModel? _dx;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.msg.referenceId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final dx = await widget.dxService.getById(widget.msg.referenceId!);
      if (mounted) setState(() { _dx = dx; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
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
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                      blurRadius: 8, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _loading
                    ? const Row(children: [
                        SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B))),
                        SizedBox(width: 10),
                        Text('Loading diagnosis...', style: TextStyle(color: Color(0xFFF59E0B))),
                      ])
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.assignment_rounded, color: Color(0xFFF59E0B), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _dx?.title ?? widget.msg.messageContent ?? 'Diagnosis',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, color: Color(0xFFB45309), fontSize: 14),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFF59E0B)),
                            ],
                          ),
                          if (_dx?.description != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _dx!.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                            ),
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
