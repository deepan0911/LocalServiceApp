import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/models.dart';

class ChatProvider extends ChangeNotifier {
  IO.Socket? _socket;
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _currentBookingId;
  final _storage = const FlutterSecureStorage();

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;

  Future<void> connectSocket() async {
    final token = await _storage.read(key: 'auth_token');
    _socket = IO.io(
      'https://local-service-backend-k2aq.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .build(),
    );
    _socket!.onConnect((_) => debugPrint('Chat socket connected'));
    _socket!.on('new_message', _onNewMessage);
    _socket!.on('user_typing', (_) { _isTyping = true; notifyListeners(); });
    _socket!.on('user_stop_typing', (_) { _isTyping = false; notifyListeners(); });
  }

  void joinBookingRoom(String bookingId) {
    _currentBookingId = bookingId;
    _socket?.emit('join_booking', {'bookingId': bookingId});
  }

  Future<void> loadMessages(String bookingId) async {
    _isLoading = true;
    _messages = [];
    notifyListeners();
    try {
      final res = await ApiClient.dio.get('/chat/$bookingId');
      _messages = (res.data['data'] as List).map((m) => MessageModel.fromJson(m)).toList();
    } on DioException catch (e) {
      debugPrint('Chat load error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void sendTextMessage(String content) {
    _socket?.emit('send_message', {
      'bookingId': _currentBookingId,
      'content': content,
    });
  }

  Future<void> sendImageMessage(String imagePath) async {
    if (_currentBookingId == null) return;
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath),
    });
    await ApiClient.dio.post('/chat/$_currentBookingId', data: formData);
  }

  void emitTyping() => _socket?.emit('typing', {'bookingId': _currentBookingId});
  void emitStopTyping() => _socket?.emit('stop_typing', {'bookingId': _currentBookingId});

  void _onNewMessage(dynamic data) {
    _messages.add(MessageModel.fromJson(data));
    notifyListeners();
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
  }

  @override
  void dispose() {
    disconnectSocket();
    super.dispose();
  }
}
