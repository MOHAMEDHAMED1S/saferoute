import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_assistant_model.dart';

import 'ml_service.dart';
import 'weather_service.dart';
import 'driving_settings_service.dart';
import 'location_service.dart';

class AIAssistantService {
  static AIAssistantService? _instance;
  static AIAssistantService get instance => _instance ??= AIAssistantService._();
  AIAssistantService._();
  
  // Core components
  late AIAssistantModel _assistant;
  late ConversationContext _currentContext;
  late LearningData _learningData;
  
  // Services
  MLService? _mlService;
  WeatherService? _weatherService;
  DrivingSettingsService? _settingsService;
  LocationService? _locationService;
  
  // Stream controllers
  final StreamController<ConversationMessage> _messageController = StreamController.broadcast();
  final StreamController<AIResponse> _responseController = StreamController.broadcast();
  final StreamController<VoiceCommand> _commandController = StreamController.broadcast();
  final StreamController<bool> _listeningController = StreamController.broadcast();
  
  // State
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _currentSessionId = '';
  Timer? _contextTimer;
  
  // Getters
  Stream<ConversationMessage> get messageStream => _messageController.stream;
  Stream<AIResponse> get responseStream => _responseController.stream;
  Stream<VoiceCommand> get commandStream => _commandController.stream;
  Stream<bool> get listeningStream => _listeningController.stream;
  
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  AIAssistantModel get assistant => _assistant;
  ConversationContext get currentContext => _currentContext;
  LearningData get learningData => _learningData;
  
  // Initialization
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadAssistantData();
      await _initializeServices();
      _startNewSession();
      _setupContextTimer();
      
      _isInitialized = true;
      
      // Send welcome message
      await _sendWelcomeMessage();
      
    } catch (e) {
      debugPrint('Error initializing AI Assistant: $e');
      rethrow;
    }
  }
  
  Future<void> _loadAssistantData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load assistant configuration
    final assistantJson = prefs.getString('ai_assistant_config');
    if (assistantJson != null) {
      _assistant = AIAssistantModel.fromJson(jsonDecode(assistantJson));
    } else {
      _assistant = AIAssistantModel.defaultAssistant();
      await _saveAssistantData();
    }
    
    // Load learning data
    final learningJson = prefs.getString('ai_learning_data');
    if (learningJson != null) {
      _learningData = LearningData.fromJson(jsonDecode(learningJson));
    } else {
      _learningData = LearningData(
        userId: 'default_user',
        preferences: {},
        commandFrequency: {},
        responseRatings: {},
        commonPhrases: [],
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  Future<void> _saveAssistantData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_assistant_config', jsonEncode(_assistant.toJson()));
    await prefs.setString('ai_learning_data', jsonEncode(_learningData.toJson()));
  }
  
  Future<void> _initializeServices() async {
    _mlService = MLService();
    _weatherService = WeatherService();
    _settingsService = DrivingSettingsService();
    _locationService = LocationService();
    
    await _mlService?.initialize();
    await _weatherService?.initialize();
    await _settingsService?.initialize();
  }
  
  void _startNewSession() {
    _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _currentContext = ConversationContext(
      sessionId: _currentSessionId,
      messages: [],
      userPreferences: _learningData.preferences,
      currentState: {
        'driving_mode': false,
        'location': null,
        'weather': null,
        'route': null,
      },
      startTime: DateTime.now(),
      lastActivity: DateTime.now(),
    );
  }
  
  void _setupContextTimer() {
    _contextTimer?.cancel();
    _contextTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateContextualInformation();
    });
  }
  
  Future<void> _sendWelcomeMessage() async {
    final welcomeMessage = ConversationMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      content: 'مرحباً! أنا سلامة، مساعدك الذكي للقيادة الآمنة. كيف يمكنني مساعدتك اليوم؟',
      type: MessageType.text,
      sender: MessageSender.assistant,
      timestamp: DateTime.now(),
      actions: [
        MessageAction(
          id: 'start_navigation',
          label: 'بدء الملاحة',
          type: ActionType.navigate,
          parameters: {},
        ),
        MessageAction(
          id: 'check_weather',
          label: 'حالة الطقس',
          type: ActionType.weather,
          parameters: {},
        ),
      ],
    );
    
    _addMessageToContext(welcomeMessage);
    _messageController.add(welcomeMessage);
  }
  
  // Voice interaction
  Future<void> startListening() async {
    if (_isListening || _isProcessing) return;
    
    _isListening = true;
    _listeningController.add(true);
    
    // Simulate voice recognition start
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In a real implementation, this would start the speech recognition service
    debugPrint('Started listening for voice commands...');
  }
  
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    _isListening = false;
    _listeningController.add(false);
    
    debugPrint('Stopped listening for voice commands.');
  }
  
  Future<void> processVoiceInput(String audioData) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    try {
      // Simulate voice recognition processing
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final recognizedText = await _simulateVoiceRecognition(audioData);
      final command = await _parseVoiceCommand(recognizedText);
      
      _commandController.add(command);
      await _processCommand(command);
      
    } catch (e) {
      debugPrint('Error processing voice input: $e');
      await _sendErrorMessage('عذراً، لم أتمكن من فهم ما قلته. يرجى المحاولة مرة أخرى.');
    } finally {
      _isProcessing = false;
    }
  }
  
  Future<String> _simulateVoiceRecognition(String audioData) async {
    // Simulate voice recognition with common Arabic phrases
    final commonPhrases = [
      'أين أقرب محطة وقود؟',
      'كيف حالة الطقس؟',
      'ابحث عن مطعم قريب',
      'اتصل بأحمد',
      'أرسل رسالة لسارة',
      'ما هي أسرع طريق للمنزل؟',
      'تحذير من الازدحام',
      'احفظ هذا الموقع',
    ];
    
    return commonPhrases[math.Random().nextInt(commonPhrases.length)];
  }
  
  Future<VoiceCommand> _parseVoiceCommand(String text) async {
    final command = VoiceCommand(
      id: 'cmd_${DateTime.now().millisecondsSinceEpoch}',
      phrase: text,
      intent: _extractIntent(text),
      entities: _extractEntities(text),
      confidence: 0.85 + (math.Random().nextDouble() * 0.15),
      timestamp: DateTime.now(),
    );
    
    // Update learning data
    _updateCommandFrequency(command.intent);
    
    return command;
  }
  
  String _extractIntent(String text) {
    final intentPatterns = {
      'navigation': ['أين', 'طريق', 'اتجاه', 'موقع', 'ملاحة'],
      'weather': ['طقس', 'حالة الجو', 'مطر', 'حرارة'],
      'search': ['ابحث', 'أبحث', 'أريد', 'أين أقرب'],
      'communication': ['اتصل', 'أرسل', 'رسالة', 'مكالمة'],
      'emergency': ['طوارئ', 'مساعدة', 'حادث', 'خطر'],
      'settings': ['إعدادات', 'تغيير', 'ضبط'],
      'information': ['ما هي', 'كيف', 'متى', 'أخبرني'],
    };
    
    for (final entry in intentPatterns.entries) {
      for (final pattern in entry.value) {
        if (text.contains(pattern)) {
          return entry.key;
        }
      }
    }
    
    return 'unknown';
  }
  
  Map<String, dynamic> _extractEntities(String text) {
    final entities = <String, dynamic>{};
    
    // Extract location entities
    final locationPatterns = ['محطة وقود', 'مطعم', 'مستشفى', 'بنك', 'صيدلية'];
    for (final pattern in locationPatterns) {
      if (text.contains(pattern)) {
        entities['location_type'] = pattern;
        break;
      }
    }
    
    // Extract contact names (simplified)
    final namePatterns = ['أحمد', 'سارة', 'محمد', 'فاطمة', 'علي'];
    for (final name in namePatterns) {
      if (text.contains(name)) {
        entities['contact_name'] = name;
        break;
      }
    }
    
    return entities;
  }
  
  void _updateCommandFrequency(String intent) {
    final frequency = _learningData.commandFrequency[intent] ?? 0;
    _learningData = _learningData.copyWith(
      commandFrequency: {
        ..._learningData.commandFrequency,
        intent: frequency + 1,
      },
      lastUpdated: DateTime.now(),
    );
  }
  
  // Command processing
  Future<void> _processCommand(VoiceCommand command) async {
    final userMessage = ConversationMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: command.phrase,
      type: MessageType.voice,
      sender: MessageSender.user,
      timestamp: command.timestamp,
      metadata: {
        'intent': command.intent,
        'confidence': command.confidence,
        'entities': command.entities,
      },
    );
    
    _addMessageToContext(userMessage);
    _messageController.add(userMessage);
    
    // Process based on intent
    AIResponse response;
    switch (command.intent) {
      case 'navigation':
        response = await _handleNavigationCommand(command);
        break;
      case 'weather':
        response = await _handleWeatherCommand(command);
        break;
      case 'search':
        response = await _handleSearchCommand(command);
        break;
      case 'communication':
        response = await _handleCommunicationCommand(command);
        break;
      case 'emergency':
        response = await _handleEmergencyCommand(command);
        break;
      case 'settings':
        response = await _handleSettingsCommand(command);
        break;
      case 'information':
        response = await _handleInformationCommand(command);
        break;
      default:
        response = await _handleUnknownCommand(command);
    }
    
    _responseController.add(response);
    
    final responseMessage = ConversationMessage(
      id: response.id,
      content: response.content,
      type: MessageType.text,
      sender: MessageSender.assistant,
      timestamp: response.timestamp,
      metadata: {
        'response_type': response.type.name,
        'confidence': response.confidence,
        'suggestions': response.suggestions,
      },
    );
    
    _addMessageToContext(responseMessage);
    _messageController.add(responseMessage);
  }
  
  Future<AIResponse> _handleNavigationCommand(VoiceCommand command) async {
    final locationType = command.entities['location_type'] as String?;
    
    String content;
    List<String> suggestions;
    
    if (locationType != null) {
      content = 'جاري البحث عن أقرب $locationType إليك...';
      suggestions = [
        'عرض على الخريطة',
        'بدء الملاحة',
        'حفظ الموقع',
      ];
    } else {
      content = 'يمكنني مساعدتك في الملاحة. ما هو وجهتك؟';
      suggestions = [
        'محطة وقود',
        'مطعم',
        'مستشفى',
        'البيت',
      ];
    }
    
    return AIResponse(
      id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      type: ResponseType.actionable,
      confidence: 0.9,
      suggestions: suggestions,
      context: {
        'intent': 'navigation',
        'location_type': locationType,
      },
      timestamp: DateTime.now(),
    );
  }
  
  Future<AIResponse> _handleWeatherCommand(VoiceCommand command) async {
    String content;
    dynamic weather;
    try {
      final position = await _locationService?.getCurrentLocation();
      if (position == null) {
        throw 'لا يمكن الحصول على الموقع الحالي';
      }
      
      weather = await _weatherService?.getCurrentWeather(position.latitude, position.longitude);
      
      if (weather != null) {
        content = 'الطقس الحالي: ${weather.temperatureDisplay}، ${weather.condition.arabicName}. '
            'الرؤية: ${weather.visibilityDisplay}. '
            'توصيات القيادة: ${weather.drivingRecommendations.join(', ')}';
      } else {
        content = 'عذراً، لا يمكنني الحصول على معلومات الطقس في الوقت الحالي.';
      }
    } catch (e) {
      content = 'عذراً، لا يمكنني الحصول على معلومات الطقس في الوقت الحالي.';
      weather = null;
    }
    
    return AIResponse(
      id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      type: ResponseType.informational,
      confidence: 0.95,
      suggestions: [
        'توقعات الطقس',
        'نصائح القيادة',
        'تحديث الطقس',
      ],
      context: {
        'intent': 'weather',
        'weather_data': weather?.toJson(),
      },
      timestamp: DateTime.now(),
    );
  }
  
  Future<AIResponse> _handleSearchCommand(VoiceCommand command) async {
    final locationType = command.entities['location_type'] as String?;
    
    return AIResponse(
      id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
      content: 'جاري البحث عن ${locationType ?? 'الأماكن القريبة'}...',
      type: ResponseType.actionable,
      confidence: 0.85,
      suggestions: [
        'عرض النتائج',
        'تصفية البحث',
        'حفظ المفضلة',
      ],
      context: {
        'intent': 'search',
        'search_type': locationType,
      },
      timestamp: DateTime.now(),
    );
  }
  
  Future<AIResponse> _handleCommunicationCommand(VoiceCommand command) async {
    final contactName = command.entities['contact_name'] as String?;
    
    String content;
    if (contactName != null) {
      if (command.phrase.contains('اتصل')) {
        content = 'جاري الاتصال بـ $contactName...';
      } else {
        content = 'ما هي الرسالة التي تريد إرسالها إلى $contactName؟';
      }
    } else {
      content = 'من تريد الاتصال به؟';
    }
    
    return AIResponse(
      id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      type: ResponseType.actionable,
      confidence: 0.8,
      suggestions: [
        'جهات الاتصال',
        'المكالمات الأخيرة',
        'رسالة سريعة',
      ],
      context: {
        'intent': 'communication',
        'contact_name': contactName,
      },
      timestamp: DateTime.now(),
    );
  }
  
  Future<AIResponse> _handleEmergencyCommand(VoiceCommand command) async {
    return AIResponse(
      id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
      content: 'تم تفعيل وضع الطوارئ. جاري الاتصال بخدمات الطوارئ...',
      type: ResponseType.emergency,
      confidence: 1.0,
      suggestions: [
        'إلغاء',
        'إرسال الموقع',
        'اتصال طوارئ',
      ],
      context: {
        'intent': 'emergency',
        'emergency_type': 'general',
      },
      timestamp: DateTime.now(),
    );
  }
  
  Future<AIResponse> _handleSettingsCommand(VoiceCommand command) async {
    return AIResponse(
      id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
      content: 'يمكنني مساعدتك في تغيير الإعدادات. ما الذي تريد تعديله؟',
      type: ResponseType.actionable,
      confidence: 0.9,
      suggestions: [
        'إعدادات الصوت',
        'إعدادات الملاحة',
        'إعدادات السلامة',
      ],
      context: {
        'intent': 'settings',
      },
      timestamp: DateTime.now(),
    );
  }
  
  Future<AIResponse> _handleInformationCommand(VoiceCommand command) async {
    return AIResponse(
      id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
      content: 'يمكنني تزويدك بمعلومات حول الطرق، الطقس، أو أي شيء آخر تحتاجه أثناء القيادة.',
      type: ResponseType.informational,
      confidence: 0.8,
      suggestions: [
        'حالة الطرق',
        'معلومات المرور',
        'نصائح القيادة',
      ],
      context: {
        'intent': 'information',
      },
      timestamp: DateTime.now(),
    );
  }
  
  Future<AIResponse> _handleUnknownCommand(VoiceCommand command) async {
    return AIResponse(
      id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
      content: 'عذراً، لم أفهم طلبك. يمكنك أن تسأل عن الملاحة، الطقس، أو أي مساعدة أخرى.',
      type: ResponseType.informational,
      confidence: 0.3,
      suggestions: [
        'أين أقرب محطة وقود؟',
        'كيف حالة الطقس؟',
        'ابحث عن مطعم',
      ],
      context: {
        'intent': 'unknown',
        'original_phrase': command.phrase,
      },
      timestamp: DateTime.now(),
    );
  }
  
  // Text interaction
  Future<void> sendTextMessage(String text) async {
    final message = ConversationMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: text,
      type: MessageType.text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    
    _addMessageToContext(message);
    _messageController.add(message);
    
    // Process as voice command
    final command = VoiceCommand(
      id: 'cmd_${DateTime.now().millisecondsSinceEpoch}',
      phrase: text,
      intent: _extractIntent(text),
      entities: _extractEntities(text),
      confidence: 1.0,
      timestamp: DateTime.now(),
    );
    
    await _processCommand(command);
  }
  
  // Context management
  void _addMessageToContext(ConversationMessage message) {
    _currentContext = _currentContext.addMessage(message);
  }
  
  Future<void> _updateContextualInformation() async {
    final newState = <String, dynamic>{};
    
    // Update weather information
    try {
      final position = await _locationService?.getCurrentLocation();
      if (position != null) {
        final weather = await _weatherService?.getCurrentWeather(position.latitude, position.longitude);
        if (weather != null) {
          newState['weather'] = weather.toJson();
        }
      }
    } catch (e) {
      // Handle location/weather error silently
    }
    
    // Update driving settings
    final settings = _settingsService?.currentSettings;
    if (settings != null) {
      newState['driving_settings'] = settings.toJson();
    }
    
    // Update ML insights
    final performance = _mlService?.currentPerformance;
    if (performance != null) {
      newState['performance'] = performance.toJson();
    }
    
    _currentContext = _currentContext.updateState(newState);
  }
  
  // Proactive assistance
  Future<void> sendProactiveAlert(String message, MessageType type) async {
    final alert = ConversationMessage(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      content: message,
      type: type,
      sender: MessageSender.system,
      timestamp: DateTime.now(),
    );
    
    _addMessageToContext(alert);
    _messageController.add(alert);
  }
  
  // Error handling
  Future<void> _sendErrorMessage(String error) async {
    final errorMessage = ConversationMessage(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      content: error,
      type: MessageType.notification,
      sender: MessageSender.system,
      timestamp: DateTime.now(),
    );
    
    _addMessageToContext(errorMessage);
    _messageController.add(errorMessage);
  }
  
  // Learning and adaptation
  Future<void> rateResponse(String responseId, double rating) async {
    _learningData = _learningData.copyWith(
      responseRatings: {
        ..._learningData.responseRatings,
        responseId: rating,
      },
      lastUpdated: DateTime.now(),
    );
    
    await _saveAssistantData();
  }
  
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    _learningData = _learningData.copyWith(
      preferences: {
        ..._learningData.preferences,
        ...preferences,
      },
      lastUpdated: DateTime.now(),
    );
    
    await _saveAssistantData();
  }
  
  // Cleanup
  Future<void> dispose() async {
    _contextTimer?.cancel();
    await _messageController.close();
    await _responseController.close();
    await _commandController.close();
    await _listeningController.close();
    
    await _saveAssistantData();
    
    _isInitialized = false;
  }
}