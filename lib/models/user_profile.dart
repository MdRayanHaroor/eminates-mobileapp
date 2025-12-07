class UserProfile {
  final String id;
  final String? fullName;
  final String? email;
  final String? mobile;
  final String role;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.mobile,
    required this.role,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'mobile': mobile,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
