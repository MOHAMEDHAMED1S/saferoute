import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();

  Position? _currentPosition;
  LocationData? _currentLocationData;
  bool _isLocationEnabled = false;
  bool _isTracking = false;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _locationUpdateTimer;
  
  // Location settings
  double _locationAccuracy = 10.0; // meters
  Duration _updateInterval = const Duration(seconds: 30);
  bool _backgroundTracking = false;

  // Getters
  Position? get currentPosition => _currentPosition;
  LocationData? get currentLocationData => _currentLocationData;
  bool get isLocationEnabled => _isLocationEnabled;
  bool get isTracking => _isTracking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get locationAccuracy => _locationAccuracy;
  Duration get updateInterval => _updateInterval;
  bool get backgroundTracking => _backgroundTracking;

  // Get current coordinates
  double? get currentLatitude => _currentPosition?.latitude;
  double? get currentLongitude => _currentPosition?.longitude;
  double? get currentAccuracy => _currentPosition?.accuracy;
  DateTime? get lastLocationUpdate => _currentLocationData?.updatedAt;

  // Initialize location provider
  Future<void> initialize() async {
    try {
      _setLoading(true);
      await _checkLocationPermissions();
      await _getCurrentLocation();
    } catch (e) {
      _setError('خطأ في تهيئة خدمات الموقع: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Check and request location permissions
  Future<void> _checkLocationPermissions() async {
    try {
      bool hasPermission = await _locationService.checkAndRequestPermissions();
      _isLocationEnabled = hasPermission;
      notifyListeners();
    } catch (e) {
      _isLocationEnabled = false;
      throw e;
    }
  }

  // Get current location once
  Future<void> _getCurrentLocation() async {
    try {
      if (!_isLocationEnabled) {
        throw 'خدمات الموقع غير مفعلة';
      }

      Position position = await _locationService.getCurrentLocation();
      _updatePosition(position);
    } catch (e) {
      throw 'خطأ في الحصول على الموقع: ${e.toString()}';
    }
  }

  // Start location tracking
  Future<void> startLocationTracking({
    String? userId,
    bool updateFirestore = true,
  }) async {
    try {
      if (_isTracking) return;
      
      _setLoading(true);
      _clearError();

      if (!_isLocationEnabled) {
        await _checkLocationPermissions();
      }

      await _locationService.startLocationTracking(
        onLocationUpdate: (Position position) {
          _updatePosition(position);
          
          // Update user location in Firestore if userId provided
          if (userId != null && updateFirestore) {
            _updateUserLocationInFirestore(userId, position);
          }
        },
        onError: (String error) {
          _setError(error);
          _isTracking = false;
          notifyListeners();
        },
      );

      _isTracking = true;
      notifyListeners();
    } catch (e) {
      _setError('خطأ في بدء تتبع الموقع: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Stop location tracking
  void stopLocationTracking() {
    _locationService.stopLocationTracking();
    _positionSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _isTracking = false;
    notifyListeners();
  }

  // Update position and location data
  void _updatePosition(Position position) {
    _currentPosition = position;
    _currentLocationData = _locationService.positionToLocationData(position);
    notifyListeners();
  }

  // Update user location in Firestore
  Future<void> _updateUserLocationInFirestore(String userId, Position position) async {
    try {
      LocationData locationData = _locationService.positionToLocationData(position);
      await _firestoreService.updateUserLocation(userId, locationData);
    } catch (e) {
      print('Error updating user location in Firestore: $e');
    }
  }

  // Refresh current location
  Future<void> refreshLocation({String? userId, bool updateFirestore = true}) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _getCurrentLocation();
      
      // Update user location in Firestore if userId provided
      if (userId != null && updateFirestore && _currentPosition != null) {
        await _updateUserLocationInFirestore(userId, _currentPosition!);
      }
    } catch (e) {
      _setError('خطأ في تحديث الموقع: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Calculate distance to a point
  double? calculateDistanceTo({
    required double latitude,
    required double longitude,
  }) {
    if (_currentPosition == null) return null;
    
    return _locationService.calculateDistance(
      startLatitude: _currentPosition!.latitude,
      startLongitude: _currentPosition!.longitude,
      endLatitude: latitude,
      endLongitude: longitude,
    ) / 1000; // Convert to kilometers
  }

  // Calculate bearing to a point
  double? calculateBearingTo({
    required double latitude,
    required double longitude,
  }) {
    if (_currentPosition == null) return null;
    
    return _locationService.calculateBearing(
      startLatitude: _currentPosition!.latitude,
      startLongitude: _currentPosition!.longitude,
      endLatitude: latitude,
      endLongitude: longitude,
    );
  }

  // Check if user is near a location
  bool isNearLocation({
    required double latitude,
    required double longitude,
    required double radiusInMeters,
  }) {
    if (_currentPosition == null) return false;
    
    return _locationService.isNearLocation(
      userPosition: _currentPosition!,
      targetLatitude: latitude,
      targetLongitude: longitude,
      radiusInMeters: radiusInMeters,
    );
  }

  // Get location accuracy description
  String getAccuracyDescription() {
    if (_currentPosition == null) return 'غير متاح';
    return _locationService.getAccuracyDescription(_currentPosition!.accuracy);
  }

  // Check if current location is valid
  bool isCurrentLocationValid() {
    return _locationService.isValidLocation(_currentPosition);
  }

  // Update location settings
  void updateLocationAccuracy(double accuracy) {
    _locationAccuracy = accuracy;
    notifyListeners();
    
    // Restart tracking with new settings if currently tracking
    if (_isTracking) {
      stopLocationTracking();
      // Note: Would need userId to restart properly
      // startLocationTracking(userId: userId);
    }
  }

  void updateUpdateInterval(Duration interval) {
    _updateInterval = interval;
    notifyListeners();
  }

  void toggleBackgroundTracking(bool enabled) {
    _backgroundTracking = enabled;
    notifyListeners();
  }

  // Get location status info
  Map<String, dynamic> getLocationStatus() {
    return {
      'isEnabled': _isLocationEnabled,
      'isTracking': _isTracking,
      'hasCurrentLocation': _currentPosition != null,
      'accuracy': _currentPosition?.accuracy,
      'lastUpdate': _currentLocationData?.updatedAt,
      'coordinates': _currentPosition != null ? {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      } : null,
    };
  }

  // Get formatted location string
  String getFormattedLocation() {
    if (_currentPosition == null) return 'الموقع غير متاح';
    
    return 'خط العرض: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
           'خط الطول: ${_currentPosition!.longitude.toStringAsFixed(6)}\n'
           'الدقة: ${_currentPosition!.accuracy.toStringAsFixed(1)} متر';
  }

  // Check if location services are available
  Future<bool> checkLocationServices() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      return serviceEnabled;
    } catch (e) {
      return false;
    }
  }

  // Request location permissions
  Future<bool> requestLocationPermissions() async {
    try {
      await _checkLocationPermissions();
      return _isLocationEnabled;
    } catch (e) {
      _setError('خطأ في طلب أذونات الموقع: ${e.toString()}');
      return false;
    }
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      _setError('خطأ في فتح إعدادات الموقع: ${e.toString()}');
    }
  }

  // Open app settings
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      _setError('خطأ في فتح إعدادات التطبيق: ${e.toString()}');
    }
  }

  // Get distance between two points
  static double getDistanceBetween({
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
    ) / 1000; // Convert to kilometers
  }

  // Get bearing between two points
  static double getBearingBetween({
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

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all location data
  void clear() {
    stopLocationTracking();
    _currentPosition = null;
    _currentLocationData = null;
    _isLocationEnabled = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopLocationTracking();
    _positionSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
}