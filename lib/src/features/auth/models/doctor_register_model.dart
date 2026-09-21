class DoctorRegisterModel {
  final String firstName;
  final String lastName;
  final String nmcNumber; // Nepal Medical Council registration number
  final int experienceYears;
  final double consultationFee;
  final String? bio;
  final String countryCode;
  final String mobileNumber;
  final String email;
  final String password;
  final bool agreedToTerms;
  final DateTime registeredAt;

  DoctorRegisterModel({
    required this.firstName,
    required this.lastName,
    required this.nmcNumber,
    this.experienceYears = 0,
    this.consultationFee = 0.0,
    this.bio,
    this.countryCode = '+977',
    required this.mobileNumber,
    required this.email,
    required this.password,
    required this.agreedToTerms,
    DateTime? registeredAt,
  }) : registeredAt = registeredAt ?? DateTime.now();

  String get fullName => 'Dr. $firstName $lastName'.trim();
  String get fullPhoneNumber => '$countryCode$mobileNumber';

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'nmc_registration_number': nmcNumber,
      'experience_years': experienceYears,
      'consultation_fee': consultationFee,
      'bio': bio,
      'phone': fullPhoneNumber,
      'email': email.isNotEmpty ? email : null,
      'password': password,
      'role': 'doctor',
      'registeredAt': registeredAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'DoctorRegisterModel(name: $fullName, nmc: $nmcNumber, exp: $experienceYears yrs, fee: NPR $consultationFee)';
  }
}
