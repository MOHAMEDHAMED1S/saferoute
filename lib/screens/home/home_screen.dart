import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/map_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reports_provider.dart';
import '../../models/report_model.dart';

import 'widgets/map_widget.dart';
import 'widgets/reports_bottom_sheet.dart';
import 'widgets/filter_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isMapReady = false;
  Set<Marker> _markers = {};
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _showReportsSheet = false;
  bool _showFilterSheet = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLocation();
    _loadReports();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeLocation() async {
    try {
      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('تم رفض إذن الموقع');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('تم رفض إذن الموقع نهائياً. يرجى تفعيله من الإعدادات');
      }
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('خدمات الموقع غير مفعلة. يرجى تفعيلها');
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
      
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (mounted) {
        setState(() {});
        _animateToCurrentLocation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديد الموقع: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        // Set default location (Cairo) if location fails
        setState(() {
          _currentPosition = null;
        });
      }
    }
  }

  Future<void> _loadReports() async {
    try {
      final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
      await reportsProvider.initialize();
      _updateMapMarkers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البلاغات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateMapMarkers() {
    final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
    final reports = reportsProvider.nearbyReports;
    
    Set<Marker> newMarkers = {};
    
    for (ReportModel report in reports) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(report.id),
          position: LatLng(report.location.lat, report.location.lng),
          icon: _getMarkerIcon(report.type),
          infoWindow: InfoWindow(
            title: _getReportTypeTitle(report.type),
            snippet: report.description,
            onTap: () => _showReportDetails(report),
          ),
        ),
      );
    }
    
    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  BitmapDescriptor _getMarkerIcon(ReportType type) {
    // TODO: Create custom marker icons for different report types
    switch (type) {
      case ReportType.accident:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case ReportType.jam:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case ReportType.carBreakdown:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case ReportType.bump:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case ReportType.closedRoad:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  String _getReportTypeTitle(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return 'حادث مروري';
      case ReportType.jam:
        return 'ازدحام مروري';
      case ReportType.carBreakdown:
        return 'عطل مركبة';
      case ReportType.bump:
        return 'مطب';
      case ReportType.closedRoad:
        return 'طريق مغلق';
      default:
        return 'بلاغ';
    }
  }

  void _showReportDetails(ReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getReportIcon(report.type),
                  color: _getReportColor(report.type),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getReportTypeTitle(report.type),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3A59),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              report.description,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2E3A59),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(report.createdAt),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return Icons.car_crash;
      case ReportType.jam:
        return Icons.traffic;
      case ReportType.carBreakdown:
        return Icons.car_repair;
      case ReportType.bump:
        return Icons.warning;
      case ReportType.closedRoad:
        return Icons.block;
      default:
        return Icons.report;
    }
  }

  Color _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return Colors.red;
      case ReportType.jam:
        return Colors.orange;
      case ReportType.carBreakdown:
        return Colors.blue;
      case ReportType.bump:
        return Colors.amber;
      case ReportType.closedRoad:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  void _animateToCurrentLocation() async {
    if (_mapController != null && _currentPosition != null) {
      final latLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      
      // Validate location is within Egypt bounds
      if (!MapUtils.isLocationInEgypt(latLng)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الموقع خارج حدود جمهورية مصر العربية'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      
      final cameraUpdate = MapUtils.safeCameraUpdate(latLng);
      await MapUtils.animateCameraSafely(_mapController, cameraUpdate);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });
    _fabAnimationController.forward();
    _animateToCurrentLocation();
  }

  void _toggleReportsSheet() {
    setState(() {
      _showReportsSheet = !_showReportsSheet;
      if (_showFilterSheet) _showFilterSheet = false;
    });
  }

  void _toggleFilterSheet() {
    setState(() {
      _showFilterSheet = !_showFilterSheet;
      if (_showReportsSheet) _showReportsSheet = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          MapWidget(
            onMapCreated: _onMapCreated,
            currentPosition: _currentPosition,
            markers: _markers,
            onMarkerTapped: (report) => _showReportDetails(report),
          ),
          
          // Top App Bar
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/profile');
                    },
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return CircleAvatar(
                          radius: 20,
                          backgroundImage: authProvider.userModel?.photoUrl != null
                              ? NetworkImage(authProvider.userModel!.photoUrl!)
                              : null,
                          child: authProvider.userModel?.photoUrl == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return Text(
                              'مرحباً، ${authProvider.userModel?.name ?? 'المستخدم'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E3A59),
                              ),
                            );
                          },
                        ),
                        const Text(
                          'ابق آمناً على الطريق',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8B9DC3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleFilterSheet,
                    icon: const Icon(
                      Icons.tune,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Sheets
          if (_showReportsSheet)
            ReportsBottomSheet(
              onClose: () => setState(() => _showReportsSheet = false),
            ),
          
          if (_showFilterSheet)
            FilterBottomSheet(
              onClose: () => setState(() => _showFilterSheet = false),
              onFiltersChanged: _updateMapMarkers,
            ),
        ],
      ),
      
      // Floating Action Buttons
      floatingActionButton: _isMapReady
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // My Location Button
                ScaleTransition(
                  scale: _fabAnimation,
                  child: FloatingActionButton(
                    heroTag: 'location',
                    onPressed: _animateToCurrentLocation,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Reports List Button
                ScaleTransition(
                  scale: _fabAnimation,
                  child: FloatingActionButton(
                    heroTag: 'reports',
                    onPressed: _toggleReportsSheet,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.list,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Add Report Button
                ScaleTransition(
                  scale: _fabAnimation,
                  child: FloatingActionButton(
                    heroTag: 'add_report',
                    onPressed: () {
                      Navigator.of(context).pushNamed('/add-report');
                    },
                    backgroundColor: const Color(0xFF4A90E2),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          : null,

    );
  }
}