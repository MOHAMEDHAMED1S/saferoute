import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/warning_model.dart';
import '../services/warning_service.dart';

class WarningOverlay extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onDismissAll;
  
  const WarningOverlay({
    Key? key,
    required this.isDarkMode,
    this.onDismissAll,
  }) : super(key: key);
  
  @override
  State<WarningOverlay> createState() => _WarningOverlayState();
}

class _WarningOverlayState extends State<WarningOverlay>
    with TickerProviderStateMixin {
  final WarningService _warningService = WarningService();
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<DrivingWarning> _warnings = [];
  Timer? _autoHideTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _listenToWarnings();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }
  
  void _listenToWarnings() {
    _warningService.warningsStream.listen((warnings) {
      setState(() {
        _warnings = warnings;
      });
      
      if (warnings.isNotEmpty) {
        _slideController.forward();
        _startAutoHideTimer();
        
        // Vibrate for critical warnings
        final criticalWarnings = warnings
            .where((w) => w.severity == WarningSeverity.critical)
            .toList();
        if (criticalWarnings.isNotEmpty) {
          HapticFeedback.heavyImpact();
        }
      } else {
        _slideController.reverse();
      }
    });
  }
  
  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        _slideController.reverse();
      }
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_warnings.isEmpty) return const SizedBox.shrink();
    
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._warnings.take(3).map((warning) => _buildWarningCard(warning)),
            if (_warnings.length > 3) _buildMoreWarningsIndicator(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWarningCard(DrivingWarning warning) {
    final warningService = WarningService();
    final color = warningService.getWarningColor(warning.type);
    final icon = warningService.getWarningIcon(warning.type);
    final severityColor = warningService.getSeverityColor(warning.severity);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.grey[900]?.withAlpha(242)
            : Colors.white.withAlpha(242),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: severityColor,
          width: warning.severity == WarningSeverity.critical ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: severityColor.withAlpha(76),
            blurRadius: warning.severity == WarningSeverity.critical ? 12 : 8,
            spreadRadius: warning.severity == WarningSeverity.critical ? 2 : 1,
          ),
        ],
      ),
      child: warning.severity == WarningSeverity.critical
          ? AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: _buildWarningContent(warning, color, icon),
                );
              },
            )
          : _buildWarningContent(warning, color, icon),
    );
  }
  
  Widget _buildWarningContent(DrivingWarning warning, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Warning icon with colored background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // Warning content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warning.message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDistance(warning.distance),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    _buildSeverityBadge(warning.severity),
                  ],
                ),
              ],
            ),
          ),
          
          // Dismiss button
          IconButton(
            onPressed: () => _dismissWarning(warning.id),
            icon: Icon(
              Icons.close,
              size: 20,
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSeverityBadge(WarningSeverity severity) {
    String text;
    Color color;
    
    switch (severity) {
      case WarningSeverity.critical:
        text = 'حرج';
        color = Colors.red;
        break;
      case WarningSeverity.high:
        text = 'عالي';
        color = Colors.orange;
        break;
      case WarningSeverity.medium:
        text = 'متوسط';
        color = Colors.yellow[700]!;
        break;
      case WarningSeverity.low:
      default:
        text = 'منخفض';
        color = Colors.blue;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
  
  Widget _buildMoreWarningsIndicator() {
    final remainingCount = _warnings.length - 3;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.grey[800]?.withAlpha(229)
            : Colors.grey[200]?.withAlpha(229),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.more_horiz,
            size: 16,
            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            '+$remainingCount تحذيرات أخرى',
            style: TextStyle(
              fontSize: 12,
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onDismissAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'إخفاء الكل',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDistance(int distance) {
    if (distance < 1000) {
      return '$distanceم';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} كم';
    }
  }
  
  void _dismissWarning(String warningId) {
    _warningService.dismissWarning(warningId);
    HapticFeedback.lightImpact();
  }
}

// Warning utilities
class WarningUtils {
  static Color getWarningColor(WarningType type) {
    switch (type) {
      case WarningType.accident:
        return Colors.red;
      case WarningType.traffic:
        return Colors.orange;
      case WarningType.roadwork:
        return Colors.yellow;
      case WarningType.police:
        return Colors.blue;
      case WarningType.speedCamera:
        return Colors.purple;
      case WarningType.speedLimit:
        return Colors.red;
      case WarningType.general:
        return Colors.green;
    }
  }
  
  static IconData getWarningIcon(WarningType type) {
    switch (type) {
      case WarningType.accident:
        return Icons.car_crash;
      case WarningType.traffic:
        return Icons.traffic;
      case WarningType.roadwork:
        return Icons.construction;
      case WarningType.police:
        return Icons.local_police;
      case WarningType.speedCamera:
        return Icons.camera_alt;
      case WarningType.speedLimit:
        return Icons.speed;
      case WarningType.general:
        return Icons.warning;
    }
  }
  

}