import 'package:flutter/material.dart';
import 'dart:async';
import '../models/notification_model.dart';
import '../models/report_model.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';

class NotificationsProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  List<NotificationModel> _notifications = [];
  List<NotificationModel> _unreadNotifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications => _unreadNotifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  int get unreadCount => _unreadNotifications.length;
  bool get hasUnreadNotifications => _unreadNotifications.isNotEmpty;

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((notification) => notification.type == type).toList();
  }

  // Get alert notifications
  List<NotificationModel> get alertNotifications {
    return _notifications.where((notification) => notification.isAlert).toList();
  }

  // Get confirmation notifications
  List<NotificationModel> get confirmationNotifications {
    return _notifications.where((notification) => !notification.isAlert).toList();
  }

  // Get recent notifications (last 24 hours)
  List<NotificationModel> get recentNotifications {
    DateTime yesterday = DateTime.now().subtract(const Duration(hours: 24));
    return _notifications.where((notification) => 
      notification.createdAt.isAfter(yesterday)
    ).toList();
  }

  // Initialize notifications provider
  Future<void> initialize(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      // Initialize notification service
      await _notificationService.initialize();
      
      // Start listening to user notifications
      await _startListeningToNotifications(userId);
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تهيئة الإشعارات: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Start listening to notifications stream
  Future<void> _startListeningToNotifications(String userId) async {
    _notificationsSubscription?.cancel();
    
    // TODO: Implement getUserNotificationsStream in FirestoreService
    // _notificationsSubscription = _firestoreService.getUserNotificationsStream(userId).listen(
    //   (notifications) {
    //     _notifications = notifications;
    //     _updateUnreadNotifications();
    //     notifyListeners();
    //   },
    //   onError: (error) {
    //     _setError('خطأ في تحميل الإشعارات: ${error.toString()}');
    //   },
    // );
  }

  // Update unread notifications list
  void _updateUnreadNotifications() {
    _unreadNotifications = _notifications.where((notification) => !notification.isRead).toList();
  }

  // Send report alert notification
  Future<void> sendReportAlert({
    required ReportModel report,
    required String targetUserId,
    required int distanceInMeters,
  }) async {
    try {
      if (!_notificationsEnabled) return;

      await _notificationService.showTrafficAlert(
        report: report,
        distanceInMeters: distanceInMeters.toDouble(),
      );
    } catch (e) {
      _setError('خطأ في إرسال إشعار البلاغ: ${e.toString()}');
    }
  }

  // Send confirmation notification
  Future<void> sendConfirmationNotification({
    required String userId,
    required String reportId,
    required String message,
    required int pointsEarned,
  }) async {
    try {
      if (!_notificationsEnabled) return;

      NotificationModel notification = NotificationModel.createConfirmation(
        userId: userId,
        reportId: reportId,
        isConfirmed: true,
        pointsEarned: pointsEarned,
      );

      // TODO: Save notification to Firestore
      // await _firestoreService.addNotification(notification);

      // Show local notification
      await _notificationService.showConfirmationNotification(
        reportId: reportId,
        reportType: 'بلاغ',
        isConfirmed: true,
      );
    } catch (e) {
      _setError('خطأ في إرسال إشعار التأكيد: ${e.toString()}');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      // Find notification in local list
      int index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        // Update local state
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _updateUnreadNotifications();
        notifyListeners();

        // TODO: Update in Firestore
        // await _firestoreService.markNotificationAsRead(notificationId);
      }
    } catch (e) {
      _setError('خطأ في تحديث حالة الإشعار: ${e.toString()}');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      _setLoading(true);
      
      // Update local state
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      _updateUnreadNotifications();
      notifyListeners();

      // TODO: Update all in Firestore
      // await _firestoreService.markAllNotificationsAsRead(userId);
    } catch (e) {
      _setError('خطأ في تحديث جميع الإشعارات: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Remove from local list
      _notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadNotifications();
      notifyListeners();

      // TODO: Delete from Firestore
      // await _firestoreService.deleteNotification(notificationId);
    } catch (e) {
      _setError('خطأ في حذف الإشعار: ${e.toString()}');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    try {
      _setLoading(true);
      
      // Clear local state
      _notifications.clear();
      _unreadNotifications.clear();
      notifyListeners();

      // TODO: Clear all from Firestore
      // await _firestoreService.clearAllNotifications(userId);
    } catch (e) {
      _setError('خطأ في مسح جميع الإشعارات: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (!_notificationsEnabled) return;

      // TODO: Implement showLocalNotification method in NotificationService
      // await _notificationService.showLocalNotification(
      //   title: title,
      //   body: body,
      //   data: data,
      // );
    } catch (e) {
      _setError('خطأ في عرض الإشعار: ${e.toString()}');
    }
  }

  // Play alert sound
  Future<void> playAlertSound() async {
    try {
      if (!_soundEnabled) return;
      // TODO: Implement playAlertSound method in NotificationService
      // await _notificationService.playAlertSound();
    } catch (e) {
      print('Error playing alert sound: $e');
    }
  }

  // Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    try {
      return await _notificationService.requestPermissions();
    } catch (e) {
      _setError('خطأ في طلب أذونات الإشعارات: ${e.toString()}');
      return false;
    }
  }

  // Update notification settings
  void updateNotificationSettings({
    bool? enabled,
    bool? sound,
    bool? vibration,
  }) {
    if (enabled != null) {
      _notificationsEnabled = enabled;
    }
    if (sound != null) {
      _soundEnabled = sound;
    }
    if (vibration != null) {
      _vibrationEnabled = vibration;
    }
    notifyListeners();
  }

  // Get notification settings
  Map<String, bool> getNotificationSettings() {
    return {
      'enabled': _notificationsEnabled,
      'sound': _soundEnabled,
      'vibration': _vibrationEnabled,
    };
  }

  // Filter notifications by criteria
  List<NotificationModel> filterNotifications({
    List<NotificationType>? types,
    bool? isRead,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    List<NotificationModel> filtered = List.from(_notifications);

    if (types != null && types.isNotEmpty) {
      filtered = filtered.where((notification) => types.contains(notification.type)).toList();
    }

    if (isRead != null) {
      filtered = filtered.where((notification) => notification.isRead == isRead).toList();
    }

    if (fromDate != null) {
      filtered = filtered.where((notification) => notification.createdAt.isAfter(fromDate)).toList();
    }

    if (toDate != null) {
      filtered = filtered.where((notification) => notification.createdAt.isBefore(toDate)).toList();
    }

    return filtered;
  }

  // Search notifications
  List<NotificationModel> searchNotifications(String query) {
    if (query.isEmpty) return _notifications;
    
    String lowerQuery = query.toLowerCase();
    return _notifications.where((notification) {
      return notification.title.toLowerCase().contains(lowerQuery) ||
             notification.body.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get notification statistics
  Map<String, int> getNotificationStats() {
    Map<String, int> stats = {
      'total': _notifications.length,
      'unread': _unreadNotifications.length,
      'alerts': alertNotifications.length,
      'confirmations': confirmationNotifications.length,
    };

    // Count by type
    for (NotificationType type in NotificationType.values) {
      List<NotificationModel> typeNotifications = getNotificationsByType(type);
      stats[type.toString().split('.').last] = typeNotifications.length;
    }

    return stats;
  }

  // Check if notification exists
  bool hasNotification(String notificationId) {
    return _notifications.any((notification) => notification.id == notificationId);
  }

  // Get notification by ID
  NotificationModel? getNotificationById(String notificationId) {
    try {
      return _notifications.firstWhere((notification) => notification.id == notificationId);
    } catch (e) {
      return null;
    }
  }

  // Refresh notifications
  Future<void> refreshNotifications(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // TODO: Reload notifications from Firestore
      // List<NotificationModel> notifications = await _firestoreService.getUserNotifications(userId);
      // _notifications = notifications;
      // _updateUnreadNotifications();
      // notifyListeners();
    } catch (e) {
      _setError('خطأ في تحديث الإشعارات: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
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
    _notifications.clear();
    _unreadNotifications.clear();
    _isLoading = false;
    _errorMessage = null;
    _isInitialized = false;
    _notificationsSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}