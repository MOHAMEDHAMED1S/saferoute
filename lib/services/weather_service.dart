import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  final StreamController<WeatherData> _weatherController =
      StreamController<WeatherData>.broadcast();
  final StreamController<WeatherForecast> _forecastController =
      StreamController<WeatherForecast>.broadcast();

  Stream<WeatherData> get weatherStream => _weatherController.stream;
  Stream<WeatherForecast> get forecastStream => _forecastController.stream;

  WeatherData? _currentWeather;
  WeatherForecast? _currentForecast;

  Timer? _updateTimer;
  bool _isInitialized = false;

  // API configuration (using OpenWeatherMap as example)
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey = String.fromEnvironment(
    'WEATHER_API_KEY',
    defaultValue: '',
  ); // Use environment variable for security

  WeatherData? get currentWeather => _currentWeather;
  WeatherForecast? get currentForecast => _currentForecast;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadCachedWeather();
    _startPeriodicUpdates();

    _isInitialized = true;
  }

  void dispose() {
    _updateTimer?.cancel();
    _weatherController.close();
    _forecastController.close();
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      if (_currentWeather != null) {
        updateWeather(_currentWeather!.latitude, _currentWeather!.longitude);
      }
    });
  }

  Future<void> _loadCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weatherJson = prefs.getString('cached_weather');
      final forecastJson = prefs.getString('cached_forecast');

      if (weatherJson != null) {
        final weatherData = json.decode(weatherJson);
        _currentWeather = WeatherData.fromJson(weatherData);
        _weatherController.add(_currentWeather!);
      }

      if (forecastJson != null) {
        final forecastData = json.decode(forecastJson);
        _currentForecast = WeatherForecast.fromJson(forecastData);
        _forecastController.add(_currentForecast!);
      }
    } catch (e) {
      print('Error loading cached weather: $e');
    }
  }

  Future<void> _cacheWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_currentWeather != null) {
        await prefs.setString(
          'cached_weather',
          json.encode(_currentWeather!.toJson()),
        );
      }

      if (_currentForecast != null) {
        await prefs.setString(
          'cached_forecast',
          json.encode(_currentForecast!.toJson()),
        );
      }
    } catch (e) {
      print('Error caching weather: $e');
    }
  }

  Future<WeatherData> getCurrentWeather(
    double latitude,
    double longitude,
  ) async {
    try {
      // In a real implementation, you would use an actual weather API
      // For demo purposes, we'll simulate weather data
      final weather = await _fetchWeatherFromAPI(latitude, longitude);

      _currentWeather = weather;
      _weatherController.add(weather);
      await _cacheWeather();

      return weather;
    } catch (e) {
      print('Error fetching weather: $e');

      // Return cached weather or default weather
      if (_currentWeather != null) {
        return _currentWeather!;
      } else {
        return _generateDefaultWeather(latitude, longitude);
      }
    }
  }

  Future<WeatherForecast> getWeatherForecast(
    double latitude,
    double longitude,
  ) async {
    try {
      final forecast = await _fetchForecastFromAPI(latitude, longitude);

      _currentForecast = forecast;
      _forecastController.add(forecast);
      await _cacheWeather();

      return forecast;
    } catch (e) {
      print('Error fetching forecast: $e');

      // Return cached forecast or default forecast
      if (_currentForecast != null) {
        return _currentForecast!;
      } else {
        return _generateDefaultForecast(latitude, longitude);
      }
    }
  }

  Future<void> updateWeather(double latitude, double longitude) async {
    await getCurrentWeather(latitude, longitude);
    await getWeatherForecast(latitude, longitude);
  }

  // Simulated API calls (replace with actual API implementation)
  Future<WeatherData> _fetchWeatherFromAPI(
    double latitude,
    double longitude,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // For demo purposes, generate realistic weather data based on location and time
    return _generateRealisticWeather(latitude, longitude);
  }

  Future<WeatherForecast> _fetchForecastFromAPI(
    double latitude,
    double longitude,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Generate forecast data
    final hourlyForecast = <WeatherData>[];
    final dailyForecast = <WeatherData>[];

    final now = DateTime.now();

    // Generate 24 hours of hourly forecast
    for (int i = 1; i <= 24; i++) {
      final forecastTime = now.add(Duration(hours: i));
      hourlyForecast.add(
        _generateRealisticWeather(
          latitude,
          longitude,
          timestamp: forecastTime,
          variation: i * 0.1,
        ),
      );
    }

    // Generate 7 days of daily forecast
    for (int i = 1; i <= 7; i++) {
      final forecastTime = now.add(Duration(days: i));
      dailyForecast.add(
        _generateRealisticWeather(
          latitude,
          longitude,
          timestamp: forecastTime,
          variation: i * 0.2,
        ),
      );
    }

    return WeatherForecast(
      hourlyForecast: hourlyForecast,
      dailyForecast: dailyForecast,
      lastUpdated: now,
    );
  }

  WeatherData _generateRealisticWeather(
    double latitude,
    double longitude, {
    DateTime? timestamp,
    double variation = 0.0,
  }) {
    final now = timestamp ?? DateTime.now();
    final random = Random(now.millisecondsSinceEpoch);

    // Base temperature calculation based on latitude and season
    double baseTemp = _calculateBaseTemperature(latitude, now);
    baseTemp += (random.nextDouble() - 0.5) * 10 * (1 + variation);

    // Time of day temperature variation
    final hour = now.hour;
    double timeVariation = 0;
    if (hour >= 6 && hour <= 18) {
      // Daytime - warmer
      timeVariation = 5 + (random.nextDouble() * 5);
    } else {
      // Nighttime - cooler
      timeVariation = -(2 + (random.nextDouble() * 3));
    }

    final temperature = baseTemp + timeVariation;

    // Generate other weather parameters
    final humidity = 30 + random.nextDouble() * 60;
    final windSpeed = random.nextDouble() * 30;
    final windDirection = random.nextDouble() * 360;
    final pressure = 1000 + random.nextDouble() * 50;
    final visibility = 5000 + random.nextDouble() * 15000;
    final uvIndex = _calculateUVIndex(latitude, now);
    final cloudCover = random.nextDouble() * 100;

    // Determine weather condition based on parameters
    WeatherCondition condition = _determineWeatherCondition(
      temperature,
      humidity,
      windSpeed,
      cloudCover,
      random,
    );

    // Adjust visibility based on condition
    double adjustedVisibility = visibility;
    if (condition == WeatherCondition.fog ||
        condition == WeatherCondition.mist) {
      adjustedVisibility = 500 + random.nextDouble() * 2000;
    } else if (condition == WeatherCondition.rain ||
        condition == WeatherCondition.heavyRain) {
      adjustedVisibility = 2000 + random.nextDouble() * 8000;
    }

    return WeatherData(
      temperature: temperature,
      humidity: humidity,
      windSpeed: windSpeed,
      windDirection: windDirection,
      pressure: pressure,
      visibility: adjustedVisibility,
      condition: condition,
      description: condition.arabicName,
      icon: condition.iconName,
      timestamp: now,
      location: _getLocationName(latitude, longitude),
      latitude: latitude,
      longitude: longitude,
      uvIndex: uvIndex,
      cloudCover: cloudCover,
      dewPoint: temperature - ((100 - humidity) / 5),
      feelsLike: _calculateFeelsLike(temperature, humidity, windSpeed),
    );
  }

  double _calculateBaseTemperature(double latitude, DateTime date) {
    // Simplified temperature calculation based on latitude and season
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final seasonalVariation = 15 * cos((dayOfYear - 172) * 2 * pi / 365);

    // Temperature decreases with latitude
    final latitudeEffect = 30 - (latitude.abs() * 0.6);

    return latitudeEffect + seasonalVariation;
  }

  double _calculateUVIndex(double latitude, DateTime date) {
    final hour = date.hour;
    if (hour < 6 || hour > 18) return 0.0;

    // Peak UV at noon, varies by latitude
    final timeFromNoon = (hour - 12).abs();
    final timeEffect = max(0.0, 1.0 - (timeFromNoon / 6.0));
    final latitudeEffect = max(0.0, 1.0 - (latitude.abs() / 90.0));

    return 11.0 * timeEffect * latitudeEffect;
  }

  double _calculateFeelsLike(
    double temperature,
    double humidity,
    double windSpeed,
  ) {
    // Simplified heat index calculation
    if (temperature > 26) {
      // Heat index for hot weather
      return temperature + (humidity - 40) * 0.1;
    } else if (temperature < 10) {
      // Wind chill for cold weather
      return temperature - (windSpeed * 0.2);
    } else {
      return temperature;
    }
  }

  WeatherCondition _determineWeatherCondition(
    double temperature,
    double humidity,
    double windSpeed,
    double cloudCover,
    Random random,
  ) {
    // Determine weather condition based on parameters
    if (humidity > 90 && temperature > 0) {
      if (random.nextDouble() < 0.3) return WeatherCondition.fog;
      if (random.nextDouble() < 0.5) return WeatherCondition.mist;
    }

    if (cloudCover > 80) {
      if (humidity > 80 && random.nextDouble() < 0.4) {
        return random.nextDouble() < 0.7
            ? WeatherCondition.rain
            : WeatherCondition.heavyRain;
      }
      if (random.nextDouble() < 0.2) return WeatherCondition.thunderstorm;
      return WeatherCondition.overcast;
    } else if (cloudCover > 50) {
      if (humidity > 70 && random.nextDouble() < 0.2) {
        return WeatherCondition.rain;
      }
      return WeatherCondition.cloudy;
    } else if (cloudCover > 20) {
      return WeatherCondition.partlyCloudy;
    } else {
      if (windSpeed > 25) return WeatherCondition.wind;
      return WeatherCondition.clear;
    }
  }

  String _getLocationName(double latitude, double longitude) {
    // Simplified location naming (in a real app, use reverse geocoding)
    if (latitude > 20 && latitude < 35 && longitude > 30 && longitude < 60) {
      return 'المملكة العربية السعودية';
    } else if (latitude > 22 &&
        latitude < 26 &&
        longitude > 50 &&
        longitude < 57) {
      return 'دولة الإمارات العربية المتحدة';
    } else if (latitude > 25 &&
        latitude < 30 &&
        longitude > 46 &&
        longitude < 49) {
      return 'دولة الكويت';
    } else {
      return 'موقع غير محدد';
    }
  }

  WeatherData _generateDefaultWeather(double latitude, double longitude) {
    return WeatherData(
      temperature: 25.0,
      humidity: 50.0,
      windSpeed: 10.0,
      windDirection: 180.0,
      pressure: 1013.25,
      visibility: 10000.0,
      condition: WeatherCondition.clear,
      description: 'صافي',
      icon: 'sunny',
      timestamp: DateTime.now(),
      location: _getLocationName(latitude, longitude),
      latitude: latitude,
      longitude: longitude,
      uvIndex: 5.0,
      cloudCover: 10.0,
      dewPoint: 15.0,
      feelsLike: 25.0,
    );
  }

  WeatherForecast _generateDefaultForecast(double latitude, double longitude) {
    final now = DateTime.now();
    final hourlyForecast = <WeatherData>[];
    final dailyForecast = <WeatherData>[];

    // Generate simple forecast
    for (int i = 1; i <= 24; i++) {
      hourlyForecast.add(_generateDefaultWeather(latitude, longitude));
    }

    for (int i = 1; i <= 7; i++) {
      dailyForecast.add(_generateDefaultWeather(latitude, longitude));
    }

    return WeatherForecast(
      hourlyForecast: hourlyForecast,
      dailyForecast: dailyForecast,
      lastUpdated: now,
    );
  }

  // Utility methods
  bool isWeatherSuitableForDriving(WeatherData weather) {
    return weather.drivingCondition != DrivingCondition.dangerous &&
        weather.drivingCondition != DrivingCondition.poor;
  }

  List<String> getWeatherWarnings(WeatherData weather) {
    List<String> warnings = [];

    if (weather.drivingCondition == DrivingCondition.dangerous) {
      warnings.add('ظروف قيادة خطيرة - تجنب القيادة إن أمكن');
    } else if (weather.drivingCondition == DrivingCondition.poor) {
      warnings.add('ظروف قيادة سيئة - قد بحذر شديد');
    } else if (weather.drivingCondition == DrivingCondition.caution) {
      warnings.add('ظروف قيادة تتطلب الحذر');
    }

    if (weather.hasLowVisibility) {
      warnings.add('رؤية منخفضة - استخدم الأضواء');
    }

    if (weather.isWindy) {
      warnings.add('رياح قوية - احذر من الرياح الجانبية');
    }

    if (weather.hasHighUV) {
      warnings.add('أشعة فوق بنفسجية عالية - استخدم النظارات الشمسية');
    }

    return warnings;
  }

  String getWeatherSummary(WeatherData weather) {
    return '${weather.condition.arabicName} - ${weather.temperatureDisplay}';
  }

  Duration getRecommendedUpdateInterval(WeatherData weather) {
    if (weather.drivingCondition == DrivingCondition.dangerous ||
        weather.drivingCondition == DrivingCondition.poor) {
      return const Duration(minutes: 5);
    } else if (weather.drivingCondition == DrivingCondition.caution) {
      return const Duration(minutes: 10);
    } else {
      return const Duration(minutes: 15);
    }
  }

  // تنسيق الوقت بنظام 12 ساعة
  String formatTimeIn12Hour(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  // تحويل درجة الحرارة إلى نص مع الوحدة
  String formatTemperature(double temp) {
    return '${temp.round()}°م';
  }
}