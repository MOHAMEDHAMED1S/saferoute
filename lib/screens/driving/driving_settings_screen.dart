import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/driving_settings_model.dart';
import '../../services/driving_settings_service.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';

class DrivingSettingsScreen extends StatefulWidget {
  const DrivingSettingsScreen({super.key});

  @override
  State<DrivingSettingsScreen> createState() => _DrivingSettingsScreenState();
}

class _DrivingSettingsScreenState extends State<DrivingSettingsScreen>
    with TickerProviderStateMixin {
  late DrivingSettingsService _settingsService;
  late TabController _tabController;
  DrivingSettings _settings = const DrivingSettings();
  Map<String, DrivingSettings> _profiles = {};
  String _currentProfile = 'افتراضي';
  bool _isLoading = true;
  
  final TextEditingController _profileNameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _settingsService = DrivingSettingsService();
    _initializeSettings();
  }
  
  Future<void> _initializeSettings() async {
    await _settingsService.initialize();
    
    _settingsService.settingsStream.listen((settings) {
      if (mounted) {
        setState(() {
          _settings = settings;
        });
      }
    });
    
    _settingsService.profilesStream.listen((profiles) {
      if (mounted) {
        setState(() {
          _profiles = profiles;
        });
      }
    });
    
    setState(() {
      _settings = _settingsService.currentSettings;
      _profiles = _settingsService.profiles;
      _currentProfile = _settingsService.currentProfileName;
      _isLoading = false;
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _profileNameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: LiquidGlassTheme.primaryColor,
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProfileSelector(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralTab(),
                _buildDisplayTab(),
                _buildSafetyTab(),
                _buildVoiceTab(),
                _buildNavigationTab(),
                _buildAdvancedTab(),
                _buildUIElementsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'إعدادات القيادة',
        style: TextStyle(
          color: LiquidGlassTheme.textColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: LiquidGlassTheme.textColor),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: LiquidGlassTheme.textColor),
          onPressed: _resetCurrentProfile,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: LiquidGlassTheme.textColor),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.upload),
                  SizedBox(width: 8),
                  Text('تصدير الإعدادات'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('استيراد الإعدادات'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reset_all',
              child: Row(
                children: [
                  Icon(Icons.restore),
                  SizedBox(width: 8),
                  Text('إعادة تعيين الكل'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildProfileSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: LiquidGlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الملف الشخصي الحالي',
                      style: TextStyle(
                        color: LiquidGlassTheme.textColor.withAlpha(178),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: _currentProfile,
                      isExpanded: true,
                      underline: Container(),
                      style: TextStyle(
                        color: LiquidGlassTheme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      dropdownColor: LiquidGlassTheme.surfaceColor,
                      items: _profiles.keys.map((String profile) {
                        return DropdownMenuItem<String>(
                          value: profile,
                          child: Text(profile),
                        );
                      }).toList(),
                      onChanged: (String? newProfile) {
                        if (newProfile != null) {
                          _switchProfile(newProfile);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    color: LiquidGlassTheme.primaryColor,
                    onPressed: _createNewProfile,
                  ),
                  if (_currentProfile != 'افتراضي')
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: _deleteCurrentProfile,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: LiquidGlassTheme.primaryColor,
        unselectedLabelColor: LiquidGlassTheme.textColor.withAlpha(153),
        indicatorColor: LiquidGlassTheme.primaryColor,
        tabs: const [
          Tab(text: 'عام'),
          Tab(text: 'العرض'),
          Tab(text: 'السلامة'),
          Tab(text: 'الصوت'),
          Tab(text: 'الملاحة'),
          Tab(text: 'متقدم'),
          Tab(text: 'العناصر'),
        ],
      ),
    );
  }
  
  Widget _buildGeneralTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'وضع القيادة',
          [
            _buildModeSelector(),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'الوحدات',
          [
            _buildUnitSelector('وحدة السرعة', _settings.speedUnit, SpeedUnit.values, 
              (unit) => _settingsService.updateSettings(_settings.copyWith(speedUnit: unit))),
            _buildUnitSelector('وحدة المسافة', _settings.distanceUnit, DistanceUnit.values, 
              (unit) => _settingsService.updateSettings(_settings.copyWith(distanceUnit: unit))),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'نمط الخريطة',
          [
            _buildMapStyleSelector(),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDisplayTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'عناصر العرض',
          [
            _buildSwitchTile('عداد السرعة', _settings.showSpeedometer, 
              (value) => _settingsService.updateDisplaySettings(showSpeedometer: value)),
            _buildSwitchTile('البوصلة', _settings.showCompass, 
              (value) => _settingsService.updateDisplaySettings(showCompass: value)),
            _buildSwitchTile('الطقس', _settings.showWeather, 
              (value) => _settingsService.updateDisplaySettings(showWeather: value)),
            _buildSwitchTile('حركة المرور', _settings.showTraffic, 
              (value) => _settingsService.updateDisplaySettings(showTraffic: value)),
            _buildSwitchTile('نقاط الاهتمام', _settings.showPOI, 
              (value) => _settingsService.updateDisplaySettings(showPOI: value)),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'الإضاءة',
          [
            _buildSwitchTile('الوضع الليلي التلقائي', _settings.nightModeAuto, 
              (value) => _settingsService.updateDisplaySettings(nightModeAuto: value)),
            _buildSliderTile('السطوع', _settings.brightness, 0.1, 1.0, 
              (value) => _settingsService.updateDisplaySettings(brightness: value)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSafetyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'تحذيرات السلامة',
          [
            _buildSwitchTile('تحذيرات السرعة', _settings.speedWarningsEnabled, 
              (value) => _settingsService.updateSafetySettings(speedWarnings: value)),
            _buildSwitchTile('كشف التعب', _settings.fatigueDetectionEnabled, 
              (value) => _settingsService.updateSafetySettings(fatigueDetection: value)),
            _buildSwitchTile('مساعد المسار', _settings.laneAssistEnabled, 
              (value) => _settingsService.updateSafetySettings(laneAssist: value)),
            _buildSwitchTile('كشف الطوارئ', _settings.emergencyDetectionEnabled, 
              (value) => _settingsService.updateSafetySettings(emergencyDetection: value)),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'إعدادات التحذير',
          [
            _buildSliderTile('حد تجاوز السرعة (كم/س)', _settings.speedWarningThreshold.toDouble(), 5, 30, 
              (value) => _settingsService.updateSafetySettings(speedThreshold: value.round())),
            _buildSliderTile('فترة فحص التعب (دقيقة)', _settings.fatigueCheckInterval.toDouble(), 10, 60, 
              (value) => _settingsService.updateSafetySettings(fatigueInterval: value.round())),
          ],
        ),
      ],
    );
  }
  
  Widget _buildVoiceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'إعدادات الصوت',
          [
            _buildSwitchTile('تفعيل الصوت', _settings.voiceEnabled, 
              (value) => _settingsService.updateVoiceSettings(enabled: value)),
            _buildSwitchTile('الإعلانات الاستباقية', _settings.voiceProactiveAnnouncements, 
              (value) => _settingsService.updateVoiceSettings()),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'جودة الصوت',
          [
            _buildSliderTile('مستوى الصوت', _settings.voiceVolume, 0.1, 1.0, 
              (value) => _settingsService.updateVoiceSettings(volume: value)),
            _buildSliderTile('سرعة الكلام', _settings.voiceSpeed, 0.5, 1.5, 
              (value) => _settingsService.updateVoiceSettings(speed: value)),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'نوع الصوت',
          [
            _buildUnitSelector('جنس الصوت', _settings.voiceGender, VoiceGender.values, 
              (gender) => _settingsService.updateVoiceSettings(gender: gender)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildNavigationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'تفضيلات الطريق',
          [
            _buildSwitchTile('تجنب الرسوم', _settings.avoidTolls, 
              (value) => _settingsService.updateNavigationSettings(avoidTolls: value)),
            _buildSwitchTile('تجنب الطرق السريعة', _settings.avoidHighways, 
              (value) => _settingsService.updateNavigationSettings(avoidHighways: value)),
            _buildSwitchTile('تجنب العبارات', _settings.avoidFerries, 
              (value) => _settingsService.updateNavigationSettings(avoidFerries: value)),
            _buildSwitchTile('تفضيل الطريق الأسرع', _settings.preferFastestRoute, 
              (value) => _settingsService.updateNavigationSettings(preferFastest: value)),
            _buildSwitchTile('إظهار الطرق البديلة', _settings.showAlternativeRoutes, 
              (value) => _settingsService.updateNavigationSettings(showAlternatives: value)),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'إعادة الحساب',
          [
            _buildSliderTile('حساسية إعادة الحساب', _settings.routeRecalculationSensitivity.toDouble(), 1, 5, 
              (value) => _settingsService.updateNavigationSettings(recalculationSensitivity: value.round())),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'التحذيرات',
          [
            _buildSwitchTile('تحذيرات الحوادث', _settings.showAccidentWarnings, 
              (value) => _settingsService.updateWarningSettings(showAccidents: value)),
            _buildSwitchTile('تحذيرات الازدحام', _settings.showTrafficWarnings, 
              (value) => _settingsService.updateWarningSettings(showTraffic: value)),
            _buildSwitchTile('تحذيرات كاميرات السرعة', _settings.showSpeedCameraWarnings, 
              (value) => _settingsService.updateWarningSettings(showSpeedCameras: value)),
            _buildSwitchTile('تحذيرات الشرطة', _settings.showPoliceWarnings, 
              (value) => _settingsService.updateWarningSettings(showPolice: value)),
            _buildSwitchTile('تحذيرات أعمال الطريق', _settings.showRoadworkWarnings, 
              (value) => _settingsService.updateWarningSettings(showRoadwork: value)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAdvancedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'الذكاء الاصطناعي',
          [
            _buildSwitchTile('الواجهة التكيفية', _settings.adaptiveInterface, 
              (value) => _settingsService.updateAdvancedSettings(adaptiveInterface: value)),
            _buildSwitchTile('وضع التعلم', _settings.learningMode, 
              (value) => _settingsService.updateAdvancedSettings(learningMode: value)),
            _buildSwitchTile('التوجيه التنبؤي', _settings.predictiveRouting, 
              (value) => _settingsService.updateAdvancedSettings(predictiveRouting: value)),
            _buildSwitchTile('التكيف مع الطقس', _settings.weatherAdaptation, 
              (value) => _settingsService.updateAdvancedSettings(weatherAdaptation: value)),
            _buildSwitchTile('التحسين الزمني', _settings.timeBasedOptimization, 
              (value) => _settingsService.updateAdvancedSettings(timeBasedOptimization: value)),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'الخصوصية',
          [
            _buildSwitchTile('مشاركة بيانات الموقع', _settings.shareLocationData, 
              (value) => _settingsService.updatePrivacySettings(shareLocation: value)),
            _buildSwitchTile('مشاركة بيانات المرور', _settings.shareTrafficData, 
              (value) => _settingsService.updatePrivacySettings(shareTraffic: value)),
            _buildSwitchTile('مشاركة تقارير الحوادث', _settings.shareIncidentReports, 
              (value) => _settingsService.updatePrivacySettings(shareIncidents: value)),
            _buildSwitchTile('الوضع المجهول', _settings.anonymousMode, 
              (value) => _settingsService.updatePrivacySettings(anonymousMode: value)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSectionCard(String title, List<Widget> children) {
    return LiquidGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: LiquidGlassTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildModeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DrivingMode.values.map((mode) {
        final isSelected = _settings.mode == mode;
        return GestureDetector(
          onTap: () => _settingsService.updateDrivingMode(mode),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? LiquidGlassTheme.primaryColor : Colors.transparent,
              border: Border.all(
                color: isSelected ? LiquidGlassTheme.primaryColor : LiquidGlassTheme.textColor.withAlpha(76),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getModeDisplayName(mode),
              style: TextStyle(
                color: isSelected ? Colors.white : LiquidGlassTheme.textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildMapStyleSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MapStyle.values.map((style) {
        final isSelected = _settings.mapStyle == style;
        return GestureDetector(
          onTap: () => _settingsService.updateMapStyle(style),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? LiquidGlassTheme.primaryColor : Colors.transparent,
              border: Border.all(
                color: isSelected ? LiquidGlassTheme.primaryColor : LiquidGlassTheme.textColor.withAlpha(76),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getMapStyleDisplayName(style),
              style: TextStyle(
                color: isSelected ? Colors.white : LiquidGlassTheme.textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildUnitSelector<T>(String title, T currentValue, List<T> values, Function(T) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: LiquidGlassTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: values.map((value) {
            final isSelected = currentValue == value;
            return GestureDetector(
              onTap: () => onChanged(value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? LiquidGlassTheme.primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? LiquidGlassTheme.primaryColor : LiquidGlassTheme.textColor.withAlpha(76),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getDisplayName(value),
                  style: TextStyle(
                    color: isSelected ? Colors.white : LiquidGlassTheme.textColor,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: LiquidGlassTheme.textColor,
                fontSize: 16,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: LiquidGlassTheme.primaryColor,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSliderTile(String title, double value, double min, double max, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: LiquidGlassTheme.textColor,
                  fontSize: 16,
                ),
              ),
              Text(
                value.toStringAsFixed(value < 10 ? 1 : 0),
                style: TextStyle(
                  color: LiquidGlassTheme.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: LiquidGlassTheme.primaryColor,
            inactiveColor: LiquidGlassTheme.textColor.withAlpha(76),
          ),
        ],
      ),
    );
  }
  
  String _getModeDisplayName(DrivingMode mode) {
    switch (mode) {
      case DrivingMode.normal:
        return 'عادي';
      case DrivingMode.eco:
        return 'اقتصادي';
      case DrivingMode.sport:
        return 'رياضي';
      case DrivingMode.comfort:
        return 'مريح';
      case DrivingMode.night:
        return 'ليلي';
      case DrivingMode.rain:
        return 'مطر';
      case DrivingMode.highway:
        return 'طريق سريع';
    }
  }
  
  String _getMapStyleDisplayName(MapStyle style) {
    switch (style) {
      case MapStyle.standard:
        return 'عادي';
      case MapStyle.satellite:
        return 'قمر صناعي';
      case MapStyle.hybrid:
        return 'مختلط';
      case MapStyle.terrain:
        return 'تضاريس';
      case MapStyle.dark:
        return 'داكن';
      case MapStyle.retro:
        return 'كلاسيكي';
    }
  }
  
  String _getDisplayName(dynamic value) {
    if (value is SpeedUnit) {
      return value == SpeedUnit.kmh ? 'كم/س' : 'ميل/س';
    } else if (value is DistanceUnit) {
      return value == DistanceUnit.km ? 'كيلومتر' : 'ميل';
    } else if (value is VoiceGender) {
      return value == VoiceGender.male ? 'ذكر' : 'أنثى';
    }
    return value.toString();
  }
  
  void _switchProfile(String profileName) async {
    await _settingsService.switchToProfile(profileName);
    setState(() {
      _currentProfile = profileName;
    });
  }
  
  void _createNewProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LiquidGlassTheme.surfaceColor,
        title: Text(
          'إنشاء ملف شخصي جديد',
          style: TextStyle(color: LiquidGlassTheme.textColor),
        ),
        content: TextField(
          controller: _profileNameController,
          style: TextStyle(color: LiquidGlassTheme.textColor),
          decoration: InputDecoration(
            hintText: 'اسم الملف الشخصي',
            hintStyle: TextStyle(color: LiquidGlassTheme.textColor.withAlpha(153)),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: LiquidGlassTheme.primaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: LiquidGlassTheme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: LiquidGlassTheme.textColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_profileNameController.text.isNotEmpty) {
                await _settingsService.createProfile(
                  _profileNameController.text,
                  _settings,
                );
                _profileNameController.clear();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LiquidGlassTheme.primaryColor,
            ),
            child: const Text('إنشاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _deleteCurrentProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LiquidGlassTheme.surfaceColor,
        title: Text(
          'حذف الملف الشخصي',
          style: TextStyle(color: LiquidGlassTheme.textColor),
        ),
        content: Text(
          'هل أنت متأكد من حذف الملف الشخصي "$_currentProfile"؟',
          style: TextStyle(color: LiquidGlassTheme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: TextStyle(color: LiquidGlassTheme.textColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _settingsService.deleteProfile(_currentProfile);
    }
  }
  
  void _resetCurrentProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LiquidGlassTheme.surfaceColor,
        title: Text(
          'إعادة تعيين الملف الشخصي',
          style: TextStyle(color: LiquidGlassTheme.textColor),
        ),
        content: Text(
          'هل تريد إعادة تعيين الملف الشخصي "$_currentProfile" إلى الإعدادات الافتراضية؟',
          style: TextStyle(color: LiquidGlassTheme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: TextStyle(color: LiquidGlassTheme.textColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: LiquidGlassTheme.primaryColor),
            child: const Text('إعادة تعيين', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _settingsService.resetProfile(_currentProfile);
    }
  }
  
  void _handleMenuAction(String action) async {
    switch (action) {
      case 'export':
        final settings = _settingsService.exportSettings();
        await Clipboard.setData(ClipboardData(text: settings));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نسخ الإعدادات إلى الحافظة')),
        );
        break;
      case 'import':
        // In a real app, you would show a file picker or text input dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ميزة الاستيراد قيد التطوير')),
        );
        break;
      case 'reset_all':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: LiquidGlassTheme.surfaceColor,
            title: Text(
              'إعادة تعيين جميع الإعدادات',
              style: TextStyle(color: LiquidGlassTheme.textColor),
            ),
            content: Text(
              'هل تريد إعادة تعيين جميع الإعدادات والملفات الشخصية؟',
              style: TextStyle(color: LiquidGlassTheme.textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('إلغاء', style: TextStyle(color: LiquidGlassTheme.textColor)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('إعادة تعيين', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        
        if (confirmed == true) {
          await _settingsService.resetToDefaults();
        }
        break;
    }
  }
  
  Widget _buildUIElementsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'العناصر العائمة',
          [
            _buildSwitchTile('إظهار الأزرار العائمة', _settings.showFloatingActions, 
              (value) => _settingsService.updateUIVisibilitySettings(showFloatingActions: value)),
            _buildSwitchTile('زر الواقع المعزز', _settings.showARNavigation, 
              (value) => _settingsService.updateUIVisibilitySettings(showARNavigation: value)),
            _buildSwitchTile('مراقب الأداء', _settings.showPerformanceMonitor, 
              (value) => _settingsService.updateUIVisibilitySettings(showPerformanceMonitor: value)),
            _buildSwitchTile('المساعد الذكي', _settings.showAIChat, 
              (value) => _settingsService.updateUIVisibilitySettings(showAIChat: value)),
            _buildSwitchTile('المساعد الصوتي', _settings.showVoiceAssistant, 
              (value) => _settingsService.updateUIVisibilitySettings(showVoiceAssistant: value)),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'عناصر الواجهة',
          [
            _buildSwitchTile('معلومات الملاحة', _settings.showNavigationInfo, 
              (value) => _settingsService.updateUIVisibilitySettings(showNavigationInfo: value)),
            _buildSwitchTile('أزرار التحكم السفلية', _settings.showBottomControls, 
              (value) => _settingsService.updateUIVisibilitySettings(showBottomControls: value)),
          ],
        ),
      ],
    );
  }
}