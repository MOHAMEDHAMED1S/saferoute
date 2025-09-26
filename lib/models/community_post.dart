import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String content;
  final String category;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likes;
  final List<Map<String, dynamic>> comments;
  final List<String> tags;
  final Map<String, double>? location;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.content,
    required this.category,
    this.imageUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.likes = 0,
    this.comments = const [],
    this.tags = const [],
    this.location,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      likes: json['likes'] as int? ?? 0,
      comments: List<Map<String, dynamic>>.from(json['comments'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      location: json['location'] != null
          ? Map<String, double>.from(json['location'])
          : null,
    );
  }

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      title: data['title'] as String,
      content: data['content'] as String,
      category: data['category'] as String,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likes: data['likes'] as int? ?? 0,
      comments: List<Map<String, dynamic>>.from(data['comments'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      location: data['location'] != null
          ? Map<String, double>.from(data['location'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'title': title,
      'content': content,
      'category': category,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'likes': likes,
      'comments': comments,
      'tags': tags,
      'location': location,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'title': title,
      'content': content,
      'category': category,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likes': likes,
      'comments': comments,
      'tags': tags,
      'location': location,
    };
  }

  CommunityPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? title,
    String? content,
    String? category,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likes,
    List<Map<String, dynamic>>? comments,
    List<String>? tags,
    Map<String, double>? location,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      tags: tags ?? this.tags,
      location: location ?? this.location,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityPost &&
        other.id == id &&
        other.userId == userId &&
        other.userName == userName &&
        other.title == title &&
        other.content == content &&
        other.category == category &&
        other.imageUrls == imageUrls &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.likes == likes &&
        other.comments == comments &&
        other.tags == tags &&
        other.location == location;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      userName,
      title,
      content,
      category,
      imageUrls,
      createdAt,
      updatedAt,
      likes,
      comments,
      tags,
      location,
    );
  }
}
