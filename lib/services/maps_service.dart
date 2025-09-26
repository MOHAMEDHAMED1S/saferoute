import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/route_model.dart';
import 'maps_firebase_service.dart';

class MapsService {
  // Firebase service
  final MapsFirebaseService _firebaseService = MapsFirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Current route
  RouteInfo? _currentRoute;
  NavigationStatus _navigationStatus = NavigationStatus.idle;
  
  // Controllers
  final _routeController = StreamController<RouteInfo?>.broadcast();
  final _navigationStatusController = StreamController<NavigationStatus>.broadcast();
  final _locationController = StreamController<LatLng>.broadcast();
  
  // Streams
  Stream<RouteInfo?> get routeStream => _routeController.stream;
  Stream<NavigationStatus> get navigationStatusStream => _navigationStatusController.stream;
  Stream<LatLng> get locationStream => _locationController.stream;
  
  // Initialize service
  Future<void> initialize() async {
    // Set initial navigation status
    _navigationStatusController.add(_navigationStatus);
  }
  
  // Calculate route
  Future<RouteInfo> calculateRoute(LatLng start, LatLng end, RouteType type) async {
    // Update navigation status
    _navigationStatus = NavigationStatus.calculating;
    _navigationStatusController.add(_navigationStatus);
    
    try {
      // In a real app, this would call a routing API
      // For now, we'll create a mock route
      _currentRoute = RouteInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startLocation: start,
        endLocation: end,
        polylinePoints: [start, end],
        totalDistance: 5000, // 5 km
        remainingDistance: 5000, // 5 km
        estimatedTotalTime: const Duration(minutes: 15),
        estimatedTimeRemaining: const Duration(minutes: 15),
        routeType: type,
        trafficCondition: TrafficCondition.moderate,
        instructions: [
          RouteInstruction(
            text: 'Start navigation',
            maneuver: 'start',
            location: LatLng(24.7136, 46.6753), // الرياض
            distance: 0,
            time: const Duration(seconds: 0),
            instruction: 'Start navigation',
            timeToInstruction: const Duration(seconds: 0),
            maneuverType: ManeuverType.start,
          ),
          RouteInstruction(
            text: 'Arrive at destination',
            maneuver: 'arrive',
            location: LatLng(24.7255, 46.6468), // وجهة في الرياض
            distance: 5000,
            time: const Duration(minutes: 15),
            instruction: 'Arrive at destination',
            timeToInstruction: const Duration(minutes: 15),
            maneuverType: ManeuverType.arrive,
          ),
        ],
        safetyScore: 85,
      );
      
      // Update route stream
      _routeController.add(_currentRoute);
      
      // Update navigation status
      _navigationStatus = NavigationStatus.navigating;
      _navigationStatusController.add(_navigationStatus);
      
      return _currentRoute!;
    } catch (e) {
      // Update navigation status
      _navigationStatus = NavigationStatus.error;
      _navigationStatusController.add(_navigationStatus);
      
      throw Exception('Failed to calculate route: $e');
    }
  }
  
  // Start navigation
  Future<void> startNavigation() async {
    if (_currentRoute == null) {
      throw Exception('No route calculated');
    }
    
    // Update navigation status
    _navigationStatus = NavigationStatus.navigating;
    _navigationStatusController.add(_navigationStatus);
    
    // Save route to history in Firebase
    await _firebaseService.saveRouteToHistory(_currentRoute!);
  }
  
  // Stop navigation
  Future<void> stopNavigation() async {
    // Update navigation status
    _navigationStatus = NavigationStatus.idle;
    _navigationStatusController.add(_navigationStatus);
    
    // Clear current route
    _currentRoute = null;
    _routeController.add(null);
  }
  
  // Update current location
  Future<void> updateCurrentLocation(LatLng location) async {
    // Update location stream
    _locationController.add(location);
    
    // Update user location in Firebase
    await _firebaseService.updateUserLocation(location);
  }
  
  // Save favorite location
  Future<void> saveFavoriteLocation(String name, LatLng location, String icon) async {
    await _firebaseService.saveFavoriteLocation(name, location, icon);
  }
  
  // Get favorite locations
  Future<List<Map<String, dynamic>>> getFavoriteLocations() async {
    return await _firebaseService.getFavoriteLocations();
  }
  
  // Delete favorite location
  Future<void> deleteFavoriteLocation(String id) async {
    await _firebaseService.deleteFavoriteLocation(id);
  }
  
  // Save custom route
  Future<String> saveCustomRoute(String name) async {
    if (_currentRoute == null) {
      throw Exception('No route to save');
    }
    
    return await _firebaseService.saveCustomRoute(_currentRoute!, name);
  }
  
  // Get saved routes
  Future<List<Map<String, dynamic>>> getSavedRoutes() async {
    return await _firebaseService.getSavedRoutes();
  }
  
  // Delete saved route
  Future<void> deleteSavedRoute(String id) async {
    await _firebaseService.deleteSavedRoute(id);
  }
  
  // Get navigation history
  Future<List<Map<String, dynamic>>> getNavigationHistory() async {
    return await _firebaseService.getNavigationHistory();
  }
  
  // Dispose resources
  void dispose() {
    _routeController.close();
    _navigationStatusController.close();
    _locationController.close();
  }
}