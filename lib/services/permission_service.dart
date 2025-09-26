import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // طلب إذن الموقع
  Future<bool> requestLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // التحقق من تفعيل خدمة الموقع
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // عرض رسالة للمستخدم لتفعيل خدمة الموقع
      _showPermissionDialog(
        context,
        'خدمة الموقع غير مفعلة',
        'يرجى تفعيل خدمة الموقع للاستفادة من جميع مميزات التطبيق',
        () async {
          await Geolocator.openLocationSettings();
        },
      );
      return false;
    }

    // التحقق من إذن الموقع
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDialog(
          context,
          'إذن الموقع مرفوض',
          'يحتاج التطبيق إلى إذن الموقع للعمل بشكل صحيح',
          () async {
            await requestLocationPermission(context);
          },
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionDialog(
        context,
        'إذن الموقع مرفوض دائمًا',
        'يرجى السماح بإذن الموقع من إعدادات الجهاز',
        () async {
          await openAppSettings();
        },
      );
      return false;
    }

    return true;
  }

  // طلب إذن الكاميرا
  Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        'إذن الكاميرا مرفوض',
        'يحتاج التطبيق إلى إذن الكاميرا لالتقاط صور البلاغات',
        () async {
          if (status.isPermanentlyDenied) {
            await openAppSettings();
          } else {
            await requestCameraPermission(context);
          }
        },
      );
      return false;
    }
    
    return status.isGranted;
  }

  // طلب إذن المعرض
  Future<bool> requestGalleryPermission(BuildContext context) async {
    final status = await Permission.photos.request();
    
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        'إذن المعرض مرفوض',
        'يحتاج التطبيق إلى إذن المعرض لاختيار صور البلاغات',
        () async {
          if (status.isPermanentlyDenied) {
            await openAppSettings();
          } else {
            await requestGalleryPermission(context);
          }
        },
      );
      return false;
    }
    
    return status.isGranted;
  }

  // طلب إذن الإشعارات
  Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.request();
    
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        'إذن الإشعارات مرفوض',
        'يحتاج التطبيق إلى إذن الإشعارات لإبلاغك بالتحديثات المهمة',
        () async {
          if (status.isPermanentlyDenied) {
            await openAppSettings();
          } else {
            await requestNotificationPermission(context);
          }
        },
      );
      return false;
    }
    
    return status.isGranted;
  }

  // طلب جميع الأذونات المطلوبة
  Future<Map<String, bool>> requestAllPermissions(BuildContext context) async {
    final locationGranted = await requestLocationPermission(context);
    final cameraGranted = await requestCameraPermission(context);
    final galleryGranted = await requestGalleryPermission(context);
    final notificationGranted = await requestNotificationPermission(context);
    
    return {
      'location': locationGranted,
      'camera': cameraGranted,
      'gallery': galleryGranted,
      'notification': notificationGranted,
    };
  }

  // عرض حوار طلب الإذن
  void _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onAction,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقًا'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onAction();
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  // التحقق من حالة الأذونات
  Future<Map<Permission, PermissionStatus>> checkPermissionsStatus() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.photos,
      Permission.notification,
    ].request();
    
    return statuses;
  }

  // الحصول على الموقع الحالي
  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location: $e');
      }
      return null;
    }
  }
}