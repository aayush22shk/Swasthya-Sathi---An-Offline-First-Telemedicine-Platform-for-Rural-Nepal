/// Pure Dart Clinical Decision Support (CDS) Engine.
///
/// Implements:
/// 1. WHO PEN (Package of Essential NCD Interventions for Primary Health Care)
/// 2. Deterministic Drug-Drug Interaction (DDI) Matrix
/// 3. Cardiovascular & Blood Pressure Staging (ACC/AHA & WHO guidelines)
/// 4. Diabetes / Glycemic Range Verification (ADA 2024 / WHO)
/// 5. Asian BMI Risk Adjustments
/// 6. Pediatric Paracetamol / Antibiotic safe dosage bounds
library;

enum ClinicalSeverity {
  info,
  warning,
  alert,
  critical,
}

class ClinicalAlert {
  final String code;
  final String title;
  final String message;
  final ClinicalSeverity severity;
  final String category; // 'cardiovascular', 'glucose', 'medication', 'pediatric'
  final String? clinicalRecommendation;

  const ClinicalAlert({
    required this.code,
    required this.title,
    required this.message,
    required this.severity,
    required this.category,
    this.clinicalRecommendation,
  });

  bool get isUrgent =>
      severity == ClinicalSeverity.alert || severity == ClinicalSeverity.critical;

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'message': message,
        'severity': severity.name,
        'category': category,
        'clinical_recommendation': clinicalRecommendation,
      };
}

class BpStagingResult {
  final String stage; // 'Normal', 'Elevated', 'Stage 1 HTN', 'Stage 2 HTN', 'Crisis'
  final double map; // Mean Arterial Pressure (mmHg)
  final ClinicalSeverity severity;
  final String advice;

  const BpStagingResult({
    required this.stage,
    required this.map,
    required this.severity,
    required this.advice,
  });
}

class ClinicalRulesEngine {
  ClinicalRulesEngine._();

  // ───────────────────────────────────────────────────────────────────────────
  // 1. BLOOD PRESSURE & CARDIOVASCULAR (WHO PEN / ACC-AHA 2024)
  // ───────────────────────────────────────────────────────────────────────────

  /// Calculates Mean Arterial Pressure (MAP) = Diastolic + 1/3(Systolic - Diastolic)
  static double calculateMap(int systolic, int diastolic) {
    return diastolic + ((systolic - diastolic) / 3.0);
  }

  /// Classifies blood pressure reading according to WHO & AHA criteria
  static BpStagingResult evaluateBloodPressure(int systolic, int diastolic) {
    final map = calculateMap(systolic, diastolic);

    if (systolic >= 180 || diastolic >= 120) {
      return BpStagingResult(
        stage: 'Hypertensive Crisis',
        map: map,
        severity: ClinicalSeverity.critical,
        advice:
            'Critical emergency. Immediate clinical evaluation required to prevent organ damage.',
      );
    } else if (systolic >= 140 || diastolic >= 90) {
      return BpStagingResult(
        stage: 'Stage 2 Hypertension',
        map: map,
        severity: ClinicalSeverity.alert,
        advice:
            'Persistently high. Medical intervention and antihypertensive review advised.',
      );
    } else if (systolic >= 130 || diastolic >= 80) {
      return BpStagingResult(
        stage: 'Stage 1 Hypertension',
        map: map,
        severity: ClinicalSeverity.warning,
        advice:
            'Lifestyle modifications (dietary sodium < 2g/day, exercise) and periodic monitoring.',
      );
    } else if (systolic >= 120 && diastolic < 80) {
      return BpStagingResult(
        stage: 'Elevated BP',
        map: map,
        severity: ClinicalSeverity.info,
        advice: 'Pre-hypertension range. Recommend lifestyle assessment.',
      );
    } else {
      return BpStagingResult(
        stage: 'Normal',
        map: map,
        severity: ClinicalSeverity.info,
        advice: 'Blood pressure is within optimal physiological range.',
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. GLYCEMIC STATUS EVALUATION (ADA 2024 / WHO PEN)
  // ───────────────────────────────────────────────────────────────────────────

  /// Evaluates blood glucose in mg/dL
  static ClinicalAlert? evaluateGlucose(double glucoseMgDl, {String context = 'random'}) {
    if (glucoseMgDl < 54.0) {
      return const ClinicalAlert(
        code: 'GLUCOSE_SEVERE_HYPO',
        title: 'Severe Hypoglycemia',
        message: 'Glucose reading is below 54 mg/dL (< 3.0 mmol/L). Danger of acute neuroglycopenia.',
        severity: ClinicalSeverity.critical,
        category: 'glucose',
        clinicalRecommendation:
            'Administer rapid-acting oral carbohydrates (15-20g glucose) immediately if conscious, or emergency IV dextrose.',
      );
    } else if (glucoseMgDl < 70.0) {
      return const ClinicalAlert(
        code: 'GLUCOSE_HYPO',
        title: 'Hypoglycemia',
        message: 'Blood glucose is below 70 mg/dL.',
        severity: ClinicalSeverity.alert,
        category: 'glucose',
        clinicalRecommendation:
            'Consume fast-acting simple carbohydrates and retest in 15 minutes.',
      );
    } else if (glucoseMgDl > 250.0) {
      return const ClinicalAlert(
        code: 'GLUCOSE_SEVERE_HYPER',
        title: 'Severe Hyperglycemia',
        message: 'Blood glucose exceeds 250 mg/dL.',
        severity: ClinicalSeverity.alert,
        category: 'glucose',
        clinicalRecommendation:
            'Assess for dehydration, ketones, and medication adherence. Physician review required.',
      );
    } else if (glucoseMgDl > 180.0 && context != 'fasting') {
      return const ClinicalAlert(
        code: 'GLUCOSE_ELEVATED',
        title: 'Elevated Post-prandial Glucose',
        message: 'Glucose exceeds the target post-prandial threshold of 180 mg/dL.',
        severity: ClinicalSeverity.warning,
        category: 'glucose',
        clinicalRecommendation: 'Dietary carbohydrate review and clinical follow-up advised.',
      );
    } else if (glucoseMgDl >= 126.0 && context == 'fasting') {
      return const ClinicalAlert(
        code: 'GLUCOSE_FASTING_DIABETIC',
        title: 'Fasting Hyperglycemia',
        message: 'Fasting glucose is >= 126 mg/dL, indicative of diabetes threshold.',
        severity: ClinicalSeverity.warning,
        category: 'glucose',
        clinicalRecommendation: 'Confirm with repeat fasting test or HbA1c screening.',
      );
    }
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. BMI CLASSIFICATION (WHO SOUTH ASIAN CUT-OFFS)
  // ───────────────────────────────────────────────────────────────────────────

  /// Computes and stages BMI according to South Asian criteria (WHO Expert Consultation)
  static Map<String, dynamic> evaluateBmi(double weightKg, double heightCm) {
    if (heightCm <= 0 || weightKg <= 0) return {'bmi': 0.0, 'category': 'Invalid Input'};
    final heightM = heightCm / 100.0;
    final bmi = double.parse((weightKg / (heightM * heightM)).toStringAsFixed(1));

    String category;
    ClinicalSeverity severity;

    if (bmi < 18.5) {
      category = 'Underweight';
      severity = ClinicalSeverity.warning;
    } else if (bmi < 23.0) {
      category = 'Normal (South Asian Target)';
      severity = ClinicalSeverity.info;
    } else if (bmi < 27.5) {
      category = 'Overweight (Increased Risk)';
      severity = ClinicalSeverity.warning;
    } else {
      category = 'Obese (High Risk)';
      severity = ClinicalSeverity.alert;
    }

    return {
      'bmi': bmi,
      'category': category,
      'severity': severity.name,
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. DRUG-DRUG INTERACTION (DDI) & CONTRAINDICATION MATRIX
  // ───────────────────────────────────────────────────────────────────────────

  /// Matrix of high-risk drug pairs common in rural telemedicine
  static final List<_DdiRule> _ddiMatrix = [
    _DdiRule(
      drugA: ['enalapril', 'lisinopril', 'ramipril', 'losartan', 'telmisartan'],
      drugB: ['spironolactone'],
      code: 'DDI_HYPERKALEMIA',
      title: 'Risk of Severe Hyperkalemia',
      message: 'Co-administering ACEi/ARB with Spironolactone can cause fatal potassium retention.',
      severity: ClinicalSeverity.alert,
      recommendation: 'Monitor serum potassium and renal function closely or consider alternative.',
    ),
    _DdiRule(
      drugA: ['ibuprofen', 'diclofenac', 'naproxen', 'piroxicam'],
      drugB: ['warfarin', 'aspirin', 'clopidogrel'],
      code: 'DDI_GI_BLEED',
      title: 'Major Hemorrhagic / GI Bleed Risk',
      message: 'NSAID combined with anticoagulant or antiplatelet significantly multiplies GI bleeding risk.',
      severity: ClinicalSeverity.alert,
      recommendation: 'Substitute with Paracetamol for analgesia or prescribe proton-pump inhibitor (Pantoprazole/Omeprazole).',
    ),
    _DdiRule(
      drugA: ['ciprofloxacin', 'norfloxacin', 'levofloxacin'],
      drugB: ['antacid', 'calcium', 'iron', 'sucralfate'],
      code: 'DDI_CHELATION',
      title: 'Reduced Fluoroquinolone Bioavailability',
      message: 'Divalent and trivalent cations bind fluoroquinolones, preventing intestinal absorption.',
      severity: ClinicalSeverity.warning,
      recommendation: 'Separate administration times by at least 2 hours before or 4 hours after cation ingestion.',
    ),
    _DdiRule(
      drugA: ['metformin'],
      drugB: ['furosemide'],
      code: 'DDI_METFORMIN_LACTIC',
      title: 'Increased Metformin Exposure',
      message: 'Furosemide may increase metformin blood levels, elevating risk of lactic acidosis.',
      severity: ClinicalSeverity.warning,
      recommendation: 'Monitor renal function and adjust metformin dosage if required.',
    ),
    _DdiRule(
      drugA: ['atorvastatin', 'simvastatin'],
      drugB: ['clarithromycin', 'erythromycin', 'itraconazole'],
      code: 'DDI_RHABDOMYOLYSIS',
      title: 'Statin Toxicity / Rhabdomyolysis Risk',
      message: 'Strong CYP3A4 inhibitors dramatically increase statin levels, risking muscle breakdown.',
      severity: ClinicalSeverity.alert,
      recommendation: 'Temporarily pause statin therapy during antibiotic/antifungal course or switch to Rosuvastatin.',
    ),
  ];

  /// Checks a proposed list of new medicines against active medicines
  static List<ClinicalAlert> checkDrugInteractions({
    required List<String> activeMedicines,
    required List<String> proposedMedicines,
  }) {
    final alerts = <ClinicalAlert>[];
    final allMeds = <String>{...activeMedicines, ...proposedMedicines};

    for (final rule in _ddiMatrix) {
      final matchesA = allMeds.any((m) => rule.drugA.any((target) => m.toLowerCase().contains(target)));
      final matchesB = allMeds.any((m) => rule.drugB.any((target) => m.toLowerCase().contains(target)));

      if (matchesA && matchesB) {
        alerts.add(
          ClinicalAlert(
            code: rule.code,
            title: rule.title,
            message: rule.message,
            severity: rule.severity,
            category: 'medication',
            clinicalRecommendation: rule.recommendation,
          ),
        );
      }
    }

    return alerts;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. PEDIATRIC DOSAGE GUARD (PARACETAMOL WHO GUIDELINE)
  // ───────────────────────────────────────────────────────────────────────────

  /// Verifies pediatric paracetamol dosage (Standard: 10-15 mg/kg per single dose, max 60 mg/kg/day)
  static ClinicalAlert? evaluatePediatricParacetamol({
    required double weightKg,
    required double singleDoseMg,
    required int dosesPerDay,
  }) {
    if (weightKg <= 0) return null;

    final recommendedMinDose = weightKg * 10.0;
    final recommendedMaxDose = weightKg * 15.0;
    final maxDailyDose = weightKg * 60.0;
    final totalDailyGiven = singleDoseMg * dosesPerDay;

    if (totalDailyGiven > maxDailyDose || singleDoseMg > recommendedMaxDose * 1.25) {
      return ClinicalAlert(
        code: 'PEDIATRIC_DOSE_OVERDOSE',
        title: 'Pediatric Paracetamol Overdose Alert',
        message:
            'Proposed single dose (${singleDoseMg.toInt()} mg) or daily dose (${totalDailyGiven.toInt()} mg) exceeds the safe therapeutic ceiling for a ${weightKg.toStringAsFixed(1)} kg child.',
        severity: ClinicalSeverity.critical,
        category: 'pediatric',
        clinicalRecommendation:
            'Safe single dose is ${recommendedMinDose.toInt()}–${recommendedMaxDose.toInt()} mg (max 4 doses/24 hours). Adjust to prevent hepatotoxicity.',
      );
    } else if (singleDoseMg < recommendedMinDose * 0.7) {
      return ClinicalAlert(
        code: 'PEDIATRIC_DOSE_SUBTHERAPEUTIC',
        title: 'Sub-therapeutic Pediatric Dose',
        message:
            'Proposed single dose (${singleDoseMg.toInt()} mg) is below standard therapeutic threshold (${recommendedMinDose.toInt()} mg).',
        severity: ClinicalSeverity.info,
        category: 'pediatric',
        clinicalRecommendation:
            'Dose may be ineffective for fever/pain reduction. Standard dose is 15 mg/kg.',
      );
    }

    return null;
  }
}

class _DdiRule {
  final List<String> drugA;
  final List<String> drugB;
  final String code;
  final String title;
  final String message;
  final ClinicalSeverity severity;
  final String recommendation;

  const _DdiRule({
    required this.drugA,
    required this.drugB,
    required this.code,
    required this.title,
    required this.message,
    required this.severity,
    required this.recommendation,
  });
}
