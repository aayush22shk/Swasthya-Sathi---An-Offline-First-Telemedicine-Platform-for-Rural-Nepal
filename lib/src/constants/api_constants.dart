/// Central API configuration for SwasthyaSathi.
///
/// Change [baseUrl] to match your environment:
///   - Android Emulator  → http://10.0.2.2:5000
///   - Physical device   → http://[YOUR_LAN_IP]:5000   e.g. http://192.168.1.5:5000
///   - Production        → https://api.swasthyasathi.np
class ApiConstants {
  ApiConstants._();

  // ── Base URL ──────────────────────────────────────────────────────────────
  static const String baseUrl = 'http://10.10.9.233:5000/api/v1';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String registerPatient = '$baseUrl/auth/register/patient';
  static const String registerDoctor  = '$baseUrl/auth/register/doctor';
  static const String login           = '$baseUrl/auth/login';

  // ── Patients & Doctors (profile) ─────────────────────────────────────────
  static const String patientProfileMe = '$baseUrl/patients/me';
  static const String doctorProfileMe  = '$baseUrl/doctors/me';
  static String patientById(String id) => '$baseUrl/patients/$id';

  // ── Doctors (list + detail) ───────────────────────────────────────────────
  static const String doctors         = '$baseUrl/doctors';
  static String doctorById(String id) => '$baseUrl/doctors/$id';

  // ── Scheduling / Slots ────────────────────────────────────────────────────
  static String doctorAvailability(String doctorId) =>
      '$baseUrl/scheduling/doctors/$doctorId/availability';
  static String doctorSlots(String doctorId) =>
      '$baseUrl/scheduling/doctors/$doctorId/slots';

  // ── Masters ───────────────────────────────────────────────────────────────
  static const String specializations = '$baseUrl/masters/specializations';

  // ── Appointments ──────────────────────────────────────────────────────────
  static const String appointments           = '$baseUrl/appointments';
  static String appointmentById(String id)   => '$baseUrl/appointments/$id';
  static String appointmentStatus(String id) => '$baseUrl/appointments/$id/status';

  // ── Payments ──────────────────────────────────────────────────────────────
  static const String paymentsInitiate   = '$baseUrl/payments/initiate';
  static String paymentVerify(String id) => '$baseUrl/payments/$id/verify';
  static String paymentById(String id)   => '$baseUrl/payments/$id';

  // ── Consultations ─────────────────────────────────────────────────────────
  static const String consultations             = '$baseUrl/consultations';
  static String consultationById(String id)     => '$baseUrl/consultations/$id';
  static String consultationMessages(String id) => '$baseUrl/consultations/$id/messages';

  // ── Doctor Dashboard (authenticated doctor-specific) ──────────────────────
  static const String doctorMyPatients      = '$baseUrl/doctors/me/patients';
  static String doctorMyPatientById(String patientId) =>
      '$baseUrl/doctors/me/patients/$patientId';
  static const String doctorMyPrescriptions = '$baseUrl/doctors/me/prescriptions';
  static const String doctorMyConversations = '$baseUrl/doctors/me/conversations';

  // ── Prescriptions ─────────────────────────────────────────────────────────
  static const String prescriptions                       = '$baseUrl/prescriptions';
  static String prescriptionById(String id)               => '$baseUrl/prescriptions/$id';
  static String prescriptionsByPatient(String patientId)  =>
      '$baseUrl/prescriptions/patient/$patientId';

  // ── Follow-Ups ────────────────────────────────────────────────────────────
  static const String followUps           = '$baseUrl/follow-ups';
  static const String followUpsByDoctor   = '$baseUrl/follow-ups/doctor/me';
  static const String followUpsByPatient  = '$baseUrl/follow-ups/patient/me';
  static String followUpStatus(String id) => '$baseUrl/follow-ups/$id/status';

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
