import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../models/patient_profile_model.dart';

class EditProfileDialog extends StatefulWidget {
  final PatientProfileModel profile;

  const EditProfileDialog({
    super.key,
    required this.profile,
  });

  static Future<PatientProfileModel?> show(BuildContext context, PatientProfileModel profile) {
    return showModalBottomSheet<PatientProfileModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProfileDialog(profile: profile),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;

  String? _selectedGender;
  String? _selectedBloodGroup;
  DateTime? _selectedDob;
  bool _isLoading = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _genders = ['male', 'female', 'other'];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.fullName);
    _phoneController = TextEditingController(text: p.phone);
    _emailController = TextEditingController(text: p.email ?? '');
    _addressController = TextEditingController(text: p.addressLine ?? '');
    _emergencyNameController = TextEditingController(text: p.emergencyContactName ?? '');
    _emergencyPhoneController = TextEditingController(text: p.emergencyContactPhone ?? '');

    _selectedGender = p.gender;
    _selectedBloodGroup = p.bloodGroup;
    if (p.dob != null && p.dob!.isNotEmpty) {
      try {
        _selectedDob = DateTime.parse(p.dob!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
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
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dobStr = _selectedDob != null
          ? "${_selectedDob!.year.toString().padLeft(4, '0')}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}"
          : null;

      final updateData = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        'gender': _selectedGender,
        'blood_group': _selectedBloodGroup,
        'dob': dobStr,
        'address_line': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        'emergency_contact_name': _emergencyNameController.text.trim().isNotEmpty
            ? _emergencyNameController.text.trim()
            : null,
        'emergency_contact_phone': _emergencyPhoneController.text.trim().isNotEmpty
            ? _emergencyPhoneController.text.trim()
            : null,
      };

      final updatedProfile = await _profileService.updatePatientProfile(
        patientId: widget.profile.id,
        data: updateData,
      );

      // Update session credentials
      await _authService.updateUserSession(
        fullName: updatedProfile.fullName,
        phone: updatedProfile.phone,
        email: updatedProfile.email,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pop(context, updatedProfile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Profile updated successfully in database!'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(e.toString())),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Sheet Handle & Header
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Patient Profile',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            // Scrollable Form Fields
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Full Name *'),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Enter full name', Icons.person_outline),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Full name is required' : null,
                    ),

                    const SizedBox(height: 16),
                    _buildFieldLabel('Mobile Number *'),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('98XXXXXXXX', Icons.phone_outlined),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Phone number is required' : null,
                    ),

                    const SizedBox(height: 16),
                    _buildFieldLabel('Email Address'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('name@example.com', Icons.email_outlined),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Gender
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Gender'),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedGender,
                                decoration: _inputDecoration('Select', null),
                                items: _genders
                                    .map((g) => DropdownMenuItem(
                                          value: g,
                                          child: Text(g[0].toUpperCase() + g.substring(1)),
                                        ))
                                    .toList(),
                                onChanged: (val) => setState(() => _selectedGender = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Blood Group
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Blood Group'),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedBloodGroup,
                                decoration: _inputDecoration('Select', null),
                                items: _bloodGroups
                                    .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                                    .toList(),
                                onChanged: (val) => setState(() => _selectedBloodGroup = val),
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    _buildFieldLabel('Date of Birth'),
                    InkWell(
                      onTap: _pickDob,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDob != null
                                  ? "${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}"
                                  : 'Select Date of Birth',
                              style: TextStyle(
                                fontSize: 14.5,
                                color: _selectedDob != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                              ),
                            ),
                            const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildFieldLabel('Address / Location'),
                    TextFormField(
                      controller: _addressController,
                      decoration: _inputDecoration('e.g. Kathmandu, Sindhupalchok, Nepal', Icons.location_on_outlined),
                    ),

                    const SizedBox(height: 16),
                    _buildFieldLabel('Emergency Contact Name'),
                    TextFormField(
                      controller: _emergencyNameController,
                      decoration: _inputDecoration('Guardian / relative name', Icons.contact_phone_outlined),
                    ),

                    const SizedBox(height: 16),
                    _buildFieldLabel('Emergency Contact Phone'),
                    TextFormField(
                      controller: _emergencyPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Emergency phone number', Icons.phone_forwarded_outlined),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0072FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF64748B), size: 20) : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0072FF), width: 1.5),
      ),
    );
  }
}
