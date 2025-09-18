import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/notification_model.dart';
import '../models/report_model.dart';
import 'firestore_service.dart';

// Top-level function for background message handling
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirestoreService _firestoreService = FirestoreService();

  String? _fcmToken;
  bool _isInitialized = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();
      
      _isInitialized = true;
      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
      throw 'خطأ في تهيئة خدمة الإشعارات: ${e.toString()}';
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
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

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
      'traffic_alerts',
      'تنبيهات المرور',
      description: 'إشعارات تنبيهات المخاطر المرورية',
      importance: Importance.high,
      sound: const RawResourceAndroidNotificationSound('alert_sound'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general',
      'إشعارات عامة',
      description: 'الإشعارات العامة للتطبيق',
      importance: Importance.defaultImportance,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  // Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      throw 'تم رفض إذن الإشعارات';
    }

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('FCM Token refreshed: $newToken');
      // Update token in Firestore if user is logged in
      _updateTokenInFirestore(newToken);
    });
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'تنبيه مروري',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
      isAlert: message.data['type'] == 'traffic_alert',
    );
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    // Handle navigation based on notification data
    _handleNotificationNavigation(message.data);
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Parse payload and handle navigation
    if (response.payload != null) {
      // Handle navigation based on payload
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool isAlert = false,
  }) async {
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      isAlert ? 'traffic_alerts' : 'general',
      isAlert ? 'تنبيهات المرور' : 'إشعارات عامة',
      channelDescription: isAlert 
          ? 'إشعارات تنبيهات المخاطر المرورية'
          : 'الإشعارات العامة للتطبيق',
      importance: isAlert ? Importance.high : Importance.defaultImportance,
      priority: isAlert ? Priority.high : Priority.defaultPriority,
      sound: _soundEnabled 
          ? (isAlert ? const RawResourceAndroidNotificationSound('alert_sound') : null)
          : null,
      enableVibration: _vibrationEnabled,
      vibrationPattern: isAlert && _vibrationEnabled 
          ? Int64List.fromList([0, 1000, 500, 1000])
          : null,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    // Play alert sound if enabled and it's an alert
    if (isAlert && _soundEnabled) {
      await _playAlertSound();
    }
  }

  // Play alert sound
  Future<void> _playAlertSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      print('Error playing alert sound: $e');
    }
  }

  // Show traffic alert notification
  Future<void> showTrafficAlert({
    required ReportModel report,
    required double distanceInMeters,
  }) async {
    String distanceText = distanceInMeters < 1000 
        ? '${distanceInMeters.round()} متر'
        : '${(distanceInMeters / 1000).toStringAsFixed(1)} كم';
    
    String title = 'تحذير: ${_getReportTypeInArabic(report.type)}';
    String body = 'يوجد ${_getReportTypeInArabic(report.type)} على بعد $distanceText';
    
    await _showLocalNotification(
      title: title,
      body: body,
      payload: 'traffic_alert:${report.id}',
      isAlert: true,
    );

    // Save notification to Firestore
    await _saveNotificationToFirestore(
      NotificationModel.createAlert(
        userId: 'current_user', // This should be the current user ID
        reportId: report.id!,
        type: _getNotificationTypeFromReportType(report.type),
        hazardType: _getReportTypeInArabic(report.type),
        distanceInMeters: distanceInMeters.round(),
      ),
    );
  }

  // Show confirmation notification
  Future<void> showConfirmationNotification({
    required String reportId,
    required String reportType,
    required bool isConfirmed,
  }) async {
    String title = isConfirmed ? 'تم تأكيد البلاغ' : 'تم رفض البلاغ';
    String body = isConfirmed 
        ? 'تم تأكيد بلاغ $reportType من قبل مستخدم آخر'
        : 'تم رفض بلاغ $reportType من قبل مستخدم آخر';
    
    await _showLocalNotification(
      title: title,
      body: body,
      payload: 'confirmation:$reportId',
    );

    // Save notification to Firestore
    await _saveNotificationToFirestore(
      NotificationModel.createConfirmation(
        userId: 'current_user', // This should be the current user ID
        reportId: reportId,
        isConfirmed: isConfirmed,
        pointsEarned: isConfirmed ? 5 : 0,
      ),
    );
  }

  // Save notification to Firestore
  Future<void> _saveNotificationToFirestore(NotificationModel notification) async {
    try {
      // TODO: Implement addNotification method in FirestoreService
      // await _firestoreService.addNotification(notification);
      print('Notification saved: ${notification.title}');
    } catch (e) {
      print('Error saving notification to Firestore: $e');
    }
  }

  // Get report type in Arabic
  String _getReportTypeInArabic(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return 'حادث';
      case ReportType.jam:
        return 'ازدحام';
      case ReportType.carBreakdown:
        return 'سيارة معطلة';
      case ReportType.bump:
        return 'مطب';
      case ReportType.closedRoad:
        return 'طريق مغلق';
    }
  }

  // Get notification type from report type
  NotificationType _getNotificationTypeFromReportType(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return NotificationType.accidentAlert;
      case ReportType.jam:
        return NotificationType.jamAlert;
      case ReportType.carBreakdown:
        return NotificationType.carBreakdownAlert;
      case ReportType.bump:
        return NotificationType.bumpAlert;
      case ReportType.closedRoad:
        return NotificationType.closedRoadAlert;
    }
  }

  // Update FCM token in Firestore
  Future<void> _updateTokenInFirestore(String token) async {
    try {
      // This would be called when user is logged in
      // await _firestoreService.updateUserFCMToken(token);
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    String? type = data['type'];
    String? reportId = data['reportId'];
    
    switch (type) {
      case 'traffic_alert':
        // Navigate to map with report highlighted
        break;
      case 'confirmation':
        // Navigate to report details or profile
        break;
      default:
        // Navigate to home
        break;
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  // Enable/disable sound
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  // Enable/disable vibration
  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final settings = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings ?? false;
    }
    return false;
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      return await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }
    return false;
  }

  // Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}