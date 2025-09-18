import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final LocationService _locationService;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isOnline = false;
  String? _error;
  List<UserModel> _nearbyUsers = [];
  List<String> _blockedUsers = [];

  UserProvider({
    required AuthService authService,
    required FirestoreService firestoreService,
    required LocationService locationService,
  }) : _authService = authService,
       _firestoreService = firestoreService,
       _locationService = locationService;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  bool get isAuthenticated => _currentUser != null;
  String? get currentUserId => _currentUser?.id;
  bool get isDriverMode => _currentUser?.isDriverMode ?? false;
  String get displayName => _currentUser?.name ?? 'مستخدم';
  String get email => _currentUser?.email ?? '';
  String get phoneNumber => _currentUser?.phone ?? '';
  String? get profileImageUrl => _currentUser?.photoUrl;
  List<UserModel> get nearbyUsers => _nearbyUsers;
  List<String> get blockedUsers => _blockedUsers;
  String? get error => _error;

  // Initialize user provider
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      final user = _authService.currentUser;
      if (user != null) {
        await loadUserData(user.uid);
        await updateOnlineStatus(true);
      }
    } catch (e) {
      _setError('خطأ في تهيئة بيانات المستخدم: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load user data from Firestore
  Future<void> loadUserData(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final userData = await _firestoreService.getUser(userId);
      if (userData != null) {
        _currentUser = userData;
        notifyListeners();
      }
    } catch (e) {
      _setError('خطأ في تحميل بيانات المستخدم: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) {
      _setError('لا يوجد مستخدم مسجل دخول');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final updatedUser = _currentUser!.copyWith(
        name: displayName ?? _currentUser!.name,
        phone: phoneNumber ?? _currentUser!.phone,
        photoUrl: profileImageUrl ?? _currentUser!.photoUrl,
        lastLogin: DateTime.now(),
      );

      await _firestoreService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحديث الملف الشخصي: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update user location
  Future<void> updateLocation() async {
    if (_currentUser == null) {
      _setError('لا يوجد مستخدم مسجل دخول');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final position = await _locationService.getCurrentLocation();
      
      final locationData = LocationData(
        lat: position.latitude,
        lng: position.longitude,
        updatedAt: DateTime.now(),
      );
      
      final updatedUser = _currentUser!.copyWith(
        location: locationData,
        lastLogin: DateTime.now(),
      );

      await _firestoreService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحديث الموقع: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load nearby users
  Future<void> loadNearbyUsers({double radiusInKm = 5.0}) async {
    if (_currentUser?.location == null) {
      _setError('لا يمكن العثور على المستخدمين القريبين بدون موقع');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final currentLocation = _currentUser!.location!;
      final users = await _firestoreService.getNearbyUsers(
        latitude: currentLocation.lat,
        longitude: currentLocation.lng,
        radiusInKm: radiusInKm,
      );

      _nearbyUsers = users.where((user) => user.id != _currentUser!.id).toList();
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحميل المستخدمين القريبين: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle driver mode
  Future<void> toggleDriverMode() async {
    if (_currentUser == null) {
      _setError('لا يوجد مستخدم مسجل دخول');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final newDriverMode = !_currentUser!.isDriverMode;
      final updatedUser = _currentUser!.copyWith(
        isDriverMode: newDriverMode,
        lastLogin: DateTime.now(),
      );

      await _firestoreService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تغيير وضع السائق: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_currentUser == null) return;

    try {
      _isOnline = isOnline;
      final updatedUser = _currentUser!.copyWith(
        lastLogin: DateTime.now(),
      );

      await _firestoreService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('خطأ في تحديث حالة الاتصال: $e');
    }
  }

  // Block user
  Future<void> blockUser(String userId) async {
    if (_currentUser == null) {
      _setError('لا يوجد مستخدم مسجل دخول');
      return;
    }

    if (_blockedUsers.contains(userId)) {
      _setError('المستخدم محظور بالفعل');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      // TODO: Implement blocked users in UserModel
      _blockedUsers.add(userId);
      
      final updatedUser = _currentUser!.copyWith(
        lastLogin: DateTime.now(),
      );

      await _firestoreService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('خطأ في حظر المستخدم: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Unblock user
  Future<void> unblockUser(String userId) async {
    if (_currentUser == null) {
      _setError('لا يوجد مستخدم مسجل دخول');
      return;
    }

    if (!_blockedUsers.contains(userId)) {
      _setError('المستخدم غير محظور');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      // TODO: Implement blocked users in UserModel
      _blockedUsers.remove(userId);
      
      final updatedUser = _currentUser!.copyWith(
        lastLogin: DateTime.now(),
      );

      await _firestoreService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('خطأ في إلغاء حظر المستخدم: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Check if user is blocked
  bool isUserBlocked(String userId) {
    return _blockedUsers.contains(userId);
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      // Update online status before signing out
      if (_currentUser != null) {
        await updateOnlineStatus(false);
      }

      await _authService.signOut();
      _clearUserData();
    } catch (e) {
      _setError('خطأ في تسجيل الخروج: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (_currentUser == null) {
      _setError('لا يوجد مستخدم مسجل دخول');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      // TODO: Implement deleteUser method in FirestoreService
      // await _firestoreService.deleteUser(_currentUser!.id);
      
      // Delete authentication account
      await _authService.deleteAccount();
      _clearUserData();
    } catch (e) {
      _setError('خطأ في حذف الحساب: ${e.toString()}');
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
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _clearUserData() {
    _currentUser = null;
    _isOnline = false;
    _nearbyUsers.clear();
    _blockedUsers.clear();
    _clearError();
    notifyListeners();
  }

  // Refresh user data
  Future<void> refresh() async {
    if (_currentUser != null) {
      await loadUserData(_currentUser!.id);
    }
  }
}