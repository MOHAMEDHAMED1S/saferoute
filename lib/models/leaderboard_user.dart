import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardUser {
  final String id;
  final String name;
  final String? photoUrl;
  final int points;
  final int rank;
  final int safetyReports;
  final int helpfulTips;
  final String? badge;

  // إضافة الحقول المفقودة
  String get userId => id;
  String? get avatarUrl => photoUrl;

  LeaderboardUser({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.points,
    required this.rank,
    this.safetyReports = 0,
    this.helpfulTips = 0,
    this.badge,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      points: json['points'] as int,
      rank: json['rank'] as int,
      safetyReports: json['safetyReports'] as int? ?? 0,
      helpfulTips: json['helpfulTips'] as int? ?? 0,
      badge: json['badge'] as String?,
    );
  }

  factory LeaderboardUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardUser(
      id: doc.id,
      name: data['name'] as String,
      photoUrl: data['photoUrl'] as String?,
      points: data['points'] as int? ?? 0,
      rank: 0, // سيتم حساب الترتيب منفصل
      safetyReports: data['totalReports'] as int? ?? 0,
      helpfulTips: 0, // سيتم إضافة هذا الحقل لاحقاً
      badge: data['badge'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'points': points,
      'rank': rank,
      'safetyReports': safetyReports,
      'helpfulTips': helpfulTips,
      'badge': badge,
    };
  }

  LeaderboardUser copyWith({
    String? id,
    String? name,
    String? photoUrl,
    int? points,
    int? rank,
    int? safetyReports,
    int? helpfulTips,
    String? badge,
  }) {
    return LeaderboardUser(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      points: points ?? this.points,
      rank: rank ?? this.rank,
      safetyReports: safetyReports ?? this.safetyReports,
      helpfulTips: helpfulTips ?? this.helpfulTips,
      badge: badge ?? this.badge,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardUser &&
        other.id == id &&
        other.name == name &&
        other.photoUrl == photoUrl &&
        other.points == points &&
        other.rank == rank &&
        other.safetyReports == safetyReports &&
        other.helpfulTips == helpfulTips &&
        other.badge == badge;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      photoUrl,
      points,
      rank,
      safetyReports,
      helpfulTips,
      badge,
    );
  }
}
