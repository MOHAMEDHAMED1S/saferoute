import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/route_model.dart';
import '../models/threat_model.dart';
import '../models/report_model.dart';
import '../utils/cache_utils.dart';
import '../utils/network_utils.dart';
import 'ai_prediction_service.dart';
import 'firebase_schema_service.dart';

// Smart Notification Service
class SmartNotificationService {
  static final SmartNotificationService _instance =
      SmartNotificationService._internal();
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();

  final StreamController<SmartNotification> _notificationController =
      StreamController.broadcast();
  final List<SmartNotification> _activeNotifications = [];
  final List<NotificationRule> _rules = [];
  final Map<String, NotificationPreference> _userPreferences = {};
  Timer? _notificationTimer;
  bool _isInitialized = false;
  bool _isDisposed = false;

  // Firebase services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification channels
  final Map<NotificationChannel, bool> _channelStates = {
    NotificationChannel.safety: true,
    NotificationChannel.traffic: true,
    NotificationChannel.weather: true,
    NotificationChannel.route: true,
    NotificationChannel.ai: true,
    NotificationChannel.emergency: true,
  };

  Stream<SmartNotification> get notifications => _notificationController.stream;
  List<SmartNotification> get activeNotifications =>
      List.unmodifiable(_activeNotifications);

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadUserPreferences();
    await _setupNotificationRules();
    _startNotificationEngine();

    _isInitialized = true;

    if (kDebugMode) {
      print('Smart Notification Service initialized');
    }
  }

  Future<void> _loadUserPreferences() async {
    final cached = CacheManager().get<Map<String, dynamic>>(
      'notification_preferences',
    );

    if (cached != null) {
      cached.forEach((key, value) {
        _userPreferences[key] = NotificationPreference.fromJson(value);
      });
    } else {
      // Set default preferences
      _setDefaultPreferences();
    }
  }

  void _setDefaultPreferences() {
    for (final channel in NotificationChannel.values) {
      _userPreferences[channel.name] = NotificationPreference(
        channel: channel,
        enabled: true,
        priority: NotificationPriority.medium,
        soundEnabled: true,
        vibrationEnabled: true,
        quietHours: const QuietHours(
          enabled: true,
          startTime: TimeOfDay(hour: 22, minute: 0),
          endTime: TimeOfDay(hour: 7, minute: 0),
        ),
      );
    }
  }

  Future<void> _setupNotificationRules() async {
    _rules.clear();

    // Safety rules
    _rules.add(
      NotificationRule(
        id: 'high_risk_route',
        channel: NotificationChannel.safety,
        priority: NotificationPriority.high,
        condition: (context) =>
            context.riskLevel == RiskLevel.high ||
            context.riskLevel == RiskLevel.critical,
        template: NotificationTemplate(
          title: 'تحذير: طريق عالي الخطورة',
          body:
              'تم اكتشاف مخاطر عالية على الطريق المحدد. يُنصح بالحذر أو اختيار طريق بديل.',
          icon: 'warning',
          actions: ['view_details', 'find_alternative'],
        ),
        cooldown: const Duration(minutes: 30),
      ),
    );

    _rules.add(
      NotificationRule(
        id: 'weather_alert',
        channel: NotificationChannel.weather,
        priority: NotificationPriority.high,
        condition: (context) =>
            context.weatherCondition == WeatherCondition.storm ||
            context.weatherCondition == WeatherCondition.snow,
        template: NotificationTemplate(
          title: 'تحذير طقس',
          body: 'ظروف جوية سيئة متوقعة. قد بحذر شديد.',
          icon: 'weather',
          actions: ['view_weather', 'delay_trip'],
        ),
        cooldown: const Duration(hours: 2),
      ),
    );

    _rules.add(
      NotificationRule(
        id: 'traffic_jam',
        channel: NotificationChannel.traffic,
        priority: NotificationPriority.medium,
        condition: (context) => context.trafficDensity > 0.8,
        template: NotificationTemplate(
          title: 'ازدحام مروري',
          body: 'ازدحام شديد على طريقك. وقت إضافي متوقع: {extra_time} دقيقة.',
          icon: 'traffic',
          actions: ['view_traffic', 'find_alternative'],
        ),
        cooldown: const Duration(minutes: 15),
      ),
    );

    _rules.add(
      NotificationRule(
        id: 'ai_prediction',
        channel: NotificationChannel.ai,
        priority: NotificationPriority.medium,
        condition: (context) =>
            context.aiConfidence > 0.8 && context.riskScore > 0.6,
        template: NotificationTemplate(
          title: 'تنبؤ ذكي',
          body:
              'الذكاء الاصطناعي يتوقع مخاطر محتملة. دقة التنبؤ: {confidence}%',
          icon: 'ai',
          actions: ['view_prediction', 'ignore'],
        ),
        cooldown: const Duration(minutes: 45),
      ),
    );

    _rules.add(
      NotificationRule(
        id: 'route_optimization',
        channel: NotificationChannel.route,
        priority: NotificationPriority.low,
        condition: (context) =>
            context.hasAlternativeRoute && context.timeSavings > 10,
        template: NotificationTemplate(
          title: 'طريق أفضل متاح',
          body: 'وجدنا طريقاً أسرع يوفر {time_savings} دقيقة.',
          icon: 'route',
          actions: ['use_alternative', 'keep_current'],
        ),
        cooldown: const Duration(minutes: 20),
      ),
    );

    _rules.add(
      NotificationRule(
        id: 'emergency_alert',
        channel: NotificationChannel.emergency,
        priority: NotificationPriority.critical,
        condition: (context) => context.hasEmergency,
        template: NotificationTemplate(
          title: 'تحذير طوارئ',
          body: 'حالة طوارئ على طريقك: {emergency_type}',
          icon: 'emergency',
          actions: ['call_emergency', 'find_alternative'],
        ),
        cooldown: const Duration(minutes: 5),
      ),
    );
  }

  void _startNotificationEngine() {
    _notificationTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _processNotificationRules();
      _cleanupExpiredNotifications();
    });
  }

  Future<void> _processNotificationRules() async {
    try {
      // استخدام متغير مؤقت لتخزين السياق بدلاً من استخدام BuildContext مباشرة
      final notificationContext = await _buildNotificationContext();

      // التحقق من أن الخدمة لا تزال نشطة قبل معالجة القواعد
      if (_isDisposed) return;

      for (final rule in _rules) {
        if (_shouldProcessRule(rule, notificationContext)) {
          await _processRule(rule, notificationContext);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing notification rules: $e');
      }
    }
  }

  Future<NotificationContext> _buildNotificationContext() async {
    // This would normally gather real-time data
    // For demo purposes, we'll simulate some data
    final random = math.Random();

    return NotificationContext(
      timestamp: DateTime.now(),
      riskLevel: RiskLevel.values[random.nextInt(RiskLevel.values.length)],
      riskScore: random.nextDouble(),
      weatherCondition: WeatherCondition
          .values[random.nextInt(WeatherCondition.values.length)],
      trafficDensity: random.nextDouble(),
      aiConfidence: 0.7 + random.nextDouble() * 0.3,
      hasAlternativeRoute: random.nextBool(),
      timeSavings: random.nextInt(30),
      hasEmergency: random.nextDouble() < 0.05, // 5% chance
      emergencyType: 'حادث مروري',
      currentLocation: 'الرياض',
      destination: 'جدة',
    );
  }

  bool _shouldProcessRule(NotificationRule rule, NotificationContext context) {
    // Check if channel is enabled
    if (!_channelStates[rule.channel]!) return false;

    // Check user preferences
    final preference = _userPreferences[rule.channel.name];
    if (preference == null || !preference.enabled) return false;

    // Check quiet hours
    if (_isInQuietHours(preference.quietHours)) {
      return rule.priority == NotificationPriority.critical;
    }

    // Check cooldown
    if (_isInCooldown(rule)) return false;

    // Check condition
    return rule.condition(context);
  }

  bool _isInQuietHours(QuietHours quietHours) {
    if (!quietHours.enabled) return false;

    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    // Handle overnight quiet hours
    if (quietHours.startTime.hour > quietHours.endTime.hour) {
      return _isTimeAfter(currentTime, quietHours.startTime) ||
          _isTimeBefore(currentTime, quietHours.endTime);
    } else {
      return _isTimeAfter(currentTime, quietHours.startTime) &&
          _isTimeBefore(currentTime, quietHours.endTime);
    }
  }

  bool _isTimeAfter(TimeOfDay time, TimeOfDay reference) {
    return time.hour > reference.hour ||
        (time.hour == reference.hour && time.minute >= reference.minute);
  }

  bool _isTimeBefore(TimeOfDay time, TimeOfDay reference) {
    return time.hour < reference.hour ||
        (time.hour == reference.hour && time.minute <= reference.minute);
  }

  bool _isInCooldown(NotificationRule rule) {
    final lastSent = _getLastNotificationTime(rule.id);
    if (lastSent == null) return false;

    return DateTime.now().difference(lastSent) < rule.cooldown;
  }

  DateTime? _getLastNotificationTime(String ruleId) {
    final cached = CacheManager().get<String>('last_notification_$ruleId');
    return cached != null ? DateTime.parse(cached) : null;
  }

  Future<void> _processRule(
    NotificationRule rule,
    NotificationContext context,
  ) async {
    try {
      final notification = await _createNotification(rule, context);
      await _sendNotification(notification);

      // Update last sent time
      CacheManager().put(
        'last_notification_${rule.id}',
        DateTime.now().toIso8601String(),
        ttl: rule.cooldown * 2,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error processing rule ${rule.id}: $e');
      }
    }
  }

  Future<SmartNotification> _createNotification(
    NotificationRule rule,
    NotificationContext context,
  ) async {
    final template = rule.template;

    // Replace placeholders in template
    String title = template.title;
    String body = _replacePlaceholders(template.body, context);

    return SmartNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      channel: rule.channel,
      priority: rule.priority,
      icon: template.icon,
      actions: template.actions,
      timestamp: DateTime.now(),
      data: {'rule_id': rule.id, 'context': context.toJson()},
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  String _replacePlaceholders(String text, NotificationContext context) {
    return text
        .replaceAll('{extra_time}', '${(context.trafficDensity * 30).toInt()}')
        .replaceAll('{confidence}', '${(context.aiConfidence * 100).toInt()}')
        .replaceAll('{time_savings}', '${context.timeSavings}')
        .replaceAll('{emergency_type}', context.emergencyType)
        .replaceAll('{location}', context.currentLocation)
        .replaceAll('{destination}', context.destination);
  }

  Future<void> _sendNotification(SmartNotification notification) async {
    // Add to active notifications
    _activeNotifications.add(notification);

    // Trigger haptic feedback based on priority
    await _triggerHapticFeedback(notification.priority);

    // Send to stream
    _notificationController.add(notification);

    // Log analytics
    _logNotificationAnalytics(notification);

    if (kDebugMode) {
      print('Sent notification: ${notification.title}');
    }
  }

  Future<void> _triggerHapticFeedback(NotificationPriority priority) async {
    switch (priority) {
      case NotificationPriority.low:
        await HapticFeedback.selectionClick();
        break;
      case NotificationPriority.medium:
        await HapticFeedback.lightImpact();
        break;
      case NotificationPriority.high:
        await HapticFeedback.mediumImpact();
        break;
      case NotificationPriority.critical:
        await HapticFeedback.heavyImpact();
        break;
    }
  }

  void _logNotificationAnalytics(SmartNotification notification) {
    // Log notification metrics for analysis
    final analytics = {
      'notification_id': notification.id,
      'channel': notification.channel.name,
      'priority': notification.priority.name,
      'timestamp': notification.timestamp.toIso8601String(),
      'rule_id': notification.data['rule_id'],
    };

    CacheManager().put(
      'notification_analytics_${notification.id}',
      analytics,
      ttl: const Duration(days: 30),
    );
  }

  void _cleanupExpiredNotifications() {
    final now = DateTime.now();
    _activeNotifications.removeWhere((notification) {
      return notification.expiresAt.isBefore(now);
    });
  }

  // Public methods for notification management
  Future<void> sendCustomNotification({
    required String title,
    required String body,
    required NotificationChannel channel,
    NotificationPriority priority = NotificationPriority.medium,
    List<String> actions = const [],
    Map<String, dynamic> data = const {},
  }) async {
    final notification = SmartNotification(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      channel: channel,
      priority: priority,
      icon: 'custom',
      actions: actions,
      timestamp: DateTime.now(),
      data: data,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );

    await _sendNotification(notification);
  }

  void dismissNotification(String notificationId) {
    _activeNotifications.removeWhere((n) => n.id == notificationId);
  }

  void dismissAllNotifications() {
    _activeNotifications.clear();
  }

  void setChannelEnabled(NotificationChannel channel, bool enabled) {
    _channelStates[channel] = enabled;
    _saveChannelStates();
  }

  bool isChannelEnabled(NotificationChannel channel) {
    return _channelStates[channel] ?? true;
  }

  void updateUserPreference(
    String channelName,
    NotificationPreference preference,
  ) {
    _userPreferences[channelName] = preference;
    _saveUserPreferences();
  }

  NotificationPreference? getUserPreference(String channelName) {
    return _userPreferences[channelName];
  }

  Future<void> _saveChannelStates() async {
    final states = _channelStates.map(
      (key, value) => MapEntry(key.name, value),
    );
    CacheManager().put(
      'notification_channels',
      states,
      ttl: const Duration(days: 365),
    );
  }

  Future<void> _saveUserPreferences() async {
    final prefs = _userPreferences.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    CacheManager().put(
      'notification_preferences',
      prefs,
      ttl: const Duration(days: 365),
    );
  }

  // Analytics and insights
  Map<String, dynamic> getNotificationStats() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));

    final recent = _activeNotifications
        .where((n) => n.timestamp.isAfter(last24h))
        .toList();

    final byChannel = <String, int>{};
    final byPriority = <String, int>{};

    for (final notification in recent) {
      byChannel[notification.channel.name] =
          (byChannel[notification.channel.name] ?? 0) + 1;
      byPriority[notification.priority.name] =
          (byPriority[notification.priority.name] ?? 0) + 1;
    }

    return {
      'total_active': _activeNotifications.length,
      'last_24h': recent.length,
      'by_channel': byChannel,
      'by_priority': byPriority,
      'channels_enabled': _channelStates.values
          .where((enabled) => enabled)
          .length,
      'total_channels': _channelStates.length,
    };
  }

  List<SmartNotification> getNotificationHistory({
    NotificationChannel? channel,
    NotificationPriority? priority,
    DateTime? since,
  }) {
    var notifications = _activeNotifications.toList();

    if (channel != null) {
      notifications = notifications.where((n) => n.channel == channel).toList();
    }

    if (priority != null) {
      notifications = notifications
          .where((n) => n.priority == priority)
          .toList();
    }

    if (since != null) {
      notifications = notifications
          .where((n) => n.timestamp.isAfter(since))
          .toList();
    }

    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return notifications;
  }

  void dispose() {
    _isDisposed = true;
    _notificationTimer?.cancel();
    _notificationController.close();
    _activeNotifications.clear();
  }

  // إضافة وظائف إرسال البلاغات ورفع الصور
  Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(initializationSettings);
  }

  // إرسال بلاغ مع صورة
  Future<void> sendReport({
    required String type,
    required Map<String, dynamic> location,
    required String description,
    List<File>? images,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // رفع الصور إذا وجدت
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        for (var image in images) {
          String fileName =
              'reports/ ${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.jpg';
          final ref = _storage.ref().child(fileName);
          await ref.putFile(image);
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }

      // إنشاء البلاغ
      final reportRef = await _firestore
          .collection(FirebaseSchemaService.reportsCollection)
          .add({
            'userId': user.uid,
            'type': type,
            'location': location,
            'description': description,
            'imageUrls': imageUrls,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'status': 'pending',
            'verifiedBy': [],
            'rejectedBy': [],
          });

      // إرسال إشعار للمستخدم
      await sendFirebaseNotification(
        userId: user.uid,
        title: 'تم إرسال البلاغ',
        body: 'تم إرسال بلاغك بنجاح وسيتم مراجعته',
        type: 'report',
        data: {'reportId': reportRef.id},
      );

      // تحديث نقاط المستخدم
      await _firestore
          .collection(FirebaseSchemaService.usersCollection)
          .doc(user.uid)
          .update({
            'points': FieldValue.increment(5), // إضافة 5 نقاط لإرسال بلاغ
            'totalReports': FieldValue.increment(1),
          });
    } catch (e) {
      print('Error sending report: $e');
      throw Exception('فشل في إرسال البلاغ: $e');
    }
  }

  // إرسال إشعار إلى Firebase
  Future<void> sendFirebaseNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore
          .collection(FirebaseSchemaService.notificationsCollection)
          .add({
            'userId': userId,
            'title': title,
            'body': body,
            'type': type,
            'data': data,
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
            'readAt': null,
          });

      // إرسال إشعار محلي أيضًا
      await showLocalNotification(title: title, body: body, payload: type);
    } catch (e) {
      print('Error sending notification: $e');
      throw Exception('فشل في إرسال الإشعار');
    }
  }

  // إرسال إشعار محلي
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'saferoute_channel',
          'SafeRoute Notifications',
          channelDescription: 'Notifications for SafeRoute app',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // الحصول على بلاغات المستخدم
  Stream<QuerySnapshot> getUserReports() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    return _firestore
        .collection(FirebaseSchemaService.reportsCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

// Data models
class SmartNotification {
  final String id;
  final String title;
  final String body;
  final NotificationChannel channel;
  final NotificationPriority priority;
  final String icon;
  final List<String> actions;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final DateTime expiresAt;
  bool isRead;

  SmartNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.channel,
    required this.priority,
    required this.icon,
    required this.actions,
    required this.timestamp,
    required this.data,
    required this.expiresAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'channel': channel.name,
      'priority': priority.name,
      'icon': icon,
      'actions': actions,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'expires_at': expiresAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  factory SmartNotification.fromJson(Map<String, dynamic> json) {
    return SmartNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      channel: NotificationChannel.values.firstWhere(
        (c) => c.name == json['channel'],
      ),
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name == json['priority'],
      ),
      icon: json['icon'],
      actions: List<String>.from(json['actions']),
      timestamp: DateTime.parse(json['timestamp']),
      data: Map<String, dynamic>.from(json['data']),
      expiresAt: DateTime.parse(json['expires_at']),
      isRead: json['is_read'] ?? false,
    );
  }
}

class NotificationRule {
  final String id;
  final NotificationChannel channel;
  final NotificationPriority priority;
  final bool Function(NotificationContext) condition;
  final NotificationTemplate template;
  final Duration cooldown;

  NotificationRule({
    required this.id,
    required this.channel,
    required this.priority,
    required this.condition,
    required this.template,
    required this.cooldown,
  });
}

class NotificationTemplate {
  final String title;
  final String body;
  final String icon;
  final List<String> actions;

  NotificationTemplate({
    required this.title,
    required this.body,
    required this.icon,
    required this.actions,
  });
}

class NotificationContext {
  final DateTime timestamp;
  final RiskLevel riskLevel;
  final double riskScore;
  final WeatherCondition weatherCondition;
  final double trafficDensity;
  final double aiConfidence;
  final bool hasAlternativeRoute;
  final int timeSavings;
  final bool hasEmergency;
  final String emergencyType;
  final String currentLocation;
  final String destination;

  NotificationContext({
    required this.timestamp,
    required this.riskLevel,
    required this.riskScore,
    required this.weatherCondition,
    required this.trafficDensity,
    required this.aiConfidence,
    required this.hasAlternativeRoute,
    required this.timeSavings,
    required this.hasEmergency,
    required this.emergencyType,
    required this.currentLocation,
    required this.destination,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'risk_level': riskLevel.name,
      'risk_score': riskScore,
      'weather_condition': weatherCondition.name,
      'traffic_density': trafficDensity,
      'ai_confidence': aiConfidence,
      'has_alternative_route': hasAlternativeRoute,
      'time_savings': timeSavings,
      'has_emergency': hasEmergency,
      'emergency_type': emergencyType,
      'current_location': currentLocation,
      'destination': destination,
    };
  }
}

class NotificationPreference {
  final NotificationChannel channel;
  final bool enabled;
  final NotificationPriority priority;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final QuietHours quietHours;

  NotificationPreference({
    required this.channel,
    required this.enabled,
    required this.priority,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.quietHours,
  });

  Map<String, dynamic> toJson() {
    return {
      'channel': channel.name,
      'enabled': enabled,
      'priority': priority.name,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
      'quiet_hours': quietHours.toJson(),
    };
  }

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      channel: NotificationChannel.values.firstWhere(
        (c) => c.name == json['channel'],
      ),
      enabled: json['enabled'],
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name == json['priority'],
      ),
      soundEnabled: json['sound_enabled'],
      vibrationEnabled: json['vibration_enabled'],
      quietHours: QuietHours.fromJson(json['quiet_hours']),
    );
  }
}

class QuietHours {
  final bool enabled;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const QuietHours({
    required this.enabled,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'start_hour': startTime.hour,
      'start_minute': startTime.minute,
      'end_hour': endTime.hour,
      'end_minute': endTime.minute,
    };
  }

  factory QuietHours.fromJson(Map<String, dynamic> json) {
    return QuietHours(
      enabled: json['enabled'],
      startTime: TimeOfDay(
        hour: json['start_hour'],
        minute: json['start_minute'],
      ),
      endTime: TimeOfDay(hour: json['end_hour'], minute: json['end_minute']),
    );
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});
}

// Enums
enum NotificationChannel { safety, traffic, weather, route, ai, emergency }

enum NotificationPriority { low, medium, high, critical }

// Import required enums from AI service
enum RiskLevel { low, medium, high, critical }

enum WeatherCondition { clear, rain, snow, fog, storm }