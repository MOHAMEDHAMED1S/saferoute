import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings_model.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  
  AppSettingsModel _appSettings = AppSettingsModel.defaultSettings();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // User preferences (stored locally)
  bool _isDarkMode = false;
  String _language = 'ar';
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _alertRadius = 1000;
  bool _locationSharingEnabled = true;
  bool _backgroundLocationEnabled = false;
  int _locationUpdateInterval = 30;
  bool _shareLocationWithOthers = true;
  bool _showInNearbyUsers = true;
  bool _allowReportNotifications = true;
  String _mapStyle = 'normal';
  bool _showTrafficLayer = true;
  bool _showSatelliteView = false;
  double _mapZoomLevel = 15.0;
  bool _autoEnableDriverMode = false;
  int _driverModeSpeedThreshold = 30;
  bool _voiceAlertsEnabled = true;

  // Getters
  AppSettingsModel get appSettings => _appSettings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  // Theme settings
  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Notification settings
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  int get alertRadius => _alertRadius;

  // Location settings
  bool get locationSharingEnabled => _locationSharingEnabled;
  bool get backgroundLocationEnabled => _backgroundLocationEnabled;
  int get locationUpdateInterval => _locationUpdateInterval;

  // Privacy settings
  bool get shareLocationWithOthers => _shareLocationWithOthers;
  bool get showInNearbyUsers => _showInNearbyUsers;
  bool get allowReportNotifications => _allowReportNotifications;

  // Map settings
  String get mapStyle => _mapStyle;
  bool get showTrafficLayer => _showTrafficLayer;
  bool get showSatelliteView => _showSatelliteView;
  double get mapZoomLevel => _mapZoomLevel;

  // Driver mode settings
  bool get autoEnableDriverMode => _autoEnableDriverMode;
  int get driverModeSpeedThreshold => _driverModeSpeedThreshold;
  bool get voiceAlertsEnabled => _voiceAlertsEnabled;

  // Initialize settings provider
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      // Load settings from SharedPreferences
      await _loadSettings();
      
      // Apply loaded settings
      await _applySettings();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحميل الإعدادات: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Load user preferences
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _language = prefs.getString('language') ?? 'ar';
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    _alertRadius = prefs.getInt('alertRadius') ?? 1000;
    _locationSharingEnabled = prefs.getBool('locationSharingEnabled') ?? true;
    _backgroundLocationEnabled = prefs.getBool('backgroundLocationEnabled') ?? false;
    _locationUpdateInterval = prefs.getInt('locationUpdateInterval') ?? 30;
    _shareLocationWithOthers = prefs.getBool('shareLocationWithOthers') ?? true;
    _showInNearbyUsers = prefs.getBool('showInNearbyUsers') ?? true;
    _allowReportNotifications = prefs.getBool('allowReportNotifications') ?? true;
    _mapStyle = prefs.getString('mapStyle') ?? 'normal';
    _showTrafficLayer = prefs.getBool('showTrafficLayer') ?? true;
    _showSatelliteView = prefs.getBool('showSatelliteView') ?? false;
    _mapZoomLevel = prefs.getDouble('mapZoomLevel') ?? 15.0;
    _autoEnableDriverMode = prefs.getBool('autoEnableDriverMode') ?? false;
    _driverModeSpeedThreshold = prefs.getInt('driverModeSpeedThreshold') ?? 30;
    _voiceAlertsEnabled = prefs.getBool('voiceAlertsEnabled') ?? true;
  }

  // Apply settings to services
  Future<void> _applySettings() async {
    try {
      // Apply notification settings
      // TODO: Apply notification settings to service
      // _notificationService.updateNotificationSettings(
      //   enabled: _notificationsEnabled,
      //   sound: _soundEnabled,
      //   vibration: _vibrationEnabled,
      // );
      
      // Apply location settings if needed
      if (_backgroundLocationEnabled) {
        // TODO: Enable background location tracking
      }
    } catch (e) {
      print('Error applying settings: $e');
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Theme settings
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setString('language', _language);
      
      // Notification settings
      await prefs.setBool('notificationsEnabled', _notificationsEnabled);
      await prefs.setBool('soundEnabled', _soundEnabled);
      await prefs.setBool('vibrationEnabled', _vibrationEnabled);
      await prefs.setInt('alertRadius', _alertRadius);
      
      // Location settings
      await prefs.setBool('locationSharingEnabled', _locationSharingEnabled);
      await prefs.setBool('backgroundLocationEnabled', _backgroundLocationEnabled);
      await prefs.setInt('locationUpdateInterval', _locationUpdateInterval);
      
      // Privacy settings
      await prefs.setBool('shareLocationWithOthers', _shareLocationWithOthers);
      await prefs.setBool('showInNearbyUsers', _showInNearbyUsers);
      await prefs.setBool('allowReportNotifications', _allowReportNotifications);
      
      // Map settings
      await prefs.setString('mapStyle', _mapStyle);
      await prefs.setBool('showTrafficLayer', _showTrafficLayer);
      await prefs.setBool('showSatelliteView', _showSatelliteView);
      await prefs.setDouble('mapZoomLevel', _mapZoomLevel);
      
      // Driver mode settings
      await prefs.setBool('autoEnableDriverMode', _autoEnableDriverMode);
      await prefs.setInt('driverModeSpeedThreshold', _driverModeSpeedThreshold);
      await prefs.setBool('voiceAlertsEnabled', _voiceAlertsEnabled);
    } catch (e) {
      _setError('خطأ في حفظ الإعدادات: ${e.toString()}');
    }
  }

  // Update theme settings
  Future<void> updateThemeSettings({
    bool? isDarkMode,
    String? language,
  }) async {
    try {
      if (isDarkMode != null) _isDarkMode = isDarkMode;
      if (language != null) _language = language;
      
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحديث إعدادات المظهر: ${e.toString()}');
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings({
    bool? enabled,
    bool? sound,
    bool? vibration,
    int? alertRadius,
  }) async {
    try {
      if (enabled != null) _notificationsEnabled = enabled;
      if (sound != null) _soundEnabled = sound;
      if (vibration != null) _vibrationEnabled = vibration;
      if (alertRadius != null) _alertRadius = alertRadius;
      
      // Apply notification settings
      // TODO: Apply notification settings to service
      // _notificationService.updateNotificationSettings(
      //   enabled: _notificationsEnabled,
      //   sound: _soundEnabled,
      //   vibration: _vibrationEnabled,
      // );
      
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحديث إعدادات الإشعارات: ${e.toString()}');
    }
  }

  // Update location settings
  Future<void> updateLocationSettings({
    bool? locationSharingEnabled,
    bool? backgroundLocationEnabled,
    int? locationUpdateInterval,
  }) async {
    try {
      if (locationSharingEnabled != null) _locationSharingEnabled = locationSharingEnabled;
      if (backgroundLocationEnabled != null) _backgroundLocationEnabled = backgroundLocationEnabled;
      if (locationUpdateInterval != null) _locationUpdateInterval = locationUpdateInterval;
      
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحديث إعدادات الموقع: ${e.toString()}');
    }
  }

  // Update privacy settings
  Future<void> updatePrivacySettings({
    bool? shareLocationWithOthers,
    bool? showInNearbyUsers,
    bool? allowReportNotifications,
  }) async {
    try {
      if (shareLocationWithOthers != null) _shareLocationWithOthers = shareLocationWithOthers;
      if (showInNearbyUsers != null) _showInNearbyUsers = showInNearbyUsers;
      if (allowReportNotifications != null) _allowReportNotifications = allowReportNotifications;
      
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحديث إعدادات الخصوصية: ${e.toString()}');
    }
  }

  // Update map settings
  Future<void> updateMapSettings({
    String? mapStyle,
    bool? showTrafficLayer,
    bool? showSatelliteView,
    double? mapZoomLevel,
  }) async {
    try {
      if (mapStyle != null) _mapStyle = mapStyle;
      if (showTrafficLayer != null) _showTrafficLayer = showTrafficLayer;
      if (showSatelliteView != null) _showSatelliteView = showSatelliteView;
      if (mapZoomLevel != null) _mapZoomLevel = mapZoomLevel;
      
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحديث إعدادات الخريطة: ${e.toString()}');
    }
  }

  // Update driver mode settings
  Future<void> updateDriverModeSettings({
    bool? autoEnableDriverMode,
    int? driverModeSpeedThreshold,
    bool? voiceAlertsEnabled,
  }) async {
    try {
      if (autoEnableDriverMode != null) _autoEnableDriverMode = autoEnableDriverMode;
      if (driverModeSpeedThreshold != null) _driverModeSpeedThreshold = driverModeSpeedThreshold;
      if (voiceAlertsEnabled != null) _voiceAlertsEnabled = voiceAlertsEnabled;
      
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحديث إعدادات وضع السائق: ${e.toString()}');
    }
  }

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    await updateThemeSettings(isDarkMode: !_isDarkMode);
  }

  // Toggle notifications
  Future<void> toggleNotifications() async {
    await updateNotificationSettings(enabled: !_notificationsEnabled);
  }

  // Toggle location sharing
  Future<void> toggleLocationSharing() async {
    await updateLocationSettings(locationSharingEnabled: !_locationSharingEnabled);
  }

  // Reset settings to default
  Future<void> resetToDefaults() async {
    try {
      _setLoading(true);
      
      _isDarkMode = false;
      _language = 'ar';
      _notificationsEnabled = true;
      _soundEnabled = true;
      _vibrationEnabled = true;
      _alertRadius = 1000;
      _locationSharingEnabled = true;
      _backgroundLocationEnabled = false;
      _locationUpdateInterval = 30;
      _shareLocationWithOthers = true;
      _showInNearbyUsers = true;
      _allowReportNotifications = true;
      _mapStyle = 'normal';
      _showTrafficLayer = true;
      _showSatelliteView = false;
      _mapZoomLevel = 15.0;
      _autoEnableDriverMode = false;
      _driverModeSpeedThreshold = 30;
      _voiceAlertsEnabled = true;
      
      await _saveSettings();
      await _applySettings();
      
      notifyListeners();
    } catch (e) {
      _setError('خطأ في إعادة تعيين الإعدادات: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Export settings
  Map<String, dynamic> exportSettings() {
    return {
      'isDarkMode': _isDarkMode,
      'language': _language,
      'notificationsEnabled': _notificationsEnabled,
      'soundEnabled': _soundEnabled,
      'vibrationEnabled': _vibrationEnabled,
      'alertRadius': _alertRadius,
      'locationSharingEnabled': _locationSharingEnabled,
      'backgroundLocationEnabled': _backgroundLocationEnabled,
      'locationUpdateInterval': _locationUpdateInterval,
      'shareLocationWithOthers': _shareLocationWithOthers,
      'showInNearbyUsers': _showInNearbyUsers,
      'allowReportNotifications': _allowReportNotifications,
      'mapStyle': _mapStyle,
      'showTrafficLayer': _showTrafficLayer,
      'showSatelliteView': _showSatelliteView,
      'mapZoomLevel': _mapZoomLevel,
      'autoEnableDriverMode': _autoEnableDriverMode,
      'driverModeSpeedThreshold': _driverModeSpeedThreshold,
      'voiceAlertsEnabled': _voiceAlertsEnabled,
    };
  }

  // Import settings
  Future<void> importSettings(Map<String, dynamic> settingsData) async {
    try {
      _setLoading(true);
      
      _isDarkMode = settingsData['isDarkMode'] ?? false;
      _language = settingsData['language'] ?? 'ar';
      _notificationsEnabled = settingsData['notificationsEnabled'] ?? true;
      _soundEnabled = settingsData['soundEnabled'] ?? true;
      _vibrationEnabled = settingsData['vibrationEnabled'] ?? true;
      _alertRadius = settingsData['alertRadius'] ?? 1000;
      _locationSharingEnabled = settingsData['locationSharingEnabled'] ?? true;
      _backgroundLocationEnabled = settingsData['backgroundLocationEnabled'] ?? false;
      _locationUpdateInterval = settingsData['locationUpdateInterval'] ?? 30;
      _shareLocationWithOthers = settingsData['shareLocationWithOthers'] ?? true;
      _showInNearbyUsers = settingsData['showInNearbyUsers'] ?? true;
      _allowReportNotifications = settingsData['allowReportNotifications'] ?? true;
      _mapStyle = settingsData['mapStyle'] ?? 'normal';
      _showTrafficLayer = settingsData['showTrafficLayer'] ?? true;
      _showSatelliteView = settingsData['showSatelliteView'] ?? false;
      _mapZoomLevel = settingsData['mapZoomLevel'] ?? 15.0;
      _autoEnableDriverMode = settingsData['autoEnableDriverMode'] ?? false;
      _driverModeSpeedThreshold = settingsData['driverModeSpeedThreshold'] ?? 30;
      _voiceAlertsEnabled = settingsData['voiceAlertsEnabled'] ?? true;
      
      await _saveSettings();
      await _applySettings();
      
      notifyListeners();
    } catch (e) {
      _setError('خطأ في استيراد الإعدادات: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Get available languages
  List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'ar', 'name': 'العربية'},
      {'code': 'en', 'name': 'English'},
    ];
  }

  // Get available map styles
  List<Map<String, String>> getAvailableMapStyles() {
    return [
      {'code': 'normal', 'name': 'عادي'},
      {'code': 'satellite', 'name': 'قمر صناعي'},
      {'code': 'terrain', 'name': 'تضاريس'},
      {'code': 'hybrid', 'name': 'مختلط'},
    ];
  }

  // Get alert radius options
  List<Map<String, dynamic>> getAlertRadiusOptions() {
    return [
      {'value': 500, 'label': '500 متر'},
      {'value': 1000, 'label': '1 كيلومتر'},
      {'value': 2000, 'label': '2 كيلومتر'},
      {'value': 5000, 'label': '5 كيلومتر'},
    ];
  }

  // Get location update interval options
  List<Map<String, dynamic>> getLocationUpdateIntervalOptions() {
    return [
      {'value': 10, 'label': '10 ثواني'},
      {'value': 30, 'label': '30 ثانية'},
      {'value': 60, 'label': 'دقيقة واحدة'},
      {'value': 300, 'label': '5 دقائق'},
    ];
  }

  // Check and request location permissions
  Future<bool> checkAndRequestLocationPermissions() async {
    try {
      return await _locationService.checkAndRequestPermissions();
    } catch (e) {
      _setError('خطأ في فحص وطلب أذونات الموقع: ${e.toString()}');
      return false;
    }
  }

  // Check if notification permission is granted
  Future<bool> checkNotificationPermission() async {
    return await _notificationService.requestPermissions();
  }

  // Validate settings
  bool validateSettings() {
    // Check alert radius
    if (_alertRadius < 100 || _alertRadius > 10000) {
      return false;
    }
    
    // Check location update interval
    if (_locationUpdateInterval < 5 || _locationUpdateInterval > 3600) {
      return false;
    }
    
    // Check map zoom level
    if (_mapZoomLevel < 1.0 || _mapZoomLevel > 20.0) {
      return false;
    }
    
    // Check driver mode speed threshold
    if (_driverModeSpeedThreshold < 10 || _driverModeSpeedThreshold > 200) {
      return false;
    }
    
    return true;
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _appSettings = AppSettingsModel.defaultSettings();
    _isDarkMode = false;
    _language = 'ar';
    _notificationsEnabled = true;
    _soundEnabled = true;
    _vibrationEnabled = true;
    _alertRadius = 1000;
    _locationSharingEnabled = true;
    _backgroundLocationEnabled = false;
    _locationUpdateInterval = 30;
    _shareLocationWithOthers = true;
    _showInNearbyUsers = true;
    _allowReportNotifications = true;
    _mapStyle = 'normal';
    _showTrafficLayer = true;
    _showSatelliteView = false;
    _mapZoomLevel = 15.0;
    _autoEnableDriverMode = false;
    _driverModeSpeedThreshold = 30;
    _voiceAlertsEnabled = true;
    _isLoading = false;
    _errorMessage = null;
    _isInitialized = false;
    notifyListeners();
  }
}