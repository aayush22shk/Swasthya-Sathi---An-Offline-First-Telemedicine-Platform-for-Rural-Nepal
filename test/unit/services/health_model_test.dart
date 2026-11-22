// test/unit/services/health_model_test.dart
//
// Unit Tests — Health Data Models (BPReading, GlucoseReading, WeightReading)
// Tests clinical BP classification (ACC/AHA 2017), display formatters,
// and JSON deserialization edge cases.
//
// Run: flutter test test/unit/services/health_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:swasthyasathi/src/services/health_service.dart';

void main() {
  // ─── Group: BPReading — Clinical Classification (ACC/AHA 2017) ───────────────

  group('BPReading.category — ACC/AHA 2017 classification —', () {
    BPReading bp(int systolic, int diastolic) => BPReading(
          id: 'test',
          systolic: systolic,
          diastolic: diastolic,
          measuredAt: DateTime.now(),
          measurementContext: 'manual',
        );

    // NORMAL: systolic < 120 AND diastolic < 80
    test('120/80 is Normal', () {
      expect(bp(119, 79).category, equals('Normal'));
    });

    test('115/75 is Normal (ideal reading)', () {
      expect(bp(115, 75).category, equals('Normal'));
    });

    // ELEVATED: systolic 120–129 AND diastolic < 80
    test('125/78 is Elevated', () {
      expect(bp(125, 78).category, equals('Elevated'));
    });

    test('129/79 is Elevated (upper boundary)', () {
      expect(bp(129, 79).category, equals('Elevated'));
    });

    test('120/80 boundary — systolic elevated but diastolic at 80 → Stage 1', () {
      // systolic = 120 but diastolic = 80 → Stage 1 condition kicks in
      expect(bp(120, 80).category, equals('High (Stage 1)'));
    });

    // HIGH STAGE 1: systolic 130–139 OR diastolic 80–89
    test('135/85 is High (Stage 1)', () {
      expect(bp(135, 85).category, equals('High (Stage 1)'));
    });

    test('130/80 is High (Stage 1) — at the boundary', () {
      expect(bp(130, 80).category, equals('High (Stage 1)'));
    });

    test('110/85 is High (Stage 1) — triggered by diastolic alone', () {
      expect(bp(110, 85).category, equals('High (Stage 1)'));
    });

    // HIGH STAGE 2: systolic >= 140 OR diastolic >= 90
    test('145/92 is High (Stage 2)', () {
      expect(bp(145, 92).category, equals('High (Stage 2)'));
    });

    test('140/90 is High (Stage 2) — at the boundary', () {
      expect(bp(140, 90).category, equals('High (Stage 2)'));
    });

    test('160/95 is High (Stage 2)', () {
      expect(bp(160, 95).category, equals('High (Stage 2)'));
    });

    // HYPERTENSIVE CRISIS: systolic >= 180 OR diastolic >= 120
    test('180/120 is Crisis — dual boundary trigger', () {
      expect(bp(180, 120).category, equals('Crisis'));
    });

    test('200/130 is Crisis — extreme values', () {
      expect(bp(200, 130).category, equals('Crisis'));
    });

    test('170/122 is Crisis — triggered by diastolic alone', () {
      expect(bp(170, 122).category, equals('Crisis'));
    });

    test('182/85 is Crisis — triggered by systolic alone', () {
      expect(bp(182, 85).category, equals('Crisis'));
    });
  });

  // ─── Group: BPReading.bpLabel ───────────────────────────────────────────────

  group('BPReading.bpLabel —', () {
    test('formats as "systolic / diastolic"', () {
      final reading = BPReading(
        id: 'r1',
        systolic: 120,
        diastolic: 80,
        measuredAt: DateTime.now(),
        measurementContext: 'manual',
      );
      expect(reading.bpLabel, equals('120 / 80'));
    });
  });

  // ─── Group: BPReading.fromJson ───────────────────────────────────────────────

  group('BPReading.fromJson —', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'bp-001',
        'systolic': 130,
        'diastolic': 85,
        'heart_rate': 72,
        'measured_at': '2026-10-01T08:00:00.000Z',
        'measurement_context': 'morning',
      };

      final r = BPReading.fromJson(json);

      expect(r.id, equals('bp-001'));
      expect(r.systolic, equals(130));
      expect(r.diastolic, equals(85));
      expect(r.heartRate, equals(72));
      expect(r.measurementContext, equals('morning'));
      expect(r.measuredAt.year, equals(2026));
    });

    test('heart_rate is null when not in JSON', () {
      final json = {
        'id': 'bp-002',
        'systolic': 120,
        'diastolic': 80,
        'measured_at': '2026-10-01T08:00:00.000Z',
        'measurement_context': 'manual',
      };
      final r = BPReading.fromJson(json);
      expect(r.heartRate, isNull);
    });

    test('defaults to "manual" measurement_context when missing', () {
      final json = {
        'id': 'bp-003',
        'systolic': 115,
        'diastolic': 75,
        'measured_at': '2026-10-01T08:00:00.000Z',
      };
      final r = BPReading.fromJson(json);
      expect(r.measurementContext, equals('manual'));
    });

    test('defaults systolic/diastolic to 0 when missing', () {
      final json = {
        'id': 'bp-004',
        'measured_at': '2026-10-01T08:00:00.000Z',
        'measurement_context': 'manual',
      };
      final r = BPReading.fromJson(json);
      expect(r.systolic, equals(0));
      expect(r.diastolic, equals(0));
    });
  });

  // ─── Group: BPReading.toJson ────────────────────────────────────────────────

  group('BPReading.toJson —', () {
    test('serializes required fields', () {
      final now = DateTime(2026, 10, 14, 9, 30);
      final r = BPReading(
        id: 'r1',
        systolic: 120,
        diastolic: 80,
        measuredAt: now,
        measurementContext: 'morning',
      );
      final json = r.toJson();
      expect(json['systolic'], equals(120));
      expect(json['diastolic'], equals(80));
      expect(json['measurement_context'], equals('morning'));
      expect(json.containsKey('heart_rate'), isFalse); // null → excluded
    });

    test('includes heart_rate when set', () {
      final r = BPReading(
        id: 'r2',
        systolic: 118,
        diastolic: 76,
        heartRate: 68,
        measuredAt: DateTime.now(),
        measurementContext: 'manual',
      );
      final json = r.toJson();
      expect(json['heart_rate'], equals(68));
    });
  });

  // ─── Group: GlucoseReading ───────────────────────────────────────────────────

  group('GlucoseReading.fromJson —', () {
    test('parses full glucose reading', () {
      final json = {
        'id': 'gl-001',
        'glucose_value': '126.5',
        'unit': 'mg/dl',
        'measurement_type': 'fasting',
        'measured_at': '2026-09-15T07:00:00.000Z',
      };
      final r = GlucoseReading.fromJson(json);
      expect(r.glucoseValue, closeTo(126.5, 0.01));
      expect(r.unit, equals('mg/dl'));
      expect(r.measurementType, equals('fasting'));
    });

    test('parses glucose_value from int (no decimal)', () {
      final json = {
        'id': 'gl-002',
        'glucose_value': 100,
        'unit': 'mg/dl',
        'measurement_type': 'random',
        'measured_at': '2026-09-15T14:00:00.000Z',
      };
      final r = GlucoseReading.fromJson(json);
      expect(r.glucoseValue, equals(100.0));
    });

    test('defaults to 0 when glucose_value is missing', () {
      final json = {
        'id': 'gl-003',
        'unit': 'mg/dl',
        'measurement_type': 'random',
        'measured_at': '2026-09-15T14:00:00.000Z',
      };
      final r = GlucoseReading.fromJson(json);
      expect(r.glucoseValue, equals(0.0));
    });
  });

  group('GlucoseReading.typeLabel —', () {
    GlucoseReading glWith(String type) => GlucoseReading(
          id: 'g1',
          glucoseValue: 100,
          unit: 'mg/dl',
          measurementType: type,
          measuredAt: DateTime.now(),
        );

    test('"fasting" → "Fasting"', () {
      expect(glWith('fasting').typeLabel, equals('Fasting'));
    });

    test('"before_meal" → "Before Meal"', () {
      expect(glWith('before_meal').typeLabel, equals('Before Meal'));
    });

    test('"after_meal" → "After Meal"', () {
      expect(glWith('after_meal').typeLabel, equals('After Meal'));
    });

    test('"bedtime" → "Bedtime"', () {
      expect(glWith('bedtime').typeLabel, equals('Bedtime'));
    });

    test('unknown type → "Random"', () {
      expect(glWith('something_else').typeLabel, equals('Random'));
    });
  });

  group('GlucoseReading.displayValue —', () {
    test('formats value with unit', () {
      final r = GlucoseReading(
        id: 'g1',
        glucoseValue: 126.7,
        unit: 'mg/dl',
        measurementType: 'fasting',
        measuredAt: DateTime.now(),
      );
      expect(r.displayValue, equals('127 mg/dl')); // toStringAsFixed(0)
    });
  });

  // ─── Group: WeightReading.fromJson ──────────────────────────────────────────

  group('WeightReading.fromJson —', () {
    test('parses weight correctly from string', () {
      final json = {
        'id': 'w-001',
        'weight_kg': '68.5',
        'measured_at': '2026-10-01T07:00:00.000Z',
      };
      final r = WeightReading.fromJson(json);
      expect(r.weightKg, closeTo(68.5, 0.01));
    });

    test('parses weight correctly from number', () {
      final json = {
        'id': 'w-002',
        'weight_kg': 72,
        'measured_at': '2026-10-01T07:00:00.000Z',
      };
      final r = WeightReading.fromJson(json);
      expect(r.weightKg, equals(72.0));
    });

    test('defaults weight to 0 when missing', () {
      final json = {
        'id': 'w-003',
        'measured_at': '2026-10-01T07:00:00.000Z',
      };
      final r = WeightReading.fromJson(json);
      expect(r.weightKg, equals(0.0));
    });
  });
}
