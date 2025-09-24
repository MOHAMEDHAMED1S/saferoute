// لا حاجة لاستيراد foundation.dart بعد استبدال hashValues بـ Object.hash

enum IncidentType {
  accident,
  roadBlock,
  policeCheckpoint,
  hazard,
  traffic,
  speedBump,
  construction,
  other
}

class IncidentReport {
  final String id;
  final String userId;
  final String userName;
  final IncidentType incidentType;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String? imageUrl;
  final int confirmations;
  final bool isActive;

  IncidentReport({
    required this.id,
    required this.userId,
    required this.userName,
    required this.incidentType,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.description,
    this.imageUrl,
    this.confirmations = 0,
    this.isActive = true,
  });

  factory IncidentReport.fromJson(Map<String, dynamic> json) {
    return IncidentReport(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      incidentType: _incidentTypeFromString(json['incidentType'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      confirmations: json['confirmations'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'incidentType': _incidentTypeToString(incidentType),
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'imageUrl': imageUrl,
      'confirmations': confirmations,
      'isActive': isActive,
    };
  }

  static IncidentType _incidentTypeFromString(String value) {
    switch (value) {
      case 'accident':
        return IncidentType.accident;
      case 'roadBlock':
        return IncidentType.roadBlock;
      case 'policeCheckpoint':
        return IncidentType.policeCheckpoint;
      case 'hazard':
        return IncidentType.hazard;
      case 'traffic':
        return IncidentType.traffic;
      case 'speedBump':
        return IncidentType.speedBump;
      case 'construction':
        return IncidentType.construction;
      default:
        return IncidentType.other;
    }
  }

  static String _incidentTypeToString(IncidentType type) {
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

  IncidentReport copyWith({
    String? id,
    String? userId,
    String? userName,
    IncidentType? incidentType,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? description,
    String? imageUrl,
    int? confirmations,
    bool? isActive,
  }) {
    return IncidentReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      incidentType: incidentType ?? this.incidentType,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      confirmations: confirmations ?? this.confirmations,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IncidentReport &&
        other.id == id &&
        other.userId == userId &&
        other.userName == userName &&
        other.incidentType == incidentType &&
        other.timestamp == timestamp &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.confirmations == confirmations &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      userName,
      incidentType,
      timestamp,
      latitude,
      longitude,
      description,
      imageUrl,
      confirmations,
      isActive,
    );
  }
}