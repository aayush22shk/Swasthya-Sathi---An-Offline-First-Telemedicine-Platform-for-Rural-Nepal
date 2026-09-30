import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'auth_service.dart';

class PrescriptionItem {
  final String id;
  final String medicineName;
  final String dosage;
  final String route;
  final String frequency;
  final int durationDays;
  final String instructions;

  PrescriptionItem({
    required this.id,
    required this.medicineName,
    this.dosage = '',
    this.route = 'oral',
    this.frequency = '',
    this.durationDays = 0,
    this.instructions = '',
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      id: json['id']?.toString() ?? '',
      medicineName: json['medicine_name']?.toString() ?? 'Medicine',
      dosage: json['dosage']?.toString() ?? '',
      route: json['route']?.toString() ?? 'oral',
      frequency: json['frequency']?.toString() ?? '',
      durationDays: int.tryParse(json['duration_days']?.toString() ?? '0') ?? 0,
      instructions: json['instructions']?.toString() ?? '',
    );
  }
}

class PatientPrescription {
  final String id;
  final String? consultationId;
  final String? appointmentId;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final DateTime issuedAt;
  final String notes;
  final List<PrescriptionItem> items;

  PatientPrescription({
    required this.id,
    this.consultationId,
    this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.issuedAt,
    this.notes = '',
    this.items = const [],
  });

  factory PatientPrescription.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<PrescriptionItem> itemList = [];
    if (rawItems is List) {
      itemList = rawItems
          .map((i) => PrescriptionItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return PatientPrescription(
      id: json['id']?.toString() ?? '',
      consultationId: json['consultation_id']?.toString(),
      appointmentId: json['appointment_id']?.toString(),
      doctorId: json['doctor_id']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString() ?? 'Doctor',
      patientId: json['patient_id']?.toString() ?? '',
      issuedAt: DateTime.tryParse(json['issued_at']?.toString() ?? '') ?? DateTime.now(),
      notes: json['notes']?.toString() ?? '',
      items: itemList,
    );
  }

  String get formattedDate {
    return '${issuedAt.day}/${issuedAt.month}/${issuedAt.year}';
  }
}

class PrescriptionService {
  PrescriptionService._internal();
  static final PrescriptionService _instance = PrescriptionService._internal();
  factory PrescriptionService() => _instance;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Fetch all prescriptions for a specific patient ID
  Future<List<PatientPrescription>> getPatientPrescriptions(String patientId) async {
    final token = AuthService().currentUser?.token;
    if (token == null || token.isEmpty) return [];

    try {
      final url = Uri.parse(ApiConstants.prescriptionsByPatient(patientId));
      final response = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final List<dynamic> rows = body['data'] ?? [];
        return rows
            .map((r) => PatientPrescription.fromJson(r as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
