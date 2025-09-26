import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, location, incidentReport }

class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;
  final String? userAvatar;
  final bool isDelivered;
  final bool isRead;
  final MessageType messageType;
  final Map<String, dynamic>? metadata;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final String? replyTo;
  final Map<String, List<String>> reactions;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
    this.userAvatar,
    this.isDelivered = false,
    this.isRead = false,
    this.messageType = MessageType.text,
    this.metadata,
    this.editedAt,
    this.deletedAt,
    this.replyTo,
    this.reactions = const {},
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userAvatar: json['userAvatar'] as String?,
      isDelivered: json['isDelivered'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      messageType: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['messageType'],
        orElse: () => MessageType.text,
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      replyTo: json['replyTo'] as String?,
      reactions: Map<String, List<String>>.from(
        json['reactions'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      message: data['message'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      userAvatar: data['userAvatar'] as String?,
      isDelivered: data['isDelivered'] as bool? ?? false,
      isRead: data['isRead'] as bool? ?? false,
      messageType: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == data['messageType'],
        orElse: () => MessageType.text,
      ),
      metadata: data['metadata'] as Map<String, dynamic>?,
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
      replyTo: data['replyTo'] as String?,
      reactions: Map<String, List<String>>.from(
        data['reactions'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'userAvatar': userAvatar,
      'isDelivered': isDelivered,
      'isRead': isRead,
      'messageType': messageType.toString().split('.').last,
      'metadata': metadata,
      'editedAt': editedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'replyTo': replyTo,
      'reactions': reactions,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'userAvatar': userAvatar,
      'isDelivered': isDelivered,
      'isRead': isRead,
      'messageType': messageType.toString().split('.').last,
      'metadata': metadata,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'replyTo': replyTo,
      'reactions': reactions,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? userId,
    String? userName,
    String? message,
    DateTime? timestamp,
    String? userAvatar,
    bool? isDelivered,
    bool? isRead,
    MessageType? messageType,
    Map<String, dynamic>? metadata,
    DateTime? editedAt,
    DateTime? deletedAt,
    String? replyTo,
    Map<String, List<String>>? reactions,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      userAvatar: userAvatar ?? this.userAvatar,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.userId == userId &&
        other.userName == userName &&
        other.message == message &&
        other.timestamp == timestamp &&
        other.userAvatar == userAvatar &&
        other.isDelivered == isDelivered &&
        other.isRead == isRead &&
        other.messageType == messageType &&
        other.metadata == metadata &&
        other.editedAt == editedAt &&
        other.deletedAt == deletedAt &&
        other.replyTo == replyTo &&
        other.reactions == reactions;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      userName,
      message,
      timestamp,
      userAvatar,
      isDelivered,
      isRead,
      messageType,
      metadata,
      editedAt,
      deletedAt,
      replyTo,
      reactions,
    );
  }
}
