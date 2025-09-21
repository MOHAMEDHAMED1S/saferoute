import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/warning_model.dart';
import '../models/report_model.dart';

class WarningService {
  static final WarningService _instance = WarningService._internal();
  factory WarningService() => _instance;
  WarningService._internal();

  final StreamController<List<DrivingWarning>> _warningsController =
      StreamController<List<DrivingWarning>>.broadcast();
  
  Stream<List<DrivingWarning>> get warningsStream => _warningsController.stream;
  
  List<DrivingWarning> _activeWarnings = [];
  Timer? _scanTimer;
  Position? _currentPosition;
  List<ReportModel> _nearbyReports = [];
  
  // Warning detection settings
  static const double _warningRadius = 2000; // 2km radius
  static const double _criticalRadius = 500; // 500m critical radius
  static const double _immediateRadius = 100; // 100m immediate radius
  
  void initialize() {
    _startWarningScanner();
  }
  
  void dispose() {
    _scanTimer?.cancel();
    _warningsController.close();
  }
  
  void updateLocation(Position position) {
    _currentPosition = position;
  }
  
  void updateNearbyReports(List<ReportModel> reports) {
    _nearbyReports = reports;
    _scanForWarnings();
  }
  
  void _startWarningScanner() {
    _scanTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _scanForWarnings();
    });
  }
  
  void _scanForWarnings() {
    if (_currentPosition == null) return;
    
    List<DrivingWarning> newWarnings = [];
    
    // Scan for report-based warnings
    for (ReportModel report in _nearbyReports) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        report.location.lat,
        report.location.lng,
      );
      
      if (distance <= _warningRadius) {
        DrivingWarning warning = _createWarningFromReport(report, distance);
        newWarnings.add(warning);
      }
    }
    
    // Add simulated warnings for demo
    _addSimulatedWarnings(newWarnings);
    
    // Update active warnings
    _activeWarnings = newWarnings;
    _warningsController.add(_activeWarnings);
  }
  
  DrivingWarning _createWarningFromReport(ReportModel report, double distance) {
    WarningType type = _getWarningTypeFromReport(report.type.name);
    WarningSeverity severity = _calculateSeverity(distance, type);
    String message = _generateWarningMessage(type, distance.round());
    
    return DrivingWarning(
      id: report.id,
      type: type,
      message: message,
      distance: distance.round(),
      severity: severity,
      location: LatLng(report.location.lat, report.location.lng),
      timestamp: DateTime.now(),
      isActive: true,
    );
  }
  
  WarningType _getWarningTypeFromReport(String reportType) {
    switch (reportType) {
      case 'accident':
        return WarningType.accident;
      case 'traffic':
        return WarningType.traffic;
      case 'roadwork':
        return WarningType.roadwork;
      case 'police':
        return WarningType.police;
      default:
        return WarningType.general;
    }
  }
  
  WarningSeverity _calculateSeverity(double distance, WarningType type) {
    if (distance <= _immediateRadius) {
      return WarningSeverity.critical;
    } else if (distance <= _criticalRadius) {
      return type == WarningType.accident ? WarningSeverity.high : WarningSeverity.medium;
    } else if (distance <= 1000) {
      return WarningSeverity.medium;
    } else {
      return WarningSeverity.low;
    }
  }
  
  String _generateWarningMessage(WarningType type, int distance) {
    String typeText = _getWarningTypeText(type);
    
    if (distance <= _immediateRadius) {
      return 'احذر! $typeText الآن';
    } else if (distance <= _criticalRadius) {
      return 'انتباه، $typeText خلال $distanceم';
    } else if (distance <= 1000) {
      return '$typeText خلال ${(distance / 1000).toStringAsFixed(1)} كم';
    } else {
      return '$typeText على بعد ${(distance / 1000).toStringAsFixed(1)} كم';
    }
  }
  
  String _getWarningTypeText(WarningType type) {
    switch (type) {
      case WarningType.accident:
        return 'حادث مروري';
      case WarningType.traffic:
        return 'ازدحام مروري';
      case WarningType.roadwork:
        return 'أعمال طريق';
      case WarningType.police:
        return 'نقطة شرطة';
      case WarningType.speedCamera:
        return 'كاميرا سرعة';
      case WarningType.speedLimit:
        return 'تحذير سرعة';
      case WarningType.general:
        return 'تحذير';
    }
  }
  
  void _addSimulatedWarnings(List<DrivingWarning> warnings) {
    if (_currentPosition == null) return;
    
    // Simulate accident warning
    if (Random().nextBool() && warnings.length < 2) {
      warnings.add(
        DrivingWarning(
          id: 'sim_accident_${DateTime.now().millisecondsSinceEpoch}',
          type: WarningType.accident,
          message: 'حادث خلال 800م في المسار الأيسر',
          distance: 800,
          severity: WarningSeverity.high,
          location: LatLng(
            _currentPosition!.latitude + 0.007,
            _currentPosition!.longitude + 0.007,
          ),
          timestamp: DateTime.now(),
          isActive: true,
        ),
      );
    }
    
    // Simulate traffic warning
    if (Random().nextBool() && warnings.length < 3) {
      warnings.add(
        DrivingWarning(
          id: 'sim_traffic_${DateTime.now().millisecondsSinceEpoch}',
          type: WarningType.traffic,
          message: 'ازدحام مروري خلال 1.2 كم',
          distance: 1200,
          severity: WarningSeverity.medium,
          location: LatLng(
            _currentPosition!.latitude + 0.01,
            _currentPosition!.longitude + 0.01,
          ),
          timestamp: DateTime.now(),
          isActive: true,
        ),
      );
    }
  }
  
  // Warning management methods
  void dismissWarning(String warningId) {
    _activeWarnings.removeWhere((warning) => warning.id == warningId);
    _warningsController.add(_activeWarnings);
  }
  
  void dismissAllWarnings() {
    _activeWarnings.clear();
    _warningsController.add(_activeWarnings);
  }
  
  List<DrivingWarning> getActiveWarnings() {
    return List.from(_activeWarnings);
  }
  
  List<DrivingWarning> getCriticalWarnings() {
    return _activeWarnings
        .where((warning) => warning.severity == WarningSeverity.critical)
        .toList();
  }
  
  List<DrivingWarning> getWarningsByType(WarningType type) {
    return _activeWarnings
        .where((warning) => warning.type == type)
        .toList();
  }
  
  // Voice warning methods
  bool shouldPlayVoiceWarning(DrivingWarning warning) {
    // Play voice warning for high and critical severity
    return warning.severity == WarningSeverity.high ||
           warning.severity == WarningSeverity.critical;
  }
  
  String getVoiceWarningText(DrivingWarning warning) {
    if (warning.distance <= _immediateRadius) {
      return 'احذر، أنت تقترب من ${_getWarningTypeText(warning.type)} الآن';
    } else if (warning.distance <= _criticalRadius) {
      return 'انتباه، ${_getWarningTypeText(warning.type)} خلال ${warning.distance} متر';
    } else {
      return warning.message;
    }
  }
  
  // Warning colors and icons
  Color getWarningColor(WarningType type) {
    switch (type) {
      case WarningType.accident:
        return Colors.red;
      case WarningType.traffic:
        return Colors.orange;
      case WarningType.roadwork:
        return Colors.yellow;
      case WarningType.police:
        return Colors.blue;
      case WarningType.speedCamera:
        return Colors.purple;
      case WarningType.speedLimit:
        return Colors.red;
      case WarningType.general:
        return Colors.grey;
    }
  }
  
  IconData getWarningIcon(WarningType type) {
    switch (type) {
      case WarningType.accident:
        return Icons.car_crash;
      case WarningType.traffic:
        return Icons.traffic;
      case WarningType.roadwork:
        return Icons.construction;
      case WarningType.police:
        return Icons.local_police;
      case WarningType.speedCamera:
        return Icons.camera_alt;
      case WarningType.speedLimit:
        return Icons.speed;
      case WarningType.general:
        return Icons.warning;
    }
  }
  
  Color getSeverityColor(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.critical:
        return Colors.red;
      case WarningSeverity.high:
        return Colors.orange;
      case WarningSeverity.medium:
        return Colors.yellow;
      case WarningSeverity.low:
        return Colors.blue;
    }
  }
}