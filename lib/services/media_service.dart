import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:saferoute/services/location_service.dart';

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  final LocationService _locationService = LocationService();
  
  // تخزين الصورة الأخيرة والموقع
  File? _lastCapturedImage;
  Position? _lastCapturedLocation;
  
  // الحصول على الصورة من الكاميرا مع الموقع
  Future<Map<String, dynamic>> captureImageWithLocation({
    bool includeLocation = true,
    int imageQuality = 85,
    double maxWidth = 1200,
    double maxHeight = 1200,
  }) async {
    try {
      // التقاط الصورة
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      
      if (pickedFile == null) {
        throw 'لم يتم اختيار صورة';
      }
      
      _lastCapturedImage = File(pickedFile.path);
      
      // الحصول على الموقع إذا كان مطلوبًا
      Position? location;
      if (includeLocation) {
        try {
          location = await _locationService.getCurrentLocation();
          _lastCapturedLocation = location;
        } catch (e) {
          debugPrint('فشل في الحصول على الموقع: $e');
          // نستمر بدون موقع
        }
      }
      
      return {
        'image': _lastCapturedImage,
        'location': location,
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      throw 'فشل في التقاط الصورة: ${e.toString()}';
    }
  }
  
  // اختيار صورة من المعرض
  Future<File?> pickImageFromGallery({
    int imageQuality = 85,
    double maxWidth = 1200,
    double maxHeight = 1200,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      
      if (pickedFile == null) {
        return null;
      }
      
      return File(pickedFile.path);
    } catch (e) {
      throw 'فشل في اختيار الصورة: ${e.toString()}';
    }
  }
  
  // حفظ الصورة في مجلد التطبيق
  Future<String> saveImageToAppDirectory(File imageFile, {String? customName}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = customName ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy('${appDir.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      throw 'فشل في حفظ الصورة: ${e.toString()}';
    }
  }
  
  // تحويل الصورة إلى Base64 لإرسالها إلى API
  Future<String> imageToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      return base64.encode(imageBytes);
    } catch (e) {
      throw 'فشل في تحويل الصورة: ${e.toString()}';
    }
  }
  
  // الحصول على موقع الصورة الأخيرة
  Position? getLastCapturedLocation() {
    return _lastCapturedLocation;
  }
  
  // الحصول على الصورة الأخيرة
  File? getLastCapturedImage() {
    return _lastCapturedImage;
  }
  
  // تحويل الموقع إلى تنسيق مناسب للإرسال
  Map<String, double> locationToMap(Position position) {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
    };
  }
  
  // التحقق من أذونات الكاميرا
  Future<bool> checkCameraPermission() async {
    // هذه مجرد واجهة بسيطة، يمكن استخدام مكتبة permission_handler للتنفيذ الكامل
    return true;
  }
  
  // التحقق من أذونات الموقع
  Future<bool> checkLocationPermission() async {
    return await _locationService.checkAndRequestPermissions();
  }
}

// تم إزالة هذه الدالة لأن dart:convert يوفر base64Encode مباشرة
// استخدم base64.encode من مكتبة dart:convert بدلاً من ذلك