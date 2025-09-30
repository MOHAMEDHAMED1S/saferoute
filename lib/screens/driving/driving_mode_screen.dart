import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../providers/reports_provider.dart';
import '../../models/nearby_report.dart';
import '../../services/location_service.dart';
import '../../theme/liquid_glass_theme.dart';
import '../home/widgets/mapbox_widget.dart';

class DrivingModeScreen extends StatefulWidget {
  static const String routeName = '/driving-mode';

  const DrivingModeScreen({super.key});

  @override
  State<DrivingModeScreen> createState() => _DrivingModeScreenState();
}

class _DrivingModeScreenState extends State<DrivingModeScreen>
    with TickerProviderStateMixin {
  // Location tracking
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  final LocationService _locationService = LocationService();

  // Reports and warnings
  List<NearbyReport> _nearbyReports = [];
  List<NearbyReport> _filteredReports = [];
  Timer? _reportsUpdateTimer;
  Timer? _warningTimer;

  // UI state
  bool _isLocationEnabled = false;
  double _searchRadius = 1000.0; // 1km default
  String _selectedFilter = 'الكل';

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _warningController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _warningAnimation;

  // Warning system
  String? _currentWarning;
  bool _showWarning = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLocation();
    _startDrivingMode();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _warningController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _warningAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _warningController, curve: Curves.elasticOut),
    );

    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('تم رفض إذن الموقع');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('تم رفض إذن الموقع نهائياً');
        return;
      }

      // Get current position
      _currentPosition = await _locationService.getCurrentLocation();
      if (_currentPosition != null) {
        setState(() {
          _isLocationEnabled = true;
        });
        _startLocationTracking();
        _loadNearbyReports();
      }
    } catch (e) {
      _showLocationError('خطأ في الحصول على الموقع: $e');
    }
  }

  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
        setState(() {
          _currentPosition = position;
        });
      _updateNearbyReports();
    });
  }

  void _startDrivingMode() {
    // Update reports every 30 seconds
    _reportsUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) => _loadNearbyReports(),
    );

    // Check for warnings every 5 seconds
    _warningTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => _checkForWarnings(),
    );
  }

  Future<void> _loadNearbyReports() async {
    if (_currentPosition == null) return;

    try {
      final reportsProvider = context.read<ReportsProvider>();
      await reportsProvider.initialize();
      
      final nearbyReports = <NearbyReport>[];
      
      for (final report in reportsProvider.reports) {
        final distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          report.location.lat,
          report.location.lng,
        );
        
        if (distance <= _searchRadius) {
          nearbyReports.add(NearbyReport(
            id: report.id,
            title: _getReportTypeName(report.type),
            description: report.description,
            latitude: report.location.lat,
            longitude: report.location.lng,
            distance: '${distance.toStringAsFixed(0)}م',
            timeAgo: _getTimeAgo(report.createdAt),
            type: report.type,
            confirmations: report.confirmations?.trueVotes ?? 0,
            relatedReportId: report.id,
          ));
        }
      }

      setState(() {
        _nearbyReports = nearbyReports;
        _filteredReports = _filterReports(nearbyReports);
      });
    } catch (e) {
      debugPrint('Error loading reports: $e');
    }
  }

  void _updateNearbyReports() {
    if (_currentPosition == null) return;

    final updatedReports = _nearbyReports.map((report) {
      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        report.latitude,
        report.longitude,
      );
      return NearbyReport(
        id: report.id,
        title: report.title,
        description: report.description,
        latitude: report.latitude,
        longitude: report.longitude,
        distance: '${distance.toStringAsFixed(0)}م',
        timeAgo: report.timeAgo,
        type: report.type,
        confirmations: report.confirmations,
        relatedReportId: report.relatedReportId,
      );
    }).toList();

    setState(() {
      _nearbyReports = updatedReports;
      _filteredReports = _filterReports(updatedReports);
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  String _getReportTypeName(dynamic reportType) {
    switch (reportType.toString()) {
      case 'ReportType.accident':
        return 'حادث';
      case 'ReportType.jam':
        return 'ازدحام';
      case 'ReportType.carBreakdown':
        return 'سيارة معطلة';
      case 'ReportType.bump':
        return 'مطب';
      case 'ReportType.closedRoad':
        return 'طريق مغلق';
      case 'ReportType.hazard':
        return 'خطر';
      case 'ReportType.police':
        return 'شرطة';
      case 'ReportType.traffic':
        return 'حركة مرور';
      case 'ReportType.other':
        return 'أخرى';
      default:
        return 'بلاغ';
    }
  }

  List<NearbyReport> _filterReports(List<NearbyReport> reports) {
    if (_selectedFilter == 'الكل') return reports;
    
    return reports.where((report) {
      switch (_selectedFilter) {
        case 'حوادث':
          return report.type.toString().contains('accident');
        case 'ازدحام':
          return report.type.toString().contains('traffic');
        case 'صيانة':
          return report.type.toString().contains('maintenance');
        default:
          return true;
      }
    }).toList();
  }

  void _checkForWarnings() {
    if (_filteredReports.isEmpty || _currentPosition == null) return;

    // Find the closest report
    NearbyReport? closestReport;
    double minDistance = double.infinity;

    for (final report in _filteredReports) {
      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        report.latitude,
        report.longitude,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        closestReport = report;
      }
    }

    // Show warning if report is within 200 meters
    if (closestReport != null && minDistance <= 200) {
      _showWarningMessage(closestReport, minDistance);
    }
  }

  void _showWarningMessage(NearbyReport report, double distance) {
    if (_currentWarning == report.id) return; // Avoid duplicate warnings

    setState(() {
      _currentWarning = report.id;
      _showWarning = true;
    });

    _warningController.forward().then((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _warningController.reverse().then((_) {
    setState(() {
              _showWarning = false;
              _currentWarning = null;
            });
          });
        }
      });
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
        math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) *
        math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _reportsUpdateTimer?.cancel();
    _warningTimer?.cancel();
    _pulseController.dispose();
    _warningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      body: Stack(
        children: [
          // Map
          if (_isLocationEnabled && _currentPosition != null)
            _buildMap()
          else
            _buildLocationLoading(),

          // Top controls
          _buildTopControls(),

          // Bottom controls
          _buildBottomControls(),

          // Warning overlay
          if (_showWarning)
            _buildWarningOverlay(),

          // Reports count indicator
        ],
      ),
    );
  }

  Widget _buildMap() {
    return const Positioned.fill(
      child: MapboxWidget(),
    );
  }

  Widget _buildLocationLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              LiquidGlassTheme.getGradientByName('primary').colors.first,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحديد الموقع...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              fontFamily: 'NotoSansArabic',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          
          // Driving mode indicator
          Expanded(
        child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade100,
                    Colors.green.shade200,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.green.shade300.withValues(alpha: 0.3),
                  width: 1,
                ),
            boxShadow: [
              BoxShadow(
                    color: Colors.green.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
            children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Icon(
                        Icons.drive_eta,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                    Text(
                    'وضع القيادة نشط',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'NotoSansArabic',
                    ),
              ),
            ],
          ),
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter chips
          Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
                // Search radius slider
                Row(
              children: [
                    Icon(
                      Icons.location_searching,
                      color: Colors.blue.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'نطاق البحث: ${_searchRadius.toInt()}م',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _searchRadius,
                  min: 100,
                  max: 5000,
                  divisions: 49,
                  activeColor: Colors.blue.shade700,
                  inactiveColor: Colors.blue.shade200,
                  onChanged: (value) {
                    setState(() {
                      _searchRadius = value;
                    });
                    _loadNearbyReports();
                  },
                ),
                
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('الكل', Icons.filter_list),
                      const SizedBox(width: 8),
                      _buildFilterChip('حوادث', Icons.car_crash),
                      const SizedBox(width: 8),
                      _buildFilterChip('ازدحام', Icons.traffic),
                      const SizedBox(width: 8),
                      _buildFilterChip('صيانة', Icons.build),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _filteredReports = _filterReports(_nearbyReports);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.8),
                    Colors.white.withValues(alpha: 0.6),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.blue.shade700
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
                left: 16,
                right: 16,
      child: AnimatedBuilder(
        animation: _warningAnimation,
        builder: (context, child) => Transform.scale(
          scale: _warningAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_rounded,
              color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
              child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تحذير!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                      Text(
                        'يوجد بلاغ قريب من موقعك',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                    ],
                  ),
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }

  Widget _buildReportsIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
              ),
            ],
          ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.report_problem,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '${_filteredReports.length} بلاغ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }

}