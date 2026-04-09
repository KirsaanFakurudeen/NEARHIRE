class Rating {
  final String ratingId;
  final String ratedBy;
  final String ratedUser;
  final String jobId;
  final double score;
  final String? review;

  const Rating({
    required this.ratingId,
    required this.ratedBy,
    required this.ratedUser,
    required this.jobId,
    required this.score,
    this.review,
  });

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
        ratingId: json['ratingId'] ?? json['_id'] ?? '',
        ratedBy: json['ratedBy'] ?? '',
        ratedUser: json['ratedUser'] ?? '',
        jobId: json['jobId'] ?? '',
        score: (json['score'] ?? 0).toDouble(),
        review: json['review'],
      );

  Map<String, dynamic> toJson() => {
        'ratingId': ratingId,
        'ratedBy': ratedBy,
        'ratedUser': ratedUser,
        'jobId': jobId,
        'score': score,
        'review': review,
      };
}
