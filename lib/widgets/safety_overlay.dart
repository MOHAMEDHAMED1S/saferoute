import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/safety_model.dart';
import '../services/safety_service.dart';
import '../theme/liquid_glass_theme.dart';

class SafetyOverlay extends StatefulWidget {
  final SafetyService safetyService;
  final VoidCallback? onEmergencyCancel;
  final VoidCallback? onUserInteraction;

  const SafetyOverlay({
    Key? key,
    required this.safetyService,
    this.onEmergencyCancel,
    this.onUserInteraction,
  }) : super(key: key);

  @override
  State<SafetyOverlay> createState() => _SafetyOverlayState();
}

class _SafetyOverlayState extends State<SafetyOverlay>
    with TickerProviderStateMixin {
  late AnimationController _speedWarningController;
  late AnimationController _fatigueWarningController;
  late AnimationController _emergencyController;
  late AnimationController _laneWarningController;

  late Animation<double> _speedWarningAnimation;
  late Animation<double> _fatigueWarningAnimation;
  late Animation<double> _emergencyAnimation;
  late Animation<double> _laneWarningAnimation;

  StreamSubscription<SpeedWarning>? _speedWarningSubscription;
  StreamSubscription<FatigueWarning>? _fatigueWarningSubscription;
  StreamSubscription<EmergencyEvent>? _emergencySubscription;
  StreamSubscription<LaneWarning>? _laneWarningSubscription;

  SpeedWarning? _currentSpeedWarning;
  FatigueWarning? _currentFatigueWarning;
  EmergencyEvent? _currentEmergencyEvent;
  LaneWarning? _currentLaneWarning;

  Timer? _speedWarningTimer;
  Timer? _fatigueWarningTimer;
  Timer? _laneWarningTimer;
  Timer? _emergencyCountdownTimer;
  int _emergencyCountdown = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _subscribeToWarnings();
  }

  void _initializeAnimations() {
    _speedWarningController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fatigueWarningController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _emergencyController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _laneWarningController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _speedWarningAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _speedWarningController,
      curve: Curves.elasticOut,
    ));

    _fatigueWarningAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fatigueWarningController,
      curve: Curves.bounceOut,
    ));

    _emergencyAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _emergencyController,
      curve: Curves.easeInOut,
    ));

    _laneWarningAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _laneWarningController,
      curve: Curves.easeOut,
    ));
  }

  void _subscribeToWarnings() {
    _speedWarningSubscription = widget.safetyService.speedWarnings.listen(
      (warning) => _showSpeedWarning(warning),
    );

    _fatigueWarningSubscription = widget.safetyService.fatigueWarnings.listen(
      (warning) => _showFatigueWarning(warning),
    );

    _emergencySubscription = widget.safetyService.emergencyEvents.listen(
      (event) => _handleEmergencyEvent(event),
    );

    _laneWarningSubscription = widget.safetyService.laneWarnings.listen(
      (warning) => _showLaneWarning(warning),
    );
  }

  void _showSpeedWarning(SpeedWarning warning) {
    setState(() {
      _currentSpeedWarning = warning;
    });

    _speedWarningController.forward();

    // Auto-hide after duration based on severity
    final duration = _getSpeedWarningDuration(warning.violationType);
    _speedWarningTimer?.cancel();
    _speedWarningTimer = Timer(duration, () {
      _hideSpeedWarning();
    });

    // Trigger haptic feedback
    _triggerHapticFeedback(warning.violationType);
  }

  void _showFatigueWarning(FatigueWarning warning) {
    setState(() {
      _currentFatigueWarning = warning;
    });

    _fatigueWarningController.forward();

    // Auto-hide after 10 seconds
    _fatigueWarningTimer?.cancel();
    _fatigueWarningTimer = Timer(const Duration(seconds: 10), () {
      _hideFatigueWarning();
    });

    HapticFeedback.mediumImpact();
  }

  void _showLaneWarning(LaneWarning warning) {
    setState(() {
      _currentLaneWarning = warning;
    });

    _laneWarningController.forward();

    // Auto-hide after 5 seconds
    _laneWarningTimer?.cancel();
    _laneWarningTimer = Timer(const Duration(seconds: 5), () {
      _hideLaneWarning();
    });
  }

  void _handleEmergencyEvent(EmergencyEvent event) {
    setState(() {
      _currentEmergencyEvent = event;
    });

    switch (event.type) {
      case EmergencyType.crashDetected:
        _startEmergencyCountdown(event.autoCallDelay);
        break;
      case EmergencyType.cancelled:
        _hideEmergencyEvent();
        break;
      case EmergencyType.callMade:
        _emergencyCountdown = 0;
        break;
      case EmergencyType.manualTrigger:
        _startEmergencyCountdown(event.autoCallDelay);
        break;
    }

    _emergencyController.forward();
  }

  void _startEmergencyCountdown(int seconds) {
    _emergencyCountdown = seconds;
    _emergencyCountdownTimer?.cancel();
    _emergencyCountdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        setState(() {
          _emergencyCountdown--;
        });

        if (_emergencyCountdown <= 0) {
          timer.cancel();
        }
      },
    );
  }

  Duration _getSpeedWarningDuration(SpeedViolationType type) {
    switch (type) {
      case SpeedViolationType.minor:
        return const Duration(seconds: 3);
      case SpeedViolationType.moderate:
        return const Duration(seconds: 5);
      case SpeedViolationType.severe:
        return const Duration(seconds: 8);
    }
  }

  void _triggerHapticFeedback(SpeedViolationType type) {
    switch (type) {
      case SpeedViolationType.minor:
        HapticFeedback.lightImpact();
        break;
      case SpeedViolationType.moderate:
        HapticFeedback.mediumImpact();
        break;
      case SpeedViolationType.severe:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  void _hideSpeedWarning() {
    _speedWarningController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentSpeedWarning = null;
        });
      }
    });
  }

  void _hideFatigueWarning() {
    _fatigueWarningController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentFatigueWarning = null;
        });
      }
    });
  }

  void _hideLaneWarning() {
    _laneWarningController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentLaneWarning = null;
        });
      }
    });
  }

  void _hideEmergencyEvent() {
    _emergencyController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentEmergencyEvent = null;
        });
      }
    });
    _emergencyCountdownTimer?.cancel();
  }

  @override
  void dispose() {
    _speedWarningController.dispose();
    _fatigueWarningController.dispose();
    _emergencyController.dispose();
    _laneWarningController.dispose();

    _speedWarningSubscription?.cancel();
    _fatigueWarningSubscription?.cancel();
    _emergencySubscription?.cancel();
    _laneWarningSubscription?.cancel();

    _speedWarningTimer?.cancel();
    _fatigueWarningTimer?.cancel();
    _laneWarningTimer?.cancel();
    _emergencyCountdownTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Speed warning
        if (_currentSpeedWarning != null)
          _buildSpeedWarningCard(),

        // Fatigue warning
        if (_currentFatigueWarning != null)
          _buildFatigueWarningCard(),

        // Lane warning
        if (_currentLaneWarning != null)
          _buildLaneWarningCard(),

        // Emergency overlay
        if (_currentEmergencyEvent != null)
          _buildEmergencyOverlay(),
      ],
    );
  }

  Widget _buildSpeedWarningCard() {
    final warning = _currentSpeedWarning!;
    final color = _getSpeedWarningColor(warning.violationType);

    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _speedWarningAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _speedWarningAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.9),
                    color.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _getSpeedWarningIcon(warning.violationType),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          warning.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'السرعة الحالية: ${warning.currentSpeed.toInt()} كم/س',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.onUserInteraction?.call();
                      _hideSpeedWarning();
                    },
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
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

  Widget _buildFatigueWarningCard() {
    final warning = _currentFatigueWarning!;

    return Positioned(
      top: 140,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _fatigueWarningAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fatigueWarningAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.9),
                    Colors.deepOrange.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'تحذير التعب',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          widget.onUserInteraction?.call();
                          _hideFatigueWarning();
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    warning.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warning.recommendation,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
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

  Widget _buildLaneWarningCard() {
    final warning = _currentLaneWarning!;

    return Positioned(
      bottom: 200,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _laneWarningAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _laneWarningAnimation.value) * 50),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.9),
                    Colors.indigo.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.track_changes,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildEmergencyOverlay() {
    final event = _currentEmergencyEvent!;

    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _emergencyAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _emergencyAnimation.value) * -50),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: 0.95),
                    Colors.red.shade700.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.shade300,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.emergency,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'حالة طوارئ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              event.message,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          widget.safetyService.cancelEmergencyMode();
                          widget.onEmergencyCancel?.call();
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  if (_emergencyCountdown > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الاتصال بالطوارئ خلال $_emergencyCountdown ثانية',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              widget.safetyService.cancelEmergencyMode();
                              widget.onEmergencyCancel?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const Text(
                              'أنا بخير',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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

  Color _getSpeedWarningColor(SpeedViolationType type) {
    switch (type) {
      case SpeedViolationType.minor:
        return Colors.orange;
      case SpeedViolationType.moderate:
        return Colors.deepOrange;
      case SpeedViolationType.severe:
        return Colors.red;
    }
  }

  IconData _getSpeedWarningIcon(SpeedViolationType type) {
    switch (type) {
      case SpeedViolationType.minor:
        return Icons.speed;
      case SpeedViolationType.moderate:
        return Icons.warning;
      case SpeedViolationType.severe:
        return Icons.dangerous;
    }
  }
}