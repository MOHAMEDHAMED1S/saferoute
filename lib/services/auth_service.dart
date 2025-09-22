import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn? _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService() {
    // Initialize Google Sign-In safely for web
    try {
      if (kIsWeb) {
        // Disable Google Sign-In for web temporarily to avoid errors
        _googleSignIn = null;
      } else {
        _googleSignIn = GoogleSignIn();
      }
    } catch (e) {
      print('Google Sign-In initialization failed: $e');
      _googleSignIn = null;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last login
      if (result.user != null) {
        await _updateLastLogin(result.user!.uid);
      }
      
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ غير متوقع: ${e.toString()}';
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        // Update display name
        await result.user!.updateDisplayName(name);
        
        // Create user document in Firestore
        await _createUserDocument(
          uid: result.user!.uid,
          email: email,
          name: name,
          phone: phone,
          photoUrl: result.user!.photoURL,
        );
      }
      
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ غير متوقع: ${e.toString()}';
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    if (_googleSignIn == null) {
      throw 'Google Sign-In غير متاح في هذه البيئة';
    }
    
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      
      if (googleUser == null) {
        return null; // User cancelled the sign-in
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);
      
      if (result.user != null) {
        // Check if user document exists, create if not
        await _createOrUpdateUserDocument(
          uid: result.user!.uid,
          email: result.user!.email ?? '',
          name: result.user!.displayName ?? 'مستخدم',
          photoUrl: result.user!.photoURL,
        );
      }
      
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ في تسجيل الدخول بـ Google: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      List<Future> signOutFutures = [_auth.signOut()];
      
      if (_googleSignIn != null) {
        signOutFutures.add(_googleSignIn!.signOut());
      }
      
      await Future.wait(signOutFutures);
    } catch (e) {
      throw 'حدث خطأ في تسجيل الخروج: ${e.toString()}';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ في إرسال رابط إعادة تعيين كلمة المرور: ${e.toString()}';
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Delete user account
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ في حذف الحساب: ${e.toString()}';
    }
  }

  // Get user document from Firestore
  Future<UserModel?> getUserDocument(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'حدث خطأ في جلب بيانات المستخدم: ${e.toString()}';
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String name,
    required String phone,
    String? photoUrl,
  }) async {
    UserModel user = UserModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
      points: 0,
      trustScore: 1.0,
      totalReports: 0,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      isDriverMode: false,
      location: null,
    );
    
    await _firestore.collection('users').doc(uid).set(user.toFirestore());
  }

  // Create or update user document (for Google sign-in)
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
      UserModel user = UserModel(
        id: uid,
        name: name,
        email: email,
        phone: '',
        photoUrl: photoUrl,
        points: 0,
        trustScore: 1.0,
        totalReports: 0,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        isDriverMode: false,
        location: null,
      );
      
      await userDoc.set(user.toFirestore());
    } else {
      // Update last login
      await _updateLastLogin(uid);
    }
  }

  // Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLogin': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'لا يوجد مستخدم بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-login-credentials':
        return 'بيانات تسجيل الدخول غير صحيحة. تأكد من البريد الإلكتروني وكلمة المرور';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل. يمكنك تسجيل الدخول أو استخدام بريد إلكتروني آخر';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً. يجب أن تحتوي على 6 أحرف على الأقل';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموح. حاول مرة أخرى لاحقاً';
      case 'operation-not-allowed':
        return 'هذه العملية غير مسموحة';
      case 'requires-recent-login':
        return 'يتطلب تسجيل دخول حديث لإتمام هذه العملية';
      case 'network-request-failed':
        return 'فشل في الاتصال بالشبكة. تأكد من اتصالك بالإنترنت';
      case 'invalid-credential':
        return 'بيانات الاعتماد غير صحيحة';
      case 'account-exists-with-different-credential':
        return 'يوجد حساب بهذا البريد الإلكتروني بطريقة تسجيل دخول مختلفة';
      default:
        return 'حدث خطأ في المصادقة: ${e.message ?? e.code}';
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get current user email
  String? get currentUserEmail => _auth.currentUser?.email;

  // Reload current user
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Check if email exists (for better UX before registration)
  Future<bool> checkEmailExists(String email) async {
    try {
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty;
    } catch (e) {
      // If there's an error, assume email doesn't exist to allow registration attempt
      return false;
    }
  }
}