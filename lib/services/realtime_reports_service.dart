import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/report_model.dart';
import '../models/nearby_report.dart';

/// خدمة إدارة البلاغات باستخدام Real-time Database
class RealtimeReportsService {
  static final RealtimeReportsService _instance =
      RealtimeReportsService._internal();
  factory RealtimeReportsService() => _instance;
  RealtimeReportsService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // مراجع قاعدة البيانات
  DatabaseReference get _reportsRef => _database.ref('realtime_reports');
  DatabaseReference get _userLocationsRef => _database.ref('user_locations');
  DatabaseReference get _activeNotificationsRef =>
      _database.ref('active_notifications');
  DatabaseReference get _trafficUpdatesRef => _database.ref('traffic_updates');
  DatabaseReference get _emergencyAlertsRef =>
      _database.ref('emergency_alerts');

  // Stream controllers للبيانات الفورية
  StreamController<List<NearbyReport>>? _nearbyReportsController;
  final StreamController<List<Map<String, dynamic>>>
  _activeNotificationsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, dynamic>> _trafficUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Streams للاستماع للبيانات الفورية
  Stream<List<NearbyReport>>? get nearbyReportsStream =>
      _nearbyReportsController?.stream;
  Stream<List<Map<String, dynamic>>> get activeNotificationsStream =>
      _activeNotificationsController.stream;
  Stream<Map<String, dynamic>> get trafficUpdatesStream =>
      _trafficUpdatesController.stream;

  StreamSubscription? _reportsSubscription;
  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _trafficSubscription;

  /// بدء الاستماع للبلاغات القريبة
  Stream<List<NearbyReport>> listenToNearbyReports({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    _nearbyReportsController ??=
        StreamController<List<NearbyReport>>.broadcast();

    _reportsSubscription?.cancel();
    _reportsSubscription = _reportsRef.onValue.listen((event) {
      if (event.snapshot.value == null) {
        _nearbyReportsController?.add([]);
        return;
      }

      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      final List<NearbyReport> nearbyReports = [];

      data.forEach((key, value) {
        if (value is Map) {
          final report = Map<String, dynamic>.from(value as Map);
          final location = (report['location'] is Map)
              ? Map<String, dynamic>.from(report['location'])
              : null;
          final reportLat = (location?['lat'] as num?)?.toDouble();
          final reportLng = (location?['lng'] as num?)?.toDouble();

          if (reportLat != null && reportLng != null) {
            final distanceKm = _calculateDistance(
              latitude,
              longitude,
              reportLat,
              reportLng,
            );

            final bool isActive =
                (report['isActive'] == true) &&
                (report['status']?.toString() != 'removed');

            if (distanceKm <= radiusKm && isActive) {
              final createdAtMs =
                  (report['createdAt'] as num?)?.toInt() ??
                  (report['timestamp'] as num?)?.toInt();
              final createdAt = createdAtMs != null
                  ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
                  : DateTime.now();

              final String typeStr = report['type']?.toString() ?? 'other';

              nearbyReports.add(
                NearbyReport(
                  id: key.toString(),
                  title:
                      '${_getReportTypeNameArabic(typeStr)} - ${(report['description']?.toString() ?? 'بلاغ')}',
                  description: report['description']?.toString() ?? 'بلاغ',
                  distance: _formatDistance(distanceKm * 1000),
                  timeAgo: _getTimeAgo(createdAt),
                  confirmations: (report['verifiedBy'] is List)
                      ? (report['verifiedBy'] as List).length
                      : 0,
                  type: _mapTypeToReportType(typeStr),
                  latitude: reportLat,
                  longitude: reportLng,
                  relatedReportId: report['relatedReportId']?.toString(),
                ),
              );
            }
          }
        }
      });

      // ترتيب البلاغات حسب المسافة (بالأمتار في النص) ثم لا شيء آخر
      nearbyReports.sort(
        (a, b) =>
            _parseDistance(a.distance).compareTo(_parseDistance(b.distance)),
      );

      _nearbyReportsController?.add(nearbyReports);
    });

    return _nearbyReportsController!.stream;
  }

  /// تهيئة الاستماع بطريقة منفصلة للتوافق مع الـ Provider
  void startListeningToNearbyReports({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    // تشغيل الاستماع وحفظ الاشتراك داخلياً
    listenToNearbyReports(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }

  /// الاستماع للإشعارات النشطة
  Stream<List<dynamic>> listenToActiveNotifications() {
    final StreamController<List<dynamic>> controller =
        StreamController<List<dynamic>>.broadcast();

    final subscription = _activeNotificationsRef.onValue.listen((event) {
      try {
        final List<dynamic> notifications = [];

        if (event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          data.forEach((key, value) {
            final notificationData = Map<String, dynamic>.from(value);
            notificationData['id'] = key;
            notifications.add(notificationData);
          });
        }

        controller.add(notifications);
      } catch (e) {
        print('Error processing active notifications: $e');
        controller.addError(e);
      }
    });

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// إضافة بلاغ جديد
  Future<String?> addReport({
    required String type,
    required double latitude,
    required double longitude,
    required String description,
    List<String>? imageUrls,
    int priority = 1,
    String severity = 'medium',
    Duration? expirationDuration,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      final reportRef = _reportsRef.push();
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = expirationDuration != null
          ? now + expirationDuration.inMilliseconds
          : now + const Duration(hours: 24).inMilliseconds;

      final reportData = {
        'userId': user.uid,
        'type': type,
        'location': {'lat': latitude, 'lng': longitude},
        'description': description,
        'imageUrls': imageUrls ?? [],
        'status': 'active',
        'priority': priority,
        'severity': severity,
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
        'expiresAt': expiresAt,
        'viewCount': 0,
        'interactionCount': 0,
      };

      await reportRef.set(reportData);

      // إرسال إشعار للمستخدمين القريبين
      await _notifyNearbyUsers(
        reportId: reportRef.key!,
        type: type,
        latitude: latitude,
        longitude: longitude,
        priority: priority,
      );

      return reportRef.key;
    } catch (e) {
      print('خطأ في إضافة البلاغ: $e');
      return null;
    }
  }

  /// تحديث بلاغ موجود
  Future<bool> updateReport({
    required String reportId,
    String? status,
    int? priority,
    String? severity,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (status != null) updates['status'] = status;
      if (priority != null) updates['priority'] = priority;
      if (severity != null) updates['severity'] = severity;
      if (isActive != null) updates['isActive'] = isActive;

      await _reportsRef.child(reportId).update(updates);
      return true;
    } catch (e) {
      print('خطأ في تحديث البلاغ: $e');
      return false;
    }
  }

  /// حذف بلاغ
  Future<bool> deleteReport(String reportId) async {
    try {
      await _reportsRef.child(reportId).update({
        'isActive': false,
        'status': 'removed',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('خطأ في حذف البلاغ: $e');
      return false;
    }
  }

  /// بدء الاستماع للإشعارات النشطة
  void startListeningToActiveNotifications() {
    final user = _auth.currentUser;
    if (user == null) return;

    _notificationsSubscription?.cancel();

    _notificationsSubscription = _activeNotificationsRef
        .orderByChild('userId')
        .equalTo(user.uid)
        .onValue
        .listen((event) {
          if (event.snapshot.value != null) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            final notifications = <Map<String, dynamic>>[];

            data.forEach((key, value) {
              final notificationData = Map<String, dynamic>.from(value);
              if (notificationData['isActive'] == true) {
                notificationData['id'] = key;
                notifications.add(notificationData);
              }
            });

            // ترتيب الإشعارات حسب الأولوية والوقت
            notifications.sort((a, b) {
              final priorityOrder = {
                'urgent': 4,
                'high': 3,
                'medium': 2,
                'low': 1,
              };
              final aPriority = priorityOrder[a['priority']] ?? 1;
              final bPriority = priorityOrder[b['priority']] ?? 1;

              final priorityComparison = bPriority.compareTo(aPriority);
              if (priorityComparison != 0) return priorityComparison;

              return (b['createdAt'] as int).compareTo(a['createdAt'] as int);
            });

            _activeNotificationsController.add(notifications);
          } else {
            _activeNotificationsController.add([]);
          }
        });
  }

  /// إرسال إشعار للمستخدمين القريبين
  Future<void> _notifyNearbyUsers({
    required String reportId,
    required String type,
    required double latitude,
    required double longitude,
    required int priority,
  }) async {
    try {
      final notificationRef = _activeNotificationsRef.push();
      final now = DateTime.now().millisecondsSinceEpoch;

      // تحديد نطاق الإشعار حسب نوع البلاغ
      double radius = 5000; // 5 كم افتراضي
      switch (type) {
        case 'accident':
          radius = 10000; // 10 كم للحوادث
          break;
        case 'police':
          radius = 3000; // 3 كم للشرطة
          break;
        case 'traffic':
          radius = 7000; // 7 كم للازدحام
          break;
      }

      final notificationData = {
        'userId': 'all', // سيتم فلترة المستخدمين القريبين لاحقاً
        'type': 'report_update',
        'priority': _getPriorityString(priority),
        'relatedReportId': reportId,
        'location': {'lat': latitude, 'lng': longitude, 'radius': radius},
        'createdAt': now,
        'expiresAt': now + const Duration(hours: 2).inMilliseconds,
        'isActive': true,
      };

      await notificationRef.set(notificationData);
    } catch (e) {
      print('خطأ في إرسال الإشعار: $e');
    }
  }

  /// تحويل رقم الأولوية إلى نص
  String _getPriorityString(int priority) {
    switch (priority) {
      case 5:
        return 'urgent';
      case 4:
        return 'high';
      case 3:
        return 'medium';
      case 2:
        return 'low';
      default:
        return 'low';
    }
  }

  // Helpers for formatting distance/time and mapping types
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}م';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}كم';
    }
  }

  double _parseDistance(String distanceStr) {
    if (distanceStr.contains('كم')) {
      return double.tryParse(distanceStr.replaceAll('كم', ''))! * 1000.0;
    }
    return double.tryParse(distanceStr.replaceAll('م', '')) ?? 0.0;
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ساعة';
    } else {
      return '${difference.inDays} يوم';
    }
  }

  ReportType _mapTypeToReportType(String type) {
    switch (type) {
      case 'accident':
        return ReportType.accident;
      case 'jam':
        return ReportType.jam;
      case 'car_breakdown':
        return ReportType.carBreakdown;
      case 'bump':
        return ReportType.bump;
      case 'closed_road':
        return ReportType.closedRoad;
      case 'hazard':
        return ReportType.hazard;
      case 'police':
        return ReportType.police;
      case 'traffic':
        return ReportType.traffic;
      default:
        return ReportType.other;
    }
  }

  String _getReportTypeNameArabic(String type) {
    switch (type) {
      case 'accident':
        return 'حادث';
      case 'jam':
        return 'ازدحام';
      case 'car_breakdown':
        return 'سيارة معطلة';
      case 'bump':
        return 'مطب';
      case 'closed_road':
        return 'طريق مغلق';
      case 'hazard':
        return 'خطر';
      case 'police':
        return 'شرطة';
      case 'traffic':
        return 'حركة مرور';
      default:
        return 'أخرى';
    }
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  // Convert degrees to radians
  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// تنظيف الموارد
  void dispose() {
    _reportsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _trafficSubscription?.cancel();
    _nearbyReportsController?.close();
    _activeNotificationsController.close();
    _trafficUpdatesController.close();
  }

  /// تحديث موقع المستخدم الحالي
  Future<void> updateUserLocation() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _userLocationsRef.child(user.uid).set({
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isOnline': true,
        'heading': position.heading,
      });
    } catch (e) {
      print('خطأ في تحديث موقع المستخدم: $e');
    }
  }

  /// تحديد المستخدم كغير متصل
  Future<void> setUserOffline() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _userLocationsRef.child(user.uid).update({
        'isOnline': false,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('خطأ في تحديث حالة المستخدم: $e');
    }
  }
}
