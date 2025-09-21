import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/performance_model.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  static PerformanceService get instance => _instance;
  PerformanceService._internal();
  
  // Stream controllers
  final StreamController<PerformanceMetrics> _metricsController = 
      StreamController<PerformanceMetrics>.broadcast();
  final StreamController<MemoryUsage> _memoryController = 
      StreamController<MemoryUsage>.broadcast();
  final StreamController<BatteryInfo> _batteryController = 
      StreamController<BatteryInfo>.broadcast();
  final StreamController<List<PerformanceAlert>> _alertsController = 
      StreamController<List<PerformanceAlert>>.broadcast();
  
  // Streams
  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;
  Stream<MemoryUsage> get memoryStream => _memoryController.stream;
  Stream<BatteryInfo> get batteryStream => _batteryController.stream;
  Stream<List<PerformanceAlert>> get alertsStream => _alertsController.stream;
  
  // State
  bool _isInitialized = false;
  bool _isMonitoring = false;
  late SharedPreferences _prefs;
  
  // Performance data
  PerformanceMetrics? _currentMetrics;
  MemoryUsage? _currentMemoryUsage;
  BatteryInfo? _currentBatteryInfo;
  List<PerformanceAlert> _activeAlerts = [];
  
  // Monitoring settings
  bool _enableMemoryOptimization = true;
  bool _enableBatteryOptimization = true;
  bool _enablePerformanceAlerts = true;
  double _memoryThreshold = 80.0; // Percentage
  double _batteryThreshold = 20.0; // Percentage
  
  // Timers
  Timer? _monitoringTimer;
  Timer? _optimizationTimer;
  Timer? _cleanupTimer;
  
  // Performance tracking
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, List<Duration>> _operationDurations = {};
  final List<PerformanceLog> _performanceLogs = [];
  
  // Memory management
  final Set<String> _cachedData = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const int _maxCacheSize = 100;
  static const Duration _cacheExpiry = Duration(minutes: 30);
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isMonitoring => _isMonitoring;
  PerformanceMetrics? get currentMetrics => _currentMetrics;
  MemoryUsage? get currentMemoryUsage => _currentMemoryUsage;
  BatteryInfo? get currentBatteryInfo => _currentBatteryInfo;
  List<PerformanceAlert> get activeAlerts => _activeAlerts;
  List<PerformanceLog> get performanceLogs => _performanceLogs;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      await _initializeMonitoring();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('Performance Service initialized successfully');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Performance Service: $e');
      }
      rethrow;
    }
  }
  
  Future<void> _loadSettings() async {
    _enableMemoryOptimization = _prefs.getBool('enable_memory_optimization') ?? true;
    _enableBatteryOptimization = _prefs.getBool('enable_battery_optimization') ?? true;
    _enablePerformanceAlerts = _prefs.getBool('enable_performance_alerts') ?? true;
    _memoryThreshold = _prefs.getDouble('memory_threshold') ?? 80.0;
    _batteryThreshold = _prefs.getDouble('battery_threshold') ?? 20.0;
  }
  
  Future<void> _saveSettings() async {
    await _prefs.setBool('enable_memory_optimization', _enableMemoryOptimization);
    await _prefs.setBool('enable_battery_optimization', _enableBatteryOptimization);
    await _prefs.setBool('enable_performance_alerts', _enablePerformanceAlerts);
    await _prefs.setDouble('memory_threshold', _memoryThreshold);
    await _prefs.setDouble('battery_threshold', _batteryThreshold);
  }
  
  Future<void> _initializeMonitoring() async {
    // Start performance monitoring
    await startMonitoring();
    
    // Start optimization timers
    _optimizationTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performOptimizations();
    });
    
    // Start cleanup timer
    _cleanupTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _performCleanup();
    });
  }
  
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _collectMetrics();
    });
    
    if (kDebugMode) {
      print('Performance monitoring started');
    }
  }
  
  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    
    if (kDebugMode) {
      print('Performance monitoring stopped');
    }
  }
  
  Future<void> _collectMetrics() async {
    try {
      // Collect memory usage
      final memoryUsage = await _getMemoryUsage();
      _currentMemoryUsage = memoryUsage;
      _memoryController.add(memoryUsage);
      
      // Collect battery info
      final batteryInfo = await _getBatteryInfo();
      _currentBatteryInfo = batteryInfo;
      _batteryController.add(batteryInfo);
      
      // Calculate overall metrics
      final metrics = PerformanceMetrics(
        timestamp: DateTime.now(),
        memoryUsage: memoryUsage,
        batteryInfo: batteryInfo,
        cpuUsage: await _getCPUUsage(),
        networkUsage: await _getNetworkUsage(),
        frameRate: await _getFrameRate(),
        responseTime: _calculateAverageResponseTime(),
        cacheHitRate: _calculateCacheHitRate(),
        errorRate: _calculateErrorRate(),
      );
      
      _currentMetrics = metrics;
      _metricsController.add(metrics);
      
      // Check for performance issues
      await _checkPerformanceAlerts(metrics);
      
      // Log metrics
      _logPerformanceData(metrics);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error collecting metrics: $e');
      }
    }
  }
  
  Future<MemoryUsage> _getMemoryUsage() async {
    try {
      // Get memory info from platform
      final memoryInfo = await _getSystemMemoryInfo();
      
      return MemoryUsage(
        timestamp: DateTime.now(),
        totalMemory: memoryInfo['total'] ?? 0,
        usedMemory: memoryInfo['used'] ?? 0,
        freeMemory: memoryInfo['free'] ?? 0,
        appMemory: memoryInfo['app'] ?? 0,
        cacheSize: _cachedData.length,
        heapSize: memoryInfo['heap'] ?? 0,
        usagePercentage: memoryInfo['percentage'] ?? 0.0,
      );
    } catch (e) {
      // Return default values if platform call fails
      return MemoryUsage(
        timestamp: DateTime.now(),
        totalMemory: 4000000000, // 4GB default
        usedMemory: 2000000000, // 2GB default
        freeMemory: 2000000000, // 2GB default
        appMemory: 100000000, // 100MB default
        cacheSize: _cachedData.length,
        heapSize: 50000000, // 50MB default
        usagePercentage: 50.0,
      );
    }
  }
  
  Future<Map<String, dynamic>> _getSystemMemoryInfo() async {
    try {
      if (Platform.isAndroid) {
        // Android memory info
        const platform = MethodChannel('com.saferoute.performance');
        return await platform.invokeMethod('getMemoryInfo');
      } else if (Platform.isIOS) {
        // iOS memory info
        const platform = MethodChannel('com.saferoute.performance');
        return await platform.invokeMethod('getMemoryInfo');
      } else {
        // Web or other platforms - return simulated data
        return {
          'total': 4000000000,
          'used': 2000000000,
          'free': 2000000000,
          'app': 100000000,
          'heap': 50000000,
          'percentage': 50.0,
        };
      }
    } catch (e) {
      // Return simulated data if platform call fails
      return {
        'total': 4000000000,
        'used': 2000000000,
        'free': 2000000000,
        'app': 100000000,
        'heap': 50000000,
        'percentage': 50.0,
      };
    }
  }
  
  Future<BatteryInfo> _getBatteryInfo() async {
    try {
      final batteryData = await _getBatteryData();
      
      return BatteryInfo(
        timestamp: DateTime.now(),
        level: batteryData['level'] ?? 50.0,
        isCharging: batteryData['charging'] ?? false,
        chargingState: _getChargingState(batteryData),
        temperature: batteryData['temperature'] ?? 25.0,
        voltage: batteryData['voltage'] ?? 3.7,
        health: BatteryHealth.good,
        estimatedTimeRemaining: Duration(
          hours: ((batteryData['level'] ?? 50.0) / 10).round(),
        ),
      );
    } catch (e) {
      // Return default battery info
      return BatteryInfo(
        timestamp: DateTime.now(),
        level: 50.0,
        isCharging: false,
        chargingState: ChargingState.discharging,
        temperature: 25.0,
        voltage: 3.7,
        health: BatteryHealth.good,
        estimatedTimeRemaining: const Duration(hours: 5),
      );
    }
  }
  
  Future<Map<String, dynamic>> _getBatteryData() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        const platform = MethodChannel('com.saferoute.battery');
        return await platform.invokeMethod('getBatteryInfo');
      } else {
        // Web or other platforms - return simulated data
        return {
          'level': 75.0,
          'charging': false,
          'temperature': 25.0,
          'voltage': 3.7,
        };
      }
    } catch (e) {
      return {
        'level': 75.0,
        'charging': false,
        'temperature': 25.0,
        'voltage': 3.7,
      };
    }
  }
  
  ChargingState _getChargingState(Map<String, dynamic> batteryData) {
    final isCharging = batteryData['charging'] ?? false;
    final level = batteryData['level'] ?? 50.0;
    
    if (isCharging) {
      if (level >= 100) {
        return ChargingState.full;
      } else {
        return ChargingState.charging;
      }
    } else {
      return ChargingState.discharging;
    }
  }
  
  Future<double> _getCPUUsage() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        const platform = MethodChannel('com.saferoute.performance');
        final result = await platform.invokeMethod('getCPUUsage');
        return result ?? 30.0;
      } else {
        // Return simulated CPU usage for web
        return 25.0 + (DateTime.now().millisecond % 20);
      }
    } catch (e) {
      return 30.0; // Default CPU usage
    }
  }
  
  Future<NetworkUsage> _getNetworkUsage() async {
    try {
      return NetworkUsage(
        timestamp: DateTime.now(),
        bytesReceived: 1024000, // 1MB
        bytesSent: 512000, // 512KB
        packetsReceived: 1000,
        packetsSent: 500,
        connectionType: NetworkType.wifi,
        signalStrength: 80.0,
      );
    } catch (e) {
      return NetworkUsage(
        timestamp: DateTime.now(),
        bytesReceived: 0,
        bytesSent: 0,
        packetsReceived: 0,
        packetsSent: 0,
        connectionType: NetworkType.unknown,
        signalStrength: 0.0,
      );
    }
  }
  
  Future<double> _getFrameRate() async {
    try {
      // Calculate frame rate based on rendering performance
      return 60.0; // Assume 60 FPS for now
    } catch (e) {
      return 30.0; // Default frame rate
    }
  }
  
  double _calculateAverageResponseTime() {
    if (_operationDurations.isEmpty) return 0.0;
    
    double totalTime = 0.0;
    int totalOperations = 0;
    
    for (final durations in _operationDurations.values) {
      for (final duration in durations) {
        totalTime += duration.inMilliseconds;
        totalOperations++;
      }
    }
    
    return totalOperations > 0 ? totalTime / totalOperations : 0.0;
  }
  
  double _calculateCacheHitRate() {
    // Simplified cache hit rate calculation
    return _cachedData.isNotEmpty ? 85.0 : 0.0;
  }
  
  double _calculateErrorRate() {
    // Simplified error rate calculation
    return 2.0; // 2% error rate
  }
  
  Future<void> _checkPerformanceAlerts(PerformanceMetrics metrics) async {
    if (!_enablePerformanceAlerts) return;
    
    final alerts = <PerformanceAlert>[];
    
    // Check memory usage
    if (metrics.memoryUsage.usagePercentage > _memoryThreshold) {
      alerts.add(PerformanceAlert(
        id: 'memory_high',
        type: AlertType.memory,
        severity: AlertSeverity.warning,
        title: 'استهلاك ذاكرة مرتفع',
        message: 'استهلاك الذاكرة وصل إلى ${metrics.memoryUsage.usagePercentage.toStringAsFixed(1)}%',
        timestamp: DateTime.now(),
        isActive: true,
        threshold: _memoryThreshold,
        currentValue: metrics.memoryUsage.usagePercentage,
        suggestions: [
          'إغلاق التطبيقات غير المستخدمة',
          'مسح ذاكرة التخزين المؤقت',
          'إعادة تشغيل التطبيق',
        ],
      ));
    }
    
    // Check battery level
    if (metrics.batteryInfo.level < _batteryThreshold) {
      alerts.add(PerformanceAlert(
        id: 'battery_low',
        type: AlertType.battery,
        severity: AlertSeverity.critical,
        title: 'بطارية منخفضة',
        message: 'مستوى البطارية ${metrics.batteryInfo.level.toStringAsFixed(0)}%',
        timestamp: DateTime.now(),
        isActive: true,
        threshold: _batteryThreshold,
        currentValue: metrics.batteryInfo.level,
        suggestions: [
          'تفعيل وضع توفير الطاقة',
          'تقليل سطوع الشاشة',
          'إغلاق الميزات غير الضرورية',
        ],
      ));
    }
    
    // Check CPU usage
    if (metrics.cpuUsage > 80.0) {
      alerts.add(PerformanceAlert(
        id: 'cpu_high',
        type: AlertType.cpu,
        severity: AlertSeverity.warning,
        title: 'استهلاك معالج مرتفع',
        message: 'استهلاك المعالج وصل إلى ${metrics.cpuUsage.toStringAsFixed(1)}%',
        timestamp: DateTime.now(),
        isActive: true,
        threshold: 80.0,
        currentValue: metrics.cpuUsage,
        suggestions: [
          'إغلاق العمليات الثقيلة',
          'تقليل جودة الرسوميات',
          'إيقاف الميزات المتقدمة مؤقتاً',
        ],
      ));
    }
    
    // Check frame rate
    if (metrics.frameRate < 30.0) {
      alerts.add(PerformanceAlert(
        id: 'framerate_low',
        type: AlertType.performance,
        severity: AlertSeverity.info,
        title: 'أداء رسوميات منخفض',
        message: 'معدل الإطارات ${metrics.frameRate.toStringAsFixed(0)} FPS',
        timestamp: DateTime.now(),
        isActive: true,
        threshold: 30.0,
        currentValue: metrics.frameRate,
        suggestions: [
          'تقليل جودة الرسوميات',
          'إغلاق التأثيرات البصرية',
          'تحديث برنامج تشغيل الرسوميات',
        ],
      ));
    }
    
    // Update active alerts
    _activeAlerts = alerts;
    _alertsController.add(_activeAlerts);
  }
  
  void _logPerformanceData(PerformanceMetrics metrics) {
    final log = PerformanceLog(
      timestamp: DateTime.now(),
      metrics: metrics,
      alerts: List.from(_activeAlerts),
      optimizationsApplied: [],
    );
    
    _performanceLogs.add(log);
    
    // Keep only last 100 logs
    if (_performanceLogs.length > 100) {
      _performanceLogs.removeAt(0);
    }
  }
  
  Future<void> _performOptimizations() async {
    if (!_enableMemoryOptimization && !_enableBatteryOptimization) return;
    
    try {
      final optimizations = <String>[];
      
      if (_enableMemoryOptimization) {
        await _optimizeMemory();
        optimizations.add('memory');
      }
      
      if (_enableBatteryOptimization) {
        await _optimizeBattery();
        optimizations.add('battery');
      }
      
      // Optimizations applied successfully
      
    } catch (e) {
      if (kDebugMode) {
        print('Error performing optimizations: $e');
      }
    }
  }
  
  Future<void> _optimizeMemory() async {
    // Clear expired cache
    await _clearExpiredCache();
    
    // Trigger garbage collection
    await _triggerGarbageCollection();
    
    // Optimize image cache
    await _optimizeImageCache();
  }
  
  Future<void> _optimizeBattery() async {
    // Reduce background processing
    await _reduceBackgroundProcessing();
    
    // Optimize network usage
    await _optimizeNetworkUsage();
    
    // Adjust screen brightness if needed
    await _adjustScreenBrightness();
  }
  
  Future<void> _clearExpiredCache() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _cachedData.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    // Cache entries cleared successfully
  }
  
  Future<void> _triggerGarbageCollection() async {
    // Force garbage collection (platform-specific)
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        const platform = MethodChannel('com.saferoute.performance');
        await platform.invokeMethod('triggerGC');
      }
    } catch (e) {
      // Ignore errors - GC will happen naturally
    }
  }
  
  Future<void> _optimizeImageCache() async {
    // Clear image cache if memory usage is high
    if (_currentMemoryUsage?.usagePercentage != null &&
        _currentMemoryUsage!.usagePercentage > 75.0) {
      try {
        // Clear Flutter image cache
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        
        if (kDebugMode) {
          print('Cleared image cache due to high memory usage');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error clearing image cache: $e');
        }
      }
    }
  }
  
  Future<void> _reduceBackgroundProcessing() async {
    // Reduce timer frequencies if battery is low
    if (_currentBatteryInfo?.level != null &&
        _currentBatteryInfo!.level < 30.0) {
      // Extend monitoring interval
      _monitoringTimer?.cancel();
      _monitoringTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _collectMetrics();
      });
      
      if (kDebugMode) {
        print('Reduced monitoring frequency to save battery');
      }
    }
  }
  
  Future<void> _optimizeNetworkUsage() async {
    // Implement network optimization strategies
    // This would typically involve reducing API calls, caching responses, etc.
  }
  
  Future<void> _adjustScreenBrightness() async {
    // Adjust screen brightness based on battery level
    if (_currentBatteryInfo?.level != null &&
        _currentBatteryInfo!.level < 20.0) {
      try {
        // Platform-specific brightness adjustment
        if (Platform.isAndroid || Platform.isIOS) {
          const platform = MethodChannel('com.saferoute.display');
          await platform.invokeMethod('reduceBrightness');
        }
      } catch (e) {
        // Ignore errors - user can adjust manually
      }
    }
  }
  
  Future<void> _performCleanup() async {
    try {
      // Clean up old performance logs
      if (_performanceLogs.length > 50) {
        _performanceLogs.removeRange(0, _performanceLogs.length - 50);
      }
      
      // Clean up operation tracking data
      final now = DateTime.now();
      final oldOperations = <String>[];
      
      for (final entry in _operationStartTimes.entries) {
        if (now.difference(entry.value) > const Duration(hours: 1)) {
          oldOperations.add(entry.key);
        }
      }
      
      for (final operation in oldOperations) {
        _operationStartTimes.remove(operation);
        _operationDurations.remove(operation);
      }
      
      // Clean up cache if it's too large
      if (_cachedData.length > _maxCacheSize) {
        final sortedEntries = _cacheTimestamps.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        
        final toRemove = sortedEntries.take(_cachedData.length - _maxCacheSize);
        for (final entry in toRemove) {
          _cachedData.remove(entry.key);
          _cacheTimestamps.remove(entry.key);
        }
      }
      
      if (kDebugMode) {
        print('Performance cleanup completed');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error during cleanup: $e');
      }
    }
  }
  
  // Public methods for operation tracking
  void startOperation(String operationId) {
    _operationStartTimes[operationId] = DateTime.now();
  }
  
  void endOperation(String operationId) {
    final startTime = _operationStartTimes[operationId];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      
      _operationDurations.putIfAbsent(operationId, () => []).add(duration);
      
      // Keep only last 10 durations per operation
      final durations = _operationDurations[operationId]!;
      if (durations.length > 10) {
        durations.removeAt(0);
      }
      
      _operationStartTimes.remove(operationId);
    }
  }
  
  // Public methods for cache management
  void addToCache(String key, dynamic data) {
    _cachedData.add(key);
    _cacheTimestamps[key] = DateTime.now();
  }
  
  bool isInCache(String key) {
    return _cachedData.contains(key);
  }
  
  void removeFromCache(String key) {
    _cachedData.remove(key);
    _cacheTimestamps.remove(key);
  }
  
  void clearCache() {
    _cachedData.clear();
    _cacheTimestamps.clear();
  }
  
  // Public methods for settings
  Future<void> updateSettings({
    bool? enableMemoryOptimization,
    bool? enableBatteryOptimization,
    bool? enablePerformanceAlerts,
    double? memoryThreshold,
    double? batteryThreshold,
  }) async {
    if (enableMemoryOptimization != null) {
      _enableMemoryOptimization = enableMemoryOptimization;
    }
    if (enableBatteryOptimization != null) {
      _enableBatteryOptimization = enableBatteryOptimization;
    }
    if (enablePerformanceAlerts != null) {
      _enablePerformanceAlerts = enablePerformanceAlerts;
    }
    if (memoryThreshold != null) {
      _memoryThreshold = memoryThreshold;
    }
    if (batteryThreshold != null) {
      _batteryThreshold = batteryThreshold;
    }
    
    await _saveSettings();
  }
  
  // Public methods for manual optimization
  Future<void> optimizeNow() async {
    await _performOptimizations();
  }
  
  Future<void> clearAllCache() async {
    clearCache();
    await _optimizeImageCache();
  }
  
  Future<void> forceGarbageCollection() async {
    await _triggerGarbageCollection();
  }
  
  // Public methods for alerts
  void dismissAlert(String alertId) {
    _activeAlerts.removeWhere((alert) => alert.id == alertId);
    _alertsController.add(_activeAlerts);
  }
  
  void dismissAllAlerts() {
    _activeAlerts.clear();
    _alertsController.add(_activeAlerts);
  }
  
  // Performance report generation
  PerformanceReport generateReport({
    DateTime? startTime,
    DateTime? endTime,
  }) {
    final now = DateTime.now();
    final start = startTime ?? now.subtract(const Duration(hours: 24));
    final end = endTime ?? now;
    
    final relevantLogs = _performanceLogs
        .where((log) => log.timestamp.isAfter(start) && log.timestamp.isBefore(end))
        .toList();
    
    return PerformanceReport(
      startTime: start,
      endTime: end,
      totalLogs: relevantLogs.length,
      averageMemoryUsage: _calculateAverageMemoryUsage(relevantLogs),
      averageBatteryLevel: _calculateAverageBatteryLevel(relevantLogs),
      averageCPUUsage: _calculateAverageCPUUsage(relevantLogs),
      averageFrameRate: _calculateAverageFrameRate(relevantLogs),
      totalAlerts: relevantLogs.expand((log) => log.alerts).length,
      optimizationsApplied: relevantLogs
          .expand((log) => log.optimizationsApplied)
          .toSet()
          .length,
      recommendations: _generateRecommendations(relevantLogs),
    );
  }
  
  double _calculateAverageMemoryUsage(List<PerformanceLog> logs) {
    if (logs.isEmpty) return 0.0;
    
    final total = logs
        .map((log) => log.metrics.memoryUsage.usagePercentage)
        .reduce((a, b) => a + b);
    
    return total / logs.length;
  }
  
  double _calculateAverageBatteryLevel(List<PerformanceLog> logs) {
    if (logs.isEmpty) return 0.0;
    
    final total = logs
        .map((log) => log.metrics.batteryInfo.level)
        .reduce((a, b) => a + b);
    
    return total / logs.length;
  }
  
  double _calculateAverageCPUUsage(List<PerformanceLog> logs) {
    if (logs.isEmpty) return 0.0;
    
    final total = logs
        .map((log) => log.metrics.cpuUsage)
        .reduce((a, b) => a + b);
    
    return total / logs.length;
  }
  
  double _calculateAverageFrameRate(List<PerformanceLog> logs) {
    if (logs.isEmpty) return 0.0;
    
    final total = logs
        .map((log) => log.metrics.frameRate)
        .reduce((a, b) => a + b);
    
    return total / logs.length;
  }
  
  List<String> _generateRecommendations(List<PerformanceLog> logs) {
    final recommendations = <String>[];
    
    final avgMemory = _calculateAverageMemoryUsage(logs);
    final avgBattery = _calculateAverageBatteryLevel(logs);
    final avgCPU = _calculateAverageCPUUsage(logs);
    final avgFrameRate = _calculateAverageFrameRate(logs);
    
    if (avgMemory > 70.0) {
      recommendations.add('تحسين استخدام الذاكرة - متوسط الاستخدام ${avgMemory.toStringAsFixed(1)}%');
    }
    
    if (avgBattery < 40.0) {
      recommendations.add('تحسين استهلاك البطارية - متوسط المستوى ${avgBattery.toStringAsFixed(1)}%');
    }
    
    if (avgCPU > 60.0) {
      recommendations.add('تحسين استخدام المعالج - متوسط الاستخدام ${avgCPU.toStringAsFixed(1)}%');
    }
    
    if (avgFrameRate < 45.0) {
      recommendations.add('تحسين الأداء الرسومي - متوسط الإطارات ${avgFrameRate.toStringAsFixed(1)} FPS');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('الأداء جيد - لا توجد توصيات خاصة');
    }
    
    return recommendations;
  }
  
  void dispose() {
    _monitoringTimer?.cancel();
    _optimizationTimer?.cancel();
    _cleanupTimer?.cancel();
    
    _metricsController.close();
    _memoryController.close();
    _batteryController.close();
    _alertsController.close();
  }
}