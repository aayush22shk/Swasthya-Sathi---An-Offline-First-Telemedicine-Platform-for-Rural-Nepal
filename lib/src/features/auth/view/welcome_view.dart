import 'package:flutter/material.dart';
import 'login_view.dart';
import 'role_selection_view.dart';
import '../../patient_dashboard/view/patient_dashboard_view.dart';
import '../../doctor_dashboard/view/doctor_dashboard_view.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Language / Country indicator pill
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🇳🇵', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 6),
                      Text(
                        'Nepal • EN/NE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Emblem / Hero Graphic
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0072FF).withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.health_and_safety_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Title & Subtitle
              const Text(
                'Swasthya Sathi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'स्वास्थ्य साथी • An Offline-First Telemedicine Platform',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0072FF),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Connecting rural & urban Nepal with verified doctors, direct digital consultations, and offline health records.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 32),

              // Feature cards
              _buildFeatureRow(
                icon: Icons.wifi_off_rounded,
                iconColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
                title: 'Offline-First Telehealth',
                description: 'Record symptoms & access data even with low or no internet.',
              ),
              const SizedBox(height: 12),
              _buildFeatureRow(
                icon: Icons.verified_user_rounded,
                iconColor: const Color(0xFF0072FF),
                bgColor: const Color(0xFFEFF6FF),
                title: 'Verified Doctors & NMC Specialists',
                description: 'Consult licensed medical practitioners across Nepal directly.',
              ),
              const SizedBox(height: 12),
              _buildFeatureRow(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
                title: 'Instant eSewa Consultations',
                description: 'Seamless digital payment integration for audio/video calls.',
              ),

              const SizedBox(height: 36),

              // Register CTA (Amber gradient button)
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA238), Color(0xFFF97316)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoleSelectionView(),
                        ),
                      );
                    },
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started / Register',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Login Button (Outlined / Bordered style)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginView()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'I already have an account • Login',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Guest / Direct Preview Options
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientDashboardView(),
                        ),
                      );
                    },
                    child: const Text(
                      'Patient Guest Tour',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text('  •  ', style: TextStyle(color: Color(0xFF94A3B8))),
                  TextButton.icon(
                    icon: const Icon(Icons.medical_services_outlined, size: 15, color: Color(0xFF0072FF)),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorDashboardView(),
                        ),
                      );
                    },
                    label: const Text(
                      'Doctor Portal',
                      style: TextStyle(
                        color: Color(0xFF0072FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
