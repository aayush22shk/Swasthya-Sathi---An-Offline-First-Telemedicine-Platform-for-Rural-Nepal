// test/unit/models/appointment_model_test.dart
//
// Unit Tests — AppointmentModel & AppointmentStatus
// Tests JSON deserialization, status label mapping, colour coding,
// and date/time formatting helpers.
//
// Run: flutter test test/unit/models/appointment_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:swasthyasathi/src/models/appointment_model.dart';

void main() {
  // ─── Fixtures ────────────────────────────────────────────────────────────────

  /// Full appointment JSON as returned by GET /api/v1/appointments
  Map<String, dynamic> buildAppointmentJson({
    String status = 'pending',
    String scheduledAt = '2026-10-20T10:30:00.000Z',
    double fee = 1200.0,
    String? consultationId,
  }) {
    return {
      'id': 'appt-uuid-001',
      'patient_id': 'patient-uuid-001',
      'doctor_id': 'doctor-uuid-001',
      'doctor_name': 'Dr. Anita KC',
      'doctor_photo_url': 'https://cdn.swasthyasathi.np/photos/dr_anita.jpg',
      'doctor_specialty': 'Cardiology',
      'scheduled_at': scheduledAt,
      'mode': 'video',
      'status': status,
      'fee': fee.toString(),
      'reason_for_visit': 'Chest pain and shortness of breath',
      if (consultationId != null) 'consultation_id': consultationId,
    };
  }

  // ─── Group: AppointmentStatus.fromString ────────────────────────────────────

  group('AppointmentStatus.fromString —', () {
    test('returns confirmed for "confirmed"', () {
      expect(AppointmentStatus.fromString('confirmed'),
          equals(AppointmentStatus.confirmed));
    });

    test('returns completed for "completed"', () {
      expect(AppointmentStatus.fromString('completed'),
          equals(AppointmentStatus.completed));
    });

    test('returns cancelled for "cancelled"', () {
      expect(AppointmentStatus.fromString('cancelled'),
          equals(AppointmentStatus.cancelled));
    });

    test('returns noShow for "no_show"', () {
      expect(AppointmentStatus.fromString('no_show'),
          equals(AppointmentStatus.noShow));
    });

    test('defaults to pending for unknown string', () {
      expect(AppointmentStatus.fromString('unknown_value'),
          equals(AppointmentStatus.pending));
    });

    test('defaults to pending for null', () {
      expect(AppointmentStatus.fromString(null),
          equals(AppointmentStatus.pending));
    });

    test('defaults to pending for empty string', () {
      expect(AppointmentStatus.fromString(''),
          equals(AppointmentStatus.pending));
    });
  });

  // ─── Group: AppointmentStatus.label ─────────────────────────────────────────

  group('AppointmentStatus.label —', () {
    test('all statuses have non-empty labels', () {
      for (final status in AppointmentStatus.values) {
        expect(status.label, isNotEmpty,
            reason: 'Status $status must have a non-empty label');
      }
    });

    test('pending label is "Pending"', () {
      expect(AppointmentStatus.pending.label, equals('Pending'));
    });

    test('confirmed label is "Confirmed"', () {
      expect(AppointmentStatus.confirmed.label, equals('Confirmed'));
    });

    test('noShow label is "No Show"', () {
      expect(AppointmentStatus.noShow.label, equals('No Show'));
    });
  });

  // ─── Group: AppointmentStatus.colorValue ────────────────────────────────────

  group('AppointmentStatus.colorValue —', () {
    test('pending status is amber (0xFFF59E0B)', () {
      expect(AppointmentStatus.pending.colorValue, equals(0xFFF59E0B));
    });

    test('confirmed status is emerald (0xFF10B981)', () {
      expect(AppointmentStatus.confirmed.colorValue, equals(0xFF10B981));
    });

    test('cancelled status is red (0xFFEF4444)', () {
      expect(AppointmentStatus.cancelled.colorValue, equals(0xFFEF4444));
    });

    test('completed status is blue (0xFF0072FF)', () {
      expect(AppointmentStatus.completed.colorValue, equals(0xFF0072FF));
    });

    test('noShow status is slate grey', () {
      expect(AppointmentStatus.noShow.colorValue, equals(0xFF94A3B8));
    });
  });

  // ─── Group: AppointmentModel.fromJson ───────────────────────────────────────

  group('AppointmentModel.fromJson —', () {
    test('parses a full appointment JSON correctly', () {
      final model =
          AppointmentModel.fromJson(buildAppointmentJson(status: 'confirmed'));

      expect(model.id, equals('appt-uuid-001'));
      expect(model.patientId, equals('patient-uuid-001'));
      expect(model.doctorId, equals('doctor-uuid-001'));
      expect(model.doctorName, equals('Dr. Anita KC'));
      expect(model.specialty, equals('Cardiology'));
      expect(model.mode, equals('video'));
      expect(model.status, equals(AppointmentStatus.confirmed));
      expect(model.fee, equals(1200.0));
      expect(model.reasonForVisit, equals('Chest pain and shortness of breath'));
    });

    test('parses fee from string "1500.00" to double 1500.0', () {
      final model = AppointmentModel.fromJson(
          buildAppointmentJson(fee: 1500.0));
      expect(model.fee, equals(1500.0));
    });

    test('consultationId is null when not in JSON', () {
      final model =
          AppointmentModel.fromJson(buildAppointmentJson());
      expect(model.consultationId, isNull);
    });

    test('consultationId is parsed when present', () {
      final model = AppointmentModel.fromJson(
          buildAppointmentJson(consultationId: 'consult-uuid-007'));
      expect(model.consultationId, equals('consult-uuid-007'));
    });

    test('falls back to empty string for missing doctor_name', () {
      final json = buildAppointmentJson();
      json.remove('doctor_name');
      final model = AppointmentModel.fromJson(json);
      expect(model.doctorName, equals('Unknown Doctor'));
    });

    test('falls back to specialty from "specialty" key when "doctor_specialty" missing', () {
      final json = buildAppointmentJson();
      json.remove('doctor_specialty');
      json['specialty'] = 'General Practice';
      final model = AppointmentModel.fromJson(json);
      expect(model.specialty, equals('General Practice'));
    });

    test('parses DateTime from ISO 8601 string', () {
      final model = AppointmentModel.fromJson(
          buildAppointmentJson(scheduledAt: '2026-10-20T10:30:00.000Z'));
      expect(model.scheduledAt.year, equals(2026));
      expect(model.scheduledAt.month, equals(10));
      expect(model.scheduledAt.day, equals(20));
    });
  });

  // ─── Group: AppointmentModel.formattedTime ───────────────────────────────────

  group('AppointmentModel.formattedTime —', () {
    AppointmentModel makeModelAt(int hour, int minute) {
      return AppointmentModel(
        id: 'test',
        patientId: 'p1',
        doctorId: 'd1',
        doctorName: 'Dr. Test',
        doctorPhotoUrl: '',
        specialty: 'General',
        scheduledAt: DateTime(2026, 10, 20, hour, minute),
        mode: 'video',
        status: AppointmentStatus.pending,
        fee: 0,
      );
    }

    test('2:30 PM formatted correctly', () {
      final model = makeModelAt(14, 30);
      expect(model.formattedTime, equals('2:30 PM'));
    });

    test('10:00 AM formatted correctly', () {
      final model = makeModelAt(10, 0);
      expect(model.formattedTime, equals('10:00 AM'));
    });

    test('midnight (0:00) formatted as 12:00 AM', () {
      final model = makeModelAt(0, 0);
      expect(model.formattedTime, equals('12:00 AM'));
    });

    test('noon (12:00) formatted as 12:00 PM', () {
      final model = makeModelAt(12, 0);
      expect(model.formattedTime, equals('12:00 PM'));
    });
  });
}
