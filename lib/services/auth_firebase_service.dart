import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'google_auth_web_service.dart';

class AuthFirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleAuthWebService _googleWebService = GoogleAuthWebService();

  // الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;
  
  // التحقق من حالة تسجيل الدخول
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // تحديث وقت آخر تسجيل دخول
      if (userCredential.user != null) {
        await _firestore.collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // إنشاء حساب جديد باستخدام البريد الإلكتروني وكلمة المرور
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // إنشاء وثيقة المستخدم في Firestore
      if (userCredential.user != null) {
        final now = DateTime.now();
        final userModel = UserModel(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          createdAt: now,
          lastLogin: now,
        );
        
        await _firestore.collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toFirestore());
            
        // إنشاء إعدادات المستخدم الافتراضية
        await _createDefaultUserSettings(userCredential.user!.uid);
      }
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // تسجيل الدخول بـ Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        print('AuthFirebaseService: تسجيل الدخول بـ Google للويب باستخدام Popup');
        
        // For web, use popup method directly
        UserCredential? result = await _googleWebService.signInWithGoogle();

        if (result?.user != null) {
          print('AuthFirebaseService: تم تسجيل الدخول بنجاح، إنشاء/تحديث بيانات المستخدم');
          // Create or update user document
          await _createOrUpdateUserDocument(
            uid: result!.user!.uid,
            email: result.user!.email ?? '',
            name: result.user!.displayName ?? 'مستخدم',
            photoUrl: result.user!.photoURL,
          );
        }

        return result;
      } else {
        throw UnsupportedError('Google Sign-In is only supported on web platform in this service');
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // Get redirect result (for web)
  Future<UserCredential?> getGoogleRedirectResult() async {
    if (!kIsWeb) return null;
    
    try {
      UserCredential? result = await _googleWebService.getRedirectResult();
      
      if (result?.user != null) {
        await _createOrUpdateUserDocument(
          uid: result!.user!.uid,
          email: result.user!.email ?? '',
          name: result.user!.displayName ?? 'مستخدم',
          photoUrl: result.user!.photoURL,
        );
      }
      
      return result;
    } catch (e) {
      print('Error getting redirect result: $e');
      return null;
    }
  }

  // تحديث بيانات المستخدم
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    
    await userRef.update(updates);
  }

  // الحصول على بيانات المستخدم
  Future<UserModel?> getUserData(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();
          
      if (docSnapshot.exists) {
        return UserModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // إنشاء أو تحديث وثيقة المستخدم
  Future<void> _createOrUpdateUserDocument({
    required String uid,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    DocumentReference userDoc = _firestore.collection('users').doc(uid);
    DocumentSnapshot doc = await userDoc.get();

    if (!doc.exists) {
      // Create new user document
      final now = DateTime.now();
      final userModel = UserModel(
        id: uid,
        name: name,
        email: email,
        phone: '',
        photoUrl: photoUrl,
        createdAt: now,
        lastLogin: now,
      );
      
      await userDoc.set(userModel.toFirestore());
      
      // Create default settings
      await _createDefaultUserSettings(uid);
    } else {
      // Update last login
      await userDoc.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  // إنشاء إعدادات المستخدم الافتراضية
  Future<void> _createDefaultUserSettings(String userId) async {
    // إعدادات عامة
    await _firestore.collection('settings').doc(userId).set({
      'notifications': {
        'pushEnabled': true,
        'emailEnabled': true,
        'alertTypes': {
          'safety': true,
          'security': true,
          'weather': true,
          'traffic': true,
        },
      },
      'appearance': {
        'theme': 'system',
        'mapStyle': 'standard',
        'fontSize': 14.0,
      },
      'privacy': {
        'locationSharing': 'driving',
        'dataCollection': true,
        'anonymousReporting': false,
      },
      'language': 'ar',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // إعدادات القيادة
    await _firestore.collection('driving').doc(userId).set({
      'preferences': {
        'voiceAlerts': true,
        'autoReport': false,
        'safetyMode': 'normal',
        'distanceUnit': 'km',
        'speedAlerts': true,
        'speedLimitThreshold': 10,
      },
      'statistics': {
        'totalDrives': 0,
        'totalDistance': 0.0,
        'totalDrivingTime': 0,
        'averageSpeed': 0.0,
        'maxSpeed': 0.0,
        'safetyScore': 0.0,
      },
      'currentDrive': {
        'status': 'idle',
      },
    });
    
    // إعدادات الأمان
    await _firestore.collection('security').doc(userId).set({
      'emergencyContacts': [],
      'safeZones': [],
      'alertSettings': {
        'autoAlert': false,
        'alertThreshold': 3,
        'alertMessage': 'أنا في حالة طوارئ، أرجو المساعدة!',
      },
      'securityPreferences': {
        'shareLocationWithContacts': false,
        'recordIncidents': true,
        'automaticEmergencyCalls': false,
      },
    });
    
    // إعدادات المكافآت
    await _firestore.collection('rewards').doc(userId).set({
      'points': 0,
      'level': 1,
      'badges': [],
      'achievements': [],
      'history': [],
      'redeemableRewards': [],
    });
  }
}