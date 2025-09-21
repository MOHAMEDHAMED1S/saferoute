import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class WeatherData extends Equatable {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final double windDirection;
  final double pressure;
  final double visibility;
  final WeatherCondition condition;
  final String description;
  final String icon;
  final DateTime timestamp;
  final String location;
  final double latitude;
  final double longitude;
  final double uvIndex;
  final double cloudCover;
  final double dewPoint;
  final double feelsLike;
  
  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.visibility,
    required this.condition,
    required this.description,
    required this.icon,
    required this.timestamp,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.uvIndex = 0.0,
    this.cloudCover = 0.0,
    this.dewPoint = 0.0,
    this.feelsLike = 0.0,
  });
  
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      windSpeed: (json['windSpeed'] ?? 0.0).toDouble(),
      windDirection: (json['windDirection'] ?? 0.0).toDouble(),
      pressure: (json['pressure'] ?? 0.0).toDouble(),
      visibility: (json['visibility'] ?? 10000.0).toDouble(),
      condition: WeatherCondition.fromString(json['condition'] ?? 'clear'),
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      location: json['location'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      uvIndex: (json['uvIndex'] ?? 0.0).toDouble(),
      cloudCover: (json['cloudCover'] ?? 0.0).toDouble(),
      dewPoint: (json['dewPoint'] ?? 0.0).toDouble(),
      feelsLike: (json['feelsLike'] ?? 0.0).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'pressure': pressure,
      'visibility': visibility,
      'condition': condition.toString(),
      'description': description,
      'icon': icon,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'uvIndex': uvIndex,
      'cloudCover': cloudCover,
      'dewPoint': dewPoint,
      'feelsLike': feelsLike,
    };
  }
  
  WeatherData copyWith({
    double? temperature,
    double? humidity,
    double? windSpeed,
    double? windDirection,
    double? pressure,
    double? visibility,
    WeatherCondition? condition,
    String? description,
    String? icon,
    DateTime? timestamp,
    String? location,
    double? latitude,
    double? longitude,
    double? uvIndex,
    double? cloudCover,
    double? dewPoint,
    double? feelsLike,
  }) {
    return WeatherData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      pressure: pressure ?? this.pressure,
      visibility: visibility ?? this.visibility,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      uvIndex: uvIndex ?? this.uvIndex,
      cloudCover: cloudCover ?? this.cloudCover,
      dewPoint: dewPoint ?? this.dewPoint,
      feelsLike: feelsLike ?? this.feelsLike,
    );
  }
  
  @override
  List<Object?> get props => [
    temperature,
    humidity,
    windSpeed,
    windDirection,
    pressure,
    visibility,
    condition,
    description,
    icon,
    timestamp,
    location,
    latitude,
    longitude,
    uvIndex,
    cloudCover,
    dewPoint,
    feelsLike,
  ];
  
  // Helper methods
  bool get isRaining => condition == WeatherCondition.rain || condition == WeatherCondition.thunderstorm;
  bool get isFoggy => condition == WeatherCondition.fog || visibility < 1000;
  bool get isCloudy => cloudCover > 50;
  bool get isWindy => windSpeed > 20; // km/h
  bool get isHot => temperature > 35;
  bool get isCold => temperature < 5;
  bool get isHumid => humidity > 80;
  bool get isDry => humidity < 30;
  bool get hasLowVisibility => visibility < 5000;
  bool get hasHighUV => uvIndex > 7;
  
  String get temperatureDisplay => '${temperature.round()}°C';
  String get humidityDisplay => '${humidity.round()}%';
  String get windSpeedDisplay => '${windSpeed.round()} كم/س';
  String get visibilityDisplay => '${(visibility / 1000).toStringAsFixed(1)} كم';
  String get pressureDisplay => '${pressure.round()} هكتوباسكال';
  String get uvIndexDisplay => uvIndex.toStringAsFixed(1);
  
  String get windDirectionText {
    if (windDirection >= 337.5 || windDirection < 22.5) return 'شمال';
    if (windDirection >= 22.5 && windDirection < 67.5) return 'شمال شرق';
    if (windDirection >= 67.5 && windDirection < 112.5) return 'شرق';
    if (windDirection >= 112.5 && windDirection < 157.5) return 'جنوب شرق';
    if (windDirection >= 157.5 && windDirection < 202.5) return 'جنوب';
    if (windDirection >= 202.5 && windDirection < 247.5) return 'جنوب غرب';
    if (windDirection >= 247.5 && windDirection < 292.5) return 'غرب';
    if (windDirection >= 292.5 && windDirection < 337.5) return 'شمال غرب';
    return 'غير محدد';
  }
  
  DrivingCondition get drivingCondition {
    if (isRaining && hasLowVisibility) return DrivingCondition.dangerous;
    if (isFoggy || hasLowVisibility) return DrivingCondition.poor;
    if (isRaining || isWindy) return DrivingCondition.caution;
    if (isHot || isCold) return DrivingCondition.moderate;
    return DrivingCondition.good;
  }
  
  List<String> get drivingRecommendations {
    List<String> recommendations = [];
    
    if (isRaining) {
      recommendations.add('قلل السرعة واترك مسافة أكبر');
      recommendations.add('استخدم المصابيح الأمامية');
    }
    
    if (isFoggy || hasLowVisibility) {
      recommendations.add('استخدم أضواء الضباب');
      recommendations.add('قد ببطء شديد');
      recommendations.add('تجنب التجاوز');
    }
    
    if (isWindy) {
      recommendations.add('احذر من الرياح الجانبية');
      recommendations.add('امسك المقود بقوة');
    }
    
    if (isHot) {
      recommendations.add('تأكد من تبريد المحرك');
      recommendations.add('اشرب الماء بانتظام');
    }
    
    if (isCold) {
      recommendations.add('احذر من الجليد على الطريق');
      recommendations.add('سخن المحرك قبل القيادة');
    }
    
    if (hasHighUV) {
      recommendations.add('استخدم النظارات الشمسية');
      recommendations.add('تأكد من واقي الشمس');
    }
    
    return recommendations;
  }
}

class WeatherForecast extends Equatable {
  final List<WeatherData> hourlyForecast;
  final List<WeatherData> dailyForecast;
  final DateTime lastUpdated;
  
  const WeatherForecast({
    required this.hourlyForecast,
    required this.dailyForecast,
    required this.lastUpdated,
  });
  
  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      hourlyForecast: (json['hourlyForecast'] as List<dynamic>? ?? [])
          .map((item) => WeatherData.fromJson(item as Map<String, dynamic>))
          .toList(),
      dailyForecast: (json['dailyForecast'] as List<dynamic>? ?? [])
          .map((item) => WeatherData.fromJson(item as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        json['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'hourlyForecast': hourlyForecast.map((item) => item.toJson()).toList(),
      'dailyForecast': dailyForecast.map((item) => item.toJson()).toList(),
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }
  
  @override
  List<Object?> get props => [hourlyForecast, dailyForecast, lastUpdated];
  
  // Helper methods
  WeatherData? get nextHourWeather {
    if (hourlyForecast.isEmpty) return null;
    return hourlyForecast.first;
  }
  
  WeatherData? get tomorrowWeather {
    if (dailyForecast.isEmpty) return null;
    return dailyForecast.first;
  }
  
  bool get willRainSoon {
    return hourlyForecast.take(6).any((weather) => weather.isRaining);
  }
  
  bool get willBeFoggySoon {
    return hourlyForecast.take(6).any((weather) => weather.isFoggy);
  }
  
  List<WeatherData> getWeatherForRoute(Duration routeDuration) {
    final endTime = DateTime.now().add(routeDuration);
    return hourlyForecast.where((weather) => 
      weather.timestamp.isBefore(endTime)
    ).toList();
  }
}

enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  overcast,
  rain,
  heavyRain,
  thunderstorm,
  snow,
  heavySnow,
  sleet,
  fog,
  mist,
  haze,
  dust,
  sand,
  wind,
  tornado,
  hurricane,
  unknown;
  
  static WeatherCondition fromString(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return WeatherCondition.clear;
      case 'partly_cloudy':
      case 'partly cloudy':
        return WeatherCondition.partlyCloudy;
      case 'cloudy':
        return WeatherCondition.cloudy;
      case 'overcast':
        return WeatherCondition.overcast;
      case 'rain':
      case 'light_rain':
        return WeatherCondition.rain;
      case 'heavy_rain':
        return WeatherCondition.heavyRain;
      case 'thunderstorm':
      case 'storm':
        return WeatherCondition.thunderstorm;
      case 'snow':
      case 'light_snow':
        return WeatherCondition.snow;
      case 'heavy_snow':
        return WeatherCondition.heavySnow;
      case 'sleet':
        return WeatherCondition.sleet;
      case 'fog':
        return WeatherCondition.fog;
      case 'mist':
        return WeatherCondition.mist;
      case 'haze':
        return WeatherCondition.haze;
      case 'dust':
        return WeatherCondition.dust;
      case 'sand':
        return WeatherCondition.sand;
      case 'wind':
      case 'windy':
        return WeatherCondition.wind;
      case 'tornado':
        return WeatherCondition.tornado;
      case 'hurricane':
        return WeatherCondition.hurricane;
      default:
        return WeatherCondition.unknown;
    }
  }
  
  String get arabicName {
    switch (this) {
      case WeatherCondition.clear:
        return 'صافي';
      case WeatherCondition.partlyCloudy:
        return 'غائم جزئياً';
      case WeatherCondition.cloudy:
        return 'غائم';
      case WeatherCondition.overcast:
        return 'ملبد بالغيوم';
      case WeatherCondition.rain:
        return 'مطر';
      case WeatherCondition.heavyRain:
        return 'مطر غزير';
      case WeatherCondition.thunderstorm:
        return 'عاصفة رعدية';
      case WeatherCondition.snow:
        return 'ثلج';
      case WeatherCondition.heavySnow:
        return 'ثلج كثيف';
      case WeatherCondition.sleet:
        return 'برد';
      case WeatherCondition.fog:
        return 'ضباب';
      case WeatherCondition.mist:
        return 'ضباب خفيف';
      case WeatherCondition.haze:
        return 'غبار';
      case WeatherCondition.dust:
        return 'عاصفة ترابية';
      case WeatherCondition.sand:
        return 'عاصفة رملية';
      case WeatherCondition.wind:
        return 'رياح قوية';
      case WeatherCondition.tornado:
        return 'إعصار';
      case WeatherCondition.hurricane:
        return 'إعصار مداري';
      case WeatherCondition.unknown:
        return 'غير محدد';
    }
  }
  
  String get iconName {
    switch (this) {
      case WeatherCondition.clear:
        return 'sunny';
      case WeatherCondition.partlyCloudy:
        return 'partly_cloudy';
      case WeatherCondition.cloudy:
        return 'cloudy';
      case WeatherCondition.overcast:
        return 'overcast';
      case WeatherCondition.rain:
        return 'rainy';
      case WeatherCondition.heavyRain:
        return 'heavy_rain';
      case WeatherCondition.thunderstorm:
        return 'thunderstorm';
      case WeatherCondition.snow:
        return 'snowy';
      case WeatherCondition.heavySnow:
        return 'heavy_snow';
      case WeatherCondition.sleet:
        return 'sleet';
      case WeatherCondition.fog:
        return 'foggy';
      case WeatherCondition.mist:
        return 'misty';
      case WeatherCondition.haze:
        return 'hazy';
      case WeatherCondition.dust:
        return 'dusty';
      case WeatherCondition.sand:
        return 'sandy';
      case WeatherCondition.wind:
        return 'windy';
      case WeatherCondition.tornado:
        return 'tornado';
      case WeatherCondition.hurricane:
        return 'hurricane';
      case WeatherCondition.unknown:
        return 'unknown';
    }
  }
}

enum DrivingCondition {
  excellent,
  good,
  moderate,
  caution,
  poor,
  dangerous;
  
  String get arabicName {
    switch (this) {
      case DrivingCondition.excellent:
        return 'ممتازة';
      case DrivingCondition.good:
        return 'جيدة';
      case DrivingCondition.moderate:
        return 'متوسطة';
      case DrivingCondition.caution:
        return 'احذر';
      case DrivingCondition.poor:
        return 'سيئة';
      case DrivingCondition.dangerous:
        return 'خطيرة';
    }
  }
  
  Color get color {
    switch (this) {
      case DrivingCondition.excellent:
        return const Color(0xFF4CAF50);
      case DrivingCondition.good:
        return const Color(0xFF8BC34A);
      case DrivingCondition.moderate:
        return const Color(0xFFFFEB3B);
      case DrivingCondition.caution:
        return const Color(0xFFFF9800);
      case DrivingCondition.poor:
        return const Color(0xFFFF5722);
      case DrivingCondition.dangerous:
        return const Color(0xFFF44336);
    }
  }
}