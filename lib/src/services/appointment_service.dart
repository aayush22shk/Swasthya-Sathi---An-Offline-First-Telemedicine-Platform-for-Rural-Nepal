import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/appointment_model.dart';
import 'auth_service.dart';

class AppointmentService {
  AppointmentService._internal();
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Fetch list of appointments for the current user
  Future<List<AppointmentModel>> getAppointments({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final token = AuthService().currentUser?.token;
    if (token == null || token.isEmpty) return [];

    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final uri = Uri.parse(ApiConstants.appointments).replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data['appointments'] is List) {
          list = data['appointments'] as List;
        }
        return list
            .map((item) => AppointmentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Get the earliest upcoming appointment for dashboard card
  Future<AppointmentModel?> getUpcomingAppointment() async {
    final all = await getAppointments();
    final now = DateTime.now();
    final upcoming = all.where((a) {
      return (a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.pending) &&
          a.scheduledAt.isAfter(now.subtract(const Duration(hours: 1)));
    }).toList();

    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return upcoming.first;
  }

  /// Book a new appointment
  Future<AppointmentModel> bookAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    String mode = 'video',
    double fee = 0.0,
    String? reasonForVisit,
  }) async {
    final token = AuthService().currentUser?.token;
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required to book an appointment.');
    }

    final payload = {
      'doctor_id': doctorId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'mode': mode,
      'fee': fee,
      if (reasonForVisit != null && reasonForVisit.isNotEmpty)
        'reason_for_visit': reasonForVisit,
    };

    final response = await http
        .post(
          Uri.parse(ApiConstants.appointments),
          headers: _headers(token),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return AppointmentModel.fromJson(data);
    }

    final msg = body['message'] as String? ?? 'Failed to book appointment.';
    throw Exception(msg);
  }

  /// Cancel an appointment
  Future<void> cancelAppointment(String appointmentId, {String? note}) async {
    final token = AuthService().currentUser?.token;
    if (token == null || token.isEmpty) throw Exception('Authentication required.');

    final response = await http
        .patch(
          Uri.parse(ApiConstants.appointmentStatus(appointmentId)),
          headers: _headers(token),
          body: jsonEncode({
            'status': 'cancelled',
            if (note != null && note.isNotEmpty) 'note': note,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to cancel appointment.');
    }
  }
}
