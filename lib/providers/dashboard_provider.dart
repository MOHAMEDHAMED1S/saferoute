import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';

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
  List<NearbyReport> get nearbyReports => _nearbyReports;
  WeatherInfo get weather => _weather;
  SafetyTip get dailyTip => _dailyTip;
  EmergencyAlert? get currentAlert => _currentAlert;
  bool get isLoading => _isLoading;

  // Methods
  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API calls
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real app, you would fetch data from your backend/Firebase
      await _loadStats();
      await _loadNearbyReports();
      await _loadWeather();
      await _loadDailyTip();
      await _checkEmergencyAlerts();
      
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  Future<void> _loadNearbyReports() async {
    // In a real app, fetch from Firebase/API based on user location
    // This is mock data
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
    // In a real app, check for emergency alerts based on user location
    // For demo purposes, we'll randomly show an alert
    if (DateTime.now().minute % 10 == 0) {
      _currentAlert = EmergencyAlert(
        id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
        message: 'حذر! حادث على بعد 300 متر',
        location: 'شارع التحرير',
        distanceInMeters: 300,
        timestamp: DateTime.now(),
        severity: AlertSeverity.high,
      );
    } else {
      _currentAlert = null;
    }
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