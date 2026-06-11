/// User model — info từ /api/me. Mở rộng 2026-05-05 với 9 field profile bổ sung
/// (DOB, gender, address, CCCD, ethnicity, religion, nationality,
/// place_of_birth, secondary_email).
class UserModel {
  final int userId;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String status;
  final List<String> roles;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  // Profile mở rộng
  final DateTime? dob;
  final String? gender;
  final String? citizenId;
  final String? placeOfBirth;
  final String? address;
  final String? ethnicity;
  final String? religion;
  final String? nationality;
  final String? secondaryEmail;

  UserModel({
    required this.userId,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.status,
    required this.roles,
    this.lastLoginAt,
    required this.createdAt,
    this.dob,
    this.gender,
    this.citizenId,
    this.placeOfBirth,
    this.address,
    this.ethnicity,
    this.religion,
    this.nationality,
    this.secondaryEmail,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: json['user_id'] as int,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        status: json['status'] as String,
        roles: List<String>.from(json['roles'] ?? []),
        lastLoginAt: json['last_login_at'] != null
            ? DateTime.parse(json['last_login_at'])
            : null,
        createdAt: DateTime.parse(json['created_at']),
        dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
        gender: json['gender'] as String?,
        citizenId: json['citizen_id'] as String?,
        placeOfBirth: json['place_of_birth'] as String?,
        address: json['address'] as String?,
        ethnicity: json['ethnicity'] as String?,
        religion: json['religion'] as String?,
        nationality: json['nationality'] as String?,
        secondaryEmail: json['secondary_email'] as String?,
      );

  bool hasRole(String role) => roles.contains(role);
  bool get isStudent => hasRole('STUDENT');
  bool get isOrganizer => hasRole('ORGANIZER');
  bool get isJudge => hasRole('JUDGE');
  bool get isHod => hasRole('HOD');
  bool get isAdmin => hasRole('ADMIN');
}
