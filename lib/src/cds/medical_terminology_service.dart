import 'dart:convert';
import 'package:flutter/services.dart';

class ConditionCode {
  final String code; // ICD-11
  final String icd10;
  final String name;
  final String nepali;
  final String category;
  final String triageUrgency;
  final List<String> symptoms;

  const ConditionCode({
    required this.code,
    required this.icd10,
    required this.name,
    required this.nepali,
    required this.category,
    required this.triageUrgency,
    this.symptoms = const [],
  });

  factory ConditionCode.fromJson(Map<String, dynamic> json) {
    return ConditionCode(
      code: json['code'] as String? ?? '',
      icd10: json['icd10'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nepali: json['nepali'] as String? ?? '',
      category: json['category'] as String? ?? '',
      triageUrgency: json['triage_urgency'] as String? ?? 'low',
      symptoms: (json['symptoms'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [],
    );
  }

  String get displayName => '$name ($code)';
  String get fullLabel => '$name ($code) - $nepali';
}

class EssentialMedicine {
  final String name;
  final String atc;
  final String defaultDosage;
  final String defaultFrequency;
  final String defaultDuration;
  final String route;
  final String category;
  final String nepaliUsage;
  final String? warning;

  const EssentialMedicine({
    required this.name,
    required this.atc,
    required this.defaultDosage,
    required this.defaultFrequency,
    required this.defaultDuration,
    required this.route,
    required this.category,
    required this.nepaliUsage,
    this.warning,
  });

  factory EssentialMedicine.fromJson(Map<String, dynamic> json) {
    return EssentialMedicine(
      name: json['name'] as String? ?? '',
      atc: json['atc'] as String? ?? '',
      defaultDosage: json['default_dosage'] as String? ?? '',
      defaultFrequency: json['default_frequency'] as String? ?? '',
      defaultDuration: json['default_duration'] as String? ?? '',
      route: json['route'] as String? ?? 'oral',
      category: json['category'] as String? ?? '',
      nepaliUsage: json['nepali_usage'] as String? ?? '',
      warning: json['warning'] as String?,
    );
  }

  String get displayName => '$name ($atc)';
}

/// Offline Medical Terminology lookup service for Nepal Telemedicine.
/// Pre-seeded with ICD-11 codes and WHO/Nepal Essential Drugs.
class MedicalTerminologyService {
  static final MedicalTerminologyService _instance = MedicalTerminologyService._internal();
  factory MedicalTerminologyService() => _instance;
  MedicalTerminologyService._internal();

  bool _initialized = false;
  final List<ConditionCode> _conditions = [];
  final List<EssentialMedicine> _medicines = [];

  List<ConditionCode> get conditions => List.unmodifiable(_conditions);
  List<EssentialMedicine> get medicines => List.unmodifiable(_medicines);

  /// Initializes terminology data from assets or embedded fallback.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final jsonString = await rootBundle.loadString('assets/medical_codes_nepal.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      _loadFromMap(data);
    } catch (_) {
      // Fallback for tests or before asset bundle is attached
      _loadFallbackData();
    }
    _initialized = true;
  }

  void _loadFromMap(Map<String, dynamic> data) {
    _conditions.clear();
    _medicines.clear();

    if (data['conditions'] is List) {
      for (final item in data['conditions'] as List) {
        if (item is Map<String, dynamic>) {
          _conditions.add(ConditionCode.fromJson(item));
        }
      }
    }

    if (data['medicines'] is List) {
      for (final item in data['medicines'] as List) {
        if (item is Map<String, dynamic>) {
          _medicines.add(EssentialMedicine.fromJson(item));
        }
      }
    }
  }

  void _loadFallbackData() {
    _conditions.clear();
    _medicines.clear();

    _conditions.addAll(const [
      ConditionCode(
        code: 'BA00',
        icd10: 'I10',
        name: 'Essential hypertension',
        nepali: 'उच्च रक्तचाप',
        category: 'Cardiovascular',
        triageUrgency: 'medium',
      ),
      ConditionCode(
        code: '5A11',
        icd10: 'E11',
        name: 'Type 2 diabetes mellitus',
        nepali: 'मधुमेह / चिनी रोग',
        category: 'Endocrine',
        triageUrgency: 'medium',
      ),
      ConditionCode(
        code: 'CA22',
        icd10: 'J44',
        name: 'Chronic obstructive pulmonary disease (COPD)',
        nepali: 'पुरानो दम (COPD)',
        category: 'Respiratory',
        triageUrgency: 'high',
      ),
      ConditionCode(
        code: 'CA23',
        icd10: 'J45',
        name: 'Bronchial asthma',
        nepali: 'दम',
        category: 'Respiratory',
        triageUrgency: 'high',
      ),
      ConditionCode(
        code: 'CA40',
        icd10: 'J18',
        name: 'Pneumonia',
        nepali: 'निमोनिया',
        category: 'Respiratory',
        triageUrgency: 'critical',
      ),
      ConditionCode(
        code: '1A36',
        icd10: 'A06',
        name: 'Amoebic dysentery',
        nepali: 'आउँ पर्ने',
        category: 'Infectious Gastrointestinal',
        triageUrgency: 'medium',
      ),
      ConditionCode(
        code: '1C30',
        icd10: 'A75.3',
        name: 'Scrub typhus',
        nepali: 'स्क्रब टाइफस',
        category: 'Vector-borne',
        triageUrgency: 'critical',
      ),
      ConditionCode(
        code: 'DA22',
        icd10: 'K21',
        name: 'Gastro-oesophageal reflux disease (GERD)',
        nepali: 'ग्यास्ट्रिक',
        category: 'Gastrointestinal',
        triageUrgency: 'low',
      ),
      ConditionCode(
        code: 'GC08',
        icd10: 'N39.0',
        name: 'Urinary tract infection (UTI)',
        nepali: 'पिसाब संक्रमण',
        category: 'Genitourinary',
        triageUrgency: 'medium',
      ),
    ]);

    _medicines.addAll(const [
      EssentialMedicine(
        name: 'Paracetamol',
        atc: 'N02BE01',
        defaultDosage: '500mg',
        defaultFrequency: 'Every 6-8 hours PRN',
        defaultDuration: '3-5 days',
        route: 'oral',
        category: 'Analgesic',
        nepaliUsage: 'ज्वरो र दुखाइको लागि',
      ),
      EssentialMedicine(
        name: 'Amoxicillin',
        atc: 'J01CA04',
        defaultDosage: '500mg',
        defaultFrequency: 'Three times daily (TID)',
        defaultDuration: '5-7 days',
        route: 'oral',
        category: 'Antibiotic',
        nepaliUsage: 'छाती र घाँटीको संक्रमणको लागि',
      ),
      EssentialMedicine(
        name: 'Metformin',
        atc: 'A10BA02',
        defaultDosage: '500mg',
        defaultFrequency: 'Twice daily with meals (BID)',
        defaultDuration: 'Continuous',
        route: 'oral',
        category: 'Antidiabetic',
        nepaliUsage: 'सुगर नियन्त्रणको लागि',
      ),
      EssentialMedicine(
        name: 'Amlodipine',
        atc: 'C08CA01',
        defaultDosage: '5mg',
        defaultFrequency: 'Once daily morning (OD)',
        defaultDuration: 'Continuous',
        route: 'oral',
        category: 'Antihypertensive',
        nepaliUsage: 'रक्तचाप नियन्त्रणको लागि',
      ),
      EssentialMedicine(
        name: 'Enalapril',
        atc: 'C09AA02',
        defaultDosage: '5mg',
        defaultFrequency: 'Once daily (OD)',
        defaultDuration: 'Continuous',
        route: 'oral',
        category: 'Antihypertensive',
        nepaliUsage: 'उच्च रक्तचाप नियन्त्रणको लागि',
      ),
      EssentialMedicine(
        name: 'Salbutamol Inhaler',
        atc: 'R03AC02',
        defaultDosage: '100mcg/puff',
        defaultFrequency: '2 puffs as needed (PRN)',
        defaultDuration: 'PRN',
        route: 'inhalation',
        category: 'Bronchodilator',
        nepaliUsage: 'दमको बेला सास फेर्न सजिलो बनाउन',
      ),
      EssentialMedicine(
        name: 'Omeprazole',
        atc: 'A02BC01',
        defaultDosage: '20mg',
        defaultFrequency: 'Once daily before breakfast (OD AC)',
        defaultDuration: '14 days',
        route: 'oral',
        category: 'Antacid / PPI',
        nepaliUsage: 'ग्यास्ट्रिकको लागि',
      ),
      EssentialMedicine(
        name: 'Oral Rehydration Salts (ORS)',
        atc: 'A07CA01',
        defaultDosage: '1 Sachet in 1 Litre boiled water',
        defaultFrequency: 'Sip after loose stool',
        defaultDuration: 'Until diarrhea stops',
        route: 'oral',
        category: 'Electrolyte',
        nepaliUsage: 'जीवनजल',
      ),
    ]);
  }

  /// Searches conditions by code, name, category, or Nepali name.
  List<ConditionCode> searchConditions(String query) {
    if (!_initialized) {
      _loadFallbackData();
      _initialized = true;
    }
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _conditions;

    return _conditions.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          c.icd10.toLowerCase().contains(q) ||
          c.nepali.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q);
    }).toList();
  }

  /// Searches medicines by name, ATC code, or category.
  List<EssentialMedicine> searchMedicines(String query) {
    if (!_initialized) {
      _loadFallbackData();
      _initialized = true;
    }
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _medicines;

    return _medicines.where((m) {
      return m.name.toLowerCase().contains(q) ||
          m.atc.toLowerCase().contains(q) ||
          m.category.toLowerCase().contains(q) ||
          m.nepaliUsage.toLowerCase().contains(q);
    }).toList();
  }
}
