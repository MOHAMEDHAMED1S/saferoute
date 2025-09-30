import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/dashboard_models.dart';
import '../models/report_model.dart';
import '../models/nearby_report.dart'; // إضافة استيراد نموذج البلاغات القريبة
import '../models/weather_model.dart'; // إضافة استيراد نموذج الطقس
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async'; // إضافة استيراد dart:async
import '../services/realtime_reports_service.dart'; // إضافة الخدمة الجديدة
import '../services/weather_service.dart'; // إضافة خدمة الطقس
import '../services/location_service.dart'; // إضافة خدمة الموقع
import '../services/logging_service.dart'; // إضافة خدمة التسجيل


class DashboardProvider extends ChangeNotifier {
  DashboardStats _stats = DashboardStats(
    nearbyRisks: 5,
    trustPoints: 850,
    monthlyReports: 23,
    trustLevel: 'مساهم نشط',
  );

  // حذف البيانات الافتراضية
  final List<NearbyReport> _nearbyReports = [];

  WeatherInfo _weather = WeatherInfo(
    condition: 'مشمس',
    temperature: 28,
    visibility: 'ممتازة',
    drivingCondition: 'رؤية ممتازة',
  );

  SafetyTip _dailyTip = SafetyTip(
    id: '1',
    title: 'نصيحة اليوم',
    content: 'تأكد من ضبط المرايا قبل القيادة',
    category: 'سلامة',
    date: DateTime.now(),
  );

  EmergencyAlert? _currentAlert;
  bool _isLoading = false;

  // خدمة البيانات الفورية
  final RealtimeReportsService _realtimeService = RealtimeReportsService();
  StreamSubscription<List<NearbyReport>>? _realtimeSubscription;

  // خدمات الطقس والموقع
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  WeatherData? _currentWeatherData;

  // Constructor - تهيئة الخدمات
  DashboardProvider() {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _weatherService.initialize();
      await _locationService.initialize();
    } catch (e) {
      LoggingService.instance.logError('خطأ في تهيئة الخدمات', e);
    }
  }

  // Getters
  DashboardStats get stats => _stats;
  List<NearbyReport> _filteredReports = [];

  List<NearbyReport> get nearbyReports => _nearbyReports;
  List<NearbyReport> get filteredReports => _filteredReports;
  WeatherInfo get weather => _weather;
  SafetyTip get dailyTip => _dailyTip;
  EmergencyAlert? get currentAlert => _currentAlert;
  bool get isLoading => _isLoading;

  // Methods
  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load cached reports first for immediate display
      await _loadCachedReports();

      // بدء الاستماع للبيانات الفورية دائماً
      await _startRealtimeListening();

      // Load other data from Firebase
      await _loadStats();
      await _loadWeather();
      await _loadDailyTip();
      await _checkEmergencyAlerts();
      _filteredReports = List.from(
        _nearbyReports,
      ); // Initialize filtered reports
    } catch (e) {
      LoggingService.instance.logError('Error loading dashboard data', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// بدء الاستماع للبيانات الفورية
  Future<void> _startRealtimeListening() async {
    try {
      // الحصول على الموقع الحالي
      final position = await _getCurrentPosition();
      if (position == null) {
        LoggingService.instance.logWarning('لا يمكن الحصول على الموقع، سيتم استخدام الموقع الافتراضي');
        return;
      }

      LoggingService.instance.logInfo('بدء الاستماع للبلاغات في الموقع: ${position.latitude}, ${position.longitude}');

      // إلغاء الاشتراك السابق إن وجد
      _realtimeSubscription?.cancel();

      // بدء الاستماع للبلاغات الفورية
      _realtimeService.startListeningToNearbyReports(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 10.0,
      );

      // الاشتراك في stream البلاغات
      _realtimeSubscription = _realtimeService
          .listenToNearbyReports(
            latitude: position.latitude,
            longitude: position.longitude,
            radiusKm: 10.0,
          )
          .listen(
            (reports) {
              LoggingService.instance.logInfo('تم استلام ${reports.length} بلاغ من البيانات الفورية');
              
              _nearbyReports.clear();
              _nearbyReports.addAll(reports);
              _filteredReports = List.from(_nearbyReports);

              // تحديث الإحصائيات
              _updateStatsFromReports(reports);

              // حفظ البيانات محلياً
              _saveReportsToCache(reports);

              notifyListeners();
            },
            onError: (error) {
              LoggingService.instance.logError('خطأ في stream البلاغات الفورية', error);
            },
          );

      // تحديث موقع المستخدم في قاعدة البيانات الفورية
      await _realtimeService.updateUserLocation();
    } catch (e) {
      LoggingService.instance.logError('خطأ في بدء الاستماع للبيانات الفورية', e);
    }
  }

  /// الحصول على الموقع الحالي
  Future<Position?> _getCurrentPosition() async {
    try {
      // استخدام LocationService المحسن
      final position = await _locationService.getCurrentLocation();
      LoggingService.instance.logInfo('تم الحصول على الموقع: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      LoggingService.instance.logError('خطأ في الحصول على الموقع', e);
      
      // محاولة استخدام آخر موقع معروف
      if (!kIsWeb) {
        try {
          final last = await _locationService.getLastKnownPosition();
          if (last != null) {
            LoggingService.instance.logInfo('استخدام آخر موقع معروف: ${last.latitude}, ${last.longitude}');
            return last;
          }
        } catch (_) {}
      }
      
      // موقع افتراضي كحل أخير (القاهرة)
      LoggingService.instance.logWarning('استخدام الموقع الافتراضي');
      return Position(
        latitude: 30.0444,
        longitude: 31.2357,
        timestamp: DateTime.now(),
        accuracy: 1000,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  /// تحديث الإحصائيات من البلاغات
  void _updateStatsFromReports(List<NearbyReport> reports) {
    final activeReports = reports.length;
    _stats = _stats.copyWith(nearbyRisks: activeReports);
  }

  /// حفظ البلاغات في الذاكرة المحلية
  Future<void> _saveReportsToCache(List<NearbyReport> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = reports.map((report) => jsonEncode({
        'id': report.id,
        'title': report.title,
        'description': report.description,
        'distance': report.distance,
        'timeAgo': report.timeAgo,
        'confirmations': report.confirmations,
        'type': report.type.toString(),
        'latitude': report.latitude,
        'longitude': report.longitude,
      })).toList();
      
      await prefs.setStringList('dashboard_nearby_reports', reportsJson);
      await prefs.setString('dashboard_cache_timestamp', DateTime.now().toIso8601String());
      
      LoggingService.instance.logInfo('تم حفظ ${reports.length} بلاغ في الذاكرة المحلية');
    } catch (e) {
      LoggingService.instance.logError('خطأ في حفظ البلاغات محلياً', e);
    }
  }

  // تحميل البلاغات المحفوظة محلياً
  Future<void> _loadCachedReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getStringList('dashboard_nearby_reports');
      final cacheTimestamp = prefs.getString('dashboard_cache_timestamp');

      if (reportsJson != null && cacheTimestamp != null) {
        final cacheTime = DateTime.parse(cacheTimestamp);
        final now = DateTime.now();

        // تقليل وقت التخزين المؤقت إلى 30 ثانية فقط لضمان الحصول على البيانات الحديثة
        if (now.difference(cacheTime).inSeconds < 30) {
          final List<NearbyReport> cachedReports = [];

          for (String reportJson in reportsJson) {
            final Map<String, dynamic> reportData = jsonDecode(reportJson);
            cachedReports.add(
              NearbyReport(
                id: reportData['id'],
                title: reportData['title'],
                description: reportData['description'],
                distance: reportData['distance'],
                timeAgo: reportData['timeAgo'],
                confirmations: reportData['confirmations'],
                type: _parseReportType(reportData['type']),
                latitude: reportData['latitude'],
                longitude: reportData['longitude'],
              ),
            );
          }

          _nearbyReports.clear();
          _nearbyReports.addAll(cachedReports);
          _filteredReports = List.from(_nearbyReports);
          LoggingService.instance.logInfo(
            'تم تحميل ${cachedReports.length} بلاغ من الذاكرة المحلية',
          );
          notifyListeners();
        } else {
          // إذا انتهت صلاحية التخزين المؤقت، امسح البيانات القديمة
          LoggingService.instance.logInfo(
            'انتهت صلاحية التخزين المؤقت، سيتم تحميل البيانات من قاعدة البيانات',
          );
          await prefs.remove('dashboard_nearby_reports');
          await prefs.remove('dashboard_cache_timestamp');
        }
      }
    } catch (e) {
      LoggingService.instance.logError('خطأ في تحميل البلاغات المحفوظة', e);
    }
  }

  // تحويل نص نوع البلاغ إلى enum
  ReportType _parseReportType(String typeString) {
    switch (typeString) {
      case 'ReportType.accident':
        return ReportType.accident;
      case 'ReportType.jam':
        return ReportType.jam;
      case 'ReportType.carBreakdown':
        return ReportType.carBreakdown;
      case 'ReportType.bump':
        return ReportType.bump;
      case 'ReportType.closedRoad':
        return ReportType.closedRoad;
      case 'ReportType.hazard':
        return ReportType.hazard;
      case 'ReportType.police':
        return ReportType.police;
      case 'ReportType.traffic':
        return ReportType.traffic;
      default:
        return ReportType.other;
    }
  }

  void filterReports(String filter) {
    switch (filter) {
      case 'الكل':
        _filteredReports = List.from(_nearbyReports);
        break;
      case '500م':
        _filteredReports = _nearbyReports
            .where(
              (report) =>
                  report.distance.contains('م') &&
                  double.parse(report.distance.replaceAll('م', '')) <= 500,
            )
            .toList();
        break;
      case '1كم':
        _filteredReports = _nearbyReports
            .where(
              (report) =>
                  report.distance.contains('كم') &&
                  double.parse(report.distance.replaceAll('كم', '')) <= 1,
            )
            .toList();
        break;
      case 'حوادث':
        _filteredReports = _nearbyReports
            .where((report) => report.type == ReportType.accident)
            .toList();
        break;
      case 'ازدحام':
        _filteredReports = _nearbyReports
            .where((report) => report.type == ReportType.traffic)
            .toList();
        break;
      case 'صيانة':
        _filteredReports = _nearbyReports
            .where((report) => report.type == ReportType.other)
            .toList();
        break;
      default:
        _filteredReports = List.from(_nearbyReports);
    }
    notifyListeners();
  }

  Future<void> _loadStats() async {
    // In a real app, fetch from Firebase/API
    _stats = DashboardStats(
      nearbyRisks: 5,
      trustPoints: 850,
      monthlyReports: 23,
      trustLevel: 'مساهم نشط',
    );
  }

  Future<void> _loadWeather() async {
    try {
      // الحصول على الموقع الحالي باستخدام الدالة المحلية
      final position = await _getCurrentPosition();
      
      if (position != null) {
        // جلب بيانات الطقس الحقيقية
        _currentWeatherData = await _weatherService.getCurrentWeather(
          position.latitude,
          position.longitude,
        );
        
        // تحويل WeatherData إلى WeatherInfo للتوافق مع الكود الحالي
        _weather = WeatherInfo(
          condition: _currentWeatherData!.description,
          temperature: _currentWeatherData!.temperature.round(),
          visibility: _getVisibilityText(_currentWeatherData!.visibility),
          drivingCondition: _currentWeatherData!.drivingCondition.arabicName,
        );
      } else {
        // في حالة عدم توفر الموقع، لا تعرض بيانات طقس
        _weather = WeatherInfo(
          condition: 'الموقع غير متاح',
          temperature: 0,
          visibility: 'غير محددة',
          drivingCondition: 'غير محدد',
        );
        LoggingService.instance.logWarning('لا يمكن الحصول على الموقع الحالي لجلب بيانات الطقس');
      }
    } catch (e) {
      LoggingService.instance.logError('خطأ في جلب بيانات الطقس', e);
      // في حالة الخطأ، استخدم بيانات افتراضية
      _weather = WeatherInfo(
        condition: 'غير متاح',
        temperature: 25,
        visibility: 'غير متاحة',
        drivingCondition: 'غير متاح',
      );
    }
  }

  String _getVisibilityText(double visibility) {
    if (visibility >= 10000) {
      return 'ممتازة';
    } else if (visibility >= 5000) {
      return 'جيدة';
    } else if (visibility >= 2000) {
      return 'متوسطة';
    } else {
      return 'ضعيفة';
    }
  }

  Future<void> _loadDailyTip() async {
    // In a real app, fetch from Firebase/API
    final tips = [
      'تأكد من ضبط المرايا قبل القيادة',
      'احتفظ بمسافة آمنة من السيارة التي أمامك',
      'تحقق من ضغط الإطارات بانتظام',
      'لا تستخدم الهاتف أثناء القيادة',
      'استخدم الإشارات عند تغيير المسار',
    ];

    final randomTip = tips[DateTime.now().day % tips.length];

    _dailyTip = SafetyTip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'نصيحة اليوم',
      content: randomTip,
      category: 'سلامة',
      date: DateTime.now(),
    );
  }

  Future<void> _checkEmergencyAlerts() async {
    // Show emergency alert only if there are multiple nearby reports
    // or high-risk situations

    if (_nearbyReports.length >= 3) {
      // Check for multiple reports of the same type
      final reportTypes = <ReportType, int>{};
      for (final report in _nearbyReports) {
        reportTypes[report.type] = (reportTypes[report.type] ?? 0) + 1;
      }
      // Show alert if there are multiple reports of dangerous types
      final dangerousTypes = [ReportType.accident];
      for (final type in dangerousTypes) {
        if ((reportTypes[type] ?? 0) >= 2) {
          _currentAlert = EmergencyAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            message: 'تم رصد عدة بلاغات خطيرة في المنطقة المحيطة',
            severity: AlertSeverity.high,
            timestamp: DateTime.now(),
            location: 'المنطقة المحيطة',
            distanceInMeters: 0,
          );
          return;
        }
      }

      // Show alert for high traffic congestion
      if ((reportTypes[ReportType.traffic] ?? 0) >= 2) {
        _currentAlert = EmergencyAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: 'ازدحام مروري شديد في عدة مناطق قريبة',
          severity: AlertSeverity.medium,
          timestamp: DateTime.now(),
          location: 'المنطقة المحيطة',
          distanceInMeters: 0,
        );
        return;
      }
    }

    // No emergency alert needed
    _currentAlert = null;
  }

  void dismissAlert() {
    _currentAlert = null;
    notifyListeners();
  }

  Future<void> refreshData() async {
    // مسح البيانات المحفوظة محلياً لضمان تحميل البيانات الحديثة من قاعدة البيانات
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dashboard_nearby_reports');
      await prefs.remove('dashboard_cache_timestamp');
      LoggingService.instance.logInfo('تم مسح البيانات المحفوظة محلياً');
    } catch (e) {
      LoggingService.instance.logError('خطأ في مسح البيانات المحفوظة', e);
    }

    // بعد مسح الكاش، أعد تشغيل الاستماع الفوري لضمان التحديث
    await loadDashboardData();
  }

  void updateStats({
    int? nearbyRisks,
    int? trustPoints,
    int? monthlyReports,
    String? trustLevel,
  }) {
    _stats = DashboardStats(
      nearbyRisks: nearbyRisks ?? _stats.nearbyRisks,
      trustPoints: trustPoints ?? _stats.trustPoints,
      monthlyReports: monthlyReports ?? _stats.monthlyReports,
      trustLevel: trustLevel ?? _stats.trustLevel,
    );
    notifyListeners();
  }

  void addNearbyReport(NearbyReport report) {
    _nearbyReports.insert(0, report);
    notifyListeners();
  }

  void confirmReport(String reportId) {
    final index = _nearbyReports.indexWhere((report) => report.id == reportId);
    if (index != -1) {
      final report = _nearbyReports[index];
      _nearbyReports[index] = NearbyReport(
        id: report.id,
        title: report.title,
        description: report.description,
        distance: report.distance,
        timeAgo: report.timeAgo,
        confirmations: report.confirmations + 1,
        type: report.type,
        latitude: report.latitude,
        longitude: report.longitude,
      );
      notifyListeners();
    }
  }

  void updateWeather(WeatherInfo newWeather) {
    _weather = newWeather;
    notifyListeners();
  }

  /// تنظيف الموارد عند إغلاق الـ Provider
  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  /// إضافة بلاغ جديد باستخدام البيانات الفورية
  Future<String?> addRealtimeReport({
    required String type,
    required double latitude,
    required double longitude,
    required String description,
    List<String>? imageUrls,
    int priority = 1,
    String? relatedReportId, // إضافة معرف Firestore
  }) async {
    return await _realtimeService.addReport(
      type: type,
      latitude: latitude,
      longitude: longitude,
      description: description,
      imageUrls: imageUrls,
      priority: priority,
      relatedReportId: relatedReportId, // تمرير معرف Firestore
    );
  }

  /// حذف بلاغ باستخدام البيانات الفورية
  Future<bool> deleteRealtimeReport(String reportId) async {
    return await _realtimeService.deleteReport(reportId);
  }

  /// تحديث بلاغ باستخدام البيانات الفورية
  Future<bool> updateRealtimeReport({
    required String reportId,
    String? status,
    int? priority,
  }) async {
    return await _realtimeService.updateReport(
      reportId: reportId,
      status: status,
      priority: priority,
    );
  }
}
