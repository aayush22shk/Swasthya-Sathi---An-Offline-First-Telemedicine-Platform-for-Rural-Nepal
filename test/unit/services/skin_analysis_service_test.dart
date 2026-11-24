import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swasthyasathi/src/models/skin_analysis_model.dart';
import 'package:swasthyasathi/src/services/skin_analysis_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SkinAnalysisService & Model Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Performs 100% offline analysis on valid skin condition preset', () async {
      final service = SkinAnalysisService();

      final result = await service.analyzeImageOffline(
        imagePath: '/mock/path/tinea_test.jpg',
        classHint: 'tinea_ringworm',
      );

      expect(result.id, isNotNull);
      expect(result.predictedCondition, contains('Ringworm'));
      expect(result.confidenceScore, greaterThan(0.8));
      expect(result.isUncertain, isFalse);
      expect(result.topPredictions.length, equals(3));
      expect(result.topPredictions.first.classKey, equals('tinea_ringworm'));
      expect(result.topPredictions.first.confidencePct, greaterThan(80.0));
      expect(result.urgencyLevel, equals('medium'));
      expect(result.adviceEn.isNotEmpty, isTrue);
      expect(result.adviceNe.isNotEmpty, isTrue);
    });

    test('Rejects non-skin images via heuristic with descriptive clinical error', () async {
      final service = SkinAnalysisService();

      expect(
        () async => await service.analyzeImageOffline(
          imagePath: '/mock/path/chair.jpg',
          isInvalidNonSkin: true,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('NON_SKIN_REJECTED'),
        )),
      );
    });

    test('Persists offline analysis history to SharedPreferences', () async {
      final service = SkinAnalysisService();

      final res1 = await service.analyzeImageOffline(
        imagePath: '/mock/path/eczema.jpg',
        classHint: 'eczema',
      );

      final res2 = await service.analyzeImageOffline(
        imagePath: '/mock/path/psoriasis.jpg',
        classHint: 'psoriasis',
      );

      final history = await service.getOfflineHistory();
      expect(history.length, equals(2));
      expect(history.any((item) => item.id == res1.id), isTrue);
      expect(history.any((item) => item.id == res2.id), isTrue);
    });

    test('SkinAnalysisModel JSON serialization and deserialization integrity', () {
      final model = SkinAnalysisModel(
        id: 'test_uuid_123',
        patientId: 'patient_uuid_456',
        imageUrl: 'https://swasthyasathi.np/uploads/skin_1.jpg',
        predictedCondition: 'Scabies (Mite Infestation)',
        confidenceScore: 0.892,
        topPredictions: const [
          SkinPredictionItem(
            classKey: 'scabies',
            conditionName: 'Scabies (Mite Infestation)',
            nepaliName: 'लुतो (Scabies)',
            confidence: 0.892,
            confidencePct: 89.2,
          ),
          SkinPredictionItem(
            classKey: 'eczema',
            conditionName: 'Eczema',
            nepaliName: 'दाद',
            confidence: 0.08,
            confidencePct: 8.0,
          ),
        ],
        isUncertain: false,
        urgencyLevel: 'high',
        description: 'Mite infestation test description',
        symptoms: const ['Severe itching at night', 'Burrows on hands'],
        adviceEn: 'Wash bedding in hot water.',
        adviceNe: 'तातो पानीमा लुगा धुनुहोस्।',
        modelVersion: 'mobilenetv3_nepal_v1',
        isSharedWithDoctor: true,
        doctorId: 'doc_123',
        doctorName: 'Dr. Suresh Sharma',
        doctorNotes: 'Prescribed permethrin 5% lotion.',
        reviewedAt: DateTime.parse('2026-11-24T12:00:00Z'),
      );

      final json = model.toJson();
      final revived = SkinAnalysisModel.fromJson(json);

      expect(revived.id, equals('test_uuid_123'));
      expect(revived.patientId, equals('patient_uuid_456'));
      expect(revived.predictedCondition, equals('Scabies (Mite Infestation)'));
      expect(revived.confidenceScore, closeTo(0.892, 0.001));
      expect(revived.topPredictions.length, equals(2));
      expect(revived.topPredictions[0].classKey, equals('scabies'));
      expect(revived.topPredictions[0].nepaliName, equals('लुतो (Scabies)'));
      expect(revived.symptoms.length, equals(2));
      expect(revived.isSharedWithDoctor, isTrue);
      expect(revived.doctorName, equals('Dr. Suresh Sharma'));
      expect(revived.doctorNotes, equals('Prescribed permethrin 5% lotion.'));
      expect(revived.reviewedAt, isNotNull);
    });

    test('SkinAnalysisModel.fromCondition constructor creates valid fallback model', () {
      final sample = SkinAnalysisModel.fromCondition('Herpes Zoster (Shingles)');

      expect(sample.predictedCondition, equals('Herpes Zoster (Shingles)'));
      expect(sample.topPredictions.length, equals(1));
      expect(sample.topPredictions.first.classKey, equals('herpes_zoster_(shingles)'));
      expect(sample.urgencyLevel, equals('medium'));
      expect(sample.adviceNe.isNotEmpty, isTrue);
    });
  });
}
