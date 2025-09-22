import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _notificationsKey = 'notifications_enabled';
  static const String _routeAlertsKey = 'route_alerts_enabled';
  static const String _emergencyAlertsKey = 'emergency_alerts_enabled';
  static const String _trafficUpdatesKey = 'traffic_updates_enabled';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  
  static const String _locationSharingKey = 'location_sharing_enabled';
  static const String _dataCollectionKey = 'data_collection_enabled';
  static const String _analyticsKey = 'analytics_enabled';
  static const String _biometricAuthKey = 'biometric_auth_enabled';
  static const String _autoLockKey = 'auto_lock_enabled';
  
  static const String _themeKey = 'app_theme';
  static const String _languageKey = 'app_language';
  static const String _mapStyleKey = 'map_style';
  
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();
  
  SettingsService._();
  
  SharedPreferences? _prefs;
  
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  // Notification Settings
  Future<bool> getNotificationsEnabled() async {
    await init();
    return _prefs?.getBool(_notificationsKey) ?? true;
  }
  
  Future<void> setNotificationsEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(_notificationsKey, enabled);
  }
  
  Future<bool> getRouteAlertsEnabled() async {
    await init();
    return _prefs?.getBool(_routeAlertsKey) ?? true;
  }
  
  Future<void> setRouteAlertsEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(_routeAlertsKey, enabled);
  }
  
  Future<bool> getEmergencyAlertsEnabled() async {
    await init();
    return _prefs?.getBool(_emergencyAlertsKey) ?? true;
  }
  
  Future<void> setEmergencyAlertsEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(_emergencyAlertsKey, enabled);
  }
  
  Future<bool> getTrafficUpdatesEnabled() async {
    await init();
    return _prefs?.getBool(_trafficUpdatesKey) ?? true;
  }
  
  Future<void> setTrafficUpdatesEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(_trafficUpdatesKey, enabled);
  }
  
  Future<bool> getSoundEnabled() async {
    await init();
    return _prefs?.getBool(_soundEnabledKey) ?? true;
  }
  
  Future<void> setSoundEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(_soundEnabledKey, enabled);
  }
  
  Future<bool> getVibrationEnabled() async {
    await init();
    return _prefs?.getBool(_vibrationEnabledKey) ?? true;
  }
  
  Future<void> setVibrationEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(_vibrationEnabledKey, enabled);
  }
  
  // Privacy Settings
  Future<bool> getLocationSharingEnabled() async {
    await init();
    return _prefs?.getBool(_locationSharingKey) ?? false;
  }
  
  Future<void> setLocationSharingEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(_locationSharingKey, enabled);
  }
  
  Future<bool> getDataCollectionEnabled() async {
    await init();
    return _prefs?.getBool(_dataCollectionKey) ?? true;
  }
  
  Future<void> setDataCollectionEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(_dataCollectionKey, enabled);
  }
  
  Future<bool> getAnalyticsEnabled() async {
    await init();
    return _prefs?.getBool(_analyticsKey) ?? true;
  }
  
  Future<void> setAnalyticsEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(_analyticsKey, enabled);
  }
  
  Future<bool> getBiometricAuthEnabled() async {
    await init();
    return _prefs?.getBool(_biometricAuthKey) ?? false;
  }
  
  Future<void> setBiometricAuthEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(_biometricAuthKey, enabled);
  }
  
  Future<bool> getAutoLockEnabled() async {
    await init();
    return _prefs?.getBool(_autoLockKey) ?? false;
  }
  
  Future<void> setAutoLockEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(_autoLockKey, enabled);
  }
  
  // App Settings
  Future<String> getTheme() async {
    await init();
    return _prefs?.getString(_themeKey) ?? 'system';
  }
  
  Future<void> setTheme(String theme) async {
    await init();
    await _prefs?.setString(_themeKey, theme);
  }
  
  Future<String> getLanguage() async {
    await init();
    return _prefs?.getString(_languageKey) ?? 'ar';
  }
  
  Future<void> setLanguage(String language) async {
    await init();
    await _prefs?.setString(_languageKey, language);
  }
  
  Future<String> getMapStyle() async {
    await init();
    return _prefs?.getString(_mapStyleKey) ?? 'standard';
  }
  
  Future<void> setMapStyle(String style) async {
    await init();
    await _prefs?.setString(_mapStyleKey, style);
  }
  
  // Clear all settings
  Future<void> clearAllSettings() async {
    await init();
    await _prefs?.clear();
  }
  
  // Export settings as Map
  Future<Map<String, dynamic>> exportSettings() async {
    await init();
    return {
      'notifications': {
        'enabled': await getNotificationsEnabled(),
        'route_alerts': await getRouteAlertsEnabled(),
        'emergency_alerts': await getEmergencyAlertsEnabled(),
        'traffic_updates': await getTrafficUpdatesEnabled(),
        'sound': await getSoundEnabled(),
        'vibration': await getVibrationEnabled(),
      },
      'privacy': {
        'location_sharing': await getLocationSharingEnabled(),
        'data_collection': await getDataCollectionEnabled(),
        'analytics': await getAnalyticsEnabled(),
        'biometric_auth': await getBiometricAuthEnabled(),
        'auto_lock': await getAutoLockEnabled(),
      },
      'app': {
        'theme': await getTheme(),
        'language': await getLanguage(),
        'map_style': await getMapStyle(),
      },
    };
  }
  
  // Import settings from Map
  Future<void> importSettings(Map<String, dynamic> settings) async {
    await init();
    
    // Import notification settings
    if (settings['notifications'] != null) {
      final notifications = settings['notifications'] as Map<String, dynamic>;
      if (notifications['enabled'] != null) {
        await setNotificationsEnabled(notifications['enabled']);
      }
      if (notifications['route_alerts'] != null) {
        await setRouteAlertsEnabled(notifications['route_alerts']);
      }
      if (notifications['emergency_alerts'] != null) {
        await setEmergencyAlertsEnabled(notifications['emergency_alerts']);
      }
      if (notifications['traffic_updates'] != null) {
        await setTrafficUpdatesEnabled(notifications['traffic_updates']);
      }
      if (notifications['sound'] != null) {
        await setSoundEnabled(notifications['sound']);
      }
      if (notifications['vibration'] != null) {
        await setVibrationEnabled(notifications['vibration']);
      }
    }
    
    // Import privacy settings
    if (settings['privacy'] != null) {
      final privacy = settings['privacy'] as Map<String, dynamic>;
      if (privacy['location_sharing'] != null) {
        await setLocationSharingEnabled(privacy['location_sharing']);
      }
      if (privacy['data_collection'] != null) {
        await setDataCollectionEnabled(privacy['data_collection']);
      }
      if (privacy['analytics'] != null) {
        await setAnalyticsEnabled(privacy['analytics']);
      }
      if (privacy['biometric_auth'] != null) {
        await setBiometricAuthEnabled(privacy['biometric_auth']);
      }
      if (privacy['auto_lock'] != null) {
        await setAutoLockEnabled(privacy['auto_lock']);
      }
    }
    
    // Import app settings
    if (settings['app'] != null) {
      final app = settings['app'] as Map<String, dynamic>;
      if (app['theme'] != null) {
        await setTheme(app['theme']);
      }
      if (app['language'] != null) {
        await setLanguage(app['language']);
      }
      if (app['map_style'] != null) {
        await setMapStyle(app['map_style']);
      }
    }
  }
}