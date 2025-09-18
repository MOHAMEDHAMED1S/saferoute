import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final int points;
  final double trustScore;
  final int totalReports;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isDriverMode;
  final LocationData? location;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.points = 0,
    this.trustScore = 0.5,
    this.totalReports = 0,
    required this.createdAt,
    required this.lastLogin,
    this.isDriverMode = false,
    this.location,
  });

  // Convert from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      points: data['points'] ?? 0,
      trustScore: (data['trustScore'] ?? 0.5).toDouble(),
      totalReports: data['totalReports'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: (data['lastLogin'] as Timestamp).toDate(),
      isDriverMode: data['isDriverMode'] ?? false,
      location: data['location'] != null 
          ? LocationData.fromMap(data['location'])
          : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'points': points,
      'trustScore': trustScore,
      'totalReports': totalReports,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'isDriverMode': isDriverMode,
      'location': location?.toMap(),
    };
  }

  // Copy with method for updates
  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    int? points,
    double? trustScore,
    int? totalReports,
    DateTime? lastLogin,
    bool? isDriverMode,
    LocationData? location,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      points: points ?? this.points,
      trustScore: trustScore ?? this.trustScore,
      totalReports: totalReports ?? this.totalReports,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isDriverMode: isDriverMode ?? this.isDriverMode,
      location: location ?? this.location,
    );
  }
}

class LocationData {
  final double lat;
  final double lng;
  final DateTime updatedAt;

  LocationData({
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      lat: map['lat'].toDouble(),
      lng: map['lng'].toDouble(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}