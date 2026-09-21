class PatientProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String? dob;
  final String? gender;
  final String? bloodGroup;
  final int? municipalityId;
  final String? wardNo;
  final String? addressLine;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? profilePhotoUrl;
  final String phone;
  final String? email;
  final String preferredLanguage;
  final String status;
  final String? location;

  const PatientProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.dob,
    this.gender,
    this.bloodGroup,
    this.municipalityId,
    this.wardNo,
    this.addressLine,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.profilePhotoUrl,
    required this.phone,
    this.email,
    this.preferredLanguage = 'en',
    this.status = 'active',
    this.location = 'Nepal',
  });

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    String loc = 'Nepal';
    if (json['address_line'] != null && json['address_line'].toString().isNotEmpty) {
      loc = json['address_line'].toString();
    } else if (json['ward_no'] != null && json['ward_no'].toString().isNotEmpty) {
      loc = 'Ward ${json['ward_no']}, Nepal';
    }

    return PatientProfileModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      fullName: (json['full_name'] ?? 'User').toString(),
      dob: json['dob']?.toString(),
      gender: json['gender']?.toString(),
      bloodGroup: json['blood_group']?.toString(),
      municipalityId: json['municipality_id'] is int ? json['municipality_id'] as int : null,
      wardNo: json['ward_no']?.toString(),
      addressLine: json['address_line']?.toString(),
      emergencyContactName: json['emergency_contact_name']?.toString(),
      emergencyContactPhone: json['emergency_contact_phone']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      phone: (json['phone'] ?? '').toString(),
      email: json['email']?.toString(),
      preferredLanguage: (json['preferred_language'] ?? 'en').toString(),
      status: (json['status'] ?? 'active').toString(),
      location: loc,
    );
  }

  PatientProfileModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? dob,
    String? gender,
    String? bloodGroup,
    int? municipalityId,
    String? wardNo,
    String? addressLine,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? profilePhotoUrl,
    String? phone,
    String? email,
    String? preferredLanguage,
    String? status,
    String? location,
  }) {
    return PatientProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      municipalityId: municipalityId ?? this.municipalityId,
      wardNo: wardNo ?? this.wardNo,
      addressLine: addressLine ?? this.addressLine,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      status: status ?? this.status,
      location: location ?? this.location,
    );
  }
}
