/// Represents the authenticated user returned by the backend after
/// a successful register or login call.
class AuthUser {
  final String id;
  final String phone;
  final String? email;
  final String role;          // 'patient' | 'doctor'
  final String token;         // JWT bearer token
  final String? fullName;     // from role-specific profile

  const AuthUser({
    required this.id,
    required this.phone,
    this.email,
    required this.role,
    required this.token,
    this.fullName,
  });

  bool get isPatient => role == 'patient';
  bool get isDoctor  => role == 'doctor';

  /// Build from the JSON envelope the backend returns:
  /// { token, user: { id, phone, email, role, … }, profile: { full_name, … } }
  factory AuthUser.fromApiResponse(Map<String, dynamic> json) {
    final userRaw = json['user'];
    final profileRaw = json['profile'];
    final user = userRaw is Map ? Map<String, dynamic>.from(userRaw) : <String, dynamic>{};
    final profile = profileRaw is Map ? Map<String, dynamic>.from(profileRaw) : <String, dynamic>{};

    return AuthUser(
      id:       (user['id'] ?? '').toString(),
      phone:    (user['phone'] ?? '').toString(),
      email:    user['email'] as String?,
      role:     (user['role'] ?? 'patient').toString(),
      token:    (json['token'] ?? '').toString(),
      fullName: profile['full_name'] as String?,
    );
  }

  @override
  String toString() =>
      'AuthUser(id: $id, role: $role, name: $fullName, phone: $phone)';
}
