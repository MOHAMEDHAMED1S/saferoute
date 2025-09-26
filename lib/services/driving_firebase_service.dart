import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driving_settings_model.dart';
import 'firebase_schema_service.dart';

class DrivingFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // الحصول على مرجع لمجموعة القيادة
  CollectionReference get drivingCollection => 
      _firestore.collection(FirebaseSchemaService.drivingCollection);
  
  // الحصول على إعدادات القيادة للمستخدم
  Future<Map<String, dynamic>?> getDrivingSettings(String userId) async {
    try {
      final docSnapshot = await drivingCollection.doc(userId).get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return data['preferences'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  // تحديث إعدادات القيادة للمستخدم
  Future<void> updateDrivingSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await drivingCollection.doc(userId).update({
        'preferences': settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // إذا لم يكن المستند موجودًا، قم بإنشائه
      if (e is FirebaseException && e.code == 'not-found') {
        await drivingCollection.doc(userId).set({
          'preferences': settings,
          'statistics': {
            'totalDrives': 0,
            'totalDistance': 0.0,
            'totalDrivingTime': 0,
            'averageSpeed': 0.0,
            'maxSpeed': 0.0,
            'safetyScore': 0.0,
          },
          'currentDrive': {
            'status': 'idle',
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        rethrow;
      }
    }
  }
  
  // تحديث وضع القيادة
  Future<void> updateDrivingMode(String userId, DrivingMode mode) async {
    try {
      final settings = await getDrivingSettings(userId);
      if (settings != null) {
        settings['safetyMode'] = mode.toString().split('.').last;
        await updateDrivingSettings(userId, settings);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // تحديث وحدة المسافة
  Future<void> updateDistanceUnit(String userId, DistanceUnit unit) async {
    try {
      final settings = await getDrivingSettings(userId);
      if (settings != null) {
        settings['distanceUnit'] = unit.toString().split('.').last;
        await updateDrivingSettings(userId, settings);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // تحديث إعدادات التنبيهات الصوتية
  Future<void> updateVoiceAlerts(String userId, bool enabled) async {
    try {
      final settings = await getDrivingSettings(userId);
      if (settings != null) {
        settings['voiceAlerts'] = enabled;
        await updateDrivingSettings(userId, settings);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // تحديث إعدادات التقارير التلقائية
  Future<void> updateAutoReport(String userId, bool enabled) async {
    try {
      final settings = await getDrivingSettings(userId);
      if (settings != null) {
        settings['autoReport'] = enabled;
        await updateDrivingSettings(userId, settings);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // تحديث إعدادات تنبيهات السرعة
  Future<void> updateSpeedAlerts(String userId, bool enabled) async {
    try {
      final settings = await getDrivingSettings(userId);
      if (settings != null) {
        settings['speedAlerts'] = enabled;
        await updateDrivingSettings(userId, settings);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // تحديث حد تنبيهات السرعة
  Future<void> updateSpeedLimitThreshold(String userId, int threshold) async {
    try {
      final settings = await getDrivingSettings(userId);
      if (settings != null) {
        settings['speedLimitThreshold'] = threshold;
        await updateDrivingSettings(userId, settings);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // تحديث إحصائيات القيادة
  Future<void> updateDrivingStatistics(String userId, Map<String, dynamic> statistics) async {
    try {
      await drivingCollection.doc(userId).update({
        'statistics': statistics,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
  
  // تحديث حالة القيادة الحالية
  Future<void> updateCurrentDriveStatus(String userId, String status, {String? routeId}) async {
    try {
      final updates = {
        'currentDrive.status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (routeId != null) {
        updates['currentDrive.routeId'] = routeId;
      }
      
      if (status == 'driving' && routeId != null) {
        updates['currentDrive.startTime'] = FieldValue.serverTimestamp();
      }
      
      await drivingCollection.doc(userId).update(updates);
    } catch (e) {
      rethrow;
    }
  }
  
  // تحديث الموقع الحالي أثناء القيادة
  Future<void> updateCurrentLocation(
    String userId, 
    double latitude, 
    double longitude, 
    double speed, 
    double heading
  ) async {
    try {
      await drivingCollection.doc(userId).update({
        'currentDrive.currentLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'speed': speed,
          'heading': heading,
          'timestamp': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}