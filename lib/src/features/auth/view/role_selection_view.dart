import 'package:flutter/material.dart';
import '../models/user_role.dart';
import 'widgets/role_card.dart';
import 'widgets/auth_text_field.dart';
import 'register_patient_view.dart';
import 'register_doctor_view.dart';
import 'login_view.dart';

class RoleSelectionView extends StatefulWidget {
  const RoleSelectionView({super.key});

  @override
  State<RoleSelectionView> createState() => _RoleSelectionViewState();
}

class _RoleSelectionViewState extends State<RoleSelectionView> {
  UserRole _selectedRole = UserRole.patient;

  void _onNext() {
    if (_selectedRole == UserRole.patient) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RegisterPatientView(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterDoctorView(
            isSpecialist: _selectedRole == UserRole.healthSpecialist,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              // Big bold title like the reference image
              const Text(
                'Register',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3748),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose your role to create your customized account.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              // Expanded list of role cards
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    RoleCard(
                      role: UserRole.patient,
                      isSelected: _selectedRole == UserRole.patient,
                      onTap: () {
                        setState(() => _selectedRole = UserRole.patient);
                      },
                    ),
                    RoleCard(
                      role: UserRole.doctor,
                      isSelected: _selectedRole == UserRole.doctor,
                      onTap: () {
                        setState(() => _selectedRole = UserRole.doctor);
                      },
                    ),
                    RoleCard(
                      role: UserRole.healthSpecialist,
                      isSelected: _selectedRole == UserRole.healthSpecialist,
                      onTap: () {
                        setState(() => _selectedRole = UserRole.healthSpecialist);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Orange Next Button
              AuthPrimaryButton(
                label: 'Next',
                onPressed: _onNext,
              ),

              const SizedBox(height: 18),

              // Bottom footer: "Already have an account? Login"
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginView()),
                        );
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
