/// Central API configuration for SwasthyaSathi.
///
/// Change [baseUrl] to match your environment:
///   - Android Emulator  → http://10.0.2.2:5000
///   - Physical device   → http://[YOUR_LAN_IP]:5000   e.g. http://192.168.1.5:5000
///   - Production        → https://api.swasthyasathi.np
class ApiConstants {
  ApiConstants._();

  // ── Base URL ──────────────────────────────────────────────────────────────
  static const String baseUrl = 'http://192.168.1.82:5000/api/v1';

  // ── Auth & Profile endpoints ──────────────────────────────────────────────
  static const String registerPatient  = '$baseUrl/auth/register/patient';
  static const String registerDoctor   = '$baseUrl/auth/register/doctor';
  static const String login            = '$baseUrl/auth/login';
  static const String patientProfileMe = '$baseUrl/patients/me';
  static const String doctorProfileMe  = '$baseUrl/doctors/me';
  static String patientById(String id) => '$baseUrl/patients/$id';
  static String doctorById(String id)  => '$baseUrl/doctors/$id';

  // ── Shared-prefs keys ─────────────────────────────────────────────────────
  static const String kToken          = 'auth_token';
  static const String kUserId         = 'auth_user_id';
  static const String kUserRole       = 'auth_user_role';
  static const String kUserPhone      = 'auth_user_phone';
  static const String kUserEmail      = 'auth_user_email';
  static const String kFullName       = 'auth_full_name';
  static const String kGender         = 'auth_gender';
  static const String kDob            = 'auth_dob';
  static const String kBloodGroup     = 'auth_blood_group';
  static const String kAddress        = 'auth_address';
  static const String kAppLanguage    = 'auth_app_language';
}

