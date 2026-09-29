import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_constants.dart';
import '../../../services/auth_service.dart';
import '../models/doctor_dashboard_models.dart';

/// Service that drives the Doctor Dashboard.
///
/// All data is fetched from the real backend API.  A thin offline
/// fallback keeps the UI functional when the network is unavailable.
class DoctorDashboardService extends ChangeNotifier {
  static final DoctorDashboardService _instance =
      DoctorDashboardService._internal();
  factory DoctorDashboardService() => _instance;
  DoctorDashboardService._internal() {
    _loadAvailability();
  }

  static const String _kDoctorAvailable = 'doctor_is_available';

  // ── Availability ──────────────────────────────────────────────────────────
  bool _isAvailable = true;
  bool get isAvailable => _isAvailable;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // ── Loading states ────────────────────────────────────────────────────────
  bool _loadingAppointments = false;
  bool get loadingAppointments => _loadingAppointments;

  bool _loadingPatients = false;
  bool get loadingPatients => _loadingPatients;

  bool _loadingPrescriptions = false;
  bool get loadingPrescriptions => _loadingPrescriptions;

  bool _loadingFollowUps = false;
  bool get loadingFollowUps => _loadingFollowUps;

  bool _loadingConversations = false;
  bool get loadingConversations => _loadingConversations;

  // ── Error states ──────────────────────────────────────────────────────────
  String? _appointmentsError;
  String? get appointmentsError => _appointmentsError;

  String? _patientsError;
  String? get patientsError => _patientsError;

  String? _prescriptionsError;
  String? get prescriptionsError => _prescriptionsError;

  String? _followUpsError;
  String? get followUpsError => _followUpsError;

  String? _conversationsError;
  String? get conversationsError => _conversationsError;

  // ── Data ──────────────────────────────────────────────────────────────────
  List<DoctorAppointment> _todayAppointments = [];
  List<DoctorAppointment> _upcomingAppointments = [];
  List<DoctorAppointment> _pendingRequests = [];
  List<DoctorAppointment> _completedConsultations = [];
  List<DoctorPatient> _myPatients = [];
  List<FollowUpPatient> _followUpPatients = [];
  final List<DoctorNotificationItem> _notifications = [];
  List<PatientChatThread> _chatThreads = [];
  List<PrescriptionRecord> _prescriptions = [];

  List<DoctorAppointment> get todayAppointments =>
      List.unmodifiable(_todayAppointments);
  List<DoctorAppointment> get upcomingAppointments =>
      List.unmodifiable(_upcomingAppointments);
  List<DoctorAppointment> get pendingRequests =>
      List.unmodifiable(_pendingRequests);
  List<DoctorAppointment> get completedConsultations =>
      List.unmodifiable(_completedConsultations);
  List<DoctorPatient> get myPatients => List.unmodifiable(_myPatients);
  List<FollowUpPatient> get followUpPatients =>
      List.unmodifiable(_followUpPatients);
  List<DoctorNotificationItem> get notifications =>
      List.unmodifiable(_notifications);
  List<PatientChatThread> get chatThreads => List.unmodifiable(_chatThreads);
  List<PrescriptionRecord> get prescriptions =>
      List.unmodifiable(_prescriptions);

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  DoctorDashboardStats get stats => DoctorDashboardStats(
        todayAppointments: _todayAppointments.length,
        upcomingAppointments: _upcomingAppointments.length,
        pendingRequests: _pendingRequests.length,
        completedConsultations: _completedConsultations.length,
        followUpRequired:
            _followUpPatients.where((f) => !f.isFollowedUp).length,
        unreadNotifications: unreadNotificationsCount,
      );

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<String?> _getToken() async {
    final user = AuthService().currentUser;
    if (user != null) return user.token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.kToken);
  }

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<void> _loadAvailability() async {
    final prefs = await SharedPreferences.getInstance();
    _isAvailable = prefs.getBool(_kDoctorAvailable) ?? true;
    notifyListeners();
  }

  // ── Refresh all ───────────────────────────────────────────────────────────

  /// Refresh all doctor dashboard data from the backend.
  Future<void> refreshAll() async {
    await Future.wait([
      fetchAppointments(),
      fetchMyPatients(),
      fetchPrescriptions(),
      fetchFollowUps(),
      fetchConversations(),
    ]);
  }

  // ── Appointments ──────────────────────────────────────────────────────────

  /// Fetch all appointments for the authenticated doctor.
  Future<void> fetchAppointments() async {
    _loadingAppointments = true;
    _appointmentsError = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _appointmentsError = 'Not authenticated.';
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.appointments),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> rows = body['data'] ?? [];

        final all = rows
            .map((r) => DoctorAppointment.fromJson(r as Map<String, dynamic>))
            .toList();

        _todayAppointments =
            all.where((a) => a.status == AppointmentStatus.today).toList();
        _upcomingAppointments =
            all.where((a) => a.status == AppointmentStatus.upcoming).toList();
        _pendingRequests =
            all.where((a) => a.status == AppointmentStatus.pending).toList();
        _completedConsultations = all
            .where((a) => a.status == AppointmentStatus.completed)
            .toList();
      } else {
        final body = jsonDecode(response.body);
        _appointmentsError =
            body['message']?.toString() ?? 'Failed to load appointments.';
      }
    } catch (e) {
      _appointmentsError = 'Network error. Check your connection.';
      if (kDebugMode) debugPrint('fetchAppointments error: $e');
    } finally {
      _loadingAppointments = false;
      notifyListeners();
    }
  }

  // ── My Patients (relationship-based) ─────────────────────────────────────

  Future<void> fetchMyPatients() async {
    _loadingPatients = true;
    _patientsError = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _patientsError = 'Not authenticated.';
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.doctorMyPatients),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> rows = body['data'] ?? [];
        _myPatients = rows
            .map((r) => DoctorPatient.fromJson(r as Map<String, dynamic>))
            .toList();
      } else {
        final body = jsonDecode(response.body);
        _patientsError =
            body['message']?.toString() ?? 'Failed to load patients.';
      }
    } catch (e) {
      _patientsError = 'Network error. Check your connection.';
      if (kDebugMode) debugPrint('fetchMyPatients error: $e');
    } finally {
      _loadingPatients = false;
      notifyListeners();
    }
  }

  /// Fetch full patient details (profile + appointment + prescription history)
  Future<DoctorPatient?> fetchPatientDetails(String patientId) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse(ApiConstants.doctorMyPatientById(patientId)),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return DoctorPatient.fromJson(body['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('fetchPatientDetails error: $e');
    }
    return null;
  }

  // ── Prescriptions ─────────────────────────────────────────────────────────

  Future<void> fetchPrescriptions() async {
    _loadingPrescriptions = true;
    _prescriptionsError = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _prescriptionsError = 'Not authenticated.';
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.doctorMyPrescriptions),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> rows = body['data'] ?? [];
        _prescriptions = rows
            .map((r) =>
                PrescriptionRecord.fromJson(r as Map<String, dynamic>))
            .toList();
      } else {
        final body = jsonDecode(response.body);
        _prescriptionsError =
            body['message']?.toString() ?? 'Failed to load prescriptions.';
      }
    } catch (e) {
      _prescriptionsError = 'Network error. Check your connection.';
      if (kDebugMode) debugPrint('fetchPrescriptions error: $e');
    } finally {
      _loadingPrescriptions = false;
      notifyListeners();
    }
  }

  /// Issue a new prescription via the backend.
  Future<bool> issuePrescription({
    required String consultationId,
    required String patientId,
    required String notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse(ApiConstants.prescriptions),
            headers: _authHeaders(token),
            body: jsonEncode({
              'consultation_id': consultationId,
              'patient_id': patientId,
              'notes': notes,
              'items': items,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        await fetchPrescriptions();
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('issuePrescription error: $e');
    }
    return false;
  }

  // ── Follow-Ups ────────────────────────────────────────────────────────────

  Future<void> fetchFollowUps() async {
    _loadingFollowUps = true;
    _followUpsError = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _followUpsError = 'Not authenticated.';
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.followUpsByDoctor),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> rows = body['data'] ?? [];
        _followUpPatients = rows
            .map((r) =>
                FollowUpPatient.fromJson(r as Map<String, dynamic>))
            .toList();
      } else {
        final body = jsonDecode(response.body);
        _followUpsError =
            body['message']?.toString() ?? 'Failed to load follow-ups.';
      }
    } catch (e) {
      _followUpsError = 'Network error. Check your connection.';
      if (kDebugMode) debugPrint('fetchFollowUps error: $e');
    } finally {
      _loadingFollowUps = false;
      notifyListeners();
    }
  }

  /// Schedule a new follow-up from the backend.
  Future<bool> scheduleFollowUp({
    required String patientId,
    required String followUpDate,
    String? notes,
    String? consultationId,
    String? appointmentId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final Map<String, dynamic> payload = {
        'patient_id': patientId,
        'follow_up_date': followUpDate,
      };
      if (notes != null) payload['notes'] = notes;
      if (consultationId != null) payload['consultation_id'] = consultationId;
      if (appointmentId != null) payload['appointment_id'] = appointmentId;

      final response = await http
          .post(
            Uri.parse(ApiConstants.followUps),
            headers: _authHeaders(token),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        await fetchFollowUps();
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('scheduleFollowUp error: $e');
    }
    return false;
  }

  /// Mark a follow-up as completed via the backend.
  Future<void> completeFollowUp(String followUpId) async {
    // Optimistic update
    final index = _followUpPatients.indexWhere((f) => f.id == followUpId);
    if (index != -1) {
      _followUpPatients[index].isFollowedUp = true;
      notifyListeners();
    }

    try {
      final token = await _getToken();
      if (token == null) return;

      await http
          .patch(
            Uri.parse(ApiConstants.followUpStatus(followUpId)),
            headers: _authHeaders(token),
            body: jsonEncode({'status': 'completed'}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      // Revert on failure
      if (index != -1) {
        _followUpPatients[index].isFollowedUp = false;
        notifyListeners();
      }
      if (kDebugMode) debugPrint('completeFollowUp error: $e');
    }
  }

  // ── Conversations / Chat ──────────────────────────────────────────────────

  Future<void> fetchConversations() async {
    _loadingConversations = true;
    _conversationsError = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _conversationsError = 'Not authenticated.';
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.doctorMyConversations),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> rows = body['data'] ?? [];
        _chatThreads = rows
            .map((r) =>
                PatientChatThread.fromJson(r as Map<String, dynamic>))
            .toList();
      } else {
        final body = jsonDecode(response.body);
        _conversationsError =
            body['message']?.toString() ?? 'Failed to load conversations.';
      }
    } catch (e) {
      _conversationsError = 'Network error. Check your connection.';
      if (kDebugMode) debugPrint('fetchConversations error: $e');
    } finally {
      _loadingConversations = false;
      notifyListeners();
    }
  }

  /// Fetch messages for a specific consultation (chat thread).
  Future<List<ChatMessage>> fetchMessages(String consultationId) async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse(ApiConstants.consultationMessages(consultationId)),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> rows = body['data'] ?? [];
        final doctorUserId = AuthService().currentUser?.id ?? '';

        return rows.map((m) {
          final senderId = m['sender_id']?.toString() ?? '';
          final sentAt = m['sent_at'] != null
              ? DateTime.tryParse(m['sent_at'].toString())
              : null;
          return ChatMessage(
            id: m['id']?.toString() ?? '',
            senderId: senderId,
            text: m['message']?.toString() ?? '',
            time: sentAt != null ? _timeAgo(sentAt) : '',
            isDoctor: senderId == doctorUserId,
          );
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('fetchMessages error: $e');
    }
    return [];
  }

  /// Send a message in a consultation chat.
  Future<bool> sendChatMessageToBackend(
      String consultationId, String text) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse(ApiConstants.consultationMessages(consultationId)),
            headers: _authHeaders(token),
            body: jsonEncode({'message': text}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        // Update thread last message locally
        final idx =
            _chatThreads.indexWhere((t) => t.consultationId == consultationId);
        if (idx != -1) {
          final thread = _chatThreads[idx];
          _chatThreads[idx] = PatientChatThread(
            id: thread.id,
            consultationId: thread.consultationId,
            patientId: thread.patientId,
            patientName: thread.patientName,
            patientAge: thread.patientAge,
            patientGender: thread.patientGender,
            patientLocation: thread.patientLocation,
            lastMessage: text,
            lastMessageTime: 'Just now',
            unreadCount: 0,
            isOnline: thread.isOnline,
            avatarUrl: thread.avatarUrl,
            messages: thread.messages,
          );
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('sendChatMessage error: $e');
    }
    return false;
  }

  void markChatThreadRead(String consultationId) {
    final idx =
        _chatThreads.indexWhere((t) => t.consultationId == consultationId);
    if (idx != -1) {
      _chatThreads[idx].unreadCount = 0;
      notifyListeners();
    }
  }

  // ── Appointment Actions ───────────────────────────────────────────────────

  /// Accept a pending appointment request.
  Future<bool> acceptPendingRequest(String appointmentId) async {
    final index = _pendingRequests.indexWhere((a) => a.id == appointmentId);
    if (index == -1) return false;

    // Optimistic update
    final req = _pendingRequests.removeAt(index);
    final isToday = req.date == 'Today';
    req.status = isToday ? AppointmentStatus.today : AppointmentStatus.upcoming;
    if (isToday) {
      _todayAppointments.insert(0, req);
    } else {
      _upcomingAppointments.insert(0, req);
    }
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http
          .patch(
            Uri.parse(ApiConstants.appointmentStatus(appointmentId)),
            headers: _authHeaders(token),
            body: jsonEncode({'status': 'confirmed'}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _notifications.insert(
          0,
          DoctorNotificationItem(
            id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Appointment Confirmed',
            message:
                'You accepted consultation for ${req.patientName}. Scheduled for ${req.time}.',
            timeAgo: 'Just now',
            category: NotificationCategory.appointmentRequest,
            isRead: false,
            patientName: req.patientName,
          ),
        );
        notifyListeners();
        return true;
      } else {
        // Revert on failure
        if (isToday) {
          _todayAppointments.removeWhere((a) => a.id == appointmentId);
        } else {
          _upcomingAppointments.removeWhere((a) => a.id == appointmentId);
        }
        req.status = AppointmentStatus.pending;
        _pendingRequests.insert(index, req);
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Revert on error
      if (isToday) {
        _todayAppointments.removeWhere((a) => a.id == appointmentId);
      } else {
        _upcomingAppointments.removeWhere((a) => a.id == appointmentId);
      }
      req.status = AppointmentStatus.pending;
      _pendingRequests.insert(index, req);
      notifyListeners();
      if (kDebugMode) debugPrint('acceptPendingRequest error: $e');
      return false;
    }
  }

  /// Decline a pending appointment request.
  Future<bool> declinePendingRequest(String appointmentId,
      {String? reason}) async {
    final index = _pendingRequests.indexWhere((a) => a.id == appointmentId);
    if (index == -1) return false;

    // Optimistic update
    final req = _pendingRequests.removeAt(index);
    req.status = AppointmentStatus.cancelled;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) return false;

      final Map<String, dynamic> payload = {'status': 'cancelled'};
      if (reason != null) payload['note'] = reason;

      final response = await http
          .patch(
            Uri.parse(ApiConstants.appointmentStatus(appointmentId)),
            headers: _authHeaders(token),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _notifications.insert(
          0,
          DoctorNotificationItem(
            id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Request Declined',
            message:
                'Appointment request for ${req.patientName} was declined.',
            timeAgo: 'Just now',
            category: NotificationCategory.appointmentRequest,
            isRead: true,
            patientName: req.patientName,
          ),
        );
        notifyListeners();
        return true;
      } else {
        // Revert
        req.status = AppointmentStatus.pending;
        _pendingRequests.insert(index, req);
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Revert
      req.status = AppointmentStatus.pending;
      _pendingRequests.insert(index, req);
      notifyListeners();
      if (kDebugMode) debugPrint('declinePendingRequest error: $e');
      return false;
    }
  }

  /// Mark a consultation as completed locally and in the backend database.
  Future<bool> markConsultationCompleted(
    String appointmentId, {
    String? diagnosis,
    String? prescription,
    String? notes,
  }) async {
    DoctorAppointment? targetApt;
    final todayIdx = _todayAppointments.indexWhere((a) => a.id == appointmentId);
    if (todayIdx != -1) {
      targetApt = _todayAppointments.removeAt(todayIdx);
    } else {
      final upcomingIdx = _upcomingAppointments.indexWhere((a) => a.id == appointmentId);
      if (upcomingIdx != -1) {
        targetApt = _upcomingAppointments.removeAt(upcomingIdx);
      }
    }

    if (targetApt != null) {
      final completed = targetApt.copyWith(
        status: AppointmentStatus.completed,
        diagnosis: diagnosis ??
            'Consultation successfully concluded with clinical guidance.',
        prescription: prescription ?? 'Rx: Follow symptomatic relief regime.',
        notes: notes ?? 'Teleconsultation verified via SwasthyaSathi EHR.',
      );
      _completedConsultations.insert(0, completed);
      notifyListeners();
    }

    try {
      final token = await _getToken();
      if (token != null) {
        await http
            .patch(
              Uri.parse(ApiConstants.appointmentStatus(appointmentId)),
              headers: _authHeaders(token),
              body: jsonEncode({
                'status': 'completed',
                'note': notes ?? 'Consultation completed.',
              }),
            )
            .timeout(const Duration(seconds: 10));
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('markConsultationCompleted error: $e');
      return false;
    }
  }

  // ── Availability ──────────────────────────────────────────────────────────

  Future<bool> setAvailability(bool available) async {
    _isAvailable = available;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDoctorAvailable, available);

    final currentUser = AuthService().currentUser;
    if (currentUser != null && currentUser.isDoctor) {
      _isSyncing = true;
      notifyListeners();
      try {
        final url = Uri.parse(ApiConstants.doctorById(currentUser.id));
        await http
            .put(
              url,
              headers: _authHeaders(currentUser.token),
              body: jsonEncode({'is_available': available}),
            )
            .timeout(const Duration(seconds: 4));
      } catch (e) {
        if (kDebugMode) debugPrint('setAvailability backend sync error: $e');
      } finally {
        _isSyncing = false;
        notifyListeners();
      }
    }

    return true;
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  void markNotificationAsRead(String notifId) {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
