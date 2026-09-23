import 'package:flutter/material.dart';

enum AppointmentType {
  video,
  audio,
  inPerson;

  String get label {
    switch (this) {
      case AppointmentType.video:
        return 'Video Call';
      case AppointmentType.audio:
        return 'Audio Call';
      case AppointmentType.inPerson:
        return 'In-Person';
    }
  }

  IconData get icon {
    switch (this) {
      case AppointmentType.video:
        return Icons.videocam_rounded;
      case AppointmentType.audio:
        return Icons.phone_rounded;
      case AppointmentType.inPerson:
        return Icons.local_hospital_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AppointmentType.video:
        return const Color(0xFF0072FF);
      case AppointmentType.audio:
        return const Color(0xFF10B981);
      case AppointmentType.inPerson:
        return const Color(0xFF8B5CF6);
    }
  }

  static AppointmentType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'audio':
        return AppointmentType.audio;
      case 'in_person':
      case 'chat':
        return AppointmentType.inPerson;
      default:
        return AppointmentType.video;
    }
  }
}

enum AppointmentStatus {
  today,
  upcoming,
  pending,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case AppointmentStatus.today:
        return 'Today';
      case AppointmentStatus.upcoming:
        return 'Upcoming';
      case AppointmentStatus.pending:
        return 'Pending Request';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  static AppointmentStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'confirmed':
        return AppointmentStatus.upcoming;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
      case 'no_show':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.pending;
    }
  }
}

enum UrgencyLevel {
  urgent,
  normal,
  routine;

  String get label {
    switch (this) {
      case UrgencyLevel.urgent:
        return 'Urgent';
      case UrgencyLevel.normal:
        return 'Normal';
      case UrgencyLevel.routine:
        return 'Routine Review';
    }
  }

  Color get color {
    switch (this) {
      case UrgencyLevel.urgent:
        return const Color(0xFFEF4444);
      case UrgencyLevel.normal:
        return const Color(0xFF0072FF);
      case UrgencyLevel.routine:
        return const Color(0xFF10B981);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case UrgencyLevel.urgent:
        return const Color(0xFFFEE2E2);
      case UrgencyLevel.normal:
        return const Color(0xFFE0EDFF);
      case UrgencyLevel.routine:
        return const Color(0xFFDCFCE7);
    }
  }
}

class DoctorAppointment {
  final String id;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientPhone;
  final String? patientLocation;
  final String? avatarUrl;
  final String date;
  final String time;
  final AppointmentType type;
  AppointmentStatus status;
  final UrgencyLevel urgency;
  final String chiefComplaint;
  final String? notes;
  final String? diagnosis;
  final String? prescription;
  final String consultationFee;
  final double feeAmount;
  final String? duration;

  DoctorAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientPhone,
    this.patientLocation,
    this.avatarUrl,
    required this.date,
    required this.time,
    required this.type,
    required this.status,
    this.urgency = UrgencyLevel.normal,
    required this.chiefComplaint,
    this.notes,
    this.diagnosis,
    this.prescription,
    this.consultationFee = 'NRs 0',
    this.feeAmount = 0.0,
    this.duration,
  });

  /// Deserialize from backend JSON (appointment list response)
  factory DoctorAppointment.fromJson(Map<String, dynamic> json) {
    final scheduledAt = json['scheduled_at'] != null
        ? DateTime.tryParse(json['scheduled_at'].toString()) ?? DateTime.now()
        : DateTime.now();

    final now = DateTime.now();
    final isToday = scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;

    final fee = (json['fee'] as num?)?.toDouble() ?? 0.0;
    final rawStatus = json['status']?.toString() ?? 'pending';

    // Determine display status from backend status + date
    AppointmentStatus displayStatus;
    if (rawStatus == 'completed') {
      displayStatus = AppointmentStatus.completed;
    } else if (rawStatus == 'cancelled' || rawStatus == 'no_show') {
      displayStatus = AppointmentStatus.cancelled;
    } else if (rawStatus == 'pending') {
      displayStatus = AppointmentStatus.pending;
    } else if (isToday) {
      displayStatus = AppointmentStatus.today;
    } else {
      displayStatus = AppointmentStatus.upcoming;
    }

    // Compute age from patient dob if available
    int age = 0;
    if (json['patient_dob'] != null) {
      final dob = DateTime.tryParse(json['patient_dob'].toString());
      if (dob != null) {
        age = now.year - dob.year;
        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
      }
    }

    return DoctorAppointment(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? 'Patient',
      patientAge: age,
      patientGender: json['patient_gender']?.toString() ?? 'Unknown',
      patientPhone: json['patient_phone']?.toString() ?? '',
      patientLocation: json['patient_location']?.toString(),
      avatarUrl: json['patient_photo_url']?.toString(),
      date: _formatDate(scheduledAt),
      time: _formatTime(scheduledAt),
      type: AppointmentType.fromString(json['mode']?.toString()),
      status: displayStatus,
      chiefComplaint: json['reason_for_visit']?.toString() ?? 'Consultation',
      notes: json['notes']?.toString(),
      diagnosis: json['diagnosis']?.toString(),
      consultationFee: 'NRs ${fee.toStringAsFixed(0)}',
      feeAmount: fee,
    );
  }

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == tomorrow) return 'Tomorrow';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:$m $period';
  }

  DoctorAppointment copyWith({
    AppointmentStatus? status,
    String? diagnosis,
    String? prescription,
    String? notes,
  }) {
    return DoctorAppointment(
      id: id,
      patientId: patientId,
      patientName: patientName,
      patientAge: patientAge,
      patientGender: patientGender,
      patientPhone: patientPhone,
      patientLocation: patientLocation,
      avatarUrl: avatarUrl,
      date: date,
      time: time,
      type: type,
      status: status ?? this.status,
      urgency: urgency,
      chiefComplaint: chiefComplaint,
      notes: notes ?? this.notes,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      consultationFee: consultationFee,
      feeAmount: feeAmount,
      duration: duration,
    );
  }
}

// ---------------------------------------------------------------------------
// Doctor Patient (relationship-based)
// ---------------------------------------------------------------------------
class DoctorPatient {
  final String id;
  final String fullName;
  final String? dob;
  final String? gender;
  final String? bloodGroup;
  final String? profilePhotoUrl;
  final String? phone;
  final String? email;
  final String? lastAppointmentStatus;
  final DateTime? lastAppointmentAt;
  final String? lastReason;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> prescriptions;

  const DoctorPatient({
    required this.id,
    required this.fullName,
    this.dob,
    this.gender,
    this.bloodGroup,
    this.profilePhotoUrl,
    this.phone,
    this.email,
    this.lastAppointmentStatus,
    this.lastAppointmentAt,
    this.lastReason,
    this.appointments = const [],
    this.prescriptions = const [],
  });

  int get age {
    if (dob == null) return 0;
    final dobDt = DateTime.tryParse(dob!);
    if (dobDt == null) return 0;
    final now = DateTime.now();
    int a = now.year - dobDt.year;
    if (now.month < dobDt.month ||
        (now.month == dobDt.month && now.day < dobDt.day)) {
      a--;
    }
    return a;
  }

  factory DoctorPatient.fromJson(Map<String, dynamic> json) {
    return DoctorPatient(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Patient',
      dob: json['dob']?.toString(),
      gender: json['gender']?.toString(),
      bloodGroup: json['blood_group']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      phone: json['patient_phone']?.toString(),
      email: json['email']?.toString(),
      lastAppointmentStatus: json['last_appointment_status']?.toString(),
      lastAppointmentAt: json['last_appointment_at'] != null
          ? DateTime.tryParse(json['last_appointment_at'].toString())
          : null,
      lastReason: json['last_reason']?.toString(),
      appointments: json['appointments'] != null
          ? List<Map<String, dynamic>>.from(json['appointments'])
          : [],
      prescriptions: json['prescriptions'] != null
          ? List<Map<String, dynamic>>.from(json['prescriptions'])
          : [],
    );
  }
}

// ---------------------------------------------------------------------------
// Follow-up
// ---------------------------------------------------------------------------
enum FollowUpPriority {
  high,
  medium,
  low;

  String get label {
    switch (this) {
      case FollowUpPriority.high:
        return 'High Priority';
      case FollowUpPriority.medium:
        return 'Moderate';
      case FollowUpPriority.low:
        return 'Routine';
    }
  }

  Color get color {
    switch (this) {
      case FollowUpPriority.high:
        return const Color(0xFFDC2626);
      case FollowUpPriority.medium:
        return const Color(0xFFF59E0B);
      case FollowUpPriority.low:
        return const Color(0xFF10B981);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case FollowUpPriority.high:
        return const Color(0xFFFEE2E2);
      case FollowUpPriority.medium:
        return const Color(0xFFFEF3C7);
      case FollowUpPriority.low:
        return const Color(0xFFECFDF5);
    }
  }
}

class FollowUpPatient {
  final String id;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientPhone;
  final String primaryCondition;
  final String lastConsultationDate;
  final String followUpDueDate;
  final int daysRemaining;
  final String lastPrescriptionOrPlan;
  final FollowUpPriority priority;
  bool isFollowedUp;
  final String status;

  FollowUpPatient({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientPhone,
    required this.primaryCondition,
    required this.lastConsultationDate,
    required this.followUpDueDate,
    required this.daysRemaining,
    required this.lastPrescriptionOrPlan,
    this.priority = FollowUpPriority.medium,
    this.isFollowedUp = false,
    this.status = 'upcoming',
  });

  factory FollowUpPatient.fromJson(Map<String, dynamic> json) {
    final followUpDate = json['follow_up_date'] != null
        ? DateTime.tryParse(json['follow_up_date'].toString())
        : null;
    final now = DateTime.now();
    int daysRemaining = 0;
    String followUpDueDate = 'Unknown';
    if (followUpDate != null) {
      daysRemaining = followUpDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (daysRemaining == 0) {
        followUpDueDate = 'Today (Due)';
      } else if (daysRemaining < 0) {
        followUpDueDate = 'Overdue by ${daysRemaining.abs()} days';
      } else {
        followUpDueDate = 'In $daysRemaining days';
      }
    }

    final patDob = json['patient_dob'] != null
        ? DateTime.tryParse(json['patient_dob'].toString())
        : null;
    int age = 0;
    if (patDob != null) {
      age = now.year - patDob.year;
      if (now.month < patDob.month ||
          (now.month == patDob.month && now.day < patDob.day)) {
        age--;
      }
    }

    final status = json['status']?.toString() ?? 'upcoming';

    return FollowUpPatient(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? 'Patient',
      patientAge: age,
      patientGender: json['patient_gender']?.toString() ?? 'Unknown',
      patientPhone: json['patient_phone']?.toString() ?? '',
      primaryCondition: json['notes']?.toString() ?? 'Follow-up required',
      lastConsultationDate: 'See records',
      followUpDueDate: followUpDueDate,
      daysRemaining: daysRemaining,
      lastPrescriptionOrPlan: json['notes']?.toString() ?? '',
      priority: daysRemaining < 0
          ? FollowUpPriority.high
          : (daysRemaining <= 2 ? FollowUpPriority.medium : FollowUpPriority.low),
      isFollowedUp: status == 'completed',
      status: status,
    );
  }
}

// ---------------------------------------------------------------------------
// Notification
// ---------------------------------------------------------------------------
enum NotificationCategory {
  patientMessage,
  appointmentRequest,
  labReport,
  systemAlert;

  IconData get icon {
    switch (this) {
      case NotificationCategory.patientMessage:
        return Icons.chat_bubble_outline_rounded;
      case NotificationCategory.appointmentRequest:
        return Icons.calendar_month_rounded;
      case NotificationCategory.labReport:
        return Icons.science_outlined;
      case NotificationCategory.systemAlert:
        return Icons.notifications_active_outlined;
    }
  }

  Color get color {
    switch (this) {
      case NotificationCategory.patientMessage:
        return const Color(0xFF0072FF);
      case NotificationCategory.appointmentRequest:
        return const Color(0xFFF59E0B);
      case NotificationCategory.labReport:
        return const Color(0xFF8B5CF6);
      case NotificationCategory.systemAlert:
        return const Color(0xFF10B981);
    }
  }
}

class DoctorNotificationItem {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final NotificationCategory category;
  bool isRead;
  final String? patientName;
  final String? actionPayload;

  DoctorNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.category,
    this.isRead = false,
    this.patientName,
    this.actionPayload,
  });
}

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------
class DoctorDashboardStats {
  final int todayAppointments;
  final int upcomingAppointments;
  final int pendingRequests;
  final int completedConsultations;
  final int followUpRequired;
  final int unreadNotifications;

  const DoctorDashboardStats({
    required this.todayAppointments,
    required this.upcomingAppointments,
    required this.pendingRequests,
    required this.completedConsultations,
    required this.followUpRequired,
    required this.unreadNotifications,
  });
}

// ---------------------------------------------------------------------------
// Chat
// ---------------------------------------------------------------------------
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String time;
  final bool isDoctor;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.time,
    required this.isDoctor,
  });
}

class PatientChatThread {
  final String id;
  final String consultationId;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientLocation;
  final String lastMessage;
  final String lastMessageTime;
  int unreadCount;
  final bool isOnline;
  final String? avatarUrl;
  final List<ChatMessage> messages;

  PatientChatThread({
    required this.id,
    required this.consultationId,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientLocation,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.avatarUrl,
    required this.messages,
  });

  factory PatientChatThread.fromJson(Map<String, dynamic> json) {
    final lastMsgAt = json['last_message_at'] != null
        ? DateTime.tryParse(json['last_message_at'].toString())
        : null;
    final unread = int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0;

    return PatientChatThread(
      id: json['consultation_id']?.toString() ?? '',
      consultationId: json['consultation_id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? 'Patient',
      patientAge: 0,
      patientGender: 'Unknown',
      patientLocation: '',
      lastMessage: json['last_message']?.toString() ?? 'Start the conversation',
      lastMessageTime: lastMsgAt != null ? _timeAgo(lastMsgAt) : 'No messages',
      unreadCount: unread,
      avatarUrl: json['patient_photo_url']?.toString(),
      messages: [],
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}

// ---------------------------------------------------------------------------
// Prescription
// ---------------------------------------------------------------------------
class PrescriptionItem {
  final String medicineName;
  final String dosage;
  final String duration;
  final String instructions;

  PrescriptionItem({
    required this.medicineName,
    required this.dosage,
    required this.duration,
    required this.instructions,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      medicineName: json['medicine_name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      duration: json['duration_days'] != null
          ? '${json['duration_days']} Days'
          : '',
      instructions: json['instructions']?.toString() ?? '',
    );
  }
}

class PrescriptionRecord {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientPhotoUrl;
  final String date;
  final String diagnosis;
  final List<PrescriptionItem> medicines;
  final String clinicalAdvice;
  final String? nextFollowUp;
  final String facilityName;

  PrescriptionRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientPhotoUrl,
    required this.date,
    required this.diagnosis,
    required this.medicines,
    required this.clinicalAdvice,
    this.nextFollowUp,
    this.facilityName = 'SwasthyaSathi Telehealth Nepal',
  });

  factory PrescriptionRecord.fromJson(Map<String, dynamic> json) {
    final issuedAt = json['issued_at'] != null
        ? DateTime.tryParse(json['issued_at'].toString())
        : null;
    final dateStr = issuedAt != null
        ? '${_months[issuedAt.month]} ${issuedAt.day}, ${issuedAt.year}'
        : 'Unknown';

    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .map((i) => PrescriptionItem.fromJson(i as Map<String, dynamic>))
            .toList()
        : <PrescriptionItem>[];

    return PrescriptionRecord(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? 'Patient',
      patientPhotoUrl: json['patient_photo_url']?.toString(),
      date: dateStr,
      diagnosis: json['notes']?.toString() ?? 'Prescription issued',
      medicines: items,
      clinicalAdvice: json['notes']?.toString() ?? '',
    );
  }

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
