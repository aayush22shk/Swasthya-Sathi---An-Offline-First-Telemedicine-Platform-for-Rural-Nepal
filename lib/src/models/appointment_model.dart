/// Appointment status matching backend enum values exactly.
enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  noShow;

  static AppointmentStatus fromString(String? s) {
    switch (s) {
      case 'confirmed':  return AppointmentStatus.confirmed;
      case 'completed':  return AppointmentStatus.completed;
      case 'cancelled':  return AppointmentStatus.cancelled;
      case 'no_show':    return AppointmentStatus.noShow;
      default:           return AppointmentStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case AppointmentStatus.pending:    return 'Pending';
      case AppointmentStatus.confirmed:  return 'Confirmed';
      case AppointmentStatus.completed:  return 'Completed';
      case AppointmentStatus.cancelled:  return 'Cancelled';
      case AppointmentStatus.noShow:     return 'No Show';
    }
  }

  /// Colour used in the patient's appointment status badge.
  static const Map<String, int> _statusColors = {
    'pending':   0xFFF59E0B, // amber
    'confirmed': 0xFF10B981, // emerald
    'completed': 0xFF0072FF, // blue
    'cancelled': 0xFFEF4444, // red
    'no_show':   0xFF94A3B8, // slate
  };

  int get colorValue => _statusColors[name] ?? 0xFF64748B;
}

/// Appointment model — maps from backend GET /appointments response.
class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String doctorPhotoUrl;
  final String specialty;           // doctor's primary specialization
  final DateTime scheduledAt;
  final String mode;               // 'video' | 'audio' | 'chat' | 'in_person'
  final AppointmentStatus status;
  final double fee;
  final String? reasonForVisit;
  final String? consultationId;    // set after consultation session starts

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.doctorPhotoUrl,
    required this.specialty,
    required this.scheduledAt,
    required this.mode,
    required this.status,
    required this.fee,
    this.reasonForVisit,
    this.consultationId,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id:             json['id']?.toString() ?? '',
      patientId:      json['patient_id']?.toString() ?? '',
      doctorId:       json['doctor_id']?.toString() ?? '',
      doctorName:     json['doctor_name']?.toString() ?? 'Unknown Doctor',
      // Both legacy `doctor_photo_url` and new field name supported
      doctorPhotoUrl: json['doctor_photo_url']?.toString() ?? '',
      // Enhanced query returns `doctor_specialty`, fallback to `specialty`
      specialty:      json['doctor_specialty']?.toString()
                   ?? json['specialty']?.toString()
                   ?? '',
      scheduledAt: DateTime.tryParse(json['scheduled_at']?.toString() ?? '') ?? DateTime.now(),
      mode:        json['mode']?.toString() ?? 'video',
      status:      AppointmentStatus.fromString(json['status']?.toString()),
      fee:         double.tryParse(json['fee']?.toString() ?? '0') ?? 0,
      reasonForVisit: json['reason_for_visit']?.toString(),
      consultationId: json['consultation_id']?.toString(),
    );
  }

  String get formattedDate {
    final now    = DateTime.now();
    final today  = DateTime(now.year, now.month, now.day);
    final apptDay = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    if (apptDay == today) return 'Today';
    if (apptDay == today.add(const Duration(days: 1))) return 'Tomorrow';
    return '${_monthName(scheduledAt.month)} ${scheduledAt.day}, ${scheduledAt.year}';
  }

  String get formattedTime {
    final h = scheduledAt.hour > 12
        ? scheduledAt.hour - 12
        : (scheduledAt.hour == 0 ? 12 : scheduledAt.hour);
    final m      = scheduledAt.minute.toString().padLeft(2, '0');
    final period = scheduledAt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  static String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}
