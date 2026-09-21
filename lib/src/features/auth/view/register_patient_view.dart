import 'package:flutter/material.dart';
import '../models/patient_register_model.dart';
import 'widgets/auth_text_field.dart';
import '../../patient_dashboard/view/patient_dashboard_view.dart';
import 'login_view.dart';
import '../../../services/auth_service.dart';

class RegisterPatientView extends StatefulWidget {
  const RegisterPatientView({super.key});

  @override
  State<RegisterPatientView> createState() => _RegisterPatientViewState();
}

class _RegisterPatientViewState extends State<RegisterPatientView> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();

  String _countryCode = '+977';
  String? _selectedGender;
  String? _selectedBloodGroup;
  DateTime? _selectedDob;
  bool _agreedToTerms = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<Map<String, String>> _genderOptions = [
    {'label': 'Male', 'value': 'male'},
    {'label': 'Female', 'value': 'female'},
    {'label': 'Other', 'value': 'other'},
  ];

  final List<String> _bloodGroupOptions = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

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
    _mobileController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(now.year - 25, now.month, now.day);
    final firstDate = DateTime(1900);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0072FF),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
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
          content: Text('Please agree to the Terms & Conditions to proceed.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final patientModel = PatientRegisterModel(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      countryCode: _countryCode,
      mobileNumber: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      gender: _selectedGender,
      dob: _selectedDob,
      bloodGroup: _selectedBloodGroup,
      password: _passwordController.text,
      agreedToTerms: _agreedToTerms,
    );

    try {
      // ── API call to DB ────────────────────────────────────────────────
      final payload = <String, dynamic>{
        'full_name': patientModel.fullName,
        'phone': patientModel.fullPhoneNumber,
        'password': patientModel.password,
      };

      if (patientModel.email.isNotEmpty) {
        payload['email'] = patientModel.email;
      }
      if (patientModel.gender != null) {
        payload['gender'] = patientModel.gender;
      }
      if (patientModel.formattedDob != null) {
        payload['dob'] = patientModel.formattedDob;
      }
      if (patientModel.bloodGroup != null) {
        payload['blood_group'] = patientModel.bloodGroup;
      }

      await AuthService().registerPatient(payload);
      // ──────────────────────────────────────────────────────────────────

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showRegistrationSuccessDialog(patientModel);
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

  void _showRegistrationSuccessDialog(PatientRegisterModel model) {
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
                color: Color(0xFFECFDF5),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Registration Successful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Welcome, ${model.fullName}! Your patient account is registered and ready for tele-consultations.',
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
                  _detailRow('Phone:', model.fullPhoneNumber),
                  if (model.email.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _detailRow('Email:', model.email),
                  ],
                  if (model.gender != null) ...[
                    const SizedBox(height: 6),
                    _detailRow('Gender:', model.gender!.toUpperCase()),
                  ],
                  if (model.formattedDob != null) ...[
                    const SizedBox(height: 6),
                    _detailRow('DOB:', model.formattedDob!),
                  ],
                  if (model.bloodGroup != null) ...[
                    const SizedBox(height: 6),
                    _detailRow('Blood Group:', model.bloodGroup!),
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
                  // Navigate to Patient Dashboard
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PatientDashboardView(),
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
                  'Go to Dashboard',
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Register as a Patient',
          style: TextStyle(
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
              // First Name & Last Name (full_name in DB)
              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      label: 'First Name',
                      hint: 'e.g. Aayush',
                      controller: _firstNameController,
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthTextField(
                      label: 'Last Name',
                      hint: 'e.g. Shakya',
                      controller: _lastNameController,
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Mobile Number with +977 prefix (phone in DB)
              PhoneInputField(
                label: 'Mobile Number',
                controller: _mobileController,
                countryCode: _countryCode,
                onCountryCodeTap: _showCountryCodePicker,
                isValid: _isMobileValid,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),

              // Email (optional in DB, validated if provided)
              AuthTextField(
                label: 'Email (Optional)',
                hint: 'name@example.com',
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

              // Date of Birth (dob DATE in DB)
              AuthTextField(
                label: 'Date of Birth (Optional)',
                hint: 'YYYY-MM-DD',
                controller: _dobController,
                readOnly: true,
                onTap: _pickDateOfBirth,
                suffix: IconButton(
                  icon: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF0072FF),
                    size: 20,
                  ),
                  onPressed: _pickDateOfBirth,
                ),
              ),
              const SizedBox(height: 18),

              // Gender & Blood Group (gender_type & blood_group in DB)
              Row(
                children: [
                  // Gender
                  Expanded(
                    child: AuthDropdownField<String>(
                      label: 'Gender',
                      value: _selectedGender,
                      hint: 'Select',
                      items: _genderOptions
                          .map(
                            (opt) => DropdownMenuItem(
                              value: opt['value'],
                              child: Text(
                                opt['label']!,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedGender = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Blood Group
                  Expanded(
                    child: AuthDropdownField<String>(
                      label: 'Blood Group',
                      value: _selectedBloodGroup,
                      hint: 'Select',
                      items: _bloodGroupOptions
                          .map(
                            (opt) => DropdownMenuItem(
                              value: opt,
                              child: Text(
                                opt,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedBloodGroup = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Password
              AuthTextField(
                label: 'Password',
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

              // Terms and Conditions checkbox
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
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'I have read and agree to the ',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF475569),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Swasthya Sathi Telemedicine Terms & Privacy Policy',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Next Button (Orange / Amber gradient)
              AuthPrimaryButton(
                label: 'Create Patient Account',
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
