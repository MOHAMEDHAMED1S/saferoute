import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import '../models/report_model.dart';
import 'package:saferoute/services/firebase_schema_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

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
      
      // Load data from Firebase
      await _loadStats();
      await _loadNearbyReportsFromFirebase();
      await _loadWeather();
      await _loadDailyTip();
      await _checkEmergencyAlerts();
      _filteredReports = List.from(
        _nearbyReports,
      ); // Initialize filtered reports
      
      // Save reports to cache after loading from Firebase
      await _saveReportsToCache();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // حفظ البلاغات محلياً
  Future<void> _saveReportsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = _nearbyReports
          .map((report) => jsonEncode({
                'id': report.id,
                'title': report.title,
                'description': report.description,
                'distance': report.distance,
                'timeAgo': report.timeAgo,
                'confirmations': report.confirmations,
                'type': report.type.toString(),
                'latitude': report.latitude,
                'longitude': report.longitude,
              }))
          .toList();
      
      await prefs.setStringList('dashboard_nearby_reports', reportsJson);
      await prefs.setString('dashboard_cache_timestamp', DateTime.now().toIso8601String());
      debugPrint('تم حفظ ${_nearbyReports.length} بلاغ محلياً');
    } catch (e) {
      debugPrint('خطأ في حفظ البلاغات محلياً: $e');
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
            cachedReports.add(NearbyReport(
              id: reportData['id'],
              title: reportData['title'],
              description: reportData['description'],
              distance: reportData['distance'],
              timeAgo: reportData['timeAgo'],
              confirmations: reportData['confirmations'],
              type: _parseReportType(reportData['type']),
              latitude: reportData['latitude'],
              longitude: reportData['longitude'],
            ));
          }
          
          _nearbyReports.clear();
          _nearbyReports.addAll(cachedReports);
          _filteredReports = List.from(_nearbyReports);
          debugPrint('تم تحميل ${cachedReports.length} بلاغ من الذاكرة المحلية');
          notifyListeners();
        } else {
          // إذا انتهت صلاحية التخزين المؤقت، امسح البيانات القديمة
          debugPrint('انتهت صلاحية التخزين المؤقت، سيتم تحميل البيانات من قاعدة البيانات');
          await prefs.remove('dashboard_nearby_reports');
          await prefs.remove('dashboard_cache_timestamp');
        }
      }
    } catch (e) {
      debugPrint('خطأ في تحميل البلاغات المحفوظة: $e');
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

  Future<void> _loadNearbyReportsFromFirebase() async {
    try {
      final firebaseService = FirebaseSchemaService();
      final reportsCollection = firebaseService.reports;

      // Get current location with fallback
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        debugPrint('خطأ في الحصول على الموقع: $e');
        // استخدم موقع افتراضي (الرياض) للاختبار
        position = Position(
          latitude: 24.7136,
          longitude: 46.6753,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      // Query only active reports (excluding removed/deleted ones)
      final querySnapshot = await reportsCollection
          .where('status', isEqualTo: 'active')
          .get();

      debugPrint('عدد البلاغات المسترجعة من Firebase: ${querySnapshot.docs.length}');

      final List<NearbyReport> reports = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final location = data['location'] as Map<String, dynamic>?;
        
        // تحقق من وجود بيانات الموقع
        if (location == null || 
            location['lat'] == null || 
            location['lng'] == null) {
          debugPrint('تخطي البلاغ ${doc.id} - بيانات الموقع مفقودة');
          continue;
        }
        
        final double reportLat = (location['lat'] as num).toDouble();
        final double reportLng = (location['lng'] as num).toDouble();

        // Calculate distance
        final distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          reportLat,
          reportLng,
        );

        // Only include reports within 5km
        if (distanceInMeters <= 5000) {
          // تحقق من وجود البيانات المطلوبة مع قيم افتراضية
          final createdAt = data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now().subtract(const Duration(minutes: 30));
          
          final description = data['description'] as String? ?? 'بلاغ جديد';
          final reportType = data['type'] as String? ?? 'other';
          
          final timeAgo = _getTimeAgo(createdAt);
          final distance = _formatDistance(distanceInMeters);

          reports.add(
            NearbyReport(
              id: doc.id,
              title: '${_getReportTypeNameArabic(reportType)} - ${description.isNotEmpty ? description.substring(0, math.min(20, description.length)) : 'بلاغ'}...',
              description: description,
              distance: distance,
              timeAgo: timeAgo,
              confirmations: (data['verifiedBy'] as List?)?.length ?? 0,
              type: _mapFirebaseTypeToReportType(reportType),
              latitude: reportLat,
              longitude: reportLng,
            ),
          );
        }
      }

      // إذا لم توجد بلاغات، أضف بلاغات تجريبية للاختبار
      if (reports.isEmpty) {
        debugPrint('لا توجد بلاغات في قاعدة البيانات، إضافة بلاغات تجريبية');
        reports.addAll(_createSampleReports(position));
      }

      debugPrint('عدد البلاغات المحملة من Firebase: ${reports.length}');

      // Sort by distance
      reports.sort(
        (a, b) =>
            _parseDistance(a.distance).compareTo(_parseDistance(b.distance)),
      );

      _nearbyReports.clear();
      _nearbyReports.addAll(reports);
    } catch (e) {
      debugPrint('Error loading reports from Firebase: $e');
      // في حالة الخطأ، أضف بلاغات تجريبية
      _nearbyReports.clear();
      _nearbyReports.addAll(_createSampleReports(null));
    }
  }

  // إنشاء بلاغات تجريبية للاختبار
  List<NearbyReport> _createSampleReports(Position? position) {
    final defaultLat = position?.latitude ?? 24.7136;
    final defaultLng = position?.longitude ?? 46.6753;
    
    return [
      NearbyReport(
        id: 'sample_1',
        title: 'حادث مروري - تصادم بسيط',
        description: 'حادث مروري بسيط على الطريق الرئيسي',
        distance: '250م',
        timeAgo: '15 دقيقة',
        confirmations: 3,
        type: ReportType.accident,
        latitude: defaultLat + 0.002,
        longitude: defaultLng + 0.001,
      ),
      NearbyReport(
        id: 'sample_2',
        title: 'ازدحام مروري - زحمة شديدة',
        description: 'ازدحام مروري شديد في الشارع الرئيسي',
        distance: '500م',
        timeAgo: '30 دقيقة',
        confirmations: 5,
        type: ReportType.traffic,
        latitude: defaultLat + 0.004,
        longitude: defaultLng + 0.002,
      ),
      NearbyReport(
        id: 'sample_3',
        title: 'عطل سيارة - سيارة معطلة',
        description: 'سيارة معطلة على جانب الطريق',
        distance: '800م',
        timeAgo: '45 دقيقة',
        confirmations: 2,
        type: ReportType.carBreakdown,
        latitude: defaultLat + 0.006,
        longitude: defaultLng + 0.003,
      ),
      NearbyReport(
        id: 'sample_4',
        title: 'خطر على الطريق - حفرة كبيرة',
        description: 'حفرة كبيرة في منتصف الطريق',
        distance: '1.2كم',
        timeAgo: '1 ساعة',
        confirmations: 4,
        type: ReportType.hazard,
        latitude: defaultLat + 0.008,
        longitude: defaultLng + 0.004,
      ),
    ];
  }
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}م';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}كم';
    }
  }

  double _parseDistance(String distanceStr) {
    if (distanceStr.contains('كم')) {
      return double.parse(distanceStr.replaceAll('كم', '')) * 1000;
    } else {
      return double.parse(distanceStr.replaceAll('م', ''));
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ساعة';
    } else {
      return '${difference.inDays} يوم';
    }
  }

  ReportType _mapFirebaseTypeToReportType(String type) {
    switch (type) {
      case 'accident':
        return ReportType.accident;
      case 'jam':
        return ReportType.jam;
      case 'car_breakdown':
        return ReportType.carBreakdown;
      case 'bump':
        return ReportType.bump;
      case 'closed_road':
        return ReportType.closedRoad;
      case 'hazard':
        return ReportType.hazard;
      case 'police':
        return ReportType.police;
      case 'traffic':
        return ReportType.traffic;
      default:
        return ReportType.other;
    }
  }

  String _getReportTypeNameArabic(String type) {
    switch (type) {
      case 'accident':
        return 'حادث';
      case 'jam':
        return 'ازدحام';
      case 'car_breakdown':
        return 'سيارة معطلة';
      case 'bump':
        return 'مطب';
      case 'closed_road':
        return 'طريق مغلق';
      case 'hazard':
        return 'خطر';
      case 'police':
        return 'شرطة';
      case 'traffic':
        return 'حركة مرور';
      default:
        return 'أخرى';
    }
  }

  Future<void> _loadWeather() async {
    // In a real app, fetch from weather API
    _weather = WeatherInfo(
      condition: 'مشمس',
      temperature: 28,
      visibility: 'ممتازة',
      drivingCondition: 'رؤية ممتازة',
    );
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
      debugPrint('تم مسح البيانات المحفوظة محلياً');
    } catch (e) {
      debugPrint('خطأ في مسح البيانات المحفوظة: $e');
    }
    
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
}
