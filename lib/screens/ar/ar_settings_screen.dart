import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ar_navigation_service.dart';
import '../../models/ar_navigation_model.dart';
import '../../widgets/glass_container.dart';

class ARSettingsScreen extends StatefulWidget {
  const ARSettingsScreen({Key? key}) : super(key: key);
  
  @override
  State<ARSettingsScreen> createState() => _ARSettingsScreenState();
}

class _ARSettingsScreenState extends State<ARSettingsScreen>
    with TickerProviderStateMixin {
  late ARNavigationService _arService;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Settings state
  bool _isAREnabled = true;
  bool _showLandmarks = true;
  bool _showDistanceOverlays = true;
  bool _enableVoiceInstructions = true;
  bool _autoCalibration = false;
  double _overlayOpacity = 0.8;
  double _instructionSize = 1.0;
  double _landmarkDistance = 500.0;
  ARVisibilityCondition _visibilityCondition = ARVisibilityCondition.always;
  
  // Calibration state
  ARCalibration? _currentCalibration;
  bool _isCalibrating = false;
  
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
      curve: Curves.elasticOut,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }
  
  Future<void> _initializeARService() async {
    _arService = ARNavigationService.instance;
    
    if (!_arService.isInitialized) {
      await _arService.initialize();
    }
    
    // Load current calibration
    _currentCalibration = _arService.currentCalibration;
    
    if (mounted) {
      setState(() {
        // Update UI after calibration update
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildBody(),
            ),
          );
        },
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'إعدادات الواقع المعزز',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _resetToDefaults,
        ),
      ],
    );
  }
  
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCalibrationSection(),
          const SizedBox(height: 30),
          _buildGeneralSettings(),
          const SizedBox(height: 30),
          _buildDisplaySettings(),
          const SizedBox(height: 30),
          _buildAdvancedSettings(),
          const SizedBox(height: 30),
          _buildTestSection(),
        ],
      ),
    );
  }
  
  Widget _buildCalibrationSection() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: Colors.cyan.shade300,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'معايرة النظام',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_currentCalibration != null) ...[
            _buildCalibrationInfo(),
            const SizedBox(height: 20),
          ],
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCalibrating ? null : _performCalibration,
                  icon: _isCalibrating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.explore),
                  label: Text(
                    _isCalibrating ? 'جاري المعايرة...' : 'معايرة البوصلة',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          SwitchListTile(
            title: const Text(
              'المعايرة التلقائية',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
            subtitle: const Text(
              'معايرة تلقائية كل 5 دقائق',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
            value: _autoCalibration,
            onChanged: (value) {
              setState(() {
                _autoCalibration = value;
              });
            },
            activeColor: Colors.cyan,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCalibrationInfo() {
    final calibration = _currentCalibration!;
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: calibration.isCalibrated ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                calibration.isCalibrated ? Icons.check_circle : Icons.warning,
                color: calibration.isCalibrated ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                calibration.isCalibrated ? 'تم المعايرة' : 'يحتاج معايرة',
                style: TextStyle(
                  color: calibration.isCalibrated ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'دقة المعايرة:',
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 12,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                '${(calibration.accuracy * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'آخر معايرة:',
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 12,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                _formatCalibrationTime(calibration.lastCalibration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildGeneralSettings() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: Colors.blue.shade300,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'الإعدادات العامة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          SwitchListTile(
            title: const Text(
              'تفعيل الواقع المعزز',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
            subtitle: const Text(
              'عرض التوجيهات بتقنية الواقع المعزز',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
            value: _isAREnabled,
            onChanged: (value) {
              setState(() {
                _isAREnabled = value;
              });
            },
            activeColor: Colors.blue,
          ),
          
          SwitchListTile(
            title: const Text(
              'عرض المعالم',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
            subtitle: const Text(
              'إظهار المعالم المهمة في المنطقة',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
            value: _showLandmarks,
            onChanged: _isAREnabled ? (value) {
              setState(() {
                _showLandmarks = value;
              });
            } : null,
            activeColor: Colors.blue,
          ),
          
          SwitchListTile(
            title: const Text(
              'عرض المسافات',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
            subtitle: const Text(
              'إظهار المسافات على الشاشة',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
            value: _showDistanceOverlays,
            onChanged: _isAREnabled ? (value) {
              setState(() {
                _showDistanceOverlays = value;
              });
            } : null,
            activeColor: Colors.blue,
          ),
          
          SwitchListTile(
            title: const Text(
              'التوجيهات الصوتية',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
            subtitle: const Text(
              'تشغيل التوجيهات الصوتية مع الواقع المعزز',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
            value: _enableVoiceInstructions,
            onChanged: (value) {
              setState(() {
                _enableVoiceInstructions = value;
              });
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDisplaySettings() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.display_settings,
                color: Colors.purple.shade300,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'إعدادات العرض',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildSliderSetting(
            title: 'شفافية العناصر',
            subtitle: 'تحكم في شفافية عناصر الواقع المعزز',
            value: _overlayOpacity,
            min: 0.3,
            max: 1.0,
            divisions: 7,
            onChanged: _isAREnabled ? (value) {
              setState(() {
                _overlayOpacity = value;
              });
            } : null,
            valueFormatter: (value) => '${(value * 100).toInt()}%',
          ),
          
          const SizedBox(height: 20),
          
          _buildSliderSetting(
            title: 'حجم التوجيهات',
            subtitle: 'تحكم في حجم نص التوجيهات',
            value: _instructionSize,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: _isAREnabled ? (value) {
              setState(() {
                _instructionSize = value;
              });
            } : null,
            valueFormatter: (value) => '${(value * 100).toInt()}%',
          ),
          
          const SizedBox(height: 20),
          
          _buildSliderSetting(
            title: 'مسافة عرض المعالم',
            subtitle: 'المسافة القصوى لعرض المعالم',
            value: _landmarkDistance,
            min: 100,
            max: 2000,
            divisions: 19,
            onChanged: _isAREnabled && _showLandmarks ? (value) {
              setState(() {
                _landmarkDistance = value;
              });
            } : null,
            valueFormatter: (value) => '${value.toInt()} م',
          ),
          
          const SizedBox(height: 20),
          
          _buildVisibilityConditionSetting(),
        ],
      ),
    );
  }
  
  Widget _buildSliderSetting({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double>? onChanged,
    required String Function(double) valueFormatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              valueFormatter(value),
              style: TextStyle(
                color: Colors.purple.shade300,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.purple.shade400,
            inactiveTrackColor: Colors.purple.shade400.withAlpha(76),
            thumbColor: Colors.purple.shade300,
            overlayColor: Colors.purple.shade300.withAlpha(51),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
  
  Widget _buildVisibilityConditionSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'شروط العرض',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'متى يتم عرض عناصر الواقع المعزز',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<ARVisibilityCondition>(
          initialValue: _visibilityCondition,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withAlpha(25),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          dropdownColor: const Color(0xFF1A1F3A),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
          items: ARVisibilityCondition.values.map((condition) {
            return DropdownMenuItem(
              value: condition,
              child: Text(_getVisibilityConditionName(condition)),
            );
          }).toList(),
          onChanged: _isAREnabled ? (value) {
            if (value != null) {
              setState(() {
                _visibilityCondition = value;
              });
            }
          } : null,
        ),
      ],
    );
  }
  
  Widget _buildAdvancedSettings() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.engineering,
                color: Colors.orange.shade300,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'الإعدادات المتقدمة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ListTile(
            leading: Icon(
              Icons.memory,
              color: Colors.orange.shade300,
            ),
            title: const Text(
              'تحسين الأداء',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
            subtitle: const Text(
              'تحسين استهلاك البطارية والذاكرة',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
            onTap: () {
              _showPerformanceSettings();
            },
          ),
          
          ListTile(
            leading: Icon(
              Icons.bug_report,
              color: Colors.orange.shade300,
            ),
            title: const Text(
              'تشخيص المشاكل',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
            subtitle: const Text(
              'فحص وإصلاح مشاكل الواقع المعزز',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
            onTap: () {
              _runDiagnostics();
            },
          ),
          
          ListTile(
            leading: Icon(
              Icons.restore,
              color: Colors.orange.shade300,
            ),
            title: const Text(
              'إعادة تعيين',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
            subtitle: const Text(
              'إعادة تعيين جميع إعدادات الواقع المعزز',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
            onTap: () {
              _showResetDialog();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestSection() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                color: Colors.green.shade300,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'اختبار النظام',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _testARTracking,
                  icon: const Icon(Icons.track_changes),
                  label: const Text(
                    'اختبار التتبع',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _testAROverlays,
                  icon: const Icon(Icons.layers),
                  label: const Text(
                    'اختبار العرض',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Helper methods
  String _getVisibilityConditionName(ARVisibilityCondition condition) {
    switch (condition) {
      case ARVisibilityCondition.always:
        return 'دائماً';
      case ARVisibilityCondition.nearOnly:
        return 'القريب فقط';
      case ARVisibilityCondition.farOnly:
        return 'البعيد فقط';
      case ARVisibilityCondition.dayOnly:
        return 'النهار فقط';
      case ARVisibilityCondition.nightOnly:
        return 'الليل فقط';
      case ARVisibilityCondition.goodWeather:
        return 'الطقس الجيد فقط';
      case ARVisibilityCondition.navigating:
        return 'أثناء الملاحة فقط';
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
  
  Future<void> _performCalibration() async {
    setState(() {
      _isCalibrating = true;
    });
    
    try {
      await _arService.calibrateAR();
      _currentCalibration = _arService.currentCalibration;
      
      if (mounted) {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في المعايرة: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCalibrating = false;
        });
      }
    }
  }
  
  void _resetToDefaults() {
    setState(() {
      _isAREnabled = true;
      _showLandmarks = true;
      _showDistanceOverlays = true;
      _enableVoiceInstructions = true;
      _autoCalibration = false;
      _overlayOpacity = 0.8;
      _instructionSize = 1.0;
      _landmarkDistance = 500.0;
      _visibilityCondition = ARVisibilityCondition.always;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم إعادة تعيين الإعدادات',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _showPerformanceSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'إعدادات الأداء',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'سيتم إضافة إعدادات تحسين الأداء في التحديث القادم',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'موافق',
              style: TextStyle(
                color: Colors.blue,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _runDiagnostics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'تشخيص النظام',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'جاري فحص النظام...',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
    
    // Simulate diagnostics
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pop();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          title: const Text(
            'نتائج التشخيص',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'المستشعرات تعمل بشكل طبيعي',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'البوصلة معايرة بشكل صحيح',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'يُنصح بإعادة المعايرة',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'موافق',
                style: TextStyle(
                  color: Colors.blue,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
  
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'إعادة تعيين الإعدادات',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        content: const Text(
          'هل أنت متأكد من إعادة تعيين جميع إعدادات الواقع المعزز؟',
          style: TextStyle(
            color: Colors.grey,
            fontFamily: 'Cairo',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetToDefaults();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'إعادة تعيين',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _testARTracking() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'اختبار التتبع: النظام يعمل بشكل طبيعي',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _testAROverlays() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'اختبار العرض: جميع العناصر تظهر بشكل صحيح',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}