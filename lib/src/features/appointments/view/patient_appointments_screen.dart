import 'package:flutter/material.dart';
import '../../../models/appointment_model.dart';
import '../../../services/appointment_service.dart';

/// Shows the authenticated patient's full appointment history,
/// pulling live status from the backend/database.
class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<AppointmentModel> _pending    = [];
  List<AppointmentModel> _confirmed  = [];
  List<AppointmentModel> _completed  = [];
  List<AppointmentModel> _cancelled  = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final appts = await AppointmentService().getAppointments();
      if (!mounted) return;
      setState(() {
        _pending   = appts.where((a) => a.status == AppointmentStatus.pending).toList();
        _confirmed = appts.where((a) => a.status == AppointmentStatus.confirmed).toList();
        _completed = appts.where((a) => a.status == AppointmentStatus.completed).toList();
        _cancelled = appts.where((a) =>
            a.status == AppointmentStatus.cancelled ||
            a.status == AppointmentStatus.noShow).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'My Appointments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0072FF),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF0072FF),
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Pending (${_pending.length})'),
            Tab(text: 'Confirmed (${_confirmed.length})'),
            Tab(text: 'Completed (${_completed.length})'),
            Tab(text: 'Cancelled (${_cancelled.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0072FF)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: const Color(0xFF0072FF),
                  onRefresh: _load,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_pending,   emptyLabel: 'No pending appointments'),
                      _buildList(_confirmed, emptyLabel: 'No confirmed appointments'),
                      _buildList(_completed, emptyLabel: 'No completed appointments'),
                      _buildList(_cancelled, emptyLabel: 'No cancelled appointments'),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text(
              'Could not load appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0072FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<AppointmentModel> items, {required String emptyLabel}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 14),
            Text(
              emptyLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) => _AppointmentCard(appointment: items[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Appointment Card
// ─────────────────────────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final statusColor = Color(a.status.colorValue);
    final modeIcon = _modeIcon(a.mode);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: doctor info + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE0F2FE),
                  backgroundImage: a.doctorPhotoUrl.isNotEmpty
                      ? NetworkImage(a.doctorPhotoUrl)
                      : null,
                  child: a.doctorPhotoUrl.isEmpty
                      ? const Icon(Icons.person, color: Color(0xFF0284C7), size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.doctorName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (a.specialty.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          a.specialty,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    a.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 20, color: Color(0xFFF1F5F9)),

            // Date / Time / Mode row
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 5),
                Text(
                  '${a.formattedDate} • ${a.formattedTime}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(modeIcon, size: 14, color: const Color(0xFF0072FF)),
                const SizedBox(width: 4),
                Text(
                  _modeLabel(a.mode),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0072FF), fontWeight: FontWeight.w600),
                ),
              ],
            ),

            // Reason for visit
            if (a.reasonForVisit != null && a.reasonForVisit!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notes_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        a.reasonForVisit!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Fee
            if (a.fee > 0) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.payments_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    'NRs ${a.fee.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _modeIcon(String mode) {
    switch (mode) {
      case 'audio':     return Icons.phone_rounded;
      case 'chat':      return Icons.chat_bubble_rounded;
      case 'in_person': return Icons.local_hospital_rounded;
      default:          return Icons.videocam_rounded;
    }
  }

  static String _modeLabel(String mode) {
    switch (mode) {
      case 'audio':     return 'Audio';
      case 'chat':      return 'Chat';
      case 'in_person': return 'In-Person';
      default:          return 'Video';
    }
  }
}
