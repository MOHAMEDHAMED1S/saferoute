import 'dart:convert';

enum DrivingMode {
  normal,
  eco,
  sport,
  comfort,
  night,
  rain,
  highway
}

enum SpeedUnit {
  kmh,
  mph
}

enum DistanceUnit {
  km,
  miles
}

enum VoiceGender {
  male,
  female
}

enum MapStyle {
  standard,
  satellite,
  hybrid,
  terrain,
  dark,
  retro
}

enum NavigationStyle {
  minimal,
  detailed,
  voiceOnly
}

class DrivingSettings {
  final DrivingMode mode;
  final SpeedUnit speedUnit;
  final DistanceUnit distanceUnit;
  final VoiceGender voiceGender;
  final MapStyle mapStyle;
  final NavigationStyle navigationStyle;
  
  // Display preferences
  final bool showSpeedometer;
  final bool showCompass;
  final bool showWeather;
  final bool showTraffic;
  final bool showPOI;
  final bool nightModeAuto;
  final double brightness;
  
  // Safety preferences
  final bool speedWarningsEnabled;
  final bool fatigueDetectionEnabled;
  final bool laneAssistEnabled;
  final bool emergencyDetectionEnabled;
  final int speedWarningThreshold; // km/h over limit
  final int fatigueCheckInterval; // minutes
  
  // Voice preferences
  final bool voiceEnabled;
  final bool voiceProactiveAnnouncements;
  final double voiceVolume;
  final double voiceSpeed;
  final String voiceLanguage;
  
  // Navigation preferences
  final bool avoidTolls;
  final bool avoidHighways;
  final bool avoidFerries;
  final bool preferFastestRoute;
  final bool showAlternativeRoutes;
  final int routeRecalculationSensitivity; // 1-5
  
  // Warning preferences
  final bool showAccidentWarnings;
  final bool showTrafficWarnings;
  final bool showSpeedCameraWarnings;
  final bool showPoliceWarnings;
  final bool showRoadworkWarnings;
  final int warningDistance; // meters
  
  // Privacy preferences
  final bool shareLocationData;
  final bool shareTrafficData;
  final bool shareIncidentReports;
  final bool anonymousMode;
  
  // Advanced preferences
  final bool adaptiveInterface;
  final bool learningMode;
  final bool predictiveRouting;
  final bool weatherAdaptation;
  final bool timeBasedOptimization;
  
  // UI Element visibility preferences
  final bool showFloatingActions;
  final bool showARNavigation;
  final bool showPerformanceMonitor;
  final bool showAIChat;
  final bool showVoiceAssistant;
  final bool showNavigationInfo;
  final bool showBottomControls;
  
  const DrivingSettings({
    this.mode = DrivingMode.normal,
    this.speedUnit = SpeedUnit.kmh,
    this.distanceUnit = DistanceUnit.km,
    this.voiceGender = VoiceGender.female,
    this.mapStyle = MapStyle.standard,
    this.navigationStyle = NavigationStyle.detailed,
    
    // Display defaults
    this.showSpeedometer = true,
    this.showCompass = true,
    this.showWeather = true,
    this.showTraffic = true,
    this.showPOI = false,
    this.nightModeAuto = true,
    this.brightness = 0.8,
    
    // Safety defaults
    this.speedWarningsEnabled = true,
    this.fatigueDetectionEnabled = true,
    this.laneAssistEnabled = false,
    this.emergencyDetectionEnabled = true,
    this.speedWarningThreshold = 10,
    this.fatigueCheckInterval = 30,
    
    // Voice defaults
    this.voiceEnabled = true,
    this.voiceProactiveAnnouncements = true,
    this.voiceVolume = 0.8,
    this.voiceSpeed = 0.8,
    this.voiceLanguage = 'ar-SA',
    
    // Navigation defaults
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.avoidFerries = true,
    this.preferFastestRoute = true,
    this.showAlternativeRoutes = true,
    this.routeRecalculationSensitivity = 3,
    
    // Warning defaults
    this.showAccidentWarnings = true,
    this.showTrafficWarnings = true,
    this.showSpeedCameraWarnings = true,
    this.showPoliceWarnings = true,
    this.showRoadworkWarnings = true,
    this.warningDistance = 1000,
    
    // Privacy defaults
    this.shareLocationData = true,
    this.shareTrafficData = true,
    this.shareIncidentReports = true,
    this.anonymousMode = false,
    
    // Advanced defaults
    this.adaptiveInterface = true,
    this.learningMode = true,
    this.predictiveRouting = true,
    this.weatherAdaptation = true,
    this.timeBasedOptimization = true,
    
    // UI Element visibility defaults
    this.showFloatingActions = true,
    this.showARNavigation = true,
    this.showPerformanceMonitor = true,
    this.showAIChat = true,
    this.showVoiceAssistant = true,
    this.showNavigationInfo = true,
    this.showBottomControls = true,
  });
  
  // Create settings for specific driving modes
  factory DrivingSettings.forMode(DrivingMode mode) {
    switch (mode) {
      case DrivingMode.eco:
        return const DrivingSettings(
          mode: DrivingMode.eco,
          preferFastestRoute: false,
          speedWarningThreshold: 5,
          voiceProactiveAnnouncements: false,
          brightness: 0.6,
        );
      case DrivingMode.sport:
        return const DrivingSettings(
          mode: DrivingMode.sport,
          mapStyle: MapStyle.satellite,
          speedWarningThreshold: 20,
          routeRecalculationSensitivity: 5,
          brightness: 1.0,
        );
      case DrivingMode.comfort:
        return const DrivingSettings(
          mode: DrivingMode.comfort,
          navigationStyle: NavigationStyle.voiceOnly,
          fatigueCheckInterval: 20,
          voiceVolume: 0.6,
          brightness: 0.7,
        );
      case DrivingMode.night:
        return const DrivingSettings(
          mode: DrivingMode.night,
          mapStyle: MapStyle.dark,
          brightness: 0.3,
          fatigueDetectionEnabled: true,
          fatigueCheckInterval: 15,
          voiceProactiveAnnouncements: true,
        );
      case DrivingMode.rain:
        return const DrivingSettings(
          mode: DrivingMode.rain,
          speedWarningThreshold: 5,
          routeRecalculationSensitivity: 2,
          weatherAdaptation: true,
          brightness: 0.9,
        );
      case DrivingMode.highway:
        return const DrivingSettings(
          mode: DrivingMode.highway,
          navigationStyle: NavigationStyle.minimal,
          fatigueCheckInterval: 45,
          laneAssistEnabled: true,
          speedWarningThreshold: 15,
        );
      default:
        return const DrivingSettings();
    }
  }
  
  DrivingSettings copyWith({
    DrivingMode? mode,
    SpeedUnit? speedUnit,
    DistanceUnit? distanceUnit,
    VoiceGender? voiceGender,
    MapStyle? mapStyle,
    NavigationStyle? navigationStyle,
    bool? showSpeedometer,
    bool? showCompass,
    bool? showWeather,
    bool? showTraffic,
    bool? showPOI,
    bool? nightModeAuto,
    double? brightness,
    bool? speedWarningsEnabled,
    bool? fatigueDetectionEnabled,
    bool? laneAssistEnabled,
    bool? emergencyDetectionEnabled,
    int? speedWarningThreshold,
    int? fatigueCheckInterval,
    bool? voiceEnabled,
    bool? voiceProactiveAnnouncements,
    double? voiceVolume,
    double? voiceSpeed,
    String? voiceLanguage,
    bool? avoidTolls,
    bool? avoidHighways,
    bool? avoidFerries,
    bool? preferFastestRoute,
    bool? showAlternativeRoutes,
    int? routeRecalculationSensitivity,
    bool? showAccidentWarnings,
    bool? showTrafficWarnings,
    bool? showSpeedCameraWarnings,
    bool? showPoliceWarnings,
    bool? showRoadworkWarnings,
    int? warningDistance,
    bool? shareLocationData,
    bool? shareTrafficData,
    bool? shareIncidentReports,
    bool? anonymousMode,
    bool? adaptiveInterface,
    bool? learningMode,
    bool? predictiveRouting,
    bool? weatherAdaptation,
    bool? timeBasedOptimization,
    // UI visibility
    bool? showFloatingActions,
    bool? showARNavigation,
    bool? showPerformanceMonitor,
    bool? showAIChat,
    bool? showVoiceAssistant,
    bool? showNavigationInfo,
    bool? showBottomControls,
  }) {
    return DrivingSettings(
      mode: mode ?? this.mode,
      speedUnit: speedUnit ?? this.speedUnit,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      voiceGender: voiceGender ?? this.voiceGender,
      mapStyle: mapStyle ?? this.mapStyle,
      navigationStyle: navigationStyle ?? this.navigationStyle,
      showSpeedometer: showSpeedometer ?? this.showSpeedometer,
      showCompass: showCompass ?? this.showCompass,
      showWeather: showWeather ?? this.showWeather,
      showTraffic: showTraffic ?? this.showTraffic,
      showPOI: showPOI ?? this.showPOI,
      nightModeAuto: nightModeAuto ?? this.nightModeAuto,
      brightness: brightness ?? this.brightness,
      speedWarningsEnabled: speedWarningsEnabled ?? this.speedWarningsEnabled,
      fatigueDetectionEnabled: fatigueDetectionEnabled ?? this.fatigueDetectionEnabled,
      laneAssistEnabled: laneAssistEnabled ?? this.laneAssistEnabled,
      emergencyDetectionEnabled: emergencyDetectionEnabled ?? this.emergencyDetectionEnabled,
      speedWarningThreshold: speedWarningThreshold ?? this.speedWarningThreshold,
      fatigueCheckInterval: fatigueCheckInterval ?? this.fatigueCheckInterval,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      voiceProactiveAnnouncements: voiceProactiveAnnouncements ?? this.voiceProactiveAnnouncements,
      voiceVolume: voiceVolume ?? this.voiceVolume,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      avoidTolls: avoidTolls ?? this.avoidTolls,
      avoidHighways: avoidHighways ?? this.avoidHighways,
      avoidFerries: avoidFerries ?? this.avoidFerries,
      preferFastestRoute: preferFastestRoute ?? this.preferFastestRoute,
      showAlternativeRoutes: showAlternativeRoutes ?? this.showAlternativeRoutes,
      routeRecalculationSensitivity: routeRecalculationSensitivity ?? this.routeRecalculationSensitivity,
      showAccidentWarnings: showAccidentWarnings ?? this.showAccidentWarnings,
      showTrafficWarnings: showTrafficWarnings ?? this.showTrafficWarnings,
      showSpeedCameraWarnings: showSpeedCameraWarnings ?? this.showSpeedCameraWarnings,
      showPoliceWarnings: showPoliceWarnings ?? this.showPoliceWarnings,
      showRoadworkWarnings: showRoadworkWarnings ?? this.showRoadworkWarnings,
      warningDistance: warningDistance ?? this.warningDistance,
      shareLocationData: shareLocationData ?? this.shareLocationData,
      shareTrafficData: shareTrafficData ?? this.shareTrafficData,
      shareIncidentReports: shareIncidentReports ?? this.shareIncidentReports,
      anonymousMode: anonymousMode ?? this.anonymousMode,
      adaptiveInterface: adaptiveInterface ?? this.adaptiveInterface,
      learningMode: learningMode ?? this.learningMode,
      predictiveRouting: predictiveRouting ?? this.predictiveRouting,
      weatherAdaptation: weatherAdaptation ?? this.weatherAdaptation,
      timeBasedOptimization: timeBasedOptimization ?? this.timeBasedOptimization,
      showFloatingActions: showFloatingActions ?? this.showFloatingActions,
      showARNavigation: showARNavigation ?? this.showARNavigation,
      showPerformanceMonitor: showPerformanceMonitor ?? this.showPerformanceMonitor,
      showAIChat: showAIChat ?? this.showAIChat,
      showVoiceAssistant: showVoiceAssistant ?? this.showVoiceAssistant,
      showNavigationInfo: showNavigationInfo ?? this.showNavigationInfo,
      showBottomControls: showBottomControls ?? this.showBottomControls,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'speedUnit': speedUnit.name,
      'distanceUnit': distanceUnit.name,
      'voiceGender': voiceGender.name,
      'mapStyle': mapStyle.name,
      'navigationStyle': navigationStyle.name,
      'showSpeedometer': showSpeedometer,
      'showCompass': showCompass,
      'showWeather': showWeather,
      'showTraffic': showTraffic,
      'showPOI': showPOI,
      'nightModeAuto': nightModeAuto,
      'brightness': brightness,
      'speedWarningsEnabled': speedWarningsEnabled,
      'fatigueDetectionEnabled': fatigueDetectionEnabled,
      'laneAssistEnabled': laneAssistEnabled,
      'emergencyDetectionEnabled': emergencyDetectionEnabled,
      'speedWarningThreshold': speedWarningThreshold,
      'fatigueCheckInterval': fatigueCheckInterval,
      'voiceEnabled': voiceEnabled,
      'voiceProactiveAnnouncements': voiceProactiveAnnouncements,
      'voiceVolume': voiceVolume,
      'voiceSpeed': voiceSpeed,
      'voiceLanguage': voiceLanguage,
      'avoidTolls': avoidTolls,
      'avoidHighways': avoidHighways,
      'avoidFerries': avoidFerries,
      'preferFastestRoute': preferFastestRoute,
      'showAlternativeRoutes': showAlternativeRoutes,
      'routeRecalculationSensitivity': routeRecalculationSensitivity,
      'showAccidentWarnings': showAccidentWarnings,
      'showTrafficWarnings': showTrafficWarnings,
      'showSpeedCameraWarnings': showSpeedCameraWarnings,
      'showPoliceWarnings': showPoliceWarnings,
      'showRoadworkWarnings': showRoadworkWarnings,
      'warningDistance': warningDistance,
      'shareLocationData': shareLocationData,
      'shareTrafficData': shareTrafficData,
      'shareIncidentReports': shareIncidentReports,
      'anonymousMode': anonymousMode,
      'adaptiveInterface': adaptiveInterface,
      'learningMode': learningMode,
      'predictiveRouting': predictiveRouting,
      'weatherAdaptation': weatherAdaptation,
      'timeBasedOptimization': timeBasedOptimization,
    };
  }
  
  factory DrivingSettings.fromJson(Map<String, dynamic> json) {
    return DrivingSettings(
      mode: DrivingMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => DrivingMode.normal,
      ),
      speedUnit: SpeedUnit.values.firstWhere(
        (e) => e.name == json['speedUnit'],
        orElse: () => SpeedUnit.kmh,
      ),
      distanceUnit: DistanceUnit.values.firstWhere(
        (e) => e.name == json['distanceUnit'],
        orElse: () => DistanceUnit.km,
      ),
      voiceGender: VoiceGender.values.firstWhere(
        (e) => e.name == json['voiceGender'],
        orElse: () => VoiceGender.female,
      ),
      mapStyle: MapStyle.values.firstWhere(
        (e) => e.name == json['mapStyle'],
        orElse: () => MapStyle.standard,
      ),
      navigationStyle: NavigationStyle.values.firstWhere(
        (e) => e.name == json['navigationStyle'],
        orElse: () => NavigationStyle.detailed,
      ),
      showSpeedometer: json['showSpeedometer'] ?? true,
      showCompass: json['showCompass'] ?? true,
      showWeather: json['showWeather'] ?? true,
      showTraffic: json['showTraffic'] ?? true,
      showPOI: json['showPOI'] ?? false,
      nightModeAuto: json['nightModeAuto'] ?? true,
      brightness: (json['brightness'] ?? 0.8).toDouble(),
      speedWarningsEnabled: json['speedWarningsEnabled'] ?? true,
      fatigueDetectionEnabled: json['fatigueDetectionEnabled'] ?? true,
      laneAssistEnabled: json['laneAssistEnabled'] ?? false,
      emergencyDetectionEnabled: json['emergencyDetectionEnabled'] ?? true,
      speedWarningThreshold: json['speedWarningThreshold'] ?? 10,
      fatigueCheckInterval: json['fatigueCheckInterval'] ?? 30,
      voiceEnabled: json['voiceEnabled'] ?? true,
      voiceProactiveAnnouncements: json['voiceProactiveAnnouncements'] ?? true,
      voiceVolume: (json['voiceVolume'] ?? 0.8).toDouble(),
      voiceSpeed: (json['voiceSpeed'] ?? 0.8).toDouble(),
      voiceLanguage: json['voiceLanguage'] ?? 'ar-SA',
      avoidTolls: json['avoidTolls'] ?? false,
      avoidHighways: json['avoidHighways'] ?? false,
      avoidFerries: json['avoidFerries'] ?? true,
      preferFastestRoute: json['preferFastestRoute'] ?? true,
      showAlternativeRoutes: json['showAlternativeRoutes'] ?? true,
      routeRecalculationSensitivity: json['routeRecalculationSensitivity'] ?? 3,
      showAccidentWarnings: json['showAccidentWarnings'] ?? true,
      showTrafficWarnings: json['showTrafficWarnings'] ?? true,
      showSpeedCameraWarnings: json['showSpeedCameraWarnings'] ?? true,
      showPoliceWarnings: json['showPoliceWarnings'] ?? true,
      showRoadworkWarnings: json['showRoadworkWarnings'] ?? true,
      warningDistance: json['warningDistance'] ?? 1000,
      shareLocationData: json['shareLocationData'] ?? true,
      shareTrafficData: json['shareTrafficData'] ?? true,
      shareIncidentReports: json['shareIncidentReports'] ?? true,
      anonymousMode: json['anonymousMode'] ?? false,
      adaptiveInterface: json['adaptiveInterface'] ?? true,
      learningMode: json['learningMode'] ?? true,
      predictiveRouting: json['predictiveRouting'] ?? true,
      weatherAdaptation: json['weatherAdaptation'] ?? true,
      timeBasedOptimization: json['timeBasedOptimization'] ?? true,
    );
  }
  
  String toJsonString() => jsonEncode(toJson());
  
  factory DrivingSettings.fromJsonString(String jsonString) {
    return DrivingSettings.fromJson(jsonDecode(jsonString));
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrivingSettings &&
        other.mode == mode &&
        other.speedUnit == speedUnit &&
        other.distanceUnit == distanceUnit &&
        other.voiceGender == voiceGender &&
        other.mapStyle == mapStyle &&
        other.navigationStyle == navigationStyle &&
        other.showSpeedometer == showSpeedometer &&
        other.showCompass == showCompass &&
        other.showWeather == showWeather &&
        other.showTraffic == showTraffic &&
        other.showPOI == showPOI &&
        other.nightModeAuto == nightModeAuto &&
        other.brightness == brightness &&
        other.speedWarningsEnabled == speedWarningsEnabled &&
        other.fatigueDetectionEnabled == fatigueDetectionEnabled &&
        other.laneAssistEnabled == laneAssistEnabled &&
        other.emergencyDetectionEnabled == emergencyDetectionEnabled &&
        other.speedWarningThreshold == speedWarningThreshold &&
        other.fatigueCheckInterval == fatigueCheckInterval &&
        other.voiceEnabled == voiceEnabled &&
        other.voiceProactiveAnnouncements == voiceProactiveAnnouncements &&
        other.voiceVolume == voiceVolume &&
        other.voiceSpeed == voiceSpeed &&
        other.voiceLanguage == voiceLanguage &&
        other.avoidTolls == avoidTolls &&
        other.avoidHighways == avoidHighways &&
        other.avoidFerries == avoidFerries &&
        other.preferFastestRoute == preferFastestRoute &&
        other.showAlternativeRoutes == showAlternativeRoutes &&
        other.routeRecalculationSensitivity == routeRecalculationSensitivity &&
        other.showAccidentWarnings == showAccidentWarnings &&
        other.showTrafficWarnings == showTrafficWarnings &&
        other.showSpeedCameraWarnings == showSpeedCameraWarnings &&
        other.showPoliceWarnings == showPoliceWarnings &&
        other.showRoadworkWarnings == showRoadworkWarnings &&
        other.warningDistance == warningDistance &&
        other.shareLocationData == shareLocationData &&
        other.shareTrafficData == shareTrafficData &&
        other.shareIncidentReports == shareIncidentReports &&
        other.anonymousMode == anonymousMode &&
        other.adaptiveInterface == adaptiveInterface &&
        other.learningMode == learningMode &&
        other.predictiveRouting == predictiveRouting &&
        other.weatherAdaptation == weatherAdaptation &&
        other.timeBasedOptimization == timeBasedOptimization;
  }
  
  @override
  int get hashCode {
    return Object.hashAll([
      mode,
      speedUnit,
      distanceUnit,
      voiceGender,
      mapStyle,
      navigationStyle,
      showSpeedometer,
      showCompass,
      showWeather,
      showTraffic,
      showPOI,
      nightModeAuto,
      brightness,
      speedWarningsEnabled,
      fatigueDetectionEnabled,
      laneAssistEnabled,
      emergencyDetectionEnabled,
      speedWarningThreshold,
      fatigueCheckInterval,
      voiceEnabled,
      voiceProactiveAnnouncements,
      voiceVolume,
      voiceSpeed,
      voiceLanguage,
      avoidTolls,
      avoidHighways,
      avoidFerries,
      preferFastestRoute,
      showAlternativeRoutes,
      routeRecalculationSensitivity,
      showAccidentWarnings,
      showTrafficWarnings,
      showSpeedCameraWarnings,
      showPoliceWarnings,
      showRoadworkWarnings,
      warningDistance,
      shareLocationData,
      shareTrafficData,
      shareIncidentReports,
      anonymousMode,
      adaptiveInterface,
      learningMode,
      predictiveRouting,
      weatherAdaptation,
      timeBasedOptimization,
    ]);
  }
  
  // Helper methods
  String get modeDisplayName {
    switch (mode) {
      case DrivingMode.normal:
        return 'عادي';
      case DrivingMode.eco:
        return 'اقتصادي';
      case DrivingMode.sport:
        return 'رياضي';
      case DrivingMode.comfort:
        return 'مريح';
      case DrivingMode.night:
        return 'ليلي';
      case DrivingMode.rain:
        return 'مطر';
      case DrivingMode.highway:
        return 'طريق سريع';
    }
  }
  
  String get speedUnitSymbol {
    switch (speedUnit) {
      case SpeedUnit.kmh:
        return 'كم/س';
      case SpeedUnit.mph:
        return 'ميل/س';
    }
  }
  
  String get distanceUnitSymbol {
    switch (distanceUnit) {
      case DistanceUnit.km:
        return 'كم';
      case DistanceUnit.miles:
        return 'ميل';
    }
  }
}