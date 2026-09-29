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
        List rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map && data['slots'] is List) {
          rawList = data['slots'] as List;
        }

        if (rawList.isNotEmpty) {
          return rawList.map((e) {
            final s = e.toString().trim();
            // If already in AM/PM format
            if (s.toUpperCase().contains('AM') || s.toUpperCase().contains('PM')) {
              return s;
            }
            // Parse HH:mm to AM/PM
            final parts = s.split(':');
            if (parts.length >= 2) {
              int h = int.tryParse(parts[0]) ?? 12;
              final m = parts[1].padLeft(2, '0');
              final ampm = h >= 12 ? 'PM' : 'AM';
              final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
              return '${displayH.toString().padLeft(2, '0')}:$m $ampm';
            }
            return s;
          }).toList();
        }
      }
    } catch (_) {}

    // Fallback default slots
    return [
      '09:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '01:00 PM',
      '02:00 PM',
      '03:00 PM',
      '04:00 PM',
      '05:00 PM',
    ];
  }
}
