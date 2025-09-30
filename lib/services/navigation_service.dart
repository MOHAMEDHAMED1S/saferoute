import 'dart:async';
import 'dart:math';
import '../models/warning_model.dart';
import '../models/route_model.dart';
import 'warning_service.dart';

// Navigation state enum
enum NavigationStateType { idle, navigating, paused, completed, error }

// Navigation state class
class NavigationState {
  final NavigationStateType type;
  final String? message;
  
  const NavigationState({required this.type, this.message});
  
  factory NavigationState.idle() => const NavigationState(type: NavigationStateType.idle);
  factory NavigationState.navigating() => const NavigationState(type: NavigationStateType.navigating);
  factory NavigationState.paused() => const NavigationState(type: NavigationStateType.paused);
  factory NavigationState.completed() => const NavigationState(type: NavigationStateType.completed);
  factory NavigationState.error(String message) => NavigationState(type: NavigationStateType.error, message: message);
  factory NavigationState.calculating() => const NavigationState(type: NavigationStateType.idle, message: 'calculating');
}

// Navigation settings class
class NavigationSettings {
  final bool voiceEnabled;
  final bool avoidTolls;
  final bool avoidHighways;
  final String routePreference;
  final String preferredRouteType;
  final bool enableAlternativeRoutes;
  
  const NavigationSettings({
    this.voiceEnabled = true,
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.routePreference = 'fastest',
    this.preferredRouteType = 'fastest',
    this.enableAlternativeRoutes = true,
  });
}

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Stream controllers
  final StreamController<NavigationState> _navigationStateController =
      StreamController<NavigationState>.broadcast();
  final StreamController<RouteInfo> _routeUpdateController =
      StreamController<RouteInfo>.broadcast();
  final StreamController<String> _voiceInstructionController =
      StreamController<String>.broadcast();
  final StreamController<List<RouteInfo>> _alternativeRoutesController =
      StreamController<List<RouteInfo>>.broadcast();

  // Streams
  Stream<NavigationState> get navigationStateStream =>
      _navigationStateController.stream;
  Stream<RouteInfo> get routeUpdateStream => _routeUpdateController.stream;
  Stream<String> get voiceInstructionStream =>
      _voiceInstructionController.stream;
  Stream<List<RouteInfo>> get alternativeRoutesStream =>
      _alternativeRoutesController.stream;

  // Current state
  NavigationState _currentState = NavigationState.idle();
  RouteInfo? _currentRoute;
  List<RouteInfo> _alternativeRoutes = [];
  Position? _currentLocation;
  Position? _destination;
  String? _destinationName;
  Timer? _routeMonitoringTimer;
  Timer? _recalculationTimer;
  Timer? _trafficUpdateTimer;
  bool _isNavigating = false;
  double _currentSpeed = 0.0;
  final List<Position> _routeHistory = [];
  DateTime? _lastRecalculation;
  int _routeDeviationCount = 0;
  
  // Settings
  NavigationSettings _settings = const NavigationSettings();

  // Getters
  NavigationState get currentState => _currentState;
  RouteInfo? get currentRoute => _currentRoute;
  List<RouteInfo> get alternativeRoutes => _alternativeRoutes;
  Position? get currentLocation => _currentLocation;
  Position? get destination => _destination;
  String? get destinationName => _destinationName;
  bool get isNavigating => _isNavigating;
  double get currentSpeed => _currentSpeed;
  NavigationSettings get settings => _settings;

  // Calculate route
  Future<RouteInfo?> calculateRoute(Position start, Position end, {String? routeType}) async {
    try {
      _navigationStateController.add(NavigationState.calculating());
      
      // Mock route calculation
      await Future.delayed(const Duration(seconds: 2));
      
      final route = RouteInfo(
         id: 'route_${DateTime.now().millisecondsSinceEpoch}',
         startLocation: start,
         endLocation: end,
         polylinePoints: _generateMockPolyline(start, end),
         totalDistance: _calculateDistance(start, end).round(),
         remainingDistance: _calculateDistance(start, end).round(),
         estimatedTotalTime: Duration(minutes: (_calculateDistance(start, end) / 1000 * 2).round()),
         estimatedTimeRemaining: Duration(minutes: (_calculateDistance(start, end) / 1000 * 2).round()),
         instructions: _generateMockInstructions(start, end),
         trafficCondition: TrafficCondition.moderate,
         routeType: RouteType.fastest,
         safetyScore: 85,
       );

      _currentRoute = route;
      _navigationStateController.add(NavigationState.idle());
      
      return route;
    } catch (e) {
      _navigationStateController.add(NavigationState.error('Failed to calculate route: $e'));
      return null;
    }
  }

  // Start navigation
  Future<void> startNavigation(RouteInfo route) async {
    _currentRoute = route;
    _isNavigating = true;
    _currentState = NavigationState.navigating();
    _navigationStateController.add(_currentState);
    
    // Start monitoring
    _startRouteMonitoring();
  }

  // Stop navigation
  void stopNavigation() {
    _isNavigating = false;
    _currentState = NavigationState.idle();
    _navigationStateController.add(_currentState);
    
    _routeMonitoringTimer?.cancel();
    _recalculationTimer?.cancel();
    _trafficUpdateTimer?.cancel();
  }

  // Update current location
  void updateCurrentLocation(Position location) {
    _currentLocation = location;
    _routeHistory.add(location);
    
    if (_isNavigating && _currentRoute != null) {
      _checkRouteProgress(location);
    }
  }

  // Private methods
  void _startRouteMonitoring() {
    _routeMonitoringTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentLocation != null && _currentRoute != null) {
        _checkRouteProgress(_currentLocation!);
      }
    });
  }

  void _checkRouteProgress(Position currentLocation) {
    // Mock route progress checking
    final distanceToDestination = _calculateDistance(currentLocation, _currentRoute!.endLocation);
    
    if (distanceToDestination < 50) { // Within 50 meters
      _completeNavigation();
    }
  }

  void _completeNavigation() {
    _isNavigating = false;
    _currentState = NavigationState.completed();
    _navigationStateController.add(_currentState);
    
    _routeMonitoringTimer?.cancel();
    _recalculationTimer?.cancel();
    _trafficUpdateTimer?.cancel();
  }

  List<Position> _generateMockPolyline(Position start, Position end, {double offset = 0}) {
    final List<Position> points = [];
    const int steps = 20;
    
    for (int i = 0; i <= steps; i++) {
      final double ratio = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * ratio;
      final lng = start.longitude + (end.longitude - start.longitude) * ratio;
      
      // Add some variation for alternative routes
      final latOffset = offset * 0.001 * sin(i * pi / steps);
      final lngOffset = offset * 0.001 * cos(i * pi / steps);
      
      points.add(Position(latitude: lat + latOffset, longitude: lng + lngOffset));
    }
    
    return points;
  }

  List<RouteInstruction> _generateMockInstructions(Position start, Position end) {
    return [
      RouteInstruction(
        text: 'اتجه شمالاً على الطريق الرئيسي',
        instruction: 'اتجه شمالاً على الطريق الرئيسي',
        maneuver: 'straight',
        maneuverType: ManeuverType.straight,
        location: start,
        distance: 1000,
        time: const Duration(minutes: 2),
        timeToInstruction: const Duration(minutes: 2),
        streetName: 'الطريق الرئيسي',
      ),
      RouteInstruction(
        text: 'انعطف يميناً',
        instruction: 'انعطف يميناً',
        maneuver: 'turn-right',
        maneuverType: ManeuverType.turnRight,
        location: Position(
          latitude: start.latitude + 0.01,
          longitude: start.longitude + 0.01,
        ),
        distance: 500,
        time: const Duration(minutes: 1),
        timeToInstruction: const Duration(minutes: 1),
        streetName: 'شارع الملك فهد',
      ),
      RouteInstruction(
        text: 'وصلت إلى وجهتك',
        instruction: 'وصلت إلى وجهتك',
        maneuver: 'arrive',
        maneuverType: ManeuverType.arrive,
        location: end,
        distance: 0,
        time: const Duration(seconds: 0),
        timeToInstruction: const Duration(seconds: 0),
      ),
    ];
  }

  double _calculateDistance(Position point1, Position point2) {
    const double earthRadius = 6371000; // meters
    
    final double lat1Rad = point1.latitude * pi / 180;
    final double lat2Rad = point2.latitude * pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  void dispose() {
    _navigationStateController.close();
    _routeUpdateController.close();
    _voiceInstructionController.close();
    _alternativeRoutesController.close();
    
    _routeMonitoringTimer?.cancel();
    _recalculationTimer?.cancel();
    _trafficUpdateTimer?.cancel();
  }
}