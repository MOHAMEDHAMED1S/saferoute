import 'package:equatable/equatable.dart';

// Speed warning model
class SpeedWarning extends Equatable {
  final double currentSpeed;
  final double speedLimit;
  final double excessSpeed;
  final SpeedViolationType violationType;
  final DateTime timestamp;
  final String message;

  const SpeedWarning({
    required this.currentSpeed,
    required this.speedLimit,
    required this.excessSpeed,
    required this.violationType,
    required this.timestamp,
    required this.message,
  });

  @override
  List<Object?> get props => [
        currentSpeed,
        speedLimit,
        excessSpeed,
        violationType,
        timestamp,
        message,
      ];

  Map<String, dynamic> toJson() => {
        'currentSpeed': currentSpeed,
        'speedLimit': speedLimit,
        'excessSpeed': excessSpeed,
        'violationType': violationType.name,
        'timestamp': timestamp.toIso8601String(),
        'message': message,
      };

  factory SpeedWarning.fromJson(Map<String, dynamic> json) => SpeedWarning(
        currentSpeed: json['currentSpeed']?.toDouble() ?? 0.0,
        speedLimit: json['speedLimit']?.toDouble() ?? 0.0,
        excessSpeed: json['excessSpeed']?.toDouble() ?? 0.0,
        violationType: SpeedViolationType.values.firstWhere(
          (e) => e.name == json['violationType'],
          orElse: () => SpeedViolationType.minor,
        ),
        timestamp: DateTime.parse(json['timestamp']),
        message: json['message'] ?? '',
      );
}

// Speed violation types
enum SpeedViolationType {
  minor,
  moderate,
  severe,
}

// Fatigue warning model
class FatigueWarning extends Equatable {
  final FatigueType type;
  final FatigueSeverity severity;
  final DateTime timestamp;
  final String message;
  final String recommendation;

  const FatigueWarning({
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.message,
    required this.recommendation,
  });

  @override
  List<Object?> get props => [
        type,
        severity,
        timestamp,
        message,
        recommendation,
      ];

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'severity': severity.name,
        'timestamp': timestamp.toIso8601String(),
        'message': message,
        'recommendation': recommendation,
      };

  factory FatigueWarning.fromJson(Map<String, dynamic> json) => FatigueWarning(
        type: FatigueType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => FatigueType.lackOfInteraction,
        ),
        severity: FatigueSeverity.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => FatigueSeverity.low,
        ),
        timestamp: DateTime.parse(json['timestamp']),
        message: json['message'] ?? '',
        recommendation: json['recommendation'] ?? '',
      );
}

// Fatigue types
enum FatigueType {
  lackOfInteraction,
  slowReactions,
  erraticDriving,
  timeBasedFatigue,
}

// Fatigue severity levels
enum FatigueSeverity {
  low,
  moderate,
  high,
  critical,
}

// Fatigue level for status
enum FatigueLevel {
  normal,
  moderate,
  high,
}

// Lane warning model
class LaneWarning extends Equatable {
  final DateTime timestamp;
  final String message;
  final String recommendation;

  const LaneWarning({
    required this.timestamp,
    required this.message,
    required this.recommendation,
  });

  @override
  List<Object?> get props => [
        timestamp,
        message,
        recommendation,
      ];

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'message': message,
        'recommendation': recommendation,
      };

  factory LaneWarning.fromJson(Map<String, dynamic> json) => LaneWarning(
        timestamp: DateTime.parse(json['timestamp']),
        message: json['message'] ?? '',
        recommendation: json['recommendation'] ?? '',
      );
}

// Emergency event model
class EmergencyEvent extends Equatable {
  final EmergencyType type;
  final DateTime timestamp;
  final String location;
  final String message;
  final int autoCallDelay;

  const EmergencyEvent({
    required this.type,
    required this.timestamp,
    required this.location,
    required this.message,
    required this.autoCallDelay,
  });

  @override
  List<Object?> get props => [
        type,
        timestamp,
        location,
        message,
        autoCallDelay,
      ];

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'location': location,
        'message': message,
        'autoCallDelay': autoCallDelay,
      };

  factory EmergencyEvent.fromJson(Map<String, dynamic> json) => EmergencyEvent(
        type: EmergencyType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => EmergencyType.crashDetected,
        ),
        timestamp: DateTime.parse(json['timestamp']),
        location: json['location'] ?? '',
        message: json['message'] ?? '',
        autoCallDelay: json['autoCallDelay'] ?? 30,
      );
}

// Emergency types
enum EmergencyType {
  crashDetected,
  manualTrigger,
  callMade,
  cancelled,
}

// Safety settings model
class SafetySettings extends Equatable {
  final bool speedWarningEnabled;
  final bool fatigueDetectionEnabled;
  final bool emergencyDetectionEnabled;
  final bool laneWarningEnabled;
  final double speedWarningThreshold;
  final int emergencyCallDelay;
  final bool hapticFeedbackEnabled;
  final bool voiceWarningsEnabled;
  final List<String> emergencyContacts;

  const SafetySettings({
    this.speedWarningEnabled = true,
    this.fatigueDetectionEnabled = true,
    this.emergencyDetectionEnabled = true,
    this.laneWarningEnabled = true,
    this.speedWarningThreshold = 10.0,
    this.emergencyCallDelay = 30,
    this.hapticFeedbackEnabled = true,
    this.voiceWarningsEnabled = true,
    this.emergencyContacts = const [],
  });

  @override
  List<Object?> get props => [
        speedWarningEnabled,
        fatigueDetectionEnabled,
        emergencyDetectionEnabled,
        laneWarningEnabled,
        speedWarningThreshold,
        emergencyCallDelay,
        hapticFeedbackEnabled,
        voiceWarningsEnabled,
        emergencyContacts,
      ];

  SafetySettings copyWith({
    bool? speedWarningEnabled,
    bool? fatigueDetectionEnabled,
    bool? emergencyDetectionEnabled,
    bool? laneWarningEnabled,
    double? speedWarningThreshold,
    int? emergencyCallDelay,
    bool? hapticFeedbackEnabled,
    bool? voiceWarningsEnabled,
    List<String>? emergencyContacts,
  }) {
    return SafetySettings(
      speedWarningEnabled: speedWarningEnabled ?? this.speedWarningEnabled,
      fatigueDetectionEnabled: fatigueDetectionEnabled ?? this.fatigueDetectionEnabled,
      emergencyDetectionEnabled: emergencyDetectionEnabled ?? this.emergencyDetectionEnabled,
      laneWarningEnabled: laneWarningEnabled ?? this.laneWarningEnabled,
      speedWarningThreshold: speedWarningThreshold ?? this.speedWarningThreshold,
      emergencyCallDelay: emergencyCallDelay ?? this.emergencyCallDelay,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      voiceWarningsEnabled: voiceWarningsEnabled ?? this.voiceWarningsEnabled,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }

  Map<String, dynamic> toJson() => {
        'speedWarningEnabled': speedWarningEnabled,
        'fatigueDetectionEnabled': fatigueDetectionEnabled,
        'emergencyDetectionEnabled': emergencyDetectionEnabled,
        'laneWarningEnabled': laneWarningEnabled,
        'speedWarningThreshold': speedWarningThreshold,
        'emergencyCallDelay': emergencyCallDelay,
        'hapticFeedbackEnabled': hapticFeedbackEnabled,
        'voiceWarningsEnabled': voiceWarningsEnabled,
        'emergencyContacts': emergencyContacts,
      };

  factory SafetySettings.fromJson(Map<String, dynamic> json) => SafetySettings(
        speedWarningEnabled: json['speedWarningEnabled'] ?? true,
        fatigueDetectionEnabled: json['fatigueDetectionEnabled'] ?? true,
        emergencyDetectionEnabled: json['emergencyDetectionEnabled'] ?? true,
        laneWarningEnabled: json['laneWarningEnabled'] ?? true,
        speedWarningThreshold: json['speedWarningThreshold']?.toDouble() ?? 10.0,
        emergencyCallDelay: json['emergencyCallDelay'] ?? 30,
        hapticFeedbackEnabled: json['hapticFeedbackEnabled'] ?? true,
        voiceWarningsEnabled: json['voiceWarningsEnabled'] ?? true,
        emergencyContacts: List<String>.from(json['emergencyContacts'] ?? []),
      );
}

// Safety status model
class SafetyStatus extends Equatable {
  final bool isActive;
  final double currentSpeed;
  final double speedLimit;
  final bool isEmergencyMode;
  final DateTime? lastInteractionTime;
  final FatigueLevel fatigueLevel;

  const SafetyStatus({
    required this.isActive,
    required this.currentSpeed,
    required this.speedLimit,
    required this.isEmergencyMode,
    this.lastInteractionTime,
    required this.fatigueLevel,
  });

  @override
  List<Object?> get props => [
        isActive,
        currentSpeed,
        speedLimit,
        isEmergencyMode,
        lastInteractionTime,
        fatigueLevel,
      ];

  Map<String, dynamic> toJson() => {
        'isActive': isActive,
        'currentSpeed': currentSpeed,
        'speedLimit': speedLimit,
        'isEmergencyMode': isEmergencyMode,
        'lastInteractionTime': lastInteractionTime?.toIso8601String(),
        'fatigueLevel': fatigueLevel.name,
      };

  factory SafetyStatus.fromJson(Map<String, dynamic> json) => SafetyStatus(
        isActive: json['isActive'] ?? false,
        currentSpeed: json['currentSpeed']?.toDouble() ?? 0.0,
        speedLimit: json['speedLimit']?.toDouble() ?? 120.0,
        isEmergencyMode: json['isEmergencyMode'] ?? false,
        lastInteractionTime: json['lastInteractionTime'] != null
            ? DateTime.parse(json['lastInteractionTime'])
            : null,
        fatigueLevel: FatigueLevel.values.firstWhere(
          (e) => e.name == json['fatigueLevel'],
          orElse: () => FatigueLevel.normal,
        ),
      );
}

// Distance warning model for following distance
class DistanceWarning extends Equatable {
  final double currentDistance;
  final double recommendedDistance;
  final double currentSpeed;
  final DateTime timestamp;
  final String message;

  const DistanceWarning({
    required this.currentDistance,
    required this.recommendedDistance,
    required this.currentSpeed,
    required this.timestamp,
    required this.message,
  });

  @override
  List<Object?> get props => [
        currentDistance,
        recommendedDistance,
        currentSpeed,
        timestamp,
        message,
      ];

  Map<String, dynamic> toJson() => {
        'currentDistance': currentDistance,
        'recommendedDistance': recommendedDistance,
        'currentSpeed': currentSpeed,
        'timestamp': timestamp.toIso8601String(),
        'message': message,
      };

  factory DistanceWarning.fromJson(Map<String, dynamic> json) => DistanceWarning(
        currentDistance: json['currentDistance']?.toDouble() ?? 0.0,
        recommendedDistance: json['recommendedDistance']?.toDouble() ?? 0.0,
        currentSpeed: json['currentSpeed']?.toDouble() ?? 0.0,
        timestamp: DateTime.parse(json['timestamp']),
        message: json['message'] ?? '',
      );
}