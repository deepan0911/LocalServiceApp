import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';


const Color _primary   = Color(0xFF1E40AF);
const Color _textSub   = Color(0xFF64748B);
const Color _bgInput   = Color(0xFFF1F5F9);

class WorkerChatScreen extends StatefulWidget {
  final String bookingId;
  final String customerName;
  final String serviceType;

  const WorkerChatScreen({
    super.key,
    required this.bookingId,
    required this.customerName,
    required this.serviceType,
  });

  @override
  State<WorkerChatScreen> createState() => _WorkerChatScreenState();
}

class _WorkerChatScreenState extends State<WorkerChatScreen> {
  IO.Socket? _socket;
  final List<Map<String, dynamic>> _messages = [];
  final _msgCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _storage   = const FlutterSecureStorage();
  String? _myUserId;
  bool _isTyping   = false;
  bool _isLoading  = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null || !mounted) return;

    // Decode user id from token (basic split)
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final padded = payload.padRight((payload.length + 3) & ~3, '=');
        final decoded = String.fromCharCodes(base64Decode(padded));
        final json = jsonDecode(decoded);
        _myUserId = json['id'];
      }
    } catch (_) {}

    // Load history via REST
    try {
      final dio = Dio(BaseOptions(baseUrl: 'https://local-service-backend-k2aq.onrender.com/api'));
      dio.options.headers['Authorization'] = 'Bearer $token';
      final res = await dio.get('/chat/${widget.bookingId}');
      final data = res.data['data'] as List;
      setState(() {
        _messages.addAll(data.map((m) => m as Map<String, dynamic>));
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }

    // Connect socket
    _socket = IO.io('https://local-service-backend-k2aq.onrender.com',
        IO.OptionBuilder().setTransports(['websocket']).setAuth({'token': token}).build());
    _socket!.onConnect((_) {
      _socket!.emit('join_booking', {'bookingId': widget.bookingId});
    });
    _socket!.on('new_message', (data) {
      setState(() => _messages.add(Map<String, dynamic>.from(data)));
      _scrollToBottom();
    });
    _socket!.on('user_typing', (_) => setState(() => _isTyping = true));
    _socket!.on('user_stop_typing', (_) => setState(() => _isTyping = false));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      }
    });
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _socket?.emit('send_message', {'bookingId': widget.bookingId, 'content': text});
    _msgCtrl.clear();
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    final token = await _storage.read(key: 'auth_token');
    final dio = Dio(BaseOptions(baseUrl: 'https://local-service-backend-k2aq.onrender.com/api'));
    dio.options.headers['Authorization'] = 'Bearer $token';
    final formData = FormData.fromMap({
      'image': kIsWeb 
        ? MultipartFile.fromBytes(await file.readAsBytes(), filename: 'chat_image.jpg')
        : await MultipartFile.fromFile(file.path)
    });
    await dio.post('/chat/${widget.bookingId}', data: formData);
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool _isMe(Map<String, dynamic> msg) {
    final sender = msg['sender'];
    if (sender is Map) return sender['_id'] == _myUserId || sender['id'] == _myUserId;
    return sender == _myUserId;
  }

  String _senderName(Map<String, dynamic> msg) {
    final sender = msg['sender'];
    if (sender is Map) return sender['name'] ?? '';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.customerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text(widget.serviceType, style: const TextStyle(fontSize: 12, color: _textSub)),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_isTyping && i == _messages.length) {
                      return const Align(alignment: Alignment.centerLeft,
                          child: Padding(padding: EdgeInsets.only(bottom: 10),
                              child: Text('Customer is typing...', style: TextStyle(fontSize: 12, color: _textSub, fontStyle: FontStyle.italic))));
                    }
                    final msg = _messages[i];
                    final isMe = _isMe(msg);
                    final content = msg['content'] as String?;
                    final image   = msg['image'] as String?;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                        padding: image != null ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? _primary : const Color(0xFFE8EDF5),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                        ),
                        child: image != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(image, width: 200, fit: BoxFit.cover))
                            : Text(content ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                      ),
                    );
                  },
                ),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          color: Colors.white,
          child: Row(children: [
            IconButton(icon: const Icon(Icons.image_outlined, color: _primary), onPressed: _sendImage),
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                onChanged: (_) => _socket?.emit('typing', {'bookingId': widget.bookingId}),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true, fillColor: _bgInput,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
