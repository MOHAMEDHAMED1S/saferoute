import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/leaderboard_user.dart';
import '../models/incident_report.dart';

class CommunityRealtimeService {
  static final CommunityRealtimeService _instance =
      CommunityRealtimeService._internal();
  factory CommunityRealtimeService() => _instance;
  CommunityRealtimeService._internal();

  late FirebaseDatabase _database;

  // Streams for real-time updates
  final _messageStreamController = StreamController<ChatMessage>.broadcast();
  final _onlineCountStreamController = StreamController<int>.broadcast();
  final _leaderboardStreamController =
      StreamController<List<LeaderboardUser>>.broadcast();

  // Stream getters
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;
  Stream<int> get onlineCountStream => _onlineCountStreamController.stream;
  Stream<List<LeaderboardUser>> get leaderboardStream =>
      _leaderboardStreamController.stream;

  // State variables
  bool _isInitialized = false;
  StreamSubscription<DatabaseEvent>? _messagesSubscription;
  StreamSubscription<DatabaseEvent>? _onlineUsersSubscription;
  StreamSubscription<DatabaseEvent>? _leaderboardSubscription;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _database = FirebaseDatabase.instance;
      if (!kIsWeb) {
        _database.setPersistenceEnabled(true);
        _database.setPersistenceCacheSizeBytes(10000000); // 10MB cache
      }

      // Start listening to real-time updates
      _listenToMessages();
      _listenToOnlineUsers();
      _listenToLeaderboard();

      _isInitialized = true;
      debugPrint('CommunityRealtimeService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing CommunityRealtimeService: $e');
      rethrow;
    }
  }

  // Listen to real-time chat messages
  void _listenToMessages() {
    _messagesSubscription = _database
        .ref('chat_messages')
        .orderByChild('timestamp')
        .limitToLast(50)
        .onValue
        .listen((DatabaseEvent event) {
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            data.forEach((key, value) {
              if (value is Map<dynamic, dynamic>) {
                try {
                  final message = ChatMessage.fromRealtimeDatabase(
                    key.toString(),
                    Map<String, dynamic>.from(value),
                  );
                  _messageStreamController.add(message);
                } catch (e) {
                  debugPrint('Error parsing message: $e');
                }
              }
            });
          }
        });
  }

  // Listen to online users count
  void _listenToOnlineUsers() {
    _onlineUsersSubscription = _database.ref('online_users').onValue.listen((
      DatabaseEvent event,
    ) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        _onlineCountStreamController.add(data.length);
      } else {
        _onlineCountStreamController.add(0);
      }
    });
  }

  // Listen to leaderboard updates
  void _listenToLeaderboard() {
    _leaderboardSubscription = _database
        .ref('leaderboard')
        .orderByChild('points')
        .limitToLast(10)
        .onValue
        .listen((DatabaseEvent event) {
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            final leaderboard = <LeaderboardUser>[];

            data.forEach((key, value) {
              if (value is Map<dynamic, dynamic>) {
                try {
                  final user = LeaderboardUser.fromRealtimeDatabase(
                    key.toString(),
                    Map<String, dynamic>.from(value),
                  );
                  leaderboard.add(user);
                } catch (e) {
                  debugPrint('Error parsing leaderboard user: $e');
                }
              }
            });

            // Sort by points in descending order
            leaderboard.sort((a, b) => b.points.compareTo(a.points));
            _leaderboardStreamController.add(leaderboard);
          }
        });
  }

  // Send a chat message
  Future<void> sendMessage(
    String userId,
    String userName,
    String message,
  ) async {
    try {
      final messageData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'userName': userName,
        'message': message,
        'timestamp': ServerValue.timestamp,
        'type': 'text',
      };

      await _database.ref('chat_messages').push().set(messageData);
    } catch (e) {
      debugPrint('Error sending chat message: $e');
      rethrow;
    }
  }

  // Send incident report
  Future<void> sendIncidentReport(
    String userId,
    String userName,
    IncidentType type,
    String description,
    double latitude,
    double longitude,
  ) async {
    try {
      final incidentData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'userName': userName,
        'type': _getIncidentTypeString(type),
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': ServerValue.timestamp,
      };

      await _database.ref('incident_reports').push().set(incidentData);

      // Also send as chat message
      final incidentMessage =
          'Incident reported: ${_getIncidentTypeString(type)} - $description';
      await sendMessage(userId, userName, incidentMessage);
    } catch (e) {
      debugPrint('Error sending incident report: $e');
      rethrow;
    }
  }

  // Get incident type string
  String _getIncidentTypeString(IncidentType type) {
    switch (type) {
      case IncidentType.accident:
        return 'accident';
      case IncidentType.roadBlock:
        return 'roadBlock';
      case IncidentType.policeCheckpoint:
        return 'policeCheckpoint';
      case IncidentType.hazard:
        return 'hazard';
      case IncidentType.traffic:
        return 'traffic';
      case IncidentType.speedBump:
        return 'speedBump';
      case IncidentType.construction:
        return 'construction';
      case IncidentType.other:
        return 'other';
    }
  }

  // Update user points in leaderboard
  Future<void> updateUserPoints(
    String userId,
    String userName,
    int points,
  ) async {
    try {
      final userData = {
        'userId': userId,
        'userName': userName,
        'points': points,
        'lastUpdated': ServerValue.timestamp,
      };

      await _database.ref('leaderboard').child(userId).set(userData);
    } catch (e) {
      debugPrint('Error updating user points: $e');
      rethrow;
    }
  }

  // Set user online status
  Future<void> setUserOnline(String userId, String userName) async {
    try {
      final userData = {
        'userId': userId,
        'userName': userName,
        'lastSeen': ServerValue.timestamp,
        'isOnline': true,
      };

      await _database.ref('online_users').child(userId).set(userData);

      // Set up offline detection
      await _database.ref('online_users').child(userId).onDisconnect().remove();
    } catch (e) {
      debugPrint('Error setting user online: $e');
      rethrow;
    }
  }

  // Set user offline status
  Future<void> setUserOffline(String userId) async {
    try {
      await _database.ref('online_users').child(userId).remove();
    } catch (e) {
      debugPrint('Error setting user offline: $e');
      rethrow;
    }
  }

  // Get chat messages (for initial load)
  Future<List<ChatMessage>> getChatMessages({int limit = 50}) async {
    try {
      final snapshot = await _database
          .ref('chat_messages')
          .orderByChild('timestamp')
          .limitToLast(limit)
          .get();

      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final messages = <ChatMessage>[];

        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            try {
              final message = ChatMessage.fromRealtimeDatabase(
                key.toString(),
                Map<String, dynamic>.from(value),
              );
              messages.add(message);
            } catch (e) {
              debugPrint('Error parsing message: $e');
            }
          }
        });

        // Sort by timestamp
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return messages;
      }

      return [];
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
      return [];
    }
  }

  // Get leaderboard data
  Future<List<LeaderboardUser>> getLeaderboard({int limit = 10}) async {
    try {
      final snapshot = await _database
          .ref('leaderboard')
          .orderByChild('points')
          .limitToLast(limit)
          .get();

      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final leaderboard = <LeaderboardUser>[];

        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            try {
              final user = LeaderboardUser.fromRealtimeDatabase(
                key.toString(),
                Map<String, dynamic>.from(value),
              );
              leaderboard.add(user);
            } catch (e) {
              debugPrint('Error parsing leaderboard user: $e');
            }
          }
        });

        // Sort by points in descending order
        leaderboard.sort((a, b) => b.points.compareTo(a.points));
        return leaderboard;
      }

      return [];
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  // Get online users count
  Future<int> getOnlineUsersCount() async {
    try {
      final snapshot = await _database.ref('online_users').get();
      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.length;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting online users count: $e');
      return 0;
    }
  }

  // Dispose resources
  void dispose() {
    _messagesSubscription?.cancel();
    _onlineUsersSubscription?.cancel();
    _leaderboardSubscription?.cancel();
    _messageStreamController.close();
    _onlineCountStreamController.close();
    _leaderboardStreamController.close();
    _isInitialized = false;
  }
}
