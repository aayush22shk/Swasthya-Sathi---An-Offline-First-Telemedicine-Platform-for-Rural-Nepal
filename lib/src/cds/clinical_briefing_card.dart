import 'package:flutter/material.dart';
import 'longitudinal_summary_service.dart';

class ClinicalBriefingCard extends StatefulWidget {
  final LongitudinalSummary summary;
  final VoidCallback? onDismiss;

  const ClinicalBriefingCard({
    super.key,
    required this.summary,
    this.onDismiss,
  });

  @override
  State<ClinicalBriefingCard> createState() => _ClinicalBriefingCardState();
}

class _ClinicalBriefingCardState extends State<ClinicalBriefingCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final hasUrgent = s.hasUrgentAlerts;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: hasUrgent ? const Color(0xFFEF4444) : const Color(0xFF0072FF).withValues(alpha: 0.3),
          width: hasUrgent ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasUrgent ? const Color(0xFFEF4444) : const Color(0xFF0072FF)).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7.0),
                    decoration: BoxDecoration(
                      color: hasUrgent
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasUrgent ? Icons.warning_amber_rounded : Icons.auto_awesome_rounded,
                      size: 18.0,
                      color: hasUrgent ? const Color(0xFFEF4444) : const Color(0xFF0072FF),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Clinical Summary',
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: const Text(
                                'WHO PEN',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          hasUrgent
                              ? '⚠️ ${s.clinicalAlerts.length} clinical alert(s) require review'
                              : 'Continuous trajectory · Tap to view details',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: hasUrgent ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                            fontWeight: hasUrgent ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible 4-Box Detail View
          if (_isExpanded) ...[
            const Divider(height: 1.0, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  // Box 1 & 2
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _boxCard(
                          title: 'Diagnostic Trajectory',
                          icon: Icons.history_edu_rounded,
                          color: const Color(0xFF0072FF),
                          content: s.diagnosticTrajectory,
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: _boxCard(
                          title: 'Active Regimen',
                          icon: Icons.medication_rounded,
                          color: const Color(0xFF059669),
                          content: s.activeMedications.isNotEmpty
                              ? s.activeMedications.join('\n')
                              : 'No active medications',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),

                  // Box 3 & 4
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _boxCard(
                          title: 'Vitals & BMI',
                          icon: Icons.monitor_heart_outlined,
                          color: const Color(0xFF8B5CF6),
                          content: s.vitalsTrend,
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: _boxCard(
                          title: 'Clinical Flags',
                          icon: Icons.shield_outlined,
                          color: hasUrgent ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                          content: s.clinicalAlerts.isNotEmpty
                              ? s.clinicalAlerts.map((a) => '• ${a.title}').join('\n')
                              : 'No contraindications identified',
                        ),
                      ),
                    ],
                  ),

                  // Expanded Alert Details if present
                  if (s.clinicalAlerts.isNotEmpty) ...[
                    const SizedBox(height: 12.0),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, size: 14.0, color: Color(0xFFB45309)),
                              SizedBox(width: 6.0),
                              Text(
                                'Recommended Actions:',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          ...s.clinicalAlerts.map((a) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  '• ${a.title}: ${a.clinicalRecommendation ?? a.message}',
                                  style: const TextStyle(fontSize: 11.0, color: Color(0xFF78350F)),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _boxCard({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.0, color: color),
              const SizedBox(width: 5.0),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            content,
            style: const TextStyle(
              fontSize: 11.0,
              color: Color(0xFF334155),
              height: 1.35,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
