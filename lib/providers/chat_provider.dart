import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentApplicationId;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMessages(String applicationId) async {
    _currentApplicationId = applicationId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _subscription?.cancel();

    _subscription = _db
        .collection('messages')
        .where('applicationId', isEqualTo: applicationId)
        .orderBy('createdAt')
        .snapshots()
        .listen((snap) {
      _messages = snap.docs.map((d) {
        final data = d.data();
        final ts = data['createdAt'];
        return Message.fromJson({
          ...data,
          'messageId': d.id,
          'createdAt': ts is Timestamp
              ? ts.toDate().toIso8601String()
              : DateTime.now().toIso8601String(),
        });
      }).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    if (_currentApplicationId == null) return;

    // Optimistic update
    final optimistic = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      receiverId: receiverId,
      applicationId: _currentApplicationId!,
      content: content,
      isRead: false,
      createdAt: DateTime.now(),
    );
    _messages.add(optimistic);
    notifyListeners();

    await _db.collection('messages').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'applicationId': _currentApplicationId!,
      'content': content,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void clearChat() {
    _subscription?.cancel();
    _subscription = null;
    _messages = [];
    _currentApplicationId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
