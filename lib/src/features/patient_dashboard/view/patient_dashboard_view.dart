import 'package:flutter/material.dart';
import '../../../common_widgets/carosel/horizonal_carosel.dart';
import '../../../common_widgets/doctors/doctor_horizontal_list.dart';
import '../../../common_widgets/doctors/doctor_model.dart';
import '../../../common_widgets/navigation_bar/nav_bar.dart';
import '../../../common_widgets/urgent_care/urgent_care_banner.dart';
import '../../../models/appointment_model.dart';
import '../../../models/specialization_model.dart';
import '../../../services/appointment_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/doctor_service.dart';
import '../../../services/masters_service.dart';
import '../../../services/profile_service.dart';
import '../../appointments/view/book_appointment_screen.dart';
import '../../consultation/view/chat_screen.dart';
import '../../consultation/view/consultation_view.dart';
import '../../doctor_profile/view/doctor_detail_screen.dart';
import '../../patient_profile/view/view_profile_screen.dart';
import '../../urgent_care/urgentCare.dart';

class PatientDashboardView extends StatefulWidget {
  const PatientDashboardView({super.key});

  @override
  State<PatientDashboardView> createState() => _PatientDashboardViewState();
}

class _PatientDashboardViewState extends State<PatientDashboardView> {
  int _selectedTabIndex = 0;

  // Dynamic Dashboard Data State
  List<DoctorModel> _allDoctors = [];
  List<DoctorModel> _filteredDoctors = [];
  List<SpecializationModel> _specializations = [];
  AppointmentModel? _upcomingAppointment;

  bool isLoadingDashboard = true;
  String _searchQuery = '';
  SpecializationModel? _selectedSpec;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoadingDashboard = true);

    try {
      final futures = await Future.wait([
        DoctorService().getDoctors(),
        MastersService().getSpecializations(),
        AppointmentService().getUpcomingAppointment(),
      ]);

      if (mounted) {
        setState(() {
          _allDoctors = futures[0] as List<DoctorModel>;
          _specializations = futures[1] as List<SpecializationModel>;
          _upcomingAppointment = futures[2] as AppointmentModel?;
          _applyFilters();
          isLoadingDashboard = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allDoctors = DoctorModel.sampleDoctors;
          _applyFilters();
          isLoadingDashboard = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<DoctorModel> list = List.from(_allDoctors);

    // Apply specialization filter
    if (_selectedSpec != null) {
      list = list.where((doc) {
        return doc.specialty.toLowerCase().contains(_selectedSpec!.name.toLowerCase()) ||
            doc.specializations.any((s) => s.toLowerCase().contains(_selectedSpec!.name.toLowerCase()));
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((doc) {
        return doc.name.toLowerCase().contains(q) ||
            doc.specialty.toLowerCase().contains(q) ||
            doc.location.toLowerCase().contains(q);
      }).toList();
    }

    _filteredDoctors = list;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _toggleSpecialization(SpecializationModel spec) {
    setState(() {
      if (_selectedSpec?.id == spec.id) {
        _selectedSpec = null;
      } else {
        _selectedSpec = spec;
      }
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTabIndex,
          children: [
            // Home / Main Patient Dashboard Content
            _buildDashboardHome(context),

            // Services & Specialties Tab
            _buildSpecialtiesTab(),

            // Consultations Tab
            const ConsultationView(),

            // Health Records Tab
            _buildTabPlaceholder('Offline Medical Records', Icons.folder_shared_outlined),

            // Patient Profile Tab
            ViewProfileScreen(
              onBackToHome: () {
                setState(() => _selectedTabIndex = 0);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildDashboardHome(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: const Color(0xFF0072FF),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. APP HEADER
            _buildAppHeader(),

            const SizedBox(height: 16.0),

            // 2. SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildSearchBar(),
            ),

            const SizedBox(height: 16.0),

            // URGENT CARE BANNER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: UrgentCareBanner(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UrgentCareScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20.0),

            // 3. ANNOUNCEMENT & HEALTH CAROUSEL
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured & Updates',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0072FF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
            const HorizontalCarouselWidget(),

            const SizedBox(height: 24.0),

            // 4. QUICK HEALTHCARE ACTIONS / SPECIALTIES GRID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quick Healthcare Actions',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (_selectedSpec != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSpec = null;
                              _applyFilters();
                            });
                          },
                          child: const Text(
                            'Clear Filter',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14.0),
                  _buildQuickActionsGrid(),
                ],
              ),
            ),

            const SizedBox(height: 24.0),

            // 5. AVAILABLE DOCTORS HORIZONTAL LIST
            DoctorHorizontalList(
              title: _selectedSpec != null
                  ? '${_selectedSpec!.name} Specialists (${_filteredDoctors.length})'
                  : 'Available Specialists (${_filteredDoctors.length})',
              doctors: _filteredDoctors,
              onViewAll: () {
                setState(() => _selectedTabIndex = 1);
              },
            ),

            const SizedBox(height: 24.0),

            // 6. UPCOMING CONSULTATION CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildUpcomingAppointmentCard(),
            ),

            const SizedBox(height: 24.0),

            // 7. OFFLINE SYNC STATUS CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildOfflineStatusCard(),
            ),

            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }

  // APP HEADER DESIGN
  Widget _buildAppHeader() {
    final user = AuthService().currentUser;
    final profile = ProfileService().currentProfile;
    final fullName = user?.fullName ?? profile?.fullName ?? 'Aayush';
    final firstName = fullName.split(' ').first;
    final initials = fullName.trim().isNotEmpty
        ? fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'AS';

    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.0),
          bottomRight: Radius.circular(24.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // User Greeting & Avatar
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 4; // Jump to profile tab
                      });
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0072FF).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initials.isNotEmpty ? initials : 'AS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Namaste, $firstName 🙏',
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13.0,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 3.0),
                          Text(
                            profile?.addressLine ?? profile?.location ?? 'Sindhupalchok, Nepal',
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Notification Button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded,
                          color: Color(0xFF334155)),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SEARCH BAR
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search doctors, specialties, location...',
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14.0,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0072FF)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : Container(
                  margin: const EdgeInsets.all(8.0),
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0072FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF0072FF),
                    size: 18.0,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
      ),
    );
  }

  // DYNAMIC QUICK ACTIONS GRID
  Widget _buildQuickActionsGrid() {
    final defaultSpecs = [
      {'name': 'General Physician', 'icon': Icons.health_and_safety_outlined, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
      {'name': 'Cardiology', 'icon': Icons.monitor_heart_rounded, 'color': const Color(0xFF0072FF), 'bg': const Color(0xFFEFF6FF)},
      {'name': 'Obstetrics & Gynecology', 'icon': Icons.pregnant_woman_rounded, 'color': const Color(0xFFEC4899), 'bg': const Color(0xFFFDF2F8)},
      {'name': 'Pediatrics', 'icon': Icons.child_care_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'name': 'Psychiatry', 'icon': Icons.psychology_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF)},
      {'name': 'Dermatology', 'icon': Icons.healing_rounded, 'color': const Color(0xFF06B6D4), 'bg': const Color(0xFFECFEFF)},
    ];

    final displayList = _specializations.isNotEmpty
        ? _specializations.take(6).toList()
        : defaultSpecs.map((s) => SpecializationModel(id: defaultSpecs.indexOf(s) + 1, name: s['name'] as String)).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.95,
      ),
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final spec = displayList[index];
        final isSelected = _selectedSpec?.id == spec.id;
        final style = defaultSpecs[index % defaultSpecs.length];

        return InkWell(
          onTap: () => _toggleSpecialization(spec),
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0072FF) : Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isSelected ? const Color(0xFF0072FF) : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF0072FF).withValues(alpha: 0.2)
                      : const Color(0x08000000),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(9.0),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.2) : style['bg'] as Color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    style['icon'] as IconData,
                    color: isSelected ? Colors.white : style['color'] as Color,
                    size: 22.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  spec.name,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // DYNAMIC UPCOMING APPOINTMENT HERO CARD
  Widget _buildUpcomingAppointmentCard() {
    final appt = _upcomingAppointment;

    if (appt == null) {
      // Empty state / Promo card to book consultation
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.video_camera_front_outlined, color: Color(0xFF0072FF), size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Doctor Advice?',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Book video or audio consult with specialists.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_allDoctors.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookAppointmentScreen(doctor: _allDoctors.first),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0072FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                elevation: 0,
              ),
              child: const Text('Book Now', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
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
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0072FF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  const Text(
                    'Upcoming Tele-Consultation',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${appt.formattedDate} • ${appt.formattedTime}',
                  style: const TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20.0, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: appt.doctorPhotoUrl.isNotEmpty ? NetworkImage(appt.doctorPhotoUrl) : null,
                backgroundColor: const Color(0xFFE0F2FE),
                child: appt.doctorPhotoUrl.isEmpty
                    ? const Icon(Icons.person, color: Color(0xFF0284C7))
                    : null,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt.doctorName,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '${appt.specialty.isNotEmpty ? appt.specialty : "Specialist"} • ${appt.mode.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        doctorName: appt.doctorName,
                        specialty: appt.specialty,
                        avatarUrl: appt.doctorPhotoUrl,
                        consultationId: appt.consultationId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0072FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Join Call',
                  style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // OFFLINE SYNC STATUS CARD
  Widget _buildOfflineStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFF38EF7D),
              size: 22,
            ),
          ),
          const SizedBox(width: 12.0),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Sync Mode Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                  ),
                ),
                SizedBox(height: 2.0),
                Text(
                  'Records stored locally. Will auto-sync when online.',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            decoration: BoxDecoration(
              color: const Color(0xFF38EF7D).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: const Color(0xFF38EF7D), width: 0.8),
            ),
            child: const Text(
              'Synced',
              style: TextStyle(
                color: Color(0xFF38EF7D),
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SERVICES & SPECIALTIES TAB
  Widget _buildSpecialtiesTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('All Specialists', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allDoctors.length,
        itemBuilder: (context, index) {
          final doc = _allDoctors[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(doc.avatarUrl),
                onBackgroundImageError: (e, s) {},
              ),
              title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.specialty, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(doc.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 10),
                      Text(doc.consultationFee, style: const TextStyle(color: Color(0xFF0072FF), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doc)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0072FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Consult', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      ),
    );
  }

  // TAB PLACEHOLDER FOR OTHER PAGES
  Widget _buildTabPlaceholder(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFF0072FF)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Swasthya Sathi Telemedicine Platform',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
