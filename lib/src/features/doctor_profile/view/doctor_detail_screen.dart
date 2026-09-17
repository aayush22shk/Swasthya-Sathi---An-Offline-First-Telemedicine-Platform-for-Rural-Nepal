import 'package:flutter/material.dart';
import '../../../common_widgets/doctors/doctor_model.dart';

class DoctorDetailScreen extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorDetailScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  bool _isLiked = false;
  bool _isVideoExpanded = true;

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100.0), // Padding for fixed bottom button
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HERO HEADER WITH DOCTOR PHOTO & TOP NAV BUTTONS
                _buildHeroHeader(context, doc),

                const SizedBox(height: 16.0),

                // 2. DOCTOR INFO CARD (Name, Location, Stars, Response Time, Fee)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _buildDoctorInfoCard(doc),
                ),

                const SizedBox(height: 20.0),

                // 3. VIDEO INTRODUCTION EXPANDABLE SECTION
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _buildVideoIntroSection(doc),
                ),

                const SizedBox(height: 16.0),

                // 4. EXPANDABLE ACCORDION SECTIONS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      _buildAccordionTile(
                        icon: Icons.work_outline_rounded,
                        title: 'Services / Procedures',
                        items: doc.services,
                        initiallyExpanded: true,
                      ),
                      const SizedBox(height: 10.0),
                      _buildAccordionTile(
                        icon: Icons.local_hospital_outlined,
                        title: 'Hospital Affiliations',
                        items: doc.hospitalAffiliations,
                      ),
                      const SizedBox(height: 10.0),
                      _buildAccordionTile(
                        icon: Icons.assignment_outlined,
                        title: 'Memberships',
                        items: doc.memberships,
                      ),
                      const SizedBox(height: 10.0),
                      _buildAccordionTile(
                        icon: Icons.school_outlined,
                        title: 'Education',
                        items: doc.education,
                      ),
                      const SizedBox(height: 10.0),
                      _buildAccordionTile(
                        icon: Icons.verified_outlined,
                        title: 'Certifications',
                        items: doc.certifications,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),
              ],
            ),
          ),

          // 5. FIXED BOTTOM START CONSULTATION BUTTON BAR
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFixedBottomBar(context, doc),
          ),
        ],
      ),
    );
  }

  // HERO TOP HEADER PHOTO WITH NAVIGATION BUTTONS
  Widget _buildHeroHeader(BuildContext context, DoctorModel doc) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            doc.avatarUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF1E293B),
              child: const Icon(Icons.person, size: 100, color: Colors.white70),
            ),
          ),

          // Dark Gradient Overlay at Top & Bottom
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Top Action Buttons (Back, Like, Share)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: Color(0xFF1E293B), size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Like & Share Buttons
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        radius: 20,
                        child: IconButton(
                          icon: Icon(
                            _isLiked
                                ? Icons.thumb_up_rounded
                                : Icons.thumb_up_outlined,
                            color: _isLiked ? const Color(0xFFF59E0B) : const Color(0xFF1E293B),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _isLiked = !_isLiked;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.share_outlined,
                              color: Color(0xFF1E293B), size: 20),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DOCTOR INFO CARD (Matches Image 2 reference layout)
  Widget _buildDoctorInfoCard(DoctorModel doc) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Name & Specialty Title
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: doc.name,
                  style: const TextStyle(
                    fontSize: 19.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextSpan(
                  text: '  |  ${doc.specialty}',
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4.0),

          // Location & Flag
          Text(
            'From ${doc.location} ${doc.flagEmoji}',
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 16.0),

          // Stats Rows: Recommendations, Response Time, Fee
          _buildInfoRow(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFF59E0B),
            text: '${doc.recommendationsCount} Recommendations (${doc.rating} ★)',
            textColor: const Color(0xFFD97706),
          ),
          const SizedBox(height: 10.0),
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFF0D9488),
            text: doc.responseTime,
            textColor: const Color(0xFF0D9488),
          ),
          const SizedBox(height: 10.0),
          _buildInfoRow(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFF0284C7),
            text: '${doc.consultationFee} per consultation',
            textColor: const Color(0xFF0284C7),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // VIDEO INTRODUCTION EXPANDABLE SECTION
  Widget _buildVideoIntroSection(DoctorModel doc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header Tile
          ListTile(
            onTap: () {
              setState(() {
                _isVideoExpanded = !_isVideoExpanded;
              });
            },
            leading: const Icon(Icons.play_circle_fill_rounded,
                color: Color(0xFF0072FF), size: 28),
            title: const Text(
              'Video Introduction',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            trailing: Icon(
              _isVideoExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF64748B),
            ),
          ),

          if (_isVideoExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        doc.avatarUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(color: Colors.black.withValues(alpha: 0.35)),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0072FF).withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ACCORDION TILE BUILDER
  Widget _buildAccordionTile({
    required IconData icon,
    required String title,
    required List<String> items,
    bool initiallyExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon, color: const Color(0xFF0072FF)),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0072FF))),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF475569),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED BOTTOM BUTTON BAR
  Widget _buildFixedBottomBar(BuildContext context, DoctorModel doc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: ElevatedButton(
        onPressed: () {
          _showBookingSuccessDialog(context, doc);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B), // Vibrant Amber Orange matching Image 2
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Start Consultation',
          style: TextStyle(
            fontSize: 17.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showBookingSuccessDialog(BuildContext context, DoctorModel doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.video_call_rounded, color: Color(0xFF0072FF)),
            SizedBox(width: 8),
            Text('Start Consultation'),
          ],
        ),
        content: Text(
          'Connecting live video call with ${doc.name} (${doc.specialty}). Fee: ${doc.consultationFee}.',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Join Room'),
          ),
        ],
      ),
    );
  }
}
