import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import 'notifications_firebase_service.dart';

class NotificationsService {
  // Firebase service
  final NotificationsFirebaseService _firebaseService = NotificationsFirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Controller for notifications stream
  final _notificationsController = StreamController<List<NotificationModel>>.broadcast();
  
  // Stream for notifications
  Stream<List<NotificationModel>> get notificationsStream => _notificationsController.stream;
  
  // Initialize service
  Future<void> initialize() async {
    // Initialize Firebase service
    await _firebaseService.initialize();
    
    // Subscribe to Firebase notifications stream
    _firebaseService.getNotifications().listen((notifications) {
      _notificationsController.add(notifications);
    });
  }
  
  // Get all notifications
  Future<List<NotificationModel>> getNotifications() async {
    return _firebaseService.getNotifications().first;
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firebaseService.markAsRead(notificationId);
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _firebaseService.markAllAsRead();
  }
  
  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firebaseService.deleteNotification(notificationId);
  }
  
  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    await _firebaseService.deleteAllNotifications();
  }
  
  // Create notification
  Future<String> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? reportId,
    Map<String, dynamic>? data,
  }) async {
    return await _firebaseService.createNotification(
      title: title,
      body: body,
      type: type,
      reportId: reportId,
      data: data,
    );
  }
  
  // Get security settings
  Future<Map<String, dynamic>> getSecuritySettings() async {
    return await _firebaseService.getSecuritySettings();
  }
  
  // Update security settings
  Future<void> updateSecuritySettings(Map<String, dynamic> settings) async {
    await _firebaseService.updateSecuritySettings(settings);
  }
  
  // Add emergency contact
  Future<void> addEmergencyContact(String name, String phone) async {
    await _firebaseService.addEmergencyContact(name, phone);
  }
  
  // Remove emergency contact
  Future<void> removeEmergencyContact(String phone) async {
    await _firebaseService.removeEmergencyContact(phone);
  }
  
  // Dispose resources
  void dispose() {
    _notificationsController.close();
  }
}