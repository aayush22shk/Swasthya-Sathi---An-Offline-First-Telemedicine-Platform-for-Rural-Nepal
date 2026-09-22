import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_constants.dart';
import '../../../services/auth_service.dart';
import '../models/doctor_dashboard_models.dart';

class DoctorDashboardService extends ChangeNotifier {
  static final DoctorDashboardService _instance = DoctorDashboardService._internal();
  factory DoctorDashboardService() => _instance;
  DoctorDashboardService._internal() {
    _loadState();
  }

  static const String _kDoctorAvailable = 'doctor_is_available';

  bool _isAvailable = true;
  bool get isAvailable => _isAvailable;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // List states
  List<DoctorAppointment> _todayAppointments = [];
  List<DoctorAppointment> _upcomingAppointments = [];
  List<DoctorAppointment> _pendingRequests = [];
  List<DoctorAppointment> _completedConsultations = [];
  List<FollowUpPatient> _followUpPatients = [];
  List<DoctorNotificationItem> _notifications = [];
  List<PatientChatThread> _chatThreads = [];
  List<PrescriptionRecord> _prescriptions = [];

  List<DoctorAppointment> get todayAppointments => List.unmodifiable(_todayAppointments);
  List<DoctorAppointment> get upcomingAppointments => List.unmodifiable(_upcomingAppointments);
  List<DoctorAppointment> get pendingRequests => List.unmodifiable(_pendingRequests);
  List<DoctorAppointment> get completedConsultations => List.unmodifiable(_completedConsultations);
  List<FollowUpPatient> get followUpPatients => List.unmodifiable(_followUpPatients);
  List<DoctorNotificationItem> get notifications => List.unmodifiable(_notifications);
  List<PatientChatThread> get chatThreads => List.unmodifiable(_chatThreads);
  List<PrescriptionRecord> get prescriptions => List.unmodifiable(_prescriptions);

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  DoctorDashboardStats get stats => DoctorDashboardStats(
        todayAppointments: _todayAppointments.length,
        upcomingAppointments: _upcomingAppointments.length,
        pendingRequests: _pendingRequests.length,
        completedConsultations: _completedConsultations.length,
        followUpRequired: _followUpPatients.where((f) => !f.isFollowedUp).length,
        unreadNotifications: unreadNotificationsCount,
      );

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _isAvailable = prefs.getBool(_kDoctorAvailable) ?? true;
    _initializeSeedData();
    notifyListeners();
  }

  /// Toggle doctor Active (online) / Inactive (away) status
  Future<bool> setAvailability(bool available) async {
    _isAvailable = available;
    notifyListeners();

    // Persist locally for immediate offline responsiveness
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDoctorAvailable, available);

    // Sync with backend if logged in
    final currentUser = AuthService().currentUser;
    if (currentUser != null && currentUser.isDoctor) {
      _isSyncing = true;
      notifyListeners();
      try {
        final url = Uri.parse(ApiConstants.doctorById(currentUser.id));
        final response = await http
            .put(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${currentUser.token}',
              },
              body: jsonEncode({'is_available': available}),
            )
            .timeout(const Duration(seconds: 4));

        if (kDebugMode) {
          debugPrint('Doctor status updated on server: ${response.statusCode}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Backend sync error (persisted offline): $e');
        }
      } finally {
        _isSyncing = false;
        notifyListeners();
      }
    }

    return true;
  }

  void acceptPendingRequest(String appointmentId) {
    final index = _pendingRequests.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      final req = _pendingRequests.removeAt(index);
      req.status = AppointmentStatus.today;
      _todayAppointments.insert(0, req);

      // Add a notification for confirmation
      _notifications.insert(
        0,
        DoctorNotificationItem(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Appointment Confirmed',
          message: 'You accepted consultation for ${req.patientName}. Scheduled for ${req.time}.',
          timeAgo: 'Just now',
          category: NotificationCategory.appointmentRequest,
          isRead: false,
          patientName: req.patientName,
        ),
      );

      notifyListeners();
    }
  }

  void declinePendingRequest(String appointmentId, {String? reason}) {
    final index = _pendingRequests.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      final req = _pendingRequests.removeAt(index);
      req.status = AppointmentStatus.cancelled;

      _notifications.insert(
        0,
        DoctorNotificationItem(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Request Declined',
          message: 'Appointment request for ${req.patientName} was declined.',
          timeAgo: 'Just now',
          category: NotificationCategory.appointmentRequest,
          isRead: true,
          patientName: req.patientName,
        ),
      );

      notifyListeners();
    }
  }

  void markConsultationCompleted(
    String appointmentId, {
    String? diagnosis,
    String? prescription,
    String? notes,
  }) {
    final index = _todayAppointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      final apt = _todayAppointments.removeAt(index);
      final completed = apt.copyWith(
        status: AppointmentStatus.completed,
        diagnosis: diagnosis ?? 'Consultation successfully concluded with clinical guidance.',
        prescription: prescription ?? 'Rx: Follow symptomatic relief regime.',
        notes: notes ?? 'Teleconsultation verified via SwasthyaSathi EHR.',
      );
      _completedConsultations.insert(0, completed);
      notifyListeners();
    }
  }

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

  void completeFollowUp(String followUpId) {
    final index = _followUpPatients.indexWhere((f) => f.id == followUpId);
    if (index != -1) {
      _followUpPatients[index].isFollowedUp = true;
      notifyListeners();
    }
  }

  void sendChatMessage(String threadId, String text) {
    final index = _chatThreads.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      final thread = _chatThreads[index];
      final newMsg = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'doctor',
        text: text,
        time: 'Just now',
        isDoctor: true,
      );
      thread.messages.add(newMsg);
      _chatThreads[index] = PatientChatThread(
        id: thread.id,
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
  }

  void markChatThreadRead(String threadId) {
    final index = _chatThreads.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      _chatThreads[index].unreadCount = 0;
      notifyListeners();
    }
  }

  void addPrescription(PrescriptionRecord record) {
    _prescriptions.insert(0, record);
    notifyListeners();
  }

  void _initializeSeedData() {
    // 1. TODAY'S APPOINTMENTS
    _todayAppointments = [
      DoctorAppointment(
        id: 'apt_t1',
        patientId: 'p101',
        patientName: 'Sunita Gurung',
        patientAge: 32,
        patientGender: 'Female',
        patientPhone: '+977 9841234567',
        patientLocation: 'Gorkha - Ward 4, Barpak',
        avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&q=80',
        date: 'Today',
        time: '11:00 AM',
        type: AppointmentType.video,
        status: AppointmentStatus.today,
        urgency: UrgencyLevel.urgent,
        chiefComplaint: 'Severe lower abdominal cramping during 3rd trimester pregnancy; blurred vision',
        notes: 'Pre-eclampsia triage priority. Blood pressure reported 145/95 mmHg by village health worker.',
        consultationFee: 'NRs 1,000',
        feeAmount: 1000,
        duration: '25 min',
      ),
      DoctorAppointment(
        id: 'apt_t2',
        patientId: 'p102',
        patientName: 'Ram Bahadur Thapa',
        patientAge: 58,
        patientGender: 'Male',
        patientPhone: '+977 9812987654',
        patientLocation: 'Jumla - Chandannath-3',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
        date: 'Today',
        time: '01:30 PM',
        type: AppointmentType.audio,
        status: AppointmentStatus.today,
        urgency: UrgencyLevel.normal,
        chiefComplaint: 'Persistent productive cough with low-grade fever for 10 days',
        notes: 'Review sputum microscopy report sent via local health post.',
        consultationFee: 'NRs 800',
        feeAmount: 800,
        duration: '15 min',
      ),
      DoctorAppointment(
        id: 'apt_t3',
        patientId: 'p103',
        patientName: 'Pooja Shrestha',
        patientAge: 24,
        patientGender: 'Female',
        patientPhone: '+977 9801122334',
        patientLocation: 'Sindhupalchok - Melamchi',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
        date: 'Today',
        time: '03:45 PM',
        type: AppointmentType.video,
        status: AppointmentStatus.today,
        urgency: UrgencyLevel.routine,
        chiefComplaint: 'Post-operative wound dressing inspection following cesarean delivery',
        notes: 'Wound dry, no discharge reported by Female Community Health Volunteer (FCHV).',
        consultationFee: 'NRs 900',
        feeAmount: 900,
        duration: '20 min',
      ),
    ];

    // 2. UPCOMING APPOINTMENTS
    _upcomingAppointments = [
      DoctorAppointment(
        id: 'apt_u1',
        patientId: 'p201',
        patientName: 'Dawa Tamang',
        patientAge: 46,
        patientGender: 'Male',
        patientPhone: '+977 9849887766',
        patientLocation: 'Solukhumbu - Namche Bazaar',
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
        date: 'Tomorrow, 10:00 AM',
        time: '10:00 AM',
        type: AppointmentType.video,
        status: AppointmentStatus.upcoming,
        urgency: UrgencyLevel.normal,
        chiefComplaint: 'High-altitude acclimatization check & chronic knee arthritis review',
        consultationFee: 'NRs 1,200',
        feeAmount: 1200,
        duration: '20 min',
      ),
      DoctorAppointment(
        id: 'apt_u2',
        patientId: 'p202',
        patientName: 'Maya Devi Adhikari',
        patientAge: 62,
        patientGender: 'Female',
        patientPhone: '+977 9865123490',
        patientLocation: 'Baglung - Galkot',
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&q=80',
        date: 'Sep 25, 02:00 PM',
        time: '02:00 PM',
        type: AppointmentType.audio,
        status: AppointmentStatus.upcoming,
        urgency: UrgencyLevel.routine,
        chiefComplaint: 'Hypertension routine monthly medication adjustment',
        consultationFee: 'NRs 800',
        feeAmount: 800,
        duration: '15 min',
      ),
      DoctorAppointment(
        id: 'apt_u3',
        patientId: 'p203',
        patientName: 'Bikram Karki',
        patientAge: 19,
        patientGender: 'Male',
        patientPhone: '+977 9845012345',
        patientLocation: 'Dhading - Gajuri',
        date: 'Sep 26, 11:30 AM',
        time: '11:30 AM',
        type: AppointmentType.inPerson,
        status: AppointmentStatus.upcoming,
        urgency: UrgencyLevel.normal,
        chiefComplaint: 'Clinical follow-up for right forearm fracture plaster removal',
        consultationFee: 'NRs 1,000',
        feeAmount: 1000,
        duration: '30 min',
      ),
    ];

    // 3. PENDING APPOINTMENT REQUESTS
    _pendingRequests = [
      DoctorAppointment(
        id: 'apt_p1',
        patientId: 'p301',
        patientName: 'Kamala KC',
        patientAge: 27,
        patientGender: 'Female',
        patientPhone: '+977 9803456789',
        patientLocation: 'Ramechhap - Manthali',
        avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&q=80',
        date: 'Requested for Today, 04:30 PM',
        time: '04:30 PM',
        type: AppointmentType.video,
        status: AppointmentStatus.pending,
        urgency: UrgencyLevel.urgent,
        chiefComplaint: 'Baby (7 months) high fever 102.8°F, lethargy, poor breastfeeding since morning',
        notes: 'Mother requests urgent pediatric triage before evening rains block road.',
        consultationFee: 'NRs 1,200',
        feeAmount: 1200,
      ),
      DoctorAppointment(
        id: 'apt_p2',
        patientId: 'p302',
        patientName: 'Hari Prasad Pokharel',
        patientAge: 51,
        patientGender: 'Male',
        patientPhone: '+977 9841998877',
        patientLocation: 'Kavre - Dhulikhel',
        date: 'Requested for Tomorrow, 09:30 AM',
        time: '09:30 AM',
        type: AppointmentType.audio,
        status: AppointmentStatus.pending,
        urgency: UrgencyLevel.normal,
        chiefComplaint: 'Type 2 Diabetes fasting blood glucose spike (210 mg/dL)',
        notes: 'Patient submitted recent lab photo via SwasthyaSathi portal.',
        consultationFee: 'NRs 900',
        feeAmount: 900,
      ),
      DoctorAppointment(
        id: 'apt_p3',
        patientId: 'p303',
        patientName: 'Gita Nepali',
        patientAge: 38,
        patientGender: 'Female',
        patientPhone: '+977 9813224466',
        patientLocation: 'Sindhuli - Kamalamai',
        date: 'Requested for Sep 24, 03:00 PM',
        time: '03:00 PM',
        type: AppointmentType.video,
        status: AppointmentStatus.pending,
        urgency: UrgencyLevel.routine,
        chiefComplaint: 'Skin rash with severe itching on both arms for 2 weeks',
        consultationFee: 'NRs 800',
        feeAmount: 800,
      ),
    ];

    // 4. COMPLETED CONSULTATIONS
    _completedConsultations = [
      DoctorAppointment(
        id: 'apt_c1',
        patientId: 'p401',
        patientName: 'Tek Bahadur Bohara',
        patientAge: 64,
        patientGender: 'Male',
        patientPhone: '+977 9848123456',
        patientLocation: 'Humla - Simikot',
        date: 'Yesterday',
        time: '02:00 PM',
        type: AppointmentType.video,
        status: AppointmentStatus.completed,
        urgency: UrgencyLevel.normal,
        chiefComplaint: 'Chronic Obstructive Pulmonary Disease (COPD) exacerbation',
        diagnosis: 'Moderate COPD exacerbation triggered by wood smoke exposure. SpO2 93%.',
        prescription: 'Salbutamol + Ipratropium inhaler 2 puffs TID, Prednisolone 20mg OD x 5d.',
        notes: 'Advised chimney ventilation in kitchen. Follow-up in 10 days.',
        consultationFee: 'NRs 1,200',
        feeAmount: 1200,
        duration: '22 min',
      ),
      DoctorAppointment(
        id: 'apt_c2',
        patientId: 'p402',
        patientName: 'Laxmi Maya Shrestha',
        patientAge: 29,
        patientGender: 'Female',
        patientPhone: '+977 9808665544',
        patientLocation: 'Lalitpur - Godawari',
        date: 'Sep 20, 2026',
        time: '11:15 AM',
        type: AppointmentType.video,
        status: AppointmentStatus.completed,
        urgency: UrgencyLevel.routine,
        chiefComplaint: 'Antenatal care 2nd trimester routine ultrasound assessment',
        diagnosis: 'Single live intrauterine gestation, 24 weeks. Normal amniotic fluid index.',
        prescription: 'Continue Tab Iron + Folic Acid 1 tab OD, Calcium 500mg BD.',
        consultationFee: 'NRs 1,000',
        feeAmount: 1000,
        duration: '18 min',
      ),
      DoctorAppointment(
        id: 'apt_c3',
        patientId: 'p403',
        patientName: 'Dipak Rai',
        patientAge: 42,
        patientGender: 'Male',
        patientPhone: '+977 9815990011',
        patientLocation: 'Okhaldhunga - Siddhicharan',
        date: 'Sep 19, 2026',
        time: '04:00 PM',
        type: AppointmentType.audio,
        status: AppointmentStatus.completed,
        urgency: UrgencyLevel.normal,
        chiefComplaint: 'Acute gastroenteritis following village community feast',
        diagnosis: 'Mild dehydration secondary to acute viral gastroenteritis.',
        prescription: 'ORS Jeevan Jal 3 sachets in 3L boiled water, Tab Zinc 20mg OD x 14d, Tab Paracetamol 500mg SOS.',
        consultationFee: 'NRs 800',
        feeAmount: 800,
        duration: '14 min',
      ),
    ];

    // 5. PATIENTS REQUIRING FOLLOW-UP
    _followUpPatients = [
      FollowUpPatient(
        id: 'fu_1',
        patientId: 'p101',
        patientName: 'Sunita Gurung',
        patientAge: 32,
        patientGender: 'Female',
        patientPhone: '+977 9841234567',
        primaryCondition: 'Pregnancy Pre-eclampsia Monitoring (BP 145/95)',
        lastConsultationDate: 'Sep 18, 2026',
        followUpDueDate: 'Today (Due)',
        daysRemaining: 0,
        lastPrescriptionOrPlan: 'Labetalol 100mg BD. Daily urine dipstick for proteinuria.',
        priority: FollowUpPriority.high,
      ),
      FollowUpPatient(
        id: 'fu_2',
        patientId: 'p401',
        patientName: 'Tek Bahadur Bohara',
        patientAge: 64,
        patientGender: 'Male',
        patientPhone: '+977 9848123456',
        primaryCondition: 'COPD Exacerbation & SpO2 Recovery Check',
        lastConsultationDate: 'Sep 21, 2026',
        followUpDueDate: 'In 2 days (Sep 24)',
        daysRemaining: 2,
        lastPrescriptionOrPlan: 'Assess response to Prednisolone taper and inhaler technique.',
        priority: FollowUpPriority.medium,
      ),
      FollowUpPatient(
        id: 'fu_3',
        patientId: 'p501',
        patientName: 'Bishnu Prasad Tiwari',
        patientAge: 67,
        patientGender: 'Male',
        patientPhone: '+977 9847112233',
        primaryCondition: 'Post-Myocardial Infarction Post-discharge Review',
        lastConsultationDate: 'Sep 15, 2026',
        followUpDueDate: 'Overdue by 2 days',
        daysRemaining: -2,
        lastPrescriptionOrPlan: 'Review lipid profile, ECG rhythm strip, and beta-blocker compliance.',
        priority: FollowUpPriority.high,
      ),
      FollowUpPatient(
        id: 'fu_4',
        patientId: 'p502',
        patientName: 'Sabita Chaudhari',
        patientAge: 22,
        patientGender: 'Female',
        patientPhone: '+977 9814556677',
        primaryCondition: 'Iron Deficiency Anemia during Lactation (Hb 8.9 g/dL)',
        lastConsultationDate: 'Sep 10, 2026',
        followUpDueDate: 'In 5 days (Sep 27)',
        daysRemaining: 5,
        lastPrescriptionOrPlan: 'Repeat Hb count at primary healthcare center and dietary iron intake check.',
        priority: FollowUpPriority.low,
      ),
    ];

    // 6. UNREAD NOTIFICATIONS & MESSAGES
    _notifications = [
      DoctorNotificationItem(
        id: 'notif_1',
        title: 'New Emergency Patient Request',
        message: 'Kamala KC requested immediate triage for 7-month baby with 102.8°F fever.',
        timeAgo: '12 min ago',
        category: NotificationCategory.appointmentRequest,
        isRead: false,
        patientName: 'Kamala KC',
      ),
      DoctorNotificationItem(
        id: 'notif_2',
        title: 'Patient Message & Blood Pressure Log',
        message: 'Sunita Gurung: "Doctor, morning BP is 142/92, took the morning tablet with warm water."',
        timeAgo: '45 min ago',
        category: NotificationCategory.patientMessage,
        isRead: false,
        patientName: 'Sunita Gurung',
      ),
      DoctorNotificationItem(
        id: 'notif_3',
        title: 'Lab Report Uploaded',
        message: 'Gorkha District Lab uploaded Sputum AFB report for patient Ram Bahadur Thapa.',
        timeAgo: '2 hrs ago',
        category: NotificationCategory.labReport,
        isRead: false,
        patientName: 'Ram Bahadur Thapa',
      ),
      DoctorNotificationItem(
        id: 'notif_4',
        title: 'NMC Telemedicine Protocol Verified',
        message: 'Your annual Nepal Medical Council Teleconsultation License credential sync is active.',
        timeAgo: 'Yesterday',
        category: NotificationCategory.systemAlert,
        isRead: true,
      ),
    ];

    // 7. PATIENT CHAT THREADS
    _chatThreads = [
      PatientChatThread(
        id: 'chat_1',
        patientId: 'p101',
        patientName: 'Sunita Gurung',
        patientAge: 32,
        patientGender: 'Female',
        patientLocation: 'Gorkha - Barpak',
        lastMessage: 'Doctor, morning BP is 142/92, took the morning tablet.',
        lastMessageTime: '10:45 AM',
        unreadCount: 2,
        isOnline: true,
        avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&q=80',
        messages: [
          ChatMessage(
            id: 'm1',
            senderId: 'p101',
            text: 'Namaste Doctor, I measured my BP with the community health volunteer.',
            time: '10:40 AM',
            isDoctor: false,
          ),
          ChatMessage(
            id: 'm2',
            senderId: 'p101',
            text: 'Doctor, morning BP is 142/92, took the morning tablet.',
            time: '10:45 AM',
            isDoctor: false,
          ),
        ],
      ),
      PatientChatThread(
        id: 'chat_2',
        patientId: 'p102',
        patientName: 'Ram Bahadur Thapa',
        patientAge: 58,
        patientGender: 'Male',
        patientLocation: 'Jumla - Chandannath',
        lastMessage: 'I have uploaded the sputum test photo from the local clinic.',
        lastMessageTime: 'Yesterday',
        unreadCount: 1,
        isOnline: false,
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
        messages: [
          ChatMessage(
            id: 'm3',
            senderId: 'p102',
            text: 'I have uploaded the sputum test photo from the local clinic.',
            time: 'Yesterday 4:15 PM',
            isDoctor: false,
          ),
          ChatMessage(
            id: 'm4',
            senderId: 'doctor',
            text: 'Thank you Ram Bahadur ji. I will review it during our 1:30 PM call today.',
            time: 'Yesterday 5:00 PM',
            isDoctor: true,
          ),
        ],
      ),
      PatientChatThread(
        id: 'chat_3',
        patientId: 'p301',
        patientName: 'Kamala KC',
        patientAge: 27,
        patientGender: 'Female',
        patientLocation: 'Ramechhap - Manthali',
        lastMessage: 'Baby fever is still 102.5. Waiting for the video call.',
        lastMessageTime: '08:20 AM',
        unreadCount: 3,
        isOnline: true,
        avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&q=80',
        messages: [
          ChatMessage(
            id: 'm5',
            senderId: 'p301',
            text: 'Baby fever is still 102.5. Waiting for the video call.',
            time: '08:20 AM',
            isDoctor: false,
          ),
        ],
      ),
    ];

    // 8. PRESCRIPTIONS & CLINICAL RECORDS
    _prescriptions = [
      PrescriptionRecord(
        id: 'rx_101',
        patientId: 'p401',
        patientName: 'Tek Bahadur Bohara',
        date: 'Sep 21, 2026',
        diagnosis: 'Moderate COPD Exacerbation secondary to indoor woodsmoke exposure.',
        clinicalAdvice: 'Avoid direct biomass cooking smoke; ensure cross-ventilation in kitchen; steam inhalation BID.',
        nextFollowUp: 'Oct 01, 2026',
        medicines: [
          PrescriptionItem(
            medicineName: 'Salbutamol + Ipratropium Inhaler',
            dosage: '2 Puffs',
            duration: '14 Days',
            instructions: 'TID with spacer chamber',
          ),
          PrescriptionItem(
            medicineName: 'Prednisolone 20mg Tablet',
            dosage: '1 Tab (20mg)',
            duration: '5 Days',
            instructions: 'Once daily after breakfast, do not abruptly stop',
          ),
          PrescriptionItem(
            medicineName: 'Azithromycin 500mg Tablet',
            dosage: '1 Tab (500mg)',
            duration: '3 Days',
            instructions: 'Once daily 1 hour before meal',
          ),
        ],
      ),
      PrescriptionRecord(
        id: 'rx_102',
        patientId: 'p402',
        patientName: 'Laxmi Maya Shrestha',
        date: 'Sep 20, 2026',
        diagnosis: 'Antenatal Care 2nd Trimester Routine Micronutrient Supplementation.',
        clinicalAdvice: 'Adequate hydration (3L/day boiled water); maintain maternal left lateral resting posture.',
        nextFollowUp: 'Oct 18, 2026',
        medicines: [
          PrescriptionItem(
            medicineName: 'Iron + Folic Acid Tablet',
            dosage: '1 Tab (60mg elemental Iron)',
            duration: '90 Days',
            instructions: 'Once daily after dinner with lemon water',
          ),
          PrescriptionItem(
            medicineName: 'Calcium Carbonate + Vit D3 500mg',
            dosage: '1 Tab',
            duration: '90 Days',
            instructions: 'Twice daily after lunch and breakfast',
          ),
        ],
      ),
    ];
  }
}
