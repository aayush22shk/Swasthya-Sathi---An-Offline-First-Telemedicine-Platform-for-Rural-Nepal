import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../auth/view/login_view.dart';
import '../../auth/view/welcome_view.dart';
import '../models/patient_profile_model.dart';

class AccountSettingsScreen extends StatefulWidget {
  final PatientProfileModel? profile;

  const AccountSettingsScreen({
    super.key,
    this.profile,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _profileService = ProfileService();
  final _authService = AuthService();

  String _currentLanguage = 'नेपाली';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final lang = await _profileService.getAppLanguage();
    setState(() {
      if (lang == 'ne') {
        _currentLanguage = 'नेपाली';
      } else if (lang == 'ar') {
        _currentLanguage = 'عربي';
      } else {
        _currentLanguage = 'English';
      }
    });
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Language',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                _languageOption(code: 'ne', title: 'नेपाली (Nepali)', label: 'नेपाली'),
                _languageOption(code: 'en', title: 'English', label: 'English'),
                _languageOption(code: 'ar', title: 'العربية (Arabic)', label: 'عربي'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _languageOption({
    required String code,
    required String title,
    required String label,
  }) {
    final isSelected = _currentLanguage == label;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFFE58A1F) : const Color(0xFF1E293B),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFFE58A1F))
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () async {
        final profile = _profileService.currentProfile ?? widget.profile;
        await _profileService.saveAppLanguage(code);
        if (profile != null && profile.id.isNotEmpty && (code == 'ne' || code == 'en')) {
          try {
            await _profileService.updatePatientProfile(
              patientId: profile.id,
              data: {'preferred_language': code},
            );
          } catch (_) {}
        }
        setState(() => _currentLanguage = label);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  void _showEditPhoneSheet(String currentPhone, String patientId) {
    final controller = TextEditingController(text: currentPhone);
    final messenger = ScaffoldMessenger.of(context);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final navigator = Navigator.of(ctx);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Mobile Number',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      hintText: '98XXXXXXXX',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE58A1F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final newPhone = controller.text.trim();
                              if (newPhone.isEmpty) return;

                              setSheetState(() => isSaving = true);
                              try {
                                if (patientId.isNotEmpty) {
                                  await _profileService.updatePatientProfile(
                                    patientId: patientId,
                                    data: {'phone': newPhone},
                                  );
                                }
                                await _authService.updateUserSession(phone: newPhone);
                                navigator.pop();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Mobile number saved to database!'),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                                if (mounted) setState(() {});
                              } catch (e) {
                                setSheetState(() => isSaving = false);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Failed: $e'),
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Save Number',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditEmailSheet(String currentEmail, String patientId) {
    final controller = TextEditingController(text: currentEmail);
    final messenger = ScaffoldMessenger.of(context);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final navigator = Navigator.of(ctx);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Email Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'name@example.com',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE58A1F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final newEmail = controller.text.trim();
                              setSheetState(() => isSaving = true);
                              try {
                                if (patientId.isNotEmpty) {
                                  await _profileService.updatePatientProfile(
                                    patientId: patientId,
                                    data: {'email': newEmail.isNotEmpty ? newEmail : null},
                                  );
                                }
                                await _authService.updateUserSession(email: newEmail.isNotEmpty ? newEmail : null);
                                navigator.pop();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Email address saved to database!'),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                                if (mounted) setState(() {});
                              } catch (e) {
                                setSheetState(() => isSaving = false);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Failed: $e'),
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Save Email',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }



  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out from Swasthya Sathi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeView()),
        (route) => false,
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
        content: const Text(
          'This action will permanently deactivate your account and patient records. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() => _isLoading = true);
      try {
        final profile = _profileService.currentProfile ?? widget.profile;
        if (profile != null && profile.id.isNotEmpty) {
          await _profileService.deactivateAccount(profile.id);
        } else {
          await _authService.logout();
        }

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profileService.currentProfile ?? widget.profile;
    final phone = profile?.phone.isNotEmpty == true
        ? profile!.phone
        : (_authService.currentUser?.phone ?? '9779749869506');
    final email = profile?.email != null && profile!.email!.isNotEmpty
        ? profile.email!
        : (_authService.currentUser?.email ?? 'aayush.shakya04@gmail.com');
    final patientId = profile?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------------------
              // 1. CHANGE LANGUAGE CARD
              // -------------------------------------------------------------
              _buildSettingCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Change Language',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    InkWell(
                      onTap: _showLanguageSelector,
                      borderRadius: BorderRadius.circular(10.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: const Color(0xFFE58A1F), width: 1.5),
                        ),
                        child: Text(
                          _currentLanguage,
                          style: const TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE58A1F),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // -------------------------------------------------------------
              // 2. MOBILE NUMBER CARD
              // -------------------------------------------------------------
              _buildSettingCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mobile Number',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showEditPhoneSheet(phone, patientId),
                      borderRadius: BorderRadius.circular(10.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: const Color(0xFFE58A1F), width: 1.5),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE58A1F),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // -------------------------------------------------------------
              // 3. EMAIL CARD
              // -------------------------------------------------------------
              _buildSettingCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        // Verify Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8D0),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Text(
                            'Verify',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE58A1F),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        // Edit Button
                        InkWell(
                          onTap: () => _showEditEmailSheet(email, patientId),
                          borderRadius: BorderRadius.circular(10.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: const Color(0xFFE58A1F), width: 1.5),
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE58A1F),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28.0),

              // -------------------------------------------------------------
              // 4. LOG OUT BUTTON
              // -------------------------------------------------------------
              InkWell(
                onTap: _handleLogout,
                borderRadius: BorderRadius.circular(12.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFDC2626),
                        size: 24.0,
                      ),
                      const SizedBox(width: 12.0),
                      const Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 120.0),

              // -------------------------------------------------------------
              // 5. DELETE ACCOUNT BUTTON
              // -------------------------------------------------------------
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleDeleteAccount,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26.0),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)),
                          )
                        : const Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
