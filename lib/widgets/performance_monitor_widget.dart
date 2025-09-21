import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/performance_service.dart';
import '../models/performance_model.dart';
import 'glass_container.dart';
import 'animated_button.dart';

class PerformanceMonitorWidget extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onToggle;
  final bool showDetailedView;
  
  const PerformanceMonitorWidget({
    super.key,
    this.isExpanded = false,
    this.onToggle,
    this.showDetailedView = false,
  });

  @override
  State<PerformanceMonitorWidget> createState() => _PerformanceMonitorWidgetState();
}

class _PerformanceMonitorWidgetState extends State<PerformanceMonitorWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _expandController;
  late Animation<double> _pulseAnimation;

  late Animation<double> _expandAnimation;
  
  final PerformanceService _performanceService = PerformanceService.instance;
  
  // Subscriptions
  StreamSubscription<PerformanceMetrics>? _metricsSubscription;
  StreamSubscription<List<PerformanceAlert>>? _alertsSubscription;
  
  // State
  PerformanceMetrics? _currentMetrics;
  List<PerformanceAlert> _activeAlerts = [];
  bool _isMonitoring = false;
  
  // Chart data
  final List<double> _memoryHistory = [];
  final List<double> _cpuHistory = [];
  final List<double> _batteryHistory = [];
  final List<double> _frameRateHistory = [];
  static const int _maxHistoryLength = 30;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePerformanceService();
    _subscribeToPerformanceData();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _expandController = AnimationController(
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
    

    
    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    
    if (widget.isExpanded) {
      _expandController.forward();
    }
  }
  
  void _initializePerformanceService() async {
    if (!_performanceService.isInitialized) {
      await _performanceService.initialize();
    }
    
    if (!_performanceService.isMonitoring) {
      await _performanceService.startMonitoring();
    }
    
    setState(() {
      _isMonitoring = _performanceService.isMonitoring;
    });
  }
  
  void _subscribeToPerformanceData() {
    _metricsSubscription = _performanceService.metricsStream.listen((metrics) {
      if (mounted) {
        setState(() {
          _currentMetrics = metrics;
          _updateHistory(metrics);
        });
      }
    });
    
    _alertsSubscription = _performanceService.alertsStream.listen((alerts) {
      if (mounted) {
        setState(() {
          _activeAlerts = alerts;
        });
      }
    });
  }
  
  void _updateHistory(PerformanceMetrics metrics) {
    _memoryHistory.add(metrics.memoryUsage.usagePercentage);
    _cpuHistory.add(metrics.cpuUsage);
    _batteryHistory.add(metrics.batteryInfo.level);
    _frameRateHistory.add(metrics.frameRate);
    
    if (_memoryHistory.length > _maxHistoryLength) {
      _memoryHistory.removeAt(0);
      _cpuHistory.removeAt(0);
      _batteryHistory.removeAt(0);
      _frameRateHistory.removeAt(0);
    }
  }
  
  @override
  void didUpdateWidget(PerformanceMonitorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _expandController.dispose();
    _metricsSubscription?.cancel();
    _alertsSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              if (_expandAnimation.value > 0) ...[
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: _buildExpandedContent(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildHeader() {
    final hasAlerts = _activeAlerts.isNotEmpty;
    final criticalAlerts = _activeAlerts.where((a) => a.severity == AlertSeverity.critical).length;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Status indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: hasAlerts ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor().withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          
          // Title and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مراقب الأداء',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Quick metrics
          if (_currentMetrics != null && !widget.isExpanded) ...[
            _buildQuickMetric(
              Icons.memory,
              '${_currentMetrics!.memoryUsage.usagePercentage.toStringAsFixed(0)}%',
              Colors.purple,
            ),
            const SizedBox(width: 8),
            _buildQuickMetric(
              Icons.battery_full,
              '${_currentMetrics!.batteryInfo.level.toStringAsFixed(0)}%',
              Colors.green,
            ),
            const SizedBox(width: 8),
          ],
          
          // Alert badge
          if (hasAlerts) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: criticalAlerts > 0 ? Colors.red : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_activeAlerts.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Expand/collapse button
          if (widget.onToggle != null)
            GestureDetector(
              onTap: widget.onToggle!,
              child: AnimatedRotation(
                turns: widget.isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(
                  Icons.expand_more,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildQuickMetric(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpandedContent() {
    if (_currentMetrics == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          
          if (widget.showDetailedView) ...[
            _buildDetailedMetrics(),
            const SizedBox(height: 16),
            _buildPerformanceCharts(),
            const SizedBox(height: 16),
          ] else ...[
            _buildCompactMetrics(),
            const SizedBox(height: 16),
          ],
          
          if (_activeAlerts.isNotEmpty) ...[
            _buildAlertsSection(),
            const SizedBox(height: 16),
          ],
          
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildDetailedMetrics() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'الذاكرة',
                '${_currentMetrics!.memoryUsage.usagePercentage.toStringAsFixed(1)}%',
                _currentMetrics!.memoryUsage.usagePercentage / 100,
                Icons.memory,
                Colors.purple,
                subtitle: _currentMetrics!.memoryUsage.appMemoryFormatted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'البطارية',
                '${_currentMetrics!.batteryInfo.level.toStringAsFixed(0)}%',
                _currentMetrics!.batteryInfo.level / 100,
                Icons.battery_full,
                Colors.green,
                subtitle: _currentMetrics!.batteryInfo.chargingStateArabic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'المعالج',
                '${_currentMetrics!.cpuUsage.toStringAsFixed(1)}%',
                _currentMetrics!.cpuUsage / 100,
                Icons.speed,
                Colors.orange,
                subtitle: 'متوسط الاستخدام',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'الإطارات',
                '${_currentMetrics!.frameRate.toStringAsFixed(0)} FPS',
                _currentMetrics!.frameRate / 60,
                Icons.videocam,
                Colors.cyan,
                subtitle: 'معدل الرسم',
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCompactMetrics() {
    return Column(
      children: [
        _buildCompactMetricRow(
          'استخدام الذاكرة',
          '${_currentMetrics!.memoryUsage.usagePercentage.toStringAsFixed(1)}%',
          _currentMetrics!.memoryUsage.usagePercentage / 100,
          Icons.memory,
          Colors.purple,
        ),
        const SizedBox(height: 8),
        _buildCompactMetricRow(
          'مستوى البطارية',
          '${_currentMetrics!.batteryInfo.level.toStringAsFixed(0)}%',
          _currentMetrics!.batteryInfo.level / 100,
          Icons.battery_full,
          Colors.green,
        ),
        const SizedBox(height: 8),
        _buildCompactMetricRow(
          'استخدام المعالج',
          '${_currentMetrics!.cpuUsage.toStringAsFixed(1)}%',
          _currentMetrics!.cpuUsage / 100,
          Icons.speed,
          Colors.orange,
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(
    String title,
    String value,
    double progress,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
          ],
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactMetricRow(
    String title,
    String value,
    double progress,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPerformanceCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الرسوم البيانية',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: Row(
            children: [
              Expanded(
                child: _buildMiniChart(
                  'الذاكرة',
                  _memoryHistory,
                  Colors.purple,
                  '%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniChart(
                  'المعالج',
                  _cpuHistory,
                  Colors.orange,
                  '%',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMiniChart(
    String title,
    List<double> data,
    Color color,
    String unit,
  ) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'لا توجد بيانات',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final currentValue = data.last;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${currentValue.toStringAsFixed(0)}$unit',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: MiniChartPainter(
                data: data,
                color: color,
                maxValue: maxValue,
                minValue: minValue,
              ),
              size: const Size.fromHeight(60),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Text(
              'التنبيهات النشطة (${_activeAlerts.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._activeAlerts.take(3).map((alert) => _buildAlertItem(alert)),
        if (_activeAlerts.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'و ${_activeAlerts.length - 3} تنبيهات أخرى...',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildAlertItem(PerformanceAlert alert) {
    Color alertColor;
    switch (alert.severity) {
      case AlertSeverity.critical:
        alertColor = Colors.red;
        break;
      case AlertSeverity.warning:
        alertColor = Colors.orange;
        break;
      case AlertSeverity.info:
        alertColor = Colors.blue;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: alertColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: alertColor, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alert.title,
              style: TextStyle(
                color: alertColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AnimatedButton(
            text: 'تحسين',
            onPressed: _optimizeNow,
            icon: Icons.flash_on,
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
            ),
            borderRadius: 8,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedButton(
            text: 'إعدادات',
            onPressed: _openSettings,
            icon: Icons.settings,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            borderRadius: 8,
            isOutlined: true,
          ),
        ),
      ],
    );
  }
  
  Color _getStatusColor() {
    if (_activeAlerts.any((a) => a.severity == AlertSeverity.critical)) {
      return Colors.red;
    } else if (_activeAlerts.any((a) => a.severity == AlertSeverity.warning)) {
      return Colors.orange;
    } else if (_isMonitoring) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }
  
  String _getStatusText() {
    if (!_isMonitoring) {
      return 'غير نشط';
    } else if (_activeAlerts.any((a) => a.severity == AlertSeverity.critical)) {
      return 'تنبيهات حرجة';
    } else if (_activeAlerts.any((a) => a.severity == AlertSeverity.warning)) {
      return 'تحذيرات';
    } else {
      return 'يعمل بشكل طبيعي';
    }
  }
  
  void _optimizeNow() async {
    try {
      await _performanceService.optimizeNow();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تطبيق التحسينات بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تطبيق التحسينات: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  void _openSettings() {
    Navigator.pushNamed(context, '/performance-settings');
  }
}

// Custom painter for mini charts
class MiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double maxValue;
  final double minValue;
  
  MiniChartPainter({
    required this.data,
    required this.color,
    required this.maxValue,
    required this.minValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final fillPath = Path();
    
    final stepX = size.width / (data.length - 1);
    final range = maxValue - minValue;
    
    // Start from bottom left
    fillPath.moveTo(0, size.height);
    
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    // Complete the fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    
    // Draw fill first, then stroke
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}