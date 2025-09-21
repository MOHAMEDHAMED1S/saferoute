import 'dart:async';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';
import '../models/ar_navigation_model.dart';

import '../models/user_model.dart';
import 'location_service.dart';
import 'navigation_service.dart';

// Mock sensor event classes since sensors_plus is not available
class AccelerometerEvent {
  final double x, y, z;
  AccelerometerEvent(this.x, this.y, this.z);
}

class GyroscopeEvent {
  final double x, y, z;
  GyroscopeEvent(this.x, this.y, this.z);
}

class MagnetometerEvent {
  final double x, y, z;
  MagnetometerEvent(this.x, this.y, this.z);
}

class ARNavigationService {
  static final ARNavigationService _instance = ARNavigationService._internal();
  static ARNavigationService get instance => _instance;
  ARNavigationService._internal();
  
  // Stream controllers
  final StreamController<List<ARNavigationData>> _arDataController = 
      StreamController<List<ARNavigationData>>.broadcast();
  final StreamController<ARCalibration> _calibrationController = 
      StreamController<ARCalibration>.broadcast();
  final StreamController<List<ARLandmark>> _landmarksController = 
      StreamController<List<ARLandmark>>.broadcast();
  final StreamController<bool> _arModeController = 
      StreamController<bool>.broadcast();
  
  // Streams
  Stream<List<ARNavigationData>> get arDataStream => _arDataController.stream;
  Stream<ARCalibration> get calibrationStream => _calibrationController.stream;
  Stream<List<ARLandmark>> get landmarksStream => _landmarksController.stream;
  Stream<bool> get arModeStream => _arModeController.stream;
  
  // Services (kept for future use)
  LocationService? _locationService;
  NavigationService? _navigationService;
  late SharedPreferences _prefs;
  
  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<LocationData>? _locationSubscription;
  
  // State
  bool _isInitialized = false;
  bool _isARModeActive = false;
  ARCalibration? _currentCalibration;
  List<ARNavigationData> _currentARData = [];
  List<ARLandmark> _currentLandmarks = [];
  
  // Sensor data
  double _currentHeading = 0.0;
  double _currentTilt = 0.0;
  double _currentRoll = 0.0;
  LocationData? _currentLocation;
  
  // Timers
  Timer? _updateTimer;
  Timer? _calibrationTimer;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isARModeActive => _isARModeActive;
  ARCalibration? get currentCalibration => _currentCalibration;
  List<ARNavigationData> get currentARData => _currentARData;
  List<ARLandmark> get currentLandmarks => _currentLandmarks;
  double get currentHeading => _currentHeading;
  double get currentTilt => _currentTilt;
  double get currentRoll => _currentRoll;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      // Mock services since .instance is not available
      _locationService = LocationService();
      _navigationService = NavigationService();
      
      await _loadCalibration();
      await _initializeSensors();
      _setupLocationTracking();
      _startUpdateTimer();
      
      _isInitialized = true;
      
      // Load sample landmarks
      await _loadSampleLandmarks();
      
    } catch (e) {
      print('Error initializing AR Navigation Service: $e');
      rethrow;
    }
  }
  
  Future<void> _initializeSensors() async {
    // Mock sensor initialization since sensors_plus is not available
    // Initialize accelerometer
    _accelerometerSubscription = Stream<AccelerometerEvent>.periodic(
      const Duration(milliseconds: 100),
      (_) => AccelerometerEvent(0.0, 0.0, 9.8)
    ).listen((event) {
      _updateTiltAndRoll(event);
    });
    
    // Initialize gyroscope
    _gyroscopeSubscription = Stream<GyroscopeEvent>.periodic(
      const Duration(milliseconds: 100),
      (_) => GyroscopeEvent(0.0, 0.0, 0.0)
    ).listen((event) {
      _updateRotation(event);
    });
    
    // Initialize magnetometer
    _magnetometerSubscription = Stream<MagnetometerEvent>.periodic(
      const Duration(milliseconds: 100),
      (_) => MagnetometerEvent(0.0, 1.0, 0.0)
    ).listen((event) {
      _updateHeading(event);
    });
  }
  
  void _setupLocationTracking() {
    // Mock location stream since positionStream is not available
    _locationSubscription = Stream.periodic(Duration(seconds: 1), (count) => 
        LocationData(lat: 0.0, lng: 0.0, updatedAt: DateTime.now())
    ).listen((location) {
      _currentLocation = location;
      _updateARData();
    });
  }
  
  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateARData();
    });
    
    _calibrationTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkCalibration();
    });
  }
  
  Future<void> _loadCalibration() async {
    final calibrationData = _prefs.getString('ar_calibration');
    if (calibrationData != null) {
      try {
        final Map<String, dynamic> json = {
          'compassOffset': _prefs.getDouble('compass_offset') ?? 0.0,
          'tiltOffset': _prefs.getDouble('tilt_offset') ?? 0.0,
          'scaleOffset': _prefs.getDouble('scale_offset') ?? 1.0,
          'lastCalibration': _prefs.getString('last_calibration') ?? DateTime.now().toIso8601String(),
          'isCalibrated': _prefs.getBool('is_calibrated') ?? false,
          'accuracy': _prefs.getDouble('calibration_accuracy') ?? 0.0,
        };
        _currentCalibration = ARCalibration.fromJson(json);
      } catch (e) {
        print('Error loading calibration: $e');
        _currentCalibration = _getDefaultCalibration();
      }
    } else {
      _currentCalibration = _getDefaultCalibration();
    }
    
    _calibrationController.add(_currentCalibration!);
  }
  
  ARCalibration _getDefaultCalibration() {
    return ARCalibration(
      compassOffset: 0.0,
      tiltOffset: 0.0,
      scaleOffset: 1.0,
      lastCalibration: DateTime.now(),
      isCalibrated: false,
      accuracy: 0.0,
    );
  }
  
  Future<void> _saveCalibration() async {
    if (_currentCalibration == null) return;
    
    await _prefs.setDouble('compass_offset', _currentCalibration!.compassOffset);
    await _prefs.setDouble('tilt_offset', _currentCalibration!.tiltOffset);
    await _prefs.setDouble('scale_offset', _currentCalibration!.scaleOffset);
    await _prefs.setString('last_calibration', _currentCalibration!.lastCalibration.toIso8601String());
    await _prefs.setBool('is_calibrated', _currentCalibration!.isCalibrated);
    await _prefs.setDouble('calibration_accuracy', _currentCalibration!.accuracy);
  }
  
  void _updateTiltAndRoll(AccelerometerEvent event) {
    // Calculate tilt and roll from accelerometer data
    _currentTilt = math.atan2(event.y, math.sqrt(event.x * event.x + event.z * event.z)) * 180 / math.pi;
    _currentRoll = math.atan2(-event.x, event.z) * 180 / math.pi;
    
    // Apply calibration offset
    if (_currentCalibration != null) {
      _currentTilt += _currentCalibration!.tiltOffset;
    }
  }
  
  void _updateRotation(GyroscopeEvent event) {
    // Update rotation based on gyroscope data
    // This would be used for smooth rotation tracking
  }
  
  void _updateHeading(MagnetometerEvent event) {
    // Calculate heading from magnetometer data
    _currentHeading = math.atan2(event.y, event.x) * 180 / math.pi;
    
    // Normalize to 0-360 degrees
    if (_currentHeading < 0) {
      _currentHeading += 360;
    }
    
    // Apply calibration offset
    if (_currentCalibration != null) {
      _currentHeading += _currentCalibration!.compassOffset;
      _currentHeading = _currentHeading % 360;
    }
  }
  
  void _updateARData() {
    if (!_isARModeActive || _currentLocation == null) return;
    
    final List<ARNavigationData> arData = [];
    
    // Get current navigation instructions
    final instructions = <Map<String, dynamic>>[
      {
        'latitude': 0.0,
        'longitude': 0.0,
        'distance': 0.0,
        'type': 'turn_left',
        'text': 'Turn left',
      }
    ]; // Mock instructions since currentInstructions is not available
    
    for (int i = 0; i < instructions.length && i < 3; i++) {
      final instruction = instructions[i];
      final arInstruction = _createARInstruction(instruction, i);
      final arOverlay = _createAROverlay(arInstruction, i);
      
      final arNavData = ARNavigationData(
        id: 'instruction_$i',
        instruction: arInstruction,
        landmark: _findNearestLandmark(instruction['latitude'], instruction['longitude']),
        overlay: arOverlay,
        distance: instruction['distance'],
        bearing: _calculateBearing(
          _currentLocation!.lat,
          _currentLocation!.lng,
          instruction['latitude'],
          instruction['longitude'],
        ),
        timestamp: DateTime.now(),
        visibility: _calculateVisibility(0.0, i), // Mock distance
      );
      
      arData.add(arNavData);
    }
    
    _currentARData = arData;
    _arDataController.add(_currentARData);
  }
  
  ARInstruction _createARInstruction(dynamic instruction, int index) {
    return ARInstruction(
      id: 'ar_instruction_$index',
      type: _getARInstructionType(instruction['type']),
      text: instruction['text'],
      arabicText: _getArabicInstruction(instruction),
      direction: _getARDirection(instruction['direction'] ?? 'straight'),
      distance: instruction['distance'],
      streetName: instruction['streetName'] ?? 'Unknown Street',
      priority: index == 0 ? ARPriority.high : ARPriority.medium,
      animation: ARAnimation(
        type: index == 0 ? ARAnimationType.pulse : ARAnimationType.fade,
        duration: 1.0,
        curve: ARAnimationCurve.easeInOut,
        repeat: index == 0,
        reverse: true,
        delay: index * 0.2,
      ),
    );
  }
  
  AROverlay _createAROverlay(ARInstruction instruction, int index) {
    final position = _calculateARPosition(instruction.distance, instruction.direction);
    
    return AROverlay(
      id: 'overlay_${instruction.id}',
      type: AROverlayType.arrow,
      position: position,
      size: ARSize(
        width: 100 - (index * 20),
        height: 100 - (index * 20),
        depth: 10,
      ),
      color: _getInstructionColor(instruction.priority),
      opacity: 1.0 - (index * 0.2),
      animation: instruction.animation,
      isVisible: true,
      text: instruction.arabicText,
      iconPath: _getDirectionIcon(instruction.direction),
      rotation: _getDirectionRotation(instruction.direction),
      scale: 1.0 - (index * 0.1),
    );
  }
  
  ARPosition _calculateARPosition(double distance, ARDirection direction) {
    // Calculate 3D position based on distance and direction
    double x = 0;
    double y = 0;
    double z = distance;
    
    // Adjust position based on direction
    switch (direction) {
      case ARDirection.left:
      case ARDirection.slightLeft:
      case ARDirection.sharpLeft:
        x = -50;
        break;
      case ARDirection.right:
      case ARDirection.slightRight:
      case ARDirection.sharpRight:
        x = 50;
        break;
      default:
        x = 0;
    }
    
    // Convert to GPS coordinates (simplified)
    final lat = _currentLocation?.lat ?? 0.0;
    final lon = _currentLocation?.lng ?? 0.0;
    
    return ARPosition(
      x: x,
      y: y,
      z: z,
      latitude: lat,
      longitude: lon,
      altitude: 0,
    );
  }
  
  ARLandmark? _findNearestLandmark(double lat, double lon) {
    if (_currentLandmarks.isEmpty) return null;
    
    ARLandmark? nearest;
    double minDistance = double.infinity;
    
    for (final landmark in _currentLandmarks) {
      final distance = _calculateDistance(
        lat, lon,
        landmark.position.latitude,
        landmark.position.longitude,
      );
      
      if (distance < minDistance && distance < 500) { // Within 500m
        minDistance = distance;
        nearest = landmark;
      }
    }
    
    return nearest;
  }
  
  ARVisibility _calculateVisibility(double distance, int index) {
    return ARVisibility(
      isVisible: distance < 1000, // Show within 1km
      distance: distance,
      minDistance: 10,
      maxDistance: 1000,
      opacity: math.max(0.3, 1.0 - (distance / 1000)),
      condition: ARVisibilityCondition.always,
    );
  }
  
  Future<void> _loadSampleLandmarks() async {
    // Load sample landmarks for demonstration
    _currentLandmarks = [
      ARLandmark(
        id: 'landmark_1',
        name: 'King Fahd Fountain',
        arabicName: 'نافورة الملك فهد',
        type: ARLandmarkType.monument,
        position: const ARPosition(
          x: 0, y: 0, z: 0,
          latitude: 21.5433, longitude: 39.1728, altitude: 0,
        ),
        distance: 500,
        bearing: 45,
        visibility: const ARVisibility(
          isVisible: true,
          distance: 500,
          minDistance: 0,
          maxDistance: 1000,
          opacity: 1.0,
          condition: ARVisibilityCondition.always,
        ),
        confidence: 0.9,
      ),
      ARLandmark(
        id: 'landmark_2',
        name: 'Red Sea Mall',
        arabicName: 'مول البحر الأحمر',
        type: ARLandmarkType.mall,
        position: const ARPosition(
          x: 0, y: 0, z: 0,
          latitude: 21.5507, longitude: 39.1467, altitude: 0,
        ),
        distance: 800,
        bearing: 120,
        visibility: const ARVisibility(
          isVisible: true,
          distance: 800,
          minDistance: 0,
          maxDistance: 1000,
          opacity: 0.8,
          condition: ARVisibilityCondition.always,
        ),
        confidence: 0.85,
      ),
    ];
    
    _landmarksController.add(_currentLandmarks);
  }
  
  // Public methods
  Future<void> startARMode() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    _isARModeActive = true;
    _arModeController.add(_isARModeActive);
    
    // Start AR tracking
    _updateARData();
  }
  
  void stopARMode() {
    _isARModeActive = false;
    _arModeController.add(_isARModeActive);
    
    // Clear AR data
    _currentARData.clear();
    _arDataController.add(_currentARData);
  }
  
  Future<void> calibrateAR() async {
    // Perform AR calibration
    final newCalibration = ARCalibration(
      compassOffset: _currentHeading,
      tiltOffset: _currentTilt,
      scaleOffset: 1.0,
      lastCalibration: DateTime.now(),
      isCalibrated: true,
      accuracy: 0.9,
    );
    
    _currentCalibration = newCalibration;
    await _saveCalibration();
    _calibrationController.add(_currentCalibration!);
  }
  
  void _checkCalibration() {
    if (_currentCalibration?.needsRecalibration == true) {
      // Trigger recalibration notification
      print('AR calibration needed');
    }
  }
  
  // Helper methods
  ARInstructionType _getARInstructionType(String type) {
    switch (type.toLowerCase()) {
      case 'turn':
        return ARInstructionType.turn;
      case 'continue':
        return ARInstructionType.continue_;
      case 'merge':
        return ARInstructionType.merge;
      case 'exit':
        return ARInstructionType.exit;
      case 'roundabout':
        return ARInstructionType.roundabout;
      default:
        return ARInstructionType.continue_;
    }
  }
  
  ARDirection _getARDirection(String direction) {
    switch (direction.toLowerCase()) {
      case 'left':
        return ARDirection.left;
      case 'right':
        return ARDirection.right;
      case 'straight':
        return ARDirection.straight;
      case 'slight_left':
        return ARDirection.slightLeft;
      case 'slight_right':
        return ARDirection.slightRight;
      case 'sharp_left':
        return ARDirection.sharpLeft;
      case 'sharp_right':
        return ARDirection.sharpRight;
      case 'u_turn':
        return ARDirection.uTurn;
      default:
        return ARDirection.straight;
    }
  }
  
  String _getArabicInstruction(dynamic instruction) {
    // Convert instruction to Arabic
    final type = instruction.type.toLowerCase();
    final direction = instruction.direction?.toLowerCase() ?? '';
    final distance = instruction.distance;
    
    String arabicText = '';
    
    if (type == 'turn') {
      if (direction.contains('left')) {
        arabicText = 'انعطف يساراً';
      } else if (direction.contains('right')) {
        arabicText = 'انعطف يميناً';
      }
    } else if (type == 'continue') {
      arabicText = 'تابع السير';
    } else if (type == 'exit') {
      arabicText = 'اخرج من';
    }
    
    if (distance < 100) {
      arabicText += ' بعد ${distance.toInt()} متر';
    } else if (distance < 1000) {
      arabicText += ' بعد ${(distance / 100).round() * 100} متر';
    } else {
      arabicText += ' بعد ${(distance / 1000).toStringAsFixed(1)} كم';
    }
    
    return arabicText;
  }
  
  ARColor _getInstructionColor(ARPriority priority) {
    switch (priority) {
      case ARPriority.critical:
        return const ARColor(red: 255, green: 0, blue: 0, alpha: 1.0);
      case ARPriority.high:
        return const ARColor(red: 255, green: 165, blue: 0, alpha: 1.0);
      case ARPriority.medium:
        return const ARColor(red: 0, green: 255, blue: 0, alpha: 1.0);
      case ARPriority.low:
        return const ARColor(red: 0, green: 0, blue: 255, alpha: 1.0);
    }
  }
  
  String _getDirectionIcon(ARDirection direction) {
    switch (direction) {
      case ARDirection.left:
        return 'assets/icons/arrow_left.svg';
      case ARDirection.right:
        return 'assets/icons/arrow_right.svg';
      case ARDirection.straight:
        return 'assets/icons/arrow_up.svg';
      case ARDirection.uTurn:
        return 'assets/icons/u_turn.svg';
      default:
        return 'assets/icons/arrow_up.svg';
    }
  }
  
  double _getDirectionRotation(ARDirection direction) {
    switch (direction) {
      case ARDirection.left:
        return -90;
      case ARDirection.right:
        return 90;
      case ARDirection.slightLeft:
        return -45;
      case ARDirection.slightRight:
        return 45;
      case ARDirection.sharpLeft:
        return -135;
      case ARDirection.sharpRight:
        return 135;
      case ARDirection.uTurn:
        return 180;
      default:
        return 0;
    }
  }
  
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final lat1Rad = lat1 * math.pi / 180;
    final lat2Rad = lat2 * math.pi / 180;
    final deltaLonRad = (lon2 - lon1) * math.pi / 180;
    
    final y = math.sin(deltaLonRad) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLonRad);
    
    final bearing = math.atan2(y, x);
    
    return (bearing * 180 / math.pi + 360) % 360;
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    
    final lat1Rad = lat1 * math.pi / 180;
    final lat2Rad = lat2 * math.pi / 180;
    final deltaLatRad = (lat2 - lat1) * math.pi / 180;
    final deltaLonRad = (lon2 - lon1) * math.pi / 180;
    
    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  void dispose() {
    _updateTimer?.cancel();
    _calibrationTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _locationSubscription?.cancel();
    
    _arDataController.close();
    _calibrationController.close();
    _landmarksController.close();
    _arModeController.close();
  }
}