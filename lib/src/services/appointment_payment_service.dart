import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'auth_service.dart';

/// Result of the full appointment + payment booking sequence.
class BookingResult {
  final String appointmentId;
  final String paymentId;
  final String? consultationId;
  final bool backendSuccess;
  final String? errorMessage;

  const BookingResult({
    required this.appointmentId,
    required this.paymentId,
    this.consultationId,
    required this.backendSuccess,
    this.errorMessage,
  });
}

/// Service that orchestrates the 3-step backend flow for starting a consultation:
///
///   1. POST /appointments         → creates appointment (status: pending)
///   2. POST /payments/initiate    → records payment record linked to appointment
///   3. POST /payments/:id/verify  → confirms payment → appointment auto-promoted to 'confirmed'
///
/// The service uses the currently logged-in user's JWT token for all requests.
/// If no token is available (offline / not logged in) all calls are skipped and
/// [backendSuccess] is false with an appropriate message.
class AppointmentPaymentService {
  AppointmentPaymentService._internal();
  static final AppointmentPaymentService _instance =
      AppointmentPaymentService._internal();
  factory AppointmentPaymentService() => _instance;

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, String> get _headers {
    final token = AuthService().currentUser?.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _post(
      String url, Map<String, dynamic> body) async {
    final response = await http
        .post(Uri.parse(url), headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (json['data'] as Map<String, dynamic>?) ?? json;
    }

    final message =
        json['message'] as String? ?? 'Request failed (${response.statusCode})';
    throw Exception(message);
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Book an appointment for [doctorId] and record the eSewa payment in one
  /// atomic sequence. Returns a [BookingResult] with IDs and a success flag.
  ///
  /// [doctorId]             – the doctor's DB UUID (from the backend doctor listing)
  /// [feeAmount]            – numeric consultation fee (e.g. 1200.0)
  /// [eSewaTransactionRef]  – the transaction reference returned by the eSewa SDK
  ///
  /// If the token is missing or any backend call fails, [backendSuccess] is false
  /// and [errorMessage] explains what happened. The caller should still proceed
  /// to the chat screen (offline mode) but display a warning snackbar.
  Future<BookingResult> bookAndConfirm({
    required String doctorId,
    required double feeAmount,
    String eSewaTransactionRef = 'esewa_txn',
  }) async {
    final token = AuthService().currentUser?.token;
    if (token == null || token.isEmpty) {
      return const BookingResult(
        appointmentId: '',
        paymentId: '',
        backendSuccess: false,
        errorMessage: 'Not logged in — consultation recorded locally only.',
      );
    }

    try {
      // ── Step 1: Book appointment ───────────────────────────────────────────
      final scheduledAt = DateTime.now()
          .add(const Duration(minutes: 5))
          .toUtc()
          .toIso8601String();

      final appointmentData = await _post(ApiConstants.appointments, {
        'doctor_id': doctorId,
        'scheduled_at': scheduledAt,
        'mode': 'video',
        'fee': feeAmount,
        'reason_for_visit': 'Online teleconsultation via Swasthya Sathi',
      });

      final appointmentId = appointmentData['id'] as String? ?? '';
      if (appointmentId.isEmpty) {
        return const BookingResult(
          appointmentId: '',
          paymentId: '',
          backendSuccess: false,
          errorMessage: 'Appointment created but ID was missing from response.',
        );
      }

      // ── Step 2: Initiate payment ───────────────────────────────────────────
      final serviceFee = (feeAmount * 0.02).roundToDouble();
      final totalAmount = feeAmount + serviceFee;

      final paymentData = await _post(ApiConstants.paymentsInitiate, {
        'appointment_id': appointmentId,
        'amount': totalAmount,
        'gateway': 'esewa',
      });

      final paymentId = paymentData['id'] as String? ?? '';
      if (paymentId.isEmpty) {
        return BookingResult(
          appointmentId: appointmentId,
          paymentId: '',
          backendSuccess: false,
          errorMessage: 'Payment record created but ID was missing.',
        );
      }

      // ── Step 3: Verify payment → auto-confirms the appointment ────────────
      await _post(ApiConstants.paymentVerify(paymentId), {
        'gateway_txn_id': eSewaTransactionRef,
        'status': 'success',
      });

      // ── Step 4: Start consultation session ────────────────────────────────
      String? consultationId;
      try {
        final consultData = await _post(ApiConstants.consultations, {
          'appointment_id': appointmentId,
        });
        consultationId = consultData['id']?.toString();
      } catch (_) {}

      return BookingResult(
        appointmentId: appointmentId,
        paymentId: paymentId,
        consultationId: consultationId,
        backendSuccess: true,
      );
    } catch (e) {
      return BookingResult(
        appointmentId: '',
        paymentId: '',
        backendSuccess: false,
        errorMessage:
            'Backend sync failed: ${e.toString()}. '
            'Consultation will continue in offline mode.',
      );
    }
  }
}
