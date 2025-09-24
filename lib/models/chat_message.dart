// لا حاجة لاستيراد foundation.dart بعد استبدال hashValues بـ Object.hash

class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;
  final String? userAvatar;
  final bool isDelivered;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
    this.userAvatar,
    this.isDelivered = false,
    this.isRead = false,
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
        other.isRead == isRead;
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
    );
  }
}