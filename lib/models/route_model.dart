import 'package:google_maps_flutter/google_maps_flutter.dart';

enum RouteType {
  fastest,
  shortest,
  scenic,
  safest,
  economical,
}

enum TrafficCondition {
  light,
  moderate,
  heavy,
  severe,
}

enum NavigationStatus {
  idle,
  calculating,
  navigating,
  recalculating,
  arrived,
  error,
}

class RouteInfo {
  final String id;
  final LatLng startLocation;
  final LatLng endLocation;
  final List<LatLng> polylinePoints;
  final int totalDistance; // in meters
  final int remainingDistance; // in meters
  final Duration estimatedTotalTime;
  final Duration estimatedTimeRemaining;
  final RouteType routeType;
  final TrafficCondition trafficCondition;
  final List<RouteInstruction> instructions;
  final double? fuelConsumption; // liters
  final double? tollCost; // currency
  final int safetyScore; // 0-100
  
  const RouteInfo({
    required this.id,
    required this.startLocation,
    required this.endLocation,
    required this.polylinePoints,
    required this.totalDistance,
    required this.remainingDistance,
    required this.estimatedTotalTime,
    required this.estimatedTimeRemaining,
    required this.routeType,
    required this.trafficCondition,
    this.instructions = const [],
    this.fuelConsumption,
    this.tollCost,
    this.safetyScore = 85,
  });
  
  RouteInfo copyWith({
    String? id,
    LatLng? startLocation,
    LatLng? endLocation,
    List<LatLng>? polylinePoints,
    int? totalDistance,
    int? remainingDistance,
    Duration? estimatedTotalTime,
    Duration? estimatedTimeRemaining,
    RouteType? routeType,
    TrafficCondition? trafficCondition,
    List<RouteInstruction>? instructions,
    double? fuelConsumption,
    double? tollCost,
    int? safetyScore,
  }) {
    return RouteInfo(
      id: id ?? this.id,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      totalDistance: totalDistance ?? this.totalDistance,
      remainingDistance: remainingDistance ?? this.remainingDistance,
      estimatedTotalTime: estimatedTotalTime ?? this.estimatedTotalTime,
      estimatedTimeRemaining: estimatedTimeRemaining ?? this.estimatedTimeRemaining,
      routeType: routeType ?? this.routeType,
      trafficCondition: trafficCondition ?? this.trafficCondition,
      instructions: instructions ?? this.instructions,
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
      tollCost: tollCost ?? this.tollCost,
      safetyScore: safetyScore ?? this.safetyScore,
    );
  }
  
  String get formattedDistance {
    if (remainingDistance < 1000) {
      return '$remainingDistanceم';
    } else {
      return '${(remainingDistance / 1000).toStringAsFixed(1)} كم';
    }
  }
  
  String get formattedTime {
    final hours = estimatedTimeRemaining.inHours;
    final minutes = estimatedTimeRemaining.inMinutes % 60;
    
    if (hours > 0) {
      return '$hoursس $minutesد';
    } else {
      return '$minutes دقيقة';
    }
  }
  
  String get routeTypeText {
    switch (routeType) {
      case RouteType.fastest:
        return 'الأسرع';
      case RouteType.shortest:
        return 'الأقصر';
      case RouteType.scenic:
        return 'المناظر الطبيعية';
      case RouteType.safest:
        return 'الأكثر أماناً';
      case RouteType.economical:
        return 'الاقتصادي';
    }
  }
  
  String get trafficConditionText {
    switch (trafficCondition) {
      case TrafficCondition.light:
        return 'حركة مرور خفيفة';
      case TrafficCondition.moderate:
        return 'حركة مرور متوسطة';
      case TrafficCondition.heavy:
        return 'حركة مرور كثيفة';
      case TrafficCondition.severe:
        return 'ازدحام شديد';
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startLocation': {
        'latitude': startLocation.latitude,
        'longitude': startLocation.longitude,
      },
      'endLocation': {
        'latitude': endLocation.latitude,
        'longitude': endLocation.longitude,
      },
      'polylinePoints': polylinePoints
          .map((point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              })
          .toList(),
      'totalDistance': totalDistance,
      'remainingDistance': remainingDistance,
      'estimatedTotalTime': estimatedTotalTime.inMinutes,
      'estimatedTimeRemaining': estimatedTimeRemaining.inMinutes,
      'routeType': routeType.toString().split('.').last,
      'trafficCondition': trafficCondition.toString().split('.').last,
      'instructions': instructions.map((i) => i.toJson()).toList(),
      'fuelConsumption': fuelConsumption,
      'tollCost': tollCost,
      'safetyScore': safetyScore,
    };
  }
  
  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      id: json['id'],
      startLocation: LatLng(
        json['startLocation']['latitude'],
        json['startLocation']['longitude'],
      ),
      endLocation: LatLng(
        json['endLocation']['latitude'],
        json['endLocation']['longitude'],
      ),
      polylinePoints: (json['polylinePoints'] as List)
          .map((point) => LatLng(point['latitude'], point['longitude']))
          .toList(),
      totalDistance: json['totalDistance'],
      remainingDistance: json['remainingDistance'],
      estimatedTotalTime: Duration(minutes: json['estimatedTotalTime']),
      estimatedTimeRemaining: Duration(minutes: json['estimatedTimeRemaining']),
      routeType: RouteType.values.firstWhere(
        (e) => e.toString().split('.').last == json['routeType'],
        orElse: () => RouteType.fastest,
      ),
      trafficCondition: TrafficCondition.values.firstWhere(
        (e) => e.toString().split('.').last == json['trafficCondition'],
        orElse: () => TrafficCondition.moderate,
      ),
      instructions: (json['instructions'] as List? ?? [])
          .map((i) => RouteInstruction.fromJson(i))
          .toList(),
      fuelConsumption: json['fuelConsumption']?.toDouble(),
      tollCost: json['tollCost']?.toDouble(),
      safetyScore: json['safetyScore'] ?? 85,
    );
  }
}

class RouteInstruction {
  final String text;
  final String maneuver;
  final LatLng location;
  final int distance; // meters to next instruction
  final Duration time; // time to next instruction
  final String? streetName;
  
  const RouteInstruction({
    required this.text,
    required this.maneuver,
    required this.location,
    required this.distance,
    required this.time,
    this.streetName,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'maneuver': maneuver,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'distance': distance,
      'time': time.inSeconds,
      'streetName': streetName,
    };
  }
  
  factory RouteInstruction.fromJson(Map<String, dynamic> json) {
    return RouteInstruction(
      text: json['text'],
      maneuver: json['maneuver'],
      location: LatLng(
        json['location']['latitude'],
        json['location']['longitude'],
      ),
      distance: json['distance'],
      time: Duration(seconds: json['time']),
      streetName: json['streetName'],
    );
  }
}

class NavigationState {
  final NavigationStatus status;
  final RouteInfo? route;
  final List<RouteInfo> alternativeRoutes;
  final String? destinationName;
  final String? errorMessage;
  final String? statusMessage;
  final bool hasRouteUpdate;
  
  const NavigationState({
    required this.status,
    this.route,
    this.alternativeRoutes = const [],
    this.destinationName,
    this.errorMessage,
    this.statusMessage,
    this.hasRouteUpdate = false,
  });
  
  // Factory constructors for different states
  factory NavigationState.idle() {
    return const NavigationState(status: NavigationStatus.idle);
  }
  
  factory NavigationState.calculating() {
    return const NavigationState(
      status: NavigationStatus.calculating,
      statusMessage: 'جاري حساب المسار...',
    );
  }
  
  factory NavigationState.navigating({
    required RouteInfo route,
    List<RouteInfo> alternativeRoutes = const [],
    String? destinationName,
    bool hasRouteUpdate = false,
  }) {
    return NavigationState(
      status: NavigationStatus.navigating,
      route: route,
      alternativeRoutes: alternativeRoutes,
      destinationName: destinationName,
      hasRouteUpdate: hasRouteUpdate,
    );
  }
  
  factory NavigationState.recalculating(String reason) {
    return NavigationState(
      status: NavigationStatus.recalculating,
      statusMessage: 'إعادة حساب المسار: $reason',
    );
  }
  
  factory NavigationState.arrived() {
    return const NavigationState(
      status: NavigationStatus.arrived,
      statusMessage: 'وصلت إلى وجهتك',
    );
  }
  
  factory NavigationState.error(String message) {
    return NavigationState(
      status: NavigationStatus.error,
      errorMessage: message,
    );
  }
  
  // Getters for convenience
  bool get isIdle => status == NavigationStatus.idle;
  bool get isCalculating => status == NavigationStatus.calculating;
  bool get isNavigating => status == NavigationStatus.navigating;
  bool get isRecalculating => status == NavigationStatus.recalculating;
  bool get hasArrived => status == NavigationStatus.arrived;
  bool get hasError => status == NavigationStatus.error;
  bool get isActive => isNavigating || isRecalculating;
  
  NavigationState copyWith({
    NavigationStatus? status,
    RouteInfo? route,
    List<RouteInfo>? alternativeRoutes,
    String? destinationName,
    String? errorMessage,
    String? statusMessage,
    bool? hasRouteUpdate,
  }) {
    return NavigationState(
      status: status ?? this.status,
      route: route ?? this.route,
      alternativeRoutes: alternativeRoutes ?? this.alternativeRoutes,
      destinationName: destinationName ?? this.destinationName,
      errorMessage: errorMessage ?? this.errorMessage,
      statusMessage: statusMessage ?? this.statusMessage,
      hasRouteUpdate: hasRouteUpdate ?? this.hasRouteUpdate,
    );
  }
}

class NavigationSettings {
  final bool enableVoiceGuidance;
  final bool enableAutoReroute;
  final bool avoidTolls;
  final bool avoidHighways;
  final bool avoidFerries;
  final RouteType preferredRouteType;
  final double rerouteThreshold; // meters
  final Duration recalculationInterval;
  final bool enableTrafficData;
  final bool enableAlternativeRoutes;
  
  const NavigationSettings({
    this.enableVoiceGuidance = true,
    this.enableAutoReroute = true,
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.avoidFerries = true,
    this.preferredRouteType = RouteType.fastest,
    this.rerouteThreshold = 100.0,
    this.recalculationInterval = const Duration(seconds: 30),
    this.enableTrafficData = true,
    this.enableAlternativeRoutes = true,
  });
  
  NavigationSettings copyWith({
    bool? enableVoiceGuidance,
    bool? enableAutoReroute,
    bool? avoidTolls,
    bool? avoidHighways,
    bool? avoidFerries,
    RouteType? preferredRouteType,
    double? rerouteThreshold,
    Duration? recalculationInterval,
    bool? enableTrafficData,
    bool? enableAlternativeRoutes,
  }) {
    return NavigationSettings(
      enableVoiceGuidance: enableVoiceGuidance ?? this.enableVoiceGuidance,
      enableAutoReroute: enableAutoReroute ?? this.enableAutoReroute,
      avoidTolls: avoidTolls ?? this.avoidTolls,
      avoidHighways: avoidHighways ?? this.avoidHighways,
      avoidFerries: avoidFerries ?? this.avoidFerries,
      preferredRouteType: preferredRouteType ?? this.preferredRouteType,
      rerouteThreshold: rerouteThreshold ?? this.rerouteThreshold,
      recalculationInterval: recalculationInterval ?? this.recalculationInterval,
      enableTrafficData: enableTrafficData ?? this.enableTrafficData,
      enableAlternativeRoutes: enableAlternativeRoutes ?? this.enableAlternativeRoutes,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'enableVoiceGuidance': enableVoiceGuidance,
      'enableAutoReroute': enableAutoReroute,
      'avoidTolls': avoidTolls,
      'avoidHighways': avoidHighways,
      'avoidFerries': avoidFerries,
      'preferredRouteType': preferredRouteType.toString().split('.').last,
      'rerouteThreshold': rerouteThreshold,
      'recalculationInterval': recalculationInterval.inSeconds,
      'enableTrafficData': enableTrafficData,
      'enableAlternativeRoutes': enableAlternativeRoutes,
    };
  }
  
  factory NavigationSettings.fromJson(Map<String, dynamic> json) {
    return NavigationSettings(
      enableVoiceGuidance: json['enableVoiceGuidance'] ?? true,
      enableAutoReroute: json['enableAutoReroute'] ?? true,
      avoidTolls: json['avoidTolls'] ?? false,
      avoidHighways: json['avoidHighways'] ?? false,
      avoidFerries: json['avoidFerries'] ?? true,
      preferredRouteType: RouteType.values.firstWhere(
        (e) => e.toString().split('.').last == json['preferredRouteType'],
        orElse: () => RouteType.fastest,
      ),
      rerouteThreshold: json['rerouteThreshold']?.toDouble() ?? 100.0,
      recalculationInterval: Duration(seconds: json['recalculationInterval'] ?? 30),
      enableTrafficData: json['enableTrafficData'] ?? true,
      enableAlternativeRoutes: json['enableAlternativeRoutes'] ?? true,
    );
  }
}

class RouteModel {
  final String id;
  final String name;
  final String startPoint;
  final String endPoint;
  final double distance;
  final Duration estimatedTime;
  final RouteType type;
  final int safetyScore;
  final double fuelConsumption;
  final List<LatLng> waypoints;

  const RouteModel({
    required this.id,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.distance,
    required this.estimatedTime,
    this.type = RouteType.fastest,
    this.safetyScore = 85,
    this.fuelConsumption = 0.0,
    this.waypoints = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'distance': distance,
      'estimatedTime': estimatedTime.inMinutes,
      'type': type.toString(),
      'safetyScore': safetyScore,
      'fuelConsumption': fuelConsumption,
      'waypoints': waypoints.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
    };
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      name: json['name'],
      startPoint: json['startPoint'],
      endPoint: json['endPoint'],
      distance: json['distance'].toDouble(),
      estimatedTime: Duration(minutes: json['estimatedTime']),
      type: RouteType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => RouteType.fastest,
      ),
      safetyScore: json['safetyScore'] ?? 85,
      fuelConsumption: json['fuelConsumption']?.toDouble() ?? 0.0,
      waypoints: (json['waypoints'] as List<dynamic>?)?.map((point) => 
        LatLng(point['latitude'], point['longitude'])
      ).toList() ?? [],
    );
  }
}