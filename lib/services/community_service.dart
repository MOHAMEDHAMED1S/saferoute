import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferoute/models/chat_message.dart';
import 'package:saferoute/models/leaderboard_user.dart';
import 'package:saferoute/models/incident_report.dart';
import 'package:saferoute/models/community_post.dart';
import 'package:saferoute/services/firebase_schema_service.dart';

class CommunityService {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  // Firebase Services
  final FirebaseSchemaService _schemaService = FirebaseSchemaService();

  // Streams for real-time updates
  final _messageStreamController = StreamController<ChatMessage>.broadcast();
  final _onlineCountStreamController = StreamController<int>.broadcast();

  // Stream getters
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;
  Stream<int> get onlineCountStream => _onlineCountStreamController.stream;

  // State variables
  bool _isInitialized = false;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  StreamSubscription<QuerySnapshot>? _onlineUsersSubscription;
  Timer? _reconnectTimer;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase schema
      await _schemaService.initializeDatabase();

      // Start listening to chat messages
      _startListeningToMessages();

      // Start listening to online users count
      _startListeningToOnlineUsers();

      _isInitialized = true;
    } catch (e) {
      debugPrint('فشل في تهيئة خدمة المجتمع: $e');
      rethrow;
    }
  }

  // Start listening to chat messages
  void _startListeningToMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = _schemaService.communityChat
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen(
          (snapshot) {
            for (final change in snapshot.docChanges) {
              final message = ChatMessage.fromFirestore(change.doc);

              switch (change.type) {
                case DocumentChangeType.added:
                  // رسالة جديدة - إضافتها للـ stream
                  _messageStreamController.add(message);
                  break;
                case DocumentChangeType.modified:
                  // رسالة معدلة - إرسال تحديث
                  _messageStreamController.add(message);
                  break;
                case DocumentChangeType.removed:
                  // رسالة محذوفة - لا نحتاج للتعامل معها هنا
                  break;
              }
            }
          },
          onError: (error) {
            debugPrint('خطأ في استماع الرسائل: $error');
            _reconnectListeners();
          },
        );
  }

  // Start listening to online users count
  void _startListeningToOnlineUsers() {
    _onlineUsersSubscription?.cancel();
    _onlineUsersSubscription = _schemaService.users
        .where(
          'lastLogin',
          isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        )
        .snapshots()
        .listen(
          (snapshot) {
            _onlineCountStreamController.add(snapshot.docs.length);
          },
          onError: (error) {
            debugPrint('خطأ في استماع عدد المستخدمين المتصلين: $error');
            _reconnectListeners();
          },
        );
  }

  // Reconnect listeners if connection is lost
  void _reconnectListeners() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_isInitialized) {
        debugPrint('إعادة محاولة الاتصال...');
        _startListeningToMessages();
        _startListeningToOnlineUsers();
      }
    });
  }

  // Get chat messages
  Future<List<ChatMessage>> getChatMessages() async {
    try {
      final snapshot = await _schemaService.communityChat
          .orderBy('timestamp', descending: false) // الأقدم أولاً
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
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
    MessageType messageType = MessageType.text,
    Map<String, dynamic>? metadata,
    String? replyTo,
  }) async {
    try {
      final messageData = ChatMessage(
        id: '', // سيتم تعيينه من Firebase
        userId: userId,
        userName: userName,
        message: message,
        timestamp: DateTime.now(),
        userAvatar: userAvatar,
        messageType: messageType,
        metadata: metadata,
        replyTo: replyTo,
      );

      final docRef = await _schemaService.communityChat.add(
        messageData.toFirestore(),
      );

      // إنشاء الرسالة مع المعرف الجديد
      final sentMessage = messageData.copyWith(id: docRef.id);

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
        messageType: message.messageType,
        metadata: message.metadata,
        replyTo: message.replyTo,
      );
    } catch (e) {
      debugPrint('فشل في إرسال الرسالة: $e');
      rethrow;
    }
  }

  // Get posts
  Future<List<CommunityPost>> getPosts() async {
    try {
      final snapshot = await _schemaService.community
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => CommunityPost.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('فشل في جلب المنشورات: $e');
      return []; // Return empty list as fallback
    }
  }

  // Create post
  Future<void> createPost(CommunityPost post) async {
    try {
      await _schemaService.community.add(post.toFirestore());
    } catch (e) {
      debugPrint('فشل في إنشاء المنشور: $e');
      rethrow;
    }
  }

  // Like post
  Future<void> likePost(String postId, String userId) async {
    try {
      await _schemaService.community.doc(postId).update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('فشل في الإعجاب بالمنشور: $e');
      rethrow;
    }
  }

  // Upload post images
  Future<List<String>> uploadPostImages(List<XFile> images) async {
    try {
      // TODO: Implement Firebase Storage upload
      // For now, return empty list as placeholder
      debugPrint('رفع الصور غير مطبق بعد - سيتم تطبيقه مع Firebase Storage');
      return [];
    } catch (e) {
      debugPrint('فشل في رفع الصور: $e');
      rethrow;
    }
  }

  // Get leaderboard users
  Future<List<LeaderboardUser>> getLeaderboard() async {
    try {
      final snapshot = await _schemaService.users
          .orderBy('points', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => LeaderboardUser.fromFirestore(doc))
          .toList();
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
      final reportData = {
        'userId': userId,
        'userName': userName,
        'incidentType': incidentType.toString().split('.').last,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'verifiedBy': <String>[],
        'rejectedBy': <String>[],
      };

      if (location != null) {
        reportData['location'] = {
          'lat': location['latitude'],
          'lng': location['longitude'],
        };
      }

      if (imageUrl != null) {
        reportData['imageUrls'] = [imageUrl];
      }

      if (description != null) {
        reportData['description'] = description;
      }

      await _schemaService.reports.add(reportData);
    } catch (e) {
      debugPrint('فشل في إرسال البلاغ: $e');
      rethrow;
    }
  }

  // Get online users count
  Future<int> getOnlineUsersCount() async {
    try {
      // حساب المستخدمين المتصلين بناءً على آخر تسجيل دخول
      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

      final snapshot = await _schemaService.users
          .where('lastLogin', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('فشل في جلب عدد المستخدمين المتصلين: $e');
      return 0; // Return 0 as fallback
    }
  }

  // Add reaction to message
  Future<void> addReaction(
    String messageId,
    String userId,
    String emoji,
  ) async {
    try {
      await _schemaService.communityChat.doc(messageId).update({
        'reactions.$emoji': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('فشل في إضافة التفاعل: $e');
      rethrow;
    }
  }

  // Remove reaction from message
  Future<void> removeReaction(
    String messageId,
    String userId,
    String emoji,
  ) async {
    try {
      await _schemaService.communityChat.doc(messageId).update({
        'reactions.$emoji': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      debugPrint('فشل في إزالة التفاعل: $e');
      rethrow;
    }
  }

  // Edit message
  Future<void> editMessage(String messageId, String newMessage) async {
    try {
      await _schemaService.communityChat.doc(messageId).update({
        'message': newMessage,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('فشل في تعديل الرسالة: $e');
      rethrow;
    }
  }

  // Delete message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    try {
      await _schemaService.communityChat.doc(messageId).update({
        'deletedAt': FieldValue.serverTimestamp(),
        'message': '[تم حذف هذه الرسالة]',
      });
    } catch (e) {
      debugPrint('فشل في حذف الرسالة: $e');
      rethrow;
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId, String userId) async {
    try {
      await _schemaService.communityChat.doc(messageId).update({
        'isRead': true,
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('فشل في تحديد الرسالة كمقروءة: $e');
      rethrow;
    }
  }

  // Dispose resources
  void dispose() {
    _messagesSubscription?.cancel();
    _onlineUsersSubscription?.cancel();
    _reconnectTimer?.cancel();
    _messageStreamController.close();
    _onlineCountStreamController.close();
  }
}
