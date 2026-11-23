import '../models/conv_prescription_model.dart';
import '../models/diagnosis_model.dart';
import 'clinical_rules_engine.dart';

/// Structured 4-Box Clinical Briefing for Doctor Handovers and Follow-up Sessions
class LongitudinalSummary {
  final String patientId;
  final String diagnosticTrajectory;
  final List<String> activeMedications;
  final String vitalsTrend;
  final List<ClinicalAlert> clinicalAlerts;
  final String naturalLanguageBriefing;
  final DateTime generatedAt;

  const LongitudinalSummary({
    required this.patientId,
    required this.diagnosticTrajectory,
    required this.activeMedications,
    required this.vitalsTrend,
    required this.clinicalAlerts,
    required this.naturalLanguageBriefing,
    required this.generatedAt,
  });

  bool get hasUrgentAlerts => clinicalAlerts.any((a) => a.isUrgent);
}

class LongitudinalSummaryService {
  LongitudinalSummaryService._();

  /// Deterministically compiles the longitudinal summary from chronological patient data
  static LongitudinalSummary generateSummary({
    required String patientId,
    required List<DiagnosisModel> diagnoses,
    required List<ConvPrescriptionModel> prescriptions,
    int? latestSystolic,
    int? latestDiastolic,
    double? latestGlucoseMgDl,
    double? weightKg,
    double? heightCm,
  }) {
    // 1. Diagnostic Trajectory
    final sortedDx = List<DiagnosisModel>.from(diagnoses)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    String dxTrajectory;
    if (sortedDx.isEmpty) {
      dxTrajectory = 'No prior diagnostic records on file.';
    } else if (sortedDx.length == 1) {
      dxTrajectory = 'Single diagnostic encounter: ${sortedDx.first.title} on ${_formatDate(sortedDx.first.createdAt)}.';
    } else {
      final initial = sortedDx.first;
      final latest = sortedDx.last;
      dxTrajectory =
          'Progression: Originally diagnosed with "${initial.title}" (${_formatDate(initial.createdAt)}), '
          'most recently evaluated as "${latest.title}" (${_formatDate(latest.createdAt)}).';
    }

    // 2. Active Medications & DDI Check
    final activeMedsList = <String>[];
    for (final rx in prescriptions) {
      for (final med in rx.medicines) {
        final medDesc = '${med.medicineName}${med.dosage != null && med.dosage!.isNotEmpty ? " (${med.dosage})" : ""}';
        if (!activeMedsList.contains(medDesc)) {
          activeMedsList.add(medDesc);
        }
      }
    }

    // 3. Clinical Alerts Collection
    final alerts = <ClinicalAlert>[];

    // Drug-Drug Interaction check across all active meds
    final medNames = activeMedsList.map((m) => m.split('(').first.trim()).toList();
    alerts.addAll(ClinicalRulesEngine.checkDrugInteractions(
      activeMedicines: medNames,
      proposedMedicines: const [],
    ));

    // 4. Vitals Trend & Staging
    final vitalsParts = <String>[];
    if (latestSystolic != null && latestDiastolic != null) {
      final bpResult = ClinicalRulesEngine.evaluateBloodPressure(latestSystolic, latestDiastolic);
      vitalsParts.add('BP: $latestSystolic/$latestDiastolic mmHg (${bpResult.stage}, MAP: ${bpResult.map.toStringAsFixed(1)})');
      if (bpResult.severity == ClinicalSeverity.alert || bpResult.severity == ClinicalSeverity.critical) {
        alerts.add(ClinicalAlert(
          code: 'BP_ELEVATED_ALERT',
          title: 'Blood Pressure Flag: ${bpResult.stage}',
          message: bpResult.advice,
          severity: bpResult.severity,
          category: 'cardiovascular',
        ));
      }
    }

    if (latestGlucoseMgDl != null) {
      vitalsParts.add('Glucose: ${latestGlucoseMgDl.toStringAsFixed(0)} mg/dL');
      final glucoseAlert = ClinicalRulesEngine.evaluateGlucose(latestGlucoseMgDl);
      if (glucoseAlert != null) {
        alerts.add(glucoseAlert);
      }
    }

    if (weightKg != null && heightCm != null) {
      final bmiData = ClinicalRulesEngine.evaluateBmi(weightKg, heightCm);
      vitalsParts.add('BMI: ${bmiData['bmi']} (${bmiData['category']})');
    }

    final vitalsSummary = vitalsParts.isNotEmpty
        ? vitalsParts.join(' | ')
        : 'No recent vital readings recorded.';

    // 5. Natural Language Clinician Handover Briefing
    final handoverBuffer = StringBuffer();
    handoverBuffer.writeln('CLINICAL SUMMARY:');
    handoverBuffer.writeln('• Diagnosis: $dxTrajectory');
    handoverBuffer.writeln('• Regimen: ${activeMedsList.isNotEmpty ? activeMedsList.join(', ') : "None currently active"}');
    handoverBuffer.writeln('• Vitals: $vitalsSummary');
    if (alerts.isNotEmpty) {
      handoverBuffer.writeln('• Alerts (${alerts.length}):');
      for (final a in alerts) {
        handoverBuffer.writeln('  - [${a.severity.name.toUpperCase()}] ${a.title}: ${a.message}');
      }
    } else {
      handoverBuffer.writeln('• Alerts: No acute clinical contraindications identified.');
    }

    return LongitudinalSummary(
      patientId: patientId,
      diagnosticTrajectory: dxTrajectory,
      activeMedications: activeMedsList,
      vitalsTrend: vitalsSummary,
      clinicalAlerts: alerts,
      naturalLanguageBriefing: handoverBuffer.toString(),
      generatedAt: DateTime.now(),
    );
  }

  static String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}
