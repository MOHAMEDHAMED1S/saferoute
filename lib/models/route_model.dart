// Define Position class for Mapbox compatibility
class Position {
  final double latitude;
  final double longitude;
  
  const Position({required this.latitude, required this.longitude});
  
  @override
  String toString() => 'Position($latitude, $longitude)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }
  
  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

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
  final Position startLocation;
  final Position endLocation;
  final List<Position> polylinePoints;
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
    required this.instructions,
    this.fuelConsumption,
    this.tollCost,
    required this.safetyScore,
  });

  // Convert to map for Firebase storage
  Map<String, dynamic> toMap() {
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
      'polylinePoints': polylinePoints.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
      'totalDistance': totalDistance,
      'remainingDistance': remainingDistance,
      'estimatedTotalTime': estimatedTotalTime.inMilliseconds,
      'estimatedTimeRemaining': estimatedTimeRemaining.inMilliseconds,
      'routeType': routeType.name,
      'trafficCondition': trafficCondition.name,
      'instructions': instructions.map((instruction) => instruction.toMap()).toList(),
      'fuelConsumption': fuelConsumption,
      'tollCost': tollCost,
      'safetyScore': safetyScore,
    };
  }

  // Create from map (Firebase data)
  factory RouteInfo.fromMap(Map<String, dynamic> map) {
    return RouteInfo(
      id: map['id'] ?? '',
      startLocation: Position(
        latitude: map['startLocation']['latitude']?.toDouble() ?? 0.0,
        longitude: map['startLocation']['longitude']?.toDouble() ?? 0.0,
      ),
      endLocation: Position(
        latitude: map['endLocation']['latitude']?.toDouble() ?? 0.0,
        longitude: map['endLocation']['longitude']?.toDouble() ?? 0.0,
      ),
      polylinePoints: (map['polylinePoints'] as List<dynamic>?)
          ?.map((point) => Position(
                latitude: point['latitude']?.toDouble() ?? 0.0,
                longitude: point['longitude']?.toDouble() ?? 0.0,
              ))
          .toList() ?? [],
      totalDistance: map['totalDistance']?.toInt() ?? 0,
      remainingDistance: map['remainingDistance']?.toInt() ?? 0,
      estimatedTotalTime: Duration(milliseconds: map['estimatedTotalTime']?.toInt() ?? 0),
      estimatedTimeRemaining: Duration(milliseconds: map['estimatedTimeRemaining']?.toInt() ?? 0),
      routeType: RouteType.values.firstWhere(
        (type) => type.name == map['routeType'],
        orElse: () => RouteType.fastest,
      ),
      trafficCondition: TrafficCondition.values.firstWhere(
        (condition) => condition.name == map['trafficCondition'],
        orElse: () => TrafficCondition.moderate,
      ),
      instructions: (map['instructions'] as List<dynamic>?)
          ?.map((instruction) => RouteInstruction.fromMap(instruction))
          .toList() ?? [],
      fuelConsumption: map['fuelConsumption']?.toDouble(),
      tollCost: map['tollCost']?.toDouble(),
      safetyScore: map['safetyScore']?.toInt() ?? 0,
    );
  }

  // Copy with method
  RouteInfo copyWith({
    String? id,
    Position? startLocation,
    Position? endLocation,
    List<Position>? polylinePoints,
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
}

enum ManeuverType {
  start,
  straight,
  turnLeft,
  turnRight,
  turnSlightLeft,
  turnSlightRight,
  turnSharpLeft,
  turnSharpRight,
  uturn,
  merge,
  exit,
  arrive,
  roundabout,
}

class RouteInstruction {
  final String text;
  final String maneuver;
  final Position location;
  final int distance; // meters to this instruction
  final Duration time; // time to reach this instruction
  final String instruction;
  final Duration timeToInstruction;
  final ManeuverType maneuverType;
  final String? streetName;
  final String? exitNumber;
  final int? roundaboutExit;

  const RouteInstruction({
    required this.text,
    required this.maneuver,
    required this.location,
    required this.distance,
    required this.time,
    required this.instruction,
    required this.timeToInstruction,
    required this.maneuverType,
    this.streetName,
    this.exitNumber,
    this.roundaboutExit,
  });

  // Convert to map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'maneuver': maneuver,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'distance': distance,
      'time': time.inMilliseconds,
      'instruction': instruction,
      'timeToInstruction': timeToInstruction.inMilliseconds,
      'maneuverType': maneuverType.name,
      'streetName': streetName,
      'exitNumber': exitNumber,
      'roundaboutExit': roundaboutExit,
    };
  }

  // Create from map (Firebase data)
  factory RouteInstruction.fromMap(Map<String, dynamic> map) {
    return RouteInstruction(
      text: map['text'] ?? '',
      maneuver: map['maneuver'] ?? '',
      location: Position(
        latitude: map['location']['latitude']?.toDouble() ?? 0.0,
        longitude: map['location']['longitude']?.toDouble() ?? 0.0,
      ),
      distance: map['distance']?.toInt() ?? 0,
      time: Duration(milliseconds: map['time']?.toInt() ?? 0),
      instruction: map['instruction'] ?? '',
      timeToInstruction: Duration(milliseconds: map['timeToInstruction']?.toInt() ?? 0),
      maneuverType: ManeuverType.values.firstWhere(
        (type) => type.name == map['maneuverType'],
        orElse: () => ManeuverType.straight,
      ),
      streetName: map['streetName'],
      exitNumber: map['exitNumber'],
      roundaboutExit: map['roundaboutExit']?.toInt(),
    );
  }
}

// Route model for saved routes
class RouteModel {
  final String id;
  final String name;
  final Position? startLocation;
  final Position? endLocation;
  final List<Position> waypoints;
  final RouteType routeType;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final bool isFavorite;
  final String? description;
  final List<String> tags;

  const RouteModel({
    required this.id,
    required this.name,
    this.startLocation,
    this.endLocation,
    required this.waypoints,
    required this.routeType,
    required this.createdAt,
    this.lastUsed,
    this.isFavorite = false,
    this.description,
    this.tags = const [],
  });

  // Convert to map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startLocation': startLocation != null ? {
        'latitude': startLocation!.latitude,
        'longitude': startLocation!.longitude,
      } : null,
      'endLocation': endLocation != null ? {
        'latitude': endLocation!.latitude,
        'longitude': endLocation!.longitude,
      } : null,
      'waypoints': waypoints.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
      'routeType': routeType.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUsed': lastUsed?.millisecondsSinceEpoch,
      'isFavorite': isFavorite,
      'description': description,
      'tags': tags,
    };
  }

  // Create from map (Firebase data)
  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      startLocation: map['startLocation'] != null ? Position(
        latitude: map['startLocation']['latitude']?.toDouble() ?? 0.0,
        longitude: map['startLocation']['longitude']?.toDouble() ?? 0.0,
      ) : null,
      endLocation: map['endLocation'] != null ? Position(
        latitude: map['endLocation']['latitude']?.toDouble() ?? 0.0,
        longitude: map['endLocation']['longitude']?.toDouble() ?? 0.0,
      ) : null,
      waypoints: (map['waypoints'] as List<dynamic>?)
          ?.map((point) => Position(
                latitude: point['latitude']?.toDouble() ?? 0.0,
                longitude: point['longitude']?.toDouble() ?? 0.0,
              ))
          .toList() ?? [],
      routeType: RouteType.values.firstWhere(
        (type) => type.name == map['routeType'],
        orElse: () => RouteType.fastest,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastUsed: map['lastUsed'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUsed'])
          : null,
      isFavorite: map['isFavorite'] ?? false,
      description: map['description'],
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // Copy with method
  RouteModel copyWith({
    String? id,
    String? name,
    Position? startLocation,
    Position? endLocation,
    List<Position>? waypoints,
    RouteType? routeType,
    DateTime? createdAt,
    DateTime? lastUsed,
    bool? isFavorite,
    String? description,
    List<String>? tags,
  }) {
    return RouteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      waypoints: waypoints ?? this.waypoints,
      routeType: routeType ?? this.routeType,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
      tags: tags ?? this.tags,
    );
  }
}