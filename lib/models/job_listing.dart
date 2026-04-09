class JobListing {
  final String jobId;
  final String employerId;
  final String title;
  final String description;
  final double payAmount;
  final String jobType;
  final String schedule;
  final List<String> requiredSkills;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final String status;
  final DateTime createdAt;
  final String? employerName;
  final bool? employerVerified;
  final double? employerRating;

  const JobListing({
    required this.jobId,
    required this.employerId,
    required this.title,
    required this.description,
    required this.payAmount,
    required this.jobType,
    required this.schedule,
    required this.requiredSkills,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.status,
    required this.createdAt,
    this.employerName,
    this.employerVerified,
    this.employerRating,
  });

  factory JobListing.fromJson(Map<String, dynamic> json) => JobListing(
        jobId: json['jobId'] ?? json['_id'] ?? '',
        employerId: json['employerId'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        payAmount: (json['payAmount'] ?? 0).toDouble(),
        jobType: json['jobType'] ?? '',
        schedule: json['schedule'] ?? '',
        requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
        latitude: (json['latitude'] ?? 0).toDouble(),
        longitude: (json['longitude'] ?? 0).toDouble(),
        radiusKm: (json['radiusKm'] ?? 10).toDouble(),
        status: json['status'] ?? 'active',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        employerName: json['employerName'],
        employerVerified: json['employerVerified'],
        employerRating: json['employerRating'] != null
            ? (json['employerRating']).toDouble()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'employerId': employerId,
        'title': title,
        'description': description,
        'payAmount': payAmount,
        'jobType': jobType,
        'schedule': schedule,
        'requiredSkills': requiredSkills,
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}
