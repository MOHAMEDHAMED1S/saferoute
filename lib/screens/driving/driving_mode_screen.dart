import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'dart:async';

import '../../providers/reports_provider.dart';
import '../../models/report_model.dart';
import '../../models/warning_model.dart';
import '../../services/warning_service.dart';
import '../../services/navigation_service.dart';
import '../../models/route_model.dart';
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
  // Map controllers
  geo.Position? _currentPosition;
  StreamSubscription<geo.Position>? _positionStream;

  // Navigation
  final NavigationService _navigationService = NavigationService();
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

  // Reports provider
  late ReportsProvider _reportsProvider;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
    _initializeLocationService();
  }

  void _initializeAnimations() {
    _warningAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _warningAnimation = CurvedAnimation(
      parent: _warningAnimationController,
      curve: Curves.elasticOut,
    );
  }

  void _initializeServices() {
    _reportsProvider = Provider.of<ReportsProvider>(context, listen: false);

    // Subscribe to navigation state changes
     _navigationSubscription = _navigationService.navigationStateStream.listen(
       (state) {
         setState(() {
           _isNavigating = state.type == NavigationStateType.navigating;
         });
       },
     );

    // Subscribe to voice instructions
    _voiceInstructionSubscription =
        _navigationService.voiceInstructionStream.listen(
      (instruction) {
        // Handle voice instruction
        _speakInstruction(instruction);
      },
    );

    // Subscribe to warnings
    _warningsSubscription = _warningService.warningsStream.listen(
      (warnings) {
        setState(() {
          _activeWarnings = warnings;
        });
        if (warnings.isNotEmpty) {
          _warningAnimationController.forward();
        } else {
          _warningAnimationController.reverse();
        }
      },
    );
  }

  void _initializeLocationService() async {
    final permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      final requestedPermission = await geo.Geolocator.requestPermission();
      if (requestedPermission == geo.LocationPermission.denied) {
        return;
      }
    }

    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _updateMapMarkers();
      }
    });
  }

  void _updateMapMarkers() {
    // MapboxWidget handles markers internally
  }

  void _speakInstruction(String instruction) {
    // Implement text-to-speech for navigation instructions
  }

  @override
  void dispose() {
    _warningAnimationController.dispose();
    _positionStream?.cancel();
    _navigationSubscription?.cancel();
    _voiceInstructionSubscription?.cancel();
    _warningsSubscription?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

  void _onMapCreated() {
    // MapboxWidget handles map creation
  }

  void _animateToCurrentLocation() {
    // MapboxWidget handles location animation
  }

  void _startDestinationSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _cancelDestinationSearch() {
    setState(() {
      _isSearching = false;
      _searchSuggestions = [];
    });
    _destinationController.clear();
  }

  void _onDestinationSearchChanged(String query) {
    _searchDestination(query);
  }

  void _searchDestination(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
      });
      return;
    }

    // Mock search results
    final suggestions = [
      {
        'name': 'مطار الملك خالد الدولي',
        'address': 'الرياض، المملكة العربية السعودية',
        'latitude': 24.9576,
        'longitude': 46.6988,
      },
      {
        'name': 'برج المملكة',
        'address': 'الرياض، المملكة العربية السعودية',
        'latitude': 24.7116,
        'longitude': 46.6753,
      },
    ];

    setState(() {
      _searchSuggestions = suggestions;
    });
  }

  void _selectDestination(Map<String, dynamic> destination) async {
    final destinationPosition = Position(
      latitude: destination['latitude'],
      longitude: destination['longitude'],
    );

    _startNavigation(destinationPosition);
  }

  void _startNavigation(Position destination) {
    if (_currentPosition == null) return;

    final origin = Position(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
    );

    // Create a mock route
    final route = RouteInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startLocation: origin,
      endLocation: destination,
      polylinePoints: [origin, destination],
      totalDistance: 5000,
      remainingDistance: 5000,
      estimatedTotalTime: const Duration(minutes: 15),
      estimatedTimeRemaining: const Duration(minutes: 15),
      routeType: RouteType.fastest,
      trafficCondition: TrafficCondition.moderate,
      instructions: [],
      safetyScore: 85,
    );

    _navigationService.startNavigation(route);

    setState(() {
      _isNavigating = true;
      _selectedDestination = '${destination.latitude}, ${destination.longitude}';
      _isSearching = false;
    });
  }

  void _stopNavigation() {
    _navigationService.stopNavigation();
    setState(() {
      _isNavigating = false;
      _selectedDestination = null;
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

  String _getWarningTypeText(WarningType type) {
    switch (type) {
      case WarningType.speedLimit:
        return 'تحذير من السرعة';
      case WarningType.accident:
        return 'حادث مروري';
      case WarningType.roadwork:
        return 'أعمال طريق';
      case WarningType.police:
        return 'نقطة تفتيش';
      case WarningType.traffic:
        return 'ازدحام مروري';
      case WarningType.speedCamera:
        return 'كاميرا سرعة';
      case WarningType.general:
        return 'تحذير عام';
    }
  }

  Widget _buildMap() {
    return MapboxWidget();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          _buildMap(),

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
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                .withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
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
    if (!_isNavigating || _navigationService.currentRoute == null) {
      return const SizedBox.shrink();
    }

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
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              "جاري التنقل...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
          if (_isNavigating)
            _buildControlButton(
              icon: Icons.stop,
              label: 'إيقاف',
              onTap: _stopNavigation,
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
        color: Colors.black.withValues(alpha: 0.5),
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
