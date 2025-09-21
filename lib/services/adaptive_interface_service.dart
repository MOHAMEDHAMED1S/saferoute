import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';
import '../models/driving_settings_model.dart';
import '../services/weather_service.dart';
import '../services/driving_settings_service.dart';

class AdaptiveInterfaceService {
  static final AdaptiveInterfaceService _instance = AdaptiveInterfaceService._internal();
  factory AdaptiveInterfaceService() => _instance;
  AdaptiveInterfaceService._internal();

  final StreamController<AdaptiveTheme> _themeController = StreamController<AdaptiveTheme>.broadcast();
  final StreamController<AdaptiveLayout> _layoutController = StreamController<AdaptiveLayout>.broadcast();
  final StreamController<AdaptiveColors> _colorsController = StreamController<AdaptiveColors>.broadcast();
  
  Stream<AdaptiveTheme> get themeStream => _themeController.stream;
  Stream<AdaptiveLayout> get layoutStream => _layoutController.stream;
  Stream<AdaptiveColors> get colorsStream => _colorsController.stream;
  
  late WeatherService _weatherService;
  late DrivingSettingsService _settingsService;
  
  AdaptiveTheme _currentTheme = AdaptiveTheme.auto;
  AdaptiveLayout _currentLayout = AdaptiveLayout.standard;
  AdaptiveColors _currentColors = AdaptiveColors.standard;
  
  WeatherData? _currentWeather;
  TimeOfDay? _currentTime;
  double _currentSpeed = 0.0;
  bool _isNightTime = false;
  bool _isRaining = false;
  bool _isFoggy = false;
  bool _isHighSpeed = false;
  
  Timer? _adaptationTimer;
  Timer? _timeCheckTimer;
  
  bool _isInitialized = false;
  
  AdaptiveTheme get currentTheme => _currentTheme;
  AdaptiveLayout get currentLayout => _currentLayout;
  AdaptiveColors get currentColors => _currentColors;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _weatherService = WeatherService();
    _settingsService = DrivingSettingsService();
    
    await _weatherService.initialize();
    await _settingsService.initialize();
    
    _startAdaptationTimer();
    _startTimeCheckTimer();
    
    _isInitialized = true;
  }
  
  void dispose() {
    _adaptationTimer?.cancel();
    _timeCheckTimer?.cancel();
    _themeController.close();
    _layoutController.close();
    _colorsController.close();
  }
  
  void _startAdaptationTimer() {
    _adaptationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateAdaptiveInterface();
    });
  }
  
  void _startTimeCheckTimer() {
    _timeCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTimeBasedAdaptation();
    });
  }
  
  Future<void> _updateAdaptiveInterface() async {
    try {
      // Get current position
      final position = await Geolocator.getCurrentPosition();
      
      // Update weather information
      _currentWeather = await _weatherService.getCurrentWeather(
        position.latitude,
        position.longitude,
      );
      
      // Update environmental conditions
      _updateEnvironmentalConditions();
      
      // Apply adaptive changes
      _applyAdaptiveTheme();
      _applyAdaptiveLayout();
      _applyAdaptiveColors();
      
    } catch (e) {
      print('Error updating adaptive interface: $e');
    }
  }
  
  void _updateTimeBasedAdaptation() {
    final now = DateTime.now();
    _currentTime = TimeOfDay.fromDateTime(now);
    
    // Determine if it's night time
    final hour = now.hour;
    _isNightTime = hour < 6 || hour > 20;
    
    _applyAdaptiveTheme();
    _applyAdaptiveColors();
  }
  
  void _updateEnvironmentalConditions() {
    if (_currentWeather == null) return;
    
    _isRaining = _currentWeather!.condition == WeatherCondition.rain ||
                 _currentWeather!.condition == WeatherCondition.thunderstorm;
    
    _isFoggy = _currentWeather!.condition == WeatherCondition.fog ||
               _currentWeather!.visibility < 1000;
    
    _isHighSpeed = _currentSpeed > 80; // km/h
  }
  
  void updateSpeed(double speed) {
    _currentSpeed = speed;
    _isHighSpeed = speed > 80;
    
    if (_isHighSpeed != (_currentSpeed > 80)) {
      _applyAdaptiveLayout();
    }
  }
  
  void _applyAdaptiveTheme() {
    AdaptiveTheme newTheme;
    
    if (!_settingsService.currentSettings.adaptiveInterface) {
      newTheme = AdaptiveTheme.standard;
    } else if (_isNightTime || _settingsService.currentSettings.nightModeAuto) {
      newTheme = AdaptiveTheme.night;
    } else if (_isRaining) {
      newTheme = AdaptiveTheme.rain;
    } else if (_isFoggy) {
      newTheme = AdaptiveTheme.fog;
    } else if (_isHighSpeed) {
      newTheme = AdaptiveTheme.highway;
    } else {
      newTheme = AdaptiveTheme.day;
    }
    
    if (newTheme != _currentTheme) {
      _currentTheme = newTheme;
      _themeController.add(_currentTheme);
    }
  }
  
  void _applyAdaptiveLayout() {
    AdaptiveLayout newLayout;
    
    if (!_settingsService.currentSettings.adaptiveInterface) {
      newLayout = AdaptiveLayout.standard;
    } else if (_isHighSpeed) {
      newLayout = AdaptiveLayout.highway;
    } else if (_isRaining || _isFoggy) {
      newLayout = AdaptiveLayout.cautious;
    } else if (_isNightTime) {
      newLayout = AdaptiveLayout.night;
    } else {
      newLayout = AdaptiveLayout.standard;
    }
    
    if (newLayout != _currentLayout) {
      _currentLayout = newLayout;
      _layoutController.add(_currentLayout);
    }
  }
  
  void _applyAdaptiveColors() {
    AdaptiveColors newColors;
    
    if (!_settingsService.currentSettings.adaptiveInterface) {
      newColors = AdaptiveColors.standard;
    } else if (_isNightTime) {
      newColors = AdaptiveColors.night;
    } else if (_isRaining) {
      newColors = AdaptiveColors.rain;
    } else if (_isFoggy) {
      newColors = AdaptiveColors.fog;
    } else if (_currentWeather?.temperature != null && _currentWeather!.temperature > 35) {
      newColors = AdaptiveColors.hot;
    } else if (_currentWeather?.temperature != null && _currentWeather!.temperature < 5) {
      newColors = AdaptiveColors.cold;
    } else {
      newColors = AdaptiveColors.standard;
    }
    
    if (newColors != _currentColors) {
      _currentColors = newColors;
      _colorsController.add(_currentColors);
    }
  }
  
  // Manual override methods
  void setTheme(AdaptiveTheme theme) {
    _currentTheme = theme;
    _themeController.add(_currentTheme);
  }
  
  void setLayout(AdaptiveLayout layout) {
    _currentLayout = layout;
    _layoutController.add(_currentLayout);
  }
  
  void setColors(AdaptiveColors colors) {
    _currentColors = colors;
    _colorsController.add(_currentColors);
  }
  
  // Get adaptive properties
  ThemeData getAdaptiveThemeData() {
    switch (_currentTheme) {
      case AdaptiveTheme.night:
        return _getNightTheme();
      case AdaptiveTheme.rain:
        return _getRainTheme();
      case AdaptiveTheme.fog:
        return _getFogTheme();
      case AdaptiveTheme.highway:
        return _getHighwayTheme();
      case AdaptiveTheme.day:
        return _getDayTheme();
      case AdaptiveTheme.auto:
      case AdaptiveTheme.standard:
      default:
        return _getStandardTheme();
    }
  }
  
  Map<String, dynamic> getAdaptiveLayoutProperties() {
    switch (_currentLayout) {
      case AdaptiveLayout.highway:
        return {
          'speedometerSize': 120.0,
          'buttonSize': 60.0,
          'fontSize': 18.0,
          'iconSize': 28.0,
          'spacing': 16.0,
          'showMinimalUI': true,
          'emphasizeSpeed': true,
        };
      case AdaptiveLayout.cautious:
        return {
          'speedometerSize': 100.0,
          'buttonSize': 70.0,
          'fontSize': 20.0,
          'iconSize': 32.0,
          'spacing': 20.0,
          'showMinimalUI': false,
          'emphasizeWarnings': true,
        };
      case AdaptiveLayout.night:
        return {
          'speedometerSize': 110.0,
          'buttonSize': 65.0,
          'fontSize': 19.0,
          'iconSize': 30.0,
          'spacing': 18.0,
          'showMinimalUI': false,
          'reducedBrightness': true,
        };
      case AdaptiveLayout.standard:
      default:
        return {
          'speedometerSize': 100.0,
          'buttonSize': 56.0,
          'fontSize': 16.0,
          'iconSize': 24.0,
          'spacing': 12.0,
          'showMinimalUI': false,
          'emphasizeSpeed': false,
        };
    }
  }
  
  ColorScheme getAdaptiveColorScheme() {
    switch (_currentColors) {
      case AdaptiveColors.night:
        return _getNightColors();
      case AdaptiveColors.rain:
        return _getRainColors();
      case AdaptiveColors.fog:
        return _getFogColors();
      case AdaptiveColors.hot:
        return _getHotColors();
      case AdaptiveColors.cold:
        return _getColdColors();
      case AdaptiveColors.standard:
      default:
        return _getStandardColors();
    }
  }
  
  // Theme implementations
  ThemeData _getStandardTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      colorScheme: _getStandardColors(),
    );
  }
  
  ThemeData _getNightTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.amber,
      colorScheme: _getNightColors(),
    );
  }
  
  ThemeData _getRainTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.indigo,
      colorScheme: _getRainColors(),
    );
  }
  
  ThemeData _getFogTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.grey,
      colorScheme: _getFogColors(),
    );
  }
  
  ThemeData _getHighwayTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.green,
      colorScheme: _getStandardColors(),
    );
  }
  
  ThemeData _getDayTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      colorScheme: _getStandardColors(),
    );
  }
  
  // Color scheme implementations
  ColorScheme _getStandardColors() {
    return const ColorScheme.light(
      primary: Color(0xFF2196F3),
      secondary: Color(0xFF03DAC6),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFF5F5F5),
      error: Color(0xFFB00020),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFF000000),
      onBackground: Color(0xFF000000),
      onError: Color(0xFFFFFFFF),
    );
  }
  
  ColorScheme _getNightColors() {
    return const ColorScheme.dark(
      primary: Color(0xFFFFB74D),
      secondary: Color(0xFF81C784),
      surface: Color(0xFF121212),
      background: Color(0xFF000000),
      error: Color(0xFFCF6679),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFFFFFFFF),
      onBackground: Color(0xFFFFFFFF),
      onError: Color(0xFF000000),
    );
  }
  
  ColorScheme _getRainColors() {
    return const ColorScheme.light(
      primary: Color(0xFF3F51B5),
      secondary: Color(0xFF607D8B),
      surface: Color(0xFFE3F2FD),
      background: Color(0xFFE1F5FE),
      error: Color(0xFFB00020),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A237E),
      onBackground: Color(0xFF0D47A1),
      onError: Color(0xFFFFFFFF),
    );
  }
  
  ColorScheme _getFogColors() {
    return const ColorScheme.light(
      primary: Color(0xFF9E9E9E),
      secondary: Color(0xFF757575),
      surface: Color(0xFFF5F5F5),
      background: Color(0xFFEEEEEE),
      error: Color(0xFFFF5722),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF212121),
      onBackground: Color(0xFF424242),
      onError: Color(0xFFFFFFFF),
    );
  }
  
  ColorScheme _getHotColors() {
    return const ColorScheme.light(
      primary: Color(0xFFFF5722),
      secondary: Color(0xFFFF9800),
      surface: Color(0xFFFFF3E0),
      background: Color(0xFFFFF8E1),
      error: Color(0xFFD32F2F),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFFBF360C),
      onBackground: Color(0xFFE65100),
      onError: Color(0xFFFFFFFF),
    );
  }
  
  ColorScheme _getColdColors() {
    return const ColorScheme.light(
      primary: Color(0xFF2196F3),
      secondary: Color(0xFF00BCD4),
      surface: Color(0xFFE0F2F1),
      background: Color(0xFFE0F7FA),
      error: Color(0xFFB00020),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFF004D40),
      onBackground: Color(0xFF006064),
      onError: Color(0xFFFFFFFF),
    );
  }
  
  // Utility methods
  double getAdaptiveBrightness() {
    switch (_currentTheme) {
      case AdaptiveTheme.night:
        return 0.3;
      case AdaptiveTheme.fog:
        return 0.8;
      case AdaptiveTheme.rain:
        return 0.7;
      default:
        return 1.0;
    }
  }
  
  bool shouldShowMinimalUI() {
    return _currentLayout == AdaptiveLayout.highway;
  }
  
  bool shouldEmphasizeWarnings() {
    return _currentLayout == AdaptiveLayout.cautious || _isRaining || _isFoggy;
  }
  
  String getAdaptationReason() {
    List<String> reasons = [];
    
    if (_isNightTime) reasons.add('الوقت الليلي');
    if (_isRaining) reasons.add('الطقس الممطر');
    if (_isFoggy) reasons.add('الضباب');
    if (_isHighSpeed) reasons.add('السرعة العالية');
    
    if (reasons.isEmpty) {
      return 'الوضع العادي';
    } else {
      return 'تم التكيف مع: ${reasons.join('، ')}';
    }
  }
}

// Enums for adaptive interface
enum AdaptiveTheme {
  auto,
  standard,
  night,
  day,
  rain,
  fog,
  highway,
}

enum AdaptiveLayout {
  standard,
  highway,
  cautious,
  night,
}

enum AdaptiveColors {
  standard,
  night,
  rain,
  fog,
  hot,
  cold,
}