class DoctorRegisterModel {
  final String firstName;
  final String lastName;
  final String nmcNumber; // Nepal Medical Council registration number
  final String specialty;
  final String hospitalAffiliation;
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
    required this.specialty,
    required this.hospitalAffiliation,
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
      'firstName': firstName,
      'lastName': lastName,
      'nmcNumber': nmcNumber,
      'specialty': specialty,
      'hospitalAffiliation': hospitalAffiliation,
      'countryCode': countryCode,
      'mobileNumber': mobileNumber,
      'email': email,
      'role': 'doctor',
      'agreedToTerms': agreedToTerms,
      'registeredAt': registeredAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'DoctorRegisterModel(name: $fullName, nmc: $nmcNumber, specialty: $specialty)';
  }
}
