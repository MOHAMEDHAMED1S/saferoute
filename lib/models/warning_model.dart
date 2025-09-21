import 'package:google_maps_flutter/google_maps_flutter.dart';

enum WarningType {
  accident,
  traffic,
  roadwork,
  police,
  speedCamera,
  speedLimit,
  general,
}

enum WarningSeverity {
  low,
  medium,
  high,
  critical,
}

class DrivingWarning {
  final String id;
  final WarningType type;
  final String message;
  final int distance; // Distance in meters
  final WarningSeverity severity;
  final LatLng location;
  final DateTime timestamp;
  final bool isActive;
  final String? additionalInfo;
  final Duration? estimatedDelay;
  
  const DrivingWarning({
    required this.id,
    required this.type,
    required this.message,
    required this.distance,
    required this.severity,
    required this.location,
    required this.timestamp,
    required this.isActive,
    this.additionalInfo,
    this.estimatedDelay,
  });
  
  DrivingWarning copyWith({
    String? id,
    WarningType? type,
    String? message,
    int? distance,
    WarningSeverity? severity,
    LatLng? location,
    DateTime? timestamp,
    bool? isActive,
    String? additionalInfo,
    Duration? estimatedDelay,
  }) {
    return DrivingWarning(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      distance: distance ?? this.distance,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      isActive: isActive ?? this.isActive,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      estimatedDelay: estimatedDelay ?? this.estimatedDelay,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'message': message,
      'distance': distance,
      'severity': severity.toString().split('.').last,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'timestamp': timestamp.toIso8601String(),
      'isActive': isActive,
      'additionalInfo': additionalInfo,
      'estimatedDelay': estimatedDelay?.inMinutes,
    };
  }
  
  factory DrivingWarning.fromJson(Map<String, dynamic> json) {
    return DrivingWarning(
      id: json['id'],
      type: WarningType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => WarningType.general,
      ),
      message: json['message'],
      distance: json['distance'],
      severity: WarningSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == json['severity'],
        orElse: () => WarningSeverity.low,
      ),
      location: LatLng(
        json['location']['latitude'],
        json['location']['longitude'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isActive: json['isActive'],
      additionalInfo: json['additionalInfo'],
      estimatedDelay: json['estimatedDelay'] != null
          ? Duration(minutes: json['estimatedDelay'])
          : null,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrivingWarning && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'DrivingWarning(id: $id, type: $type, message: $message, distance: $distance, severity: $severity)';
  }
}

class WarningSettings {
  final bool enableVoiceWarnings;
  final bool enableVisualWarnings;
  final bool enableVibration;
  final double warningRadius; // in meters
  final List<WarningType> enabledWarningTypes;
  final WarningSeverity minimumSeverity;
  final bool autoRepeatCritical;
  final Duration repeatInterval;
  
  const WarningSettings({
    this.enableVoiceWarnings = true,
    this.enableVisualWarnings = true,
    this.enableVibration = true,
    this.warningRadius = 2000,
    this.enabledWarningTypes = const [
      WarningType.accident,
      WarningType.traffic,
      WarningType.roadwork,
      WarningType.police,
      WarningType.speedCamera,
    ],
    this.minimumSeverity = WarningSeverity.low,
    this.autoRepeatCritical = true,
    this.repeatInterval = const Duration(minutes: 2),
  });
  
  WarningSettings copyWith({
    bool? enableVoiceWarnings,
    bool? enableVisualWarnings,
    bool? enableVibration,
    double? warningRadius,
    List<WarningType>? enabledWarningTypes,
    WarningSeverity? minimumSeverity,
    bool? autoRepeatCritical,
    Duration? repeatInterval,
  }) {
    return WarningSettings(
      enableVoiceWarnings: enableVoiceWarnings ?? this.enableVoiceWarnings,
      enableVisualWarnings: enableVisualWarnings ?? this.enableVisualWarnings,
      enableVibration: enableVibration ?? this.enableVibration,
      warningRadius: warningRadius ?? this.warningRadius,
      enabledWarningTypes: enabledWarningTypes ?? this.enabledWarningTypes,
      minimumSeverity: minimumSeverity ?? this.minimumSeverity,
      autoRepeatCritical: autoRepeatCritical ?? this.autoRepeatCritical,
      repeatInterval: repeatInterval ?? this.repeatInterval,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'enableVoiceWarnings': enableVoiceWarnings,
      'enableVisualWarnings': enableVisualWarnings,
      'enableVibration': enableVibration,
      'warningRadius': warningRadius,
      'enabledWarningTypes': enabledWarningTypes
          .map((type) => type.toString().split('.').last)
          .toList(),
      'minimumSeverity': minimumSeverity.toString().split('.').last,
      'autoRepeatCritical': autoRepeatCritical,
      'repeatInterval': repeatInterval.inMinutes,
    };
  }
  
  factory WarningSettings.fromJson(Map<String, dynamic> json) {
    return WarningSettings(
      enableVoiceWarnings: json['enableVoiceWarnings'] ?? true,
      enableVisualWarnings: json['enableVisualWarnings'] ?? true,
      enableVibration: json['enableVibration'] ?? true,
      warningRadius: json['warningRadius']?.toDouble() ?? 2000.0,
      enabledWarningTypes: (json['enabledWarningTypes'] as List<dynamic>?)
              ?.map((typeStr) => WarningType.values.firstWhere(
                    (e) => e.toString().split('.').last == typeStr,
                    orElse: () => WarningType.general,
                  ))
              .toList() ??
          [
            WarningType.accident,
            WarningType.traffic,
            WarningType.roadwork,
            WarningType.police,
            WarningType.speedCamera,
          ],
      minimumSeverity: WarningSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == json['minimumSeverity'],
        orElse: () => WarningSeverity.low,
      ),
      autoRepeatCritical: json['autoRepeatCritical'] ?? true,
      repeatInterval: Duration(minutes: json['repeatInterval'] ?? 2),
    );
  }
}