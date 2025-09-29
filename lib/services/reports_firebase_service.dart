import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/report_model.dart';
import '../models/analytics_report_model.dart';
import '../services/firebase_schema_service.dart';
import 'external_image_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../services/firestore_connection_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportsFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ExternalImageUploadService _externalUploadService =
      ExternalImageUploadService();

  // Collection references
  CollectionReference get _reportsCollection =>
      _firestore.collection(FirebaseSchemaService.reportsCollection);
  CollectionReference get _analyticsCollection =>
      _firestore.collection('analytics');

  // Get all reports
  Stream<List<ReportModel>> getReports() {
    return _reportsCollection
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReportModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get reports by user
  Stream<List<ReportModel>> getUserReports(String userId) {
    return _reportsCollection
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReportModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get reports by type
  Stream<List<ReportModel>> getReportsByType(ReportType type) {
    String typeString;
    switch (type) {
      case ReportType.accident:
        typeString = 'accident';
        break;
      case ReportType.jam:
        typeString = 'jam';
        break;
      case ReportType.carBreakdown:
        typeString = 'car_breakdown';
        break;
      case ReportType.bump:
        typeString = 'bump';
        break;
      case ReportType.closedRoad:
        typeString = 'closed_road';
        break;
      case ReportType.hazard:
        typeString = 'hazard';
        break;
      case ReportType.police:
        typeString = 'police';
        break;
      case ReportType.traffic:
        typeString = 'traffic';
        break;
      case ReportType.other:
        typeString = 'other';
        break;
    }

    return _reportsCollection
        .where('type', isEqualTo: typeString)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReportModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get reports by location (within radius)
  Stream<List<ReportModel>> getReportsByLocation(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    // تحويل نصف القطر من كيلومتر إلى درجات تقريبية
    // 1 درجة = حوالي 111 كيلومتر
    double radiusDegrees = radiusKm / 111.0;

    // حساب الحدود الجغرافية
    double minLat = latitude - radiusDegrees;
    double maxLat = latitude + radiusDegrees;
    double minLng = longitude - radiusDegrees;
    double maxLng = longitude + radiusDegrees;

    return _reportsCollection
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReportModel.fromFirestore(doc))
              .where((report) {
                double lat = report.location.lat;
                double lng = report.location.lng;

                // Simple distance check (square area)
                return (lat >= minLat &&
                    lat <= maxLat &&
                    lng >= minLng &&
                    lng <= maxLng);
              })
              .toList();
        });
  }

  // Upload image and get URL
  Future<List<String>> uploadReportImages(
    List<XFile> images,
    String reportId,
  ) async {
    try {
      // Use external image upload service
      List<String> imageUrls = await _externalUploadService.uploadImages(
        images,
      );
      print(
        'ReportsFirebaseService: تم رفع ${imageUrls.length} صورة عبر الخدمة الخارجية',
      );
      return imageUrls;
    } catch (e) {
      print('ReportsFirebaseService: فشل في رفع الصور عبر الخدمة الخارجية: $e');
      print(
        'ReportsFirebaseService: محاولة رفع الصور عبر Firebase Storage كبديل',
      );

      // Fallback to Firebase Storage if external service fails
      List<String> imageUrls = [];
      for (var xfile in images) {
        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${xfile.name}';
        Reference storageRef = _storage.ref().child(
          'reports/$reportId/$fileName',
        );
        UploadTask uploadTask;
        if (kIsWeb) {
          Uint8List bytes = await xfile.readAsBytes();
          uploadTask = storageRef.putData(bytes);
        } else {
          uploadTask = storageRef.putFile(File(xfile.path));
        }
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
      return imageUrls;
    }
  }

  // Create report with images
  Future<String> createReportWithImages(
    ReportModel report,
    List<XFile> images,
  ) async {
    print('ReportsFirebaseService: بدء إنشاء البلاغ مع الصور');

    // 1. إنشاء الإبلاغ أولاً للحصول على معرف
    String reportId = await createReport(report);
    print('ReportsFirebaseService: تم إنشاء البلاغ الأساسي: $reportId');

    // 2. رفع الصور إذا وجدت
    if (images.isNotEmpty) {
      print('ReportsFirebaseService: بدء رفع ${images.length} صورة');
      try {
        List<String> imageUrls = await uploadReportImages(images, reportId);
        print(
          'ReportsFirebaseService: تم رفع الصور بنجاح: ${imageUrls.length} صورة',
        );

        // 3. تحديث الإبلاغ بروابط الصور
        await _reportsCollection.doc(reportId).update({
          'imageUrls': imageUrls,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('ReportsFirebaseService: تم تحديث البلاغ بروابط الصور');
      } catch (e) {
        print('ReportsFirebaseService: خطأ في رفع الصور: $e');
        // لا نرمي خطأ هنا، البلاغ تم إنشاؤه بالفعل
      }
    }

    return reportId;
  }

  // Create a new report
  Future<String> createReport(ReportModel report) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    print('ReportsFirebaseService: بدء إنشاء البلاغ للمستخدم: ${user.uid}');

    // Create a new document reference
    DocumentReference docRef = _reportsCollection.doc();

    // Create a new report with the generated ID
    ReportModel newReport = ReportModel(
      id: docRef.id,
      type: report.type,
      description: report.description,
      location: report.location,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(
        const Duration(hours: 24),
      ), // زيادة الصلاحية إلى 24 ساعة
      createdBy: user.uid,
      confirmations: report.confirmations,
      status: ReportStatus.pending,
      confirmedBy: [],
      deniedBy: [],
      imageUrls: [],
      updatedAt: DateTime.now(),
    );

    print('ReportsFirebaseService: تم إنشاء نموذج البلاغ: ${newReport.id}');

    try {
      // Save to Firestore
      await docRef.set(newReport.toFirestore());
      print('ReportsFirebaseService: تم حفظ البلاغ في Firestore بنجاح');

      // Update user's report count
      await _firestore.collection('users').doc(user.uid).update({
        'totalReports': FieldValue.increment(1),
        'points': FieldValue.increment(5), // إضافة 5 نقاط لإرسال البلاغ
      });
      print('ReportsFirebaseService: تم تحديث إحصائيات المستخدم');

      return docRef.id;
    } catch (e) {
      print('ReportsFirebaseService: خطأ في حفظ البلاغ: $e');
      throw Exception('فشل في حفظ البلاغ: $e');
    }
  }

  // Confirm a report
  Future<void> confirmReport(String reportId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'يجب تسجيل الدخول أولاً';
    }

    try {
      // Use connection manager for better error handling
      await FirestoreConnectionManager().executeWithTimeout(() async {
        final batch = _firestore.batch();
        final reportRef = _reportsCollection.doc(reportId);
        
        // Get current report data
        final reportDoc = await reportRef.get();
        if (!reportDoc.exists) {
          throw 'التقرير غير موجود';
        }

        final reportData = reportDoc.data() as Map<String, dynamic>;
        
        // Check if user already voted
        final confirmations = List<String>.from(reportData['confirmations'] ?? []);
        final rejections = List<String>.from(reportData['rejections'] ?? []);
        
        if (confirmations.contains(user.uid) || rejections.contains(user.uid)) {
          throw 'لقد قمت بالتصويت على هذا التقرير من قبل';
        }

        // Check if user is trying to vote on their own report
        if (reportData['userId'] == user.uid) {
          throw 'لا يمكنك التصويت على تقريرك الخاص';
        }

        // Add user to confirmations
        confirmations.add(user.uid);
        
        // Update report
        batch.update(reportRef, {
          'confirmations': confirmations,
          'confirmationCount': confirmations.length,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Update user trust score
        final reportCreatorId = reportData['userId'] as String;
        if (reportCreatorId.isNotEmpty) {
          final userRef = _firestore.collection('users').doc(reportCreatorId);
          batch.update(userRef, {
            'trustScore': FieldValue.increment(1),
            'points': FieldValue.increment(5),
          });
        }

        await batch.commit();
      }, operationName: 'confirmReport');
    } catch (e) {
      if (kDebugMode) {
        print('Error confirming report: $e');
      }
      rethrow;
    }
  }

  // Deny a report
  Future<void> denyReport(String reportId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'يجب تسجيل الدخول أولاً';
    }

    try {
      // Use connection manager for better error handling
      await FirestoreConnectionManager().executeWithTimeout(() async {
        final batch = _firestore.batch();
        final reportRef = _reportsCollection.doc(reportId);
        
        // Get current report data
        final reportDoc = await reportRef.get();
        if (!reportDoc.exists) {
          throw 'التقرير غير موجود';
        }

        final reportData = reportDoc.data() as Map<String, dynamic>;
        
        // Check if user already voted
        final confirmations = List<String>.from(reportData['confirmations'] ?? []);
        final rejections = List<String>.from(reportData['rejections'] ?? []);
        
        if (confirmations.contains(user.uid) || rejections.contains(user.uid)) {
          throw 'لقد قمت بالتصويت على هذا التقرير من قبل';
        }

        // Check if user is trying to vote on their own report
        if (reportData['userId'] == user.uid) {
          throw 'لا يمكنك التصويت على تقريرك الخاص';
        }

        // Add user to rejections
        rejections.add(user.uid);
        
        // Update report
        batch.update(reportRef, {
          'rejections': rejections,
          'rejectionCount': rejections.length,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Decrease user trust score slightly
        final reportCreatorId = reportData['userId'] as String;
        if (reportCreatorId.isNotEmpty) {
          final userRef = _firestore.collection('users').doc(reportCreatorId);
          batch.update(userRef, {
            'trustScore': FieldValue.increment(-0.5),
          });
        }

        await batch.commit();
      }, operationName: 'denyReport');
    } catch (e) {
      if (kDebugMode) {
        print('Error denying report: $e');
      }
      rethrow;
    }
  }

  // Delete a report (only by creator or if denied by many users)
  Future<void> deleteReport(String reportId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get the report
    DocumentSnapshot reportDoc = await _reportsCollection.doc(reportId).get();
    if (!reportDoc.exists) {
      throw Exception('Report not found');
    }

    ReportModel report = ReportModel.fromFirestore(reportDoc);

    // Check if user is creator or report has many denials
    if (report.createdBy == user.uid || report.deniedBy.length > 5) {
      await _reportsCollection.doc(reportId).update({'status': 'removed'});
      
      // Clear cached data to ensure deleted reports don't appear
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('dashboard_nearby_reports');
        await prefs.remove('dashboard_cache_timestamp');
        debugPrint('تم مسح البيانات المحفوظة محلياً بعد حذف البلاغ');
      } catch (e) {
        debugPrint('خطأ في مسح البيانات المحفوظة: $e');
      }
    } else {
      throw Exception('Not authorized to delete this report');
    }
  }

  // Get analytics data
  Future<AnalyticsReportModel> getAnalyticsData(String userId) async {
    DocumentSnapshot doc = await _analyticsCollection.doc(userId).get();

    if (doc.exists) {
      return AnalyticsReportModel.fromFirestore(doc);
    } else {
      // Create default analytics data
      AnalyticsReportModel defaultAnalytics = AnalyticsReportModel(
        id: userId,
        title: "تقرير تحليلي افتراضي",
        description: "تقرير تحليلي افتراضي للمستخدم",
        type: AnalyticsReportType.monthly,
        category: AnalyticsCategory.driving,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
        data: {
          'userId': userId,
          'totalDrives': 0,
          'totalDistance': 0,
          'totalDrivingTime': 0,
        },
        charts: [],
        settings: ReportSettings(
          format: ReportFormat.pdf,
          includeCharts: true,
          includeSummary: true,
          includeDetails: true,
          language: 'ar',
          autoGenerate: false,
          enableNotifications: true,
        ),
        isGenerated: false,
        version: 1,
        summary: ReportSummary(
          overview: '',
          keyMetrics: [],
          insights: [],
          recommendations: [],
          overallScore: 0.0,
        ),
      );

      // Save default analytics
      await _analyticsCollection.doc(userId).set(defaultAnalytics.toJson());

      return defaultAnalytics;
    }
  }

  // Update analytics data
  Future<void> updateAnalyticsData(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _analyticsCollection.doc(userId).update(data);
  }
}
