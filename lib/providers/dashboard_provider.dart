import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import 'package:saferoute/services/firebase_schema_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class DashboardProvider extends ChangeNotifier {
  DashboardStats _stats = DashboardStats(
    nearbyRisks: 5,
    trustPoints: 850,
    monthlyReports: 23,
    trustLevel: 'مساهم نشط',
  );

  final List<NearbyReport> _nearbyReports = [
    NearbyReport(
      id: '1',
      title: 'حادث - شارع التحرير',
      description: 'حادث مروري بسيط',
      distance: '800م',
      timeAgo: '15 دقيقة',
      confirmations: 12,
      type: ReportType.accident,
      latitude: 30.0444,
      longitude: 31.2357,
    ),
    NearbyReport(
      id: '2',
      title: 'مطب - كوبري أكتوبر',
      description: 'مطب كبير في الطريق',
      distance: '1.2كم',
      timeAgo: '45 دقيقة',
      confirmations: 8,
      type: ReportType.pothole,
      latitude: 30.0626,
      longitude: 31.2497,
    ),
    NearbyReport(
      id: '3',
      title: 'ازدحام - ميدان رمسيس',
      description: 'ازدحام مروري شديد',
      distance: '2كم',
      timeAgo: 'ساعة',
      confirmations: 25,
      type: ReportType.traffic,
      latitude: 30.0626,
      longitude: 31.2497,
    ),
  ];

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
      // Load data from Firebase
      await _loadStats();
      await _loadNearbyReportsFromFirebase();
      await _loadWeather();
      await _loadDailyTip();
      await _checkEmergencyAlerts();
      _filteredReports = List.from(
        _nearbyReports,
      ); // Initialize filtered reports
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
            .where((report) => report.type == ReportType.maintenance)
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

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Query reports within 5km radius
      final querySnapshot = await reportsCollection
          .where('status', isEqualTo: 'verified')
          .get();

      final List<NearbyReport> reports = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final location = data['location'] as Map<String, dynamic>;
        final double reportLat = (location['latitude'] as num).toDouble();
        final double reportLng = (location['longitude'] as num).toDouble();

        // Calculate distance
        final distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          reportLat,
          reportLng,
        );

        // Only include reports within 5km
        if (distanceInMeters <= 5000) {
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          final timeAgo = _getTimeAgo(createdAt);
          final distance = _formatDistance(distanceInMeters);

          reports.add(
            NearbyReport(
              id: doc.id,
              title:
                  '${_getReportTypeNameArabic(data['type'])} - ${data['description'].substring(0, math.min(20, data['description'].length))}...',
              description: data['description'],
              distance: distance,
              timeAgo: timeAgo,
              confirmations: (data['verifiedBy'] as List?)?.length ?? 0,
              type: _mapFirebaseTypeToReportType(data['type']),
              latitude: reportLat,
              longitude: reportLng,
            ),
          );
        }
      }

      // Sort by distance
      reports.sort(
        (a, b) =>
            _parseDistance(a.distance).compareTo(_parseDistance(b.distance)),
      );

      _nearbyReports.clear();
      _nearbyReports.addAll(reports);
    } catch (e) {
      debugPrint('Error loading reports from Firebase: $e');
    }
  }

  // Helper methods for report loading
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
        return ReportType.traffic;
      case 'car_breakdown':
        return ReportType.maintenance;
      case 'bump':
        return ReportType.pothole;
      case 'closed_road':
        return ReportType.roadwork;
      case 'hazard':
        return ReportType.other;
      case 'police':
        return ReportType.other;
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
