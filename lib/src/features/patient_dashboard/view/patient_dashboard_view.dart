import 'package:flutter/material.dart';
import '../../../common_widgets/carosel/horizonal_carosel.dart';
import '../../../common_widgets/doctors/doctor_horizontal_list.dart';
import '../../../common_widgets/navigation_bar/nav_bar.dart';
import '../../../common_widgets/urgent_care/urgent_care_banner.dart';
import '../../../services/auth_service.dart';
import '../../urgent_care/urgentCare.dart';
import '../../consultation/view/consultation_view.dart';
import '../../patient_profile/view/view_profile_screen.dart';

class PatientDashboardView extends StatefulWidget {
  const PatientDashboardView({super.key});

  @override
  State<PatientDashboardView> createState() => _PatientDashboardViewState();
}

class _PatientDashboardViewState extends State<PatientDashboardView> {
  int _selectedTabIndex = 0;

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

            // Services Tab Placeholder
            _buildTabPlaceholder('Services & Specialties', Icons.medical_services_outlined),

            // Consultations Tab
            const ConsultationView(),

            // Health Records Tab Placeholder
            _buildTabPlaceholder('Offline Medical Records', Icons.folder_shared_outlined),

            // Patient Profile Tab (Connected to ViewProfileScreen)
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------
          // 1. APP HEADER
          // -------------------------------------------------------------
          _buildAppHeader(),

          const SizedBox(height: 16.0),

          // -------------------------------------------------------------
          // 2. SEARCH BAR
          // -------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildSearchBar(),
          ),

          const SizedBox(height: 16.0),

          // -------------------------------------------------------------
          // URGENT CARE BANNER
          // -------------------------------------------------------------
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

          // -------------------------------------------------------------
          // 3. ANNOUNCEMENT & HEALTH CAROUSEL
          // -------------------------------------------------------------
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

          // -------------------------------------------------------------
          // AVAILABLE DOCTORS HORIZONTAL LIST
          // -------------------------------------------------------------
          const DoctorHorizontalList(title: 'Obstetrics & Gynecology'),

          const SizedBox(height: 24.0),

          // -------------------------------------------------------------
          // 4. QUICK ACTION CATEGORIES GRID
          // -------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Healthcare Actions',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 14.0),
                _buildQuickActionsGrid(),
              ],
            ),
          ),

          const SizedBox(height: 24.0),

          // -------------------------------------------------------------
          // 5. UPCOMING CONSULTATION CARD
          // -------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildUpcomingAppointmentCard(),
          ),

          const SizedBox(height: 24.0),

          // -------------------------------------------------------------
          // 6. OFFLINE SYNC STATUS CARD
          // -------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildOfflineStatusCard(),
          ),

          const SizedBox(height: 30.0),
        ],
      ),
    );
  }

  // APP HEADER DESIGN
  Widget _buildAppHeader() {
    final user = AuthService().currentUser;
    final fullName = user?.fullName ?? 'Aayush';
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
                      Row(
                        children: [
                          Text(
                            'Namaste, $firstName 🙏',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2.0),
                      const Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 13.0,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(width: 3.0),
                          Text(
                            'Sindhupalchok, Nepal',
                            style: TextStyle(
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

              // Action Buttons: Notification & Emergency
              Row(

                children: [
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
        decoration: InputDecoration(
          hintText: 'Search doctors, medicines, symptoms...',
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14.0,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0072FF)),
          suffixIcon: Container(
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
      ),
    );
  }

  // QUICK ACTIONS GRID
  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        'title': 'Cardiology',
        //'subtitle': 'Doctor Video/Audio',
        'icon': Icons.monitor_heart_rounded,
        'color': const Color(0xFF0072FF),
        'bg': const Color(0xFFEFF6FF),
      },
      {
        'title': 'General Physician',
       // 'subtitle': 'Offline Records',
        'icon': Icons.health_and_safety_outlined,
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFECFDF5),
      },
      {
        'title': 'Clinical Psychology',
        //'subtitle': 'Meds & Dosage',
        'icon': Icons.medication_rounded,
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
      },
      {
        'title': 'Psychiatry',
       // 'subtitle': 'AI Assistance',
        'icon': Icons.health_and_safety_rounded,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
      },
      {
        'title': 'Gastroenterology',
       // 'subtitle': 'Ambulance Helpline',
        'icon': Icons.emergency_rounded,
        'color': const Color(0xFFEF4444),
        'bg': const Color(0xFFFEF2F2),
      },
      {
        'title': 'Licensed Dietician',
        //'subtitle': 'BP, Pulse, Temp',
        'icon': Icons.monitor_heart_rounded,
        'color': const Color(0xFF06B6D4),
        'bg': const Color(0xFFECFEFF),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.9,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        return InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: item['bg'] as Color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 24.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item['subtitle'] != null) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    item['subtitle'] as String,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // UPCOMING APPOINTMENT CARD
  Widget _buildUpcomingAppointmentCard() {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
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
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFE0F2FE),
                child: Icon(Icons.person, color: Color(0xFF0284C7)),
              ),
              const SizedBox(width: 12.0),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. Bikash Sharma',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2.0),
                    Text(
                      'General Physician • Kathmandu Med',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0072FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14.0, vertical: 8.0),
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
