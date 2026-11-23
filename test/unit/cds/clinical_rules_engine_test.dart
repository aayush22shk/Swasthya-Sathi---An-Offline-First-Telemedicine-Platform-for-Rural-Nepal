import 'package:flutter_test/flutter_test.dart';
import 'package:swasthyasathi/src/cds/clinical_rules_engine.dart';
import 'package:swasthyasathi/src/cds/longitudinal_summary_service.dart';
import 'package:swasthyasathi/src/models/conv_prescription_model.dart';
import 'package:swasthyasathi/src/models/diagnosis_model.dart';

void main() {
  group('ClinicalRulesEngine - Blood Pressure & MAP Tests', () {
    test('Calculates Mean Arterial Pressure correctly', () {
      // MAP = 80 + (120 - 80) / 3 = 80 + 13.33 = 93.33
      final map = ClinicalRulesEngine.calculateMap(120, 80);
      expect(map, closeTo(93.33, 0.05));
    });

    test('Identifies Normal Blood Pressure', () {
      final res = ClinicalRulesEngine.evaluateBloodPressure(118, 76);
      expect(res.stage, equals('Normal'));
      expect(res.severity, equals(ClinicalSeverity.info));
    });

    test('Identifies Stage 1 Hypertension', () {
      final res = ClinicalRulesEngine.evaluateBloodPressure(134, 84);
      expect(res.stage, equals('Stage 1 Hypertension'));
      expect(res.severity, equals(ClinicalSeverity.warning));
    });

    test('Identifies Stage 2 Hypertension', () {
      final res = ClinicalRulesEngine.evaluateBloodPressure(148, 94);
      expect(res.stage, equals('Stage 2 Hypertension'));
      expect(res.severity, equals(ClinicalSeverity.alert));
    });

    test('Flags Hypertensive Crisis immediately as critical', () {
      final res = ClinicalRulesEngine.evaluateBloodPressure(190, 125);
      expect(res.stage, equals('Hypertensive Crisis'));
      expect(res.severity, equals(ClinicalSeverity.critical));
    });
  });

  group('ClinicalRulesEngine - Glucose Evaluation', () {
    test('Flags severe hypoglycemia (< 54 mg/dL)', () {
      final alert = ClinicalRulesEngine.evaluateGlucose(48.0);
      expect(alert, isNotNull);
      expect(alert!.severity, equals(ClinicalSeverity.critical));
      expect(alert.code, equals('GLUCOSE_SEVERE_HYPO'));
    });

    test('Flags standard hypoglycemia (< 70 mg/dL)', () {
      final alert = ClinicalRulesEngine.evaluateGlucose(65.0);
      expect(alert, isNotNull);
      expect(alert!.severity, equals(ClinicalSeverity.alert));
    });

    test('Flags severe hyperglycemia (> 250 mg/dL)', () {
      final alert = ClinicalRulesEngine.evaluateGlucose(280.0);
      expect(alert, isNotNull);
      expect(alert!.severity, equals(ClinicalSeverity.alert));
      expect(alert.code, equals('GLUCOSE_SEVERE_HYPER'));
    });

    test('Normal glucose produces no alert', () {
      final alert = ClinicalRulesEngine.evaluateGlucose(105.0);
      expect(alert, isNull);
    });
  });

  group('ClinicalRulesEngine - South Asian BMI Classification', () {
    test('Correctly classifies South Asian BMI thresholds', () {
      // 65 kg, 170 cm -> BMI = 22.5 (Normal for South Asia)
      final normal = ClinicalRulesEngine.evaluateBmi(65.0, 170.0);
      expect(normal['bmi'], equals(22.5));
      expect(normal['category'], contains('Normal'));

      // 72 kg, 170 cm -> BMI = 24.9 (Overweight for South Asia: 23-27.4)
      final overweight = ClinicalRulesEngine.evaluateBmi(72.0, 170.0);
      expect(overweight['bmi'], equals(24.9));
      expect(overweight['category'], contains('Overweight'));

      // 85 kg, 170 cm -> BMI = 29.4 (Obese: >= 27.5)
      final obese = ClinicalRulesEngine.evaluateBmi(85.0, 170.0);
      expect(obese['bmi'], equals(29.4));
      expect(obese['category'], contains('Obese'));
    });
  });

  group('ClinicalRulesEngine - Drug-Drug Interactions (DDI)', () {
    test('Flags Enalapril + Spironolactone hyperkalemia risk', () {
      final alerts = ClinicalRulesEngine.checkDrugInteractions(
        activeMedicines: ['Enalapril 5mg'],
        proposedMedicines: ['Spironolactone 25mg'],
      );
      expect(alerts.length, equals(1));
      expect(alerts.first.code, equals('DDI_HYPERKALEMIA'));
      expect(alerts.first.severity, equals(ClinicalSeverity.alert));
    });

    test('Flags NSAID (Ibuprofen) + Warfarin bleeding hazard', () {
      final alerts = ClinicalRulesEngine.checkDrugInteractions(
        activeMedicines: ['Warfarin 2mg'],
        proposedMedicines: ['Ibuprofen 400mg'],
      );
      expect(alerts.length, equals(1));
      expect(alerts.first.code, equals('DDI_GI_BLEED'));
    });

    test('Safe combination produces no alerts', () {
      final alerts = ClinicalRulesEngine.checkDrugInteractions(
        activeMedicines: ['Paracetamol 500mg'],
        proposedMedicines: ['Amoxicillin 500mg'],
      );
      expect(alerts, isEmpty);
    });
  });

  group('ClinicalRulesEngine - Pediatric Dosage Guard', () {
    test('Approves standard therapeutic dose for 10kg child', () {
      // 10 kg * 15 mg/kg = 150 mg per dose
      final alert = ClinicalRulesEngine.evaluatePediatricParacetamol(
        weightKg: 10.0,
        singleDoseMg: 125.0,
        dosesPerDay: 3,
      );
      expect(alert, isNull);
    });

    test('Catches pediatric toxic overdose', () {
      // 10 kg child given adult 500mg dose
      final alert = ClinicalRulesEngine.evaluatePediatricParacetamol(
        weightKg: 10.0,
        singleDoseMg: 500.0,
        dosesPerDay: 4,
      );
      expect(alert, isNotNull);
      expect(alert!.severity, equals(ClinicalSeverity.critical));
      expect(alert.code, equals('PEDIATRIC_DOSE_OVERDOSE'));
    });
  });

  group('LongitudinalSummaryService Tests', () {
    test('Generates diagnostic trajectory and aggregates active medications', () {
      final d1 = DiagnosisModel(
        id: 'dx1',
        conversationId: 'c1',
        doctorId: 'd1',
        patientId: 'p1',
        title: 'Acute Bronchitis',
        createdAt: DateTime(2026, 8, 1),
      );
      final d2 = DiagnosisModel(
        id: 'dx2',
        conversationId: 'c1',
        doctorId: 'd1',
        patientId: 'p1',
        title: 'Bronchial Asthma',
        createdAt: DateTime(2026, 9, 15),
      );

      final rx1 = ConvPrescriptionModel(
        id: 'rx1',
        conversationId: 'c1',
        doctorId: 'd1',
        patientId: 'p1',
        medicines: [
          const MedicineItem(medicineName: 'Salbutamol Inhaler', dosage: '100mcg'),
          const MedicineItem(medicineName: 'Budesonide', dosage: '200mcg'),
        ],
        createdAt: DateTime(2026, 9, 15),
      );

      final summary = LongitudinalSummaryService.generateSummary(
        patientId: 'p1',
        diagnoses: [d1, d2],
        prescriptions: [rx1],
        latestSystolic: 122,
        latestDiastolic: 80,
      );

      expect(summary.diagnosticTrajectory, contains('Acute Bronchitis'));
      expect(summary.diagnosticTrajectory, contains('Bronchial Asthma'));
      expect(summary.activeMedications, contains('Salbutamol Inhaler (100mcg)'));
      expect(summary.activeMedications, contains('Budesonide (200mcg)'));
      expect(summary.vitalsTrend, contains('BP: 122/80'));
      expect(summary.hasUrgentAlerts, isFalse);
    });
  });
}
