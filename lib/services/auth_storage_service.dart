import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthStorageService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserPhotoUrl = 'user_photo_url';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyLastLoginTime = 'last_login_time';

  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Save login state
  static Future<void> saveLoginState({
    required String userId,
    required String email,
    String? name,
    String? photoUrl,
    bool rememberMe = true,
  }) async {
    await initialize();
    
    await _prefs!.setBool(_keyIsLoggedIn, true);
    await _prefs!.setString(_keyUserId, userId);
    await _prefs!.setString(_keyUserEmail, email);
    await _prefs!.setBool(_keyRememberMe, rememberMe);
    await _prefs!.setString(_keyLastLoginTime, DateTime.now().toIso8601String());
    
    if (name != null) {
      await _prefs!.setString(_keyUserName, name);
    }
    
    if (photoUrl != null) {
      await _prefs!.setString(_keyUserPhotoUrl, photoUrl);
    }
    
    debugPrint('AuthStorageService: تم حفظ حالة تسجيل الدخول للمستخدم: $userId');
  }

  // Clear login state
  static Future<void> clearLoginState() async {
    await initialize();
    
    await _prefs!.remove(_keyIsLoggedIn);
    await _prefs!.remove(_keyUserId);
    await _prefs!.remove(_keyUserEmail);
    await _prefs!.remove(_keyUserName);
    await _prefs!.remove(_keyUserPhotoUrl);
    await _prefs!.remove(_keyRememberMe);
    await _prefs!.remove(_keyLastLoginTime);
    
    debugPrint('AuthStorageService: تم مسح حالة تسجيل الدخول');
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    await initialize();
    
    final isLoggedIn = _prefs!.getBool(_keyIsLoggedIn) ?? false;
    final rememberMe = _prefs!.getBool(_keyRememberMe) ?? false;
    
    if (!isLoggedIn || !rememberMe) {
      return false;
    }
    
    // Check if login is still valid (optional: add expiry check)
    final lastLoginStr = _prefs!.getString(_keyLastLoginTime);
    if (lastLoginStr != null) {
      final lastLogin = DateTime.parse(lastLoginStr);
      final daysSinceLogin = DateTime.now().difference(lastLogin).inDays;
      
      // Auto logout after 30 days for security
      if (daysSinceLogin > 30) {
        await clearLoginState();
        return false;
      }
    }
    
    return true;
  }

  // Get saved user data
  static Future<Map<String, String?>> getSavedUserData() async {
    await initialize();
    
    return {
      'userId': _prefs!.getString(_keyUserId),
      'email': _prefs!.getString(_keyUserEmail),
      'name': _prefs!.getString(_keyUserName),
      'photoUrl': _prefs!.getString(_keyUserPhotoUrl),
    };
  }

  // Update remember me preference
  static Future<void> setRememberMe(bool rememberMe) async {
    await initialize();
    await _prefs!.setBool(_keyRememberMe, rememberMe);
  }

  // Get remember me preference
  static Future<bool> getRememberMe() async {
    await initialize();
    return _prefs!.getBool(_keyRememberMe) ?? true;
  }

  // Update last login time
  static Future<void> updateLastLoginTime() async {
    await initialize();
    await _prefs!.setString(_keyLastLoginTime, DateTime.now().toIso8601String());
  }

  // Get last login time
  static Future<DateTime?> getLastLoginTime() async {
    await initialize();
    final lastLoginStr = _prefs!.getString(_keyLastLoginTime);
    if (lastLoginStr != null) {
      return DateTime.parse(lastLoginStr);
    }
    return null;
  }
}