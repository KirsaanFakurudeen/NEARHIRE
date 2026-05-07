import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Global navigator key — set this in main.dart MaterialApp
  static final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _fcm.requestPermission();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (details) {
        // Local notification tapped while app is in foreground
        final payload = details.payload;
        if (payload != null) _navigateFromPayload(payload);
      },
    );

    // Foreground message — show local notification
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'nearhire_channel',
            'NearHire',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: _payloadFromData(message.data),
      );
    });

    // App opened from background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateFromData(message.data);
    });

    // App launched from terminated state via notification tap
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // Delay to let the widget tree mount
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateFromData(initial.data);
      });
    }
  }

  Future<String?> getToken() => _fcm.getToken();

  String _payloadFromData(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final refId = data['referenceId'] ?? '';
    return '$type:$refId';
  }

  void _navigateFromPayload(String payload) {
    final parts = payload.split(':');
    if (parts.length < 2) return;
    _navigateFromData({'type': parts[0], 'referenceId': parts.sublist(1).join(':')});
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final refId = data['referenceId'] as String? ?? '';
    final nav = navigatorKey.currentState;
    if (nav == null || type == null) return;

    switch (type) {
      case 'job':
        nav.pushNamed('/job-detail', arguments: {'jobId': refId});
        break;
      case 'application':
      case 'interview':
        nav.pushNamed('/application-status');
        break;
      case 'message':
        nav.pushNamed('/chat', arguments: {
          'applicationId': refId,
          'otherUserId': '',
          'otherUserName': '',
          'otherUserRole': '',
        });
        break;
      default:
        nav.pushNamed('/notifications');
    }
  }
}
