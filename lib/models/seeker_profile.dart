class SeekerProfile {
  final String seekerId;
  final String userId;
  final List<String> skills;
  final String experience;
  final String availability;
  final String? resumeUrl;
  final double latitude;
  final double longitude;

  const SeekerProfile({
    required this.seekerId,
    required this.userId,
    required this.skills,
    required this.experience,
    required this.availability,
    this.resumeUrl,
    required this.latitude,
    required this.longitude,
  });

  factory SeekerProfile.fromJson(Map<String, dynamic> json) => SeekerProfile(
        seekerId: json['seekerId'] ?? json['_id'] ?? '',
        userId: json['userId'] ?? '',
        skills: List<String>.from(json['skills'] ?? []),
        experience: json['experience'] ?? '',
        availability: json['availability'] ?? '',
        resumeUrl: json['resumeUrl'],
        latitude: (json['latitude'] ?? 0).toDouble(),
        longitude: (json['longitude'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'seekerId': seekerId,
        'userId': userId,
        'skills': skills,
        'experience': experience,
        'availability': availability,
        'resumeUrl': resumeUrl,
        'latitude': latitude,
        'longitude': longitude,
      };
}
