import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../core/services/api_service.dart';
import '../core/services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final SocketService _socket = SocketService();

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentApplicationId;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMessages(String applicationId) async {
    _currentApplicationId = applicationId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/messages/$applicationId');
      final List data = res.data['messages'] ?? [];
      _messages = data.map((m) => Message.fromJson(m)).toList();
      _socket.joinRoom(applicationId);
      _socket.offMessages();
      _socket.listenForMessages(_onMessageReceived);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onMessageReceived(Map<String, dynamic> data) {
    final message = Message.fromJson(data);
    _messages.add(message);
    notifyListeners();
  }

  void sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) {
    if (_currentApplicationId == null) return;

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

    _socket.sendMessage(
      senderId: senderId,
      receiverId: receiverId,
      applicationId: _currentApplicationId!,
      content: content,
    );
  }

  void clearChat() {
    _messages = [];
    _currentApplicationId = null;
    _socket.offMessages();
    notifyListeners();
  }
}
