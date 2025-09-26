import 'package:cloud_firestore/cloud_firestore.dart';

/// هذا الملف يحتوي على مخطط قاعدة بيانات Firebase للتطبيق
/// يتم استخدامه كمرجع لهيكل قاعدة البيانات وطريقة تنظيمها

class FirebaseSchemaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // المجموعات الرئيسية في قاعدة البيانات
  static const String usersCollection = 'users';
  static const String routesCollection = 'routes';
  static const String reportsCollection = 'reports';
  static const String incidentsCollection = 'incidents';
  static const String notificationsCollection = 'notifications';
  static const String settingsCollection = 'settings';
  static const String analyticsCollection = 'analytics';
  static const String securityCollection = 'security';
  static const String drivingCollection = 'driving';
  static const String weatherCollection = 'weather';
  static const String communityCollection = 'community';
  static const String rewardsCollection = 'rewards';

  // الحصول على مرجع للمستخدم
  CollectionReference get users => _firestore.collection(usersCollection);

  // الحصول على مرجع للمسارات
  CollectionReference get routes => _firestore.collection(routesCollection);

  // الحصول على مرجع للتقارير
  CollectionReference get reports => _firestore.collection(reportsCollection);

  // الحصول على مرجع للطقس
  CollectionReference get weather => _firestore.collection(weatherCollection);

  // الحصول على مرجع للمجتمع
  CollectionReference get community =>
      _firestore.collection(communityCollection);

  // الحصول على مرجع للمكافآت
  CollectionReference get rewards => _firestore.collection(rewardsCollection);

  // الحصول على مرجع للحوادث
  CollectionReference get incidents =>
      _firestore.collection(incidentsCollection);

  // الحصول على مرجع للإشعارات
  CollectionReference get notifications =>
      _firestore.collection(notificationsCollection);

  // الحصول على مرجع للإعدادات
  CollectionReference get settings => _firestore.collection(settingsCollection);

  // الحصول على مرجع للتحليلات
  CollectionReference get analytics =>
      _firestore.collection(analyticsCollection);

  // الحصول على مرجع للأمان
  CollectionReference get security => _firestore.collection(securityCollection);

  // الحصول على مرجع للقيادة
  CollectionReference get driving => _firestore.collection(drivingCollection);

  // نهاية: تمت إزالة النسخة الأولى المكررة من المخطط لتجنب التكرار

  // هيكل قاعدة البيانات (إصدار مبسط واحد بدون تكرار)
  Map<String, dynamic> get databaseSchema => {
    FirebaseSchemaService.usersCollection: {
      'userId': {
        'name': 'String',
        'email': 'String',
        'phone': 'String?',
        'photoUrl': 'String?',
        'points': 'int',
        'trustScore': 'double',
        'totalReports': 'int',
        'createdAt': 'Timestamp',
        'lastLogin': 'Timestamp',
        'isDriverMode': 'bool',
        'location': {
          'latitude': 'double',
          'longitude': 'double',
          'timestamp': 'Timestamp',
        },
        'settings': {
          'notifications': 'bool',
          'darkMode': 'bool',
          'language': 'String',
        },
        'drivingSettings': {
          'voiceAlerts': 'bool',
          'autoReport': 'bool',
          'safetyMode': 'String',
          'distanceUnit': 'String',
        },
      },
    },
    FirebaseSchemaService.routesCollection: {
      'routeId': {
        'userId': 'String',
        'startLocation': {
          'lat': 'double',
          'lng': 'double',
          'address': 'String',
        },
        'endLocation': {'lat': 'double', 'lng': 'double', 'address': 'String'},
        'waypoints': [
          {'latitude': 'double', 'longitude': 'double', 'address': 'String?'},
        ],
        'distance': 'double',
        'duration': 'int',
        'createdAt': 'Timestamp',
        'startedAt': 'Timestamp?',
        'completedAt': 'Timestamp?',
        'safetyScore': 'double',
        'status': 'String', // planned, active, completed, cancelled
        'incidents': 'List<String>', // Reference to incidents
      },
    },
    FirebaseSchemaService.reportsCollection: {
      'reportId': {
        'userId': 'String',
        'type': 'String', // accident, hazard, police, traffic, other
        'location': {'lat': 'double', 'lng': 'double', 'address': 'String?'},
        'description': 'String',
        'imageUrls': 'List<String>?',
        'createdAt': 'Timestamp',
        'updatedAt': 'Timestamp',
        'status':
            'String', // active, pending, verified, rejected, expired, removed
        'verifiedBy': 'List<String>', // List of user IDs who verified
        'rejectedBy': 'List<String>', // List of user IDs who rejected
      },
    },
    FirebaseSchemaService.incidentsCollection: {
      'incidentId': {
        'userId': 'String',
        'routeId': 'String?',
        'type': 'String', // accident, hazard, police, traffic, other
        'severity': 'int', // 1-5
        'location': {'lat': 'double', 'lng': 'double', 'address': 'String?'},
        'description': 'String',
        'imageUrls': 'List<String>?',
        'createdAt': 'Timestamp',
        'resolvedAt': 'Timestamp?',
        'status': 'String', // active, resolved
      },
    },
    FirebaseSchemaService.notificationsCollection: {
      'notificationId': {
        'userId': 'String',
        'title': 'String',
        'body': 'String',
        'type': 'String', // alert, info, warning
        'data': 'Map<String, dynamic>?',
        'createdAt': 'Timestamp',
        'read': 'bool',
        'readAt': 'Timestamp?',
      },
    },
    FirebaseSchemaService.settingsCollection: {
      'userId': {
        'notifications': {
          'pushEnabled': 'bool',
          'emailEnabled': 'bool',
          'alertTypes': 'Map<String, bool>', // Different alert types
        },
        'appearance': {
          'theme': 'String', // light, dark, system
          'mapStyle': 'String',
          'fontSize': 'double',
        },
        'privacy': {
          'locationSharing': 'String', // always, never, driving
          'dataCollection': 'bool',
          'anonymousReporting': 'bool',
        },
        'language': 'String',
        'updatedAt': 'Timestamp',
      },
    },
    FirebaseSchemaService.analyticsCollection: {
      'userId': {
        'dailyStats': {
          'date': 'Timestamp',
          'distanceDriven': 'double',
          'drivingTime': 'int', // in minutes
          'safetyScore': 'double',
          'incidents': 'int',
          'reportsSubmitted': 'int',
        },
        'weeklyStats': {
          'weekStartDate': 'Timestamp',
          'distanceDriven': 'double',
          'drivingTime': 'int', // in minutes
          'safetyScore': 'double',
          'incidents': 'int',
          'reportsSubmitted': 'int',
        },
        'monthlyStats': {
          'monthStartDate': 'Timestamp',
          'distanceDriven': 'double',
          'drivingTime': 'int', // in minutes
          'safetyScore': 'double',
          'incidents': 'int',
          'reportsSubmitted': 'int',
        },
      },
    },
    FirebaseSchemaService.securityCollection: {
      'userId': {
        'emergencyContacts':
            'List<Map<String, dynamic>>', // name, phone, relation
        'safeZones': 'List<Map<String, dynamic>>', // name, radius, location
        'alertSettings': {
          'autoAlert': 'bool',
          'alertThreshold': 'int',
          'alertMessage': 'String',
        },
        'securityPreferences': {
          'shareLocationWithContacts': 'bool',
          'recordIncidents': 'bool',
          'automaticEmergencyCalls': 'bool',
        },
      },
    },
    FirebaseSchemaService.drivingCollection: {
      'userId': {
        'preferences': {
          'voiceAlerts': 'bool',
          'autoReport': 'bool',
          'safetyMode': 'String', // normal, cautious, aggressive
          'distanceUnit': 'String', // km, miles
          'speedAlerts': 'bool',
          'speedLimitThreshold': 'int', // percentage above speed limit
        },
        'statistics': {
          'totalDrives': 'int',
          'totalDistance': 'double',
          'totalDrivingTime': 'int', // in minutes
          'averageSpeed': 'double',
          'maxSpeed': 'double',
          'safetyScore': 'double',
        },
        'currentDrive': {
          'routeId': 'String?',
          'startTime': 'Timestamp?',
          'currentLocation': {
            'latitude': 'double',
            'longitude': 'double',
            'speed': 'double',
            'heading': 'double',
            'timestamp': 'Timestamp',
          },
          'status': 'String', // idle, driving, paused
        },
      },
    },
    FirebaseSchemaService.weatherCollection: {
      'locationId': {
        'location': {
          'latitude': 'double',
          'longitude': 'double',
          'address': 'String?',
        },
        'currentWeather': {
          'temperature': 'double',
          'condition': 'String',
          'humidity': 'int',
          'windSpeed': 'double',
          'visibility': 'double',
          'precipitation': 'double',
          'updatedAt': 'Timestamp',
        },
        'forecast': 'List<Map<String, dynamic>>', // Daily forecast
        'alerts': 'List<Map<String, dynamic>>', // Weather alerts
        'roadConditions': {
          'isWet': 'bool',
          'isIcy': 'bool',
          'isFoggy': 'bool',
          'visibility': 'String', // good, moderate, poor
          'riskLevel': 'int', // 1-5
        },
      },
    },
    FirebaseSchemaService.communityCollection: {
      'postId': {
        'userId': 'String',
        'title': 'String',
        'content': 'String',
        'imageUrls': 'List<String>?',
        'location': {
          'latitude': 'double',
          'longitude': 'double',
          'address': 'String?',
        },
        'createdAt': 'Timestamp',
        'updatedAt': 'Timestamp',
        'likes': 'int',
        'comments': 'List<Map<String, dynamic>>', // userId, content, timestamp
        'tags': 'List<String>',
        'category': 'String',
      },
    },
    FirebaseSchemaService.rewardsCollection: {
      'userId': {
        'points': 'int',
        'level': 'int',
        'badges': 'List<Map<String, dynamic>>', // name, description, earnedAt
        'achievements':
            'List<Map<String, dynamic>>', // name, description, progress, completed, earnedAt
        'history': 'List<Map<String, dynamic>>', // action, points, timestamp
        'redeemableRewards':
            'List<Map<String, dynamic>>', // name, description, pointsCost, available
      },
    },
  };

  // إنشاء المجموعات الأساسية في قاعدة البيانات
  Future<void> initializeDatabase() async {
    // إنشاء المجموعات الرئيسية إذا لم تكن موجودة
    await Future.wait([
      _createCollectionIfNotExists(FirebaseSchemaService.usersCollection),
      _createCollectionIfNotExists(FirebaseSchemaService.routesCollection),
      _createCollectionIfNotExists(FirebaseSchemaService.reportsCollection),
      _createCollectionIfNotExists(FirebaseSchemaService.incidentsCollection),
      _createCollectionIfNotExists(
        FirebaseSchemaService.notificationsCollection,
      ),
      _createCollectionIfNotExists(FirebaseSchemaService.settingsCollection),
      _createCollectionIfNotExists(FirebaseSchemaService.analyticsCollection),
      _createCollectionIfNotExists(FirebaseSchemaService.securityCollection),
      _createCollectionIfNotExists(FirebaseSchemaService.drivingCollection),
      _createCollectionIfNotExists(FirebaseSchemaService.weatherCollection),
      _createCollectionIfNotExists(FirebaseSchemaService.communityCollection),
      _createCollectionIfNotExists(FirebaseSchemaService.rewardsCollection),
    ]);
  }

  // إنشاء مجموعة إذا لم تكن موجودة
  Future<void> _createCollectionIfNotExists(String collectionName) async {
    // Firestore يقوم بإنشاء المجموعات تلقائيًا عند إضافة وثيقة
    // لذلك نقوم بالتحقق من وجود المجموعة وإذا لم تكن موجودة نضيف وثيقة مؤقتة ثم نحذفها
    final snapshot = await _firestore.collection(collectionName).limit(1).get();
    if (snapshot.docs.isEmpty) {
      final tempDoc = await _firestore.collection(collectionName).add({
        'temp': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await tempDoc.delete();
    }
  }

  // الحصول على مخطط قاعدة البيانات كنص
  String getDatabaseSchemaAsString() {
    return databaseSchema.toString();
  }
}
