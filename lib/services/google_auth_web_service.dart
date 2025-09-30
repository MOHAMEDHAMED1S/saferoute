import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class GoogleAuthWebService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if running on web
  bool get isWeb => kIsWeb;

  // Sign in with Google using popup method
  Future<UserCredential?> signInWithGoogle() async {
    if (!isWeb) {
      throw UnsupportedError('This service is only for web platform');
    }

    try {
      // Create Google Auth Provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Use popup method for better user experience
      UserCredential result = await _auth.signInWithPopup(googleProvider);
      
      return result;
    } on FirebaseAuthException catch (e) {
      print('Google Sign-In Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected Google Sign-In Error: $e');
      throw 'حدث خطأ في تسجيل الدخول بـ Google: ${e.toString()}';
    }
  }

  // Alternative method using popup (if redirect doesn't work)
  Future<UserCredential?> signInWithGooglePopup() async {
    if (!isWeb) {
      throw UnsupportedError('This service is only for web platform');
    }

    try {
      // Create Google Auth Provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Use popup method
      UserCredential result = await _auth.signInWithPopup(googleProvider);
      
      return result;
    } on FirebaseAuthException catch (e) {
      print('Google Sign-In Popup Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected Google Sign-In Popup Error: $e');
      throw 'حدث خطأ في تسجيل الدخول بـ Google: ${e.toString()}';
    }
  }

  // Check if user is returning from redirect
  Future<UserCredential?> getRedirectResult() async {
    if (!isWeb) {
      return null;
    }

    try {
      return await _auth.getRedirectResult();
    } catch (e) {
      print('Error getting redirect result: $e');
      return null;
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'يوجد حساب بهذا البريد الإلكتروني بطريقة تسجيل دخول مختلفة';
      case 'invalid-credential':
        return 'بيانات الاعتماد غير صحيحة';
      case 'operation-not-allowed':
        return 'تسجيل الدخول بـ Google غير مفعل';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'user-not-found':
        return 'لا يوجد مستخدم بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'invalid-verification-id':
        return 'معرف التحقق غير صحيح';
      case 'network-request-failed':
        return 'فشل في الاتصال بالشبكة. تأكد من اتصالك بالإنترنت';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموح. حاول مرة أخرى لاحقاً';
      case 'popup-closed-by-user':
        return 'تم إغلاق نافذة تسجيل الدخول';
      case 'popup-blocked':
        return 'تم حظر النافذة المنبثقة. يرجى السماح بالنوافذ المنبثقة';
      case 'cancelled-popup-request':
        return 'تم إلغاء طلب تسجيل الدخول';
      default:
        return 'حدث خطأ في المصادقة: ${e.message ?? e.code}';
    }
  }

  // Check if popup is supported
  bool get isPopupSupported {
    if (!isWeb) return false;
    
    try {
      // Check if popup is not blocked
      final popup = html.window.open('', 'test', 'width=1,height=1');
      popup.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get recommended sign-in method
  String get recommendedMethod {
    if (!isWeb) return 'mobile';
    
    // Prefer redirect for better compatibility
    return 'redirect';
  }
}
