import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/map_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reports_provider.dart';
import '../../models/report_model.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';

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
        setState(() {
          // Update UI after location update
        });
        _animateToCurrentLocation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديد الموقع: ${e.toString()}'),
            backgroundColor: LiquidGlassTheme.getGradientByName('danger').colors.first,
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
            backgroundColor: LiquidGlassTheme.getGradientByName('danger').colors.first,
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
      builder: (context) => LiquidGlassContainer(
        type: LiquidGlassType.secondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LiquidGlassContainer(
                  type: LiquidGlassType.primary,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _getReportIcon(report.type),
                    color: LiquidGlassTheme.getIconColor('primary'),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _getReportTypeTitle(report.type),
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                LiquidGlassButton(
                  text: '',
                  onPressed: () => Navigator.pop(context),
                  type: LiquidGlassType.secondary,
                  borderRadius: 12,
                  padding: const EdgeInsets.all(8),
                  icon: Icons.close,
                ),
               
              ],
            ),
            const SizedBox(height: 16),
            Text(
              report.description,
              style: LiquidGlassTheme.headerTextStyle.copyWith(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: LiquidGlassTheme.getTextColor('secondary'),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(report.createdAt),
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(
                    fontSize: 14,
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
        return LiquidGlassTheme.getGradientByName('danger').colors.first;
      case ReportType.jam:
        return LiquidGlassTheme.getGradientByName('warning').colors.first;
      case ReportType.carBreakdown:
        return LiquidGlassTheme.getIconColor('primary');
      case ReportType.bump:
        return LiquidGlassTheme.getGradientByName('warning').colors.last;
      case ReportType.closedRoad:
        return LiquidGlassTheme.getIconColor('secondary');
      default:
        return LiquidGlassTheme.getTextColor('secondary') ?? Colors.grey;
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
      extendBody: true,
      backgroundColor: LiquidGlassTheme.backgroundColor,
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
            child: LiquidGlassContainer(
              type: LiquidGlassType.secondary,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              borderRadius: BorderRadius.circular(16),
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
                              ? Icon(Icons.person, color: LiquidGlassTheme.getIconColor('primary'))
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return Text(
                              'مرحباً، ${authProvider.userModel?.name ?? 'المستخدم'}',
                              style: LiquidGlassTheme.primaryTextStyle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                        Text(
                          'ابق آمناً على الطريق',
                          style: LiquidGlassTheme.bodyTextStyle.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  LiquidGlassButton(
                    text: '',
                    onPressed: _toggleFilterSheet,
                    type: LiquidGlassType.primary,
                    borderRadius: 12,
                    padding: const EdgeInsets.all(8),
                    icon: Icons.filter_list,
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
                  child: LiquidGlassButton(
                    text: '',
                    onPressed: _animateToCurrentLocation,
                    type: LiquidGlassType.secondary,
                    borderRadius: 28,
                    padding: const EdgeInsets.all(16),
                    icon: Icons.my_location,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Reports List Button
                ScaleTransition(
                  scale: _fabAnimation,
                  child: LiquidGlassButton(
                    text: '',
                    onPressed: _toggleReportsSheet,
                    type: LiquidGlassType.secondary,
                    borderRadius: 28,
                    padding: const EdgeInsets.all(16),
                    icon: Icons.list,
                  ),
                ),
                const SizedBox(height: 16),
                
                // AI Prediction Button
                ScaleTransition(
                  scale: _fabAnimation,
                  child: LiquidGlassButton(
                    text: '',
                    onPressed: () {
                      Navigator.of(context).pushNamed('/ai-prediction');
                    },
                    type: LiquidGlassType.secondary,
                    borderRadius: 28,
                    padding: const EdgeInsets.all(16),
                    icon: Icons.psychology,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Smart Notifications Button
                ScaleTransition(
                  scale: _fabAnimation,
                  child: LiquidGlassButton(
                    text: '',
                    onPressed: () {
                      Navigator.of(context).pushNamed('/smart-notifications');
                    },
                    type: LiquidGlassType.secondary,
                    borderRadius: 28,
                    padding: const EdgeInsets.all(16),
                    icon: Icons.notifications_active,
                  ),
                ),
                const SizedBox(height: 16),
                
                // 3D Maps Button
                ScaleTransition(
                  scale: _fabAnimation,
                  child: LiquidGlassButton(
                    text: '',
                    onPressed: () {
                      Navigator.of(context).pushNamed('/3d-maps');
                    },
                    type: LiquidGlassType.secondary,
                    borderRadius: 28,
                    padding: const EdgeInsets.all(16),
                    icon: Icons.view_in_ar,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Add Report Button
                ScaleTransition(
                  scale: _fabAnimation,
                  child: LiquidGlassButton(
                    text: '',
                    onPressed: () {
                      Navigator.of(context).pushNamed('/add-report');
                    },
                    type: LiquidGlassType.primary,
                    borderRadius: 28,
                    padding: const EdgeInsets.all(16),
                    icon: Icons.add,
                  ),
                ),
              ],
            )
          : null,

    );
  }
}