import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../features/patient_profile/models/patient_profile_model.dart';
import 'auth_service.dart';

class ProfileService {
  ProfileService._internal();
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;

  final ValueNotifier<PatientProfileModel?> profileNotifier = ValueNotifier(null);
  PatientProfileModel? get currentProfile => profileNotifier.value;

  Map<String, String> _authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Fetch own patient profile from /api/v1/patients/me
  Future<PatientProfileModel> getMyPatientProfile() async {
    final token = AuthService().currentUser?.token;
    if (token == null || token.isEmpty) {
      throw const AuthException('Not authenticated. Please log in.');
    }

    try {
      final response = await http
          .get(
            Uri.parse(ApiConstants.patientProfileMe),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json['data'] as Map<String, dynamic>? ?? json;
        final profile = PatientProfileModel.fromJson(data);
        profileNotifier.value = profile;
        return profile;
      }

      final message = json['message'] as String? ?? 'Failed to load profile.';
      throw AuthException(message, statusCode: response.statusCode);
    } on AuthException {
      rethrow;
    } catch (e) {
      // If network fails but we have cached user info, create a local fallback
      final cachedUser = AuthService().currentUser;
      if (cachedUser != null) {
        final fallback = PatientProfileModel(
          id: cachedUser.id,
          userId: cachedUser.id,
          fullName: cachedUser.fullName ?? 'User',
          phone: cachedUser.phone,
          email: cachedUser.email,
        );
        profileNotifier.value = fallback;
        return fallback;
      }
      throw AuthException('Network error: $e');
    }
  }

  /// Update patient profile
  Future<PatientProfileModel> updatePatientProfile({
    required String patientId,
    required Map<String, dynamic> data,
  }) async {
    final token = AuthService().currentUser?.token;
    if (token == null || token.isEmpty) {
      throw const AuthException('Not authenticated.');
    }

    try {
      final response = await http
          .put(
            Uri.parse(ApiConstants.patientById(patientId)),
            headers: _authHeaders(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Refresh full profile
        return await getMyPatientProfile();
      }

      final message = json['message'] as String? ?? 'Failed to update profile.';
      throw AuthException(message, statusCode: response.statusCode);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  /// Deactivate patient account
  Future<void> deactivateAccount(String patientId) async {
    final token = AuthService().currentUser?.token;
    if (token == null || token.isEmpty) {
      throw const AuthException('Not authenticated.');
    }

    final response = await http
        .delete(
          Uri.parse(ApiConstants.patientById(patientId)),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      profileNotifier.value = null;
      await AuthService().logout();
      return;
    }

    final message = json['message'] as String? ?? 'Failed to delete account.';
    throw AuthException(message, statusCode: response.statusCode);
  }

  /// App language preference
  Future<void> saveAppLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.kAppLanguage, langCode);
    if (currentProfile != null) {
      profileNotifier.value = currentProfile!.copyWith(preferredLanguage: langCode);
    }
  }

  Future<String> getAppLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.kAppLanguage) ?? 'en';
  }
}
