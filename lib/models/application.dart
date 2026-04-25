class Application {
  final String applicationId;
  final String jobId;
  final String seekerId;
  final String applyMethod;
  final String? resumeUrl;
  final String status;
  final DateTime appliedAt;
  final String? jobTitle;
  final String? employerName;
  final String? seekerName;
  final List<String>? seekerSkills;
  final DateTime? interviewScheduledAt;

  const Application({
    required this.applicationId,
    required this.jobId,
    required this.seekerId,
    required this.applyMethod,
    this.resumeUrl,
    required this.status,
    required this.appliedAt,
    this.jobTitle,
    this.employerName,
    this.seekerName,
    this.seekerSkills,
    this.interviewScheduledAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) => Application(
        applicationId: json['applicationId'] ?? json['_id'] ?? '',
        jobId: json['jobId'] ?? '',
        seekerId: json['seekerId'] ?? '',
        applyMethod: json['applyMethod'] ?? '',
        resumeUrl: json['resumeUrl'],
        status: json['status'] ?? 'pending',
        appliedAt: json['appliedAt'] != null
            ? (json['appliedAt'] is String
                ? DateTime.tryParse(json['appliedAt']) ?? DateTime.now()
                : (json['appliedAt'] as dynamic).toDate())
            : DateTime.now(),
        jobTitle: json['jobTitle'],
        employerName: json['employerName'],
        seekerName: json['seekerName'],
        seekerSkills: json['seekerSkills'] != null
            ? List<String>.from(json['seekerSkills'])
            : null,
        interviewScheduledAt: json['interviewScheduledAt'] != null
            ? DateTime.parse(json['interviewScheduledAt'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'applicationId': applicationId,
        'jobId': jobId,
        'seekerId': seekerId,
        'applyMethod': applyMethod,
        'resumeUrl': resumeUrl,
        'status': status,
        'appliedAt': appliedAt.toIso8601String(),
      };
}
