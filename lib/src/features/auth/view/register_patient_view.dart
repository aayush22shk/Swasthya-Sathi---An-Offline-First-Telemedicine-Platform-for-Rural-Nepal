import 'package:flutter/material.dart';
import '../models/patient_register_model.dart';
import 'widgets/auth_text_field.dart';
import '../../patient_dashboard/view/patient_dashboard_view.dart';
import 'login_view.dart';

class RegisterPatientView extends StatefulWidget {
  const RegisterPatientView({super.key});

  @override
  State<RegisterPatientView> createState() => _RegisterPatientViewState();
}

class _RegisterPatientViewState extends State<RegisterPatientView> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController(text: 'Aayush');
  final _lastNameController = TextEditingController(text: 'Shakya');
  final _mobileController = TextEditingController(text: '9749869506');
  final _emailController = TextEditingController(text: 'aayush.shakya04@gmail.com');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _countryCode = '+977';
  String _howDidYouHear = 'Prefer not to say';
  String? _selectedReference;
  bool _agreedToTerms = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> _hearOptions = [
    'Prefer not to say',
    'Friends or Family',
    'Social Media (Facebook / Instagram)',
    'Community Health Post / FCHV',
    'Hospital or Clinic Banner',
    'Internet Search / Google',
  ];

  final List<String> _referenceOptions = [
    'None',
    'FCHV (Female Community Health Volunteer)',
    'Local Rural Health Post',
    'Attending Doctor Code',
    'Red Cross Nepal Health Camp',
  ];

  bool get _isMobileValid => _mobileController.text.trim().length >= 10;
  bool get _isEmailValid {
    final email = _emailController.text.trim();
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isLoading = false);

    // Create the patient registration object
    final patientModel = PatientRegisterModel(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      countryCode: _countryCode,
      mobileNumber: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      howDidYouHear: _howDidYouHear,
      reference: _selectedReference,
      password: _passwordController.text.isNotEmpty
          ? _passwordController.text
          : 'demo_password',
      agreedToTerms: _agreedToTerms,
    );

    _showRegistrationSuccessDialog(patientModel);
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
              'Welcome, ${model.fullName}! Your patient account is verified and ready for tele-consultations.',
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
                  const SizedBox(height: 6),
                  _detailRow('Email:', model.email),
                  const SizedBox(height: 6),
                  _detailRow('Role:', 'Patient (Swasthya Sathi)'),
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
              // First Name
              AuthTextField(
                label: 'First Name',
                hint: 'e.g. Aayush',
                controller: _firstNameController,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'First name is required' : null,
              ),
              const SizedBox(height: 18),

              // Last Name
              AuthTextField(
                label: 'Last Name',
                hint: 'e.g. Shakya',
                controller: _lastNameController,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Last name is required' : null,
              ),
              const SizedBox(height: 18),

              // Mobile Number with +977 prefix and checkmark
              PhoneInputField(
                label: 'Mobile Number',
                controller: _mobileController,
                countryCode: _countryCode,
                onCountryCodeTap: _showCountryCodePicker,
                isValid: _isMobileValid,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),

              // Email with checkmark
              AuthTextField(
                label: 'Email',
                hint: 'name@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                showValidation: true,
                isValid: _isEmailValid,
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!_isEmailValid) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // How did you hear about us?
              AuthDropdownField<String>(
                label: 'How did you hear about us?',
                value: _howDidYouHear,
                hint: 'Select option',
                items: _hearOptions
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
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _howDidYouHear = val);
                  }
                },
              ),
              const SizedBox(height: 18),

              // Reference (If applicable) with Info tooltip
              AuthDropdownField<String>(
                label: 'Reference',
                labelTrailing: Tooltip(
                  message: 'Provide referral if suggested by a health worker or post.',
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                  ),
                ),
                value: _selectedReference,
                hint: 'Select reference (optional)',
                items: _referenceOptions
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
                onChanged: (val) {
                  setState(() => _selectedReference = val);
                },
              ),
              const SizedBox(height: 18),

              // Password
              AuthTextField(
                label: 'Password',
                hint: 'Create a secure password',
                controller: _passwordController,
                obscureText: _obscurePassword,
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
                                  'Swasthya Sathi Telemedicine Terms & Privacy Policy (Nepal Medical Standards)',
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

              const SizedBox(height: 30),

              // Next Button (Orange / Amber gradient)
              AuthPrimaryButton(
                label: 'Next',
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
