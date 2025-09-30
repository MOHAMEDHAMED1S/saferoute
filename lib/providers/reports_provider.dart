import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class ReportsProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final LocationService _locationService;

  ReportsProvider({
    required FirestoreService firestoreService,
    required LocationService locationService,
  }) : _firestoreService = firestoreService,
       _locationService = locationService;

  List<ReportModel> _reports = [];
  List<ReportModel> _nearbyReports = [];
  List<ReportModel> _userReports = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<ReportModel>>? _reportsSubscription;
  LocationData? _currentLocation;
  double _searchRadius = 5.0; // km

  // Getters
  List<ReportModel> get reports => _reports;
  List<ReportModel> get nearbyReports => _nearbyReports;
  List<ReportModel> get userReports => _userReports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LocationData? get currentLocation => _currentLocation;
  double get searchRadius => _searchRadius;

  // Get reports by type
  List<ReportModel> getReportsByType(ReportType type) {
    return _reports.where((report) => report.type == type).toList();
  }

  // Get active reports
  List<ReportModel> get activeReports {
    return _reports
        .where(
          (report) =>
              report.status == ReportStatus.active &&
              (report.expiresAt != null &&
                  report.expiresAt!.isAfter(DateTime.now())),
        )
        .toList();
  }

  // Get expired reports
  List<ReportModel> get expiredReports {
    return _reports
        .where(
          (report) =>
              report.expiresAt != null &&
              report.expiresAt!.isBefore(DateTime.now()),
        )
        .toList();
  }

  // Initialize reports provider
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();
      
      if (kDebugMode) {
        print('ReportsProvider: Starting initialization...');
      }
      
      // Load cached data first for immediate display
      await _loadCachedReports();
      
      // Then update with fresh data
      await Future.wait([
        _updateCurrentLocation(),
        _startListeningToReports(),
      ]);
      
      if (kDebugMode) {
        print('ReportsProvider: Initialization completed. Reports count: ${_reports.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ReportsProvider: Error during initialization: $e');
      }
      _setError('خطأ في تهيئة البلاغات: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load cached reports for immediate display
  Future<void> _loadCachedReports() async {
    try {
      // This would load from SharedPreferences or similar cache
      // For now, we'll just set loading to false quickly
      if (kDebugMode) {
        print('ReportsProvider: Loading cached reports...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ReportsProvider: Error loading cached reports: $e');
      }
    }
  }

  // Start listening to reports stream
  Future<void> _startListeningToReports() async {
    _reportsSubscription?.cancel();
    _reportsSubscription = _firestoreService.getActiveReportsStream().listen(
      (reports) {
        _reports = reports;
        _updateNearbyReports();
        notifyListeners();
      },
      onError: (error) {
        _setError('خطأ في تحميل البلاغات: ${error.toString()}');
      },
    );
  }

  // Update current location
  Future<void> _updateCurrentLocation() async {
    try {
      if (kDebugMode) {
        print('ReportsProvider: Getting current location...');
      }
      
      // Try to get last known position first for faster response
      Position? lastKnownPosition;
      try {
        lastKnownPosition = await _locationService.getLastKnownPosition();
        if (lastKnownPosition != null) {
          _currentLocation = _locationService.positionToLocationData(lastKnownPosition);
          if (kDebugMode) {
            print('ReportsProvider: Using last known location: ${_currentLocation!.lat}, ${_currentLocation!.lng}');
          }
          // Update with fresh location in background
          _updateLocationInBackground();
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          print('ReportsProvider: Could not get last known position: $e');
        }
      }
      
      // Get fresh position if no last known position
      final position = await _locationService.getCurrentLocation();
      _currentLocation = _locationService.positionToLocationData(position);
      
      if (kDebugMode) {
        print('ReportsProvider: Location updated: ${_currentLocation!.lat}, ${_currentLocation!.lng}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ReportsProvider: Could not get current location: $e');
      }
      // Use default location as fallback
      _currentLocation = LocationData(
        lat: 30.0444, // Cairo coordinates
        lng: 31.2357,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Update location in background without blocking UI
  void _updateLocationInBackground() {
    _locationService.getCurrentLocation().then((position) {
      _currentLocation = _locationService.positionToLocationData(position);
      _updateNearbyReports();
      notifyListeners();
      if (kDebugMode) {
        print('ReportsProvider: Background location update: ${_currentLocation!.lat}, ${_currentLocation!.lng}');
      }
    }).catchError((e) {
      if (kDebugMode) {
        print('ReportsProvider: Background location update failed: $e');
      }
    });
  }

  // Update nearby reports based on current location
  void _updateNearbyReports() {
    if (_currentLocation == null) {
      _nearbyReports = [];
      return;
    }

    _nearbyReports = _reports.where((report) {
      double distance =
          _locationService.calculateDistance(
            startLatitude: _currentLocation!.lat,
            startLongitude: _currentLocation!.lng,
            endLatitude: report.location.lat,
            endLongitude: report.location.lng,
          ) /
          1000; // Convert to kilometers
      return distance <= _searchRadius;
    }).toList();

    // Sort by distance
    _nearbyReports.sort((a, b) {
      double distanceA =
          _locationService.calculateDistance(
            startLatitude: _currentLocation!.lat,
            startLongitude: _currentLocation!.lng,
            endLatitude: a.location.lat,
            endLongitude: a.location.lng,
          ) /
          1000; // Convert to kilometers
      double distanceB =
          _locationService.calculateDistance(
            startLatitude: _currentLocation!.lat,
            startLongitude: _currentLocation!.lng,
            endLatitude: b.location.lat,
            endLongitude: b.location.lng,
          ) /
          1000; // Convert to kilometers
      return distanceA.compareTo(distanceB);
    });
  }

  // Create new report
  Future<bool> createReport({
    required ReportType type,
    required String description,
    required String createdBy,
    String? imageUrl,
    int? severity,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Get current location
      await _updateCurrentLocation();
      if (_currentLocation == null) {
        _setError('لا يمكن تحديد الموقع الحالي');
        return false;
      }

      // Create report model
      ReportModel report = ReportModel(
        id: '', // Will be set by Firestore
        type: type,
        description: description,
        location: ReportLocation(
          lat: _currentLocation!.lat,
          lng: _currentLocation!.lng,
        ),
        createdBy: createdBy,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(
          Duration(hours: _getReportDuration(type)),
        ),
        status: ReportStatus.active,
        // Note: severity and imageUrl not available in current ReportModel
        confirmations: ReportConfirmations(trueVotes: 0, falseVotes: 0),
        confirmedBy: [],
        deniedBy: [],
      );

      // Save to Firestore
      await _firestoreService.createReport(report);

      // Send notifications to nearby users
      await _sendReportNotifications(report);

      return true;
    } catch (e) {
      _setError('خطأ في إنشاء البلاغ: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Confirm or deny report
  Future<bool> voteOnReport({
    required String reportId,
    required String userId,
    required bool isTrue,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestoreService.confirmReport(reportId, userId, isTrue);

      // Refresh reports
      await _refreshReports();

      return true;
    } catch (e) {
      _setError('خطأ في التصويت على البلاغ: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get user's reports
  Future<void> loadUserReports(String userId) async {
    try {
      print('ReportsProvider: loadUserReports called with userId: $userId');
      _setLoading(true);
      _clearError();

      _userReports = await _firestoreService.getUserReports(userId);
      print('ReportsProvider: Loaded ${_userReports.length} user reports');
      for (var report in _userReports) {
        print('ReportsProvider: Report - ID: ${report.id}, Type: ${report.type}, Status: ${report.status}');
      }
      notifyListeners();
    } catch (e) {
      print('ReportsProvider: Error loading user reports: $e');
      _setError('خطأ في تحميل بلاغات المستخدم: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update search radius
  void updateSearchRadius(double radius) {
    _searchRadius = radius;
    _updateNearbyReports();
    notifyListeners();
  }

  // Refresh current location and nearby reports
  Future<void> refreshLocation() async {
    try {
      await _updateCurrentLocation();
      _updateNearbyReports();
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحديث الموقع: ${e.toString()}');
    }
  }

  // Refresh reports
  Future<void> _refreshReports() async {
    try {
      // The stream will automatically update the reports
      // This method is for manual refresh if needed
      await _updateCurrentLocation();
      _updateNearbyReports();
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحديث البلاغات: ${e.toString()}');
    }
  }

  // Get report duration based on type
  int _getReportDuration(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return 4; // 4 hours
      case ReportType.jam:
        return 2; // 2 hours
      case ReportType.carBreakdown:
        return 4; // 4 hours
      case ReportType.bump:
        return 24; // 24 hours
      case ReportType.closedRoad:
        return 12; // 12 hours
      case ReportType.hazard:
        return 8; // 8 hours
      case ReportType.police:
        return 6; // 6 hours
      case ReportType.traffic:
        return 2; // 2 hours
      case ReportType.other:
        return 6; // default duration
    }
  }

  // Send notifications to nearby users
  Future<void> _sendReportNotifications(ReportModel report) async {
    try {
      if (_currentLocation == null) return;

      // Get nearby users
      // TODO: Implement getNearbyUsers method in FirestoreService
      List<UserModel> nearbyUsers =
          []; // await _firestoreService.getNearbyUsers(
      //   _currentLocation!.lat,
      //   _currentLocation!.lng,
      //   10.0, // Notification radius
      // );

      // Filter out the report creator
      nearbyUsers = nearbyUsers
          .where((user) => user.id != report.createdBy)
          .toList();

      // Send notifications
      // TODO: Implement sendReportNotification method in NotificationService
      // for (UserModel user in nearbyUsers) {
      //   double distance = _locationService.calculateDistance(
      //     startLatitude: user.location?.lat ?? 0,
      //     startLongitude: user.location?.lng ?? 0,
      //     endLatitude: report.location.lat,
      //     endLongitude: report.location.lng,
      //   ) / 1000; // Convert to kilometers
      //
      //   await _notificationService.sendReportNotification(
      //     report: report,
      //     targetUserId: user.id,
      //     distanceInMeters: (distance * 1000).round(),
      //   );
      // }
    } catch (e) {
      debugPrint('Error sending report notifications: $e');
    }
  }

  // Get distance to report
  double? getDistanceToReport(ReportModel report) {
    if (_currentLocation == null) return null;

    return _locationService.calculateDistance(
          startLatitude: _currentLocation!.lat,
          startLongitude: _currentLocation!.lng,
          endLatitude: report.location.lat,
          endLongitude: report.location.lng,
        ) /
        1000; // Convert to kilometers
  }

  // Check if user can vote on report
  bool canUserVoteOnReport(ReportModel report, String userId) {
    return !report.confirmedBy.contains(userId) &&
        !report.deniedBy.contains(userId) &&
        report.createdBy != userId &&
        report.status == ReportStatus.active &&
        report.expiresAt != null &&
        report.expiresAt!.isAfter(DateTime.now());
  }

  // Get report reliability score
  double getReportReliabilityScore(ReportModel report) {
    final int trueVotes = report.confirmations?.trueVotes ?? 0;
    final int falseVotes = report.confirmations?.falseVotes ?? 0;
    int totalVotes = trueVotes + falseVotes;
    if (totalVotes == 0) return 0.5; // Neutral score for new reports
    return trueVotes / totalVotes;
  }

  // Filter reports by criteria
  List<ReportModel> filterReports({
    List<ReportType>? types,
    ReportStatus? status,
    int? minSeverity,
    int? maxSeverity,
    double? maxDistance,
  }) {
    List<ReportModel> filtered = List.from(_reports);

    if (types != null && types.isNotEmpty) {
      filtered = filtered
          .where((report) => types.contains(report.type))
          .toList();
    }

    if (status != null) {
      filtered = filtered.where((report) => report.status == status).toList();
    }

    // Note: severity not available in current ReportModel
    // if (minSeverity != null) {
    //   filtered = filtered.where((report) => report.severity >= minSeverity).toList();
    // }

    // if (maxSeverity != null) {
    //   filtered = filtered.where((report) => report.severity <= maxSeverity).toList();
    // }

    if (maxDistance != null && _currentLocation != null) {
      filtered = filtered.where((report) {
        double distance =
            _locationService.calculateDistance(
              startLatitude: _currentLocation!.lat,
              startLongitude: _currentLocation!.lng,
              endLatitude: report.location.lat,
              endLongitude: report.location.lng,
            ) /
            1000; // Convert to kilometers
        return distance <= maxDistance;
      }).toList();
    }

    return filtered;
  }

  // Search reports by description
  List<ReportModel> searchReports(String query) {
    if (query.isEmpty) return _reports;

    String lowerQuery = query.toLowerCase();
    return _reports.where((report) {
      return report.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Set search radius
  void setSearchRadius(double radius) {
    _searchRadius = radius;
    _updateNearbyReports();
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _reports.clear();
    _nearbyReports.clear();
    _userReports.clear();
    _currentLocation = null;
    _isLoading = false;
    _errorMessage = null;
    _reportsSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }
}
