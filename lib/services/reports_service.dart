import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';
import 'reports_firebase_service.dart';

class ReportsService {
  // Firebase service
  final ReportsFirebaseService _firebaseService = ReportsFirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Controller for reports stream
  final _reportsController = StreamController<List<ReportModel>>.broadcast();
  
  // Stream for reports
  Stream<List<ReportModel>> get reportsStream => _reportsController.stream;
  
  // Initialize service
  Future<void> initialize() async {
    // Subscribe to Firebase reports stream
    _firebaseService.getReports().listen((reports) {
      _reportsController.add(reports);
    });
  }
  
  // Get all reports
  Future<List<ReportModel>> getReports() async {
    return _firebaseService.getReports().first;
  }
  
  // Get reports by user
  Future<List<ReportModel>> getUserReports(String userId) async {
    return _firebaseService.getUserReports(userId).first;
  }
  
  // Get reports by type
  Future<List<ReportModel>> getReportsByType(ReportType type) async {
    return _firebaseService.getReportsByType(type).first;
  }
  
  // Create a new report
  Future<String> createReport(ReportModel report) async {
    return await _firebaseService.createReport(report);
  }
  
  // Confirm a report
  Future<void> confirmReport(String reportId) async {
    await _firebaseService.confirmReport(reportId);
  }
  
  // Deny a report
  Future<void> denyReport(String reportId) async {
    await _firebaseService.denyReport(reportId);
  }
  
  // Delete a report
  Future<void> deleteReport(String reportId) async {
    await _firebaseService.deleteReport(reportId);
  }
  
  // Get reports by location
  Future<List<ReportModel>> getReportsByLocation(double latitude, double longitude, double radiusKm) async {
    return _firebaseService.getReportsByLocation(latitude, longitude, radiusKm).first;
  }
  
  // Dispose resources
  void dispose() {
    _reportsController.close();
  }
}