import 'package:cloud_firestore/cloud_firestore.dart';

class PointsModel {
  final int points;
  final String userId;
  final DateTime lastUpdated;

  PointsModel({
    required this.points,
    required this.userId,
    required this.lastUpdated,
  });

  factory PointsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PointsModel(
      points: data['points'] ?? 0,
      userId: data['userId'] ?? '',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'points': points,
      'userId': userId,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  PointsModel copyWith({
    int? points,
    String? userId,
    DateTime? lastUpdated,
  }) {
    return PointsModel(
      points: points ?? this.points,
      userId: userId ?? this.userId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class RewardModel {
  final String id;
  final String brandName;
  final String description;
  final String imageUrl;
  final int requiredPoints;
  final String discountCode;
  final DateTime expiryDate;
  final bool isActive;

  RewardModel({
    required this.id,
    required this.brandName,
    required this.description,
    required this.imageUrl,
    required this.requiredPoints,
    required this.discountCode,
    required this.expiryDate,
    this.isActive = true,
  });

  factory RewardModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RewardModel(
      id: doc.id,
      brandName: data['brandName'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      requiredPoints: data['requiredPoints'] ?? 0,
      discountCode: data['discountCode'] ?? '',
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brandName': brandName,
      'description': description,
      'imageUrl': imageUrl,
      'requiredPoints': requiredPoints,
      'discountCode': discountCode,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isActive': isActive,
    };
  }
}

class UserRewardModel {
  final String id;
  final String userId;
  final String rewardId;
  final String discountCode;
  final DateTime redeemedDate;
  final DateTime expiryDate;
  final bool isUsed;

  UserRewardModel({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.discountCode,
    required this.redeemedDate,
    required this.expiryDate,
    this.isUsed = false,
  });

  factory UserRewardModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserRewardModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      rewardId: data['rewardId'] ?? '',
      discountCode: data['discountCode'] ?? '',
      redeemedDate: (data['redeemedDate'] as Timestamp).toDate(),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      isUsed: data['isUsed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rewardId': rewardId,
      'discountCode': discountCode,
      'redeemedDate': Timestamp.fromDate(redeemedDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isUsed': isUsed,
    };
  }
}