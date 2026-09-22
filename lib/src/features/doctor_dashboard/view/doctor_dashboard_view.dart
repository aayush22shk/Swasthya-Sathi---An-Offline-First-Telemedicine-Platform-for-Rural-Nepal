import 'package:flutter/material.dart';
import '../../../common_widgets/navigation_bar/doctor_nav_bar.dart';
import '../../../services/auth_service.dart';
import '../../patient_dashboard/view/patient_dashboard_view.dart';
import '../models/doctor_dashboard_models.dart';
import '../services/doctor_dashboard_service.dart';

class DoctorDashboardView extends StatefulWidget {
  final int initialTabIndex;

  const DoctorDashboardView({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<DoctorDashboardView> createState() => _DoctorDashboardViewState();
}

class _DoctorDashboardViewState extends State<DoctorDashboardView> {
  final DoctorDashboardService _service = DoctorDashboardService();
  late int _selectedBottomNavIndex;

  // Tab 1 (Appointments) internal filter: 0: Today, 1: Upcoming, 2: Requests, 3: Completed
  int _appointmentFilterIndex = 0;

  // Tab 2 (Patients) internal sub-tab: 0: Chats, 1: Prescriptions & EHR, 2: Directory & Follow-ups
  int _patientSubTabIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedBottomNavIndex = widget.initialTabIndex;
    _service.addListener(_onServiceChanged);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: _buildTopAppBar(context),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedBottomNavIndex,
          children: [
            // 0: HOME
            _buildHomeTab(),

            // 1: APPOINTMENTS (Unified Consultations & Appointments)
            _buildAppointmentsTab(),

            // 2: PATIENTS (Main tab featuring Chats, Prescriptions & Medical Records, Directory)
            _buildPatientsTab(),

            // 3: PROFILE (Availability and Settings under Profile)
            _buildProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: DoctorBottomNavBar(
        currentIndex: _selectedBottomNavIndex,
        onTap: (index) {
          setState(() {
            _selectedBottomNavIndex = index;
          });
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOP APP BAR: TITLE, STATUS DOT & NOTIFICATIONS AT TOP (NOT AT NAVBAR)
  // ───────────────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildTopAppBar(BuildContext context) {
    final unreadNotifs = _service.unreadNotificationsCount;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Swasthya Sathi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _service.isAvailable
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _service.isAvailable ? 'Doctor Online • Ready' : 'Doctor Offline',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _service.isAvailable
                          ? const Color(0xFF059669)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Role toggle for developer/user preview
        IconButton(
          tooltip: 'Switch to Patient Portal',
          icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF475569)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const PatientDashboardView(),
              ),
            );
          },
        ),

        // NOTIFICATION AT THE TOP
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF1E293B),
                size: 26,
              ),
              onPressed: _showNotificationsBottomSheet,
            ),
            if (unreadNotifs > 0)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadNotifs > 9 ? '9+' : '$unreadNotifs',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ===========================================================================
  // TAB 0: HOME
  // ===========================================================================
  Widget _buildHomeTab() {
    final stats = _service.stats;

    return RefreshIndicator(
      color: const Color(0xFF0072FF),
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Welcome Header
            _buildDoctorHomeHeader(),

            const SizedBox(height: 14.0),

            // Availability Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildAvailabilityBanner(),
            ),

            const SizedBox(height: 18.0),

            // Metric KPI Stats Cards
            _buildStatsCardsRow(stats),

            const SizedBox(height: 20.0),

            // Quick Actions Hub
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildQuickActionsSection(),
            ),

            const SizedBox(height: 20.0),

            // Today's Urgent Consultation Queue
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildTodaySection(isHomeSnippet: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorHomeHeader() {
    final user = AuthService().currentUser;
    final doctorName = user?.fullName ?? 'Dr. Bikash Sharma';
    final nmcNumber = 'NMC-21849';
    final isOnline = _service.isAvailable;

    final initials = doctorName.trim().isNotEmpty
        ? doctorName
            .trim()
            .split(' ')
            .where((w) => !w.toLowerCase().startsWith('dr'))
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'BS';

    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 18.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.0),
          bottomRight: Radius.circular(24.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Doctor Avatar
          Stack(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0072FF).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials.isNotEmpty ? initials : 'MD',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFF10B981)
                        : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        doctorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF0072FF),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Internal & Emergency Medicine • $nmcNumber',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Jump to Profile button
          IconButton(
            tooltip: 'View Profile & Settings',
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF475569)),
            onPressed: () {
              setState(() => _selectedBottomNavIndex = 3);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBanner() {
    final isOnline = _service.isAvailable;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF86EFAC).withValues(alpha: 0.6)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline
                  ? Icons.wifi_calling_3_rounded
                  : Icons.do_not_disturb_on_rounded,
              color: isOnline ? const Color(0xFF15803D) : const Color(0xFFB45309),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline
                      ? 'Online • Accepting Patients'
                      : 'Offline • Currently Away',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isOnline
                        ? const Color(0xFF166534)
                        : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline
                      ? 'Telemedicine channels active for rural health posts.'
                      : 'Toggle active status in Profile to receive urgent calls.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOnline
                        ? const Color(0xFF15803D).withValues(alpha: 0.85)
                        : const Color(0xFFB45309).withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _selectedBottomNavIndex = 3);
            },
            child: const Text(
              'Change',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Doctor Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionItem(
                icon: Icons.calendar_month_rounded,
                title: 'Appointments',
                color: const Color(0xFF0072FF),
                onTap: () {
                  setState(() => _selectedBottomNavIndex = 1);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionItem(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Patient Chats',
                color: const Color(0xFF10B981),
                onTap: () {
                  setState(() {
                    _selectedBottomNavIndex = 2;
                    _patientSubTabIndex = 0; // Chats
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionItem(
                icon: Icons.receipt_long_rounded,
                title: 'Prescriptions',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  setState(() {
                    _selectedBottomNavIndex = 2;
                    _patientSubTabIndex = 1; // Prescriptions
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCardsRow(DoctorDashboardStats stats) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          _buildStatCard(
            title: "Today's",
            count: stats.todayAppointments,
            subtitle: 'Visits',
            icon: Icons.calendar_today_rounded,
            color: const Color(0xFF0072FF),
            onTap: () {
              setState(() {
                _selectedBottomNavIndex = 1;
                _appointmentFilterIndex = 0;
              });
            },
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            title: 'Requests',
            count: stats.pendingRequests,
            subtitle: 'To Review',
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () {
              setState(() {
                _selectedBottomNavIndex = 1;
                _appointmentFilterIndex = 2;
              });
            },
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            title: 'Chats',
            count: _service.chatThreads.where((t) => t.unreadCount > 0).length,
            subtitle: 'Unread',
            icon: Icons.chat_rounded,
            color: const Color(0xFF10B981),
            onTap: () {
              setState(() {
                _selectedBottomNavIndex = 2;
                _patientSubTabIndex = 0;
              });
            },
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            title: 'Follow-ups',
            count: stats.followUpRequired,
            subtitle: 'Active',
            icon: Icons.alarm_on_rounded,
            color: const Color(0xFFEF4444),
            onTap: () {
              setState(() {
                _selectedBottomNavIndex = 2;
                _patientSubTabIndex = 2;
              });
            },
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            title: 'Completed',
            count: stats.completedConsultations,
            subtitle: 'Consults',
            icon: Icons.task_alt_rounded,
            color: const Color(0xFF6366F1),
            onTap: () {
              setState(() {
                _selectedBottomNavIndex = 1;
                _appointmentFilterIndex = 3;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 116,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: APPOINTMENTS (Unified Consultations & Appointments)
  // ===========================================================================
  Widget _buildAppointmentsTab() {
    final stats = _service.stats;

    final tabs = [
      {'label': "Today's", 'count': stats.todayAppointments},
      {'label': 'Upcoming', 'count': stats.upcomingAppointments},
      {'label': 'Requests', 'count': stats.pendingRequests},
      {'label': 'Completed', 'count': stats.completedConsultations},
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointments & Consultations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Unified patient visit scheduling and consultation management',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Search Bar
          _buildSearchBar(),
          const SizedBox(height: 16),

          // Segmented Switcher for Today, Upcoming, Requests, Completed
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(tabs.length, (index) {
                final isSelected = _appointmentFilterIndex == index;
                final item = tabs[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item['label'] as String),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${item['count']}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFF0072FF)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0072FF),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    elevation: isSelected ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF0072FF)
                            : Colors.grey.shade200,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _appointmentFilterIndex = index);
                      }
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // List content
          if (_appointmentFilterIndex == 0) _buildTodaySection(isHomeSnippet: false),
          if (_appointmentFilterIndex == 1) _buildUpcomingSection(),
          if (_appointmentFilterIndex == 2) _buildPendingRequestsSection(),
          if (_appointmentFilterIndex == 3) _buildCompletedSection(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: PATIENTS (Main tab featuring Chats, Prescriptions & Records, Directory)
  // ===========================================================================
  Widget _buildPatientsTab() {
    final chatThreads = _service.chatThreads;
    final prescriptions = _service.prescriptions;
    final followUps = _service.followUpPatients;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Patients Hub',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Patient chats, prescriptions, and clinical records',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              if (_patientSubTabIndex == 1)
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('New Rx', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0072FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _showNewPrescriptionModal,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Three Sub-Features Segmented Control: [Chats, Prescriptions & EHR, Directory]
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildSubTabButton(
                  index: 0,
                  label: 'Chats',
                  badge: chatThreads.where((t) => t.unreadCount > 0).length,
                ),
                _buildSubTabButton(
                  index: 1,
                  label: 'Prescriptions & EHR',
                  badge: prescriptions.length,
                ),
                _buildSubTabButton(
                  index: 2,
                  label: 'Follow-ups',
                  badge: followUps.where((f) => !f.isFollowedUp).length,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Feature Content
          if (_patientSubTabIndex == 0) _buildPatientChatsList(chatThreads),
          if (_patientSubTabIndex == 1) _buildPrescriptionsList(prescriptions),
          if (_patientSubTabIndex == 2) _buildFollowUpSection(),
        ],
      ),
    );
  }

  Widget _buildSubTabButton({
    required int index,
    required String label,
    int? badge,
  }) {
    final isSelected = _patientSubTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _patientSubTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF0072FF)
                      : const Color(0xFF64748B),
                ),
              ),
              if (badge != null && badge > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0072FF)
                        : const Color(0xFF94A3B8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Patients Feature 1: CHATS ──
  Widget _buildPatientChatsList(List<PatientChatThread> threads) {
    if (threads.isEmpty) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No Patient Chats',
        description: 'You have no active message threads with patients.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: threads.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final thread = threads[i];

        return InkWell(
          onTap: () => _openChatModal(thread),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: thread.unreadCount > 0
                    ? const Color(0xFF93C5FD)
                    : Colors.grey.shade200,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: thread.avatarUrl != null
                          ? NetworkImage(thread.avatarUrl!)
                          : null,
                      backgroundColor: const Color(0xFFE0EDFF),
                      child: thread.avatarUrl == null
                          ? Text(
                              thread.patientName[0],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0072FF),
                              ),
                            )
                          : null,
                    ),
                    if (thread.isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            thread.patientName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: thread.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            thread.lastMessageTime,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${thread.patientAge} yrs • ${thread.patientLocation}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thread.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: thread.unreadCount > 0
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF64748B),
                          fontWeight: thread.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (thread.unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0072FF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${thread.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Patients Feature 2: PRESCRIPTIONS & MEDICAL RECORDS ──
  Widget _buildPrescriptionsList(List<PrescriptionRecord> list) {
    if (list.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'No Prescriptions Yet',
        description: 'Issued digital prescriptions and EHR files will appear here.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final rx = list[i];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.medication_rounded,
                          color: Color(0xFF4F46E5),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rx.patientName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Rx #${rx.id} • ${rx.date}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.print_outlined, size: 20),
                    tooltip: 'Print / Download Prescription PDF',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Prescription PDF downloaded for ${rx.patientName}.'),
                          backgroundColor: const Color(0xFF0072FF),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diagnosis:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Text(
                      rx.diagnosis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Prescribed Medicines:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              ...rx.medicines.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Color(0xFF0072FF))),
                        Expanded(
                          child: Text(
                            '${m.medicineName} (${m.dosage}) - ${m.duration} [${m.instructions}]',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (rx.nextFollowUp != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event_available_rounded,
                        size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      'Follow-up due: ${rx.nextFollowUp}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 3: PROFILE (Availability and Settings under Profile)
  // ===========================================================================
  Widget _buildProfileTab() {
    final user = AuthService().currentUser;
    final doctorName = user?.fullName ?? 'Dr. Bikash Sharma';
    final isOnline = _service.isAvailable;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doctor Profile & Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage availability schedule, consultation fees, and account',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Doctor Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF0072FF),
                  child: const Text(
                    'BS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'NMC-21849 • Verified Doctor',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Internal & Emergency Telemedicine',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── AVAILABILITY SECTION (UNDER PROFILE) ──
          const Text(
            'Availability & Telehealth Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Active / Inactive Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isOnline
                                ? Icons.check_circle_rounded
                                : Icons.pause_circle_outline_rounded,
                            color: isOnline
                                ? const Color(0xFF10B981)
                                : const Color(0xFF64748B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOnline ? 'Online & Available' : 'Offline / Away',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              isOnline
                                  ? 'Accepting incoming patient visits'
                                  : 'Calls will be paused',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: isOnline,
                      activeThumbColor: const Color(0xFF10B981),
                      activeTrackColor: const Color(0xFFA7F3D0),
                      inactiveThumbColor: const Color(0xFF64748B),
                      inactiveTrackColor: const Color(0xFFE2E8F0),
                      onChanged: (val) async {
                        await _service.setAvailability(val);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val
                                  ? 'You are now Active (Online).'
                                  : 'You are now Inactive (Offline).'),
                              backgroundColor: val
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF475569),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Telemedicine Working Hours
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 18, color: Color(0xFF64748B)),
                        SizedBox(width: 10),
                        Text(
                          'Working Hours',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '08:00 AM - 06:00 PM',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0072FF),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Auto-accept Urgent Triage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emergency_rounded,
                            size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 10),
                        Text(
                          'Urgent Triage On-Call',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Enabled',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── DOCTOR SETTINGS SECTION (UNDER PROFILE) ──
          const Text(
            'Doctor Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.payments_outlined,
                  title: 'Consultation Fee Rates',
                  subtitle: 'Video: NRs 1,000 • Audio: NRs 800',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  icon: Icons.network_cell_rounded,
                  title: 'Low-Bandwidth 2G/3G Mode',
                  subtitle: 'Optimized for remote rural health posts',
                  trailing: const Text(
                    'Active',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  icon: Icons.translate_rounded,
                  title: 'Language / भाषा',
                  subtitle: 'Nepali & English (नेपाली र अंग्रेजी)',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  icon: Icons.security_rounded,
                  title: 'Security & NMC Credentials',
                  subtitle: 'License renewal & digital signature',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Switch / Logout Actions
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Switch to Patient Dashboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0072FF),
                side: const BorderSide(color: Color(0xFF0072FF)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PatientDashboardView(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
              label: const Text(
                'Log Out from Doctor Portal',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
              onPressed: () async {
                await AuthService().logout();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF334155), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8), size: 20),
      onTap: onTap,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SHARED LIST COMPONENTS: TODAY, UPCOMING, PENDING, COMPLETED, FOLLOW-UP
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTodaySection({required bool isHomeSnippet}) {
    final list = _service.todayAppointments.where((a) {
      if (_searchQuery.isEmpty) return true;
      return a.patientName.toLowerCase().contains(_searchQuery) ||
          a.chiefComplaint.toLowerCase().contains(_searchQuery) ||
          (a.patientLocation ?? '').toLowerCase().contains(_searchQuery);
    }).toList();

    if (list.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available_rounded,
        title: 'No Appointments Today',
        description: 'You have no scheduled appointments for today.',
      );
    }

    final displayList = isHomeSnippet ? list.take(2).toList() : list;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHomeSnippet ? "Today's Patient Queue" : "Today's Consultations",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  isHomeSnippet
                      ? 'Immediate teleconsultations & triage'
                      : 'Scheduled appointments for today',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            if (isHomeSnippet && list.length > 2)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedBottomNavIndex = 1;
                    _appointmentFilterIndex = 0;
                  });
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, i) => _buildTodayAppointmentCard(displayList[i]),
        ),
      ],
    );
  }

  Widget _buildTodayAppointmentCard(DoctorAppointment apt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: apt.urgency == UrgencyLevel.urgent
              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE0EDFF),
                backgroundImage:
                    apt.avatarUrl != null ? NetworkImage(apt.avatarUrl!) : null,
                child: apt.avatarUrl == null
                    ? Text(
                        apt.patientName.isNotEmpty ? apt.patientName[0] : 'P',
                        style: const TextStyle(
                          color: Color(0xFF0072FF),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apt.patientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${apt.patientAge} yrs • ${apt.patientGender} • ${apt.patientLocation ?? "Health Post"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: apt.urgency.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  apt.urgency.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: apt.urgency.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chief Complaint / Symptoms:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  apt.chiefComplaint,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: Color(0xFF475569)),
                    const SizedBox(width: 4),
                    Text(
                      apt.time,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: apt.type.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(apt.type.icon, size: 13, color: apt.type.color),
                    const SizedBox(width: 4),
                    Text(
                      apt.type.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: apt.type.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                apt.consultationFee,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  icon: Icon(
                    apt.type == AppointmentType.video
                        ? Icons.videocam_rounded
                        : Icons.phone_rounded,
                    size: 18,
                  ),
                  label: Text(
                    apt.type == AppointmentType.video
                        ? 'Start Video Call'
                        : 'Start Audio Call',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0072FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _simulateStartConsultation(apt),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Patient Records',
                icon: const Icon(Icons.folder_shared_outlined,
                    color: Color(0xFF475569)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showPatientFileModal(apt),
              ),
              IconButton(
                tooltip: 'Conclude & Issue Rx',
                icon: const Icon(Icons.check_circle_outline_rounded,
                    color: Color(0xFF10B981)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFECFDF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showCompleteConsultationDialog(apt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSection() {
    final list = _service.upcomingAppointments;
    if (list.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No Upcoming Appointments',
        description: 'Your schedule is clear for the coming days.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final apt = list[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_note_rounded,
                        color: Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          apt.patientName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${apt.patientAge} yrs • ${apt.patientLocation ?? "Clinic"}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      apt.date,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                apt.chiefComplaint,
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestsSection() {
    final list = _service.pendingRequests;
    if (list.isEmpty) {
      return _buildEmptyState(
        icon: Icons.checklist_rounded,
        title: 'No Pending Requests',
        description: 'All patient consultation requests have been addressed.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final req = list[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: req.urgency == UrgencyLevel.urgent
                  ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                  : const Color(0xFFFDE68A),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: req.urgency == UrgencyLevel.urgent
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      req.urgency == UrgencyLevel.urgent
                          ? Icons.emergency_rounded
                          : Icons.pending_actions_rounded,
                      color: req.urgency == UrgencyLevel.urgent
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFD97706),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${req.patientAge} yrs • ${req.patientLocation ?? "Nepal"}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: req.urgency.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      req.urgency.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: req.urgency.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                req.chiefComplaint,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _service.declinePendingRequest(req.id),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Accept Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _service.acceptPendingRequest(req.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Accepted! Moved to Today\'s schedule.'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                        setState(() => _appointmentFilterIndex = 0);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedSection() {
    final list = _service.completedConsultations;
    if (list.isEmpty) {
      return _buildEmptyState(
        icon: Icons.task_alt_rounded,
        title: 'No Completed Consultations',
        description: 'Completed consultations will appear here.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final apt = list[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    apt.patientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    apt.consultationFee,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${apt.date} • ${apt.time} (${apt.duration ?? "20 min"})',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              if (apt.diagnosis != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Diagnosis: ${apt.diagnosis!}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFollowUpSection() {
    final list = _service.followUpPatients;
    if (list.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_turned_in_rounded,
        title: 'No Follow-ups Due',
        description: 'All patient reviews are currently up to date.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final patient = list[i];
        final isDone = patient.isFollowedUp;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFFF8FAFC) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDone
                  ? Colors.grey.shade200
                  : patient.priority.color.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    patient.patientName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDone
                          ? const Color(0xFF64748B)
                          : const Color(0xFF0F172A),
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFFE2E8F0)
                          : patient.priority.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isDone ? 'Concluded' : patient.priority.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDone
                            ? const Color(0xFF64748B)
                            : patient.priority.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Condition: ${patient.primaryCondition}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Due: ${patient.followUpDueDate}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: patient.daysRemaining < 0
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF047857),
                ),
              ),
              if (!isDone) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.call_rounded, size: 14),
                    label: const Text('Initiate Review Call',
                        style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      _service.completeFollowUp(patient.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Follow-up call started with ${patient.patientName}.'),
                          backgroundColor: const Color(0xFF0072FF),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MODALS: CHAT, NEW PRESCRIPTION, NOTIFICATIONS, CALL SIMULATION
  // ───────────────────────────────────────────────────────────────────────────
  void _openChatModal(PatientChatThread thread) {
    _service.markChatThreadRead(thread.id);
    final msgCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF0072FF),
                          child: Text(
                            thread.patientName[0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                thread.patientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${thread.patientAge} yrs • ${thread.patientLocation}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Messages list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: thread.messages.length,
                      itemBuilder: (context, i) {
                        final m = thread.messages[i];
                        final isMe = m.isDoctor;

                        return Align(
                          alignment:
                              isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFF0072FF)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.text,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isMe ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  m.time,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isMe
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Chat Input Bar
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: msgCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Type clinical advice or response...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: Color(0xFF0072FF)),
                          onPressed: () {
                            final text = msgCtrl.text.trim();
                            if (text.isNotEmpty) {
                              _service.sendChatMessage(thread.id, text);
                              msgCtrl.clear();
                              setModalState(() {});
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNewPrescriptionModal() {
    final nameCtrl = TextEditingController(text: 'Ram Bahadur Thapa');
    final diagCtrl = TextEditingController(text: 'Chronic bronchitis follow-up');
    final medCtrl = TextEditingController(text: 'Salbutamol Inhaler 2 puffs BD x 14d');
    final adviceCtrl = TextEditingController(text: 'Boil drinking water, avoid smoke exposure');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Issue Digital Prescription (EHR)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Patient Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diagCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Clinical Diagnosis',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: medCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Medicines & Dosage',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adviceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Clinical Advice',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0072FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _service.addPrescription(
                        PrescriptionRecord(
                          id: 'rx_${DateTime.now().millisecondsSinceEpoch}',
                          patientId: 'p_${DateTime.now().millisecondsSinceEpoch}',
                          patientName: nameCtrl.text,
                          date: 'Today',
                          diagnosis: diagCtrl.text,
                          clinicalAdvice: adviceCtrl.text,
                          nextFollowUp: 'In 14 days',
                          medicines: [
                            PrescriptionItem(
                              medicineName: medCtrl.text,
                              dosage: 'As prescribed',
                              duration: '14 Days',
                              instructions: 'Follow strictly',
                            ),
                          ],
                        ),
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Prescription issued & added to patient EHR!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                      setState(() => _patientSubTabIndex = 1);
                    },
                    child: const Text('Save & Issue Prescription'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final notifs = _service.notifications;

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notifications & Alerts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _service.markAllNotificationsAsRead();
                            setModalState(() {});
                            setState(() {});
                          },
                          child: const Text('Mark all read'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: notifs.isEmpty
                        ? const Center(child: Text('No notifications right now.'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: notifs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final n = notifs[i];
                              return InkWell(
                                onTap: () {
                                  _service.markNotificationAsRead(n.id);
                                  setModalState(() {});
                                  setState(() {});
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: n.isRead
                                        ? const Color(0xFFF8FAFC)
                                        : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: n.isRead
                                          ? Colors.grey.shade200
                                          : const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: n.category.color.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          n.category.icon,
                                          size: 18,
                                          color: n.category.color,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    n.title,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: n.isRead
                                                          ? FontWeight.w600
                                                          : FontWeight.bold,
                                                      color: const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  n.timeAgo,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              n.message,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF334155),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _simulateStartConsultation(DoctorAppointment apt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: apt.type.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(apt.type.icon, color: apt.type.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Launch ${apt.type.label}',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Connecting secure telemedicine channel to:'),
            const SizedBox(height: 8),
            Text(
              apt.patientName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${apt.patientLocation ?? "Health Post"} • ${apt.patientPhone}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0072FF),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Connected with ${apt.patientName}! Call session live.'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Connect Call Now'),
          ),
        ],
      ),
    );
  }

  void _showPatientFileModal(DoctorAppointment apt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              apt.patientName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'ID: ${apt.patientId} • Phone: ${apt.patientPhone}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const Divider(),
            const Text(
              'Presenting Symptoms',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(apt.chiefComplaint),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteConsultationDialog(DoctorAppointment apt) {
    final diagCtrl = TextEditingController(text: 'Clinical assessment verified.');
    final rxCtrl = TextEditingController(text: 'Rx: Oral rehydration & rest.');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Consultation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: diagCtrl,
              decoration: const InputDecoration(labelText: 'Diagnosis'),
            ),
            TextField(
              controller: rxCtrl,
              decoration: const InputDecoration(labelText: 'Prescription'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              _service.markConsultationCompleted(
                apt.id,
                diagnosis: diagCtrl.text,
                prescription: rxCtrl.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Consultation with ${apt.patientName} concluded.'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
              setState(() {
                _selectedBottomNavIndex = 1;
                _appointmentFilterIndex = 3;
              });
            },
            child: const Text('Save & Conclude', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search patient, symptoms, or location...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon:
              const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
