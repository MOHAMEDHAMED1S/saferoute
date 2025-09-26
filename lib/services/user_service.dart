import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firebase_schema_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // الحصول على مرجع للمستخدمين
  CollectionReference get _usersCollection => 
      _firestore.collection(FirebaseSchemaService.usersCollection);
  
  // الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;
  
  // الحصول على بيانات المستخدم الحالي
  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) return null;
    
    try {
      final docSnapshot = await _usersCollection.doc(currentUser!.uid).get();
      if (docSnapshot.exists) {
        return UserModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
  }
  
  // الحصول على بيانات مستخدم محدد
  Future<UserModel?> getUserById(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (docSnapshot.exists) {
        return UserModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }
  
  // إنشاء مستخدم جديد
  Future<bool> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toFirestore());
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }
  
  // تحديث بيانات المستخدم
  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(userId).update(data);
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }
  
  // تحديث الملف الشخصي للمستخدم
  Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    final Map<String, dynamic> updates = {};
    
    if (name != null && name.isNotEmpty) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    
    if (updates.isEmpty) return true; // لا يوجد تحديثات
    
    return updateUser(userId, updates);
  }
  
  // تحديث إعدادات المستخدم
  Future<bool> updateUserSettings({
    required String userId,
    bool? notifications,
    bool? darkMode,
    String? language,
  }) async {
    final Map<String, dynamic> updates = {};
    
    if (notifications != null) updates['settings.notifications'] = notifications;
    if (darkMode != null) updates['settings.darkMode'] = darkMode;
    if (language != null) updates['settings.language'] = language;
    
    if (updates.isEmpty) return true; // لا يوجد تحديثات
    
    return updateUser(userId, updates);
  }
  
  // تحديث إعدادات القيادة
  Future<bool> updateDrivingSettings({
    required String userId,
    bool? voiceAlerts,
    bool? autoReport,
    String? safetyMode,
    String? distanceUnit,
  }) async {
    final Map<String, dynamic> updates = {};
    
    if (voiceAlerts != null) updates['drivingSettings.voiceAlerts'] = voiceAlerts;
    if (autoReport != null) updates['drivingSettings.autoReport'] = autoReport;
    if (safetyMode != null) updates['drivingSettings.safetyMode'] = safetyMode;
    if (distanceUnit != null) updates['drivingSettings.distanceUnit'] = distanceUnit;
    
    if (updates.isEmpty) return true; // لا يوجد تحديثات
    
    return updateUser(userId, updates);
  }
  
  // تحديث موقع المستخدم
  Future<bool> updateUserLocation(String userId, double latitude, double longitude) async {
    final Map<String, dynamic> locationData = {
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }
    };
    
    return updateUser(userId, locationData);
  }
  
  // تحديث وضع القيادة
  Future<bool> toggleDriverMode(String userId, bool isDriverMode) async {
    return updateUser(userId, {'isDriverMode': isDriverMode});
  }
  
  // زيادة نقاط المستخدم
  Future<bool> incrementUserPoints(String userId, int points) async {
    try {
      await _usersCollection.doc(userId).update({
        'points': FieldValue.increment(points),
      });
      return true;
    } catch (e) {
      print('Error incrementing user points: $e');
      return false;
    }
  }
  
  // زيادة عدد التقارير
  Future<bool> incrementTotalReports(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'totalReports': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      print('Error incrementing total reports: $e');
      return false;
    }
  }
  
  // تحديث درجة الثقة
  Future<bool> updateTrustScore(String userId, double newScore) async {
    return updateUser(userId, {'trustScore': newScore});
  }
  
  // تحديث وقت آخر تسجيل دخول
  Future<bool> updateLastLogin(String userId) async {
    return updateUser(userId, {'lastLogin': FieldValue.serverTimestamp()});
  }
}