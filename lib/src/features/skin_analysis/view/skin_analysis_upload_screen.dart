import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/skin_analysis_model.dart';
import '../../../services/skin_analysis_service.dart';
import '../../../services/skin_model_runner.dart';
import '../../../services/photo_quality_validator.dart';
import 'skin_analysis_consent_dialog.dart';
import 'skin_analysis_result_screen.dart';

class SkinAnalysisUploadScreen extends StatefulWidget {
  const SkinAnalysisUploadScreen({super.key});

  @override
  State<SkinAnalysisUploadScreen> createState() => _SkinAnalysisUploadScreenState();
}

class _SkinAnalysisUploadScreenState extends State<SkinAnalysisUploadScreen> {
  final SkinAnalysisService _service = SkinAnalysisService();
  final ImagePicker _picker = ImagePicker();

  String? _selectedImagePath;
  String? _selectedClassHint;
  bool _isRealPhoto = false; // true when user picks a real file (not a preset)
  bool _isAnalyzing = false;
  List<SkinAnalysisModel> _recentHistory = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // Warm up TFLite model in background while user selects image
    SkinModelRunner.instance.ensureLoaded();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final list = await _service.getOfflineHistory();
    if (mounted) {
      setState(() {
        _recentHistory = list;
        _isLoadingHistory = false;
      });
    }
  }

  void _selectPresetSample(String classKey) {
    setState(() {
      _selectedImagePath = 'sample_$classKey.jpg';
      _selectedClassHint = classKey;
      _isRealPhoto = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (file != null && mounted) {
        setState(() {
          _selectedImagePath = file.path;
          _selectedClassHint = null;
          _isRealPhoto = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access ${source == ImageSource.camera ? "camera" : "gallery"}: $e')),
        );
      }
    }
  }

  Future<void> _runAnalysis() async {
    if (_selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or capture a photograph first.')),
      );
      return;
    }

    // 1. Consent gate — shown once; persisted in SharedPreferences
    final consented = await SkinAnalysisConsentDialog.requestConsentIfNeeded(context);
    if (!consented || !mounted) return;

    // 2. Photo quality gate — only for real photos (not demo presets)
    if (_isRealPhoto) {
      final qr = await PhotoQualityValidator.validate(_selectedImagePath!);
      if (!qr.isPassed) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.image_not_supported_rounded, color: Color(0xFFDC2626)),
                SizedBox(width: 8),
                Text('Photo Quality Issue', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Text(
              qr.failureReason ?? 'Photo quality is insufficient.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Retake Photo'),
              ),
            ],
          ),
        );
        return;
      }
    }

    setState(() => _isAnalyzing = true);

    try {
      final result = await _service.analyzeImageOffline(
        imagePath: _selectedImagePath!,
        classHint: _selectedClassHint,
        isInvalidNonSkin: _selectedClassHint == 'invalid_object',
      );

      // Attempt background sync if online (non-blocking)
      _service.syncWithBackend(result);

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SkinAnalysisResultScreen(analysis: result),
        ),
      ).then((_) => _loadHistory());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text('Image Quality Warning', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Skin Disease Screening',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Offline & Triage Information Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A0072FF), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% Offline AI Screening',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Trained on MobileNetV3. Analyzes lesions on-device with zero internet access.',
                          style: TextStyle(fontSize: 12, color: Colors.white, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Image Preview / Picker Box
            const Text(
              'Photograph Affected Area',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: _selectedImagePath == null ? () => _showImageSourceSheet() : null,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedImagePath != null ? const Color(0xFF0072FF) : const Color(0xFFE2E8F0),
                    width: _selectedImagePath != null ? 2 : 1,
                  ),
                ),
                child: _selectedImagePath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_a_photo_outlined, size: 36, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tap to capture or upload a photo',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Or choose a sample condition below for demo',
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _isRealPhoto
                                ? Image.file(
                                    File(_selectedImagePath!),
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _placeholderImage(),
                                  )
                                : _placeholderImage(),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedImagePath = null;
                                _selectedClassHint = null;
                                _isRealPhoto = false;
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                          if (!_isRealPhoto)
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _selectedImagePath ?? '',
                                    style: const TextStyle(fontSize: 11, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. Camera / Gallery action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0072FF),
                      side: const BorderSide(color: Color(0xFF0072FF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Camera', style: TextStyle(fontSize: 13)),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFF059669)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Gallery', style: TextStyle(fontSize: 13)),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4. Clinical Sample Presets (For testing and demoing)
            const Text(
              'Or select a demo condition:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _presetChip('tinea_ringworm', 'Tinea / Ringworm', const Color(0xFF0072FF)),
                  _presetChip('eczema', 'Eczema', const Color(0xFF059669)),
                  _presetChip('psoriasis', 'Psoriasis', const Color(0xFF7C3AED)),
                  _presetChip('acne', 'Acne Vulgaris', const Color(0xFFD97706)),
                  _presetChip('vitiligo', 'Vitiligo', const Color(0xFF0284C7)),
                  _presetChip('scabies', 'Scabies', const Color(0xFFDC2626)),
                  _presetChip('impetigo', 'Impetigo', const Color(0xFFD97706)),
                  _presetChip('herpes_zoster', 'Shingles', const Color(0xFFB91C1C)),
                  _presetChip('urticaria', 'Urticaria', const Color(0xFF4F46E5)),
                  _presetChip('rosacea', 'Rosacea', const Color(0xFFE11D48)),
                  _presetChip('invalid_object', 'Non-Skin Object (Test Filter)', const Color(0xFF475569)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. Analyze Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0072FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.psychology_outlined),
                label: Text(
                  _isAnalyzing ? 'Analyzing on-device...' : 'Analyze Image (Offline)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: _isAnalyzing ? null : _runAnalysis,
              ),
            ),

            const SizedBox(height: 32),

            // 6. Previous Screening History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Previous Screenings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                if (_recentHistory.isNotEmpty)
                  Text(
                    '${_recentHistory.length} saved',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoadingHistory)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_recentHistory.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Text(
                    'No prior screenings recorded on this device.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentHistory.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = _recentHistory[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0072FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.biotech_outlined, color: Color(0xFF0072FF)),
                      ),
                      title: Text(
                        item.predictedCondition,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Confidence: ${(item.confidenceScore * 100).toStringAsFixed(1)}% • ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SkinAnalysisResultScreen(analysis: item),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: const Icon(Icons.image_rounded, size: 50, color: Color(0xFF0072FF)),
          ),
          const SizedBox(height: 10),
          Text(
            _selectedClassHint != null ? 'Demo: $_selectedClassHint' : _selectedImagePath ?? '',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.camera_alt_outlined, color: Color(0xFF0072FF)),
                ),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use your camera to photograph the skin'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF0FDF4),
                  child: Icon(Icons.photo_library_outlined, color: Color(0xFF059669)),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing photo from your device'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String classKey, String label, Color color) {
    final isSelected = _selectedClassHint == classKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : color)),
        selected: isSelected,
        selectedColor: color,
        backgroundColor: color.withValues(alpha: 0.08),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        onSelected: (selected) {
          if (selected) {
            _selectPresetSample(classKey);
          }
        },
      ),
    );
  }
}
