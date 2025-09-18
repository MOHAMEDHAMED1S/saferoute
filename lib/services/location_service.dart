import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  bool _isTracking = false;

  // Get current position
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;

  // Check and request location permissions
  Future<bool> checkAndRequestPermissions() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'خدمات الموقع غير مفعلة. يرجى تفعيلها من الإعدادات.';
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'تم رفض إذن الموقع. يرجى السماح بالوصول للموقع.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'تم رفض إذن الموقع نهائياً. يرجى تفعيله من إعدادات التطبيق.';
      }

      return true;
    } catch (e) {
      throw e.toString();
    }
  }

  // Get current location once
  Future<Position> getCurrentLocation() async {
    try {
      await checkAndRequestPermissions();
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _currentPosition = position;
      return position;
    } catch (e) {
      throw 'خطأ في الحصول على الموقع الحالي: ${e.toString()}';
    }
  }

  // Start location tracking
  Future<void> startLocationTracking({
    required Function(Position) onLocationUpdate,
    Function(String)? onError,
  }) async {
    try {
      if (_isTracking) {
        return; // Already tracking
      }

      await checkAndRequestPermissions();
      
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _currentPosition = position;
          onLocationUpdate(position);
        },
        onError: (error) {
          _isTracking = false;
          if (onError != null) {
            onError('خطأ في تتبع الموقع: ${error.toString()}');
          }
        },
      );

      _isTracking = true;
    } catch (e) {
      _isTracking = false;
      throw 'خطأ في بدء تتبع الموقع: ${e.toString()}';
    }
  }

  // Stop location tracking
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
  }

  // Calculate distance between two points
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Calculate bearing between two points
  double calculateBearing({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Check if user is near a location
  bool isNearLocation({
    required Position userPosition,
    required double targetLatitude,
    required double targetLongitude,
    required double radiusInMeters,
  }) {
    double distance = calculateDistance(
      startLatitude: userPosition.latitude,
      startLongitude: userPosition.longitude,
      endLatitude: targetLatitude,
      endLongitude: targetLongitude,
    );
    
    return distance <= radiusInMeters;
  }

  // Convert Position to LocationData
  LocationData positionToLocationData(Position position) {
    return LocationData(
      lat: position.latitude,
      lng: position.longitude,
      updatedAt: DateTime.now(),
    );
  }

  // Get location accuracy description
  String getAccuracyDescription(double accuracy) {
    if (accuracy <= 5) {
      return 'دقة عالية جداً';
    } else if (accuracy <= 10) {
      return 'دقة عالية';
    } else if (accuracy <= 20) {
      return 'دقة متوسطة';
    } else if (accuracy <= 50) {
      return 'دقة منخفضة';
    } else {
      return 'دقة ضعيفة';
    }
  }

  // Check if location is valid (not null and reasonable coordinates)
  bool isValidLocation(Position? position) {
    if (position == null) return false;
    
    // Check if coordinates are within reasonable bounds
    if (position.latitude < -90 || position.latitude > 90) return false;
    if (position.longitude < -180 || position.longitude > 180) return false;
    
    // Check if accuracy is reasonable (less than 1000 meters)
    if (position.accuracy > 1000) return false;
    
    return true;
  }

  // Get location settings for different scenarios
  LocationSettings getLocationSettings({
    required LocationAccuracy accuracy,
    int distanceFilter = 0,
    Duration? timeLimit,
  }) {
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeLimit: timeLimit,
    );
  }

  // Get optimized settings for driver mode
  LocationSettings getDriverModeSettings() {
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters for better navigation
    );
  }

  // Get optimized settings for battery saving
  LocationSettings getBatterySavingSettings() {
    return const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 50, // Update every 50 meters to save battery
    );
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Open app settings
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  // Dispose resources
  void dispose() {
    stopLocationTracking();
  }

  // Format coordinates for display
  String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  // Get location permission status
  Future<LocationPermission> getPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  // Check if high accuracy is available
  Future<bool> isHighAccuracyAvailable() async {
    try {
      LocationAccuracyStatus status = await Geolocator.getLocationAccuracy();
      return status == LocationAccuracyStatus.precise;
    } catch (e) {
      return false;
    }
  }
}