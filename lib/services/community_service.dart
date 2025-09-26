import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saferoute/models/chat_message.dart';
import 'package:saferoute/models/leaderboard_user.dart';
import 'package:saferoute/models/incident_report.dart';
import 'package:saferoute/models/community_post.dart';
import 'package:saferoute/services/api_service.dart';
import 'package:saferoute/services/websocket_service.dart';

class CommunityService {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  // API Service
  final ApiService _apiService = ApiService();

  // WebSocket Service
  late WebSocketService _webSocketService;

  // Streams for real-time updates
  final _messageStreamController = StreamController<ChatMessage>.broadcast();
  final _onlineCountStreamController = StreamController<int>.broadcast();

  // Stream getters
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;
  Stream<int> get onlineCountStream => _onlineCountStreamController.stream;

  // State variables
  bool _isInitialized = false;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize WebSocket service
      _webSocketService = WebSocketService();
      await _webSocketService.connect();

      // Listen to WebSocket events
      _webSocketService.messageStream.listen(_handleNewMessage);
      _webSocketService.onlineUsersStream.listen(_handleOnlineUsersUpdate);

      _isInitialized = true;
    } catch (e) {
      debugPrint('فشل في تهيئة خدمة المجتمع: $e');
      rethrow;
    }
  }

  // Handle new message from WebSocket
  void _handleNewMessage(ChatMessage message) {
    _messageStreamController.add(message);
  }

  // Handle online users count update
  void _handleOnlineUsersUpdate(int count) {
    _onlineCountStreamController.add(count);
  }

  // Get chat messages
  Future<List<ChatMessage>> getChatMessages() async {
    try {
      return await _apiService.getChatMessages();
    } catch (e) {
      debugPrint('فشل في جلب الرسائل: $e');
      rethrow;
    }
  }

  // Send a chat message
  Future<ChatMessage> sendChatMessage({
    required String userId,
    required String userName,
    required String message,
    String? userAvatar,
  }) async {
    try {
      final sentMessage = await _apiService.sendChatMessage(
        userId: userId,
        userName: userName,
        message: message,
        userAvatar: userAvatar,
      );

      // No need to add to stream as WebSocket will handle this
      return sentMessage;
    } catch (e) {
      debugPrint('فشل في إرسال الرسالة: $e');
      rethrow;
    }
  }

  // Send message (alias for sendChatMessage)
  Future<void> sendMessage(ChatMessage message) async {
    try {
      await sendChatMessage(
        userId: message.userId,
        userName: message.userName,
        message: message.message,
        userAvatar: message.userAvatar,
      );
    } catch (e) {
      debugPrint('فشل في إرسال الرسالة: $e');
      rethrow;
    }
  }

  // Get posts
  Future<List<CommunityPost>> getPosts() async {
    try {
      return await _apiService.getPosts();
    } catch (e) {
      debugPrint('فشل في جلب المنشورات: $e');
      return []; // Return empty list as fallback
    }
  }

  // Create post
  Future<void> createPost(CommunityPost post) async {
    try {
      await _apiService.createPost(post);
    } catch (e) {
      debugPrint('فشل في إنشاء المنشور: $e');
      rethrow;
    }
  }

  // Like post
  Future<void> likePost(String postId, String userId) async {
    try {
      await _apiService.likePost(postId, userId);
    } catch (e) {
      debugPrint('فشل في الإعجاب بالمنشور: $e');
      rethrow;
    }
  }

  // Upload post images
  Future<List<String>> uploadPostImages(List<XFile> images) async {
    try {
      return await _apiService.uploadPostImages(images);
    } catch (e) {
      debugPrint('فشل في رفع الصور: $e');
      rethrow;
    }
  }

  // Get leaderboard users
  Future<List<LeaderboardUser>> getLeaderboard() async {
    try {
      return await _apiService.getLeaderboard();
    } catch (e) {
      debugPrint('فشل في جلب قائمة المتصدرين: $e');
      rethrow;
    }
  }

  // Send incident report
  Future<void> sendIncidentReport({
    required String userId,
    required String userName,
    required IncidentType incidentType,
    Map<String, double>? location,
    String? imageUrl,
    String? description,
  }) async {
    try {
      await _apiService.sendIncidentReport(
        userId: userId,
        userName: userName,
        incidentType: incidentType,
        location: location,
        imageUrl: imageUrl,
        description: description,
      );
    } catch (e) {
      debugPrint('فشل في إرسال البلاغ: $e');
      rethrow;
    }
  }

  // Get online users count
  Future<int> getOnlineUsersCount() async {
    try {
      return await _apiService.getOnlineUsersCount();
    } catch (e) {
      debugPrint('فشل في جلب عدد المستخدمين المتصلين: $e');
      return 0; // Return 0 as fallback
    }
  }

  // Dispose resources
  void dispose() {
    _messageStreamController.close();
    _onlineCountStreamController.close();
    _webSocketService.disconnect();
  }
}
