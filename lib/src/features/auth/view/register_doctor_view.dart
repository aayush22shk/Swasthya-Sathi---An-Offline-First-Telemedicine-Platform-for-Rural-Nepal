import 'package:flutter/material.dart';
import '../models/doctor_register_model.dart';
import 'widgets/auth_text_field.dart';
import '../../doctor_dashboard/view/doctor_dashboard_view.dart';
import 'login_view.dart';
import '../../../services/auth_service.dart';

class RegisterDoctorView extends StatefulWidget {
  final bool isSpecialist;

  const RegisterDoctorView({
    super.key,
    this.isSpecialist = false,
  });

  @override
  State<RegisterDoctorView> createState() => _RegisterDoctorViewState();
}

class _RegisterDoctorViewState extends State<RegisterDoctorView> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nmcNumberController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _bioController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _countryCode = '+977';
  bool _agreedToTerms = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get _isMobileValid => _mobileController.text.trim().length >= 10;
  bool get _isEmailValid {
    final email = _emailController.text.trim();
    if (email.isEmpty) return true; // Optional in DB
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nmcNumberController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _bioController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select Country Code',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Text('🇳🇵', style: TextStyle(fontSize: 22)),
              title: const Text('Nepal (+977)'),
              trailing: _countryCode == '+977'
                  ? const Icon(Icons.check, color: Color(0xFF0072FF))
                  : null,
              onTap: () {
                setState(() => _countryCode = '+977');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🇮🇳', style: TextStyle(fontSize: 22)),
              title: const Text('India (+91)'),
              trailing: _countryCode == '+91'
                  ? const Icon(Icons.check, color: Color(0xFF0072FF))
                  : null,
              onTap: () {
                setState(() => _countryCode = '+91');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🌐', style: TextStyle(fontSize: 22)),
              title: const Text('Other (+1)'),
              onTap: () {
                setState(() => _countryCode = '+1');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to medical tele-practice guidelines.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final expYears = int.tryParse(_experienceController.text.trim()) ?? 0;
    final fee = double.tryParse(_feeController.text.trim()) ?? 0.0;
    final bioText = _bioController.text.trim();

    final doctorModel = DoctorRegisterModel(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      nmcNumber: _nmcNumberController.text.trim(),
      experienceYears: expYears,
      consultationFee: fee,
      bio: bioText.isNotEmpty ? bioText : null,
      countryCode: _countryCode,
      mobileNumber: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      agreedToTerms: _agreedToTerms,
    );

    try {
      // ── API call to DB ────────────────────────────────────────────────
      final payload = <String, dynamic>{
        'full_name': doctorModel.fullName,
        'nmc_registration_number': doctorModel.nmcNumber,
        'phone': doctorModel.fullPhoneNumber,
        'password': doctorModel.password,
        'experience_years': doctorModel.experienceYears,
        'consultation_fee': doctorModel.consultationFee,
      };

      if (doctorModel.email.isNotEmpty) {
        payload['email'] = doctorModel.email;
      }
      if (doctorModel.bio != null) {
        payload['bio'] = doctorModel.bio;
      }

      await AuthService().registerDoctor(payload);
      // ──────────────────────────────────────────────────────────────────

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showDoctorSuccessDialog(doctorModel);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(e.message)),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showDoctorSuccessDialog(DoctorRegisterModel model) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEFF6FF),
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Color(0xFF0072FF),
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Doctor Profile Registered!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Welcome, ${model.fullName}! Your NMC registration (${model.nmcNumber}) has been submitted for tele-verification.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _detailRow('NMC License:', model.nmcNumber),
                  const SizedBox(height: 6),
                  _detailRow('Contact:', model.fullPhoneNumber),
                  const SizedBox(height: 6),
                  _detailRow('Experience:', '${model.experienceYears} Years'),
                  const SizedBox(height: 6),
                  _detailRow('Consultation Fee:', 'NPR ${model.consultationFee.toStringAsFixed(0)}'),
                  if (model.email.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _detailRow('Email:', model.email),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DoctorDashboardView(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0072FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Enter Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSpecialist
        ? 'Register as Health Specialist'
        : 'Register as a Doctor';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            physics: const BouncingScrollPhysics(),
            children: [
              // Notice banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0072FF).withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.security_rounded,
                      color: Color(0xFF0072FF),
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nepal Medical Council (NMC) verification is required for practicing doctors.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // First Name & Last Name (full_name in DB)
              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      label: 'First Name',
                      hint: 'e.g. Ramesh',
                      controller: _firstNameController,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthTextField(
                      label: 'Last Name',
                      hint: 'e.g. Shrestha',
                      controller: _lastNameController,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // NMC Number (nmc_registration_number in DB)
              AuthTextField(
                label: 'NMC Registration Number',
                hint: 'e.g. 14820-NMC',
                controller: _nmcNumberController,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'NMC registration number is required'
                    : null,
              ),
              const SizedBox(height: 18),

              // Experience Years & Consultation Fee (experience_years & consultation_fee in DB)
              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      label: 'Experience (Years)',
                      hint: 'e.g. 5',
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                          return 'Enter whole number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthTextField(
                      label: 'Fee (NPR)',
                      hint: 'e.g. 500',
                      controller: _feeController,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
                          return 'Enter valid fee';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Bio / Clinical Summary (bio in DB)
              AuthTextField(
                label: 'Bio / Summary (Optional)',
                hint: 'e.g. Senior Physician at Bir Hospital with focus on Internal Medicine...',
                controller: _bioController,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 18),

              // Mobile Number (phone in DB)
              PhoneInputField(
                label: 'Mobile Number',
                controller: _mobileController,
                countryCode: _countryCode,
                onCountryCodeTap: _showCountryCodePicker,
                isValid: _isMobileValid,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),

              // Official Email (email in DB)
              AuthTextField(
                label: 'Email (Optional)',
                hint: 'doctor@hospital.org.np',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                showValidation: _emailController.text.trim().isNotEmpty,
                isValid: _isEmailValid,
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty && !_isEmailValid) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Password
              AuthTextField(
                label: 'Account Password',
                hint: 'At least 8 characters',
                controller: _passwordController,
                obscureText: _obscurePassword,
                validator: (val) {
                  if (val == null || val.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 18),

              // Agreement
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      activeColor: const Color(0xFF00A389),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onChanged: (val) {
                        setState(() => _agreedToTerms = val ?? false);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'I confirm that I am a licensed medical practitioner under Nepal Medical Council regulations.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Next Button (Amber gradient)
              AuthPrimaryButton(
                label: 'Register Doctor Account',
                isLoading: _isLoading,
                onPressed: _submitRegistration,
              ),

              const SizedBox(height: 18),

              // Bottom footer: Already have an account? Login
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Already registered? ',
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
