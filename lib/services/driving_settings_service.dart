import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/driving_settings_model.dart';
import 'driving_firebase_service.dart';

class DrivingSettingsService {
  static final DrivingSettingsService _instance = DrivingSettingsService._internal();
  factory DrivingSettingsService() => _instance;
  DrivingSettingsService._internal();

  static const String _settingsKey = 'driving_settings';
  static const String _profilesKey = 'driving_profiles';
  static const String _currentProfileKey = 'current_profile';
  
  DrivingSettings _currentSettings = const DrivingSettings();
  Map<String, DrivingSettings> _profiles = {};
  String _currentProfileName = 'افتراضي';
  
  // Streams for reactive updates
  final StreamController<DrivingSettings> _settingsController = 
      StreamController<DrivingSettings>.broadcast();
  final StreamController<Map<String, DrivingSettings>> _profilesController = 
      StreamController<Map<String, DrivingSettings>>.broadcast();
  
  // Getters
  Stream<DrivingSettings> get settingsStream => _settingsController.stream;
  Stream<Map<String, DrivingSettings>> get profilesStream => _profilesController.stream;
  DrivingSettings get currentSettings => _currentSettings;
  Map<String, DrivingSettings> get profiles => Map.unmodifiable(_profiles);
  
  // Add missing getters for driving settings screen
  bool get enableVoiceGuidance => _currentSettings.enableVoiceGuidance;
  MapType get mapType => _currentSettings.mapType;
  bool get enableSpeedAlerts => _currentSettings.enableSpeedAlerts;
  bool get enableAccidentAlerts => _currentSettings.enableAccidentAlerts;
  bool get enableTrafficAlerts => _currentSettings.enableTrafficAlerts;
  int get alertDistance => _currentSettings.alertDistance;
  bool get enableReportNotifications => _currentSettings.enableReportNotifications;
  bool get enableEmergencyNotifications => _currentSettings.enableEmergencyNotifications;
  String get currentProfileName => _currentProfileName;
  
  Future<void> initialize() async {
    try {
      await _loadSettings();
      await _loadProfiles();
      await _loadCurrentProfile();
      
      // Create default profiles if none exist
      if (_profiles.isEmpty) {
        await _createDefaultProfiles();
      }
      
    } catch (e) {
      debugPrint('Settings initialization error: $e');
      // Use default settings if loading fails
      _currentSettings = const DrivingSettings();
      await _createDefaultProfiles();
    }
  }
  
  // Add missing methods for driving settings screen
  Future<DrivingSettings> getSettings() async {
    return _currentSettings;
  }
  
  Future<void> saveSettings(DrivingSettings settings) async {
    _currentSettings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    _settingsController.add(_currentSettings);
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    
    if (settingsJson != null) {
      try {
        _currentSettings = DrivingSettings.fromJsonString(settingsJson);
      } catch (e) {
        debugPrint('Error loading settings: $e');
        _currentSettings = const DrivingSettings();
      }
    }
  }
  
  Future<void> _loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getString(_profilesKey);
    
    if (profilesJson != null) {
      try {
        final Map<String, dynamic> profilesMap = jsonDecode(profilesJson);
        _profiles = profilesMap.map(
          (key, value) => MapEntry(key, DrivingSettings.fromJson(value)),
        );
      } catch (e) {
        debugPrint('Error loading profiles: $e');
        _profiles = {};
      }
    }
  }
  
  Future<void> _loadCurrentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _currentProfileName = prefs.getString(_currentProfileKey) ?? 'افتراضي';
    
    // Load settings from current profile if it exists
    if (_profiles.containsKey(_currentProfileName)) {
      _currentSettings = _profiles[_currentProfileName]!;
    }
  }
  
  Future<void> _createDefaultProfiles() async {
    _profiles = {
      'افتراضي': const DrivingSettings(),
      'اقتصادي': DrivingSettings.forMode(DrivingMode.eco),
      'رياضي': DrivingSettings.forMode(DrivingMode.sport),
      'مريح': DrivingSettings.forMode(DrivingMode.comfort),
      'ليلي': DrivingSettings.forMode(DrivingMode.night),
      'مطر': DrivingSettings.forMode(DrivingMode.rain),
      'طريق سريع': DrivingSettings.forMode(DrivingMode.highway),
    };
    
    await _saveProfiles();
    _profilesController.add(_profiles);
  }
  
  Future<void> updateSettings(DrivingSettings settings) async {
    _currentSettings = settings;
    await _saveSettings();
    _settingsController.add(_currentSettings);
    
    // Update current profile with new settings
    if (_profiles.containsKey(_currentProfileName)) {
      _profiles[_currentProfileName] = settings;
      await _saveProfiles();
      _profilesController.add(_profiles);
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, _currentSettings.toJsonString());
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }
  
  Future<void> _saveProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesMap = _profiles.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      await prefs.setString(_profilesKey, jsonEncode(profilesMap));
    } catch (e) {
      debugPrint('Error saving profiles: $e');
    }
  }
  
  Future<void> _saveCurrentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentProfileKey, _currentProfileName);
    } catch (e) {
      debugPrint('Error saving current profile: $e');
    }
  }
  
  // Profile management
  Future<void> switchToProfile(String profileName) async {
    if (_profiles.containsKey(profileName)) {
      _currentProfileName = profileName;
      _currentSettings = _profiles[profileName]!;
      
      await _saveCurrentProfile();
      await _saveSettings();
      
      _settingsController.add(_currentSettings);
    }
  }
  
  Future<void> createProfile(String name, DrivingSettings settings) async {
    _profiles[name] = settings;
    await _saveProfiles();
    _profilesController.add(_profiles);
  }
  
  Future<void> deleteProfile(String name) async {
    if (name == 'افتراضي') {
      throw Exception('Cannot delete default profile');
    }
    
    _profiles.remove(name);
    
    // Switch to default if current profile was deleted
    if (_currentProfileName == name) {
      await switchToProfile('افتراضي');
    }
    
    await _saveProfiles();
    _profilesController.add(_profiles);
  }
  
  Future<void> renameProfile(String oldName, String newName) async {
    if (!_profiles.containsKey(oldName) || oldName == 'افتراضي') {
      throw Exception('Cannot rename this profile');
    }
    
    final settings = _profiles[oldName]!;
    _profiles.remove(oldName);
    _profiles[newName] = settings;
    
    if (_currentProfileName == oldName) {
      _currentProfileName = newName;
      await _saveCurrentProfile();
    }
    
    await _saveProfiles();
    _profilesController.add(_profiles);
  }
  
  // Quick settings updates
  Future<void> updateDrivingMode(DrivingMode mode) async {
    final newSettings = _currentSettings.copyWith(mode: mode);
    await updateSettings(newSettings);
  }
  
  Future<void> updateMapStyle(MapStyle style) async {
    final newSettings = _currentSettings.copyWith(mapStyle: style);
    await updateSettings(newSettings);
  }
  
  Future<void> updateVoiceSettings({
    bool? enabled,
    double? volume,
    double? speed,
    VoiceGender? gender,
    String? language,
  }) async {
    final newSettings = _currentSettings.copyWith(
      voiceEnabled: enabled,
      voiceVolume: volume,
      voiceSpeed: speed,
      voiceGender: gender,
      voiceLanguage: language,
    );
    await updateSettings(newSettings);
  }
  
  Future<void> updateSafetySettings({
    bool? speedWarnings,
    bool? fatigueDetection,
    bool? laneAssist,
    bool? emergencyDetection,
    int? speedThreshold,
    int? fatigueInterval,
  }) async {
    final newSettings = _currentSettings.copyWith(
      speedWarningsEnabled: speedWarnings,
      fatigueDetectionEnabled: fatigueDetection,
      laneAssistEnabled: laneAssist,
      emergencyDetectionEnabled: emergencyDetection,
      speedWarningThreshold: speedThreshold,
      fatigueCheckInterval: fatigueInterval,
    );
    await updateSettings(newSettings);
  }
  
  Future<void> updateNavigationSettings({
    bool? avoidTolls,
    bool? avoidHighways,
    bool? avoidFerries,
    bool? preferFastest,
    bool? showAlternatives,
    int? recalculationSensitivity,
  }) async {
    final newSettings = _currentSettings.copyWith(
      avoidTolls: avoidTolls,
      avoidHighways: avoidHighways,
      avoidFerries: avoidFerries,
      preferFastestRoute: preferFastest,
      showAlternativeRoutes: showAlternatives,
      routeRecalculationSensitivity: recalculationSensitivity,
    );
    await updateSettings(newSettings);
  }
  
  Future<void> updateDisplaySettings({
    bool? showSpeedometer,
    bool? showCompass,
    bool? showWeather,
    bool? showTraffic,
    bool? showPOI,
    bool? nightModeAuto,
    double? brightness,
  }) async {
    final newSettings = _currentSettings.copyWith(
      showSpeedometer: showSpeedometer,
      showCompass: showCompass,
      showWeather: showWeather,
      showTraffic: showTraffic,
      showPOI: showPOI,
      nightModeAuto: nightModeAuto,
      brightness: brightness,
    );
    await updateSettings(newSettings);
  }
  
  Future<void> updateWarningSettings({
    bool? showAccidents,
    bool? showTraffic,
    bool? showSpeedCameras,
    bool? showPolice,
    bool? showRoadwork,
    int? warningDistance,
  }) async {
    final newSettings = _currentSettings.copyWith(
      showAccidentWarnings: showAccidents,
      showTrafficWarnings: showTraffic,
      showSpeedCameraWarnings: showSpeedCameras,
      showPoliceWarnings: showPolice,
      showRoadworkWarnings: showRoadwork,
      warningDistance: warningDistance,
    );
    await updateSettings(newSettings);
  }
  
  Future<void> updatePrivacySettings({
    bool? shareLocation,
    bool? shareTraffic,
    bool? shareIncidents,
    bool? anonymousMode,
  }) async {
    final newSettings = _currentSettings.copyWith(
      shareLocationData: shareLocation,
      shareTrafficData: shareTraffic,
      shareIncidentReports: shareIncidents,
      anonymousMode: anonymousMode,
    );
    await updateSettings(newSettings);
  }
  
  Future<void> updateAdvancedSettings({
    bool? adaptiveInterface,
    bool? learningMode,
    bool? predictiveRouting,
    bool? weatherAdaptation,
    bool? timeBasedOptimization,
  }) async {
    final newSettings = _currentSettings.copyWith(
      adaptiveInterface: adaptiveInterface,
      learningMode: learningMode,
      predictiveRouting: predictiveRouting,
      weatherAdaptation: weatherAdaptation,
      timeBasedOptimization: timeBasedOptimization,
    );
    await updateSettings(newSettings);
  }
  
  Future<void> updateUIVisibilitySettings({
    bool? showFloatingActions,
    bool? showARNavigation,
    bool? showPerformanceMonitor,
    bool? showAIChat,
    bool? showVoiceAssistant,
    bool? showNavigationInfo,
    bool? showBottomControls,
  }) async {
    final newSettings = _currentSettings.copyWith(
      showFloatingActions: showFloatingActions,
      showARNavigation: showARNavigation,
      showPerformanceMonitor: showPerformanceMonitor,
      showAIChat: showAIChat,
      showVoiceAssistant: showVoiceAssistant,
      showNavigationInfo: showNavigationInfo,
      showBottomControls: showBottomControls,
    );
    await updateSettings(newSettings);
  }
  
  // Auto-adaptation based on conditions
  Future<void> adaptToConditions({
    bool? isNight,
    bool? isRaining,
    bool? isHighway,
    double? batteryLevel,
  }) async {
    DrivingSettings adaptedSettings = _currentSettings;
    
    if (isNight == true && _currentSettings.nightModeAuto) {
      adaptedSettings = adaptedSettings.copyWith(
        mapStyle: MapStyle.dark,
        brightness: 0.3,
        fatigueDetectionEnabled: true,
        fatigueCheckInterval: 15,
      );
    }
    
    if (isRaining == true && _currentSettings.weatherAdaptation) {
      adaptedSettings = adaptedSettings.copyWith(
        speedWarningThreshold: 5,
        routeRecalculationSensitivity: 2,
        brightness: 0.9,
      );
    }
    
    if (isHighway == true) {
      adaptedSettings = adaptedSettings.copyWith(
        navigationStyle: NavigationStyle.minimal,
        laneAssistEnabled: true,
        fatigueCheckInterval: 45,
      );
    }
    
    if (batteryLevel != null && batteryLevel < 0.2) {
      // Battery saving mode
      adaptedSettings = adaptedSettings.copyWith(
        brightness: 0.4,
        showPOI: false,
        voiceProactiveAnnouncements: false,
      );
    }
    
    if (adaptedSettings != _currentSettings) {
      await updateSettings(adaptedSettings);
    }
  }
  
  // Reset to defaults
  Future<void> resetToDefaults() async {
    await updateSettings(const DrivingSettings());
  }
  
  Future<void> resetProfile(String profileName) async {
    if (!_profiles.containsKey(profileName)) return;
    
    DrivingSettings defaultSettings;
    switch (profileName) {
      case 'اقتصادي':
        defaultSettings = DrivingSettings.forMode(DrivingMode.eco);
        break;
      case 'رياضي':
        defaultSettings = DrivingSettings.forMode(DrivingMode.sport);
        break;
      case 'مريح':
        defaultSettings = DrivingSettings.forMode(DrivingMode.comfort);
        break;
      case 'ليلي':
        defaultSettings = DrivingSettings.forMode(DrivingMode.night);
        break;
      case 'مطر':
        defaultSettings = DrivingSettings.forMode(DrivingMode.rain);
        break;
      case 'طريق سريع':
        defaultSettings = DrivingSettings.forMode(DrivingMode.highway);
        break;
      default:
        defaultSettings = const DrivingSettings();
    }
    
    _profiles[profileName] = defaultSettings;
    
    if (_currentProfileName == profileName) {
      _currentSettings = defaultSettings;
      await _saveSettings();
      _settingsController.add(_currentSettings);
    }
    
    await _saveProfiles();
    _profilesController.add(_profiles);
  }
  
  // Export/Import settings
  String exportSettings() {
    final exportData = {
      'settings': _currentSettings.toJson(),
      'profiles': _profiles.map((key, value) => MapEntry(key, value.toJson())),
      'currentProfile': _currentProfileName,
      'exportDate': DateTime.now().toIso8601String(),
    };
    return jsonEncode(exportData);
  }
  
  Future<void> importSettings(String jsonData) async {
    try {
      final Map<String, dynamic> importData = jsonDecode(jsonData);
      
      // Import settings
      if (importData.containsKey('settings')) {
        _currentSettings = DrivingSettings.fromJson(importData['settings']);
        await _saveSettings();
        _settingsController.add(_currentSettings);
      }
      
      // Import profiles
      if (importData.containsKey('profiles')) {
        final Map<String, dynamic> profilesData = importData['profiles'];
        _profiles = profilesData.map(
          (key, value) => MapEntry(key, DrivingSettings.fromJson(value)),
        );
        await _saveProfiles();
        _profilesController.add(_profiles);
      }
      
      // Import current profile
      if (importData.containsKey('currentProfile')) {
        _currentProfileName = importData['currentProfile'];
        await _saveCurrentProfile();
      }
      
    } catch (e) {
      debugPrint('Error importing settings: $e');
      throw Exception('فشل في استيراد الإعدادات');
    }
  }
  
  void dispose() {
    _settingsController.close();
    _profilesController.close();
  }
}