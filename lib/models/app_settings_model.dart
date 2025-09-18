import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettingsModel {
  final Map<String, ReportTypeSettings> reportTypes;
  final DriverModeSettings driverModeDefaults;

  AppSettingsModel({
    required this.reportTypes,
    required this.driverModeDefaults,
  });

  // Convert from Firestore document
  factory AppSettingsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    Map<String, ReportTypeSettings> reportTypes = {};
    if (data['reportTypes'] != null) {
      Map<String, dynamic> reportTypesData = data['reportTypes'];
      reportTypesData.forEach((key, value) {
        reportTypes[key] = ReportTypeSettings.fromMap(value);
      });
    }
    
    return AppSettingsModel(
      reportTypes: reportTypes,
      driverModeDefaults: DriverModeSettings.fromMap(data['driverModeDefaults'] ?? {}),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> reportTypesData = {};
    reportTypes.forEach((key, value) {
      reportTypesData[key] = value.toMap();
    });
    
    return {
      'reportTypes': reportTypesData,
      'driverModeDefaults': driverModeDefaults.toMap(),
    };
  }

  // Get default settings
  factory AppSettingsModel.defaultSettings() {
    return AppSettingsModel(
      reportTypes: {
        'accident': ReportTypeSettings(expiryHours: 3),
        'jam': ReportTypeSettings(expiryHours: 2),
        'car_breakdown': ReportTypeSettings(expiryHours: 4),
        'bump': ReportTypeSettings(expiryHours: 0), // دائم
        'closed_road': ReportTypeSettings(expiryHours: 12),
      },
      driverModeDefaults: DriverModeSettings(alertsOnly: true),
    );
  }

  // Get expiry hours for a report type
  int getExpiryHours(String reportType) {
    return reportTypes[reportType]?.expiryHours ?? 3;
  }

  // Check if report type is permanent (never expires)
  bool isPermanent(String reportType) {
    return getExpiryHours(reportType) == 0;
  }
}

class ReportTypeSettings {
  final int expiryHours;
  final bool isEnabled;
  final int minConfirmations;
  final double trustThreshold;

  ReportTypeSettings({
    required this.expiryHours,
    this.isEnabled = true,
    this.minConfirmations = 3,
    this.trustThreshold = 0.6,
  });

  factory ReportTypeSettings.fromMap(Map<String, dynamic> map) {
    return ReportTypeSettings(
      expiryHours: map['expiryHours'] ?? 3,
      isEnabled: map['isEnabled'] ?? true,
      minConfirmations: map['minConfirmations'] ?? 3,
      trustThreshold: (map['trustThreshold'] ?? 0.6).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expiryHours': expiryHours,
      'isEnabled': isEnabled,
      'minConfirmations': minConfirmations,
      'trustThreshold': trustThreshold,
    };
  }
}

class DriverModeSettings {
  final bool alertsOnly;
  final bool vibrationEnabled;
  final double alertDistance; // in meters
  final int alertVolume; // 0-100

  DriverModeSettings({
    this.alertsOnly = true,
    this.vibrationEnabled = true,
    this.alertDistance = 500.0,
    this.alertVolume = 80,
  });

  factory DriverModeSettings.fromMap(Map<String, dynamic> map) {
    return DriverModeSettings(
      alertsOnly: map['alertsOnly'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      alertDistance: (map['alertDistance'] ?? 500.0).toDouble(),
      alertVolume: map['alertVolume'] ?? 80,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alertsOnly': alertsOnly,
      'vibrationEnabled': vibrationEnabled,
      'alertDistance': alertDistance,
      'alertVolume': alertVolume,
    };
  }
}