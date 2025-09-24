import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  
  WebSocketChannel? _channel;
  final String _wsUrl = 'wss://api.saferoute.com/ws'; // استبدل بعنوان WebSocket الخاص بك
  
  final StreamController<ChatMessage> _messageController = StreamController<ChatMessage>.broadcast();
  final StreamController<int> _onlineUsersController = StreamController<int>.broadcast();
  
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<int> get onlineUsersStream => _onlineUsersController.stream;
  
  bool _isConnected = false;
  Timer? _pingTimer;
  
  WebSocketService._internal();
  
  Future<void> connect({String? authToken}) async {
    if (_isConnected) return;
    
    try {
      final uri = Uri.parse(_wsUrl);
      final Map<String, dynamic> headers = {};
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      _channel = IOWebSocketChannel.connect(
        uri,
        headers: headers,
        pingInterval: const Duration(seconds: 30),
      );
      
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      
      _isConnected = true;
      _startPingTimer();
      
      debugPrint('WebSocket connected successfully');
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _isConnected = false;
    }
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        sendPing();
      }
    });
  }
  
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final String eventType = data['type'] ?? '';
      
      switch (eventType) {
        case 'message':
          final chatMessage = ChatMessage.fromJson(data['data']);
          _messageController.add(chatMessage);
          break;
        case 'online_users':
          final int count = data['count'] ?? 0;
          _onlineUsersController.add(count);
          break;
        case 'pong':
          // تم استلام رد على ping
          break;
        default:
          debugPrint('Unknown WebSocket event type: $eventType');
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }
  
  void _onError(error) {
    debugPrint('WebSocket error: $error');
    _reconnect();
  }
  
  void _onDone() {
    debugPrint('WebSocket connection closed');
    _isConnected = false;
    _reconnect();
  }
  
  Future<void> _reconnect() async {
    if (!_isConnected) {
      await Future.delayed(const Duration(seconds: 5));
      connect();
    }
  }
  
  void sendPing() {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'ping'}));
    }
  }
  
  void sendMessage(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      debugPrint('Cannot send message: WebSocket not connected');
      _reconnect();
    }
  }
  
  void disconnect() {
    _pingTimer?.cancel();
    _pingTimer = null;
    
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    
    _isConnected = false;
    debugPrint('WebSocket disconnected');
  }
  
  void dispose() {
    disconnect();
    _messageController.close();
    _onlineUsersController.close();
  }
}