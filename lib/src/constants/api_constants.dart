import 'package:flutter/foundation.dart' show kIsWeb;

/// Central API configuration for SwasthyaSathi.
///
/// Automatically switches between:
///   - Web (Browser)     → http://localhost:5000/api/v1
///   - Mobile / LAN      → http://10.10.9.4:5000/api/v1 (or local LAN IP)
///   - Production        → https://api.swasthyasathi.np
class ApiConstants {
  ApiConstants._();

  // ── Base URL ──────────────────────────────────────────────────────────────
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    return 'http://10.10.9.4:5000/api/v1';
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  static String get registerPatient => '$baseUrl/auth/register/patient';
  static String get registerDoctor  => '$baseUrl/auth/register/doctor';
  static String get login           => '$baseUrl/auth/login';

  // ── Patients & Doctors (profile) ─────────────────────────────────────────
  static String get patientProfileMe => '$baseUrl/patients/me';
  static String get doctorProfileMe  => '$baseUrl/doctors/me';
  static String patientById(String id) => '$baseUrl/patients/$id';

  // ── Doctors (list + detail) ───────────────────────────────────────────────
  static String get doctors         => '$baseUrl/doctors';
  static String doctorById(String id) => '$baseUrl/doctors/$id';

  // ── Scheduling / Slots ────────────────────────────────────────────────────
  static String doctorAvailability(String doctorId) =>
      '$baseUrl/scheduling/doctors/$doctorId/availability';
  static String doctorSlots(String doctorId) =>
      '$baseUrl/scheduling/doctors/$doctorId/slots';

  // ── Masters ───────────────────────────────────────────────────────────────
  static String get specializations => '$baseUrl/masters/specializations';

  // ── Appointments ──────────────────────────────────────────────────────────
  static String get appointments           => '$baseUrl/appointments';
  static String appointmentById(String id)   => '$baseUrl/appointments/$id';
  static String appointmentStatus(String id) => '$baseUrl/appointments/$id/status';

  // ── Payments ──────────────────────────────────────────────────────────────
  static String get paymentsInitiate   => '$baseUrl/payments/initiate';
  static String paymentVerify(String id) => '$baseUrl/payments/$id/verify';
  static String paymentById(String id)   => '$baseUrl/payments/$id';

  // ── Consultations ─────────────────────────────────────────────────────────
  static String get consultations             => '$baseUrl/consultations';
  static String consultationById(String id)     => '$baseUrl/consultations/$id';
  static String consultationMessages(String id) => '$baseUrl/consultations/$id/messages';

  // ── Doctor Dashboard (authenticated doctor-specific) ──────────────────────
  static String get doctorMyPatients      => '$baseUrl/doctors/me/patients';
  static String doctorMyPatientById(String patientId) =>
      '$baseUrl/doctors/me/patients/$patientId';
  static String get doctorMyPrescriptions => '$baseUrl/doctors/me/prescriptions';
  static String get doctorMyConversations => '$baseUrl/doctors/me/conversations';

  // ── Prescriptions ─────────────────────────────────────────────────────────
  static String get prescriptions                       => '$baseUrl/prescriptions';
  static String prescriptionById(String id)               => '$baseUrl/prescriptions/$id';
  static String prescriptionsByPatient(String patientId)  =>
      '$baseUrl/prescriptions/patient/$patientId';

  // ── Follow-Ups ────────────────────────────────────────────────────────────
  static String get followUps           => '$baseUrl/follow-ups';
  static String get followUpsByDoctor   => '$baseUrl/follow-ups/doctor/me';
  static String get followUpsByPatient  => '$baseUrl/follow-ups/patient/me';
  static String followUpStatus(String id) => '$baseUrl/follow-ups/$id/status';

  // ── Health Data (Blood Pressure, Glucose, Weight, Symptoms, Conditions, Medications) ──
  static String get healthVitals      => '$baseUrl/health/vitals';
  static String get healthBP          => '$baseUrl/health/blood-pressure';
  static String get healthGlucose     => '$baseUrl/health/glucose';
  static String get healthWeight      => '$baseUrl/health/weight';
  static String get healthSymptoms    => '$baseUrl/health/symptoms';
  static String get healthConditions  => '$baseUrl/health/conditions';
  static String get healthMedications => '$baseUrl/health/medications';
  static String healthConditionById(String id) => '$baseUrl/health/conditions/$id';
  static String healthMedicationById(String id) => '$baseUrl/health/medications/$id';

  // ── Health Analysis ────────────────────────────────────────────────────────
  static String get healthAnalysisSummary => '$baseUrl/health-analysis/summary';
  static String get healthAnalysisHistory => '$baseUrl/health-analysis/history';
  static String healthAnalysisById(String id) => '$baseUrl/health-analysis/$id';

  // ── AI ────────────────────────────────────────────────────────────────────
  static String get aiExplain           => '$baseUrl/ai/explain';
  static String get aiConversations     => '$baseUrl/ai/conversations';
  static String aiConversationMessages(String id) => '$baseUrl/ai/conversations/$id/messages';

  // ── Shared-prefs keys ─────────────────────────────────────────────────────
  static const String kToken       = 'auth_token';
  static const String kUserId      = 'auth_user_id';
  static const String kUserRole    = 'auth_user_role';
  static const String kUserPhone   = 'auth_user_phone';
  static const String kUserEmail   = 'auth_user_email';
  static const String kFullName    = 'auth_full_name';
  static const String kGender      = 'auth_gender';
  static const String kDob         = 'auth_dob';
  static const String kBloodGroup  = 'auth_blood_group';
  static const String kAddress     = 'auth_address';
  static const String kAppLanguage = 'auth_app_language';
}
