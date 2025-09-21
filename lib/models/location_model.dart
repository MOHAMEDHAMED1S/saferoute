import 'dart:math' as math;

class LocationModel {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final DateTime timestamp;
  final String? address;
  final String? city;
  final String? country;
  final String? postalCode;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.heading,
    this.speed,
    required this.timestamp,
    this.address,
    this.city,
    this.country,
    this.postalCode,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: json['altitude'] != null ? (json['altitude'] as num).toDouble() : null,
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'heading': heading,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
      'city': city,
      'country': country,
      'postalCode': postalCode,
    };
  }

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    double? heading,
    double? speed,
    DateTime? timestamp,
    String? address,
    String? city,
    String? country,
    String? postalCode,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  double distanceTo(LocationModel other) {
    const double earthRadius = 6371000; // meters
    double lat1Rad = latitude * (math.pi / 180);
    double lat2Rad = other.latitude * (math.pi / 180);
    double deltaLatRad = (other.latitude - latitude) * (math.pi / 180);
    double deltaLngRad = (other.longitude - longitude) * (math.pi / 180);

    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, timestamp);

  @override
  String toString() {
    return 'LocationModel(latitude: $latitude, longitude: $longitude, altitude: $altitude, accuracy: $accuracy, heading: $heading, speed: $speed, timestamp: $timestamp, address: $address, city: $city, country: $country, postalCode: $postalCode)';
  }
}

class LocationBounds {
  final double northEast;
  final double southWest;
  final double northWest;
  final double southEast;

  LocationBounds({
    required this.northEast,
    required this.southWest,
    required this.northWest,
    required this.southEast,
  });

  bool contains(LocationModel location) {
    return location.latitude <= northEast &&
        location.latitude >= southWest &&
        location.longitude >= northWest &&
        location.longitude <= southEast;
  }
}

extension LocationModelExtensions on LocationModel {
  bool get hasAccuracy => accuracy != null;
  bool get hasAltitude => altitude != null;
  bool get hasHeading => heading != null;
  bool get hasSpeed => speed != null;
  bool get hasAddress => address != null && address!.isNotEmpty;
  
  String get coordinatesString => '$latitude, $longitude';
  
  bool isWithinRadius(LocationModel center, double radiusInMeters) {
    return distanceTo(center) <= radiusInMeters;
  }
}