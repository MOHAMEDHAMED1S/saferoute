import 'package:flutter/material.dart';

// تعدادات الأمان
enum SecurityLevel {
  low,
  medium,
  high,
  critical,
}

enum ThreatType {
  unauthorizedAccess,
  dataBreach,
  locationTracking,
  malware,
  phishing,
  suspiciousActivity,
  deviceCompromise,
  networkAttack,
}

enum SecurityEventType {
  loginAttempt,
  passwordChange,
  dataAccess,
  locationRequest,
  permissionChange,
  appInstall,
  appUninstall,
  networkConnection,
  fileAccess,
}

enum ProtectionStatus {
  active,
  inactive,
  warning,
  error,
  updating,
}

enum AuthenticationMethod {
  password,
  biometric,
  twoFactor,
  pin,
  pattern,
}

// نموذج التهديد الأمني
class SecurityThreat {
  final String id;
  final ThreatType type;
  final SecurityLevel level;
  final String title;
  final String description;
  final DateTime detectedAt;
  final String source;
  final Map<String, dynamic> metadata;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolution;
  final String? resolutionMethod;

  const SecurityThreat({
    required this.id,
    required this.type,
    required this.level,
    required this.title,
    required this.description,
    required this.detectedAt,
    required this.source,
    this.metadata = const {},
    this.isResolved = false,
    this.resolvedAt,
    this.resolution,
    this.resolutionMethod,
  });

  factory SecurityThreat.fromMap(Map<String, dynamic> map) {
    return SecurityThreat(
      id: map['id'] ?? '',
      type: ThreatType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ThreatType.suspiciousActivity,
      ),
      level: SecurityLevel.values.firstWhere(
        (e) => e.toString() == map['level'],
        orElse: () => SecurityLevel.medium,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      detectedAt: DateTime.fromMillisecondsSinceEpoch(map['detectedAt'] ?? 0),
      source: map['source'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      isResolved: map['isResolved'] ?? false,
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['resolvedAt'])
          : null,
      resolution: map['resolution'],
      resolutionMethod: map['resolutionMethod'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'level': level.toString(),
      'title': title,
      'description': description,
      'detectedAt': detectedAt.millisecondsSinceEpoch,
      'source': source,
      'metadata': metadata,
      'isResolved': isResolved,
      'resolvedAt': resolvedAt?.millisecondsSinceEpoch,
      'resolution': resolution,
      'resolutionMethod': resolutionMethod,
    };
  }

  SecurityThreat copyWith({
    String? id,
    ThreatType? type,
    SecurityLevel? level,
    String? title,
    String? description,
    DateTime? detectedAt,
    String? source,
    Map<String, dynamic>? metadata,
    bool? isResolved,
    DateTime? resolvedAt,
    String? resolution,
    String? resolutionMethod,
  }) {
    return SecurityThreat(
      id: id ?? this.id,
      type: type ?? this.type,
      level: level ?? this.level,
      title: title ?? this.title,
      description: description ?? this.description,
      detectedAt: detectedAt ?? this.detectedAt,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
      resolutionMethod: resolutionMethod ?? this.resolutionMethod,
    );
  }
}

// نموذج حدث الأمان
class SecurityEvent {
  final String id;
  final SecurityEventType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String userId;
  final String deviceId;
  final String ipAddress;
  final Map<String, dynamic> details;
  final SecurityLevel riskLevel;

  const SecurityEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.userId,
    required this.deviceId,
    required this.ipAddress,
    this.details = const {},
    this.riskLevel = SecurityLevel.low,
  });

  factory SecurityEvent.fromMap(Map<String, dynamic> map) {
    return SecurityEvent(
      id: map['id'] ?? '',
      type: SecurityEventType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => SecurityEventType.loginAttempt,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      userId: map['userId'] ?? '',
      deviceId: map['deviceId'] ?? '',
      ipAddress: map['ipAddress'] ?? '',
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      riskLevel: SecurityLevel.values.firstWhere(
        (e) => e.toString() == map['riskLevel'],
        orElse: () => SecurityLevel.low,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'userId': userId,
      'deviceId': deviceId,
      'ipAddress': ipAddress,
      'details': details,
      'riskLevel': riskLevel.toString(),
    };
  }
}

// نموذج إعدادات الأمان
class SecuritySettings {
  final bool biometricEnabled;
  final bool twoFactorEnabled;
  final bool locationEncryption;
  final bool dataEncryption;
  final bool autoLock;
  final int autoLockTimeout; // بالدقائق
  final bool threatDetection;
  final bool realTimeMonitoring;
  final bool secureBackup;
  final List<AuthenticationMethod> enabledMethods;
  final Map<String, bool> permissions;
  final SecurityLevel minimumSecurityLevel;
  // الخصائص المضافة لحل المشاكل
  final bool biometricAuth;
  final bool shareLocationWithContacts;
  final bool recordIncidents;
  final bool automaticEmergencyCalls;

  const SecuritySettings({
    this.biometricEnabled = false,
    this.twoFactorEnabled = false,
    this.locationEncryption = true,
    this.dataEncryption = true,
    this.autoLock = true,
    this.autoLockTimeout = 5,
    this.threatDetection = true,
    this.realTimeMonitoring = true,
    this.secureBackup = true,
    this.enabledMethods = const [AuthenticationMethod.password],
    this.permissions = const {},
    this.minimumSecurityLevel = SecurityLevel.medium,
    this.biometricAuth = false,
    this.shareLocationWithContacts = false,
    this.recordIncidents = true,
    this.automaticEmergencyCalls = false,
  });

  factory SecuritySettings.fromMap(Map<String, dynamic> map) {
    return SecuritySettings(
      biometricEnabled: map['biometricEnabled'] ?? false,
      twoFactorEnabled: map['twoFactorEnabled'] ?? false,
      locationEncryption: map['locationEncryption'] ?? true,
      dataEncryption: map['dataEncryption'] ?? true,
      autoLock: map['autoLock'] ?? true,
      autoLockTimeout: map['autoLockTimeout'] ?? 5,
      threatDetection: map['threatDetection'] ?? true,
      realTimeMonitoring: map['realTimeMonitoring'] ?? true,
      secureBackup: map['secureBackup'] ?? true,
      enabledMethods: (map['enabledMethods'] as List<dynamic>? ?? [])
          .map((e) => AuthenticationMethod.values.firstWhere(
                (method) => method.toString() == e,
                orElse: () => AuthenticationMethod.password,
              ))
          .toList(),
      permissions: Map<String, bool>.from(map['permissions'] ?? {}),
      minimumSecurityLevel: SecurityLevel.values.firstWhere(
        (e) => e.toString() == map['minimumSecurityLevel'],
        orElse: () => SecurityLevel.medium,
      ),
      // إضافة الخصائص الجديدة
      biometricAuth: map['biometricAuth'] ?? false,
      shareLocationWithContacts: map['shareLocationWithContacts'] ?? false,
      recordIncidents: map['recordIncidents'] ?? true,
      automaticEmergencyCalls: map['automaticEmergencyCalls'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'biometricEnabled': biometricEnabled,
      'twoFactorEnabled': twoFactorEnabled,
      'locationEncryption': locationEncryption,
      'dataEncryption': dataEncryption,
      'autoLock': autoLock,
      'autoLockTimeout': autoLockTimeout,
      'threatDetection': threatDetection,
      'realTimeMonitoring': realTimeMonitoring,
      'secureBackup': secureBackup,
      'enabledMethods': enabledMethods.map((e) => e.toString()).toList(),
      'permissions': permissions,
      'minimumSecurityLevel': minimumSecurityLevel.toString(),
      // إضافة الخصائص الجديدة
      'biometricAuth': biometricAuth,
      'shareLocationWithContacts': shareLocationWithContacts,
      'recordIncidents': recordIncidents,
      'automaticEmergencyCalls': automaticEmergencyCalls,
    };
  }

  SecuritySettings copyWith({
    bool? biometricEnabled,
    bool? twoFactorEnabled,
    bool? locationEncryption,
    bool? dataEncryption,
    bool? autoLock,
    int? autoLockTimeout,
    bool? threatDetection,
    bool? realTimeMonitoring,
    bool? secureBackup,
    List<AuthenticationMethod>? enabledMethods,
    Map<String, bool>? permissions,
    SecurityLevel? minimumSecurityLevel,
    bool? biometricAuth,
    bool? shareLocationWithContacts,
    bool? recordIncidents,
    bool? automaticEmergencyCalls,
  }) {
    return SecuritySettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      locationEncryption: locationEncryption ?? this.locationEncryption,
      dataEncryption: dataEncryption ?? this.dataEncryption,
      autoLock: autoLock ?? this.autoLock,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      threatDetection: threatDetection ?? this.threatDetection,
      realTimeMonitoring: realTimeMonitoring ?? this.realTimeMonitoring,
      secureBackup: secureBackup ?? this.secureBackup,
      enabledMethods: enabledMethods ?? this.enabledMethods,
      permissions: permissions ?? this.permissions,
      minimumSecurityLevel: minimumSecurityLevel ?? this.minimumSecurityLevel,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      shareLocationWithContacts: shareLocationWithContacts ?? this.shareLocationWithContacts,
      recordIncidents: recordIncidents ?? this.recordIncidents,
      automaticEmergencyCalls: automaticEmergencyCalls ?? this.automaticEmergencyCalls,
    );
  }
}

// نموذج حالة الحماية
class ProtectionState {
  final ProtectionStatus status;
  final SecurityLevel currentLevel;
  final List<SecurityThreat> activeThreats;
  final List<SecurityEvent> recentEvents;
  final DateTime lastScan;
  final Map<String, dynamic> systemHealth;
  final double securityScore; // من 0 إلى 100

  const ProtectionState({
    this.status = ProtectionStatus.active,
    this.currentLevel = SecurityLevel.medium,
    this.activeThreats = const [],
    this.recentEvents = const [],
    required this.lastScan,
    this.systemHealth = const {},
    this.securityScore = 75.0,
  });

  factory ProtectionState.fromMap(Map<String, dynamic> map) {
    return ProtectionState(
      status: ProtectionStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => ProtectionStatus.active,
      ),
      currentLevel: SecurityLevel.values.firstWhere(
        (e) => e.toString() == map['currentLevel'],
        orElse: () => SecurityLevel.medium,
      ),
      activeThreats: (map['activeThreats'] as List<dynamic>? ?? [])
          .map((e) => SecurityThreat.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      recentEvents: (map['recentEvents'] as List<dynamic>? ?? [])
          .map((e) => SecurityEvent.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      lastScan: DateTime.fromMillisecondsSinceEpoch(map['lastScan'] ?? 0),
      systemHealth: Map<String, dynamic>.from(map['systemHealth'] ?? {}),
      securityScore: (map['securityScore'] ?? 75.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.toString(),
      'currentLevel': currentLevel.toString(),
      'activeThreats': activeThreats.map((e) => e.toMap()).toList(),
      'recentEvents': recentEvents.map((e) => e.toMap()).toList(),
      'lastScan': lastScan.millisecondsSinceEpoch,
      'systemHealth': systemHealth,
      'securityScore': securityScore,
    };
  }
}

// امتدادات مساعدة
extension SecurityLevelExtension on SecurityLevel {
  String get displayName {
    switch (this) {
      case SecurityLevel.low:
        return 'منخفض';
      case SecurityLevel.medium:
        return 'متوسط';
      case SecurityLevel.high:
        return 'عالي';
      case SecurityLevel.critical:
        return 'حرج';
    }
  }

  Color get color {
    switch (this) {
      case SecurityLevel.low:
        return Colors.green;
      case SecurityLevel.medium:
        return Colors.orange;
      case SecurityLevel.high:
        return Colors.red;
      case SecurityLevel.critical:
        return Colors.red.shade900;
    }
  }

  IconData get icon {
    switch (this) {
      case SecurityLevel.low:
        return Icons.shield;
      case SecurityLevel.medium:
        return Icons.warning;
      case SecurityLevel.high:
        return Icons.error;
      case SecurityLevel.critical:
        return Icons.dangerous;
    }
  }
}

extension ThreatTypeExtension on ThreatType {
  String get displayName {
    switch (this) {
      case ThreatType.unauthorizedAccess:
        return 'وصول غير مصرح';
      case ThreatType.dataBreach:
        return 'خرق البيانات';
      case ThreatType.locationTracking:
        return 'تتبع الموقع';
      case ThreatType.malware:
        return 'برمجيات خبيثة';
      case ThreatType.phishing:
        return 'تصيد إلكتروني';
      case ThreatType.suspiciousActivity:
        return 'نشاط مشبوه';
      case ThreatType.deviceCompromise:
        return 'اختراق الجهاز';
      case ThreatType.networkAttack:
        return 'هجوم شبكة';
    }
  }

  IconData get icon {
    switch (this) {
      case ThreatType.unauthorizedAccess:
        return Icons.security;
      case ThreatType.dataBreach:
        return Icons.warning;
      case ThreatType.locationTracking:
        return Icons.location_on;
      case ThreatType.malware:
        return Icons.bug_report;
      case ThreatType.phishing:
        return Icons.phishing;
      case ThreatType.suspiciousActivity:
        return Icons.report;
      case ThreatType.deviceCompromise:
        return Icons.phone_android;
      case ThreatType.networkAttack:
        return Icons.wifi_off;
    }
  }
}

extension ProtectionStatusExtension on ProtectionStatus {
  String get displayName {
    switch (this) {
      case ProtectionStatus.active:
        return 'نشط';
      case ProtectionStatus.inactive:
        return 'غير نشط';
      case ProtectionStatus.warning:
        return 'تحذير';
      case ProtectionStatus.error:
        return 'خطأ';
      case ProtectionStatus.updating:
        return 'جاري التحديث';
    }
  }

  Color get color {
    switch (this) {
      case ProtectionStatus.active:
        return Colors.green;
      case ProtectionStatus.inactive:
        return Colors.grey;
      case ProtectionStatus.warning:
        return Colors.orange;
      case ProtectionStatus.error:
        return Colors.red;
      case ProtectionStatus.updating:
        return Colors.blue;
    }
  }
}

extension AuthenticationMethodExtension on AuthenticationMethod {
  String get displayName {
    switch (this) {
      case AuthenticationMethod.password:
        return 'كلمة المرور';
      case AuthenticationMethod.biometric:
        return 'البصمة الحيوية';
      case AuthenticationMethod.twoFactor:
        return 'المصادقة الثنائية';
      case AuthenticationMethod.pin:
        return 'رقم التعريف';
      case AuthenticationMethod.pattern:
        return 'النمط';
    }
  }

  IconData get icon {
    switch (this) {
      case AuthenticationMethod.password:
        return Icons.password;
      case AuthenticationMethod.biometric:
        return Icons.fingerprint;
      case AuthenticationMethod.twoFactor:
        return Icons.security;
      case AuthenticationMethod.pin:
        return Icons.pin;
      case AuthenticationMethod.pattern:
        return Icons.pattern;
    }
  }
}

// ثوابت الأمان
class SecurityConstants {
  static const int maxLoginAttempts = 5;
  static const int lockoutDuration = 30; // دقائق
  static const int sessionTimeout = 60; // دقائق
  static const int passwordMinLength = 8;
  static const int pinLength = 6;
  static const double minimumSecurityScore = 60.0;
  
  static const List<String> commonPasswords = [
    '123456',
    'password',
    '123456789',
    '12345678',
    '12345',
    '1234567',
    '1234567890',
    'qwerty',
    'abc123',
    'password123',
  ];
  
  static const Map<String, String> securityMessages = {
    'weak_password': 'كلمة المرور ضعيفة',
    'strong_password': 'كلمة المرور قوية',
    'biometric_not_available': 'البصمة الحيوية غير متاحة',
    'two_factor_required': 'المصادقة الثنائية مطلوبة',
    'account_locked': 'تم قفل الحساب مؤقتاً',
    'suspicious_login': 'محاولة دخول مشبوهة',
    'security_scan_complete': 'تم إكمال فحص الأمان',
    'threat_detected': 'تم اكتشاف تهديد أمني',
  };
}