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
        return "Today";
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
    this.consultationFee = 'NRs 800',
    this.feeAmount = 800.0,
    this.duration,
  });

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
  final int daysRemaining; // negative means overdue
  final String lastPrescriptionOrPlan;
  final FollowUpPriority priority;
  bool isFollowedUp;

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
  });
}

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
}

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
}

class PrescriptionRecord {
  final String id;
  final String patientId;
  final String patientName;
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
    required this.date,
    required this.diagnosis,
    required this.medicines,
    required this.clinicalAdvice,
    this.nextFollowUp,
    this.facilityName = 'SwasthyaSathi Telehealth Nepal',
  });
}

