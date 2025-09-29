import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Manages Firestore connection and handles timeout issues
class FirestoreConnectionManager {
  static final FirestoreConnectionManager _instance =
      FirestoreConnectionManager._internal();
  factory FirestoreConnectionManager() => _instance;
  FirestoreConnectionManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _connectionCheckTimer;
  bool _isConnected = false;
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  /// Initialize the connection manager
  void initialize() {
    _configureFirestore();
    _startConnectionMonitoring();
  }

  /// Configure Firestore settings for better connection handling
  void _configureFirestore() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Start monitoring Firestore connection
  void _startConnectionMonitoring() {
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnection();
    });

    // Initial connection check
    _checkConnection();
  }

  /// Check if Firestore is reachable
  Future<void> _checkConnection() async {
    try {
      // Try a simple read operation with short timeout
      await _firestore
          .collection('_health_check')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!_isConnected) {
        _isConnected = true;
        _connectionController.add(true);
        if (kDebugMode) {
          print('Firestore connection restored');
        }
      }
    } catch (e) {
      if (_isConnected) {
        _isConnected = false;
        _connectionController.add(false);
        if (kDebugMode) {
          print('Firestore connection lost: $e');
        }
      }
    }
  }

  /// Execute a Firestore operation with proper timeout handling
  Future<T> executeWithTimeout<T>(
    Future<T> Function() operation, {
    Duration? timeout,
    String? operationName,
    bool retryOnFailure = true,
  }) async {
    const defaultTimeout = Duration(seconds: 15);
    const retryTimeout = Duration(seconds: 5);

    try {
      return await operation().timeout(
        timeout ?? defaultTimeout,
        onTimeout: () {
          throw TimeoutException(
            'انتهت مهلة الاتصال بقاعدة البيانات',
            timeout ?? defaultTimeout,
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Firestore operation failed (${operationName ?? 'Unknown'}): $e');
      }

      // If it's a timeout and we should retry, try once more with shorter timeout
      if (retryOnFailure && e is TimeoutException) {
        if (kDebugMode) {
          print('Retrying Firestore operation with shorter timeout');
        }

        try {
          return await operation().timeout(retryTimeout);
        } catch (retryError) {
          throw _handleFirestoreError(retryError, operationName);
        }
      }

      throw _handleFirestoreError(e, operationName);
    }
  }

  /// Handle and translate Firestore errors to user-friendly messages
  String _handleFirestoreError(dynamic error, String? operationName) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('could not reach cloud firestore backend')) {
      return 'لا يمكن الوصول إلى قاعدة البيانات. تحقق من اتصالك بالإنترنت.';
    } else if (errorString.contains('timeout')) {
      return 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.';
    } else if (errorString.contains('permission')) {
      return 'ليس لديك صلاحية للوصول إلى هذه البيانات.';
    } else if (errorString.contains('not found')) {
      return 'البيانات المطلوبة غير موجودة.';
    } else if (errorString.contains('already exists')) {
      return 'البيانات موجودة بالفعل.';
    } else if (errorString.contains('invalid argument') || errorString.contains('400') || errorString.contains('bad request')) {
      return 'البيانات المرسلة غير صحيحة أو تحتوي على أخطاء في التنسيق.';
    } else if (errorString.contains('unavailable')) {
      return 'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.';
    } else if (errorString.contains('cancelled') || errorString.contains('aborted')) {
      return 'تم إلغاء العملية. يرجى المحاولة مرة أخرى.';
    } else if (errorString.contains('deadline exceeded')) {
      return 'انتهت مهلة العملية. يرجى المحاولة مرة أخرى.';
    } else {
      return 'حدث خطأ في قاعدة البيانات: ${error.toString()}';
    }
  }

  /// Get cached data if available, otherwise fetch from Firestore
  Future<T?> getCachedOrFetch<T>(
    String cacheKey,
    Future<T> Function() fetchFunction, {
    Duration? cacheTimeout,
    String? operationName,
  }) async {
    // For now, always try to fetch fresh data
    // In a more sophisticated implementation, you could implement local caching
    try {
      return await executeWithTimeout(
        fetchFunction,
        operationName: operationName,
      );
    } catch (e) {
      // If fetch fails, you could return cached data here
      return null;
    }
  }

  /// Force a connection check
  Future<bool> forceConnectionCheck() async {
    await _checkConnection();
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _connectionCheckTimer?.cancel();
    _connectionController.close();
  }
}

/// Extension to add timeout handling to Firestore operations
extension FirestoreTimeoutExtension on FirebaseFirestore {
  /// Execute a collection query with timeout
  Future<QuerySnapshot> getWithTimeout(
    CollectionReference collection, {
    Duration? timeout,
    String? operationName,
  }) {
    return FirestoreConnectionManager().executeWithTimeout(
      () => collection.get(),
      timeout: timeout,
      operationName: operationName,
    );
  }

  /// Execute a document read with timeout
  Future<DocumentSnapshot> docGetWithTimeout(
    DocumentReference document, {
    Duration? timeout,
    String? operationName,
  }) {
    return FirestoreConnectionManager().executeWithTimeout(
      () => document.get(),
      timeout: timeout,
      operationName: operationName,
    );
  }

  /// Execute a document write with timeout
  Future<void> docSetWithTimeout(
    DocumentReference document,
    Map<String, dynamic> data, {
    Duration? timeout,
    String? operationName,
  }) {
    return FirestoreConnectionManager().executeWithTimeout(
      () => document.set(data),
      timeout: timeout,
      operationName: operationName,
    );
  }

  /// Execute a document update with timeout
  Future<void> docUpdateWithTimeout(
    DocumentReference document,
    Map<String, dynamic> data, {
    Duration? timeout,
    String? operationName,
  }) {
    return FirestoreConnectionManager().executeWithTimeout(
      () => document.update(data),
      timeout: timeout,
      operationName: operationName,
    );
  }
}


