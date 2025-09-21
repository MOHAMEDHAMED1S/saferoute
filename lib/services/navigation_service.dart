import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/warning_model.dart';
import '../models/route_model.dart';
import 'warning_service.dart';

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
  LatLng? _currentLocation;
  LatLng? _destination;
  String? _destinationName;
  Timer? _routeMonitoringTimer;
  Timer? _recalculationTimer;
  Timer? _trafficUpdateTimer;
  bool _isNavigating = false;
  double _currentSpeed = 0.0;
  final List<LatLng> _routeHistory = [];
  DateTime? _lastRecalculation;
  int _routeDeviationCount = 0;
  
  // Settings
  NavigationSettings _settings = const NavigationSettings();
  
  // Warning service integration
  final WarningService _warningService = WarningService();
  
  // Smart features
  final Map<String, RouteInfo> _routeCache = {};
  final List<String> _recentDestinations = [];
  final bool _isLearningMode = true;
  Map<String, int> _routePreferences = {};

  // Getters
  NavigationState get currentState => _currentState;
  RouteInfo? get currentRoute => _currentRoute;
  List<RouteInfo> get alternativeRoutes => _alternativeRoutes;
  bool get isNavigating => _isNavigating;
  NavigationSettings get settings => _settings;
  double get currentSpeed => _currentSpeed;
  List<String> get recentDestinations => _recentDestinations;

  // Initialize navigation service
  Future<void> initialize() async {
    try {
      _warningService.initialize();
      _loadUserPreferences();
      _updateState(NavigationState.idle());
    } catch (e) {
      _updateState(NavigationState.error('فشل في تهيئة خدمة الملاحة: $e'));
    }
  }

  // Start navigation to destination
  Future<void> startNavigation({
    required LatLng destination,
    String? destinationName,
    RouteType? routeType,
    bool forceRecalculation = false,
  }) async {
    try {
      _destination = destination;
      _destinationName = destinationName;
      _routeDeviationCount = 0;
      _updateState(NavigationState.calculating());

      // Add to recent destinations
      if (destinationName != null && !_recentDestinations.contains(destinationName)) {
        _recentDestinations.insert(0, destinationName);
        if (_recentDestinations.length > 10) {
          _recentDestinations.removeLast();
        }
      }

      // Use preferred route type or user's learned preference
      final preferredType = routeType ?? 
          _getPreferredRouteType(destinationName) ?? 
          _settings.preferredRouteType;

      // Check cache first
      final cacheKey = '${_currentLocation?.latitude}_${_currentLocation?.longitude}_${destination.latitude}_${destination.longitude}_$preferredType';
      RouteInfo? route;
      
      if (!forceRecalculation && _routeCache.containsKey(cacheKey)) {
        route = _routeCache[cacheKey];
      } else {
        // Calculate new route
        route = await _calculateRoute(
          destination: destination,
          routeType: preferredType,
        );
        
        if (route != null) {
          _routeCache[cacheKey] = route;
        }
      }

      if (route != null) {
        _currentRoute = route;
        _isNavigating = true;
        
        // Calculate alternative routes if enabled
        if (_settings.enableAlternativeRoutes) {
          _alternativeRoutes = await _calculateAlternativeRoutes(destination);
          _alternativeRoutesController.add(_alternativeRoutes);
        }

        _updateState(NavigationState.navigating(
          route: route,
          alternativeRoutes: _alternativeRoutes,
          destinationName: destinationName,
        ));

        // Start monitoring
        _startRouteMonitoring();
        _startRecalculationTimer();
        _startTrafficMonitoring();
        
        // Announce start
        if (_settings.enableVoiceGuidance) {
          _announceVoiceInstruction('بدء الملاحة إلى ${destinationName ?? "الوجهة"} - المسافة ${route.formattedDistance} والوقت المتوقع ${route.formattedTime}');
        }
      } else {
        _updateState(NavigationState.error('لا يمكن حساب المسار إلى الوجهة المحددة'));
      }
    } catch (e) {
      _updateState(NavigationState.error('خطأ في بدء الملاحة: $e'));
    }
  }

  // Stop navigation
  void stopNavigation() {
    _isNavigating = false;
    _currentRoute = null;
    _alternativeRoutes.clear();
    _destination = null;
    _destinationName = null;
    _routeHistory.clear();
    _routeDeviationCount = 0;
    
    _routeMonitoringTimer?.cancel();
    _recalculationTimer?.cancel();
    _trafficUpdateTimer?.cancel();
    
    _updateState(NavigationState.idle());
    
    if (_settings.enableVoiceGuidance) {
      _announceVoiceInstruction('تم إيقاف الملاحة');
    }
  }

  // Update current location
  void updateLocation(LatLng location, {double? bearing, double? speed}) {
    _currentLocation = location;
    // bearing is stored but not used in current implementation
    if (speed != null) _currentSpeed = speed;
    
    if (_isNavigating && _currentRoute != null) {
      _routeHistory.add(location);
      _checkRouteProgress(location);
      _checkForRouteDeviation(location);
      _checkSpeedLimits();
      _checkUpcomingInstructions();
    }
  }

  // Update navigation settings
  void updateSettings(NavigationSettings settings) {
    _settings = settings;
    
    if (_isNavigating) {
      // Restart timers with new intervals
      _recalculationTimer?.cancel();
      _startRecalculationTimer();
    }
  }

  // Switch to alternative route
  Future<void> switchToAlternativeRoute(RouteInfo alternativeRoute) async {
    if (!_isNavigating) return;
    
    // Learn user preference
    if (_isLearningMode && _destinationName != null) {
      _learnRoutePreference(_destinationName!, alternativeRoute.routeType);
    }
    
    _currentRoute = alternativeRoute;
    _alternativeRoutes.removeWhere((route) => route.id == alternativeRoute.id);
    
    _updateState(NavigationState.navigating(
      route: alternativeRoute,
      alternativeRoutes: _alternativeRoutes,
      destinationName: _destinationName,
      hasRouteUpdate: true,
    ));
    
    _routeUpdateController.add(alternativeRoute);
    
    if (_settings.enableVoiceGuidance) {
      final timeSaved = _calculateTimeDifference(alternativeRoute);
      final message = timeSaved > 0 
          ? 'تم التبديل إلى طريق بديل يوفر $timeSaved دقيقة'
          : 'تم التبديل إلى طريق بديل أكثر أماناً';
      _announceVoiceInstruction(message);
    }
  }

  // Force route recalculation
  Future<void> recalculateRoute({String? reason}) async {
    if (!_isNavigating || _destination == null) return;
    
    // Prevent too frequent recalculations
    if (_lastRecalculation != null && 
        DateTime.now().difference(_lastRecalculation!).inSeconds < 30) {
      return;
    }
    
    _lastRecalculation = DateTime.now();
    _updateState(NavigationState.recalculating(reason ?? 'إعادة حساب المسار'));
    
    try {
      final newRoute = await _calculateRoute(
        destination: _destination!,
        routeType: _settings.preferredRouteType,
        avoidWarnings: true,
      );
      
      if (newRoute != null) {
        _currentRoute = newRoute;
        
        // Recalculate alternatives
        if (_settings.enableAlternativeRoutes) {
          _alternativeRoutes = await _calculateAlternativeRoutes(_destination!);
          _alternativeRoutesController.add(_alternativeRoutes);
        }
        
        _updateState(NavigationState.navigating(
          route: newRoute,
          alternativeRoutes: _alternativeRoutes,
          destinationName: _destinationName,
          hasRouteUpdate: true,
        ));
        
        _routeUpdateController.add(newRoute);
        
        if (_settings.enableVoiceGuidance && reason != null) {
          _announceVoiceInstruction('تم إعادة حساب المسار: $reason');
        }
      }
    } catch (e) {
      _updateState(NavigationState.error('فشل في إعادة حساب المسار: $e'));
    }
  }

  // Get route suggestions based on current location
  Future<List<RouteInfo>> getRouteSuggestions(LatLng destination) async {
    if (_currentLocation == null) return [];
    
    final suggestions = <RouteInfo>[];
    
    // Calculate different route types
    for (final routeType in RouteType.values) {
      final route = await _calculateRoute(
        destination: destination,
        routeType: routeType,
      );
      
      if (route != null) {
        suggestions.add(route);
      }
    }
    
    // Sort by user preferences and current conditions
    suggestions.sort((a, b) {
      final aScore = _calculateRouteScore(a);
      final bScore = _calculateRouteScore(b);
      return bScore.compareTo(aScore);
    });
    
    return suggestions;
  }

  // Smart route optimization
  Future<void> optimizeRoute() async {
    if (!_isNavigating || _destination == null) return;
    
    final warnings = _warningService.getActiveWarnings();
    final hasSignificantWarnings = warnings.any(
      (w) => w.severity == WarningSeverity.high || w.severity == WarningSeverity.critical,
    );
    
    if (hasSignificantWarnings) {
      // Check if alternative route is significantly better
      final betterRoute = await _findBetterRoute();
      if (betterRoute != null) {
        _suggestRouteChange(betterRoute, 'تجنب المخاطر على المسار الحالي');
      }
    }
  }

  // Private methods
  void _updateState(NavigationState state) {
    _currentState = state;
    _navigationStateController.add(state);
  }

  void _announceVoiceInstruction(String instruction) {
    _voiceInstructionController.add(instruction);
  }

  void _startRouteMonitoring() {
    _routeMonitoringTimer?.cancel();
    _routeMonitoringTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => _monitorRoute(),
    );
  }

  void _startRecalculationTimer() {
    _recalculationTimer?.cancel();
    _recalculationTimer = Timer.periodic(
      _settings.recalculationInterval,
      (timer) => _checkForRouteOptimization(),
    );
  }

  void _startTrafficMonitoring() {
    _trafficUpdateTimer?.cancel();
    _trafficUpdateTimer = Timer.periodic(
      const Duration(minutes: 2),
      (timer) => _updateTrafficConditions(),
    );
  }

  void _monitorRoute() {
    if (!_isNavigating || _currentLocation == null || _currentRoute == null) {
      return;
    }
    
    // Check if arrived
    final distanceToDestination = _calculateDistance(
      _currentLocation!,
      _currentRoute!.endLocation,
    );
    
    if (distanceToDestination < 50) { // 50 meters threshold
      _handleArrival();
      return;
    }
    
    // Update route progress
    _updateRouteProgress();
  }

  void _checkRouteProgress(LatLng location) {
    if (_currentRoute == null) return;
    
    // Find closest point on route
    double minDistance = double.infinity;
    int closestPointIndex = 0;
    
    for (int i = 0; i < _currentRoute!.polylinePoints.length; i++) {
      final distance = _calculateDistance(location, _currentRoute!.polylinePoints[i]);
      if (distance < minDistance) {
        minDistance = distance;
        closestPointIndex = i;
      }
    }
    
    // Calculate remaining distance
    double remainingDistance = 0;
    for (int i = closestPointIndex; i < _currentRoute!.polylinePoints.length - 1; i++) {
      remainingDistance += _calculateDistance(
        _currentRoute!.polylinePoints[i],
        _currentRoute!.polylinePoints[i + 1],
      );
    }
    
    // Estimate remaining time based on current speed and traffic
    final estimatedSpeed = _currentSpeed > 0 ? _currentSpeed : 50.0; // km/h
    final remainingTimeMinutes = (remainingDistance / 1000) / (estimatedSpeed / 60);
    
    // Update route with new remaining distance and time
    final updatedRoute = _currentRoute!.copyWith(
      remainingDistance: remainingDistance.round(),
      estimatedTimeRemaining: Duration(minutes: remainingTimeMinutes.round()),
    );
    
    _currentRoute = updatedRoute;
    _routeUpdateController.add(updatedRoute);
  }

  void _checkForRouteDeviation(LatLng location) {
    if (_currentRoute == null) return;
    
    // Find distance to route
    double minDistanceToRoute = double.infinity;
    
    for (final point in _currentRoute!.polylinePoints) {
      final distance = _calculateDistance(location, point);
      if (distance < minDistanceToRoute) {
        minDistanceToRoute = distance;
      }
    }
    
    // Check if deviated beyond threshold
    if (minDistanceToRoute > _settings.rerouteThreshold) {
      _routeDeviationCount++;
      
      if (_routeDeviationCount >= 3 && _settings.enableAutoReroute) {
        recalculateRoute(reason: 'انحراف عن المسار المحدد');
        _routeDeviationCount = 0;
      } else if (_settings.enableVoiceGuidance) {
        _announceVoiceInstruction('تحذير: انحراف عن المسار المحدد');
      }
    } else {
      _routeDeviationCount = 0;
    }
  }

  void _checkSpeedLimits() {
    // Simulate speed limit checking
    const speedLimit = 120.0; // km/h
    
    if (_currentSpeed > speedLimit + 10) {
      if (_settings.enableVoiceGuidance) {
        _announceVoiceInstruction('تحذير: تجاوز الحد المسموح للسرعة');
      }
    }
  }

  void _checkUpcomingInstructions() {
    if (_currentRoute == null || _currentRoute!.instructions.isEmpty) return;
    
    for (final instruction in _currentRoute!.instructions) {
      final distance = _calculateDistance(_currentLocation!, instruction.location);
      
      if (distance <= 500 && distance > 400) { // 500m warning
        if (_settings.enableVoiceGuidance) {
          _announceVoiceInstruction('خلال 500 متر: ${instruction.text}');
        }
      } else if (distance <= 100 && distance > 50) { // 100m warning
        if (_settings.enableVoiceGuidance) {
          _announceVoiceInstruction('الآن: ${instruction.text}');
        }
      }
    }
  }

  void _checkForRouteOptimization() {
    if (!_isNavigating || _destination == null) return;
    
    // Check for traffic updates and warnings
    final warnings = _warningService.getActiveWarnings();
    if (warnings.isNotEmpty) {
      final hasHighSeverityWarnings = warnings.any(
        (w) => w.severity == WarningSeverity.high || w.severity == WarningSeverity.critical,
      );
      
      if (hasHighSeverityWarnings) {
        optimizeRoute();
      }
    }
  }

  void _updateTrafficConditions() {
    if (_currentRoute == null) return;
    
    // Simulate traffic condition updates
    final random = Random();
    final conditions = TrafficCondition.values;
    final newCondition = conditions[random.nextInt(conditions.length)];
    
    if (newCondition != _currentRoute!.trafficCondition) {
      final updatedRoute = _currentRoute!.copyWith(trafficCondition: newCondition);
      _currentRoute = updatedRoute;
      _routeUpdateController.add(updatedRoute);
      
      if (_settings.enableVoiceGuidance && newCondition == TrafficCondition.heavy) {
        _announceVoiceInstruction('تحديث: ازدحام مروري على المسار');
      }
    }
  }

  void _updateRouteProgress() {
    if (_currentRoute == null || _currentLocation == null) return;
    
    _updateState(NavigationState.navigating(
      route: _currentRoute!,
      alternativeRoutes: _alternativeRoutes,
      destinationName: _destinationName,
    ));
  }

  void _handleArrival() {
    // Learn from successful navigation
    if (_isLearningMode && _destinationName != null && _currentRoute != null) {
      _learnRoutePreference(_destinationName!, _currentRoute!.routeType);
    }
    
    _isNavigating = false;
    _routeMonitoringTimer?.cancel();
    _recalculationTimer?.cancel();
    _trafficUpdateTimer?.cancel();
    
    _updateState(NavigationState.arrived());
    
    if (_settings.enableVoiceGuidance) {
      _announceVoiceInstruction('وصلت إلى وجهتك بأمان');
    }
  }

  void _suggestRouteChange(RouteInfo betterRoute, String reason) {
    if (_settings.enableVoiceGuidance) {
      final timeSaved = _calculateTimeDifference(betterRoute);
      final message = timeSaved > 0 
          ? 'يوجد طريق بديل أفضل يوفر $timeSaved دقيقة - $reason'
          : 'يوجد طريق بديل أكثر أماناً - $reason';
      _announceVoiceInstruction(message);
    }
    
    // Add to alternatives if not already there
    if (!_alternativeRoutes.any((route) => route.id == betterRoute.id)) {
      _alternativeRoutes.insert(0, betterRoute);
      _alternativeRoutesController.add(_alternativeRoutes);
    }
  }

  // Route calculation (enhanced with smart features)
  Future<RouteInfo?> _calculateRoute({
    required LatLng destination,
    RouteType routeType = RouteType.fastest,
    bool avoidWarnings = false,
  }) async {
    if (_currentLocation == null) return null;
    
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Get nearby warnings if avoiding them
    List<DrivingWarning> warnings = [];
    if (avoidWarnings) {
      warnings = _warningService.getActiveWarnings();
    }
    
    // Calculate base route
    final distance = _calculateDistance(_currentLocation!, destination);
    
    // Adjust for route type and warnings
    double adjustedDistance = distance;
    Duration adjustedTime;
    int safetyScore = 85;
    TrafficCondition trafficCondition = TrafficCondition.moderate;
    
    switch (routeType) {
      case RouteType.fastest:
        adjustedTime = Duration(minutes: (distance / 1000 * 1.5).round());
        break;
      case RouteType.shortest:
        adjustedDistance = distance * 0.9;
        adjustedTime = Duration(minutes: (distance / 1000 * 2).round());
        break;
      case RouteType.safest:
        adjustedDistance = distance * 1.1;
        adjustedTime = Duration(minutes: (distance / 1000 * 2.2).round());
        safetyScore = 95;
        trafficCondition = TrafficCondition.light;
        break;
      case RouteType.scenic:
        adjustedDistance = distance * 1.3;
        adjustedTime = Duration(minutes: (distance / 1000 * 2.5).round());
        break;
      case RouteType.economical:
        adjustedDistance = distance * 1.05;
        adjustedTime = Duration(minutes: (distance / 1000 * 2.1).round());
        break;
    }
    
    // Adjust for warnings
    if (warnings.isNotEmpty) {
      final highSeverityWarnings = warnings.where(
        (w) => w.severity == WarningSeverity.high || w.severity == WarningSeverity.critical,
      ).length;
      
      if (highSeverityWarnings > 0) {
        adjustedDistance *= 1.1;
        adjustedTime = Duration(minutes: adjustedTime.inMinutes + highSeverityWarnings * 5);
        safetyScore -= highSeverityWarnings * 10;
        trafficCondition = TrafficCondition.heavy;
      }
    }
    
    // Generate mock instructions
    final instructions = _generateMockInstructions(_currentLocation!, destination);
    
    return RouteInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startLocation: _currentLocation!,
      endLocation: destination,
      polylinePoints: _generateMockPolyline(_currentLocation!, destination),
      totalDistance: adjustedDistance.round(),
      remainingDistance: adjustedDistance.round(),
      estimatedTotalTime: adjustedTime,
      estimatedTimeRemaining: adjustedTime,
      routeType: routeType,
      trafficCondition: trafficCondition,
      instructions: instructions,
      safetyScore: safetyScore.clamp(0, 100),
      fuelConsumption: (adjustedDistance / 1000 * 0.08), // L/100km
      tollCost: routeType == RouteType.fastest ? 15.0 : 0.0,
    );
  }

  Future<List<RouteInfo>> _calculateAlternativeRoutes(LatLng destination) async {
    if (_currentLocation == null) return [];
    
    final alternatives = <RouteInfo>[];
    final routeTypes = [RouteType.shortest, RouteType.safest, RouteType.economical];
    
    for (int i = 0; i < routeTypes.length; i++) {
      final route = await _calculateRoute(
        destination: destination,
        routeType: routeTypes[i],
      );
      
      if (route != null) {
        alternatives.add(route);
      }
    }
    
    return alternatives;
  }

  Future<RouteInfo?> _findBetterRoute() async {
    if (_destination == null || _currentRoute == null) return null;
    
    final alternatives = await _calculateAlternativeRoutes(_destination!);
    
    for (final route in alternatives) {
      if (_calculateRouteScore(route) > _calculateRouteScore(_currentRoute!)) {
        return route;
      }
    }
    
    return null;
  }

  List<LatLng> _generateMockPolyline(LatLng start, LatLng end, {int offset = 0}) {
    final points = <LatLng>[];
    final steps = 15;
    
    for (int i = 0; i <= steps; i++) {
      final ratio = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * ratio;
      final lng = start.longitude + (end.longitude - start.longitude) * ratio;
      
      // Add some variation for alternative routes
      final latOffset = offset * 0.001 * sin(i * pi / steps);
      final lngOffset = offset * 0.001 * cos(i * pi / steps);
      
      points.add(LatLng(lat + latOffset, lng + lngOffset));
    }
    
    return points;
  }

  List<RouteInstruction> _generateMockInstructions(LatLng start, LatLng end) {
    return [
      RouteInstruction(
        text: 'اتجه شمالاً على الطريق الرئيسي',
        maneuver: 'straight',
        location: start,
        distance: 1000,
        time: const Duration(minutes: 2),
        streetName: 'الطريق الرئيسي',
      ),
      RouteInstruction(
        text: 'انعطف يميناً',
        maneuver: 'turn-right',
        location: LatLng(
          start.latitude + 0.01,
          start.longitude + 0.01,
        ),
        distance: 500,
        time: const Duration(minutes: 1),
        streetName: 'شارع الملك فهد',
      ),
      RouteInstruction(
        text: 'وصلت إلى وجهتك',
        maneuver: 'arrive',
        location: end,
        distance: 0,
        time: const Duration(seconds: 0),
      ),
    ];
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
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

  int _calculateRouteScore(RouteInfo route) {
    int score = 0;
    
    // Safety score weight
    score += route.safetyScore;
    
    // Time efficiency
    score += (120 - route.estimatedTimeRemaining.inMinutes).clamp(0, 60);
    
    // Traffic condition
    switch (route.trafficCondition) {
      case TrafficCondition.light:
        score += 20;
        break;
      case TrafficCondition.moderate:
        score += 10;
        break;
      case TrafficCondition.heavy:
        score -= 10;
        break;
      case TrafficCondition.severe:
        score -= 20;
        break;
    }
    
    return score;
  }

  int _calculateTimeDifference(RouteInfo newRoute) {
    if (_currentRoute == null) return 0;
    
    return _currentRoute!.estimatedTimeRemaining.inMinutes - 
           newRoute.estimatedTimeRemaining.inMinutes;
  }

  // Learning and preferences
  void _loadUserPreferences() {
    // In a real app, load from shared preferences or database
    _routePreferences = {
      'المنزل': RouteType.fastest.index,
      'العمل': RouteType.safest.index,
    };
  }

  RouteType? _getPreferredRouteType(String? destinationName) {
    if (destinationName == null || !_routePreferences.containsKey(destinationName)) {
      return null;
    }
    
    final index = _routePreferences[destinationName]!;
    return RouteType.values[index];
  }

  void _learnRoutePreference(String destinationName, RouteType routeType) {
    _routePreferences[destinationName] = routeType.index;
    // In a real app, save to persistent storage
  }

  // Dispose
  void dispose() {
    _routeMonitoringTimer?.cancel();
    _recalculationTimer?.cancel();
    _trafficUpdateTimer?.cancel();
    _navigationStateController.close();
    _routeUpdateController.close();
    _voiceInstructionController.close();
    _alternativeRoutesController.close();
  }
}