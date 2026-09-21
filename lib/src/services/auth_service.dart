import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/auth_user.dart';

/// Singleton auth service.
///
/// Usage anywhere in the app:
///   final user = AuthService().currentUser;          // nullable
///   AuthService().userNotifier                        // ValueNotifier to listen to
///   await AuthService().registerPatient({...})
///   await AuthService().login({...})
///   await AuthService().logout()
class AuthService {
  // ── Singleton plumbing ───────────────────────────────────────────────────
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  // ── State ─────────────────────────────────────────────────────────────────
  final ValueNotifier<AuthUser?> userNotifier = ValueNotifier(null);
  AuthUser? get currentUser => userNotifier.value;
  bool      get isLoggedIn  => currentUser != null;

  // ── Session persistence ───────────────────────────────────────────────────

  /// Call once at app startup (before runApp) to restore a previous session.
  Future<void> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConstants.kToken);
    if (token == null || token.isEmpty) return;

    userNotifier.value = AuthUser(
      id:       prefs.getString(ApiConstants.kUserId)    ?? '',
      phone:    prefs.getString(ApiConstants.kUserPhone) ?? '',
      email:    prefs.getString(ApiConstants.kUserEmail),
      role:     prefs.getString(ApiConstants.kUserRole)  ?? 'patient',
      token:    token,
      fullName: prefs.getString(ApiConstants.kFullName),
    );
  }

  Future<void> _persistUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.kToken,     user.token);
    await prefs.setString(ApiConstants.kUserId,    user.id);
    await prefs.setString(ApiConstants.kUserRole,  user.role);
    await prefs.setString(ApiConstants.kUserPhone, user.phone);
    if (user.email    != null) await prefs.setString(ApiConstants.kUserEmail, user.email!);
    if (user.fullName != null) await prefs.setString(ApiConstants.kFullName,  user.fullName!);
  }

  Future<void> updateUserSession({
    String? fullName,
    String? phone,
    String? email,
  }) async {
    final current = currentUser;
    if (current == null) return;
    final updated = AuthUser(
      id: current.id,
      phone: phone ?? current.phone,
      email: email ?? current.email,
      role: current.role,
      token: current.token,
      fullName: fullName ?? current.fullName,
    );
    userNotifier.value = updated;
    await _persistUser(updated);
  }


  Future<void> _clearPersistedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.kToken);
    await prefs.remove(ApiConstants.kUserId);
    await prefs.remove(ApiConstants.kUserRole);
    await prefs.remove(ApiConstants.kUserPhone);
    await prefs.remove(ApiConstants.kUserEmail);
    await prefs.remove(ApiConstants.kFullName);
  }

  // ── Network helpers ───────────────────────────────────────────────────────


  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
  };

  /// Shared POST helper — throws [AuthException] on API or network errors.
  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Backend wraps data in { success, message, data }
        return (json['data'] as Map<String, dynamic>?) ?? json;
      }

      // Server returned an error response
      final message = json['message'] as String? ??
          'Something went wrong. Please try again.';
      throw AuthException(message, statusCode: response.statusCode);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'Network error — please check your connection and try again.',
      );
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Register a new patient.
  ///
  /// [data] must contain:
  ///   phone, email, password, full_name
  /// Optional: gender, dob, blood_group, preferred_language
  Future<AuthUser> registerPatient(Map<String, dynamic> data) async {
    final responseData = await _post(ApiConstants.registerPatient, data);
    final user = AuthUser.fromApiResponse(responseData);
    userNotifier.value = user;
    await _persistUser(user);
    return user;
  }

  /// Register a new doctor.
  ///
  /// [data] must contain:
  ///   phone, email, password, full_name, nmc_registration_number
  /// Optional: consultation_fee, experience_years, bio, preferred_language
  Future<AuthUser> registerDoctor(Map<String, dynamic> data) async {
    final responseData = await _post(ApiConstants.registerDoctor, data);
    final user = AuthUser.fromApiResponse(responseData);
    userNotifier.value = user;
    await _persistUser(user);
    return user;
  }

  /// Login with phone or email + password.
  ///
  /// [identifier] — phone number or email address
  Future<AuthUser> login({
    required String identifier,
    required String password,
  }) async {
    final responseData = await _post(ApiConstants.login, {
      'identifier': identifier,
      'password':   password,
    });
    final user = AuthUser.fromApiResponse(responseData);
    userNotifier.value = user;
    await _persistUser(user);
    return user;
  }

  /// Clear the local session and log the user out.
  Future<void> logout() async {
    userNotifier.value = null;
    await _clearPersistedUser();
  }
}

// ── Error type ────────────────────────────────────────────────────────────────

class AuthException implements Exception {
  final String message;
  final int?   statusCode;

  const AuthException(this.message, {this.statusCode});

  @override
  String toString() => 'AuthException($statusCode): $message';
}
