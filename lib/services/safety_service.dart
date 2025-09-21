import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/safety_model.dart';

class SafetyService {
  static final SafetyService _instance = SafetyService._internal();
  factory SafetyService() => _instance;
  SafetyService._internal();

  // Stream controllers
  final _speedWarningController = StreamController<SpeedWarning>.broadcast();
  final _fatigueWarningController = StreamController<FatigueWarning>.broadcast();
  final _emergencyController = StreamController<EmergencyEvent>.broadcast();
  final _laneWarningController = StreamController<LaneWarning>.broadcast();

  // Streams
  Stream<SpeedWarning> get speedWarnings => _speedWarningController.stream;
  Stream<FatigueWarning> get fatigueWarnings => _fatigueWarningController.stream;
  Stream<EmergencyEvent> get emergencyEvents => _emergencyController.stream;
  Stream<LaneWarning> get laneWarnings => _laneWarningController.stream;

  // State variables
  bool _isActive = false;
  double _currentSpeed = 0.0;
  double _speedLimit = 120.0;
  DateTime? _lastInteractionTime;
  Timer? _fatigueTimer;
  Timer? _emergencyTimer;
  bool _isEmergencyMode = false;
  
  // Fatigue detection
  int _consecutiveSlowReactions = 0;
  DateTime? _lastReactionTime;
  List<double> _reactionTimes = [];
  
  // Lane departure detection
  bool _isLaneDepartureEnabled = true;
  DateTime? _lastLaneWarning;
  
  // Emergency detection
  List<double> _accelerometerData = [];
  bool _crashDetected = false;

  SafetySettings _settings = SafetySettings();

  // Initialize safety service
  Future<void> initialize(SafetySettings settings) async {
    _settings = settings;
    _isActive = true;
    _startFatigueMonitoring();
    _startEmergencyMonitoring();
  }

  // Dispose resources
  void dispose() {
    _isActive = false;
    _fatigueTimer?.cancel();
    _emergencyTimer?.cancel();
    _speedWarningController.close();
    _fatigueWarningController.close();
    _emergencyController.close();
    _laneWarningController.close();
  }

  // Update current speed and check for violations
  void updateSpeed(double speed, double speedLimit) {
    _currentSpeed = speed;
    _speedLimit = speedLimit;
    
    if (!_isActive || !_settings.speedWarningEnabled) return;
    
    _checkSpeedViolation();
  }

  // Check for speed violations
  void _checkSpeedViolation() {
    final speedDifference = _currentSpeed - _speedLimit;
    
    if (speedDifference > 0) {
      final violationType = _getSpeedViolationType(speedDifference);
      
      final warning = SpeedWarning(
        currentSpeed: _currentSpeed,
        speedLimit: _speedLimit,
        excessSpeed: speedDifference,
        violationType: violationType,
        timestamp: DateTime.now(),
        message: _getSpeedWarningMessage(violationType, speedDifference),
      );
      
      _speedWarningController.add(warning);
      
      // Trigger haptic feedback for severe violations
      if (violationType == SpeedViolationType.severe) {
        HapticFeedback.heavyImpact();
      } else if (violationType == SpeedViolationType.moderate) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  SpeedViolationType _getSpeedViolationType(double excessSpeed) {
    if (excessSpeed >= 30) return SpeedViolationType.severe;
    if (excessSpeed >= 15) return SpeedViolationType.moderate;
    return SpeedViolationType.minor;
  }

  String _getSpeedWarningMessage(SpeedViolationType type, double excess) {
    switch (type) {
      case SpeedViolationType.minor:
        return 'تجاوزت السرعة المحددة بـ ${excess.toInt()} كم/س';
      case SpeedViolationType.moderate:
        return 'تحذير: سرعة عالية! تجاوزت الحد بـ ${excess.toInt()} كم/س';
      case SpeedViolationType.severe:
        return 'خطر! سرعة مفرطة! قلل السرعة فوراً';
    }
  }

  // Record user interaction for fatigue detection
  void recordUserInteraction() {
    _lastInteractionTime = DateTime.now();
    
    if (_lastReactionTime != null) {
      final reactionTime = DateTime.now().difference(_lastReactionTime!).inMilliseconds;
      _reactionTimes.add(reactionTime.toDouble());
      
      // Keep only last 10 reaction times
      if (_reactionTimes.length > 10) {
        _reactionTimes.removeAt(0);
      }
      
      _analyzeReactionTimes();
    }
    
    _lastReactionTime = DateTime.now();
  }

  // Start fatigue monitoring
  void _startFatigueMonitoring() {
    _fatigueTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isActive || !_settings.fatigueDetectionEnabled) return;
      
      _checkForFatigue();
    });
  }

  // Check for signs of fatigue
  void _checkForFatigue() {
    final now = DateTime.now();
    
    // Check for lack of interaction
    if (_lastInteractionTime != null) {
      final timeSinceLastInteraction = now.difference(_lastInteractionTime!).inMinutes;
      
      if (timeSinceLastInteraction >= 5) {
        final warning = FatigueWarning(
          type: FatigueType.lackOfInteraction,
          severity: FatigueSeverity.moderate,
          timestamp: now,
          message: 'لم يتم رصد أي تفاعل منذ $timeSinceLastInteraction دقائق',
          recommendation: 'يُنصح بأخذ استراحة قصيرة',
        );
        
        _fatigueWarningController.add(warning);
      }
    }
    
    // Check reaction times
    if (_consecutiveSlowReactions >= 3) {
      final warning = FatigueWarning(
        type: FatigueType.slowReactions,
        severity: FatigueSeverity.high,
        timestamp: now,
        message: 'تم رصد بطء في ردود الأفعال',
        recommendation: 'توقف فوراً وخذ استراحة',
      );
      
      _fatigueWarningController.add(warning);
      _consecutiveSlowReactions = 0;
    }
  }

  // Analyze reaction times for fatigue signs
  void _analyzeReactionTimes() {
    if (_reactionTimes.length < 3) return;
    
    final averageReactionTime = _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
    final lastReactionTime = _reactionTimes.last;
    
    // If last reaction time is significantly slower than average
    if (lastReactionTime > averageReactionTime * 1.5) {
      _consecutiveSlowReactions++;
    } else {
      _consecutiveSlowReactions = 0;
    }
  }

  // Detect lane departure
  void detectLaneDeparture(bool isDeparting) {
    if (!_isActive || !_isLaneDepartureEnabled) return;
    
    final now = DateTime.now();
    
    // Avoid too frequent warnings
    if (_lastLaneWarning != null && 
        now.difference(_lastLaneWarning!).inSeconds < 10) {
      return;
    }
    
    if (isDeparting) {
      _lastLaneWarning = now;
      
      final warning = LaneWarning(
        timestamp: now,
        message: 'تحذير: انحراف عن المسار',
        recommendation: 'تأكد من البقاء في المسار المحدد',
      );
      
      _laneWarningController.add(warning);
      HapticFeedback.mediumImpact();
    }
  }

  // Start emergency monitoring
  void _startEmergencyMonitoring() {
    _emergencyTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isActive || !_settings.emergencyDetectionEnabled) return;
      
      _simulateAccelerometerData();
      _checkForCrash();
    });
  }

  // Simulate accelerometer data (in real app, use actual sensors)
  void _simulateAccelerometerData() {
    final random = Random();
    final acceleration = random.nextDouble() * 2 - 1; // -1 to 1 g
    
    _accelerometerData.add(acceleration);
    
    // Keep only last 50 readings (5 seconds at 10Hz)
    if (_accelerometerData.length > 50) {
      _accelerometerData.removeAt(0);
    }
  }

  // Check for crash based on accelerometer data
  void _checkForCrash() {
    if (_accelerometerData.length < 10) return;
    
    // Look for sudden deceleration (crash indicator)
    final recentData = _accelerometerData.takeLast(10).toList();
    final maxDeceleration = recentData.reduce((a, b) => a < b ? a : b);
    
    // Threshold for crash detection (in real app, this would be calibrated)
    if (maxDeceleration < -0.8 && !_crashDetected) {
      _crashDetected = true;
      _triggerEmergencyMode();
    }
  }

  // Trigger emergency mode
  void _triggerEmergencyMode() {
    _isEmergencyMode = true;
    
    final event = EmergencyEvent(
      type: EmergencyType.crashDetected,
      timestamp: DateTime.now(),
      location: 'الموقع الحالي', // In real app, get actual location
      message: 'تم رصد حادث محتمل',
      autoCallDelay: _settings.emergencyCallDelay,
    );
    
    _emergencyController.add(event);
    
    // Start countdown for automatic emergency call
    Timer(Duration(seconds: _settings.emergencyCallDelay), () {
      if (_isEmergencyMode) {
        _makeEmergencyCall();
      }
    });
  }

  // Cancel emergency mode (user is okay)
  void cancelEmergencyMode() {
    _isEmergencyMode = false;
    _crashDetected = false;
    
    final event = EmergencyEvent(
      type: EmergencyType.cancelled,
      timestamp: DateTime.now(),
      location: 'الموقع الحالي',
      message: 'تم إلغاء وضع الطوارئ',
      autoCallDelay: 0,
    );
    
    _emergencyController.add(event);
  }

  // Make emergency call
  void _makeEmergencyCall() {
    final event = EmergencyEvent(
      type: EmergencyType.callMade,
      timestamp: DateTime.now(),
      location: 'الموقع الحالي',
      message: 'تم الاتصال بخدمات الطوارئ',
      autoCallDelay: 0,
    );
    
    _emergencyController.add(event);
    
    // In real app, make actual emergency call
    // await FlutterPhoneDirectCaller.callNumber('997');
  }

  // Manual emergency call
  void triggerManualEmergency() {
    _triggerEmergencyMode();
  }

  // Update settings
  void updateSettings(SafetySettings settings) {
    _settings = settings;
  }

  // Get current safety status
  SafetyStatus getCurrentStatus() {
    return SafetyStatus(
      isActive: _isActive,
      currentSpeed: _currentSpeed,
      speedLimit: _speedLimit,
      isEmergencyMode: _isEmergencyMode,
      lastInteractionTime: _lastInteractionTime,
      fatigueLevel: _getFatigueLevel(),
    );
  }

  FatigueLevel _getFatigueLevel() {
    if (_lastInteractionTime == null) return FatigueLevel.normal;
    
    final timeSinceLastInteraction = DateTime.now().difference(_lastInteractionTime!).inMinutes;
    
    if (timeSinceLastInteraction >= 10) return FatigueLevel.high;
    if (timeSinceLastInteraction >= 5) return FatigueLevel.moderate;
    if (_consecutiveSlowReactions >= 2) return FatigueLevel.moderate;
    
    return FatigueLevel.normal;
  }
}

extension on Iterable<double> {
  Iterable<double> takeLast(int count) {
    return skip(length - count);
  }
}