class AIAssistantModel {
  final String id;
  final String name;
  final String version;
  final List<String> capabilities;
  final Map<String, dynamic> settings;
  final DateTime lastUpdated;
  
  const AIAssistantModel({
    required this.id,
    required this.name,
    required this.version,
    required this.capabilities,
    required this.settings,
    required this.lastUpdated,
  });
  
  factory AIAssistantModel.defaultAssistant() {
    return AIAssistantModel(
      id: 'salama_ai_v1',
      name: 'سلامة',
      version: '1.0.0',
      capabilities: [
        'voice_recognition',
        'natural_language_processing',
        'route_optimization',
        'safety_monitoring',
        'weather_analysis',
        'traffic_prediction',
        'emergency_assistance',
        'personalized_recommendations',
      ],
      settings: {
        'language': 'ar',
        'voice_enabled': true,
        'proactive_alerts': true,
        'learning_enabled': true,
        'privacy_mode': false,
      },
      lastUpdated: DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'capabilities': capabilities,
      'settings': settings,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  factory AIAssistantModel.fromJson(Map<String, dynamic> json) {
    return AIAssistantModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      version: json['version'] ?? '',
      capabilities: List<String>.from(json['capabilities'] ?? []),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  AIAssistantModel copyWith({
    String? id,
    String? name,
    String? version,
    List<String>? capabilities,
    Map<String, dynamic>? settings,
    DateTime? lastUpdated,
  }) {
    return AIAssistantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      capabilities: capabilities ?? this.capabilities,
      settings: settings ?? this.settings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ConversationMessage {
  final String id;
  final String content;
  final MessageType type;
  final MessageSender sender;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final List<MessageAction>? actions;
  
  const ConversationMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.sender,
    required this.timestamp,
    this.metadata,
    this.actions,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'sender': sender.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'actions': actions?.map((a) => a.toJson()).toList(),
    };
  }
  
  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      sender: MessageSender.values.firstWhere(
        (e) => e.name == json['sender'],
        orElse: () => MessageSender.user,
      ),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'],
      actions: json['actions'] != null
          ? List<MessageAction>.from(
              json['actions'].map((a) => MessageAction.fromJson(a))
            )
          : null,
    );
  }
}

enum MessageType {
  text,
  voice,
  command,
  notification,
  warning,
  emergency,
  suggestion,
  confirmation,
}

enum MessageSender {
  user,
  assistant,
  system,
}

class MessageAction {
  final String id;
  final String label;
  final ActionType type;
  final Map<String, dynamic> parameters;
  
  const MessageAction({
    required this.id,
    required this.label,
    required this.type,
    required this.parameters,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      'parameters': parameters,
    };
  }
  
  factory MessageAction.fromJson(Map<String, dynamic> json) {
    return MessageAction(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      type: ActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActionType.navigate,
      ),
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
    );
  }
}

enum ActionType {
  navigate,
  call,
  message,
  settings,
  emergency,
  reminder,
  route,
  weather,
}

class VoiceCommand {
  final String id;
  final String phrase;
  final String intent;
  final Map<String, dynamic> entities;
  final double confidence;
  final DateTime timestamp;
  
  const VoiceCommand({
    required this.id,
    required this.phrase,
    required this.intent,
    required this.entities,
    required this.confidence,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phrase': phrase,
      'intent': intent,
      'entities': entities,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  factory VoiceCommand.fromJson(Map<String, dynamic> json) {
    return VoiceCommand(
      id: json['id'] ?? '',
      phrase: json['phrase'] ?? '',
      intent: json['intent'] ?? '',
      entities: Map<String, dynamic>.from(json['entities'] ?? {}),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class AIResponse {
  final String id;
  final String content;
  final ResponseType type;
  final double confidence;
  final List<String> suggestions;
  final Map<String, dynamic> context;
  final DateTime timestamp;
  
  const AIResponse({
    required this.id,
    required this.content,
    required this.type,
    required this.confidence,
    required this.suggestions,
    required this.context,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'confidence': confidence,
      'suggestions': suggestions,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      type: ResponseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ResponseType.informational,
      ),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      suggestions: List<String>.from(json['suggestions'] ?? []),
      context: Map<String, dynamic>.from(json['context'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

enum ResponseType {
  informational,
  actionable,
  warning,
  emergency,
  confirmation,
  suggestion,
}

class ConversationContext {
  final String sessionId;
  final List<ConversationMessage> messages;
  final Map<String, dynamic> userPreferences;
  final Map<String, dynamic> currentState;
  final DateTime startTime;
  final DateTime lastActivity;
  
  const ConversationContext({
    required this.sessionId,
    required this.messages,
    required this.userPreferences,
    required this.currentState,
    required this.startTime,
    required this.lastActivity,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'userPreferences': userPreferences,
      'currentState': currentState,
      'startTime': startTime.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
    };
  }
  
  factory ConversationContext.fromJson(Map<String, dynamic> json) {
    return ConversationContext(
      sessionId: json['sessionId'] ?? '',
      messages: List<ConversationMessage>.from(
        json['messages']?.map((m) => ConversationMessage.fromJson(m)) ?? []
      ),
      userPreferences: Map<String, dynamic>.from(json['userPreferences'] ?? {}),
      currentState: Map<String, dynamic>.from(json['currentState'] ?? {}),
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      lastActivity: DateTime.parse(json['lastActivity'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  ConversationContext copyWith({
    String? sessionId,
    List<ConversationMessage>? messages,
    Map<String, dynamic>? userPreferences,
    Map<String, dynamic>? currentState,
    DateTime? startTime,
    DateTime? lastActivity,
  }) {
    return ConversationContext(
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      userPreferences: userPreferences ?? this.userPreferences,
      currentState: currentState ?? this.currentState,
      startTime: startTime ?? this.startTime,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
  
  ConversationContext addMessage(ConversationMessage message) {
    return copyWith(
      messages: [...messages, message],
      lastActivity: DateTime.now(),
    );
  }
  
  ConversationContext updateState(Map<String, dynamic> newState) {
    return copyWith(
      currentState: {...currentState, ...newState},
      lastActivity: DateTime.now(),
    );
  }
}

class AICapability {
  final String id;
  final String name;
  final String description;
  final bool isEnabled;
  final Map<String, dynamic> configuration;
  final List<String> requiredPermissions;
  
  const AICapability({
    required this.id,
    required this.name,
    required this.description,
    required this.isEnabled,
    required this.configuration,
    required this.requiredPermissions,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isEnabled': isEnabled,
      'configuration': configuration,
      'requiredPermissions': requiredPermissions,
    };
  }
  
  factory AICapability.fromJson(Map<String, dynamic> json) {
    return AICapability(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isEnabled: json['isEnabled'] ?? false,
      configuration: Map<String, dynamic>.from(json['configuration'] ?? {}),
      requiredPermissions: List<String>.from(json['requiredPermissions'] ?? []),
    );
  }
  
  AICapability copyWith({
    String? id,
    String? name,
    String? description,
    bool? isEnabled,
    Map<String, dynamic>? configuration,
    List<String>? requiredPermissions,
  }) {
    return AICapability(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
      configuration: configuration ?? this.configuration,
      requiredPermissions: requiredPermissions ?? this.requiredPermissions,
    );
  }
}

class LearningData {
  final String userId;
  final Map<String, dynamic> preferences;
  final Map<String, int> commandFrequency;
  final Map<String, double> responseRatings;
  final List<String> commonPhrases;
  final DateTime lastUpdated;
  
  const LearningData({
    required this.userId,
    required this.preferences,
    required this.commandFrequency,
    required this.responseRatings,
    required this.commonPhrases,
    required this.lastUpdated,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'preferences': preferences,
      'commandFrequency': commandFrequency,
      'responseRatings': responseRatings,
      'commonPhrases': commonPhrases,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  factory LearningData.fromJson(Map<String, dynamic> json) {
    return LearningData(
      userId: json['userId'] ?? '',
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      commandFrequency: Map<String, int>.from(json['commandFrequency'] ?? {}),
      responseRatings: Map<String, double>.from(json['responseRatings'] ?? {}),
      commonPhrases: List<String>.from(json['commonPhrases'] ?? []),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  LearningData copyWith({
    String? userId,
    Map<String, dynamic>? preferences,
    Map<String, int>? commandFrequency,
    Map<String, double>? responseRatings,
    List<String>? commonPhrases,
    DateTime? lastUpdated,
  }) {
    return LearningData(
      userId: userId ?? this.userId,
      preferences: preferences ?? this.preferences,
      commandFrequency: commandFrequency ?? this.commandFrequency,
      responseRatings: responseRatings ?? this.responseRatings,
      commonPhrases: commonPhrases ?? this.commonPhrases,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}