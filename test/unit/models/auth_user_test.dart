// test/unit/models/auth_user_test.dart
//
// Unit Tests — AuthUser Model
// Tests the AuthUser data model: JSON deserialization, role helpers,
// and edge-case null handling.
//
// Run: flutter test test/unit/models/auth_user_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:swasthyasathi/src/models/auth_user.dart';

void main() {
  // ─── Fixtures ───────────────────────────────────────────────────────────────

  /// Simulates the exact JSON envelope the SwasthyaSathi backend returns
  /// after a successful POST /api/v1/auth/login or /register.
  final Map<String, dynamic> patientApiResponse = {
    'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test_token',
    'user': {
      'id': 'uuid-patient-001',
      'phone': '9841234567',
      'email': 'ram@example.com',
      'role': 'patient',
      'status': 'active',
      'preferred_language': 'ne',
    },
    'profile': {
      'id': 'uuid-patient-profile-001',
      'full_name': 'Ram Prasad Sharma',
      'gender': 'male',
      'blood_group': 'B+',
    },
  };

  final Map<String, dynamic> doctorApiResponse = {
    'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.doctor_token',
    'user': {
      'id': 'uuid-doctor-001',
      'phone': '9851234567',
      'email': 'dr.sita@hospital.np',
      'role': 'doctor',
      'status': 'active',
    },
    'profile': {
      'id': 'uuid-doctor-profile-001',
      'full_name': 'Dr. Sita Devi Thapa',
      'nmc_status': 'verified',
      'consultation_fee': '1500.00',
    },
  };

  // ─── Group: AuthUser.fromApiResponse ────────────────────────────────────────

  group('AuthUser.fromApiResponse —', () {
    test('parses patient response correctly', () {
      final user = AuthUser.fromApiResponse(patientApiResponse);

      expect(user.id, equals('uuid-patient-001'));
      expect(user.phone, equals('9841234567'));
      expect(user.email, equals('ram@example.com'));
      expect(user.role, equals('patient'));
      expect(user.token, startsWith('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'));
      expect(user.fullName, equals('Ram Prasad Sharma'));
    });

    test('parses doctor response correctly', () {
      final user = AuthUser.fromApiResponse(doctorApiResponse);

      expect(user.id, equals('uuid-doctor-001'));
      expect(user.phone, equals('9851234567'));
      expect(user.email, equals('dr.sita@hospital.np'));
      expect(user.role, equals('doctor'));
      expect(user.fullName, equals('Dr. Sita Devi Thapa'));
    });

    test('handles missing optional fields gracefully', () {
      final minimalResponse = {
        'token': 'some.jwt.token',
        'user': {
          'id': 'uuid-minimal-001',
          'phone': '9800000000',
          'role': 'patient',
        },
        'profile': {},
      };

      final user = AuthUser.fromApiResponse(minimalResponse);

      expect(user.id, equals('uuid-minimal-001'));
      expect(user.email, isNull);    // optional
      expect(user.fullName, isNull); // optional
      expect(user.phone, equals('9800000000'));
    });

    test('handles completely missing user and profile keys', () {
      // Backend error response that lacks the envelope fields
      final brokenResponse = {'token': 'xyz.abc.def'};

      final user = AuthUser.fromApiResponse(brokenResponse);

      // Should not throw — gracefully defaults
      expect(user.id, equals(''));
      expect(user.phone, equals(''));
      expect(user.role, equals('patient')); // defaults to 'patient'
      expect(user.fullName, isNull);
    });

    test('converts non-string id fields to string', () {
      final responseWithNumericId = {
        'token': 'test.token',
        'user': {'id': 12345, 'phone': '9800000001', 'role': 'patient'},
        'profile': {'full_name': 'Test User'},
      };

      final user = AuthUser.fromApiResponse(responseWithNumericId);

      expect(user.id, equals('12345')); // converted via .toString()
    });
  });

  // ─── Group: Role Helpers ────────────────────────────────────────────────────

  group('AuthUser role helpers —', () {
    test('isPatient returns true for patient role', () {
      final user = AuthUser.fromApiResponse(patientApiResponse);
      expect(user.isPatient, isTrue);
      expect(user.isDoctor, isFalse);
    });

    test('isDoctor returns true for doctor role', () {
      final user = AuthUser.fromApiResponse(doctorApiResponse);
      expect(user.isDoctor, isTrue);
      expect(user.isPatient, isFalse);
    });

    test('isPatient false for unknown role', () {
      final user = AuthUser(
        id: 'admin-001',
        phone: '9800000099',
        role: 'admin',
        token: 'admin.token',
      );
      expect(user.isPatient, isFalse);
      expect(user.isDoctor, isFalse);
    });
  });

  // ─── Group: Const Constructor ────────────────────────────────────────────────

  group('AuthUser const constructor —', () {
    test('creates user with required fields', () {
      const user = AuthUser(
        id: 'test-id',
        phone: '9811111111',
        role: 'patient',
        token: 'test.jwt.token',
      );

      expect(user.id, equals('test-id'));
      expect(user.token, equals('test.jwt.token'));
      expect(user.email, isNull);
      expect(user.fullName, isNull);
    });

    test('toString contains key fields', () {
      const user = AuthUser(
        id: 'u1',
        phone: '9811111111',
        role: 'patient',
        token: 'tok',
        fullName: 'Test Patient',
      );

      final str = user.toString();
      expect(str, contains('patient'));
      expect(str, contains('Test Patient'));
    });
  });
}
