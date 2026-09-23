import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common_widgets/doctors/doctor_model.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class DoctorService {
  DoctorService._internal();
  static final DoctorService _instance = DoctorService._internal();
  factory DoctorService() => _instance;

  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  /// Fetch list of doctors with optional search and specialization filters.
  Future<List<DoctorModel>> getDoctors({
    String? search,
    int? specializationId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (specializationId != null) 'specialization_id': specializationId.toString(),
      };

      final uri = Uri.parse(ApiConstants.doctors).replace(queryParameters: queryParams);
      final token = AuthService().currentUser?.token;

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        List<dynamic> list = [];
        if (data is Map<String, dynamic> && data['doctors'] is List) {
          list = data['doctors'] as List<dynamic>;
        } else if (data is List) {
          list = data;
        }

        final doctors = list.map((item) => DoctorModel.fromJson(item as Map<String, dynamic>)).toList();
        return doctors.isNotEmpty ? doctors : DoctorModel.sampleDoctors;
      }
      return DoctorModel.sampleDoctors;
    } catch (_) {
      // Offline / API error fallback
      return DoctorModel.sampleDoctors;
    }
  }

  /// Fetch single doctor details by UUID
  Future<DoctorModel?> getDoctorById(String doctorId) async {
    try {
      final token = AuthService().currentUser?.token;
      final uri = Uri.parse(ApiConstants.doctorById(doctorId));

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? body;
        return DoctorModel.fromJson(data);
      }
    } catch (_) {}

    // Fallback if matched in sampleDoctors
    try {
      return DoctorModel.sampleDoctors.firstWhere((d) => d.id == doctorId);
    } catch (_) {
      return null;
    }
  }

  /// Fetch available time slots for doctor on a given date (YYYY-MM-DD)
  Future<List<String>> getDoctorSlots(String doctorId, String date) async {
    try {
      final token = AuthService().currentUser?.token;
      final uri = Uri.parse(ApiConstants.doctorSlots(doctorId)).replace(
        queryParameters: {'date': date},
      );

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is List) {
          return data.map((e) => e.toString()).toList();
        } else if (data is Map && data['slots'] is List) {
          return (data['slots'] as List).map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}

    // Fallback slots if doctor is available
    return [
      '09:00 AM',
      '09:30 AM',
      '10:00 AM',
      '10:30 AM',
      '02:00 PM',
      '02:30 PM',
      '03:00 PM',
      '03:30 PM',
      '04:00 PM',
    ];
  }
}
