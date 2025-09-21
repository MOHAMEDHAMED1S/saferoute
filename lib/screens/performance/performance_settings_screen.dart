import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/performance_service.dart';
import '../../models/performance_model.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/animated_button.dart';

class PerformanceSettingsScreen extends StatefulWidget {
  const PerformanceSettingsScreen({super.key});

  @override
  State<PerformanceSettingsScreen> createState() => _PerformanceSettingsScreenState();
}

class _PerformanceSettingsScreenState extends State<PerformanceSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final PerformanceService _performanceService = PerformanceService.instance;
  
  // Settings state
  bool _enableMemoryOptimization = true;
  bool _enableBatteryOptimization = true;
  bool _enablePerformanceAlerts = true;
  bool _enableAutoOptimization = true;
  bool _enableDetailedLogging = false;
  
  double _memoryThreshold = 80.0;
  double _batteryThreshold = 20.0;
  double _cpuThreshold = 70.0;
  
  int _optimizationInterval = 5; // minutes
  int _monitoringInterval = 5; // seconds
  
  // Current metrics
  PerformanceMetrics? _currentMetrics;
  List<PerformanceAlert> _activeAlerts = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
    _subscribeToPerformanceData();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
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
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }
  
  void _loadSettings() async {
    // Load settings from performance service
    // This would typically come from the service's current settings
    setState(() {
      // Default values - in real implementation, load from service
    });
  }
  
  void _subscribeToPerformanceData() {
    _performanceService.metricsStream.listen((metrics) {
      if (mounted) {
        setState(() {
          _currentMetrics = metrics;
        });
      }
    });
    
    _performanceService.alertsStream.listen((alerts) {
      if (mounted) {
        setState(() {
          _activeAlerts = alerts;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'إعدادات الأداء',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshMetrics,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentStatusCard(),
                const SizedBox(height: 20),
                _buildOptimizationSettings(),
                const SizedBox(height: 20),
                _buildThresholdSettings(),
                const SizedBox(height: 20),
                _buildMonitoringSettings(),
                const SizedBox(height: 20),
                _buildAdvancedSettings(),
                const SizedBox(height: 20),
                _buildActionButtons(),
                const SizedBox(height: 20),
                _buildActiveAlerts(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCurrentStatusCard() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.dashboard,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'الحالة الحالية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_currentMetrics != null) ...[
              _buildMetricRow(
                'استخدام الذاكرة',
                '${_currentMetrics!.memoryUsage.usagePercentage.toStringAsFixed(1)}%',
                _currentMetrics!.memoryUsage.usagePercentage,
                _memoryThreshold,
                Icons.memory,
                Colors.purple,
              ),
              const SizedBox(height: 12),
              _buildMetricRow(
                'مستوى البطارية',
                '${_currentMetrics!.batteryInfo.level.toStringAsFixed(0)}%',
                _currentMetrics!.batteryInfo.level,
                100 - _batteryThreshold,
                Icons.battery_full,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildMetricRow(
                'استخدام المعالج',
                '${_currentMetrics!.cpuUsage.toStringAsFixed(1)}%',
                _currentMetrics!.cpuUsage,
                _cpuThreshold,
                Icons.speed,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildMetricRow(
                'معدل الإطارات',
                '${_currentMetrics!.frameRate.toStringAsFixed(0)} FPS',
                _currentMetrics!.frameRate,
                60.0,
                Icons.videocam,
                Colors.cyan,
              ),
            ] else ...[
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricRow(
    String label,
    String value,
    double current,
    double max,
    IconData icon,
    Color color,
  ) {
    final percentage = (current / max).clamp(0.0, 1.0);
    final isWarning = current > max * 0.8;
    
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: isWarning ? Colors.orange : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.white.withAlpha(25),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isWarning ? Colors.orange : color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildOptimizationSettings() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'إعدادات التحسين',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'تحسين الذاكرة التلقائي',
              'تنظيف الذاكرة وإزالة البيانات غير المستخدمة',
              _enableMemoryOptimization,
              (value) => setState(() => _enableMemoryOptimization = value),
              Icons.memory,
            ),
            _buildSwitchTile(
              'تحسين البطارية التلقائي',
              'تقليل استهلاك البطارية وتحسين الأداء',
              _enableBatteryOptimization,
              (value) => setState(() => _enableBatteryOptimization = value),
              Icons.battery_saver,
            ),
            _buildSwitchTile(
              'التحسين التلقائي',
              'تطبيق التحسينات بشكل دوري تلقائياً',
              _enableAutoOptimization,
              (value) => setState(() => _enableAutoOptimization = value),
              Icons.auto_fix_high,
            ),
            _buildSwitchTile(
              'تنبيهات الأداء',
              'إظهار تنبيهات عند وجود مشاكل في الأداء',
              _enablePerformanceAlerts,
              (value) => setState(() => _enablePerformanceAlerts = value),
              Icons.notifications,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThresholdSettings() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'حدود التنبيهات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSliderTile(
              'حد تنبيه الذاكرة',
              'إظهار تنبيه عند تجاوز هذه النسبة',
              _memoryThreshold,
              0.0,
              100.0,
              '%',
              (value) => setState(() => _memoryThreshold = value),
              Icons.memory,
              Colors.purple,
            ),
            _buildSliderTile(
              'حد تنبيه البطارية',
              'إظهار تنبيه عند انخفاض البطارية لهذا المستوى',
              _batteryThreshold,
              5.0,
              50.0,
              '%',
              (value) => setState(() => _batteryThreshold = value),
              Icons.battery_alert,
              Colors.red,
            ),
            _buildSliderTile(
              'حد تنبيه المعالج',
              'إظهار تنبيه عند تجاوز استخدام المعالج لهذه النسبة',
              _cpuThreshold,
              50.0,
              95.0,
              '%',
              (value) => setState(() => _cpuThreshold = value),
              Icons.speed,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMonitoringSettings() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.monitor,
                    color: Colors.cyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'إعدادات المراقبة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdownTile(
              'فترة التحسين التلقائي',
              'كم مرة يتم تطبيق التحسينات التلقائية',
              _optimizationInterval,
              {
                1: 'كل دقيقة',
                5: 'كل 5 دقائق',
                10: 'كل 10 دقائق',
                15: 'كل 15 دقيقة',
                30: 'كل 30 دقيقة',
                60: 'كل ساعة',
              },
              (value) => setState(() => _optimizationInterval = value!),
              Icons.schedule,
            ),
            _buildDropdownTile(
              'فترة مراقبة الأداء',
              'كم مرة يتم فحص الأداء',
              _monitoringInterval,
              {
                1: 'كل ثانية',
                5: 'كل 5 ثوان',
                10: 'كل 10 ثوان',
                30: 'كل 30 ثانية',
                60: 'كل دقيقة',
              },
              (value) => setState(() => _monitoringInterval = value!),
              Icons.timer,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAdvancedSettings() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings_applications,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'الإعدادات المتقدمة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'تسجيل مفصل',
              'حفظ سجل مفصل لجميع عمليات الأداء (يستهلك مساحة إضافية)',
              _enableDetailedLogging,
              (value) => setState(() => _enableDetailedLogging = value),
              Icons.description,
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              'مسح ذاكرة التخزين المؤقت',
              'حذف جميع البيانات المؤقتة المحفوظة',
              Icons.delete_sweep,
              Colors.orange,
              _clearCache,
            ),
            _buildActionTile(
              'إعادة تعيين الإعدادات',
              'استعادة جميع الإعدادات إلى القيم الافتراضية',
              Icons.restore,
              Colors.red,
              _resetSettings,
            ),
            _buildActionTile(
              'تصدير تقرير الأداء',
              'إنشاء تقرير مفصل عن أداء التطبيق',
              Icons.file_download,
              Colors.blue,
              _exportReport,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AnimatedButton(
            text: 'تحسين الآن',
            onPressed: _optimizeNow,
            icon: Icons.flash_on,
            backgroundColor: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedButton(
            text: 'حفظ الإعدادات',
            onPressed: _saveSettings,
            icon: Icons.save,
            backgroundColor: const Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActiveAlerts() {
    if (_activeAlerts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'التنبيهات النشطة (${_activeAlerts.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._activeAlerts.map((alert) => _buildAlertCard(alert)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAlertCard(PerformanceAlert alert) {
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertColor.withAlpha(25),
        border: Border.all(color: alertColor.withAlpha(76)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: alertColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    color: alertColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => _dismissAlert(alert.id),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          if (alert.suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'اقتراحات:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...alert.suggestions.map((suggestion) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                '• $suggestion',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.blue,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    String unit,
    ValueChanged<double> onChanged,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)}$unit',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withAlpha(76),
              thumbColor: color,
              overlayColor: color.withAlpha(51),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / 5).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDropdownTile<T>(
    String title,
    String subtitle,
    T value,
    Map<T, String> options,
    ValueChanged<T?> onChanged,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withAlpha(51)),
            ),
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: const Color(0xFF1A1F3A),
              style: const TextStyle(color: Colors.white),
              items: options.entries.map((entry) {
                return DropdownMenuItem<T>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  void _refreshMetrics() async {
    HapticFeedback.lightImpact();
    // Trigger metrics refresh
    // This would typically call the performance service to update metrics
  }
  
  void _optimizeNow() async {
    HapticFeedback.mediumImpact();
    
    try {
      await _performanceService.optimizeNow();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تطبيق التحسينات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تطبيق التحسينات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _saveSettings() async {
    HapticFeedback.lightImpact();
    
    try {
      await _performanceService.updateSettings(
        enableMemoryOptimization: _enableMemoryOptimization,
        enableBatteryOptimization: _enableBatteryOptimization,
        enablePerformanceAlerts: _enablePerformanceAlerts,
        memoryThreshold: _memoryThreshold,
        batteryThreshold: _batteryThreshold,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ الإعدادات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _clearCache() async {
    HapticFeedback.mediumImpact();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'مسح ذاكرة التخزين المؤقت',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في مسح جميع البيانات المؤقتة؟ قد يؤثر هذا على سرعة التطبيق مؤقتاً.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('مسح', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _performanceService.clearAllCache();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم مسح ذاكرة التخزين المؤقت بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في مسح ذاكرة التخزين المؤقت: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  void _resetSettings() async {
    HapticFeedback.mediumImpact();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'إعادة تعيين الإعدادات',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في إعادة تعيين جميع إعدادات الأداء إلى القيم الافتراضية؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إعادة تعيين', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _enableMemoryOptimization = true;
        _enableBatteryOptimization = true;
        _enablePerformanceAlerts = true;
        _enableAutoOptimization = true;
        _enableDetailedLogging = false;
        _memoryThreshold = 80.0;
        _batteryThreshold = 20.0;
        _cpuThreshold = 70.0;
        _optimizationInterval = 5;
        _monitoringInterval = 5;
      });
      
      await _saveSettings();
    }
  }
  
  void _exportReport() async {
    HapticFeedback.lightImpact();
    
    try {
      final report = _performanceService.generateReport();
      
      // In a real implementation, you would export this to a file
      // For now, we'll show a dialog with the report summary
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F3A),
            title: const Text(
              'تقرير الأداء',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الفترة: ${report.durationFormatted}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'متوسط استخدام الذاكرة: ${report.averageMemoryUsage.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'متوسط مستوى البطارية: ${report.averageBatteryLevel.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'إجمالي التنبيهات: ${report.totalAlerts}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'التوصيات:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...report.recommendations.map((rec) => Text(
                    '• $rec',
                    style: const TextStyle(color: Colors.white70),
                  )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء التقرير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _dismissAlert(String alertId) {
    HapticFeedback.lightImpact();
    _performanceService.dismissAlert(alertId);
  }
}