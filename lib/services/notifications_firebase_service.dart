import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';

class NotificationsFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // Collection references
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');
  CollectionReference get _securityCollection => _firestore.collection('security');
  
  // Initialize notifications
  Future<void> initialize() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      String? token = await _messaging.getToken();
      
      if (token != null) {
        // Save token to user document
        await _firestore.collection('users').doc(user.uid).update({
          'fcmTokens': FieldValue.arrayUnion([token]),
        });
      }
    }
  }
  
  // Get notifications for current user
  Stream<List<NotificationModel>> getNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    return _notificationsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    DocumentSnapshot doc = await _notificationsCollection.doc(notificationId).get();
    if (!doc.exists) {
      throw Exception('Notification not found');
    }
    
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    if (data['userId'] != user.uid) {
      throw Exception('Not authorized to update this notification');
    }
    
    await _notificationsCollection.doc(notificationId).update({
      'isRead': true,
    });
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    QuerySnapshot snapshot = await _notificationsCollection
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();
    
    WriteBatch batch = _firestore.batch();
    
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }
  
  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    DocumentSnapshot doc = await _notificationsCollection.doc(notificationId).get();
    if (!doc.exists) {
      throw Exception('Notification not found');
    }
    
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    if (data['userId'] != user.uid) {
      throw Exception('Not authorized to delete this notification');
    }
    
    await _notificationsCollection.doc(notificationId).delete();
  }
  
  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    QuerySnapshot snapshot = await _notificationsCollection
        .where('userId', isEqualTo: user.uid)
        .get();
    
    WriteBatch batch = _firestore.batch();
    
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
  
  // Create notification
  Future<String> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? reportId,
    Map<String, dynamic>? data,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    NotificationModel notification = NotificationModel(
      id: '', // Will be set by Firestore
      userId: user.uid,
      reportId: reportId,
      title: title,
      body: body,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
      data: data,
    );
    
    DocumentReference docRef = await _notificationsCollection.add({
      'userId': notification.userId,
      'reportId': notification.reportId,
      'title': notification.title,
      'body': notification.body,
      'type': _notificationTypeToString(notification.type),
      'isRead': notification.isRead,
      'createdAt': Timestamp.fromDate(notification.createdAt),
      'data': notification.data,
    });
    
    return docRef.id;
  }
  
  // Get security settings
  Future<Map<String, dynamic>> getSecuritySettings() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    DocumentSnapshot doc = await _securityCollection.doc(user.uid).get();
    
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    } else {
      // Create default security settings
      Map<String, dynamic> defaultSettings = {
        'biometricEnabled': false,
        'pinEnabled': false,
        'pin': '',
        'locationSharingEnabled': true,
        'emergencyContactsEnabled': false,
        'emergencyContacts': [],
        'dataEncryptionEnabled': true,
        'twoFactorAuthEnabled': false,
        'privacyMode': 'standard',
      };
      
      await _securityCollection.doc(user.uid).set(defaultSettings);
      
      return defaultSettings;
    }
  }
  
  // Update security settings
  Future<void> updateSecuritySettings(Map<String, dynamic> settings) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    await _securityCollection.doc(user.uid).update(settings);
  }
  
  // Add emergency contact
  Future<void> addEmergencyContact(String name, String phone) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    await _securityCollection.doc(user.uid).update({
      'emergencyContactsEnabled': true,
      'emergencyContacts': FieldValue.arrayUnion([
        {
          'name': name,
          'phone': phone,
        }
      ]),
    });
  }
  
  // Remove emergency contact
  Future<void> removeEmergencyContact(String phone) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    DocumentSnapshot doc = await _securityCollection.doc(user.uid).get();
    if (!doc.exists) {
      throw Exception('Security settings not found');
    }
    
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<dynamic> contacts = List.from(data['emergencyContacts'] ?? []);
    
    contacts.removeWhere((contact) => contact['phone'] == phone);
    
    await _securityCollection.doc(user.uid).update({
      'emergencyContacts': contacts,
      'emergencyContactsEnabled': contacts.isNotEmpty,
    });
  }
  
  // Helper methods for enum conversion
  static NotificationType _stringToNotificationType(String type) {
    switch (type) {
      case 'accident_alert':
        return NotificationType.accidentAlert;
      case 'jam_alert':
        return NotificationType.jamAlert;
      case 'car_breakdown_alert':
        return NotificationType.carBreakdownAlert;
      case 'bump_alert':
        return NotificationType.bumpAlert;
      case 'closed_road_alert':
        return NotificationType.closedRoadAlert;
      case 'report_confirmed':
        return NotificationType.reportConfirmed;
      case 'report_denied':
        return NotificationType.reportDenied;
      case 'points_earned':
        return NotificationType.pointsEarned;
      default:
        return NotificationType.accidentAlert;
    }
  }
  
  static String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.accidentAlert:
        return 'accident_alert';
      case NotificationType.jamAlert:
        return 'jam_alert';
      case NotificationType.carBreakdownAlert:
        return 'car_breakdown_alert';
      case NotificationType.bumpAlert:
        return 'bump_alert';
      case NotificationType.closedRoadAlert:
        return 'closed_road_alert';
      case NotificationType.reportConfirmed:
        return 'report_confirmed';
      case NotificationType.reportDenied:
        return 'report_denied';
      case NotificationType.pointsEarned:
        return 'points_earned';
    }
  }
}