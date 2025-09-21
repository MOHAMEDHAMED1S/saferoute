enum ThreatType {
  accident,
  roadblock,
  weather,
  crime,
  construction,
  traffic,
  other
}

enum ThreatSeverity {
  low,
  medium,
  high,
  critical
}

class ThreatModel {
  final String id;
  final ThreatType type;
  final ThreatSeverity severity;
  final double latitude;
  final double longitude;
  final String description;
  final DateTime timestamp;
  final String reportedBy;
  final bool isVerified;
  final int verificationCount;
  final Map<String, dynamic>? additionalData;

  ThreatModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.timestamp,
    required this.reportedBy,
    this.isVerified = false,
    this.verificationCount = 0,
    this.additionalData,
  });

  factory ThreatModel.fromJson(Map<String, dynamic> json) {
    return ThreatModel(
      id: json['id'] as String,
      type: ThreatType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ThreatType.other,
      ),
      severity: ThreatSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == json['severity'],
        orElse: () => ThreatSeverity.low,
      ),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      reportedBy: json['reportedBy'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationCount: json['verificationCount'] as int? ?? 0,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'reportedBy': reportedBy,
      'isVerified': isVerified,
      'verificationCount': verificationCount,
      'additionalData': additionalData,
    };
  }

  ThreatModel copyWith({
    String? id,
    ThreatType? type,
    ThreatSeverity? severity,
    double? latitude,
    double? longitude,
    String? description,
    DateTime? timestamp,
    String? reportedBy,
    bool? isVerified,
    int? verificationCount,
    Map<String, dynamic>? additionalData,
  }) {
    return ThreatModel(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      reportedBy: reportedBy ?? this.reportedBy,
      isVerified: isVerified ?? this.isVerified,
      verificationCount: verificationCount ?? this.verificationCount,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThreatModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ThreatModel(id: $id, type: $type, severity: $severity, latitude: $latitude, longitude: $longitude, description: $description, timestamp: $timestamp, reportedBy: $reportedBy, isVerified: $isVerified, verificationCount: $verificationCount)';
  }
}