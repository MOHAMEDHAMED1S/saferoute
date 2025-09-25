import 'package:flutter/material.dart';
import '../../models/driving_settings_model.dart';
import '../../services/driving_settings_service.dart';
import '../../theme/liquid_glass_theme.dart';

class DrivingSettingsScreen extends StatefulWidget {
  const DrivingSettingsScreen({super.key});

  @override
  State<DrivingSettingsScreen> createState() => _DrivingSettingsScreenState();
}

class _DrivingSettingsScreenState extends State<DrivingSettingsScreen> {
  late DrivingSettingsService _settingsService;
  DrivingSettings _settings = const DrivingSettings();
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
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
    
    final settings = await _settingsService.getSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _settingsService.dispose();
    super.dispose();
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    await _settingsService.saveSettings(_settings);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الإعدادات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات القيادة'),
        centerTitle: true,
        backgroundColor: LiquidGlassTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavigationSettings(),
                  const Divider(height: 32),
                  _buildSafetySettings(),
                  const Divider(height: 32),
                  _buildNotificationSettings(),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LiquidGlassTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'حفظ الإعدادات',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildNavigationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إعدادات الملاحة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSwitchSetting(
          title: 'تفعيل التوجيه الصوتي',
          subtitle: 'سماع التعليمات الصوتية أثناء التنقل',
          value: _settings.voiceEnabled,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(voiceEnabled: value);
            });
          },
        ),
        _buildSwitchSetting(
          title: 'تجنب الطرق ذات الرسوم',
          subtitle: 'تفضيل الطرق المجانية عند التنقل',
          value: _settings.avoidTolls,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(avoidTolls: value);
            });
          },
        ),
        _buildSwitchSetting(
          title: 'تجنب الطرق السريعة',
          subtitle: 'تفضيل الطرق العادية عند التنقل',
          value: _settings.avoidHighways,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(avoidHighways: value);
            });
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownSetting<MapStyle>(
          title: 'نوع الخريطة',
          value: _settings.mapStyle,
          items: MapStyle.values,
          getLabel: _getMapTypeLabel,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _settings = _settings.copyWith(mapStyle: value);
              });
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildSafetySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إعدادات السلامة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSwitchSetting(
          title: 'تنبيهات السرعة',
          subtitle: 'تنبيه عند تجاوز حدود السرعة',
          value: _settings.speedWarningsEnabled,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(speedWarningsEnabled: value);
            });
          },
        ),
        _buildSwitchSetting(
          title: 'تنبيهات الحوادث',
          subtitle: 'تنبيه عند وجود حوادث على الطريق',
          value: _settings.showAccidentWarnings,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(showAccidentWarnings: value);
            });
          },
        ),
        _buildSwitchSetting(
          title: 'تنبيهات الازدحام',
          subtitle: 'تنبيه عند وجود ازدحام مروري',
          value: _settings.showTrafficWarnings,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(showTrafficWarnings: value);
            });
          },
        ),
        const SizedBox(height: 16),
        _buildSliderSetting(
          title: 'مسافة التنبيه (متر)',
          value: _settings.warningDistance.toDouble(),
          min: 100,
          max: 1000,
          divisions: 9,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(warningDistance: value.round());
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إعدادات الإشعارات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSwitchSetting(
          title: 'إشعارات البلاغات',
          subtitle: 'استلام إشعارات عن البلاغات الجديدة في منطقتك',
          value: _settings.shareIncidentReports,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(shareIncidentReports: value);
            });
          },
        ),
        _buildSwitchSetting(
          title: 'إشعارات الطوارئ',
          subtitle: 'استلام إشعارات عن حالات الطوارئ في منطقتك',
          value: _settings.emergencyDetectionEnabled,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(emergencyDetectionEnabled: value);
            });
            _settingsService.updateSettings(_settings);
          },
        ),
      ],
    );
  }
  
  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeThumbColor: LiquidGlassTheme.primaryColor,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
  
  Widget _buildSliderSetting({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ${value.round()}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.round().toString(),
            onChanged: onChanged,
            activeColor: LiquidGlassTheme.primaryColor,
            thumbColor: LiquidGlassTheme.primaryColor,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDropdownSetting<T>({
    required String title,
    required T value,
    required List<T> items,
    required String Function(T) getLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          DropdownButton<T>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(getLabel(item)),
              );
            }).toList(),
            onChanged: onChanged,
            underline: Container(
              height: 1,
              color: LiquidGlassTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getMapTypeLabel(MapStyle type) {
    switch (type) {
      case MapStyle.standard:
        return 'عادية';
      case MapStyle.satellite:
        return 'قمر صناعي';
      case MapStyle.terrain:
        return 'تضاريس';
      case MapStyle.hybrid:
        return 'هجينة';
      case MapStyle.dark:
        return 'داكنة';
      case MapStyle.retro:
        return 'رجعية';
    }
  }
}