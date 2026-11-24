import 'package:flutter/material.dart';
import '../../../models/skin_analysis_model.dart';
import '../../../services/skin_analysis_service.dart';
import '../../../services/auth_service.dart';

class SkinAnalysisResultScreen extends StatefulWidget {
  final SkinAnalysisModel analysis;
  final bool isDoctorView;

  const SkinAnalysisResultScreen({
    super.key,
    required this.analysis,
    this.isDoctorView = false,
  });

  @override
  State<SkinAnalysisResultScreen> createState() => _SkinAnalysisResultScreenState();
}

class _SkinAnalysisResultScreenState extends State<SkinAnalysisResultScreen> {
  final SkinAnalysisService _service = SkinAnalysisService();
  late SkinAnalysisModel _currentAnalysis;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _currentAnalysis = widget.analysis;
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626);
      case 'high':
        return const Color(0xFFEA580C);
      case 'medium':
        return const Color(0xFFD97706);
      case 'low':
      default:
        return const Color(0xFF059669);
    }
  }

  void _showShareDialog() {
    final doctorIdCtrl = TextEditingController(text: '5e0a6536-c740-44c4-981b-58fbe903f92c');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share with Assigned Doctor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your doctor will receive this screening image, AI predictions, and can provide clinical advice during your consultation.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: doctorIdCtrl,
              decoration: InputDecoration(
                labelText: 'Doctor Reference ID',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0072FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  setState(() => _isSharing = true);
                  final success = await _service.shareWithDoctor(
                    _currentAnalysis.id ?? 'local_1',
                    doctorIdCtrl.text.trim(),
                  );
                  if (mounted) {
                    setState(() {
                      _isSharing = false;
                      _currentAnalysis = SkinAnalysisModel(
                        id: _currentAnalysis.id,
                        imageUrl: _currentAnalysis.imageUrl,
                        predictedCondition: _currentAnalysis.predictedCondition,
                        confidenceScore: _currentAnalysis.confidenceScore,
                        topPredictions: _currentAnalysis.topPredictions,
                        isUncertain: _currentAnalysis.isUncertain,
                        uncertaintyReason: _currentAnalysis.uncertaintyReason,
                        urgencyLevel: _currentAnalysis.urgencyLevel,
                        description: _currentAnalysis.description,
                        symptoms: _currentAnalysis.symptoms,
                        adviceEn: _currentAnalysis.adviceEn,
                        adviceNe: _currentAnalysis.adviceNe,
                        modelVersion: _currentAnalysis.modelVersion,
                        isSharedWithDoctor: true,
                        doctorId: doctorIdCtrl.text.trim(),
                        doctorName: 'Dr. Anita KC',
                        doctorNotes: _currentAnalysis.doctorNotes,
                        reviewedAt: _currentAnalysis.reviewedAt,
                        createdAt: _currentAnalysis.createdAt,
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Screening shared with doctor.' : 'Saved offline; will share when online.'),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                  }
                },
                child: const Text('Confirm Share', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDoctorReviewDialog() {
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doctor Clinical Review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Provide professional clinical assessment, confirm or override the AI prediction, and recommend treatment.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter clinical observations, differential diagnosis, and recommended course...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (notesCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await _service.reviewAnalysis(_currentAnalysis.id ?? 'local', notesCtrl.text.trim());
                  if (mounted) {
                    setState(() {
                      _currentAnalysis = SkinAnalysisModel(
                        id: _currentAnalysis.id,
                        imageUrl: _currentAnalysis.imageUrl,
                        predictedCondition: _currentAnalysis.predictedCondition,
                        confidenceScore: _currentAnalysis.confidenceScore,
                        topPredictions: _currentAnalysis.topPredictions,
                        isUncertain: _currentAnalysis.isUncertain,
                        uncertaintyReason: _currentAnalysis.uncertaintyReason,
                        urgencyLevel: _currentAnalysis.urgencyLevel,
                        description: _currentAnalysis.description,
                        symptoms: _currentAnalysis.symptoms,
                        adviceEn: _currentAnalysis.adviceEn,
                        adviceNe: _currentAnalysis.adviceNe,
                        modelVersion: _currentAnalysis.modelVersion,
                        isSharedWithDoctor: _currentAnalysis.isSharedWithDoctor,
                        doctorId: _currentAnalysis.doctorId,
                        doctorName: 'Dr. ${AuthService().currentUser?.fullName ?? 'You'}',
                        doctorNotes: notesCtrl.text.trim(),
                        reviewedAt: DateTime.now(),
                        createdAt: _currentAnalysis.createdAt,
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Doctor assessment saved.')),
                    );
                  }
                },
                child: const Text('Save Review', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _getUrgencyColor(_currentAnalysis.urgencyLevel);

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
          'Analysis Results',
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
            // 1. Primary Prediction Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [urgencyColor, urgencyColor.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: urgencyColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Triage: ${_currentAnalysis.urgencyLevel.toUpperCase()}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${(_currentAnalysis.confidenceScore * 100).toStringAsFixed(1)}% Confidence',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentAnalysis.predictedCondition,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (_currentAnalysis.adviceNe.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'AI प्राथमिक पहिचान (अफलाइन मोड)',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),

            // 2. Uncertainty Warning (if applicable)
            if (_currentAnalysis.isUncertain) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.help_outline_rounded, color: Color(0xFFD97706), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Borderline Confidence (<60%). Visual features are ambiguous. Formal physician examination is recommended.',
                        style: TextStyle(color: Color(0xFF92400E), fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 3. Differential Predictions (Top-3)
            const Text(
              'Top Differential Possibilities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  for (final pred in _currentAnalysis.topPredictions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pred.conditionName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                '${pred.confidencePct.toStringAsFixed(1)}%',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0072FF)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (pred.confidence / 1.0).clamp(0.0, 1.0),
                              backgroundColor: const Color(0xFFE2E8F0),
                              color: const Color(0xFF0072FF),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Clinical Overview & Symptoms
            if (_currentAnalysis.description.isNotEmpty) ...[
              const Text(
                'Clinical Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  _currentAnalysis.description,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 5. Bilingual Home Care Advice
            if (_currentAnalysis.adviceEn.isNotEmpty || _currentAnalysis.adviceNe.isNotEmpty) ...[
              const Text(
                'Recommended Care & Next Steps',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentAnalysis.adviceEn.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF059669)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentAnalysis.adviceEn,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF065F46), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_currentAnalysis.adviceNe.isNotEmpty) ...[
                      const Divider(height: 20, color: Color(0xFFA7F3D0)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.language_rounded, size: 18, color: Color(0xFF059669)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentAnalysis.adviceNe,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF065F46), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 6. Doctor Review Section (If reviewed or in doctor view)
            if (_currentAnalysis.doctorNotes != null && _currentAnalysis.doctorNotes!.isNotEmpty) ...[
              const Text(
                'Professional Assessment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0072FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF0072FF), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _currentAnalysis.doctorName ?? 'Attending Doctor',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentAnalysis.doctorNotes!,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 7. Mandatory Legal & Medical Disclaimer Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 20, color: Color(0xFF64748B)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Preliminary AI Screening Only: This is an educational tool and does not constitute a confirmed medical diagnosis. Do not take prescription medicines without professional medical advice.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 8. Action Buttons
            if (widget.isDoctorView)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Add Clinical Assessment', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _showDoctorReviewDialog,
                ),
              )
            else if (!_currentAnalysis.isSharedWithDoctor)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0072FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isSharing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.share_outlined),
                  label: Text(
                    _isSharing ? 'Sharing...' : 'Share with Assigned Doctor',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isSharing ? null : _showShareDialog,
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF93C5FD)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF0072FF), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Shared with assigned doctor for review',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0072FF)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
