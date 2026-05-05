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
      );

  bool hasRole(String role) => roles.contains(role);
  bool get isStudent => hasRole('STUDENT');
  bool get isOrganizer => hasRole('ORGANIZER');
  bool get isJudge => hasRole('JUDGE');
  bool get isHod => hasRole('HOD');
  bool get isAdmin => hasRole('ADMIN');
}
