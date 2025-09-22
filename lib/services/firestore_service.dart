import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';
import '../models/notification_model.dart';
import '../models/app_settings_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _reportsCollection => _firestore.collection('reports');
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');
  CollectionReference get _settingsCollection => _firestore.collection('settings');

  // ========== USER OPERATIONS ==========

  // Get user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'خطأ في جلب بيانات المستخدم: ${e.toString()}';
    }
  }

  // Create user
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toFirestore());
    } catch (e) {
      throw 'خطأ في إنشاء بيانات المستخدم: ${e.toString()}';
    }
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).update(user.toFirestore());
    } catch (e) {
      throw 'خطأ في تحديث بيانات المستخدم: ${e.toString()}';
    }
  }

  // Update user location
  Future<void> updateUserLocation(String userId, LocationData location) async {
    try {
      await _usersCollection.doc(userId).update({
        'location': location.toMap(),
      });
    } catch (e) {
      throw 'خطأ في تحديث موقع المستخدم: ${e.toString()}';
    }
  }

  // Update user driver mode
  Future<void> updateDriverMode(String userId, bool isDriverMode) async {
    try {
      await _usersCollection.doc(userId).update({
        'isDriverMode': isDriverMode,
      });
    } catch (e) {
      throw 'خطأ في تحديث وضع القيادة: ${e.toString()}';
    }
  }

  // Get users stream (for real-time location updates)
  Stream<List<UserModel>> getUsersStream() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // Get nearby users
  Future<List<UserModel>> getNearbyUsers({
    required double latitude,
    required double longitude,
    required double radiusInKm,
  }) async {
    try {
      // Note: This is a simplified approach. For production, consider using GeoFlutterFire
      // for more efficient geospatial queries
      QuerySnapshot snapshot = await _usersCollection
          .where('location', isNotEqualTo: null)
          .get();
      
      List<UserModel> users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) {
            if (user.location == null) return false;
            double distance = _calculateDistance(
              latitude,
              longitude,
              user.location!.lat,
              user.location!.lng,
            );
            return distance <= radiusInKm;
          })
          .toList();
      
      return users;
    } catch (e) {
      throw 'خطأ في جلب المستخدمين القريبين: ${e.toString()}';
    }
  }

  // ========== REPORT OPERATIONS ==========

  // Create report
  Future<String> createReport(ReportModel report) async {
    try {
      DocumentReference docRef = await _reportsCollection.add(report.toFirestore());
      
      // Update user's total reports count
      await _usersCollection.doc(report.createdBy).update({
        'totalReports': FieldValue.increment(1),
      });
      
      return docRef.id;
    } catch (e) {
      throw 'خطأ في إنشاء البلاغ: ${e.toString()}';
    }
  }

  // Get report by ID
  Future<ReportModel?> getReport(String reportId) async {
    try {
      DocumentSnapshot doc = await _reportsCollection.doc(reportId).get();
      if (doc.exists) {
        return ReportModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'خطأ في جلب البلاغ: ${e.toString()}';
    }
  }

  // Get active reports
  Stream<List<ReportModel>> getActiveReportsStream() {
    return _reportsCollection
        .where('status', isEqualTo: 'active')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
    });
  }

  // Get nearby reports
  Future<List<ReportModel>> getNearbyReports({
    required double latitude,
    required double longitude,
    required double radiusInKm,
  }) async {
    try {
      QuerySnapshot snapshot = await _reportsCollection
          .where('status', isEqualTo: 'active')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .get();
      
      List<ReportModel> reports = snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .where((report) {
            double distance = _calculateDistance(
              latitude,
              longitude,
              report.location.lat,
              report.location.lng,
            );
            return distance <= radiusInKm;
          })
          .toList();
      
      return reports;
    } catch (e) {
      throw 'خطأ في جلب البلاغات القريبة: ${e.toString()}';
    }
  }

  // Confirm report
  Future<void> confirmReport(String reportId, String userId, bool isTrue) async {
    try {
      DocumentReference reportRef = _reportsCollection.doc(reportId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot reportSnapshot = await transaction.get(reportRef);
        
        if (!reportSnapshot.exists) {
          throw 'البلاغ غير موجود';
        }
        
        ReportModel report = ReportModel.fromFirestore(reportSnapshot);
        
        // Check if user already confirmed/denied this report
        if (report.confirmedBy.contains(userId) ||
            report.deniedBy.contains(userId)) {
          throw 'لقد قمت بالتصويت على هذا البلاغ من قبل';
        }
        
        // Update confirmations
        ReportConfirmations updatedConfirmations;
        List<String> updatedConfirmedBy;
        List<String> updatedDeniedBy;
        
        if (isTrue) {
          updatedConfirmations = report.confirmations.copyWith(
            trueVotes: report.confirmations.trueVotes + 1,
          );
          updatedConfirmedBy = [...report.confirmedBy, userId];
          updatedDeniedBy = report.deniedBy;
        } else {
          updatedConfirmations = report.confirmations.copyWith(
            falseVotes: report.confirmations.falseVotes + 1,
          );
          updatedConfirmedBy = report.confirmedBy;
          updatedDeniedBy = [...report.deniedBy, userId];
        }
        
        // Update report
        transaction.update(reportRef, {
          'confirmations': updatedConfirmations.toMap(),
          'confirmedBy': updatedConfirmedBy,
          'deniedBy': updatedDeniedBy,
        });
        
        // Award points to the user who confirmed
        DocumentReference userRef = _usersCollection.doc(userId);
        transaction.update(userRef, {
          'points': FieldValue.increment(isTrue ? 5 : 2),
        });
        
        // Update trust score of report creator if enough votes
        int totalVotes = updatedConfirmations.trueVotes + updatedConfirmations.falseVotes;
        if (totalVotes >= 5) {
          double accuracy = updatedConfirmations.trueVotes / totalVotes;
          DocumentReference creatorRef = _usersCollection.doc(report.createdBy);
          
          // Simple trust score update (can be made more sophisticated)
          if (accuracy >= 0.7) {
            transaction.update(creatorRef, {
              'trustScore': FieldValue.increment(0.01),
              'points': FieldValue.increment(10),
            });
          } else if (accuracy < 0.3) {
            transaction.update(creatorRef, {
              'trustScore': FieldValue.increment(-0.02),
            });
          }
        }
      });
    } catch (e) {
      throw 'خطأ في تأكيد البلاغ: ${e.toString()}';
    }
  }

  // Delete report
  Future<void> deleteReport(String reportId) async {
    try {
      await _reportsCollection.doc(reportId).update({
        'status': 'removed',
      });
    } catch (e) {
      throw 'خطأ في حذف البلاغ: ${e.toString()}';
    }
  }

  // Get user reports
  Future<List<ReportModel>> getUserReports(String userId) async {
    try {
      QuerySnapshot snapshot = await _reportsCollection
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'خطأ في جلب بلاغات المستخدم: ${e.toString()}';
    }
  }

  // ========== NOTIFICATION OPERATIONS ==========

  // Create notification
  Future<String> createNotification(NotificationModel notification) async {
    try {
      DocumentReference docRef = await _notificationsCollection.add(notification.toFirestore());
      return docRef.id;
    } catch (e) {
      throw 'خطأ في إنشاء الإشعار: ${e.toString()}';
    }
  }

  // Get user notifications
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
    });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw 'خطأ في تحديث حالة الإشعار: ${e.toString()}';
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      throw 'خطأ في تحديث حالة الإشعارات: ${e.toString()}';
    }
  }

  // ========== SETTINGS OPERATIONS ==========

  // Get app settings
  Future<AppSettingsModel> getAppSettings() async {
    try {
      DocumentSnapshot doc = await _settingsCollection.doc('app').get();
      if (doc.exists) {
        return AppSettingsModel.fromFirestore(doc);
      } else {
        // Create default settings if not exists
        AppSettingsModel defaultSettings = AppSettingsModel.defaultSettings();
        await _settingsCollection.doc('app').set(defaultSettings.toFirestore());
        return defaultSettings;
      }
    } catch (e) {
      throw 'خطأ في جلب إعدادات التطبيق: ${e.toString()}';
    }
  }

  // Update app settings
  Future<void> updateAppSettings(AppSettingsModel settings) async {
    try {
      await _settingsCollection.doc('app').update(settings.toFirestore());
    } catch (e) {
      throw 'خطأ في تحديث إعدادات التطبيق: ${e.toString()}';
    }
  }

  // ========== UTILITY METHODS ==========

  // Calculate distance between two points (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Clean up expired reports (should be called periodically)
  Future<void> cleanupExpiredReports() async {
    try {
      QuerySnapshot snapshot = await _reportsCollection
          .where('expiresAt', isLessThan: Timestamp.now())
          .where('status', isEqualTo: 'active')
          .get();
      
      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in snapshot.docs) {
        batch.update(doc.reference, {'status': 'expired'});
      }
      
      await batch.commit();
    } catch (e) {
      throw 'خطأ في تنظيف البلاغات المنتهية الصلاحية: ${e.toString()}';
    }
  }

  // Get leaderboard (top users by points)
  Future<List<UserModel>> getLeaderboard({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _usersCollection
          .orderBy('points', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'خطأ في جلب لوحة المتصدرين: ${e.toString()}';
    }
  }
}