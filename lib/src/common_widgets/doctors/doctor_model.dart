/// Represents a doctor returned from the backend API.
class DoctorModel {
  final String id;
  final String name;
  final String specialty;       // first specialization name, or 'General'
  final List<String> specializations;
  final String location;
  final String flagEmoji;
  final String avatarUrl;
  final int recommendationsCount;
  final double rating;
  final String consultationFee; // formatted string e.g. "NRs 1,200"
  final double feeAmount;
  final bool isAvailable;
  final int experienceYears;
  final String? bio;
  final String responseTime;
  final String videoIntroTitle;
  final List<String> services;
  final List<String> hospitalAffiliations;
  final List<String> memberships;
  final List<String> education;
  final List<String> certifications;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    this.specializations = const [],
    this.location = 'Nepal',
    this.flagEmoji = '🇳🇵',
    required this.avatarUrl,
    this.recommendationsCount = 0,
    required this.rating,
    required this.consultationFee,
    required this.feeAmount,
    this.isAvailable = true,
    this.experienceYears = 0,
    this.bio,
    this.responseTime = 'Responds within 30 mins',
    this.videoIntroTitle = 'Online Consultation',
    this.services = const [],
    this.hospitalAffiliations = const [],
    this.memberships = const [],
    this.education = const [],
    this.certifications = const [],
  });

  /// Deserialize from the backend API response (GET /api/v1/doctors or /doctors/:id).
  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final fee = double.tryParse(json['consultation_fee']?.toString() ?? '0') ?? 0;
    final specList = (json['specializations'] as List<dynamic>? ?? [])
        .map((s) => (s as Map<String, dynamic>)['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final primarySpec = specList.isNotEmpty ? specList.first : 'General Physician';

    return DoctorModel(
      id: json['id']?.toString() ?? '',
      name: json['full_name']?.toString() ?? 'Unknown Doctor',
      specialty: primarySpec,
      specializations: specList,
      avatarUrl: json['profile_photo_url']?.toString() ?? '',
      rating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0,
      consultationFee: 'NRs ${_formatFee(fee)}',
      feeAmount: fee,
      isAvailable: json['is_available'] as bool? ?? true,
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      bio: json['bio']?.toString(),
      recommendationsCount: 0,
    );
  }

  static String _formatFee(double fee) {
    if (fee >= 1000) {
      return fee.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return fee.toStringAsFixed(0);
  }

  /// Fallback sample list — used when API is unavailable (offline mode).
  static const List<DoctorModel> sampleDoctors = [
    DoctorModel(
      id: 'doc_1',
      name: 'Dr. Bikash Sharma',
      specialty: 'Emergency & Internal Medicine',
      avatarUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&q=80',
      rating: 4.9,
      consultationFee: 'NRs 1,200',
      feeAmount: 1200,
      recommendationsCount: 124,
      responseTime: 'Responds within 15 mins',
      videoIntroTitle: 'Introduction to Tele-Triage & Rural Care',
      services: [
        'Acute Medical Consultation',
        'Fever & Infection Management',
        'Emergency Remote Triage',
        'Chronic Illness Follow-up',
      ],
      hospitalAffiliations: [
        'Tribhuvan University Teaching Hospital (TUTH)',
        'Grande International Hospital',
      ],
      memberships: ['Nepal Medical Association (NMA)'],
      education: ['MBBS - IOM, Maharajgunj', 'MD Internal Medicine - TUTH'],
      certifications: ['Board Certified in Emergency Medicine', 'ACLS'],
    ),
    DoctorModel(
      id: 'doc_2',
      name: 'Dr. Anjali Shrestha',
      specialty: 'Obstetrics & Gynecology',
      location: 'Lalitpur, Nepal',
      avatarUrl: 'https://images.unsplash.com/photo-1594824813566-78a9c2794025?w=400&q=80',
      rating: 4.8,
      consultationFee: 'NRs 1,500',
      feeAmount: 1500,
      recommendationsCount: 98,
      responseTime: 'Responds within 30 mins',
      videoIntroTitle: 'Maternal Health & Antenatal Care',
      services: [
        'High-Risk Pregnancy Care',
        'Prenatal & Postnatal Counseling',
        'Reproductive Health',
      ],
      hospitalAffiliations: ['Patan Hospital', 'Norvic International Hospital'],
      memberships: ['NESOG'],
      education: ['MBBS - KMC', 'MD OBG - BPKIHS'],
      certifications: ['Fetal Medicine Foundation Certified'],
    ),
  ];
}
