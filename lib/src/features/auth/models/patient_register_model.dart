class PatientRegisterModel {
  final String firstName;
  final String lastName;
  final String countryCode;
  final String mobileNumber;
  final String email;
  final String howDidYouHear;
  final String? reference;
  final String password;
  final bool agreedToTerms;
  final DateTime registeredAt;

  PatientRegisterModel({
    required this.firstName,
    required this.lastName,
    this.countryCode = '+977',
    required this.mobileNumber,
    required this.email,
    required this.howDidYouHear,
    this.reference,
    required this.password,
    required this.agreedToTerms,
    DateTime? registeredAt,
  }) : registeredAt = registeredAt ?? DateTime.now();

  String get fullName => '$firstName $lastName'.trim();
  String get fullPhoneNumber => '$countryCode$mobileNumber';

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'countryCode': countryCode,
      'mobileNumber': mobileNumber,
      'email': email,
      'howDidYouHear': howDidYouHear,
      'reference': reference,
      'role': 'patient',
      'agreedToTerms': agreedToTerms,
      'registeredAt': registeredAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PatientRegisterModel(name: $fullName, phone: $fullPhoneNumber, email: $email)';
  }
}
