// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../../common_widgets/doctors/doctor_horizontal_list.dart';

class UrgentCareScreen extends StatelessWidget {
  const UrgentCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Urgent Care Network',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 19.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: const Color(0xFF10B981), width: 1.0),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '24 Online',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Intro Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFFF59E0B),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Choose Tele-Consultation Network',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  const Text(
                    'Use Urgent Care for immediate response. The first available doctor on duty will accept your consultation.',
                    style: TextStyle(
                      fontSize: 13.0,
                      color: Color(0xFF94A3B8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24.0),

            const Text(
              'Available Care Networks',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 16.0),

            // CARD 1: GENERAL URGENT CARE (< 3 MINS)
            _buildModernNetworkCard(
              context: context,
              timeBadgeText: '⚡ Response within 3 min',
              badgeColor: const Color(0xFFFEF3C7),
              badgeTextColor: const Color(0xFFB45309),
              title: 'General Urgent Care',
              subtitle:
                  'Instant guidance for acute symptoms, fever, pain, or general emergency health advice.',
              buttonText: 'GENERAL CONSULTATION',
              gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
              icon: Icons.medical_services_rounded,
              onTap: () {
                _showConsultationDialog(
                    context, 'General Urgent Care (Within 3 min)');
              },
            ),

            const SizedBox(height: 20.0),

            // CARD 2: WELLNESS SUPPORT (< 10 MINS)
            _buildModernNetworkCard(
              context: context,
              timeBadgeText: '🌱 Response within 10 min',
              badgeColor: const Color(0xFFECFDF5),
              badgeTextColor: const Color(0xFF047857),
              title: 'Wellness & Primary Care',
              subtitle:
                  'Consultation for mental wellness, lifestyle guidance, nutrition & preventive advice.',
              buttonText: 'WELLNESS CONSULTATION',
              gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
              icon: Icons.spa_rounded,
              onTap: () {
                _showConsultationDialog(
                    context, 'Wellness Support (Within 10 min)');
              },
            ),

            const SizedBox(height: 20.0),

            // CARD 3: SPECIALIST DIRECT ACCESS (< 10 MINS)
            _buildModernNetworkCard(
              context: context,
              timeBadgeText: '🩺 Response within 10 min',
              badgeColor: const Color(0xFFEFF6FF),
              badgeTextColor: const Color(0xFF1D4ED8),
              title: 'Direct Specialist Network',
              subtitle:
                  'Choose from available Cardiologists, Dermatologists, Pediatricians & Gynecologists.',
              buttonText: 'CHOOSE SPECIALTY',
              gradientColors: const [Color(0xFF0072FF), Color(0xFF0052D4)],
              icon: Icons.assignment_ind_rounded,
              onTap: () {
                _showConsultationDialog(
                    context, 'Specialist Network (Within 10 min)');
              },
            ),

            const SizedBox(height: 24.0),

            // ON-DUTY DOCTORS HORIZONTAL LIST
            const DoctorHorizontalList(title: 'Featured On-Duty Doctors'),

            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }

  // MODERN NETWORK CARD BUILDER
  Widget _buildModernNetworkCard({
    required BuildContext context,
    required String timeBadgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required List<Color> gradientColors,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Time Badge & Icon Avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Time Response Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 5.0),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Text(
                        timeBadgeText,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor,
                        ),
                      ),
                    ),

                    // Modern Glowing Gradient Icon Badge
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors.first.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14.0),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 6.0),

                // Subtitle
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Action Button Banner across card bottom
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(23.0),
                bottomRight: Radius.circular(23.0),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(23.0),
                    bottomRight: Radius.circular(23.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConsultationDialog(BuildContext context, String networkName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            const Text('Connect Urgent Care'),
          ],
        ),
        content: Text(
          'Requesting consultation for "$networkName". An available doctor will connect with you immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Connect Now'),
          ),
        ],
      ),
    );
  }
}
