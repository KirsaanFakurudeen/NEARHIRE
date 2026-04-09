class NotificationModel {
  final String notifId;
  final String userId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? referenceId;

  const NotificationModel({
    required this.notifId,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.referenceId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        notifId: json['notifId'] ?? json['_id'] ?? '',
        userId: json['userId'] ?? '',
        type: json['type'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        isRead: json['isRead'] ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        referenceId: json['referenceId'],
      );

  Map<String, dynamic> toJson() => {
        'notifId': notifId,
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'referenceId': referenceId,
      };
}
