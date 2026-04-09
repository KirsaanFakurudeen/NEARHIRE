class EmployerProfile {
  final String employerId;
  final String userId;
  final String businessName;
  final String type;
  final String description;
  final double latitude;
  final double longitude;
  final bool verified;

  const EmployerProfile({
    required this.employerId,
    required this.userId,
    required this.businessName,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.verified,
  });

  factory EmployerProfile.fromJson(Map<String, dynamic> json) => EmployerProfile(
        employerId: json['employerId'] ?? json['_id'] ?? '',
        userId: json['userId'] ?? '',
        businessName: json['businessName'] ?? '',
        type: json['type'] ?? '',
        description: json['description'] ?? '',
        latitude: (json['latitude'] ?? 0).toDouble(),
        longitude: (json['longitude'] ?? 0).toDouble(),
        verified: json['verified'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'employerId': employerId,
        'userId': userId,
        'businessName': businessName,
        'type': type,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'verified': verified,
      };
}
