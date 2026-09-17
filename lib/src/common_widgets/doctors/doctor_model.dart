class DoctorModel {
  final String id;
  final String name;
  final String specialty;
  final String location;
  final String flagEmoji;
  final String avatarUrl;
  final int recommendationsCount;
  final double rating;
  final String responseTime;
  final String consultationFee;
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
    required this.location,
    required this.flagEmoji,
    required this.avatarUrl,
    required this.recommendationsCount,
    required this.rating,
    required this.responseTime,
    required this.consultationFee,
    required this.videoIntroTitle,
    required this.services,
    required this.hospitalAffiliations,
    required this.memberships,
    required this.education,
    required this.certifications,
  });

  static const List<DoctorModel> sampleDoctors = [
    DoctorModel(
      id: 'doc_1',
      name: 'Dr. Bikash Sharma',
      specialty: 'Emergency & Internal Medicine',
      location: 'Kathmandu, Nepal',
      flagEmoji: '🇳🇵',
      avatarUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&q=80',
      recommendationsCount: 124,
      rating: 4.9,
      responseTime: 'Responds within 15 mins',
      consultationFee: 'NRs 1,200',
      videoIntroTitle: 'Introduction to Tele-Triage & Rural Care',
      services: [
        'Acute Medical Consultation',
        'Fever & Infection Management',
        'Emergency Remote Triage',
        'Chronic Illness Follow-up'
      ],
      hospitalAffiliations: [
        'Tribhuvan University Teaching Hospital (TUTH)',
        'Grande International Hospital',
        'Swasthya Sathi Tele-network'
      ],
      memberships: [
        'Nepal Medical Association (NMA)',
        'Society of Internal Medicine of Nepal (SIMON)'
      ],
      education: [
        'MBBS - Institute of Medicine (IOM), Maharajgunj',
        'MD Internal Medicine - TUTH, Nepal'
      ],
      certifications: [
        'Board Certified in Emergency Medicine',
        'Advanced Cardiac Life Support (ACLS)'
      ],
    ),
    DoctorModel(
      id: 'doc_2',
      name: 'Dr. Anjali Shrestha',
      specialty: 'Obstetrics & Gynecology',
      location: 'Lalitpur, Nepal',
      flagEmoji: '🇳🇵',
      avatarUrl: 'https://images.unsplash.com/photo-1594824813566-78a9c2794025?w=400&q=80',
      recommendationsCount: 98,
      rating: 4.8,
      responseTime: 'Responds within 30 mins',
      consultationFee: 'NRs 1,500',
      videoIntroTitle: 'Maternal Health & Antenatal Care Guide',
      services: [
        'High-Risk Pregnancy Care',
        'Prenatal & Postnatal Counseling',
        'Reproductive Health',
        'Routine Gynecological Exams'
      ],
      hospitalAffiliations: [
        'Patan Hospital',
        'Norvic International Hospital'
      ],
      memberships: [
        'Nepal Society of Obstetricians & Gynecologists (NESOG)'
      ],
      education: [
        'MBBS - Kathmandu Medical College',
        'MD Obstetrics & Gynecology - BPKIHS'
      ],
      certifications: [
        'Fetal Medicine Foundation Certified',
        'Laparoscopic Surgery Fellowship'
      ],
    ),
    DoctorModel(
      id: 'doc_3',
      name: 'Dr. Ismail Aboul Foutouh',
      specialty: 'Obstetrics & Gynecology',
      location: 'Cairo, Egypt',
      flagEmoji: '🇪🇬',
      avatarUrl: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=400&q=80',
      recommendationsCount: 83,
      rating: 4.9,
      responseTime: 'Responds within 1 hour',
      consultationFee: 'NRs 2,400',
      videoIntroTitle: 'Advanced Gynecological Consultations',
      services: [
        'Infertility Treatment',
        'Ultrasound Consultation',
        'Fetal Health Assessment'
      ],
      hospitalAffiliations: [
        'Cairo University Hospitals',
        'International Women Center'
      ],
      memberships: [
        'Egyptian Medical Syndicate',
        'International Federation of Gynaecology (FIGO)'
      ],
      education: [
        'MBBS, MD - Cairo University Faculty of Medicine'
      ],
      certifications: [
        'Subspecialty Certification in Reproductive Endocrinology'
      ],
    ),
    DoctorModel(
      id: 'doc_4',
      name: 'Dr. Gael Abou Ghannam',
      specialty: 'Obstetrics & Gynecology',
      location: 'Beirut, Lebanon',
      flagEmoji: '🇱🇧',
      avatarUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&q=80',
      recommendationsCount: 112,
      rating: 4.9,
      responseTime: 'Responds within 3 hours',
      consultationFee: 'NRs 2,800',
      videoIntroTitle: 'Women’s Wellness & Tele-Care',
      services: [
        'Preventive Gynecology',
        'Hormonal Therapy Consultation',
        'Adolescent Health'
      ],
      hospitalAffiliations: [
        'American University of Beirut Medical Center'
      ],
      memberships: [
        'Lebanese Order of Physicians'
      ],
      education: [
        'MD - American University of Beirut'
      ],
      certifications: [
        'European Board of Obstetrics and Gynaecology (EBCOG)'
      ],
    ),
  ];
}
