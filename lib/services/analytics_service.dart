import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/analytics_report_model.dart';
import 'performance_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Controllers
  final StreamController<List<AnalyticsReportModel>> _reportsController =
      StreamController<List<AnalyticsReportModel>>.broadcast();
  final StreamController<Map<String, dynamic>> _analyticsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _loadingController =
      StreamController<bool>.broadcast();

  // State
  List<AnalyticsReportModel> _reports = [];
  Map<String, dynamic> _currentAnalytics = {};
  bool _isInitialized = false;
  Timer? _analyticsTimer;
  final PerformanceService _performanceService = PerformanceService.instance;

  // Getters
  Stream<List<AnalyticsReportModel>> get reportsStream => _reportsController.stream;
  Stream<Map<String, dynamic>> get analyticsStream => _analyticsController.stream;
  Stream<bool> get loadingStream => _loadingController.stream;
  List<AnalyticsReportModel> get reports => List.unmodifiable(_reports);
  Map<String, dynamic> get currentAnalytics => Map.unmodifiable(_currentAnalytics);
  bool get isInitialized => _isInitialized;

  // تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _loadingController.add(true);
      
      await _loadReports();
      await _loadAnalytics();
      _startAnalyticsCollection();
      
      _isInitialized = true;
      debugPrint('AnalyticsService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AnalyticsService: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  // تحميل التقارير المحفوظة
  Future<void> _loadReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getStringList('analytics_reports') ?? [];
      
      _reports = reportsJson
          .map((json) => AnalyticsReportModel.fromJson(jsonDecode(json)))
          .toList();
      
      _reportsController.add(_reports);
    } catch (e) {
      debugPrint('Error loading reports: $e');
      _reports = [];
    }
  }

  // حفظ التقارير
  Future<void> _saveReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = _reports
          .map((report) => jsonEncode(report.toJson()))
          .toList();
      
      await prefs.setStringList('analytics_reports', reportsJson);
    } catch (e) {
      debugPrint('Error saving reports: $e');
    }
  }

  // تحميل التحليلات
  Future<void> _loadAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analyticsJson = prefs.getString('current_analytics');
      
      if (analyticsJson != null) {
        _currentAnalytics = Map<String, dynamic>.from(jsonDecode(analyticsJson));
      } else {
        _currentAnalytics = await _generateInitialAnalytics();
      }
      
      _analyticsController.add(_currentAnalytics);
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      _currentAnalytics = await _generateInitialAnalytics();
    }
  }

  // حفظ التحليلات
  Future<void> _saveAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_analytics', jsonEncode(_currentAnalytics));
    } catch (e) {
      debugPrint('Error saving analytics: $e');
    }
  }

  // بدء جمع التحليلات
  void _startAnalyticsCollection() {
    _analyticsTimer?.cancel();
    _analyticsTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateAnalytics();
    });
  }

  // تحديث التحليلات
  Future<void> _updateAnalytics() async {
    try {
      final performanceMetrics = _performanceService.currentMetrics;
      final drivingStats = await _generateDrivingStats();
      final usageStats = await _generateUsageStats();
      
      _currentAnalytics = {
        'timestamp': DateTime.now().toIso8601String(),
        'performance': performanceMetrics?.toJson() ?? {},
        'driving': drivingStats,
        'usage': usageStats,
        'summary': await _generateSummary(),
      };
      
      await _saveAnalytics();
      _analyticsController.add(_currentAnalytics);
    } catch (e) {
      debugPrint('Error updating analytics: $e');
    }
  }

  // إنشاء تحليلات أولية
  Future<Map<String, dynamic>> _generateInitialAnalytics() async {
    final random = Random();
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'performance': {
        'memoryUsage': 45.0 + random.nextDouble() * 20,
        'cpuUsage': 30.0 + random.nextDouble() * 25,
        'batteryLevel': 60.0 + random.nextDouble() * 30,
        'networkLatency': 50.0 + random.nextDouble() * 100,
      },
      'driving': {
        'totalDistance': 1250.5 + random.nextDouble() * 500,
        'totalTrips': 45 + random.nextInt(20),
        'averageSpeed': 55.0 + random.nextDouble() * 20,
        'safetyScore': 85 + random.nextInt(15),
        'fuelEfficiency': 7.5 + random.nextDouble() * 2,
      },
      'usage': {
        'dailyActiveTime': 120 + random.nextInt(180),
        'featuresUsed': ['navigation', 'ar_mode', 'voice_assistant'],
        'screenTime': 45 + random.nextInt(60),
        'interactionCount': 150 + random.nextInt(100),
      },
      'summary': {
        'overallScore': 82 + random.nextInt(15),
        'improvements': ['تحسين كفاءة الوقود', 'زيادة نقاط السلامة'],
        'achievements': ['مسافة 1000 كم', 'أسبوع بدون حوادث'],
      },
    };
  }

  // إنشاء إحصائيات القيادة
  Future<Map<String, dynamic>> _generateDrivingStats() async {
    final random = Random();
    final now = DateTime.now();
    
    return {
      'totalDistance': 1250.5 + random.nextDouble() * 500,
      'totalTrips': 45 + random.nextInt(20),
      'averageSpeed': 55.0 + random.nextDouble() * 20,
      'maxSpeed': 120.0 + random.nextDouble() * 30,
      'safetyScore': 85 + random.nextInt(15),
      'ecoScore': 78 + random.nextInt(20),
      'fuelEfficiency': 7.5 + random.nextDouble() * 2,
      'co2Emissions': 180.0 + random.nextDouble() * 50,
      'lastTripDate': now.subtract(Duration(hours: random.nextInt(24))).toIso8601String(),
      'weeklyTrends': _generateWeeklyTrends(),
    };
  }

  // إنشاء إحصائيات الاستخدام
  Future<Map<String, dynamic>> _generateUsageStats() async {
    final random = Random();
    
    return {
      'dailyActiveTime': 120 + random.nextInt(180),
      'weeklyActiveTime': 850 + random.nextInt(300),
      'monthlyActiveTime': 3600 + random.nextInt(1200),
      'featuresUsed': [
        'navigation',
        'ar_mode',
        'voice_assistant',
        'performance_monitor',
        'reports'
      ],
      'mostUsedFeature': 'navigation',
      'screenTime': 45 + random.nextInt(60),
      'interactionCount': 150 + random.nextInt(100),
      'crashCount': random.nextInt(3),
      'errorCount': random.nextInt(10),
      'sessionCount': 25 + random.nextInt(15),
    };
  }

  // إنشاء اتجاهات أسبوعية
  List<Map<String, dynamic>> _generateWeeklyTrends() {
    final random = Random();
    final trends = <Map<String, dynamic>>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      trends.add({
        'date': date.toIso8601String(),
        'distance': 50.0 + random.nextDouble() * 100,
        'trips': 2 + random.nextInt(6),
        'safetyScore': 80 + random.nextInt(20),
        'fuelEfficiency': 7.0 + random.nextDouble() * 3,
      });
    }
    
    return trends;
  }

  // إنشاء ملخص
  Future<Map<String, dynamic>> _generateSummary() async {
    final random = Random();
    
    return {
      'overallScore': 82 + random.nextInt(15),
      'improvements': [
        'تحسين كفاءة الوقود بنسبة 5%',
        'زيادة نقاط السلامة إلى 90+',
        'تقليل وقت الرحلات بنسبة 10%'
      ],
      'achievements': [
        'مسافة 1000 كم بدون حوادث',
        'أسبوع كامل من القيادة الآمنة',
        'توفير 50 لتر وقود هذا الشهر'
      ],
      'alerts': [
        'استهلاك وقود أعلى من المعتاد',
        'سرعة عالية في المنطقة السكنية'
      ],
      'recommendations': [
        'استخدم وضع القيادة الاقتصادية',
        'تجنب الطرق المزدحمة في ساعات الذروة',
        'فحص ضغط الإطارات أسبوعياً'
      ],
    };
  }

  // إنشاء تقرير جديد
  Future<AnalyticsReportModel> generateReport({
    required String title,
    required AnalyticsReportType type,
    required AnalyticsCategory category,
    DateTime? startDate,
    DateTime? endDate,
    ReportSettings? settings,
  }) async {
    try {
      _loadingController.add(true);
      
      final now = DateTime.now();
      startDate ??= now.subtract(type.defaultDuration);
      endDate ??= now;
      settings ??= const ReportSettings();
      
      final reportData = await _generateReportData(category, startDate, endDate);
      final charts = await _generateCharts(category, reportData);
      final summary = await _generateReportSummary(category, reportData);
      
      final report = AnalyticsReportModel(
        id: 'report_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: 'تقرير ${category.displayName} من ${_formatDate(startDate)} إلى ${_formatDate(endDate)}',
        type: type,
        category: category,
        createdAt: now,
        startDate: startDate,
        endDate: endDate,
        data: reportData,
        charts: charts,
        settings: settings,
        summary: summary,
      );
      
      _reports.insert(0, report);
      await _saveReports();
      _reportsController.add(_reports);
      
      return report;
    } catch (e) {
      debugPrint('Error generating report: $e');
      rethrow;
    } finally {
      _loadingController.add(false);
    }
  }

  // إنشاء بيانات التقرير
  Future<Map<String, dynamic>> _generateReportData(
    AnalyticsCategory category,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final random = Random();
    
    switch (category) {
      case AnalyticsCategory.driving:
        return {
          'totalDistance': 500.0 + random.nextDouble() * 1000,
          'totalTrips': 20 + random.nextInt(50),
          'averageSpeed': 50.0 + random.nextDouble() * 30,
          'maxSpeed': 100.0 + random.nextDouble() * 50,
          'safetyScore': 80 + random.nextInt(20),
          'fuelConsumption': 100.0 + random.nextDouble() * 200,
          'co2Emissions': 200.0 + random.nextDouble() * 300,
          'routeAnalysis': _generateRouteAnalysis(),
          'timeAnalysis': _generateTimeAnalysis(),
        };
      
      case AnalyticsCategory.performance:
        return {
          'averageMemoryUsage': 40.0 + random.nextDouble() * 30,
          'averageCpuUsage': 25.0 + random.nextDouble() * 35,
          'averageBatteryDrain': 5.0 + random.nextDouble() * 10,
          'networkLatency': 50.0 + random.nextDouble() * 100,
          'crashCount': random.nextInt(5),
          'errorCount': random.nextInt(20),
          'loadTimes': _generateLoadTimes(),
          'optimizationSuggestions': _generateOptimizationSuggestions(),
        };
      
      case AnalyticsCategory.safety:
        return {
          'overallSafetyScore': 85 + random.nextInt(15),
          'speedingIncidents': random.nextInt(10),
          'hardBrakingEvents': random.nextInt(15),
          'rapidAcceleration': random.nextInt(8),
          'phoneUsageWhileDriving': random.nextInt(5),
          'safetyTrends': _generateSafetyTrends(),
          'riskAnalysis': _generateRiskAnalysis(),
        };
      
      case AnalyticsCategory.fuel:
        return {
          'totalFuelConsumption': 150.0 + random.nextDouble() * 100,
          'averageEfficiency': 7.0 + random.nextDouble() * 3,
          'fuelCost': 300.0 + random.nextDouble() * 200,
          'co2Emissions': 250.0 + random.nextDouble() * 150,
          'efficiencyTrends': _generateEfficiencyTrends(),
          'costAnalysis': _generateCostAnalysis(),
        };
      
      case AnalyticsCategory.routes:
        return {
          'totalRoutes': 15 + random.nextInt(20),
          'favoriteRoutes': _generateFavoriteRoutes(),
          'routeEfficiency': _generateRouteEfficiency(),
          'trafficAnalysis': _generateTrafficAnalysis(),
          'alternativeRoutes': _generateAlternativeRoutes(),
        };
      
      case AnalyticsCategory.usage:
        return {
          'totalActiveTime': 1200 + random.nextInt(1800),
          'sessionCount': 50 + random.nextInt(100),
          'featureUsage': _generateFeatureUsage(),
          'screenTime': 300 + random.nextInt(600),
          'interactionPatterns': _generateInteractionPatterns(),
          'userBehavior': _generateUserBehavior(),
        };
    }
  }

  // إنشاء الرسوم البيانية
  Future<List<ChartData>> _generateCharts(
    AnalyticsCategory category,
    Map<String, dynamic> data,
  ) async {
    final charts = <ChartData>[];
    
    switch (category) {
      case AnalyticsCategory.driving:
        charts.addAll([
          _createLineChart('driving_distance', 'المسافة اليومية', _generateDailyData('distance')),
          _createBarChart('driving_trips', 'عدد الرحلات', _generateDailyData('trips')),
          _createPieChart('driving_time', 'توزيع أوقات القيادة', _generateTimeDistribution()),
        ]);
        break;
      
      case AnalyticsCategory.performance:
        charts.addAll([
          _createLineChart('performance_memory', 'استخدام الذاكرة', _generatePerformanceData('memory')),
          _createAreaChart('performance_cpu', 'استخدام المعالج', _generatePerformanceData('cpu')),
          _createLineChart('performance_battery', 'استنزاف البطارية', _generatePerformanceData('battery')),
        ]);
        break;
      
      case AnalyticsCategory.safety:
        charts.addAll([
          _createLineChart('safety_score', 'نقاط السلامة', _generateSafetyData()),
          _createBarChart('safety_incidents', 'الحوادث والمخالفات', _generateIncidentData()),
        ]);
        break;
      
      case AnalyticsCategory.fuel:
        charts.addAll([
          _createLineChart('fuel_consumption', 'استهلاك الوقود', _generateFuelData()),
          _createBarChart('fuel_cost', 'تكلفة الوقود', _generateCostData()),
        ]);
        break;
      
      case AnalyticsCategory.routes:
        charts.addAll([
          _createBarChart('route_usage', 'استخدام المسارات', _generateRouteUsageData()),
          _createHeatmapChart('route_traffic', 'خريطة الازدحام', _generateTrafficData()),
        ]);
        break;
      
      case AnalyticsCategory.usage:
        charts.addAll([
          _createPieChart('feature_usage', 'استخدام الميزات', _generateFeatureUsageData()),
          _createLineChart('session_time', 'وقت الجلسات', _generateSessionData()),
        ]);
        break;
    }
    
    return charts;
  }

  // إنشاء ملخص التقرير
  Future<ReportSummary> _generateReportSummary(
    AnalyticsCategory category,
    Map<String, dynamic> data,
  ) async {
    final random = Random();
    
    switch (category) {
      case AnalyticsCategory.driving:
        return ReportSummary(
          overview: 'تحليل شامل لأنشطة القيادة يظهر تحسناً في الأداء العام',
          keyMetrics: [
            KeyMetric(
              name: 'إجمالي المسافة',
              value: (data['totalDistance'] as double).toStringAsFixed(1),
              unit: 'كم',
              change: 5.2,
              changeType: 'increase',
              description: 'زيادة في المسافة المقطوعة',
            ),
            KeyMetric(
              name: 'نقاط السلامة',
              value: '${data['safetyScore']}',
              unit: 'نقطة',
              change: 3.1,
              changeType: 'increase',
              description: 'تحسن في سلوك القيادة',
            ),
          ],
          insights: [
            'تحسن ملحوظ في سلوك القيادة الآمنة',
            'زيادة في المسافات المقطوعة مع الحفاظ على الكفاءة',
            'تفضيل الطرق السريعة على الطرق الفرعية',
          ],
          recommendations: [
            'الحفاظ على السرعة المناسبة في المناطق السكنية',
            'استخدام وضع القيادة الاقتصادية لتوفير الوقود',
            'تجنب القيادة في ساعات الذروة عند الإمكان',
          ],
          overallScore: 85.0 + random.nextDouble() * 10,
        );
      
      default:
        return ReportSummary(
          overview: 'تحليل ${category.displayName} يظهر أداءً جيداً مع فرص للتحسين',
          keyMetrics: [
            KeyMetric(
              name: 'المؤشر الرئيسي',
              value: '${80 + random.nextInt(20)}',
              unit: 'نقطة',
              description: 'الأداء العام للفئة',
            ),
          ],
          insights: ['تحليل عام للبيانات'],
          recommendations: ['توصيات عامة للتحسين'],
          overallScore: 80.0 + random.nextDouble() * 15,
        );
    }
  }

  // مساعدات إنشاء الرسوم البيانية
  ChartData _createLineChart(String id, String title, List<DataPoint> data) {
    return ChartData(
      id: id,
      title: title,
      type: ChartType.line,
      dataPoints: data,
      style: const ChartStyle(
        primaryColor: '#2196F3',
        secondaryColor: '#1976D2',
        strokeWidth: 3.0,
        showAnimation: true,
      ),
    );
  }

  ChartData _createBarChart(String id, String title, List<DataPoint> data) {
    return ChartData(
      id: id,
      title: title,
      type: ChartType.bar,
      dataPoints: data,
      style: const ChartStyle(
        primaryColor: '#4CAF50',
        secondaryColor: '#388E3C',
        showAnimation: true,
      ),
    );
  }

  ChartData _createPieChart(String id, String title, List<DataPoint> data) {
    return ChartData(
      id: id,
      title: title,
      type: ChartType.pie,
      dataPoints: data,
      style: const ChartStyle(
        showLegend: true,
        showLabels: true,
        showAnimation: true,
      ),
    );
  }

  ChartData _createAreaChart(String id, String title, List<DataPoint> data) {
    return ChartData(
      id: id,
      title: title,
      type: ChartType.area,
      dataPoints: data,
      style: const ChartStyle(
        primaryColor: '#FF9800',
        secondaryColor: '#F57C00',
        showAnimation: true,
      ),
    );
  }

  ChartData _createHeatmapChart(String id, String title, List<DataPoint> data) {
    return ChartData(
      id: id,
      title: title,
      type: ChartType.heatmap,
      dataPoints: data,
      style: const ChartStyle(
        showGrid: true,
        showAnimation: true,
      ),
    );
  }

  // مساعدات إنشاء البيانات
  List<DataPoint> _generateDailyData(String type) {
    final random = Random();
    final data = <DataPoint>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      double value;
      
      switch (type) {
        case 'distance':
          value = 50.0 + random.nextDouble() * 100;
          break;
        case 'trips':
          value = (2 + random.nextInt(6)).toDouble();
          break;
        default:
          value = random.nextDouble() * 100;
      }
      
      data.add(DataPoint(
        label: _formatShortDate(date),
        value: value,
        timestamp: date,
      ));
    }
    
    return data;
  }

  List<DataPoint> _generatePerformanceData(String type) {
    final random = Random();
    final data = <DataPoint>[];
    
    for (int i = 23; i >= 0; i--) {
      final time = DateTime.now().subtract(Duration(hours: i));
      double value;
      
      switch (type) {
        case 'memory':
          value = 30.0 + random.nextDouble() * 40;
          break;
        case 'cpu':
          value = 20.0 + random.nextDouble() * 50;
          break;
        case 'battery':
          value = 2.0 + random.nextDouble() * 8;
          break;
        default:
          value = random.nextDouble() * 100;
      }
      
      data.add(DataPoint(
        label: '${time.hour}:00',
        value: value,
        timestamp: time,
      ));
    }
    
    return data;
  }

  List<DataPoint> _generateSafetyData() {
    final random = Random();
    final data = <DataPoint>[];
    
    for (int i = 29; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final value = 75.0 + random.nextDouble() * 25;
      
      data.add(DataPoint(
        label: _formatShortDate(date),
        value: value,
        timestamp: date,
      ));
    }
    
    return data;
  }

  List<DataPoint> _generateIncidentData() {
    return [
      const DataPoint(label: 'تجاوز السرعة', value: 3),
      const DataPoint(label: 'فرملة مفاجئة', value: 2),
      const DataPoint(label: 'تسارع سريع', value: 1),
      const DataPoint(label: 'استخدام الهاتف', value: 1),
    ];
  }

  List<DataPoint> _generateFuelData() {
    final random = Random();
    final data = <DataPoint>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final value = 6.0 + random.nextDouble() * 4;
      
      data.add(DataPoint(
        label: _formatShortDate(date),
        value: value,
        timestamp: date,
      ));
    }
    
    return data;
  }

  List<DataPoint> _generateCostData() {
    final random = Random();
    final data = <DataPoint>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final value = 30.0 + random.nextDouble() * 50;
      
      data.add(DataPoint(
        label: _formatShortDate(date),
        value: value,
        timestamp: date,
      ));
    }
    
    return data;
  }

  List<DataPoint> _generateRouteUsageData() {
    return [
      const DataPoint(label: 'المنزل - العمل', value: 25),
      const DataPoint(label: 'العمل - المنزل', value: 23),
      const DataPoint(label: 'المنزل - المول', value: 8),
      const DataPoint(label: 'المنزل - المدرسة', value: 12),
      const DataPoint(label: 'طرق أخرى', value: 15),
    ];
  }

  List<DataPoint> _generateTrafficData() {
    final random = Random();
    final data = <DataPoint>[];
    
    for (int hour = 0; hour < 24; hour++) {
      final value = random.nextDouble() * 100;
      data.add(DataPoint(
        label: '$hour:00',
        value: value,
      ));
    }
    
    return data;
  }

  List<DataPoint> _generateFeatureUsageData() {
    return [
      const DataPoint(label: 'الملاحة', value: 45),
      const DataPoint(label: 'الواقع المعزز', value: 25),
      const DataPoint(label: 'المساعد الصوتي', value: 15),
      const DataPoint(label: 'مراقب الأداء', value: 10),
      const DataPoint(label: 'التقارير', value: 5),
    ];
  }

  List<DataPoint> _generateSessionData() {
    final random = Random();
    final data = <DataPoint>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final value = 30.0 + random.nextDouble() * 90;
      
      data.add(DataPoint(
        label: _formatShortDate(date),
        value: value,
        timestamp: date,
      ));
    }
    
    return data;
  }

  List<DataPoint> _generateTimeDistribution() {
    return [
      const DataPoint(label: 'الصباح (6-12)', value: 35),
      const DataPoint(label: 'الظهر (12-18)', value: 40),
      const DataPoint(label: 'المساء (18-24)', value: 20),
      const DataPoint(label: 'الليل (0-6)', value: 5),
    ];
  }

  // مساعدات إنشاء البيانات المعقدة
  List<Map<String, dynamic>> _generateRouteAnalysis() {
    return [
      {
        'routeName': 'المنزل - العمل',
        'distance': 25.5,
        'averageTime': 35,
        'fuelEfficiency': 8.2,
        'usageCount': 45,
      },
      {
        'routeName': 'العمل - المنزل',
        'distance': 27.2,
        'averageTime': 42,
        'fuelEfficiency': 7.8,
        'usageCount': 43,
      },
    ];
  }

  Map<String, dynamic> _generateTimeAnalysis() {
    return {
      'peakHours': ['7:00-9:00', '17:00-19:00'],
      'averageTripDuration': 28,
      'longestTrip': 125,
      'shortestTrip': 5,
      'weekdayVsWeekend': {
        'weekday': 75,
        'weekend': 25,
      },
    };
  }

  List<Map<String, dynamic>> _generateLoadTimes() {
    return [
      {'screen': 'الرئيسية', 'loadTime': 1.2},
      {'screen': 'الملاحة', 'loadTime': 2.8},
      {'screen': 'الواقع المعزز', 'loadTime': 3.5},
      {'screen': 'التقارير', 'loadTime': 2.1},
    ];
  }

  List<String> _generateOptimizationSuggestions() {
    return [
      'تحسين تحميل الخرائط',
      'تقليل استخدام الذاكرة في وضع AR',
      'تحسين خوارزمية الملاحة',
      'ضغط بيانات التقارير',
    ];
  }

  List<Map<String, dynamic>> _generateSafetyTrends() {
    final random = Random();
    final trends = <Map<String, dynamic>>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      trends.add({
        'date': date.toIso8601String(),
        'score': 80 + random.nextInt(20),
        'incidents': random.nextInt(3),
      });
    }
    
    return trends;
  }

  Map<String, dynamic> _generateRiskAnalysis() {
    return {
      'riskLevel': 'منخفض',
      'riskFactors': ['السرعة العالية أحياناً', 'القيادة في الليل'],
      'riskScore': 25,
      'recommendations': [
        'تجنب السرعة الزائدة',
        'زيادة الحذر في القيادة الليلية',
      ],
    };
  }

  List<Map<String, dynamic>> _generateEfficiencyTrends() {
    final random = Random();
    final trends = <Map<String, dynamic>>[];
    
    for (int i = 29; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      trends.add({
        'date': date.toIso8601String(),
        'efficiency': 6.5 + random.nextDouble() * 3,
        'cost': 25.0 + random.nextDouble() * 20,
      });
    }
    
    return trends;
  }

  Map<String, dynamic> _generateCostAnalysis() {
    return {
      'monthlyAverage': 450.0,
      'yearlyProjection': 5400.0,
      'savings': 120.0,
      'costPerKm': 0.85,
      'comparison': {
        'lastMonth': 480.0,
        'change': -6.25,
      },
    };
  }

  List<Map<String, dynamic>> _generateFavoriteRoutes() {
    return [
      {
        'name': 'المنزل - العمل',
        'usage': 45,
        'efficiency': 8.2,
        'rating': 4.5,
      },
      {
        'name': 'المنزل - المول',
        'usage': 12,
        'efficiency': 7.8,
        'rating': 4.2,
      },
    ];
  }

  Map<String, dynamic> _generateRouteEfficiency() {
    return {
      'mostEfficient': 'الطريق السريع الشرقي',
      'leastEfficient': 'طريق المدينة القديمة',
      'averageEfficiency': 7.8,
      'improvementPotential': 15.0,
    };
  }

  Map<String, dynamic> _generateTrafficAnalysis() {
    return {
      'peakTrafficHours': ['7:00-9:00', '17:00-19:00'],
      'averageDelay': 12,
      'worstRoute': 'شارع الملك فهد',
      'bestRoute': 'الطريق الدائري',
      'trafficScore': 75,
    };
  }

  List<Map<String, dynamic>> _generateAlternativeRoutes() {
    return [
      {
        'original': 'المنزل - العمل (الطريق الرئيسي)',
        'alternative': 'المنزل - العمل (الطريق البديل)',
        'timeSaving': 8,
        'distanceDifference': -2.5,
        'fuelSaving': 1.2,
      },
    ];
  }

  Map<String, dynamic> _generateFeatureUsage() {
    return {
      'navigation': 85,
      'ar_mode': 45,
      'voice_assistant': 35,
      'performance_monitor': 25,
      'reports': 15,
      'settings': 20,
    };
  }

  Map<String, dynamic> _generateInteractionPatterns() {
    return {
      'averageSessionLength': 25,
      'mostActiveHour': 8,
      'screenTaps': 150,
      'voiceCommands': 25,
      'gestureUsage': 45,
    };
  }

  Map<String, dynamic> _generateUserBehavior() {
    return {
      'preferredFeatures': ['navigation', 'ar_mode'],
      'usagePatterns': 'نشط في الصباح والمساء',
      'learningCurve': 'متقدم',
      'feedbackScore': 4.2,
    };
  }

  // حذف تقرير
  Future<void> deleteReport(String reportId) async {
    try {
      _reports.removeWhere((report) => report.id == reportId);
      await _saveReports();
      _reportsController.add(_reports);
    } catch (e) {
      debugPrint('Error deleting report: $e');
    }
  }

  // تصدير تقرير
  Future<String?> exportReport(
    AnalyticsReportModel report,
    ReportFormat format,
  ) async {
    try {
      // هنا يمكن تنفيذ تصدير التقرير بصيغ مختلفة
      // للتبسيط، سنعيد مسار وهمي
      final fileName = 'report_${report.id}${format.fileExtension}';
      final filePath = '/storage/reports/$fileName';
      
      // محاكاة عملية التصدير
      await Future.delayed(const Duration(seconds: 2));
      
      return filePath;
    } catch (e) {
      debugPrint('Error exporting report: $e');
      return null;
    }
  }

  // مساعدات التنسيق
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  // تنظيف الموارد
  void dispose() {
    _analyticsTimer?.cancel();
    _reportsController.close();
    _analyticsController.close();
    _loadingController.close();
  }
}