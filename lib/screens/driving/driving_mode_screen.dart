import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../utils/map_utils.dart';
import '../../providers/reports_provider.dart';
import '../../models/report_model.dart';
import '../../models/warning_model.dart';
import '../../services/warning_service.dart';
import '../../services/navigation_service.dart';
import '../../models/route_model.dart';
import '../../theme/liquid_glass_theme.dart';

class DrivingModeScreen extends StatefulWidget {
  static const String routeName = '/driving-mode';

  const DrivingModeScreen({super.key});

  @override
  State<DrivingModeScreen> createState() => _DrivingModeScreenState();
}

class _DrivingModeScreenState extends State<DrivingModeScreen>
    with TickerProviderStateMixin {
  // Map controllers
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Navigation
  final NavigationService _navigationService = NavigationService();
  NavigationState _navigationState = NavigationState.idle();
  bool _isNavigating = false;
  StreamSubscription<NavigationState>? _navigationSubscription;
  StreamSubscription<String>? _voiceInstructionSubscription;

  // Warning system
  final WarningService _warningService = WarningService();
  List<DrivingWarning> _activeWarnings = [];
  StreamSubscription<List<DrivingWarning>>? _warningsSubscription;

  // UI state
  String? _selectedDestination;
  final TextEditingController _destinationController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchSuggestions = [];

  // Animation controllers
  late AnimationController _warningAnimationController;
  late Animation<double> _warningAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeWarningSystem();
    _initializeLocation();
    _loadReports();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _positionStream?.cancel();
    _warningsSubscription?.cancel();
    _navigationSubscription?.cancel();
    _voiceInstructionSubscription?.cancel();
    _warningAnimationController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _warningAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _warningAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _warningAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  void _initializeWarningSystem() {
    _navigationService.initialize();
    _warningService.initialize();

    _warningsSubscription = _warningService.warningsStream.listen((warnings) {
      if (mounted) {
        setState(() {
          _activeWarnings = warnings;
        });
        _updateWarningMarkers(warnings);
      }
    });

    _navigationSubscription = _navigationService.navigationStateStream.listen((
      state,
    ) {
      if (mounted) {
        setState(() {
          _navigationState = state;
          _isNavigating = state.isNavigating;
        });
      }
    });

    _voiceInstructionSubscription = _navigationService.voiceInstructionStream
        .listen((instruction) {
          _showVoiceInstruction(instruction);
        });
  }

  Future<void> _initializeLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('خدمات الموقع غير مفعلة');
      }

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
            content: Text('خطأ في تحديد الموقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadReports() async {
    try {
      final reportsProvider = Provider.of<ReportsProvider>(
        context,
        listen: false,
      );
      await reportsProvider.initialize();
      _updateMapMarkers();
    } catch (e) {
      debugPrint('خطأ في تحميل البلاغات: $e');
    }
  }

  void _updateMapMarkers() {
    final reportsProvider = Provider.of<ReportsProvider>(
      context,
      listen: false,
    );
    final reports = reportsProvider.nearbyReports;

    final Set<Marker> newMarkers = {};

    for (final ReportModel report in reports) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(report.id),
          position: LatLng(report.location.lat, report.location.lng),
          icon: _getWarningMarkerIcon(_reportTypeToString(report.type)),
          infoWindow: InfoWindow(
            title: _getReportTypeTitle(_reportTypeToString(report.type)),
            snippet: report.description,
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
      });
    }
  }

  void _updateWarningMarkers(List<DrivingWarning> warnings) {
    final Set<Marker> warningMarkers = {};

    for (final DrivingWarning warning in warnings) {
      warningMarkers.add(
        Marker(
          markerId: MarkerId('warning_${warning.id}'),
          position: warning.location,
          icon: _getWarningMarkerIcon(_getWarningTypeString(warning.type)),
          infoWindow: InfoWindow(
            title: _getWarningTypeText(warning.type),
            snippet: warning.message,
            onTap: () => _showWarningDetails(warning),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers.removeWhere(
          (marker) => marker.markerId.value.startsWith('warning_'),
        );
        _markers.addAll(warningMarkers);
      });
    }
  }

  BitmapDescriptor _getWarningMarkerIcon(String type) {
    switch (type) {
      case 'accident':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'traffic':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        );
      case 'roadwork':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  String _reportTypeToString(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return 'accident';
      case ReportType.jam:
        return 'traffic';
      case ReportType.carBreakdown:
        return 'breakdown';
      case ReportType.bump:
        return 'police';
      case ReportType.closedRoad:
        return 'roadwork';
      case ReportType.hazard:
        return 'hazard';
      case ReportType.police:
        return 'police';
      case ReportType.traffic:
        return 'traffic';
      case ReportType.other:
        return 'other';
    }
  }

  String _getReportTypeTitle(String type) {
    switch (type) {
      case 'accident':
        return 'حادث مروري';
      case 'traffic':
        return 'ازدحام مروري';
      case 'roadwork':
        return 'أعمال طريق';
      case 'police':
        return 'نقطة شرطة';
      default:
        return 'تحذير';
    }
  }

  String _getWarningTypeString(WarningType type) {
    switch (type) {
      case WarningType.accident:
        return 'accident';
      case WarningType.traffic:
        return 'traffic';
      case WarningType.roadwork:
        return 'roadwork';
      case WarningType.police:
        return 'police';
      case WarningType.speedLimit:
        return 'speedLimit';
      default:
        return 'general';
    }
  }

  String _getWarningTypeText(WarningType type) {
    switch (type) {
      case WarningType.accident:
        return 'حادث مروري';
      case WarningType.traffic:
        return 'ازدحام مروري';
      case WarningType.roadwork:
        return 'أعمال طريق';
      case WarningType.police:
        return 'نقطة شرطة';
      case WarningType.speedLimit:
        return 'حد السرعة';
      default:
        return 'تحذير عام';
    }
  }

  void _animateToCurrentLocation() async {
    if (_mapController != null && _currentPosition != null) {
      final latLng = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      final cameraUpdate = MapUtils.safeCameraUpdate(latLng);
      await MapUtils.animateCameraSafely(_mapController, cameraUpdate);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _animateToCurrentLocation();
  }

  void _showVoiceInstruction(String instruction) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                instruction,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: LiquidGlassTheme.primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showWarningDetails(DrivingWarning warning) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _warningService.getWarningIcon(warning.type),
              color: _warningService.getWarningColor(warning.type),
            ),
            const SizedBox(width: 8),
            const Text('تفاصيل التحذير'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(warning.message),
            const SizedBox(height: 8),
            Text('المسافة: ${warning.distance}م'),
            Text('الخطورة: ${_getSeverityText(warning.severity)}'),
            if (warning.additionalInfo != null)
              Text('معلومات إضافية: ${warning.additionalInfo}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              _warningService.dismissWarning(warning.id);
              Navigator.pop(context);
            },
            child: const Text('إخفاء التحذير'),
          ),
        ],
      ),
    );
  }

  String _getSeverityText(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.critical:
        return 'حرج';
      case WarningSeverity.high:
        return 'عالي';
      case WarningSeverity.medium:
        return 'متوسط';
      case WarningSeverity.low:
        return 'منخفض';
    }
  }

  // Destination search methods
  void _startDestinationSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _cancelDestinationSearch() {
    setState(() {
      _isSearching = false;
      _destinationController.clear();
      _searchSuggestions.clear();
    });
  }

  void _onDestinationSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions.clear();
      });
      return;
    }

    // Simulate search suggestions (in real app, use Google Places API)
    setState(() {
      _searchSuggestions =
          [
                {
                  'name': 'مول العرب',
                  'address': 'الرياض، المملكة العربية السعودية',
                  'lat': 24.7136,
                  'lng': 46.6753,
                },
                {
                  'name': 'مطار الملك خالد الدولي',
                  'address': 'الرياض، المملكة العربية السعودية',
                  'lat': 24.9576,
                  'lng': 46.6988,
                },
                {
                  'name': 'برج المملكة',
                  'address': 'الرياض، المملكة العربية السعودية',
                  'lat': 24.7119,
                  'lng': 46.6758,
                },
                {
                  'name': 'جامعة الملك سعود',
                  'address': 'الرياض، المملكة العربية السعودية',
                  'lat': 24.7277,
                  'lng': 46.6219,
                },
              ]
              .where(
                (place) =>
                    place['name'].toString().contains(query) ||
                    place['address'].toString().contains(query),
              )
              .toList();
    });
  }

  void _selectDestination(Map<String, dynamic> destination) {
    setState(() {
      _selectedDestination = destination['name'];
      final destinationLatLng = LatLng(
        destination['lat'] as double,
        destination['lng'] as double,
      );
      _startNavigation(destinationLatLng);
      _isSearching = false;
    });
  }

  void _startNavigation(LatLng destination) {
    if (_currentPosition == null) return;

    final origin = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    _navigationService.startNavigation(destination: destination);

    setState(() {
      _isNavigating = true;
    });
  }

  void _stopNavigation() {
    _navigationService.stopNavigation();
    setState(() {
      _isNavigating = false;
      _polylines.clear();
    });
  }

  void _callEmergencyNumber() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري الاتصال بالطوارئ: 997'),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0 دقيقة';

    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return '$minutes دقيقة';
    } else {
      final hours = duration.inHours;
      final remainingMinutes = minutes - (hours * 60);
      return '$hours ساعة و $remainingMinutes دقيقة';
    }
  }

  String _formatDistance(double? distance) {
    if (distance == null) return '0 كم';

    if (distance < 1) {
      final meters = (distance * 1000).round();
      return '$meters متر';
    } else {
      return '${distance.toStringAsFixed(1)} كم';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(24.7136, 46.6753), // Default to Riyadh
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            markers: _markers,
            polylines: _polylines,
            mapType: MapType.normal,
          ),

          // Top bar with search
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // Warning overlay
          if (_activeWarnings.isNotEmpty) _buildWarningOverlay(),

          // Navigation info
          if (_isNavigating) _buildNavigationInfo(),

          // Bottom controls
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildBottomControls(),
          ),

          // Search overlay
          if (_isSearching) _buildSearchOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Open drawer or settings
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: _startDestinationSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Text(
                  _selectedDestination ?? 'إلى أين تريد الذهاب؟',
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Show notifications
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWarningOverlay() {
    final warning = _activeWarnings.first;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 16,
      right: 16,
      child: ScaleTransition(
        scale: _warningAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _warningService
                .getWarningColor(warning.type)
                .withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                _warningService.getWarningIcon(warning.type),
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getWarningTypeText(warning.type),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      warning.message,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  _warningService.dismissWarning(warning.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationInfo() {
    if (!_isNavigating || _navigationState.route == null) {
      return const SizedBox.shrink();
    }

    final route = _navigationState.route!;

    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              "جاري التنقل...",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem(
                  icon: Icons.access_time,
                  label: 'الوقت المتبقي',
                  value: "10 دقائق",
                ),
                _buildInfoItem(
                  icon: Icons.straighten,
                  label: 'المسافة المتبقية',
                  value: "5 كم",
                ),
                _buildInfoItem(
                  icon: Icons.flag,
                  label: 'الوصول المتوقع',
                  value: "10:30 ص",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildControlButton(
            icon: Icons.my_location,
            label: 'موقعي',
            onTap: _animateToCurrentLocation,
          ),
          _buildControlButton(
            icon: Icons.report_problem,
            label: 'بلاغ',
            onTap: _showReportDialog,
          ),
          _buildControlButton(
            icon: Icons.emergency,
            label: 'طوارئ',
            onTap: _callEmergencyNumber,
            isEmergency: true,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isEmergency = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEmergency ? Colors.red : LiquidGlassTheme.primaryColor,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isEmergency ? Colors.red : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _cancelDestinationSearch,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _destinationController,
                          decoration: const InputDecoration(
                            hintText: 'ابحث عن وجهة',
                            border: InputBorder.none,
                          ),
                          onChanged: _onDestinationSearchChanged,
                          autofocus: true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _destinationController.clear();
                          _onDestinationSearchChanged('');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _searchSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _searchSuggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(suggestion['name'] as String),
                    subtitle: Text(suggestion['address'] as String),
                    onTap: () => _selectDestination(suggestion),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    String reportType = 'accident';
    String description = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إبلاغ عن حادث'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: reportType,
                items: const [
                  DropdownMenuItem(value: 'accident', child: Text('حادث')),
                  DropdownMenuItem(
                    value: 'traffic',
                    child: Text('ازدحام مروري'),
                  ),
                  DropdownMenuItem(
                    value: 'hazard',
                    child: Text('خطر على الطريق'),
                  ),
                  DropdownMenuItem(value: 'police', child: Text('نقطة تفتيش')),
                ],
                onChanged: (value) {
                  setState(() {
                    reportType = value!;
                  });
                },
              ),
              TextField(
                decoration: const InputDecoration(hintText: 'وصف (اختياري)'),
                maxLines: 3,
                onChanged: (value) {
                  description = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                _submitReport(reportType, description);
                Navigator.pop(context);
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitReport(String type, String description) {
    final reportsProvider = Provider.of<ReportsProvider>(
      context,
      listen: false,
    );

    if (_currentPosition != null) {
      final report = ReportModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: ReportType.values.firstWhere(
          (t) => t.toString() == 'ReportType.$type',
          orElse: () => ReportType.accident,
        ),
        description: description,
        location: ReportLocation(
          lat: _currentPosition!.latitude,
          lng: _currentPosition!.longitude,
        ),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
        createdBy: 'current_user',
        status: ReportStatus.active,
        confirmations: ReportConfirmations(trueVotes: 0, falseVotes: 0),
        confirmedBy: [],
        deniedBy: [],
      );

      reportsProvider.createReport(
        type: report.type,
        description: report.description,
        createdBy: 'current_user',
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ بنجاح')));

      _updateMapMarkers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في تحديد موقعك الحالي')),
      );
    }
  }
}
