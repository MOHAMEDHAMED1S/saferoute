import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ar_navigation_model.dart';
import '../services/ar_navigation_service.dart';

class ARNavigationWidget extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onToggle;
  final VoidCallback? onCalibrate;
  
  const ARNavigationWidget({
    super.key,
    required this.isActive,
    this.onToggle,
    this.onCalibrate,
  });
  
  @override
  State<ARNavigationWidget> createState() => _ARNavigationWidgetState();
}

class _ARNavigationWidgetState extends State<ARNavigationWidget>
    with TickerProviderStateMixin {
  late ARNavigationService _arService;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  
  // Stream subscriptions
  StreamSubscription<List<ARNavigationData>>? _arDataSubscription;
  StreamSubscription<ARCalibration>? _calibrationSubscription;
  StreamSubscription<List<ARLandmark>>? _landmarksSubscription;
  StreamSubscription<bool>? _arModeSubscription;
  
  // State
  List<ARNavigationData> _arData = [];
  ARCalibration? _calibration;
  List<ARLandmark> _landmarks = [];
  bool _isCalibrated = false;
  bool _showCalibrationPrompt = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeARService();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _scaleController.forward();
  }
  
  Future<void> _initializeARService() async {
    _arService = ARNavigationService.instance;
    
    if (!_arService.isInitialized) {
      await _arService.initialize();
    }
    
    _setupStreamSubscriptions();
    
    if (widget.isActive) {
      await _arService.startARMode();
    }
  }
  
  void _setupStreamSubscriptions() {
    _arDataSubscription = _arService.arDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _arData = data;
        });
      }
    });
    
    _calibrationSubscription = _arService.calibrationStream.listen((calibration) {
      if (mounted) {
        setState(() {
          _calibration = calibration;
          _isCalibrated = calibration.isCalibrated;
          _showCalibrationPrompt = !calibration.isCalibrated;
        });
      }
    });
    
    _landmarksSubscription = _arService.landmarksStream.listen((landmarks) {
      if (mounted) {
        setState(() {
          _landmarks = landmarks;
        });
      }
    });
    
    _arModeSubscription = _arService.arModeStream.listen((isActive) {
      if (mounted && isActive != widget.isActive) {
        // Handle AR mode state changes
      }
    });
  }
  
  @override
  void didUpdateWidget(ARNavigationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _arService.startARMode();
        _scaleController.forward();
      } else {
        _arService.stopARMode();
        _scaleController.reverse();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return _buildARToggleButton();
    }
    
    return Stack(
      children: [
        // AR Camera View (simulated)
        _buildARCameraView(),
        
        // AR Overlays
        ..._buildAROverlays(),
        
        // AR Instructions
        _buildARInstructions(),
        
        // AR Landmarks
        _buildARLandmarks(),
        
        // AR Controls
        _buildARControls(),
        
        // Calibration prompt
        if (_showCalibrationPrompt) _buildCalibrationPrompt(),
      ],
    );
  }
  
  Widget _buildARToggleButton() {
    return Positioned(
      top: 100,
      right: 20,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: widget.onToggle,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    child: const Icon(
                      Icons.view_in_ar,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildARCameraView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900.withValues(alpha: 0.3),
            Colors.blue.shade700.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value * 0.5,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.cyan.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: CustomPaint(
                painter: ARGridPainter(),
                size: Size.infinite,
              ),
            ),
          );
        },
      ),
    );
  }
  
  List<Widget> _buildAROverlays() {
    return _arData.map((data) => _buildAROverlay(data)).toList();
  }
  
  Widget _buildAROverlay(ARNavigationData data) {
    final overlay = data.overlay;
    if (!overlay.isVisible) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Positioned(
          left: _calculateScreenX(overlay.position),
          top: _calculateScreenY(overlay.position),
          child: Transform.scale(
            scale: overlay.scale * (data.instruction.priority == ARPriority.high ? _pulseAnimation.value : 1.0),
            child: Transform.rotate(
              angle: overlay.rotation * math.pi / 180,
              child: Opacity(
                opacity: overlay.opacity,
                child: Container(
                  width: overlay.size.width,
                  height: overlay.size.height,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(
                      (overlay.color.alpha * 255).toInt(),
                      overlay.color.red,
                      overlay.color.green,
                      overlay.color.blue,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromARGB(
                          (overlay.color.alpha * 127).toInt(),
                          overlay.color.red,
                          overlay.color.green,
                          overlay.color.blue,
                        ),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _buildOverlayContent(overlay),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildOverlayContent(AROverlay overlay) {
    switch (overlay.type) {
      case AROverlayType.arrow:
        return const Icon(
          Icons.navigation,
          color: Colors.white,
          size: 30,
        );
      case AROverlayType.text:
        return Center(
          child: Text(
            overlay.text ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
      case AROverlayType.icon:
        return Icon(
          Icons.place,
          color: Colors.white,
          size: overlay.size.width * 0.6,
        );
      case AROverlayType.line:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.straighten,
              color: Colors.white,
              size: 20,
            ),
            Text(
              overlay.text ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      case AROverlayType.circle:
      case AROverlayType.rectangle:
      case AROverlayType.path:
      case AROverlayType.landmark:
      case AROverlayType.instruction:
      case AROverlayType.warning:
        return Icon(
          Icons.info,
          color: Colors.white,
          size: overlay.size.width * 0.6,
        );
    }
  }
  
  Widget _buildARInstructions() {
    if (_arData.isEmpty) return const SizedBox.shrink();
    
    final primaryInstruction = _arData.first;
    
    return Positioned(
      top: 120,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.cyan.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: Icon(
                              _getInstructionIcon(primaryInstruction.instruction.direction),
                              color: Colors.cyan,
                              size: 30,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primaryInstruction.instruction.arabicText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _formatDistance(primaryInstruction.distance),
                              style: TextStyle(
                                color: Colors.cyan.shade300,
                                fontSize: 14,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (primaryInstruction.instruction.streetName?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    Text(
                      primaryInstruction.instruction.streetName ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildARLandmarks() {
    return Stack(
      children: _landmarks.where((landmark) => landmark.visibility.isVisible)
          .map((landmark) => _buildLandmarkOverlay(landmark))
          .toList(),
    );
  }
  
  Widget _buildLandmarkOverlay(ARLandmark landmark) {
    return Positioned(
      left: _calculateLandmarkX(landmark),
      top: _calculateLandmarkY(landmark),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value * landmark.visibility.opacity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getLandmarkIcon(landmark.type),
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    landmark.arabicName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildARControls() {
    return Positioned(
      top: 50,
      right: 20,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.close,
            onTap: widget.onToggle,
            color: Colors.red,
          ),
          const SizedBox(height: 10),
          _buildControlButton(
            icon: Icons.tune,
            onTap: widget.onCalibrate,
            color: Colors.blue,
          ),
          const SizedBox(height: 10),
          _buildControlButton(
            icon: _isCalibrated ? Icons.check_circle : Icons.warning,
            onTap: () => _showCalibrationDialog(),
            color: _isCalibrated ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCalibrationPrompt() {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade600,
                    Colors.orange.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.explore,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'يحتاج الواقع المعزز إلى معايرة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showCalibrationPrompt = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'لاحقاً',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _performCalibration();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.orange.shade600,
                          ),
                          child: const Text(
                            'معايرة الآن',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Helper methods
  double _calculateScreenX(ARPosition position) {
    // Simplified 3D to 2D projection
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth / 2) + (position.x * 2);
  }
  
  double _calculateScreenY(ARPosition position) {
    // Simplified 3D to 2D projection
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight / 2) + (position.y * 2);
  }
  
  double _calculateLandmarkX(ARLandmark landmark) {
    // Calculate landmark position based on bearing and distance
    final screenWidth = MediaQuery.of(context).size.width;
    final bearing = landmark.bearing;
    final normalizedBearing = (bearing - _arService.currentHeading + 360) % 360;
    
    if (normalizedBearing > 180) {
      return -100; // Off screen left
    } else if (normalizedBearing < -180) {
      return screenWidth + 100; // Off screen right
    }
    
    return (screenWidth / 2) + (normalizedBearing * 2);
  }
  
  double _calculateLandmarkY(ARLandmark landmark) {
    // Calculate landmark Y position based on distance
    final screenHeight = MediaQuery.of(context).size.height;
    final distanceFactor = math.min(1.0, landmark.distance / 1000);
    return screenHeight * 0.3 + (distanceFactor * 100);
  }
  
  IconData _getInstructionIcon(ARDirection direction) {
    switch (direction) {
      case ARDirection.left:
        return Icons.turn_left;
      case ARDirection.right:
        return Icons.turn_right;
      case ARDirection.straight:
        return Icons.straight;
      case ARDirection.uTurn:
        return Icons.u_turn_left;
      default:
        return Icons.navigation;
    }
  }
  
  IconData _getLandmarkIcon(ARLandmarkType type) {
    switch (type) {
      case ARLandmarkType.monument:
        return Icons.account_balance;
      case ARLandmarkType.mall:
        return Icons.shopping_cart;
      case ARLandmarkType.hospital:
        return Icons.local_hospital;
      case ARLandmarkType.school:
        return Icons.school;
      case ARLandmarkType.mosque:
        return Icons.mosque;
      case ARLandmarkType.restaurant:
        return Icons.restaurant;
      case ARLandmarkType.gasStation:
        return Icons.local_gas_station;

      case ARLandmarkType.park:
        return Icons.park;
      default:
        return Icons.place;
    }
  }
  
  String _formatDistance(double distance) {
    if (distance < 100) {
      return '${distance.toInt()} متر';
    } else if (distance < 1000) {
      return '${(distance / 100).round() * 100} متر';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} كم';
    }
  }
  
  void _showCalibrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'معايرة الواقع المعزز',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'لضمان دقة التوجيهات، يرجى معايرة البوصلة والمستشعرات',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 20),
            if (_calibration != null) ...[
              Text(
                'آخر معايرة: ${_formatCalibrationTime(_calibration!.lastCalibration)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'دقة المعايرة: ${(_calibration!.accuracy * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performCalibration();
            },
            child: const Text(
              'معايرة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performCalibration() async {
    // Show calibration progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'جاري المعايرة...',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ],
        ),
      ),
    );
    
    // Perform calibration
    await _arService.calibrateAR();
    
    // Close progress dialog
    if (mounted) {
      Navigator.of(context).pop();
      
      setState(() {
        _showCalibrationPrompt = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تمت المعايرة بنجاح',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  String _formatCalibrationTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    
    _arDataSubscription?.cancel();
    _calibrationSubscription?.cancel();
    _landmarksSubscription?.cancel();
    _arModeSubscription?.cancel();
    
    super.dispose();
  }
}

class ARGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    const gridSize = 50.0;
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Draw center crosshair
    final centerPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const crosshairSize = 20.0;
    
    canvas.drawLine(
      Offset(centerX - crosshairSize, centerY),
      Offset(centerX + crosshairSize, centerY),
      centerPaint,
    );
    
    canvas.drawLine(
      Offset(centerX, centerY - crosshairSize),
      Offset(centerX, centerY + crosshairSize),
      centerPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}