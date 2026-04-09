import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  void connect(String token) {
    _socket = IO.io(
      AppConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
    _socket!.connect();
  }

  void joinRoom(String roomId) {
    _socket?.emit('join_room', {'roomId': roomId});
  }

  void sendMessage({
    required String senderId,
    required String receiverId,
    required String applicationId,
    required String content,
  }) {
    _socket?.emit('send_message', {
      'senderId': senderId,
      'receiverId': receiverId,
      'applicationId': applicationId,
      'content': content,
    });
  }

  void listenForMessages(void Function(Map<String, dynamic>) callback) {
    _socket?.on('receive_message', (data) {
      if (data is Map<String, dynamic>) callback(data);
    });
  }

  void offMessages() {
    _socket?.off('receive_message');
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
}
