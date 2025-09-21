import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/security_model.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  // Stream Controllers
  final _securityStateController = StreamController<ProtectionState>.broadcast();
  final _threatsController = StreamController<List<SecurityThreat>>.broadcast();
  final _eventsController = StreamController<List<SecurityEvent>>.broadcast();
  final _settingsController = StreamController<SecuritySettings>.broadcast();
  final _scanProgressController = StreamController<double>.broadcast();

  // Streams
  Stream<ProtectionState> get securityStateStream => _securityStateController.stream;
  Stream<List<SecurityThreat>> get threatsStream => _threatsController.stream;
  Stream<List<SecurityEvent>> get eventsStream => _eventsController.stream;
  Stream<SecuritySettings> get settingsStream => _settingsController.stream;
  Stream<double> get scanProgressStream => _scanProgressController.stream;

  // Private variables
  ProtectionState _currentState = ProtectionState(lastScan: DateTime.now());
  List<SecurityThreat> _threats = [];
  List<SecurityEvent> _events = [];
  SecuritySettings _settings = const SecuritySettings();
  Timer? _monitoringTimer;
  Timer? _scanTimer;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  bool _isInitialized = false;
  int _failedLoginAttempts = 0;
  DateTime? _lastFailedLogin;

  // Getters
  ProtectionState get currentState => _currentState;
  List<SecurityThreat> get threats => List.unmodifiable(_threats);
  List<SecurityEvent> get events => List.unmodifiable(_events);
  SecuritySettings get settings => _settings;
  bool get isInitialized => _isInitialized;

  // تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadSettings();
      await _loadThreats();
      await _loadEvents();
      await _loadSecurityState();
      
      if (_settings.realTimeMonitoring) {
        _startRealTimeMonitoring();
      }
      
      _startPeriodicScan();
      _isInitialized = true;
      
      await _logSecurityEvent(
        SecurityEventType.appInstall,
        'تم تهيئة نظام الأمان',
        'تم تشغيل نظام الحماية المتقدم بنجاح',
      );
    } catch (e) {
      debugPrint('خطأ في تهيئة خدمة الأمان: $e');
    }
  }

  // تحميل الإعدادات
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('security_settings');
      
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson);
        _settings = SecuritySettings.fromMap(settingsMap);
      }
      
      _settingsController.add(_settings);
    } catch (e) {
      debugPrint('خطأ في تحميل إعدادات الأمان: $e');
    }
  }

  // حفظ الإعدادات
  Future<void> updateSettings(SecuritySettings newSettings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('security_settings', jsonEncode(newSettings.toMap()));
      
      _settings = newSettings;
      _settingsController.add(_settings);
      
      // إعادة تشغيل المراقبة إذا تغيرت الإعدادات
      if (newSettings.realTimeMonitoring != _settings.realTimeMonitoring) {
        if (newSettings.realTimeMonitoring) {
          _startRealTimeMonitoring();
        } else {
          _stopRealTimeMonitoring();
        }
      }
      
      await _logSecurityEvent(
        SecurityEventType.permissionChange,
        'تم تحديث إعدادات الأمان',
        'تم تغيير إعدادات الحماية والأمان',
      );
    } catch (e) {
      debugPrint('خطأ في حفظ إعدادات الأمان: $e');
    }
  }

  // تحميل التهديدات
  Future<void> _loadThreats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final threatsJson = prefs.getStringList('security_threats') ?? [];
      
      _threats = threatsJson
          .map((json) => SecurityThreat.fromMap(jsonDecode(json)))
          .toList();
      
      _threatsController.add(_threats);
    } catch (e) {
      debugPrint('خطأ في تحميل التهديدات: $e');
    }
  }

  // حفظ التهديدات
  Future<void> _saveThreats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final threatsJson = _threats
          .map((threat) => jsonEncode(threat.toMap()))
          .toList();
      
      await prefs.setStringList('security_threats', threatsJson);
    } catch (e) {
      debugPrint('خطأ في حفظ التهديدات: $e');
    }
  }

  // تحميل الأحداث
  Future<void> _loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList('security_events') ?? [];
      
      _events = eventsJson
          .map((json) => SecurityEvent.fromMap(jsonDecode(json)))
          .toList();
      
      // الاحتفاظ بآخر 100 حدث فقط
      if (_events.length > 100) {
        _events = _events.take(100).toList();
      }
      
      _eventsController.add(_events);
    } catch (e) {
      debugPrint('خطأ في تحميل الأحداث: $e');
    }
  }

  // حفظ الأحداث
  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = _events
          .map((event) => jsonEncode(event.toMap()))
          .toList();
      
      await prefs.setStringList('security_events', eventsJson);
    } catch (e) {
      debugPrint('خطأ في حفظ الأحداث: $e');
    }
  }

  // تحميل حالة الأمان
  Future<void> _loadSecurityState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString('security_state');
      
      if (stateJson != null) {
        final stateMap = jsonDecode(stateJson);
        _currentState = ProtectionState.fromMap(stateMap);
      }
      
      _securityStateController.add(_currentState);
    } catch (e) {
      debugPrint('خطأ في تحميل حالة الأمان: $e');
    }
  }

  // حفظ حالة الأمان
  Future<void> _saveSecurityState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('security_state', jsonEncode(_currentState.toMap()));
    } catch (e) {
      debugPrint('خطأ في حفظ حالة الأمان: $e');
    }
  }

  // بدء المراقبة في الوقت الفعلي
  void _startRealTimeMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _performSecurityCheck();
    });
  }

  // إيقاف المراقبة في الوقت الفعلي
  void _stopRealTimeMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  // بدء الفحص الدوري
  void _startPeriodicScan() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(hours: 6), (timer) {
      performFullSecurityScan();
    });
  }

  // إجراء فحص أمني سريع
  Future<void> _performSecurityCheck() async {
    try {
      // فحص محاولات الدخول المشبوهة
      await _checkSuspiciousLoginAttempts();
      
      // فحص صحة النظام
      await _checkSystemHealth();
      
      // تحديث نقاط الأمان
      await _updateSecurityScore();
      
      // تحديث الحالة
      await _updateSecurityState();
    } catch (e) {
      debugPrint('خطأ في الفحص الأمني: $e');
    }
  }

  // إجراء فحص أمني شامل
  Future<void> performFullSecurityScan() async {
    try {
      _scanProgressController.add(0.0);
      
      // فحص التهديدات المحتملة
      _scanProgressController.add(0.2);
      await _scanForThreats();
      
      // فحص إعدادات الأمان
      _scanProgressController.add(0.4);
      await _validateSecuritySettings();
      
      // فحص البيانات المشفرة
      _scanProgressController.add(0.6);
      await _checkDataEncryption();
      
      // فحص الأذونات
      _scanProgressController.add(0.8);
      await _checkPermissions();
      
      // تحديث النتائج
      _scanProgressController.add(1.0);
      await _updateSecurityScore();
      await _updateSecurityState();
      
      await _logSecurityEvent(
        SecurityEventType.dataAccess,
        'تم إكمال الفحص الأمني الشامل',
        'تم فحص جميع جوانب الأمان بنجاح',
      );
    } catch (e) {
      debugPrint('خطأ في الفحص الأمني الشامل: $e');
    }
  }

  // فحص التهديدات
  Future<void> _scanForThreats() async {
    final random = Random();
    
    // محاكاة اكتشاف تهديدات عشوائية
    if (random.nextDouble() < 0.1) { // 10% احتمال اكتشاف تهديد
      final threatTypes = ThreatType.values;
      final randomThreat = threatTypes[random.nextInt(threatTypes.length)];
      
      await _addThreat(SecurityThreat(
        id: _generateId(),
        type: randomThreat,
        level: SecurityLevel.values[random.nextInt(SecurityLevel.values.length)],
        title: 'تهديد أمني محتمل',
        description: 'تم اكتشاف ${randomThreat.displayName} في النظام',
        detectedAt: DateTime.now(),
        source: 'نظام الفحص التلقائي',
        metadata: {
          'scan_id': _generateId(),
          'confidence': random.nextDouble(),
        },
      ));
    }
  }

  // التحقق من إعدادات الأمان
  Future<void> _validateSecuritySettings() async {
    final issues = <String>[];
    
    if (!_settings.dataEncryption) {
      issues.add('تشفير البيانات غير مفعل');
    }
    
    if (!_settings.locationEncryption) {
      issues.add('تشفير الموقع غير مفعل');
    }
    
    if (!_settings.threatDetection) {
      issues.add('كشف التهديدات غير مفعل');
    }
    
    if (_settings.autoLockTimeout > 30) {
      issues.add('مهلة القفل التلقائي طويلة جداً');
    }
    
    if (issues.isNotEmpty) {
      await _addThreat(SecurityThreat(
        id: _generateId(),
        type: ThreatType.suspiciousActivity,
        level: SecurityLevel.medium,
        title: 'مشاكل في إعدادات الأمان',
        description: issues.join(', '),
        detectedAt: DateTime.now(),
        source: 'فحص الإعدادات',
      ));
    }
  }

  // فحص تشفير البيانات
  Future<void> _checkDataEncryption() async {
    // محاكاة فحص تشفير البيانات
    if (!_settings.dataEncryption) {
      await _addThreat(SecurityThreat(
        id: _generateId(),
        type: ThreatType.dataBreach,
        level: SecurityLevel.high,
        title: 'البيانات غير مشفرة',
        description: 'البيانات الحساسة غير محمية بالتشفير',
        detectedAt: DateTime.now(),
        source: 'فحص التشفير',
      ));
    }
  }

  // فحص الأذونات
  Future<void> _checkPermissions() async {
    final suspiciousPermissions = <String>[];
    
    _settings.permissions.forEach((permission, granted) {
      if (granted && _isSuspiciousPermission(permission)) {
        suspiciousPermissions.add(permission);
      }
    });
    
    if (suspiciousPermissions.isNotEmpty) {
      await _addThreat(SecurityThreat(
        id: _generateId(),
        type: ThreatType.unauthorizedAccess,
        level: SecurityLevel.medium,
        title: 'أذونات مشبوهة',
        description: 'تم منح أذونات حساسة: ${suspiciousPermissions.join(', ')}',
        detectedAt: DateTime.now(),
        source: 'فحص الأذونات',
      ));
    }
  }

  // التحقق من محاولات الدخول المشبوهة
  Future<void> _checkSuspiciousLoginAttempts() async {
    if (_failedLoginAttempts >= SecurityConstants.maxLoginAttempts) {
      await _addThreat(SecurityThreat(
        id: _generateId(),
        type: ThreatType.unauthorizedAccess,
        level: SecurityLevel.high,
        title: 'محاولات دخول مشبوهة',
        description: 'تم تجاوز الحد الأقصى لمحاولات الدخول الفاشلة',
        detectedAt: DateTime.now(),
        source: 'نظام المصادقة',
        metadata: {
          'failed_attempts': _failedLoginAttempts,
          'last_attempt': _lastFailedLogin?.toIso8601String(),
        },
      ));
    }
  }

  // فحص صحة النظام
  Future<void> _checkSystemHealth() async {
    final health = <String, dynamic>{};
    
    try {
      // فحص معلومات الجهاز
      final deviceInfo = await _deviceInfo.androidInfo;
      health['device_model'] = deviceInfo.model;
      health['android_version'] = deviceInfo.version.release;
      health['security_patch'] = deviceInfo.version.securityPatch;
      
      // فحص مستوى الأمان
      health['security_level'] = _currentState.currentLevel.toString();
      health['active_threats'] = _threats.where((t) => !t.isResolved).length;
      health['last_scan'] = _currentState.lastScan.toIso8601String();
      
    } catch (e) {
      health['error'] = e.toString();
    }
    
    _currentState = ProtectionState(
      status: _currentState.status,
      currentLevel: _currentState.currentLevel,
      activeThreats: _currentState.activeThreats,
      recentEvents: _currentState.recentEvents,
      lastScan: _currentState.lastScan,
      systemHealth: health,
      securityScore: _currentState.securityScore,
    );
  }

  // تحديث نقاط الأمان
  Future<void> _updateSecurityScore() async {
    double score = 100.0;
    
    // خصم نقاط للتهديدات النشطة
    final activeThreats = _threats.where((t) => !t.isResolved).toList();
    for (final threat in activeThreats) {
      switch (threat.level) {
        case SecurityLevel.low:
          score -= 5;
          break;
        case SecurityLevel.medium:
          score -= 15;
          break;
        case SecurityLevel.high:
          score -= 25;
          break;
        case SecurityLevel.critical:
          score -= 40;
          break;
      }
    }
    
    // خصم نقاط للإعدادات غير الآمنة
    if (!_settings.dataEncryption) score -= 20;
    if (!_settings.locationEncryption) score -= 15;
    if (!_settings.threatDetection) score -= 10;
    if (!_settings.twoFactorEnabled) score -= 10;
    if (!_settings.biometricEnabled) score -= 5;
    
    // التأكد من أن النقاط لا تقل عن 0
    score = score.clamp(0.0, 100.0);
    
    _currentState = ProtectionState(
      status: _currentState.status,
      currentLevel: _getSecurityLevelFromScore(score),
      activeThreats: activeThreats,
      recentEvents: _events.take(10).toList(),
      lastScan: DateTime.now(),
      systemHealth: _currentState.systemHealth,
      securityScore: score,
    );
  }

  // تحديث حالة الأمان
  Future<void> _updateSecurityState() async {
    ProtectionStatus status = ProtectionStatus.active;
    
    final activeThreats = _threats.where((t) => !t.isResolved).toList();
    
    if (activeThreats.any((t) => t.level == SecurityLevel.critical)) {
      status = ProtectionStatus.error;
    } else if (activeThreats.any((t) => t.level == SecurityLevel.high)) {
      status = ProtectionStatus.warning;
    } else if (!_settings.threatDetection || !_settings.realTimeMonitoring) {
      status = ProtectionStatus.inactive;
    }
    
    _currentState = ProtectionState(
      status: status,
      currentLevel: _currentState.currentLevel,
      activeThreats: activeThreats,
      recentEvents: _currentState.recentEvents,
      lastScan: _currentState.lastScan,
      systemHealth: _currentState.systemHealth,
      securityScore: _currentState.securityScore,
    );
    
    _securityStateController.add(_currentState);
    await _saveSecurityState();
  }

  // إضافة تهديد جديد
  Future<void> _addThreat(SecurityThreat threat) async {
    _threats.insert(0, threat);
    
    // الاحتفاظ بآخر 50 تهديد فقط
    if (_threats.length > 50) {
      _threats = _threats.take(50).toList();
    }
    
    _threatsController.add(_threats);
    await _saveThreats();
    
    await _logSecurityEvent(
      SecurityEventType.dataAccess,
      'تم اكتشاف تهديد أمني',
      threat.description,
      riskLevel: threat.level,
    );
  }

  // حل تهديد
  Future<void> resolveThreat(String threatId, String resolution) async {
    final threatIndex = _threats.indexWhere((t) => t.id == threatId);
    if (threatIndex != -1) {
      _threats[threatIndex] = _threats[threatIndex].copyWith(
        isResolved: true,
        resolvedAt: DateTime.now(),
        resolution: resolution,
      );
      
      _threatsController.add(_threats);
      await _saveThreats();
      await _updateSecurityState();
      
      await _logSecurityEvent(
        SecurityEventType.dataAccess,
        'تم حل تهديد أمني',
        'تم حل التهديد: $resolution',
      );
    }
  }

  // تسجيل حدث أمني
  Future<void> _logSecurityEvent(
    SecurityEventType type,
    String title,
    String description, {
    SecurityLevel riskLevel = SecurityLevel.low,
    Map<String, dynamic>? details,
  }) async {
    final event = SecurityEvent(
      id: _generateId(),
      type: type,
      title: title,
      description: description,
      timestamp: DateTime.now(),
      userId: 'current_user', // يجب الحصول على معرف المستخدم الحقيقي
      deviceId: await _getDeviceId(),
      ipAddress: await _getIpAddress(),
      details: details ?? {},
      riskLevel: riskLevel,
    );
    
    _events.insert(0, event);
    
    // الاحتفاظ بآخر 100 حدث فقط
    if (_events.length > 100) {
      _events = _events.take(100).toList();
    }
    
    _eventsController.add(_events);
    await _saveEvents();
  }

  // المصادقة البيومترية
  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!_settings.biometricEnabled) {
        return false;
      }
      
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        await _logSecurityEvent(
          SecurityEventType.loginAttempt,
          'فشل المصادقة البيومترية',
          'البصمة الحيوية غير متاحة',
          riskLevel: SecurityLevel.medium,
        );
        return false;
      }
      
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'يرجى التحقق من هويتك للوصول إلى التطبيق',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      if (isAuthenticated) {
        _failedLoginAttempts = 0;
        await _logSecurityEvent(
          SecurityEventType.loginAttempt,
          'نجحت المصادقة البيومترية',
          'تم التحقق من الهوية بنجاح باستخدام البصمة الحيوية',
        );
      } else {
        _failedLoginAttempts++;
        _lastFailedLogin = DateTime.now();
        await _logSecurityEvent(
          SecurityEventType.loginAttempt,
          'فشلت المصادقة البيومترية',
          'فشل في التحقق من الهوية باستخدام البصمة الحيوية',
          riskLevel: SecurityLevel.medium,
        );
      }
      
      return isAuthenticated;
    } catch (e) {
      await _logSecurityEvent(
        SecurityEventType.loginAttempt,
        'خطأ في المصادقة البيومترية',
        'حدث خطأ أثناء المصادقة: $e',
        riskLevel: SecurityLevel.high,
      );
      return false;
    }
  }

  // التحقق من قوة كلمة المرور
  SecurityLevel checkPasswordStrength(String password) {
    if (password.length < SecurityConstants.passwordMinLength) {
      return SecurityLevel.low;
    }
    
    if (SecurityConstants.commonPasswords.contains(password.toLowerCase())) {
      return SecurityLevel.low;
    }
    
    int score = 0;
    
    // طول كلمة المرور
    if (password.length >= 12) {
      score += 2;
    } else if (password.length >= 8) {
      score += 1;
    }
    
    // الأحرف الكبيرة
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;
    
    // الأحرف الصغيرة
    if (password.contains(RegExp(r'[a-z]'))) score += 1;
    
    // الأرقام
    if (password.contains(RegExp(r'[0-9]'))) score += 1;
    
    // الرموز الخاصة
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 2;
    
    // عدم التكرار
    if (!password.contains(RegExp(r'(.)\1{2,}'))) score += 1;
    
    if (score >= 7) return SecurityLevel.high;
    if (score >= 4) return SecurityLevel.medium;
    return SecurityLevel.low;
  }

  // تشفير البيانات
  String encryptData(String data) {
    if (!_settings.dataEncryption) return data;
    
    // تشفير بسيط باستخدام Base64 (في التطبيق الحقيقي يجب استخدام تشفير أقوى)
    final bytes = utf8.encode(data);
    return base64Encode(bytes);
  }

  // فك تشفير البيانات
  String decryptData(String encryptedData) {
    if (!_settings.dataEncryption) return encryptedData;
    
    try {
      final bytes = base64Decode(encryptedData);
      return utf8.decode(bytes);
    } catch (e) {
      return encryptedData;
    }
  }

  // تشفير الموقع
  Map<String, dynamic> encryptLocation(double latitude, double longitude) {
    if (!_settings.locationEncryption) {
      return {'latitude': latitude, 'longitude': longitude};
    }
    
    // إضافة ضوضاء عشوائية للموقع
    final random = Random();
    final noise = 0.001; // حوالي 100 متر
    
    return {
      'latitude': latitude + (random.nextDouble() - 0.5) * noise,
      'longitude': longitude + (random.nextDouble() - 0.5) * noise,
      'encrypted': true,
    };
  }

  // مساعدات
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = await _deviceInfo.androidInfo;
      return deviceInfo.id;
    } catch (e) {
      return 'unknown';
    }
  }

  Future<String> _getIpAddress() async {
    // في التطبيق الحقيقي، يجب الحصول على عنوان IP الحقيقي
    return '192.168.1.1';
  }

  bool _isSuspiciousPermission(String permission) {
    const suspiciousPermissions = [
      'android.permission.READ_SMS',
      'android.permission.READ_CALL_LOG',
      'android.permission.RECORD_AUDIO',
      'android.permission.CAMERA',
      'android.permission.ACCESS_FINE_LOCATION',
    ];
    
    return suspiciousPermissions.contains(permission);
  }

  SecurityLevel _getSecurityLevelFromScore(double score) {
    if (score >= 90) return SecurityLevel.high;
    if (score >= 70) return SecurityLevel.medium;
    if (score >= 50) return SecurityLevel.low;
    return SecurityLevel.critical;
  }

  // إضافة تهديد جديد
  Future<void> addThreat(SecurityThreat threat) async {
    _threats.add(threat);
    await _saveThreats();
    _threatsController.add(_threats);
    
    await _logSecurityEvent(
      SecurityEventType.dataAccess,
      'تم إضافة تهديد جديد',
      'تم إضافة تهديد: ${threat.title}',
    );
  }

  // حذف تهديد
  Future<void> deleteThreat(String threatId) async {
    _threats.removeWhere((threat) => threat.id == threatId);
    await _saveThreats();
    _threatsController.add(_threats);
    
    await _logSecurityEvent(
      SecurityEventType.dataAccess,
      'تم حذف تهديد',
      'تم حذف تهديد بالمعرف: $threatId',
    );
  }

  // تنظيف الموارد
  void dispose() {
    _monitoringTimer?.cancel();
    _scanTimer?.cancel();
    _securityStateController.close();
    _threatsController.close();
    _eventsController.close();
    _settingsController.close();
    _scanProgressController.close();
  }
}