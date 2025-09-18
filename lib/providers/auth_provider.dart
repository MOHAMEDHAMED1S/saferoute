import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _firebaseUser != null && _userModel != null;
  bool get isAuthenticated => _firebaseUser != null && _userModel != null;
  bool get isInitialized => _isInitialized;
  String? get userId => _firebaseUser?.uid;
  String? get userEmail => _firebaseUser?.email;
  String? get userName => _userModel?.name ?? _firebaseUser?.displayName;
  String? get userPhotoUrl => _userModel?.photoUrl ?? _firebaseUser?.photoURL;

  // Initialize auth provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);
      
      // Listen to auth state changes
      _authService.authStateChanges.listen(_onAuthStateChanged);
      
      // Get current user if exists
      _firebaseUser = _authService.currentUser;
      if (_firebaseUser != null) {
        await _loadUserData(_firebaseUser!.uid);
      }
      
      _isInitialized = true;
    } catch (e) {
      _setError('خطأ في تهيئة المصادقة: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Handle auth state changes
  void _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    
    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      _userModel = null;
      _clearError();
    }
    
    notifyListeners();
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String userId) async {
    try {
      _userModel = await _firestoreService.getUser(userId);
      _clearError();
    } catch (e) {
      _setError('خطأ في تحميل بيانات المستخدم: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      UserCredential? userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential?.user != null) {
        await _loadUserData(userCredential!.user!.uid);
        return true;
      }
      
      return false;
    } catch (e) {
      _setError('خطأ في تسجيل الدخول: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      UserCredential? userCredential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      
      if (userCredential?.user != null) {
        await _loadUserData(userCredential!.user!.uid);
        return true;
      }
      
      return false;
    } catch (e) {
      _setError('خطأ في إنشاء الحساب: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();
      
      UserCredential? userCredential = await _authService.signInWithGoogle();
      
      if (userCredential?.user != null) {
        await _loadUserData(userCredential!.user!.uid);
        return true;
      }
      
      return false;
    } catch (e) {
      _setError('خطأ في تسجيل الدخول بـ Google: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.signOut();
      _firebaseUser = null;
      _userModel = null;
    } catch (e) {
      _setError('خطأ في تسجيل الخروج: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError('خطأ في إعادة تعيين كلمة المرور: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    if (_userModel == null) return false;
    
    try {
      _setLoading(true);
      _clearError();
      
      Map<String, dynamic> updates = {};
      
      if (name != null && name != _userModel!.name) {
        updates['name'] = name;
      }
      
      if (phone != null && phone != _userModel!.phone) {
        updates['phone'] = phone;
      }
      
      if (photoUrl != null && photoUrl != _userModel!.photoUrl) {
        updates['photoUrl'] = photoUrl;
      }
      
      if (updates.isNotEmpty) {
        _userModel = _userModel!.copyWith(
          name: name ?? _userModel!.name,
          phone: phone ?? _userModel!.phone,
          photoUrl: photoUrl ?? _userModel!.photoUrl,
        );
        
        await _firestoreService.updateUser(_userModel!);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('خطأ في تحديث الملف الشخصي: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user location
  Future<void> updateUserLocation(LocationData location) async {
    if (_userModel == null) return;
    
    try {
      _userModel = _userModel!.copyWith(location: location);
      await _firestoreService.updateUser(_userModel!);
      notifyListeners();
    } catch (e) {
      print('Error updating user location: $e');
    }
  }

  // Toggle driver mode
  Future<void> toggleDriverMode() async {
    if (_userModel == null) return;
    
    try {
      bool newDriverMode = !_userModel!.isDriverMode;
      _userModel = _userModel!.copyWith(isDriverMode: newDriverMode);
      
      await _firestoreService.updateUser(_userModel!);
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تغيير وضع القيادة: ${e.toString()}');
    }
  }

  // Add points to user
  Future<void> addPoints(int points) async {
    if (_userModel == null) return;
    
    try {
      int newPoints = _userModel!.points + points;
      _userModel = _userModel!.copyWith(points: newPoints);
      
      await _firestoreService.updateUser(_userModel!);
      notifyListeners();
    } catch (e) {
      print('Error adding points: $e');
    }
  }

  // Update trust score
  Future<void> updateTrustScore(double newScore) async {
    if (_userModel == null) return;
    
    try {
      _userModel = _userModel!.copyWith(trustScore: newScore);
      await _firestoreService.updateUser(_userModel!);
      notifyListeners();
    } catch (e) {
      print('Error updating trust score: $e');
    }
  }

  // Increment total reports
  Future<void> incrementTotalReports() async {
    if (_userModel == null) return;
    
    try {
      int newTotal = _userModel!.totalReports + 1;
      _userModel = _userModel!.copyWith(totalReports: newTotal);
      
      await _firestoreService.updateUser(_userModel!);
      notifyListeners();
    } catch (e) {
      print('Error incrementing total reports: $e');
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    if (_firebaseUser == null) return false;
    
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.deleteAccount();
      
      _firebaseUser = null;
      _userModel = null;
      
      return true;
    } catch (e) {
      _setError('خطأ في حذف الحساب: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (_firebaseUser == null) return;
    
    try {
      await _loadUserData(_firebaseUser!.uid);
    } catch (e) {
      _setError('خطأ في تحديث البيانات: ${e.toString()}');
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

  // Clear all data (for testing)
  void clear() {
    _firebaseUser = null;
    _userModel = null;
    _isLoading = false;
    _errorMessage = null;
    _isInitialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}