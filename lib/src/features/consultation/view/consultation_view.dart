import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

enum ConsultationStatus { ongoing, scheduled, closed }

class ConsultationModel {
  final String id;
  final String doctorName;
  final String specialty;
  final String avatarUrl;
  final String date;
  final String time;
  final ConsultationStatus status;
  final String? duration;
  final String? notes;
  final String consultationFee;
  final double feeAmount;

  const ConsultationModel({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.avatarUrl,
    required this.date,
    required this.time,
    required this.status,
    this.duration,
    this.notes,
    this.consultationFee = 'NRs 1,200',
    this.feeAmount = 1200,
  });
}

// ---------------------------------------------------------------------------
// SAMPLE DATA
// ---------------------------------------------------------------------------

const _sampleOngoing = [
  ConsultationModel(
    id: 'c1',
    doctorName: 'Dr. Bikash Sharma',
    specialty: 'Emergency & Internal Medicine',
    avatarUrl:
        'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=200&q=80',
    date: 'Today',
    time: '10:30 AM',
    status: ConsultationStatus.ongoing,
    duration: '12 min',
    consultationFee: 'NRs 1,200',
    feeAmount: 1200,
  ),
];

const _sampleScheduled = [
  ConsultationModel(
    id: 'c2',
    doctorName: 'Dr. Anjali Shrestha',
    specialty: 'Obstetrics & Gynecology',
    avatarUrl:
        'https://images.unsplash.com/photo-1594824813566-78a9c2794025?w=200&q=80',
    date: 'Sep 20, 2026',
    time: '2:00 PM',
    status: ConsultationStatus.scheduled,
    consultationFee: 'NRs 1,500',
    feeAmount: 1500,
  ),
  ConsultationModel(
    id: 'c3',
    doctorName: 'Dr. Ismail Aboul Foutouh',
    specialty: 'Obstetrics & Gynecology',
    avatarUrl:
        'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=200&q=80',
    date: 'Sep 23, 2026',
    time: '11:00 AM',
    status: ConsultationStatus.scheduled,
    consultationFee: 'NRs 2,400',
    feeAmount: 2400,
  ),
  ConsultationModel(
    id: 'c4',
    doctorName: 'Dr. Gael Abou Ghannam',
    specialty: 'Cardiology',
    avatarUrl:
        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=200&q=80',
    date: 'Sep 25, 2026',
    time: '4:30 PM',
    status: ConsultationStatus.scheduled,
    consultationFee: 'NRs 2,800',
    feeAmount: 2800,
  ),
];

const _sampleClosed = [
  ConsultationModel(
    id: 'c5',
    doctorName: 'Dr. Bikash Sharma',
    specialty: 'Emergency & Internal Medicine',
    avatarUrl:
        'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=200&q=80',
    date: 'Sep 10, 2026',
    time: '9:00 AM',
    status: ConsultationStatus.closed,
    notes: 'Prescribed rest & Paracetamol. Follow-up in 2 weeks.',
  ),
  ConsultationModel(
    id: 'c6',
    doctorName: 'Dr. Anjali Shrestha',
    specialty: 'Obstetrics & Gynecology',
    avatarUrl:
        'https://images.unsplash.com/photo-1594824813566-78a9c2794025?w=200&q=80',
    date: 'Aug 28, 2026',
    time: '3:00 PM',
    status: ConsultationStatus.closed,
    notes: 'Antenatal check complete. Vitamins prescribed.',
  ),
];

// ---------------------------------------------------------------------------
// MAIN VIEW
// ---------------------------------------------------------------------------

class ConsultationView extends StatefulWidget {
  const ConsultationView({super.key});

  @override
  State<ConsultationView> createState() => _ConsultationViewState();
}

class _ConsultationViewState extends State<ConsultationView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Start on Scheduled (index 1) matching the reference image
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OngoingTab(consultations: _sampleOngoing),
                  _ScheduledTab(consultations: _sampleScheduled),
                  _ClosedTab(consultations: _sampleClosed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Consultations',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0072FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              onPressed: () {},
              tooltip: 'New Consultation',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        labelColor: const Color(0xFF0F172A),
        unselectedLabelColor: const Color(0xFF94A3B8),
        indicatorColor: const Color(0xFF00C6A2),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(text: 'Ongoing'),
          Tab(text: 'Scheduled'),
          Tab(text: 'Closed'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ONGOING TAB
// ---------------------------------------------------------------------------

class _OngoingTab extends StatelessWidget {
  final List<ConsultationModel> consultations;
  const _OngoingTab({required this.consultations});

  @override
  Widget build(BuildContext context) {
    if (consultations.isEmpty) {
      return const _EmptyState(
        icon: Icons.video_call_outlined,
        title: 'No Ongoing Consultations',
        subtitle: 'You have no active consultations right now.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: consultations.length,
      itemBuilder: (ctx, i) => _OngoingCard(model: consultations[i]),
    );
  }
}

class _OngoingCard extends StatelessWidget {
  final ConsultationModel model;
  const _OngoingCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF0072FF).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0072FF).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Live banner
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF0072FF), Color(0xFF00C6FF)]),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                _PulseDot(),
                const SizedBox(width: 8),
                const Text('Live Session',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const Spacer(),
                const Icon(Icons.timer_outlined,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(model.duration ?? '0 min',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _DoctorAvatar(url: model.avatarUrl),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(model.doctorName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A))),
                          const SizedBox(height: 3),
                          Text(model.specialty,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'End Call',
                        icon: Icons.call_end_rounded,
                        backgroundColor: const Color(0xFFFEF2F2),
                        textColor: const Color(0xFFEF4444),
                        iconColor: const Color(0xFFEF4444),
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: 'Rejoin',
                        icon: Icons.video_call_rounded,
                        backgroundColor: const Color(0xFF0072FF),
                        textColor: Colors.white,
                        iconColor: Colors.white,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCHEDULED TAB
// ---------------------------------------------------------------------------

class _ScheduledTab extends StatelessWidget {
  final List<ConsultationModel> consultations;
  const _ScheduledTab({required this.consultations});

  @override
  Widget build(BuildContext context) {
    if (consultations.isEmpty) {
      return const _EmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'No Scheduled Consultations',
        subtitle: 'Book a new consultation with a specialist.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: consultations.length,
      itemBuilder: (ctx, i) => _ScheduledCard(model: consultations[i]),
    );
  }
}

class _ScheduledCard extends StatelessWidget {
  final ConsultationModel model;
  const _ScheduledCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x09000000),
              blurRadius: 12,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DoctorAvatar(url: model.avatarUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(model.doctorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 3),
                    Text(model.specialty,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: Color(0xFF0072FF)),
                        const SizedBox(width: 4),
                        Text(model.date,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155))),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: Color(0xFF0072FF)),
                        const SizedBox(width: 4),
                        Text(model.time,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF0072FF)
                          .withValues(alpha: 0.3)),
                ),
                child: const Text('Upcoming',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0072FF))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Reschedule',
                  icon: Icons.edit_calendar_outlined,
                  backgroundColor: const Color(0xFFF1F5F9),
                  textColor: const Color(0xFF334155),
                  iconColor: const Color(0xFF64748B),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Join Call',
                  icon: Icons.video_call_rounded,
                  backgroundColor: const Color(0xFF0072FF),
                  textColor: Colors.white,
                  iconColor: Colors.white,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CLOSED TAB
// ---------------------------------------------------------------------------

class _ClosedTab extends StatelessWidget {
  final List<ConsultationModel> consultations;
  const _ClosedTab({required this.consultations});

  @override
  Widget build(BuildContext context) {
    if (consultations.isEmpty) {
      return const _EmptyState(
        icon: Icons.history_rounded,
        title: 'No Past Consultations',
        subtitle: 'Your completed consultations will appear here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: consultations.length,
      itemBuilder: (ctx, i) => _ClosedCard(model: consultations[i]),
    );
  }
}

class _ClosedCard extends StatelessWidget {
  final ConsultationModel model;
  const _ClosedCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x09000000),
              blurRadius: 12,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _DoctorAvatar(url: model.avatarUrl, opacity: 0.65),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748B),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(model.doctorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 3),
                    Text(model.specialty,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text('${model.date}  \u2022  ${model.time}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Closed',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B))),
              ),
            ],
          ),
          if (model.notes != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(model.notes!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _ActionButton(
            label: 'Book Follow-up',
            icon: Icons.replay_rounded,
            backgroundColor: const Color(0xFFEFF6FF),
            textColor: const Color(0xFF0072FF),
            iconColor: const Color(0xFF0072FF),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SHARED SMALL WIDGETS
// ---------------------------------------------------------------------------

class _DoctorAvatar extends StatelessWidget {
  final String url;
  final double opacity;
  const _DoctorAvatar({required this.url, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person,
                color: Color(0xFF0072FF), size: 28),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
          ],
        ),
      ),
    );
  }
}

/// Animated pulsing red dot for the live session banner
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: const Color(0xFFFF4444),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4444).withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF), shape: BoxShape.circle),
              child:
                  Icon(icon, size: 48, color: const Color(0xFF0072FF)),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF64748B)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
