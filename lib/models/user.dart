class User {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final bool otpVerified;

  const User({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.otpVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json['userId'] ?? json['_id'] ?? '',
        fullName: json['fullName'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        role: json['role'] ?? '',
        otpVerified: json['otpVerified'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'otpVerified': otpVerified,
      };
}
