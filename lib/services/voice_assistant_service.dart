import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/warning_model.dart';
import '../models/route_model.dart';
import '../models/safety_model.dart';
import 'warning_service.dart';
import 'navigation_service.dart';
import 'safety_service.dart';

class VoiceAssistantService {
  static final VoiceAssistantService _instance = VoiceAssistantService._internal();
  factory VoiceAssistantService() => _instance;
  VoiceAssistantService._internal();

  // Speech recognition and TTS
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  // Services
  WarningService? _warningService;
  NavigationService? _navigationService;
  SafetyService? _safetyService;
  
  // State
  bool _isListening = false;
  bool _isInitialized = false;
  String? _lastCommand;
  DateTime? _lastInteraction;
  
  // Streams
  final StreamController<String> _commandController = StreamController<String>.broadcast();
  final StreamController<String> _responseController = StreamController<String>.broadcast();
  final StreamController<bool> _listeningController = StreamController<bool>.broadcast();
  
  // Getters
  Stream<String> get commands => _commandController.stream;
  Stream<String> get responses => _responseController.stream;
  Stream<bool> get isListening => _listeningController.stream;
  bool get initialized => _isInitialized;
  
  // Voice commands patterns
  final Map<String, List<String>> _commandPatterns = {
    'route_status': [
      'كيف الطريق',
      'وضع الطريق',
      'حالة المسار',
      'كيف المسار',
      'ايش وضع الطريق'
    ],
    'alternative_route': [
      'طريق بديل',
      'طريق أسرع',
      'طريق آخر',
      'غير الطريق',
      'أريد طريق أسرع'
    ],
    'gas_station': [
      'محطة وقود',
      'محطة بنزين',
      'أقرب محطة',
      'أين محطة الوقود',
      'أحتاج وقود'
    ],
    'hospital': [
      'مستشفى',
      'أقرب مستشفى',
      'مستشفى قريب',
      'طوارئ'
    ],
    'police': [
      'شرطة',
      'أقرب شرطة',
      'مركز شرطة'
    ],
    'report_incident': [
      'إبلاغ عن حادث',
      'يوجد حادث',
      'حادث في الطريق',
      'أبلغ عن مشكلة'
    ],
    'speed_limit': [
      'حد السرعة',
      'كم السرعة المسموحة',
      'السرعة القانونية'
    ],
    'eta': [
      'متى أصل',
      'كم باقي',
      'وقت الوصول',
      'متى نوصل'
    ],
    'repeat': [
      'كرر',
      'أعد',
      'ما قلت',
      'لم أسمع'
    ]
  };
  
  Future<void> initialize({
    WarningService? warningService,
    NavigationService? navigationService,
    SafetyService? safetyService,
  }) async {
    try {
      _warningService = warningService;
      _navigationService = navigationService;
      _safetyService = safetyService;
      
      // Initialize speech recognition
      bool available = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );
      
      if (!available) {
        throw Exception('Speech recognition not available');
      }
      
      // Initialize TTS
      await _flutterTts.setLanguage('ar-SA');
      await _flutterTts.setSpeechRate(0.8);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Set voice to female if available
      var voices = await _flutterTts.getVoices;
      var arabicVoices = voices.where((voice) => 
        voice['locale'].toString().startsWith('ar')).toList();
      
      if (arabicVoices.isNotEmpty) {
        await _flutterTts.setVoice(arabicVoices.first);
      }
      
      _isInitialized = true;
      
      // Welcome message
      await speak('مرحباً، أنا سلامة، مساعدك الذكي للقيادة الآمنة');
      
    } catch (e) {
      debugPrint('Voice assistant initialization error: $e');
      rethrow;
    }
  }
  
  Future<void> startListening() async {
    if (!_isInitialized || _isListening) return;
    
    try {
      _isListening = true;
      _listeningController.add(true);
      
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            _processCommand(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          partialResults: false,
        ),
        localeId: 'ar_SA',
      );
      
    } catch (e) {
      debugPrint('Start listening error: $e');
      _isListening = false;
      _listeningController.add(false);
    }
  }
  
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    await _speechToText.stop();
    _isListening = false;
    _listeningController.add(false);
  }
  
  Future<void> speak(String text) async {
    if (!_isInitialized) return;
    
    try {
      await _flutterTts.speak(text);
      _responseController.add(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }
  
  void _processCommand(String command) {
    _lastCommand = command;
    _lastInteraction = DateTime.now();
    _commandController.add(command);
    
    // Stop listening
    _isListening = false;
    _listeningController.add(false);
    
    // Process command
    _handleCommand(command.toLowerCase());
  }
  
  Future<void> _handleCommand(String command) async {
    try {
      // Check if command starts with "سلامة"
      if (!command.contains('سلامة')) {
        await speak('قل "سلامة" أولاً ثم اطلب ما تريد');
        return;
      }
      
      // Remove "سلامة" from command
      String cleanCommand = command.replaceAll('سلامة', '').trim();
      
      // Find matching command pattern
      String? commandType = _findCommandType(cleanCommand);
      
      if (commandType == null) {
        await speak('لم أفهم طلبك، يمكنك قول: كيف الطريق، طريق بديل، أقرب محطة وقود');
        return;
      }
      
      // Execute command
      await _executeCommand(commandType, cleanCommand);
      
    } catch (e) {
      debugPrint('Command processing error: $e');
      await speak('حدث خطأ، حاول مرة أخرى');
    }
  }
  
  String? _findCommandType(String command) {
    for (String type in _commandPatterns.keys) {
      for (String pattern in _commandPatterns[type]!) {
        if (command.contains(pattern)) {
          return type;
        }
      }
    }
    return null;
  }
  
  Future<void> _executeCommand(String commandType, String command) async {
    switch (commandType) {
      case 'route_status':
        await _handleRouteStatus();
        break;
      case 'alternative_route':
        await _handleAlternativeRoute();
        break;
      case 'gas_station':
        await _handleGasStation();
        break;
      case 'hospital':
        await _handleHospital();
        break;
      case 'police':
        await _handlePolice();
        break;
      case 'report_incident':
        await _handleReportIncident();
        break;
      case 'speed_limit':
        await _handleSpeedLimit();
        break;
      case 'eta':
        await _handleETA();
        break;
      case 'repeat':
        await _handleRepeat();
        break;
      default:
        await speak('لم أفهم طلبك');
    }
  }
  
  Future<void> _handleRouteStatus() async {
    if (_navigationService == null) {
      await speak('الملاحة غير مفعلة حالياً');
      return;
    }
    
    try {
      NavigationState state = _navigationService!.currentState;
      List<DrivingWarning> warnings = _warningService?.getActiveWarnings() ?? [];
      
      String response = 'الطريق ';
      
      if (warnings.isEmpty) {
        response += 'آمن، ';
      } else {
        int highPriorityWarnings = warnings.where((w) => w.severity == WarningSeverity.high).length;
        if (highPriorityWarnings > 0) {
          response += 'يحتوي على مخاطر، ';
        } else {
          response += 'يحتوي على تحذيرات خفيفة، ';
        }
      }
      
      if (state.route != null && state.route!.estimatedTimeRemaining.inMinutes > 0) {
        response += '${state.route!.estimatedTimeRemaining.inMinutes} دقيقة متبقية';
      }
      
      if (warnings.isNotEmpty) {
        DrivingWarning nearestWarning = warnings.first;
        response += '، يوجد ${_getWarningTypeText(nearestWarning.type)} خلال ${(nearestWarning.distance / 1000).toStringAsFixed(1)} كيلومتر';
      }
      
      await speak(response);
      
    } catch (e) {
      await speak('لا يمكن الحصول على معلومات الطريق حالياً');
    }
  }
  
  Future<void> _handleAlternativeRoute() async {
    if (_navigationService == null) {
      await speak('الملاحة غير مفعلة حالياً');
      return;
    }
    
    try {
      // Check for alternative routes
      List<RouteInfo> alternatives = _navigationService!.alternativeRoutes;
      
      if (alternatives.isEmpty) {
        await speak('لا توجد طرق بديلة متاحة حالياً');
        return;
      }
      
      RouteInfo bestAlternative = alternatives.first;
      NavigationState currentState = _navigationService!.currentState;
      
      if (currentState.route == null) {
        await speak('لا يوجد مسار حالي للمقارنة');
        return;
      }
      
      int timeDifference = bestAlternative.estimatedTimeRemaining.inMinutes - currentState.route!.estimatedTimeRemaining.inMinutes;
      
      if (timeDifference < 0) {
        await speak('يوجد طريق بديل أسرع بـ ${timeDifference.abs()} دقيقة، هل تريد التغيير؟');
      } else if (timeDifference == 0) {
        await speak('يوجد طريق بديل بنفس الوقت تقريباً، هل تريد التغيير؟');
      } else {
        await speak('الطرق البديلة أطول بـ $timeDifference دقيقة');
      }
      
    } catch (e) {
      await speak('لا يمكن البحث عن طرق بديلة حالياً');
    }
  }
  
  Future<void> _handleGasStation() async {
    try {
      // Simulate finding nearest gas station
      double distance = 1.5 + Random().nextDouble() * 3; // 1.5-4.5 km
      String stationName = ['موبيل', 'أرامكو', 'شل', 'توتال'][Random().nextInt(4)];
      
      await speak('أقرب محطة وقود هي $stationName على بعد ${distance.toStringAsFixed(1)} كيلومتر');
      
    } catch (e) {
      await speak('لا يمكن العثور على محطات الوقود حالياً');
    }
  }
  
  Future<void> _handleHospital() async {
    try {
      double distance = 2.0 + Random().nextDouble() * 5; // 2-7 km
      await speak('أقرب مستشفى على بعد ${distance.toStringAsFixed(1)} كيلومتر، هل تريد التوجه إليه؟');
      
    } catch (e) {
      await speak('لا يمكن العثور على المستشفيات حالياً');
    }
  }
  
  Future<void> _handlePolice() async {
    try {
      double distance = 1.0 + Random().nextDouble() * 3; // 1-4 km
      await speak('أقرب مركز شرطة على بعد ${distance.toStringAsFixed(1)} كيلومتر');
      
    } catch (e) {
      await speak('لا يمكن العثور على مراكز الشرطة حالياً');
    }
  }
  
  Future<void> _handleReportIncident() async {
    await speak('سأقوم بتسجيل بلاغ عن حادث في موقعك الحالي، شكراً لك');
    // Here you would integrate with the warning service to report an incident
  }
  
  Future<void> _handleSpeedLimit() async {
    try {
      // Get current speed limit (simulate)
      int speedLimit = [60, 80, 100, 120][Random().nextInt(4)];
      await speak('حد السرعة الحالي $speedLimit كيلومتر في الساعة');
      
    } catch (e) {
      await speak('لا يمكن الحصول على معلومات حد السرعة');
    }
  }
  
  Future<void> _handleETA() async {
    if (_navigationService == null) {
      await speak('الملاحة غير مفعلة حالياً');
      return;
    }
    
    try {
      NavigationState state = _navigationService!.currentState;
      
      if (state.route != null && state.route!.estimatedTimeRemaining.inMinutes > 0) {
        int minutes = state.route!.estimatedTimeRemaining.inMinutes;
        await speak('ستصل خلال $minutes دقيقة تقريباً');
      } else {
        await speak('لا توجد وجهة محددة حالياً');
      }
      
    } catch (e) {
      await speak('لا يمكن حساب وقت الوصول');
    }
  }
  
  Future<void> _handleRepeat() async {
    if (_responseController.hasListener) {
      // Get last response from stream (simplified)
      await speak('آخر ما قلته: معلومات الطريق');
    } else {
      await speak('لم أقل شيئاً مؤخراً');
    }
  }
  
  String _getWarningTypeText(WarningType type) {
    switch (type) {
      case WarningType.accident:
        return 'حادث';
      case WarningType.traffic:
        return 'ازدحام';
      case WarningType.roadwork:
        return 'أعمال طريق';
      case WarningType.general:
        return 'مطب';
      case WarningType.police:
        return 'نقطة شرطة';
      case WarningType.speedCamera:
        return 'كاميرا مراقبة';
      case WarningType.speedLimit:
        return 'حد السرعة';
    }
  }
  
  // Quick voice commands for emergency situations
  Future<void> emergencyAnnouncement(String message) async {
    await _flutterTts.stop();
    await _flutterTts.setSpeechRate(1.0);
    await _flutterTts.setVolume(1.0);
    await speak(message);
    await _flutterTts.setSpeechRate(0.8);
  }
  
  // Proactive announcements
  Future<void> announceWarning(DrivingWarning warning) async {
    String message = 'انتباه، ${_getWarningTypeText(warning.type)} خلال ${(warning.distance / 1000).toStringAsFixed(1)} كيلومتر';
    await speak(message);
  }
  
  Future<void> announceSpeedWarning(SpeedWarning warning) async {
    String message = 'تحذير سرعة، أنت تتجاوز الحد المسموح بـ ${warning.excessSpeed.toInt()} كيلومتر';
    await emergencyAnnouncement(message);
  }
  
  Future<void> announceFatigueWarning(FatigueWarning warning) async {
    String message;
    switch (warning.type) {
      case FatigueType.lackOfInteraction:
        message = 'تحذير تعب، يُنصح بأخذ استراحة';
        break;
      case FatigueType.slowReactions:
        message = 'ردود أفعال بطيئة، خذ استراحة';
        break;
      case FatigueType.erraticDriving:
        message = 'قيادة غير منتظمة، كن حذراً';
        break;
      case FatigueType.timeBasedFatigue:
        message = 'لقد كنت تقود لفترة طويلة، خذ استراحة';
        break;
    }
    await speak(message);
  }
  
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
    _commandController.close();
    _responseController.close();
    _listeningController.close();
  }
}