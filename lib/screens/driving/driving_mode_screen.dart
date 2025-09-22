import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../utils/map_utils.dart';

import '../../providers/reports_provider.dart';
import '../../models/report_model.dart';
import '../../models/warning_model.dart';
import '../../services/warning_service.dart';
import '../../services/navigation_service.dart';
import '../../widgets/warning_overlay.dart';
import '../../models/route_model.dart';
import '../../models/safety_model.dart';
import '../../services/safety_service.dart';
import '../../widgets/safety_overlay.dart';
import '../../services/voice_assistant_service.dart';
import '../../services/adaptive_interface_service.dart';
import 'driving_settings_screen.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../services/driving_settings_service.dart';
import '../../models/driving_settings_model.dart';

import '../../widgets/adaptive_interface_widget.dart';
import '../../widgets/ai_chat_widget.dart';
import '../../widgets/ar_navigation_widget.dart';
import '../../services/ai_assistant_service.dart';
import '../../widgets/performance_monitor_widget.dart';
import '../home/widgets/map_widget.dart';

class DrivingModeScreen extends StatefulWidget {
  static const String routeName = '/driving-mode';

  const DrivingModeScreen({Key? key}) : super(key: key);

  @override
  State<DrivingModeScreen> createState() => _DrivingModeScreenState();
}

class _DrivingModeScreenState extends State<DrivingModeScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Warning system
  final WarningService _warningService = WarningService();
  late NavigationService _navigationService;
  List<DrivingWarning> _activeWarnings = [];
  StreamSubscription<List<DrivingWarning>>? _warningsSubscription;
  StreamSubscription<NavigationState>? _navigationSubscription;
  StreamSubscription<String>? _voiceInstructionSubscription;

  // Safety system
  late SafetyService _safetyService;
  StreamSubscription<SpeedWarning>? _speedWarningSubscription;
  StreamSubscription<FatigueWarning>? _fatigueWarningSubscription;
  StreamSubscription<EmergencyEvent>? _emergencySubscription;
  final SafetySettings _safetySettings = const SafetySettings();

  // Voice assistant
  late VoiceAssistantService _voiceAssistant;
  StreamSubscription<String>? _voiceCommandSubscription;
  StreamSubscription<String>? _voiceResponseSubscription;
  StreamSubscription<bool>? _voiceListeningSubscription;
  bool _isVoiceListening = false;

  // Adaptive interface
  late AdaptiveInterfaceService _adaptiveInterface;
  late AIAssistantService _aiAssistantService;

  // Settings
  late DrivingSettingsService _settingsService;
  DrivingSettings _settings = const DrivingSettings();
  StreamSubscription<DrivingSettings>? _settingsSubscription;

  // Navigation data
  String _destination = 'المنزل';
  final String _remainingTime = '15 دقيقة';
  final String _remainingDistance = '8.5 كم';
  final double _currentSpeed = 0.0;
  bool _isDarkMode = false;
  NavigationState _navigationState = NavigationState.idle();
  bool _isNavigating = false;

  // Destination search
  final TextEditingController _destinationController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchSuggestions = [];
  LatLng? _selectedDestination;

  bool _isChatExpanded = false;
  bool _isARModeActive = false;
  bool _isPerformanceMonitorExpanded = false;

  // Animation controllers
  late AnimationController _speedAnimationController;
  late AnimationController _warningAnimationController;
  late Animation<double> _speedAnimation;
  late Animation<double> _warningAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeWarningSystem();
    _initializeLocation();
    _loadReports();
    _startWarningSystem();
    _detectTimeOfDay();
    _initializeAdaptiveInterface();
    _initializeAIAssistant();
    _initializeSettings();
  }

  void _initializeAnimations() {
    _speedAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _warningAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _speedAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _speedAnimationController, curve: Curves.easeOut),
    );
    _warningAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _warningAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _speedAnimationController.forward();
  }

  void _showVoiceInstruction(String instruction) {
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

  void _showAlternativeRoutes() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'الطرق البديلة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.route, color: Colors.blue),
              title: const Text('الطريق السريع'),
              subtitle: const Text('12 دقيقة - 6.2 كم'),
              trailing: const Text('أسرع بـ 3 دقائق'),
              onTap: () {
                Navigator.pop(context);
                _switchToAlternativeRoute('الطريق السريع');
              },
            ),
            ListTile(
              leading: const Icon(Icons.route, color: Colors.green),
              title: const Text('الطريق الداخلي'),
              subtitle: const Text('18 دقيقة - 7.8 كم'),
              trailing: const Text('أقل ازدحاماً'),
              onTap: () {
                Navigator.pop(context);
                _switchToAlternativeRoute('الطريق الداخلي');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _switchToAlternativeRoute(String routeName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم التبديل إلى $routeName'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _initializeWarningSystem() {
    _navigationService = NavigationService();

    _warningService.initialize();
    _navigationService.initialize();

    _warningsSubscription = _warningService.warningsStream.listen((warnings) {
      setState(() {
        _activeWarnings = warnings;
      });

      // Update map markers with warnings
      _updateWarningMarkers(warnings);
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

    // Initialize safety system
    _initializeSafetySystem();

    // Initialize voice assistant
    _initializeVoiceAssistant();
  }

  void _initializeAdaptiveInterface() async {
    _adaptiveInterface = AdaptiveInterfaceService();
    await _adaptiveInterface.initialize();
  }

  Future<void> _initializeAIAssistant() async {
    _aiAssistantService = AIAssistantService.instance;
    await _aiAssistantService.initialize();
  }

  void _initializeSettings() {
    _settingsService = DrivingSettingsService();
    _settingsSubscription = _settingsService.settingsStream.listen((settings) {
      setState(() {
        _settings = settings;
      });
    });
    _settingsService.initialize();
  }

  void _initializeSafetySystem() {
    _safetyService = SafetyService();
    _safetyService.initialize(_safetySettings);

    // Subscribe to safety warnings
    _speedWarningSubscription = _safetyService.speedWarnings.listen((warning) {
      // Speed warnings are handled by SafetyOverlay
    });

    _fatigueWarningSubscription = _safetyService.fatigueWarnings.listen((
      warning,
    ) {
      // Fatigue warnings are handled by SafetyOverlay
    });

    _emergencySubscription = _safetyService.emergencyEvents.listen((event) {
      if (event.type == EmergencyType.crashDetected) {
        // Additional crash handling if needed
      }
    });
  }

  void _initializeVoiceAssistant() async {
    _voiceAssistant = VoiceAssistantService();

    try {
      await _voiceAssistant.initialize(
        warningService: _warningService,
        navigationService: _navigationService,
        safetyService: _safetyService,
      );

      // Subscribe to voice events
      _voiceCommandSubscription = _voiceAssistant.commands.listen((command) {
        // Handle voice commands
      });

      _voiceResponseSubscription = _voiceAssistant.responses.listen((response) {
        // Handle voice responses
      });

      _voiceListeningSubscription = _voiceAssistant.isListening.listen((
        listening,
      ) {
        if (mounted) {
          setState(() {
            _isVoiceListening = listening;
          });
        }
      });
    } catch (e) {
      debugPrint('Voice assistant initialization failed: $e');
    }
  }

  void _updateWarningMarkers(List<DrivingWarning> warnings) {
    Set<Marker> warningMarkers = {};

    for (DrivingWarning warning in warnings) {
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

    setState(() {
      _markers = _markers
          .where((marker) => !marker.markerId.value.startsWith('warning_'))
          .toSet();
      _markers.addAll(warningMarkers);
    });
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
            Text('تفاصيل التحذير'),
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

  void _detectTimeOfDay() {
    final hour = DateTime.now().hour;
    setState(() {
      _isDarkMode = hour < 6 || hour > 18;
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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

    Set<Marker> newMarkers = {};

    for (ReportModel report in reports) {
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
        _markers = newMarkers;
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
        return 'roadwork';
      case ReportType.bump:
        return 'police';
      case ReportType.closedRoad:
        return 'roadwork';
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

  void _startWarningSystem() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForWarnings();
    });
  }

  void _checkForWarnings() {
    // Simulate warning detection
    if (_activeWarnings.isEmpty) {
      setState(() {
        _activeWarnings.add(
          DrivingWarning(
            id: 'warning_${DateTime.now().millisecondsSinceEpoch}',
            type: WarningType.accident,
            message: 'حادث خلال 800م في المسار الأيسر',
            distance: 800,
            severity: WarningSeverity.high,
            location: LatLng(
              _currentPosition?.latitude ?? 0,
              _currentPosition?.longitude ?? 0,
            ),
            timestamp: DateTime.now(),
            isActive: true,
          ),
        );
      });
      _warningAnimationController.forward();
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
      _clearSearchSuggestions();
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

  void _clearSearchSuggestions() {
    setState(() {
      _searchSuggestions.clear();
    });
  }

  void _selectDestination(Map<String, dynamic> destination) {
    setState(() {
      _destination = destination['name'];
      _selectedDestination = LatLng(destination['lat'], destination['lng']);
      _isSearching = false;
      _destinationController.clear();
      _searchSuggestions.clear();
    });

    // Start navigation to selected destination
    _startNavigationToDestination();
  }

  void _startNavigationToDestination() {
    if (_selectedDestination != null) {
      setState(() {
        _isNavigating = true;
      });

      // Start navigation service
      _navigationService.startNavigation(destination: _selectedDestination!);

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('بدء التنقل إلى $_destination'),
          backgroundColor: LiquidGlassTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Helper methods for navigation
  String _formatDistance(int distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters}م';
    } else {
      final km = (distanceInMeters / 1000).toStringAsFixed(1);
      return '${km}كم';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}س ${minutes}د';
    } else {
      return '${minutes}د';
    }
  }

  // Build real-time reports overlay
  Widget _buildReportsOverlay() {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, child) {
        final nearbyReports = reportsProvider.nearbyReports
            .where((report) => report.status == ReportStatus.active)
            .take(3)
            .toList();

        if (nearbyReports.isEmpty) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 200,
          left: 16,
          right: 16,
          child: Column(
            children: nearbyReports
                .map((report) => _buildReportCard(report))
                .toList(),
          ),
        );
      },
    );
  }

  // Build individual report card
  Widget _buildReportCard(ReportModel report) {
    final distance = _calculateDistanceToReport(report);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getReportColor(report.type).withOpacity(0.9),
            _getReportColor(report.type).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Report icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getReportIcon(report.type),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Report info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.typeNameArabic,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (report.description.isNotEmpty)
                  Text(
                    report.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Distance and trust score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                distance,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.thumb_up,
                    color: Colors.white.withOpacity(0.8),
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${(report.trustScore * 100).round()}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Action buttons
          const SizedBox(width: 8),
          Column(
            children: [
              GestureDetector(
                onTap: () => _confirmReport(report, true),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _confirmReport(report, false),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods for reports
  String _calculateDistanceToReport(ReportModel report) {
    if (_currentPosition == null) return '---';

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      report.location.lat,
      report.location.lng,
    );

    if (distance < 1000) {
      return '${distance.round()}م';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}كم';
    }
  }

  Color _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return Colors.red;
      case ReportType.jam:
        return Colors.orange;
      case ReportType.carBreakdown:
        return Colors.purple;
      case ReportType.bump:
        return Colors.yellow;
      case ReportType.closedRoad:
        return Colors.grey;
    }
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
    }
  }

  void _confirmReport(ReportModel report, bool isTrue) async {
    final reportsProvider = Provider.of<ReportsProvider>(
      context,
      listen: false,
    );
    final success = await reportsProvider.voteOnReport(
      reportId: report.id,
      userId: 'current_user_id', // Replace with actual user ID
      isTrue: isTrue,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTrue ? 'تم تأكيد البلاغ' : 'تم رفض البلاغ'),
          backgroundColor: isTrue ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      case 'merge':
        return Icons.merge;
      case 'fork-left':
      case 'fork-right':
        return Icons.call_split;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      case 'arrive':
        return Icons.location_on;
      case 'straight':
      default:
        return Icons.straight;
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _speedAnimationController.dispose();
    _warningAnimationController.dispose();
    _positionStream?.cancel();
    _warningsSubscription?.cancel();
    _navigationSubscription?.cancel();
    _voiceInstructionSubscription?.cancel();
    _warningService.dispose();
    _navigationService.dispose();
    _speedWarningSubscription?.cancel();
    _fatigueWarningSubscription?.cancel();
    _emergencySubscription?.cancel();
    _safetyService.dispose();
    _voiceCommandSubscription?.cancel();
    _voiceResponseSubscription?.cancel();
    _voiceListeningSubscription?.cancel();
    _voiceAssistant.dispose();
    _adaptiveInterface.dispose();
    _settingsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode
          ? Colors.black
          : LiquidGlassTheme.backgroundColor,
      body: AdaptiveInterfaceWidget(
        enableAdaptation: true,
        child: Stack(
          children: [
            // Map
            MapWidget(
              onMapCreated: _onMapCreated,
              currentPosition: _currentPosition,
              markers: _markers,
              onMarkerTapped: (report) {},
            ),

            // Route polyline overlay
            if (_polylines.isNotEmpty)
              GoogleMap(
                polylines: _polylines,
                initialCameraPosition: CameraPosition(
                  target: _currentPosition != null
                      ? LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        )
                      : MapUtils.defaultLocation,
                  zoom: 15,
                ),
              ),

            // Top Status Bar or Search Bar
            _isSearching ? _buildDestinationSearchBar() : _buildTopStatusBar(),

            // Safety overlay - Emergency notifications
            SafetyOverlay(
              safetyService: _safetyService,
              onEmergencyCancel: () {
                // Handle emergency cancellation
              },
              onUserInteraction: () {
                _safetyService.recordUserInteraction();
              },
            ),

            // Warning overlay - Positioned below status bar
            Positioned(
              top: 140,
              left: 16,
              right: 16,
              child: WarningOverlay(
                isDarkMode: _isDarkMode,
                onDismissAll: () {
                  _warningService.dismissAllWarnings();
                },
              ),
            ),

            // Real-time reports overlay - Positioned below warning overlay
            if (_settings.showTraffic) _buildReportsOverlay(),

            // Navigation Info - Only when navigating
            if (_isNavigating && _settings.showNavigationInfo)
              _buildNavigationInfo(),

            // Navigation controls and info
            if (_isNavigating) ..._buildNavigationUI(),

            // Bottom controls - Always visible
            if (_settings.showBottomControls) _buildBottomControls(),

            // Floating action buttons - Right side
            _buildFloatingActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStatusBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkMode
                ? [
                    Colors.black.withAlpha(204),
                    Colors.grey[900]!.withAlpha(204),
                  ]
                : [
                    Colors.white.withAlpha(229),
                    Colors.grey[100]!.withAlpha(229),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Compact driving mode indicator
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: LiquidGlassTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.drive_eta, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),

            // Compact title with search button
            GestureDetector(
              onTap: () => _startDestinationSearch(),
              child: Row(
                children: [
                  Text(
                    'قيادة',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.search,
                    color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                    size: 16,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Status indicators row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current location button
                GestureDetector(
                  onTap: () {
                    _initializeLocation();
                    _animateToCurrentLocation();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _currentPosition != null 
                          ? Colors.green.withAlpha(51)
                          : Colors.orange.withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _currentPosition != null 
                          ? Icons.gps_fixed 
                          : Icons.gps_not_fixed,
                      color: _currentPosition != null 
                          ? Colors.green 
                          : Colors.orange,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Speed Display - Compact
                AnimatedBuilder(
                  animation: _speedAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _currentSpeed > 80
                            ? Colors.red.withAlpha(51)
                            : Colors.green.withAlpha(51),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(_currentSpeed * _speedAnimation.value).round()}',
                        style: TextStyle(
                          color: _currentSpeed > 80 ? Colors.red : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationSearchBar() {
    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDarkMode
                    ? [
                        Colors.black.withAlpha(229),
                        Colors.grey[900]!.withAlpha(229),
                      ]
                    : [
                        Colors.white.withAlpha(242),
                        Colors.grey[50]!.withAlpha(242),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _cancelDestinationSearch(),
                  icon: Icon(
                    Icons.arrow_back,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _destinationController,
                    autofocus: true,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'إلى أين تريد الذهاب؟',
                      hintStyle: TextStyle(
                        color: _isDarkMode ? Colors.white54 : Colors.grey[500],
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: LiquidGlassTheme.primaryColor,
                      ),
                    ),
                    onChanged: _onDestinationSearchChanged,
                  ),
                ),
                if (_destinationController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _destinationController.clear();
                      _clearSearchSuggestions();
                    },
                    icon: Icon(
                      Icons.clear,
                      color: _isDarkMode ? Colors.white54 : Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          // Search suggestions
          if (_searchSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDarkMode
                      ? [
                          Colors.black.withAlpha(229),
                          Colors.grey[900]!.withAlpha(229),
                        ]
                      : [
                          Colors.white.withAlpha(242),
                          Colors.grey[50]!.withAlpha(242),
                        ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _searchSuggestions[index];
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: LiquidGlassTheme.primaryColor,
                    ),
                    title: Text(
                      suggestion['name'],
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      suggestion['address'],
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white54 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => _selectDestination(suggestion),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWarningOverlay() {
    return AnimatedBuilder(
      animation: _warningAnimation,
      builder: (context, child) {
        return Positioned(
          top: 120,
          left: 16,
          right: 16,
          child: Transform.scale(
            scale: _warningAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withAlpha(229),
                    Colors.orange.withAlpha(229),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withAlpha(76),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _activeWarnings.first.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _activeWarnings.clear();
                      });
                      _warningAnimationController.reverse();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationInfo() {
    final route = _navigationState.route;
    if (route == null) {
      return const SizedBox.shrink();
    }

    final remainingTime = _formatDuration(route.estimatedTimeRemaining);
    final remainingDistance = _formatDistance(route.remainingDistance);
    final destinationName =
        (_navigationState.destinationName ?? _selectedDestination ?? 'الوجهة')
            .toString();

    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkMode
                ? [
                    Colors.black.withAlpha(229),
                    Colors.grey[900]!.withAlpha(229),
                  ]
                : [
                    Colors.white.withAlpha(242),
                    Colors.grey[50]!.withAlpha(242),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Route Info
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: LiquidGlassTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'موقعك',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 40,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LiquidGlassTheme.getGradientByName('primary'),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const Spacer(),
                Icon(Icons.flag, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    destinationName,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Time and Distance
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '$remainingTime متبقية',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  '|',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white30 : Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 20),
                Icon(
                  Icons.straighten,
                  color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  remainingDistance,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              _isDarkMode
                  ? Colors.black.withAlpha(230)
                  : Colors.white.withAlpha(230),
              _isDarkMode ? Colors.black : Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _isNavigating
                ? _buildNavigationControls()
                : _buildDefaultControls(),
          ),
        ),
      ),
    );
  }

  void _toggleVoiceListening() async {
    if (_isVoiceListening) {
      await _voiceAssistant.stopListening();
    } else {
      await _voiceAssistant.startListening();
    }
  }

  Widget _buildFloatingActions() {
    if (!_settings.showFloatingActions) return const SizedBox.shrink();

    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AR Navigation Toggle
          if (!_isNavigating && _settings.showARNavigation) ...[
            FloatingActionButton(
              heroTag: "ar_toggle",
              mini: true,
              backgroundColor: _isARModeActive
                  ? LiquidGlassTheme.primaryColor
                  : Colors.grey[600],
              onPressed: () {
                setState(() {
                  _isARModeActive = !_isARModeActive;
                });
              },
              child: const Icon(
                Icons.view_in_ar,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Performance Monitor Toggle
          if (_settings.showPerformanceMonitor)
            FloatingActionButton(
              heroTag: "performance_toggle",
              mini: true,
              backgroundColor: _isPerformanceMonitorExpanded
                  ? LiquidGlassTheme.primaryColor
                  : Colors.grey[600],
              onPressed: () {
                setState(() {
                  _isPerformanceMonitorExpanded =
                      !_isPerformanceMonitorExpanded;
                });
              },
              child: const Icon(Icons.speed, color: Colors.white, size: 20),
            ),
          const SizedBox(height: 8),

          // AI Chat Toggle
          if (_settings.showAIChat)
            FloatingActionButton(
              heroTag: "chat_toggle",
              mini: true,
              backgroundColor: _isChatExpanded
                  ? LiquidGlassTheme.primaryColor
                  : Colors.grey[600],
              onPressed: () {
                setState(() {
                  _isChatExpanded = !_isChatExpanded;
                });
              },
              child: const Icon(Icons.chat, color: Colors.white, size: 20),
            ),
          const SizedBox(height: 8),

          // Voice Assistant Button
          if (_settings.showVoiceAssistant)
            FloatingActionButton(
              heroTag: "voice_assistant",
              backgroundColor: _isVoiceListening
                  ? Colors.red.shade600
                  : LiquidGlassTheme.primaryColor,
              onPressed: _toggleVoiceListening,
              child: Icon(
                _isVoiceListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar like Google Maps
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showDestinationDialog(),
              borderRadius: BorderRadius.circular(25),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'إلى أين تريد الذهاب؟',
                        style: TextStyle(
                          color: _isDarkMode
                              ? Colors.white70
                              : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.mic,
                      color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Action buttons row
        Row(
          children: [
            Expanded(
              child: _buildModernControlButton(
                'إبلاغ سريع',
                Icons.report_problem,
                Colors.orange,
                () => _showReportDialog(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModernControlButton(
                'طرق آمنة',
                Icons.route,
                Colors.green,
                () => _showSafeRoutesDialog(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModernControlButton(
                'طوارئ',
                Icons.emergency,
                Colors.red,
                () => _showEmergencyDialog(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModernControlButton(
                'إعدادات',
                Icons.settings,
                Colors.grey,
                () => _showSettingsDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Navigation info card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Navigation icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LiquidGlassTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Navigation details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _destination,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _remainingTime,
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white70
                                : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white70
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _remainingDistance,
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white70
                                : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Stop button
              IconButton(
                onPressed: () => _stopNavigation(),
                icon: Icon(
                  Icons.close,
                  color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        // Control buttons
        Row(
          children: [
            Expanded(
              child: _buildModernControlButton(
                'طريق بديل',
                Icons.alt_route,
                Colors.blue,
                () => _showAlternativeRoute(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernControlButton(
                'إبلاغ',
                Icons.report_problem,
                Colors.orange,
                () => _showReportDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernControlButton(
                'خيارات',
                Icons.more_horiz,
                Colors.grey,
                () => _showNavigationOptions(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildNavigationUI() {
    return [
      // Route information card
      Positioned(top: 180, left: 16, right: 16, child: _buildRouteInfoCard()),

      // Next instruction card
      if (_navigationState.route?.instructions.isNotEmpty == true)
        Positioned(
          top: 280,
          left: 16,
          right: 16,
          child: _buildNextInstructionCard(),
        ),
    ];
  }

  Widget _buildRouteInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [Colors.black.withAlpha(229), Colors.grey[900]!.withAlpha(229)]
              : [Colors.white.withAlpha(242), Colors.grey[50]!.withAlpha(242)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _destination,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _remainingTime,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.straighten,
                      color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _remainingDistance,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'طريق آمن',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextInstructionCard() {
    final route = _navigationState.route;
    if (route == null || route.instructions.isEmpty) {
      return const SizedBox.shrink();
    }

    final nextInstruction = route.instructions.first;
    final distanceText = _formatDistance(nextInstruction.distance);
    final maneuverIcon = _getManeuverIcon(nextInstruction.maneuver);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            LiquidGlassTheme.primaryColor.withAlpha(229),
            LiquidGlassTheme.primaryColor.withAlpha(178),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: LiquidGlassTheme.primaryColor.withAlpha(76),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(maneuverIcon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextInstruction.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (nextInstruction.streetName != null)
                  Text(
                    nextInstruction.streetName!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            distanceText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(204), color.withAlpha(153)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(76),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernControlButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDestinationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر الوجهة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('المنزل'),
              onTap: () {
                Navigator.pop(context);
                _startNavigation('المنزل');
              },
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('العمل'),
              onTap: () {
                Navigator.pop(context);
                _startNavigation('العمل');
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('بحث عن مكان'),
              onTap: () {
                Navigator.pop(context);
                _showSearchDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('البحث عن مكان'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'أدخل اسم المكان أو العنوان',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNavigation('الوجهة المحددة');
            },
            child: const Text('بدء الملاحة'),
          ),
        ],
      ),
    );
  }

  void _startNavigation(String destination) {
    setState(() {
      _destination = destination;
      _isNavigating = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('بدء الملاحة إلى $destination'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إيقاف الملاحة'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showAlternativeRoute() {
    _showAlternativeRoutes();
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إبلاغ سريع'),
        content: const Text('ما نوع المشكلة التي تريد الإبلاغ عنها؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إرسال البلاغ بنجاح')),
              );
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[50],
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text(
              'أرقام الطوارئ',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEmergencyContact(
              'الإسعاف',
              '997',
              Icons.local_hospital,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildEmergencyContact(
              'الشرطة',
              '999',
              Icons.local_police,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildEmergencyContact(
              'المطافئ',
              '998',
              Icons.local_fire_department,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildEmergencyContact(
              'الدفاع المدني',
              '911',
              Icons.security,
              Colors.green,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(
    String title,
    String number,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _callEmergencyNumber(number),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        number,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.phone, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _callEmergencyNumber(String number) async {
    Navigator.pop(context);

    // Show confirmation dialog
    final shouldCall = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الاتصال'),
        content: Text('هل تريد الاتصال بالرقم $number؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('اتصال'),
          ),
        ],
      ),
    );

    if (shouldCall == true) {
      // Here you would implement the actual phone call
      // For now, we'll show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('جاري الاتصال بـ $number...'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSettingsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DrivingSettingsScreen()),
    );
  }

  Widget _buildWeatherInfo() {
    return Positioned(
      top: 80,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkMode
                ? [
                    Colors.black.withAlpha(204),
                    Colors.grey[900]!.withAlpha(204),
                  ]
                : [
                    Colors.white.withAlpha(229),
                    Colors.grey[100]!.withAlpha(229),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wb_sunny, color: Colors.orange, size: 16),
            const SizedBox(width: 6),
            Text(
              '25°',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 16,
              color: _isDarkMode ? Colors.white30 : Colors.grey[400],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.visibility,
              color: _isDarkMode ? Colors.white70 : Colors.grey[600],
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'جيدة',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSafeRoutesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الطرق الآمنة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.route, color: Colors.green),
              ),
              title: const Text('الطريق الأسرع'),
              subtitle: const Text('15 دقيقة • 8.5 كم'),
              onTap: () {
                Navigator.pop(context);
                _selectRoute('fastest');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.security, color: Colors.blue),
              ),
              title: const Text('الطريق الأكثر أماناً'),
              subtitle: const Text('18 دقيقة • 9.2 كم'),
              onTap: () {
                Navigator.pop(context);
                _selectRoute('safest');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.eco, color: Colors.orange),
              ),
              title: const Text('الطريق الاقتصادي'),
              subtitle: const Text('20 دقيقة • 7.8 كم'),
              onTap: () {
                Navigator.pop(context);
                _selectRoute('eco');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showNavigationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'خيارات الملاحة',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNavigationOption(
                      'تجنب الطرق السريعة',
                      Icons.no_crash,
                      () => _toggleAvoidHighways(),
                    ),
                    _buildNavigationOption(
                      'تجنب الرسوم',
                      Icons.money_off,
                      () => _toggleAvoidTolls(),
                    ),
                    _buildNavigationOption(
                      'تجنب العبارات',
                      Icons.directions_boat_outlined,
                      () => _toggleAvoidFerries(),
                    ),
                    _buildNavigationOption(
                      'الوضع الليلي',
                      Icons.dark_mode,
                      () => _toggleDarkMode(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationOption(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: _isDarkMode ? Colors.white70 : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
      ),
      onTap: onTap,
      trailing: Icon(
        Icons.chevron_right,
        color: _isDarkMode ? Colors.white70 : Colors.grey[600],
      ),
    );
  }

  void _selectRoute(String routeType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم اختيار الطريق: $routeType'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleAvoidHighways() {
    Navigator.pop(context);
  }

  void _toggleAvoidTolls() {
    Navigator.pop(context);
  }

  void _toggleAvoidFerries() {
    Navigator.pop(context);
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    Navigator.pop(context);
  }
}
