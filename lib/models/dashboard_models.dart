import 'package:flutter/material.dart';

class DashboardStats {
  final int nearbyRisks;
  final int trustPoints;
  final int monthlyReports;
  final String trustLevel;

  DashboardStats({
    required this.nearbyRisks,
    required this.trustPoints,
    required this.monthlyReports,
    required this.trustLevel,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      nearbyRisks: json['nearbyRisks'] ?? 0,
      trustPoints: json['trustPoints'] ?? 0,
      monthlyReports: json['monthlyReports'] ?? 0,
      trustLevel: json['trustLevel'] ?? 'مبتدئ',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nearbyRisks': nearbyRisks,
      'trustPoints': trustPoints,
      'monthlyReports': monthlyReports,
      'trustLevel': trustLevel,
    };
  }
}

class NearbyReport {
  final String id;
  final String title;
  final String description;
  final String distance;
  final String timeAgo;
  final int confirmations;
  final ReportType type;
  final double latitude;
  final double longitude;

  NearbyReport({
    required this.id,
    required this.title,
    required this.description,
    required this.distance,
    required this.timeAgo,
    required this.confirmations,
    required this.type,
    required this.latitude,
    required this.longitude,
  });

  factory NearbyReport.fromJson(Map<String, dynamic> json) {
    return NearbyReport(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      distance: json['distance'] ?? '',
      timeAgo: json['timeAgo'] ?? '',
      confirmations: json['confirmations'] ?? 0,
      type: ReportType.values.firstWhere(
        (e) => e.toString() == 'ReportType.${json['type']}',
        orElse: () => ReportType.other,
      ),
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'distance': distance,
      'timeAgo': timeAgo,
      'confirmations': confirmations,
      'type': type.toString().split('.').last,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

enum ReportType {
  accident,
  pothole,
  traffic,
  roadwork,
  weather,
  other,
}

extension ReportTypeExtension on ReportType {
  String get displayName {
    switch (this) {
      case ReportType.accident:
        return 'حادث';
      case ReportType.pothole:
        return 'مطب';
      case ReportType.traffic:
        return 'ازدحام';
      case ReportType.roadwork:
        return 'أعمال طريق';
      case ReportType.weather:
        return 'طقس';
      case ReportType.other:
        return 'أخرى';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportType.accident:
        return Icons.car_crash;
      case ReportType.pothole:
        return Icons.warning;
      case ReportType.traffic:
        return Icons.traffic;
      case ReportType.roadwork:
        return Icons.construction;
      case ReportType.weather:
        return Icons.cloud;
      case ReportType.other:
        return Icons.error;
    }
  }

  Color get color {
    switch (this) {
      case ReportType.accident:
        return Colors.red;
      case ReportType.pothole:
        return Colors.orange;
      case ReportType.traffic:
        return Colors.blue;
      case ReportType.roadwork:
        return Colors.amber;
      case ReportType.weather:
        return Colors.grey;
      case ReportType.other:
        return Colors.purple;
    }
  }
}

class WeatherInfo {
  final String condition;
  final int temperature;
  final String visibility;
  final String drivingCondition;

  WeatherInfo({
    required this.condition,
    required this.temperature,
    required this.visibility,
    required this.drivingCondition,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      condition: json['condition'] ?? 'مشمس',
      temperature: json['temperature'] ?? 25,
      visibility: json['visibility'] ?? 'ممتازة',
      drivingCondition: json['drivingCondition'] ?? 'رؤية ممتازة',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'temperature': temperature,
      'visibility': visibility,
      'drivingCondition': drivingCondition,
    };
  }

  String get icon {
    switch (condition.toLowerCase()) {
      case 'مشمس':
      case 'صافي':
        return '☀️';
      case 'غائم':
        return '☁️';
      case 'ممطر':
        return '🌧️';
      case 'عاصف':
        return '💨';
      default:
        return '☀️';
    }
  }
}

class SafetyTip {
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime date;

  SafetyTip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.date,
  });

  factory SafetyTip.fromJson(Map<String, dynamic> json) {
    return SafetyTip(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'عام',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'date': date.toIso8601String(),
    };
  }
}

class EmergencyAlert {
  final String id;
  final String message;
  final String location;
  final int distanceInMeters;
  final DateTime timestamp;
  final AlertSeverity severity;

  EmergencyAlert({
    required this.id,
    required this.message,
    required this.location,
    required this.distanceInMeters,
    required this.timestamp,
    required this.severity,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      location: json['location'] ?? '',
      distanceInMeters: json['distanceInMeters'] ?? 0,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString() == 'AlertSeverity.${json['severity']}',
        orElse: () => AlertSeverity.low,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'location': location,
      'distanceInMeters': distanceInMeters,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.toString().split('.').last,
    };
  }

  String get distanceText {
    if (distanceInMeters < 1000) {
      return '$distanceInMetersم';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}كم';
    }
  }
}

enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

extension AlertSeverityExtension on AlertSeverity {
  String get displayName {
    switch (this) {
      case AlertSeverity.low:
        return 'منخفض';
      case AlertSeverity.medium:
        return 'متوسط';
      case AlertSeverity.high:
        return 'عالي';
      case AlertSeverity.critical:
        return 'حرج';
    }
  }

  Color get color {
    switch (this) {
      case AlertSeverity.low:
        return const Color(0xFF4CAF50);
      case AlertSeverity.medium:
        return const Color(0xFFFF9800);
      case AlertSeverity.high:
        return const Color(0xFFE53935);
      case AlertSeverity.critical:
        return const Color(0xFF9C27B0);
    }
  }
}