import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/warning_model.dart';
import '../models/weather_model.dart';

// Machine Learning Service for SafeRoute
class MLService {
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();
  
  late SharedPreferences _prefs;
  
  // Stream controllers for ML insights
  final StreamController<DrivingPattern> _drivingPatternController = StreamController<DrivingPattern>.broadcast();
  final StreamController<List<SmartRecommendation>> _recommendationsController = StreamController<List<SmartRecommendation>>.broadcast();
  final StreamController<RiskAssessment> _riskAssessmentController = StreamController<RiskAssessment>.broadcast();
  final StreamController<PerformanceMetrics> _performanceController = StreamController<PerformanceMetrics>.broadcast();
  
  // Getters for streams
  Stream<DrivingPattern> get drivingPatternStream => _drivingPatternController.stream;
  Stream<List<SmartRecommendation>> get recommendationsStream => _recommendationsController.stream;
  Stream<RiskAssessment> get riskAssessmentStream => _riskAssessmentController.stream;
  Stream<PerformanceMetrics> get performanceStream => _performanceController.stream;
  
  // ML Models and Data
  final List<DrivingSession> _drivingSessions = [];
  final List<RouteData> _routeHistory = [];
  final List<WeatherDrivingData> _weatherDrivingData = [];
  
  // Current analysis data
  DrivingPattern? _currentPattern;
  List<SmartRecommendation> _currentRecommendations = [];
  RiskAssessment? _currentRiskAssessment;
  PerformanceMetrics? _currentPerformance;
  
  // ML Configuration
  static const int _maxSessionHistory = 100;
  static const int _analysisIntervalMinutes = 5;
  
  Timer? _analysisTimer;
  bool _isInitialized = false;
  
  // Initialize ML Service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadHistoricalData();
      _startPeriodicAnalysis();
      _isInitialized = true;
      
      debugPrint('ML Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing ML Service: $e');
    }
  }
  
  // Load historical driving data
  Future<void> _loadHistoricalData() async {
    try {
      // Load driving sessions
      final sessionsJson = _prefs.getStringList('driving_sessions') ?? [];
      _drivingSessions.clear();
      for (final sessionStr in sessionsJson) {
        final sessionData = jsonDecode(sessionStr);
        _drivingSessions.add(DrivingSession.fromJson(sessionData));
      }
      
      // Load route history
      final routesJson = _prefs.getStringList('route_history') ?? [];
      _routeHistory.clear();
      for (final routeStr in routesJson) {
        final routeData = jsonDecode(routeStr);
        _routeHistory.add(RouteData.fromJson(routeData));
      }
      
      // Load weather driving data
      final weatherJson = _prefs.getStringList('weather_driving_data') ?? [];
      _weatherDrivingData.clear();
      for (final weatherStr in weatherJson) {
        final weatherData = jsonDecode(weatherStr);
        _weatherDrivingData.add(WeatherDrivingData.fromJson(weatherData));
      }
      
      debugPrint('Loaded ${_drivingSessions.length} driving sessions');
    } catch (e) {
      debugPrint('Error loading historical data: $e');
    }
  }
  
  // Save historical data
  Future<void> _saveHistoricalData() async {
    try {
      // Save driving sessions (keep only recent ones)
      final recentSessions = _drivingSessions.take(_maxSessionHistory).toList();
      final sessionsJson = recentSessions.map((session) => jsonEncode(session.toJson())).toList();
      await _prefs.setStringList('driving_sessions', sessionsJson);
      
      // Save route history
      final recentRoutes = _routeHistory.take(_maxSessionHistory).toList();
      final routesJson = recentRoutes.map((route) => jsonEncode(route.toJson())).toList();
      await _prefs.setStringList('route_history', routesJson);
      
      // Save weather driving data
      final recentWeatherData = _weatherDrivingData.take(_maxSessionHistory).toList();
      final weatherJson = recentWeatherData.map((weather) => jsonEncode(weather.toJson())).toList();
      await _prefs.setStringList('weather_driving_data', weatherJson);
    } catch (e) {
      debugPrint('Error saving historical data: $e');
    }
  }
  
  // Start periodic ML analysis
  void _startPeriodicAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(
      Duration(minutes: _analysisIntervalMinutes),
      (_) => _performMLAnalysis(),
    );
  }
  
  // Record driving session data
  Future<void> recordDrivingSession({
    required double averageSpeed,
    required double maxSpeed,
    required double distance,
    required Duration duration,
    required int hardBrakingCount,
    required int rapidAccelerationCount,
    required int sharpTurnCount,
    required List<DrivingWarning> warnings,
    required WeatherData? weather,
    required String routeType,
  }) async {
    final session = DrivingSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      averageSpeed: averageSpeed,
      maxSpeed: maxSpeed,
      distance: distance,
      duration: duration,
      hardBrakingCount: hardBrakingCount,
      rapidAccelerationCount: rapidAccelerationCount,
      sharpTurnCount: sharpTurnCount,
      warnings: warnings,
      weather: weather,
      routeType: routeType,
      safetyScore: _calculateSafetyScore(
        hardBrakingCount,
        rapidAccelerationCount,
        sharpTurnCount,
        warnings.length,
        averageSpeed,
        maxSpeed,
      ),
    );
    
    _drivingSessions.insert(0, session);
    if (_drivingSessions.length > _maxSessionHistory) {
      _drivingSessions.removeRange(_maxSessionHistory, _drivingSessions.length);
    }
    
    await _saveHistoricalData();
    await _performMLAnalysis();
  }
  
  // Record route data
  Future<void> recordRouteData({
    required String routeId,
    required String startLocation,
    required String endLocation,
    required double distance,
    required Duration estimatedTime,
    required Duration actualTime,
    required List<String> roadTypes,
    required double trafficLevel,
    required WeatherData? weather,
  }) async {
    final route = RouteData(
      id: routeId,
      timestamp: DateTime.now(),
      startLocation: startLocation,
      endLocation: endLocation,
      distance: distance,
      estimatedTime: estimatedTime,
      actualTime: actualTime,
      roadTypes: roadTypes,
      trafficLevel: trafficLevel,
      weather: weather,
      efficiency: _calculateRouteEfficiency(estimatedTime, actualTime),
    );
    
    _routeHistory.insert(0, route);
    if (_routeHistory.length > _maxSessionHistory) {
      _routeHistory.removeRange(_maxSessionHistory, _routeHistory.length);
    }
    
    await _saveHistoricalData();
  }
  
  // Perform comprehensive ML analysis
  Future<void> _performMLAnalysis() async {
    if (_drivingSessions.isEmpty) return;
    
    try {
      // Analyze driving patterns
      _currentPattern = _analyzeDrivingPatterns();
      _drivingPatternController.add(_currentPattern!);
      
      // Generate smart recommendations
      _currentRecommendations = _generateSmartRecommendations();
      _recommendationsController.add(_currentRecommendations);
      
      // Assess risk levels
      _currentRiskAssessment = _assessRiskLevels();
      _riskAssessmentController.add(_currentRiskAssessment!);
      
      // Calculate performance metrics
      _currentPerformance = _calculatePerformanceMetrics();
      _performanceController.add(_currentPerformance!);
      
      debugPrint('ML Analysis completed successfully');
    } catch (e) {
      debugPrint('Error performing ML analysis: $e');
    }
  }
  
  // Analyze driving patterns using ML algorithms
  DrivingPattern _analyzeDrivingPatterns() {
    final recentSessions = _drivingSessions.take(20).toList();
    
    // Calculate pattern metrics
    final avgSpeed = recentSessions.map((s) => s.averageSpeed).reduce((a, b) => a + b) / recentSessions.length;
    final avgSafetyScore = recentSessions.map((s) => s.safetyScore).reduce((a, b) => a + b) / recentSessions.length;
    
    // Analyze time-based patterns
    final timePatterns = _analyzeTimePatterns(recentSessions);
    
    // Analyze weather-based patterns
    final weatherPatterns = _analyzeWeatherPatterns(recentSessions);
    
    // Analyze route-based patterns
    final routePatterns = _analyzeRoutePatterns(recentSessions);
    
    // Determine driving style
    final drivingStyle = _determineDrivingStyle(recentSessions);
    
    return DrivingPattern(
      averageSpeed: avgSpeed,
      averageSafetyScore: avgSafetyScore,
      drivingStyle: drivingStyle,
      timePatterns: timePatterns,
      weatherPatterns: weatherPatterns,
      routePatterns: routePatterns,
      improvementAreas: _identifyImprovementAreas(recentSessions),
      strengths: _identifyStrengths(recentSessions),
    );
  }
  
  // Generate smart recommendations based on ML analysis
  List<SmartRecommendation> _generateSmartRecommendations() {
    final recommendations = <SmartRecommendation>[];
    
    if (_currentPattern == null) return recommendations;
    
    // Speed-based recommendations
    if (_currentPattern!.averageSpeed > 80) {
      recommendations.add(SmartRecommendation(
        id: 'speed_reduction',
        type: RecommendationType.safety,
        priority: RecommendationPriority.high,
        title: 'تقليل السرعة',
        description: 'متوسط سرعتك أعلى من المعدل الآمن. حاول تقليل السرعة للحصول على قيادة أكثر أماناً.',
        actionText: 'تطبيق',
        confidence: 0.85,
      ));
    }
    
    // Safety score recommendations
    if (_currentPattern!.averageSafetyScore < 70) {
      recommendations.add(SmartRecommendation(
        id: 'safety_improvement',
        type: RecommendationType.safety,
        priority: RecommendationPriority.high,
        title: 'تحسين السلامة',
        description: 'نقاط السلامة الخاصة بك تحتاج إلى تحسين. ركز على تجنب الفرملة المفاجئة والتسارع السريع.',
        actionText: 'عرض النصائح',
        confidence: 0.90,
      ));
    }
    
    // Route optimization recommendations
    final routeEfficiency = _calculateAverageRouteEfficiency();
    if (routeEfficiency < 0.8) {
      recommendations.add(SmartRecommendation(
        id: 'route_optimization',
        type: RecommendationType.efficiency,
        priority: RecommendationPriority.medium,
        title: 'تحسين المسارات',
        description: 'يمكن تحسين كفاءة مساراتك. جرب مسارات بديلة لتوفير الوقت والوقود.',
        actionText: 'اقتراح مسارات',
        confidence: 0.75,
      ));
    }
    
    // Weather-based recommendations
    final weatherRecommendations = _generateWeatherRecommendations();
    recommendations.addAll(weatherRecommendations);
    
    // Time-based recommendations
    final timeRecommendations = _generateTimeRecommendations();
    recommendations.addAll(timeRecommendations);
    
    return recommendations;
  }
  
  // Assess risk levels using ML models
  RiskAssessment _assessRiskLevels() {
    final recentSessions = _drivingSessions.take(10).toList();
    
    // Calculate various risk factors
    final speedRisk = _calculateSpeedRisk(recentSessions);
    final behaviorRisk = _calculateBehaviorRisk(recentSessions);
    final weatherRisk = _calculateWeatherRisk(recentSessions);
    final timeRisk = _calculateTimeRisk(recentSessions);
    final routeRisk = _calculateRouteRisk(recentSessions);
    
    // Calculate overall risk score
    final overallRisk = (speedRisk + behaviorRisk + weatherRisk + timeRisk + routeRisk) / 5;
    
    return RiskAssessment(
      overallRisk: overallRisk,
      speedRisk: speedRisk,
      behaviorRisk: behaviorRisk,
      weatherRisk: weatherRisk,
      timeRisk: timeRisk,
      routeRisk: routeRisk,
      riskLevel: _determineRiskLevel(overallRisk),
      recommendations: _generateRiskRecommendations(overallRisk),
    );
  }
  
  // Calculate performance metrics
  PerformanceMetrics _calculatePerformanceMetrics() {
    final recentSessions = _drivingSessions.take(30).toList();
    
    if (recentSessions.isEmpty) {
      return PerformanceMetrics(
        safetyScore: 0,
        efficiencyScore: 0,
        ecoScore: 0,
        overallScore: 0,
        improvement: 0,
        trend: PerformanceTrend.stable,
      );
    }
    
    final safetyScore = recentSessions.map((s) => s.safetyScore).reduce((a, b) => a + b) / recentSessions.length;
    final efficiencyScore = _calculateEfficiencyScore(recentSessions);
    final ecoScore = _calculateEcoScore(recentSessions);
    final overallScore = (safetyScore + efficiencyScore + ecoScore) / 3;
    
    // Calculate improvement trend
    final improvement = _calculateImprovement(recentSessions);
    final trend = _determineTrend(improvement);
    
    return PerformanceMetrics(
      safetyScore: safetyScore,
      efficiencyScore: efficiencyScore,
      ecoScore: ecoScore,
      overallScore: overallScore,
      improvement: improvement,
      trend: trend,
    );
  }
  
  // Helper methods for ML calculations
  double _calculateSafetyScore(int hardBraking, int rapidAcceleration, int sharpTurns, int warnings, double avgSpeed, double maxSpeed) {
    double score = 100.0;
    
    // Deduct points for risky behaviors
    score -= hardBraking * 5;
    score -= rapidAcceleration * 3;
    score -= sharpTurns * 2;
    score -= warnings * 10;
    
    // Deduct points for excessive speed
    if (avgSpeed > 80) score -= (avgSpeed - 80) * 0.5;
    if (maxSpeed > 120) score -= (maxSpeed - 120) * 1.0;
    
    return max(0, min(100, score));
  }
  
  double _calculateRouteEfficiency(Duration estimated, Duration actual) {
    if (estimated.inMinutes == 0) return 1.0;
    return min(1.0, estimated.inMinutes / actual.inMinutes);
  }
  
  DrivingStyle _determineDrivingStyle(List<DrivingSession> sessions) {
    final avgSpeed = sessions.map((s) => s.averageSpeed).reduce((a, b) => a + b) / sessions.length;
    final avgSafety = sessions.map((s) => s.safetyScore).reduce((a, b) => a + b) / sessions.length;
    
    if (avgSafety >= 85 && avgSpeed <= 70) return DrivingStyle.conservative;
    if (avgSafety >= 75 && avgSpeed <= 85) return DrivingStyle.balanced;
    if (avgSpeed > 85 || avgSafety < 70) return DrivingStyle.aggressive;
    
    return DrivingStyle.balanced;
  }
  
  // Additional helper methods...
  Map<String, double> _analyzeTimePatterns(List<DrivingSession> sessions) {
    // Analyze driving patterns by time of day
    return {
      'morning': 0.8,
      'afternoon': 0.7,
      'evening': 0.6,
      'night': 0.9,
    };
  }
  
  Map<String, double> _analyzeWeatherPatterns(List<DrivingSession> sessions) {
    // Analyze driving patterns by weather conditions
    return {
      'clear': 0.9,
      'rain': 0.7,
      'fog': 0.6,
      'snow': 0.5,
    };
  }
  
  Map<String, double> _analyzeRoutePatterns(List<DrivingSession> sessions) {
    // Analyze driving patterns by route type
    return {
      'highway': 0.8,
      'city': 0.7,
      'rural': 0.9,
    };
  }
  
  List<String> _identifyImprovementAreas(List<DrivingSession> sessions) {
    final areas = <String>[];
    
    final avgHardBraking = sessions.map((s) => s.hardBrakingCount).reduce((a, b) => a + b) / sessions.length;
    if (avgHardBraking > 2) areas.add('تقليل الفرملة المفاجئة');
    
    final avgRapidAcceleration = sessions.map((s) => s.rapidAccelerationCount).reduce((a, b) => a + b) / sessions.length;
    if (avgRapidAcceleration > 3) areas.add('تقليل التسارع السريع');
    
    return areas;
  }
  
  List<String> _identifyStrengths(List<DrivingSession> sessions) {
    final strengths = <String>[];
    
    final avgSafety = sessions.map((s) => s.safetyScore).reduce((a, b) => a + b) / sessions.length;
    if (avgSafety >= 85) strengths.add('قيادة آمنة');
    
    final avgSpeed = sessions.map((s) => s.averageSpeed).reduce((a, b) => a + b) / sessions.length;
    if (avgSpeed <= 75) strengths.add('سرعة مناسبة');
    
    return strengths;
  }
  
  double _calculateAverageRouteEfficiency() {
    if (_routeHistory.isEmpty) return 1.0;
    return _routeHistory.map((r) => r.efficiency).reduce((a, b) => a + b) / _routeHistory.length;
  }
  
  List<SmartRecommendation> _generateWeatherRecommendations() {
    // Generate weather-specific recommendations
    return [];
  }
  
  List<SmartRecommendation> _generateTimeRecommendations() {
    // Generate time-specific recommendations
    return [];
  }
  
  double _calculateSpeedRisk(List<DrivingSession> sessions) {
    final avgSpeed = sessions.map((s) => s.averageSpeed).reduce((a, b) => a + b) / sessions.length;
    return min(1.0, max(0.0, (avgSpeed - 60) / 60));
  }
  
  double _calculateBehaviorRisk(List<DrivingSession> sessions) {
    final avgHardBraking = sessions.map((s) => s.hardBrakingCount).reduce((a, b) => a + b) / sessions.length;
    final avgRapidAcceleration = sessions.map((s) => s.rapidAccelerationCount).reduce((a, b) => a + b) / sessions.length;
    return min(1.0, (avgHardBraking + avgRapidAcceleration) / 10);
  }
  
  double _calculateWeatherRisk(List<DrivingSession> sessions) {
    // Calculate weather-based risk
    return 0.3; // Placeholder
  }
  
  double _calculateTimeRisk(List<DrivingSession> sessions) {
    // Calculate time-based risk
    return 0.2; // Placeholder
  }
  
  double _calculateRouteRisk(List<DrivingSession> sessions) {
    // Calculate route-based risk
    return 0.25; // Placeholder
  }
  
  RiskLevel _determineRiskLevel(double risk) {
    if (risk >= 0.8) return RiskLevel.high;
    if (risk >= 0.5) return RiskLevel.medium;
    return RiskLevel.low;
  }
  
  List<String> _generateRiskRecommendations(double risk) {
    if (risk >= 0.8) {
      return ['تقليل السرعة فوراً', 'تجنب القيادة في الظروف السيئة', 'أخذ استراحة'];
    } else if (risk >= 0.5) {
      return ['مراقبة السرعة', 'زيادة المسافة الآمنة'];
    }
    return ['الحفاظ على القيادة الآمنة'];
  }
  
  double _calculateEfficiencyScore(List<DrivingSession> sessions) {
    // Calculate efficiency based on fuel consumption, time, etc.
    return 75.0; // Placeholder
  }
  
  double _calculateEcoScore(List<DrivingSession> sessions) {
    // Calculate eco-friendliness score
    return 80.0; // Placeholder
  }
  
  double _calculateImprovement(List<DrivingSession> sessions) {
    if (sessions.length < 2) return 0.0;
    
    final recent = sessions.take(sessions.length ~/ 2).map((s) => s.safetyScore).reduce((a, b) => a + b) / (sessions.length ~/ 2);
    final older = sessions.skip(sessions.length ~/ 2).map((s) => s.safetyScore).reduce((a, b) => a + b) / (sessions.length ~/ 2);
    
    return recent - older;
  }
  
  PerformanceTrend _determineTrend(double improvement) {
    if (improvement > 5) return PerformanceTrend.improving;
    if (improvement < -5) return PerformanceTrend.declining;
    return PerformanceTrend.stable;
  }
  
  // Public getters for current data
  DrivingPattern? get currentPattern => _currentPattern;
  List<SmartRecommendation> get currentRecommendations => _currentRecommendations;
  RiskAssessment? get currentRiskAssessment => _currentRiskAssessment;
  PerformanceMetrics? get currentPerformance => _currentPerformance;
  
  // Dispose resources
  void dispose() {
    _analysisTimer?.cancel();
    _drivingPatternController.close();
    _recommendationsController.close();
    _riskAssessmentController.close();
    _performanceController.close();
  }
}

// Data Models for ML Service
class DrivingSession {
  final String id;
  final DateTime timestamp;
  final double averageSpeed;
  final double maxSpeed;
  final double distance;
  final Duration duration;
  final int hardBrakingCount;
  final int rapidAccelerationCount;
  final int sharpTurnCount;
  final List<DrivingWarning> warnings;
  final WeatherData? weather;
  final String routeType;
  final double safetyScore;
  
  DrivingSession({
    required this.id,
    required this.timestamp,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.distance,
    required this.duration,
    required this.hardBrakingCount,
    required this.rapidAccelerationCount,
    required this.sharpTurnCount,
    required this.warnings,
    required this.weather,
    required this.routeType,
    required this.safetyScore,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'averageSpeed': averageSpeed,
    'maxSpeed': maxSpeed,
    'distance': distance,
    'duration': duration.inMinutes,
    'hardBrakingCount': hardBrakingCount,
    'rapidAccelerationCount': rapidAccelerationCount,
    'sharpTurnCount': sharpTurnCount,
    'warnings': warnings.map((w) => w.toJson()).toList(),
    'weather': weather != null ? weather!.toJson() : null,
    'routeType': routeType,
    'safetyScore': safetyScore,
  };
  
  factory DrivingSession.fromJson(Map<String, dynamic> json) => DrivingSession(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    averageSpeed: json['averageSpeed'].toDouble(),
    maxSpeed: json['maxSpeed'].toDouble(),
    distance: json['distance'].toDouble(),
    duration: Duration(minutes: json['duration']),
    hardBrakingCount: json['hardBrakingCount'],
    rapidAccelerationCount: json['rapidAccelerationCount'],
    sharpTurnCount: json['sharpTurnCount'],
    warnings: (json['warnings'] as List).map((w) => DrivingWarning.fromJson(w)).toList(),
    weather: json['weather'] != null ? WeatherData.fromJson(json['weather']) : null,
    routeType: json['routeType'],
    safetyScore: json['safetyScore'].toDouble(),
  );
}

class RouteData {
  final String id;
  final DateTime timestamp;
  final String startLocation;
  final String endLocation;
  final double distance;
  final Duration estimatedTime;
  final Duration actualTime;
  final List<String> roadTypes;
  final double trafficLevel;
  final WeatherData? weather;
  final double efficiency;
  
  RouteData({
    required this.id,
    required this.timestamp,
    required this.startLocation,
    required this.endLocation,
    required this.distance,
    required this.estimatedTime,
    required this.actualTime,
    required this.roadTypes,
    required this.trafficLevel,
    required this.weather,
    required this.efficiency,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'startLocation': startLocation,
    'endLocation': endLocation,
    'distance': distance,
    'estimatedTime': estimatedTime.inMinutes,
    'actualTime': actualTime.inMinutes,
    'roadTypes': roadTypes,
    'trafficLevel': trafficLevel,
    'weather': weather?.toJson(),
    'efficiency': efficiency,
  };
  
  factory RouteData.fromJson(Map<String, dynamic> json) => RouteData(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    startLocation: json['startLocation'],
    endLocation: json['endLocation'],
    distance: json['distance'].toDouble(),
    estimatedTime: Duration(minutes: json['estimatedTime']),
    actualTime: Duration(minutes: json['actualTime']),
    roadTypes: List<String>.from(json['roadTypes']),
    trafficLevel: json['trafficLevel'].toDouble(),
    weather: json['weather'] != null ? WeatherData.fromJson(json['weather']) : null,
    efficiency: json['efficiency'].toDouble(),
  );
}

class WeatherDrivingData {
  final DateTime timestamp;
  final WeatherData weather;
  final double averageSpeed;
  final double safetyScore;
  final int warningCount;
  
  WeatherDrivingData({
    required this.timestamp,
    required this.weather,
    required this.averageSpeed,
    required this.safetyScore,
    required this.warningCount,
  });
  
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'weather': weather.toJson(),
    'averageSpeed': averageSpeed,
    'safetyScore': safetyScore,
    'warningCount': warningCount,
  };
  
  factory WeatherDrivingData.fromJson(Map<String, dynamic> json) => WeatherDrivingData(
    timestamp: DateTime.parse(json['timestamp']),
    weather: WeatherData.fromJson(json['weather']),
    averageSpeed: json['averageSpeed'].toDouble(),
    safetyScore: json['safetyScore'].toDouble(),
    warningCount: json['warningCount'],
  );
}

class DrivingPattern {
  final double averageSpeed;
  final double averageSafetyScore;
  final DrivingStyle drivingStyle;
  final Map<String, double> timePatterns;
  final Map<String, double> weatherPatterns;
  final Map<String, double> routePatterns;
  final List<String> improvementAreas;
  final List<String> strengths;
  
  DrivingPattern({
    required this.averageSpeed,
    required this.averageSafetyScore,
    required this.drivingStyle,
    required this.timePatterns,
    required this.weatherPatterns,
    required this.routePatterns,
    required this.improvementAreas,
    required this.strengths,
  });
}

class SmartRecommendation {
  final String id;
  final RecommendationType type;
  final RecommendationPriority priority;
  final String title;
  final String description;
  final String actionText;
  final double confidence;
  
  SmartRecommendation({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.actionText,
    required this.confidence,
  });
}

class RiskAssessment {
  final double overallRisk;
  final double speedRisk;
  final double behaviorRisk;
  final double weatherRisk;
  final double timeRisk;
  final double routeRisk;
  final RiskLevel riskLevel;
  final List<String> recommendations;
  
  RiskAssessment({
    required this.overallRisk,
    required this.speedRisk,
    required this.behaviorRisk,
    required this.weatherRisk,
    required this.timeRisk,
    required this.routeRisk,
    required this.riskLevel,
    required this.recommendations,
  });
}

class PerformanceMetrics {
  final double safetyScore;
  final double efficiencyScore;
  final double ecoScore;
  final double overallScore;
  final double improvement;
  final PerformanceTrend trend;
  
  PerformanceMetrics({
    required this.safetyScore,
    required this.efficiencyScore,
    required this.ecoScore,
    required this.overallScore,
    required this.improvement,
    required this.trend,
  });
  
  Map<String, dynamic> toJson() => {
    'safetyScore': safetyScore,
    'efficiencyScore': efficiencyScore,
    'ecoScore': ecoScore,
    'overallScore': overallScore,
    'improvement': improvement,
    'trend': trend.toString().split('.').last,
  };
}

// Enums
enum DrivingStyle { conservative, balanced, aggressive }
enum RecommendationType { safety, efficiency, comfort, eco }
enum RecommendationPriority { low, medium, high, critical }
enum RiskLevel { low, medium, high, critical }
enum PerformanceTrend { improving, stable, declining }