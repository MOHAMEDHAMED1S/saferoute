import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/report_model.dart';
import '../models/analytics_report_model.dart';
import '../services/firebase_schema_service.dart';

class ReportsFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
    List<File> images,
    String reportId,
  ) async {
    List<String> imageUrls = [];

    for (var image in images) {
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      Reference storageRef = _storage.ref().child(
        'reports/$reportId/$fileName',
      );

      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      imageUrls.add(downloadUrl);
    }

    return imageUrls;
  }

  // Create report with images
  Future<String> createReportWithImages(
    ReportModel report,
    List<File> images,
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
      throw Exception('User not authenticated');
    }

    // Get the report
    DocumentSnapshot reportDoc = await _reportsCollection.doc(reportId).get();
    if (!reportDoc.exists) {
      throw Exception('Report not found');
    }

    // Update the report
    await _reportsCollection.doc(reportId).update({
      'confirmedBy': FieldValue.arrayUnion([user.uid]),
      'confirmations.total': FieldValue.increment(1),
    });

    // Update user's trust score
    await _firestore.collection('users').doc(user.uid).update({
      'trustScore': FieldValue.increment(1),
    });
  }

  // Deny a report
  Future<void> denyReport(String reportId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get the report
    DocumentSnapshot reportDoc = await _reportsCollection.doc(reportId).get();
    if (!reportDoc.exists) {
      throw Exception('Report not found');
    }

    // Update the report
    await _reportsCollection.doc(reportId).update({
      'deniedBy': FieldValue.arrayUnion([user.uid]),
      'confirmations.total': FieldValue.increment(-1),
    });
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
