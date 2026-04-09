class Message {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String applicationId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.applicationId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        messageId: json['messageId'] ?? json['_id'] ?? '',
        senderId: json['senderId'] ?? '',
        receiverId: json['receiverId'] ?? '',
        applicationId: json['applicationId'] ?? '',
        content: json['content'] ?? '',
        isRead: json['isRead'] ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'senderId': senderId,
        'receiverId': receiverId,
        'applicationId': applicationId,
        'content': content,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
      };
}
