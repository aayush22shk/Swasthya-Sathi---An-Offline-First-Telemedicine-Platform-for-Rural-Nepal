import 'package:flutter/material.dart';
import '../../../models/diagnosis_model.dart';

/// Full-page diagnosis result view — tapped from a diagnosis card in chat.
class DiagnosisDetailScreen extends StatelessWidget {
  final DiagnosisModel diagnosis;

  const DiagnosisDetailScreen({super.key, required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Diagnosis Results',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(diagnosis.title,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            if (diagnosis.doctorName != null)
                              Text('Dr. ${diagnosis.doctorName}',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (diagnosis.patientName != null)
                    _headerInfo(Icons.person_outline, 'Patient', diagnosis.patientName!),
                  const SizedBox(height: 6),
                  _headerInfo(Icons.calendar_today_outlined, 'Date',
                      '${diagnosis.createdAt.day}/${diagnosis.createdAt.month}/${diagnosis.createdAt.year}'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (diagnosis.description != null && diagnosis.description!.isNotEmpty)
              _section('Summary', diagnosis.description!, Icons.summarize_outlined, const Color(0xFF0072FF)),

            if (diagnosis.findings != null && diagnosis.findings!.isNotEmpty)
              _section('Clinical Findings', diagnosis.findings!, Icons.biotech_outlined, const Color(0xFF7C3AED)),

            if (diagnosis.recommendedTreatment != null && diagnosis.recommendedTreatment!.isNotEmpty)
              _section('Recommended Treatment', diagnosis.recommendedTreatment!, Icons.healing_rounded, const Color(0xFF059669)),

            if (diagnosis.additionalNotes != null && diagnosis.additionalNotes!.isNotEmpty)
              _section('Additional Notes', diagnosis.additionalNotes!, Icons.note_outlined, const Color(0xFF64748B)),

            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Telemedicine Clinical Assessment. In case of emergency (chest pain, acute breathlessness), visit the nearest emergency hospital immediately.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                    ),
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

  Widget _headerInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _section(String title, String content, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 10),
          Text(content,
              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), height: 1.6)),
        ],
      ),
    );
  }
}
