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
  
  // Navigation data
  String _destination = 'المنزل';
  final String _remainingTime = '15 دقيقة';
  final String _remainingDistance = '8.5 كم';
  final double _currentSpeed = 0.0;
  bool _isDarkMode = false;
  NavigationState _navigationState = NavigationState.idle();
  bool _isNavigating = false;

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
  }

  void _initializeAnimations() {
    _speedAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
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
    _warningAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _speedAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _speedAnimationController, curve: Curves.easeOut),
    );
    _warningAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _warningAnimationController, curve: Curves.elasticOut),
    );
    
    _speedAnimationController.forward();
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
    
    _navigationSubscription = _navigationService.navigationStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _navigationState = state;
          _isNavigating = state.isNavigating;
        });
      }
    });
    
    _voiceInstructionSubscription = _navigationService.voiceInstructionStream.listen((instruction) {
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
  
  void _initializeSafetySystem() {
    _safetyService = SafetyService();
    _safetyService.initialize(_safetySettings);
    
    // Subscribe to safety warnings
    _speedWarningSubscription = _safetyService.speedWarnings.listen((warning) {
      // Speed warnings are handled by SafetyOverlay
    });
    
    _fatigueWarningSubscription = _safetyService.fatigueWarnings.listen((warning) {
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
      
      _voiceListeningSubscription = _voiceAssistant.isListening.listen((listening) {
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
      _markers = _markers.where((marker) => !marker.markerId.value.startsWith('warning_')).toSet();
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
      final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
      await reportsProvider.initialize();
      _updateMapMarkers();
    } catch (e) {
      debugPrint('خطأ في تحميل البلاغات: $e');
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
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case 'roadwork':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
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
            location: LatLng(_currentPosition?.latitude ?? 0, _currentPosition?.longitude ?? 0),
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
      final latLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      final cameraUpdate = MapUtils.safeCameraUpdate(latLng);
      await MapUtils.animateCameraSafely(_mapController, cameraUpdate);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _animateToCurrentLocation();
  }

  @override
  void dispose() {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : LiquidGlassTheme.backgroundColor,
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
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : MapUtils.defaultLocation,
                zoom: 15,
              ),
            ),
            
          // Warning overlay
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: WarningOverlay(
              isDarkMode: _isDarkMode,
              onDismissAll: () {
                _warningService.dismissAllWarnings();
              },
            ),
          ),
          
          // Safety overlay
          SafetyOverlay(
            safetyService: _safetyService,
            onEmergencyCancel: () {
              // Handle emergency cancellation
            },
            onUserInteraction: () {
              _safetyService.recordUserInteraction();
            },
          ),
          
          // Top Status Bar
          _buildTopStatusBar(),
          
          // Weather and adaptive info
          _buildWeatherInfo(),
          
          // Warning Overlay
          if (_activeWarnings.isNotEmpty) _buildWarningOverlay(),
          
          // Navigation Info
          _buildNavigationInfo(),
          
          // Navigation controls and info
          if (_isNavigating) ..._buildNavigationUI(),
          
          // AR Navigation Widget
            ARNavigationWidget(
              isActive: _isARModeActive,
              onToggle: () {
                setState(() {
                  _isARModeActive = !_isARModeActive;
                });
              },
              onCalibrate: () {
                // Handle AR calibration
              },
            ),
            
            // Performance Monitor Widget
            Positioned(
              bottom: _isChatExpanded ? 320 : 240,
              left: 20,
              right: 20,
              child: PerformanceMonitorWidget(
                isExpanded: _isPerformanceMonitorExpanded,
                onToggle: () {
                  setState(() {
                    _isPerformanceMonitorExpanded = !_isPerformanceMonitorExpanded;
                  });
                },
              ),
            ),
            
            // AI Chat Widget
            Positioned(
              bottom: 160,
              left: 20,
              right: 20,
              child: AIChatWidget(
                isExpanded: _isChatExpanded,
                onToggleExpand: () {
                  setState(() {
                    _isChatExpanded = !_isChatExpanded;
                  });
                },
              ),
            ),
            
            // Bottom controls
            _buildBottomControls(),
            
            // Voice assistant button
            _buildVoiceAssistantButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStatusBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkMode
                ? [Colors.black.withAlpha(204), Colors.grey[900]!.withAlpha(204)]
                : [Colors.white.withAlpha(229), Colors.grey[100]!.withAlpha(229)],
          ),
          borderRadius: BorderRadius.circular(25),
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
            // Driving Mode Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LiquidGlassTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.drive_eta,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Title
            Text(
              'وضع القيادة',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const Spacer(),
            
            // Sound Icon
            Icon(
              Icons.volume_up,
              color: _isDarkMode ? Colors.white70 : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            
            // Location Icon
            Icon(
              Icons.location_on,
              color: _isDarkMode ? Colors.white70 : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            
            // Speed Display
            AnimatedBuilder(
              animation: _speedAnimation,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _currentSpeed > 80
                        ? Colors.red.withAlpha(51)
                        : Colors.green.withAlpha(51),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${(_currentSpeed * _speedAnimation.value).round()} كم/س',
                    style: TextStyle(
                      color: _currentSpeed > 80 ? Colors.red : Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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
                  const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 24,
                  ),
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
    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkMode
                ? [Colors.black.withAlpha(229), Colors.grey[900]!.withAlpha(229)]
                : [Colors.white.withAlpha(242), Colors.grey[50]!.withAlpha(242)],
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
                Icon(
                  Icons.flag,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _destination,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
                  '$_remainingTime متبقية',
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
                  _remainingDistance,
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
      bottom: 80, // Moved up to make room for voice button
      left: 20,
      right: 20,
      child: _isNavigating ? _buildNavigationControls() : _buildDefaultControls(),
    );
  }
  
  Widget _buildVoiceAssistantButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: GestureDetector(
        onTap: _toggleVoiceListening,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _isVoiceListening 
                ? LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: [
              BoxShadow(
                color: (_isVoiceListening ? Colors.red : Colors.blue).withAlpha(76),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            _isVoiceListening ? Icons.mic : Icons.mic_none,
            color: Colors.white,
            size: 28,
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
  
  Widget _buildDefaultControls() {
    return Row(
      children: [
        Expanded(
          child: _buildControlButton(
            'ملاحة',
            Icons.navigation,
            LiquidGlassTheme.primaryColor,
            () => _showDestinationDialog(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildControlButton(
            'إبلاغ',
            Icons.report,
            Colors.orange,
            () => _showReportDialog(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildControlButton(
            'إعدادات',
            Icons.settings,
            Colors.grey,
            () => _showSettingsDialog(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildNavigationControls() {
    return Row(
      children: [
        Expanded(
          child: _buildControlButton(
            'طريق بديل',
            Icons.alt_route,
            Colors.blue,
            () => _showAlternativeRoute(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildControlButton(
            'إبلاغ',
            Icons.report,
            Colors.orange,
            () => _showReportDialog(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildControlButton(
            'إيقاف',
            Icons.stop,
            Colors.red,
            () => _stopNavigation(),
          ),
        ),
      ],
    );
  }
  
  List<Widget> _buildNavigationUI() {
    return [
      // Route information card
      Positioned(
        top: 180,
        left: 16,
        right: 16,
        child: _buildRouteInfoCard(),
      ),
      
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
            child: const Icon(
              Icons.turn_right,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'انعطف يميناً',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'شارع الملك فهد',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '200م',
            style: TextStyle(
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
          colors: [
            color.withAlpha(204),
            color.withAlpha(153),
          ],
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
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
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

  void _showSettingsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DrivingSettingsScreen(),
      ),
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
                ? [Colors.black.withAlpha(204), Colors.grey[900]!.withAlpha(204)]
                : [Colors.white.withAlpha(229), Colors.grey[100]!.withAlpha(229)],
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
            Icon(
              Icons.wb_sunny,
              color: Colors.orange,
              size: 16,
            ),
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
}