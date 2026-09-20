enum UserRole {
  patient,
  doctor,
  healthSpecialist,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.healthSpecialist:
        return 'Health Specialist';
    }
  }

  String get description {
    switch (this) {
      case UserRole.patient:
        return 'Secure professional consultations with your physician or healthcare specialist from any location at any time.';
      case UserRole.doctor:
        return 'Connect with patients across Nepal, manage tele-consultations, and issue secure digital prescriptions.';
      case UserRole.healthSpecialist:
        return 'Provide specialized therapy, diagnostics, and community health services remotely and offline.';
    }
  }

  List<String> get bulletPoints {
    switch (this) {
      case UserRole.patient:
        return [
          'Consult your selected specialist directly.',
          'Avoid traffic and waiting times.',
          'No appointment required for urgent care.',
        ];
      case UserRole.doctor:
        return [
          'Direct remote patient consultations.',
          'Digital prescriptions & eSewa payouts.',
          'Flexible schedule & offline patient notes.',
        ];
      case UserRole.healthSpecialist:
        return [
          'Specialized patient therapy & care.',
          'Community health post coordination.',
          'Multi-disciplinary medical referrals.',
        ];
    }
  }
}
