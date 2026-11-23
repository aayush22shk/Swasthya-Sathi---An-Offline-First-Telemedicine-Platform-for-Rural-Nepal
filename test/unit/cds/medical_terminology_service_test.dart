import 'package:flutter_test/flutter_test.dart';
import 'package:swasthyasathi/src/cds/medical_terminology_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MedicalTerminologyService Tests', () {
    final service = MedicalTerminologyService();

    test('Initializes with fallback or bundled dataset', () async {
      await service.initialize();
      expect(service.conditions.isNotEmpty, isTrue);
      expect(service.medicines.isNotEmpty, isTrue);
    });

    test('Searches conditions by ICD-11 code (e.g. CA22 for COPD)', () {
      final results = service.searchConditions('CA22');
      expect(results.any((c) => c.name.toLowerCase().contains('chronic obstructive') || c.code == 'CA22'), isTrue);
    });

    test('Searches conditions by English name (e.g. Hypertension)', () {
      final results = service.searchConditions('hypertension');
      expect(results.any((c) => c.code == 'BA00'), isTrue);
    });

    test('Searches conditions by Nepali keywords (e.g. दम or खोकी)', () {
      final results = service.searchConditions('दम');
      expect(results.isNotEmpty, isTrue);
    });

    test('Searches medicines by name (e.g. Metformin)', () {
      final results = service.searchMedicines('Metformin');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.atc, equals('A10BA02'));
    });

    test('Searches medicines by ATC code (e.g. N02BE01 for Paracetamol)', () {
      final results = service.searchMedicines('N02BE01');
      expect(results.any((m) => m.name.toLowerCase().contains('paracetamol')), isTrue);
    });

    test('Searches medicines by category (e.g. Antihypertensive)', () {
      final results = service.searchMedicines('Antihypertensive');
      expect(results.length, greaterThanOrEqualTo(2));
    });
  });
}
