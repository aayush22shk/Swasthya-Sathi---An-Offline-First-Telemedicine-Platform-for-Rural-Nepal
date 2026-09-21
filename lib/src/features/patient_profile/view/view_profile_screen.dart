import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../models/patient_profile_model.dart';
import '../widgets/patient_avatar_widget.dart';
import 'account_settings_screen.dart';
import 'edit_profile_dialog.dart';

class ViewProfileScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const ViewProfileScreen({
    super.key,
    this.onBackToHome,
  });

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  final _profileService = ProfileService();
  final _authService = AuthService();

  PatientProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _profileService.getMyPatientProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountSettingsScreen(profile: _profile),
      ),
    ).then((_) => _fetchProfile());
  }

  Future<void> _openEditProfileDialog() async {
    if (_profile == null) return;
    final updated = await EditProfileDialog.show(context, _profile!);
    if (updated != null) {
      setState(() => _profile = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = _authService.currentUser;
    final fullName = _profile?.fullName ?? authUser?.fullName ?? 'Aayush Shakya';
    final location = _profile?.location ?? 'Nepal';
    final bloodGroup = _profile?.bloodGroup ?? 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () {
            if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'View profile',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFFE58A1F),
              size: 24.0,
            ),
            tooltip: 'Account Settings & Edit',
            onPressed: _navigateToSettings,
          ),
          const SizedBox(width: 8.0),
        ],
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3.0),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: Color(0xFF0072FF),
                  minHeight: 3.0,
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchProfile,
          color: const Color(0xFF0072FF),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------------------
                // 1. PROFILE HEADER ROW (Interactive tap to edit)
                // -------------------------------------------------------------
                InkWell(
                  onTap: _openEditProfileDialog,
                  borderRadius: BorderRadius.circular(16.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PatientAvatarWidget(
                          size: 88.0,
                          photoUrl: _profile?.profilePhotoUrl,
                        ),
                        const SizedBox(width: 18.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      fullName,
                                      style: const TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.mode_edit_outline_outlined, size: 16, color: Color(0xFFE58A1F)),
                                ],
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                location,
                                style: const TextStyle(
                                  fontSize: 15.0,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Container(
                                height: 1.0,
                                color: const Color(0xFFE2E8F0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


                const SizedBox(height: 24.0),

                // -------------------------------------------------------------
                // 2. METRICS / VITALS ROW (4 items with vertical dividers)
                // -------------------------------------------------------------
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 1. Weight
                      _buildMetricItem(
                        iconWidget: _buildScaleIcon(),
                        label: 'N/A',
                      ),
                      _buildVerticalDivider(),

                      // 2. Height
                      _buildMetricItem(
                        iconWidget: _buildHeightIcon(),
                        label: 'N/A',
                      ),
                      _buildVerticalDivider(),

                      // 3. Blood Group
                      _buildMetricItem(
                        iconWidget: _buildBloodDropIcon(),
                        label: bloodGroup.isNotEmpty ? bloodGroup : 'N/A',
                      ),
                      _buildVerticalDivider(),

                      // 4. Smoking
                      _buildMetricItem(
                        iconWidget: _buildNoSmokingIcon(),
                        label: 'No',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36.0),

                // -------------------------------------------------------------
                // 3. HEALTH SECTION HEADER
                // -------------------------------------------------------------
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      child: const Icon(
                        Icons.monitor_heart_outlined,
                        size: 22.0,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    const Text(
                      'Health',
                      style: TextStyle(
                        fontSize: 17.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16.0),

                // -------------------------------------------------------------
                // 4. MEDICAL RECORDS CARD
                // -------------------------------------------------------------
                _buildActionCard(
                  title: 'Medical records',
                  onTap: () {
                    _showRecordsBottomSheet(context);
                  },
                ),

                const SizedBox(height: 14.0),

                // -------------------------------------------------------------
                // 5. E-PRESCRIPTIONS CARD
                // -------------------------------------------------------------
                _buildActionCard(
                  title: 'E-prescriptions',
                  onTap: () {
                    _showPrescriptionsBottomSheet(context);
                  },
                ),

                const SizedBox(height: 40.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // METRIC ITEM WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildMetricItem({required Widget iconWidget, required String label}) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(height: 36.0, child: Center(child: iconWidget)),
          const SizedBox(height: 10.0),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15.0,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1.0,
      height: 44.0,
      color: const Color(0xFFE2E8F0),
    );
  }

  // Custom styled metric icons matching screenshots
  Widget _buildScaleIcon() {
    return Container(
      width: 32.0,
      height: 32.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFF00A896), width: 1.8),
      ),
      child: Center(
        child: Container(
          width: 14.0,
          height: 6.0,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF00A896), width: 1.2),
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
      ),
    );
  }

  Widget _buildHeightIcon() {
    return Container(
      width: 32.0,
      height: 32.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF00A896), width: 1.8),
      ),
      child: const Center(
        child: Icon(
          Icons.swap_vert_rounded,
          color: Color(0xFF00A896),
          size: 20.0,
        ),
      ),
    );
  }

  Widget _buildBloodDropIcon() {
    return Container(
      width: 32.0,
      height: 32.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF00A896), width: 1.8),
      ),
      child: const Center(
        child: Icon(
          Icons.water_drop_outlined,
          color: Color(0xFF00A896),
          size: 18.0,
        ),
      ),
    );
  }

  Widget _buildNoSmokingIcon() {
    return Container(
      width: 32.0,
      height: 32.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF00A896), width: 1.8),
      ),
      child: const Center(
        child: Icon(
          Icons.smoke_free_rounded,
          color: Color(0xFF00A896),
          size: 18.0,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTION CARDS (Medical Records & E-prescriptions)
  // ---------------------------------------------------------------------------

  Widget _buildActionCard({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF475569),
              size: 24.0,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM SHEETS
  // ---------------------------------------------------------------------------

  void _showRecordsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Medical Records',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.folder_open_rounded, color: Color(0xFF0072FF)),
                    SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        'No offline medical records found yet. Records from doctors will sync automatically.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrescriptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'E-Prescriptions',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.medication_outlined, color: Color(0xFF10B981)),
                    SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        'No active e-prescriptions. Digital prescriptions from consultations will appear here.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
