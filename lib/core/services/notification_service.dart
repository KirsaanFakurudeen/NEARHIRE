// Stubbed for UI testing - re-enable Firebase imports when google-services.json is added
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  void Function(String type, String referenceId)? onNotificationTap;

  Future<void> initialize() async {}
}
