class PatientRegisterModel {
  final String firstName;
  final String lastName;
  final String countryCode;
  final String mobileNumber;
  final String email;
  final String? gender;
  final DateTime? dob;
  final String? bloodGroup;
  final String password;
  final bool agreedToTerms;
  final DateTime registeredAt;

  PatientRegisterModel({
    required this.firstName,
    required this.lastName,
    this.countryCode = '+977',
    required this.mobileNumber,
    required this.email,
    this.gender,
    this.dob,
    this.bloodGroup,
    required this.password,
    required this.agreedToTerms,
    DateTime? registeredAt,
  }) : registeredAt = registeredAt ?? DateTime.now();

  String get fullName => '$firstName $lastName'.trim();
  String get fullPhoneNumber => '$countryCode$mobileNumber';
  String? get formattedDob => dob != null
      ? '${dob!.year.toString().padLeft(4, '0')}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}'
      : null;

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': fullPhoneNumber,
      'email': email.isNotEmpty ? email : null,
      'gender': gender,
      'dob': formattedDob,
      'blood_group': bloodGroup,
      'password': password,
      'role': 'patient',
      'registeredAt': registeredAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PatientRegisterModel(name: $fullName, phone: $fullPhoneNumber, gender: $gender, bloodGroup: $bloodGroup)';
  }
}
