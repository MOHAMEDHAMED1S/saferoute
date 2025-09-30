import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/liquid_glass_theme.dart';

class DrivingSettingsScreen extends StatefulWidget {
  static const String routeName = '/driving-settings';

  const DrivingSettingsScreen({super.key});

  @override
  State<DrivingSettingsScreen> createState() => _DrivingSettingsScreenState();
}

class _DrivingSettingsScreenState extends State<DrivingSettingsScreen> {
  // Settings
  double _warningDistance = 200.0; // meters
  double _updateInterval = 30.0; // seconds
  bool _enableVoiceWarnings = true;
  bool _enableVibration = true;
  bool _enableSound = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _warningDistance = prefs.getDouble('warning_distance') ?? 200.0;
      _updateInterval = prefs.getDouble('update_interval') ?? 30.0;
      _enableVoiceWarnings = prefs.getBool('enable_voice_warnings') ?? true;
      _enableVibration = prefs.getBool('enable_vibration') ?? true;
      _enableSound = prefs.getBool('enable_sound') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('warning_distance', _warningDistance);
    await prefs.setDouble('update_interval', _updateInterval);
    await prefs.setBool('enable_voice_warnings', _enableVoiceWarnings);
    await prefs.setBool('enable_vibration', _enableVibration);
    await prefs.setBool('enable_sound', _enableSound);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'إعدادات وضع القيادة',
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Distance
            _buildSettingCard(
              title: 'مسافة التحذير',
              subtitle: 'المسافة الدنيا لإظهار تحذير البلاغات',
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_searching,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_warningDistance.toInt()} متر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _warningDistance,
                    min: 50,
                    max: 1000,
                    divisions: 95,
                    activeColor: Colors.blue.shade700,
                    inactiveColor: Colors.blue.shade200,
                    onChanged: (value) {
                      setState(() {
                        _warningDistance = value;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Update Interval
            _buildSettingCard(
              title: 'فترة التحديث',
              subtitle: 'معدل تحديث البلاغات والموقع',
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.update,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'كل ${_updateInterval.toInt()} ثانية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _updateInterval,
                    min: 10,
                    max: 120,
                    divisions: 22,
                    activeColor: Colors.green.shade700,
                    inactiveColor: Colors.green.shade200,
                    onChanged: (value) {
                      setState(() {
                        _updateInterval = value;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Voice Warnings
            _buildSettingCard(
              title: 'التحذيرات الصوتية',
              subtitle: 'تفعيل التحذيرات الصوتية للبلاغات',
              child: Switch(
                value: _enableVoiceWarnings,
                onChanged: (value) {
                  setState(() {
                    _enableVoiceWarnings = value;
                  });
                  _saveSettings();
                },
                activeColor: Colors.blue.shade700,
              ),
            ),

            const SizedBox(height: 16),

            // Vibration
            _buildSettingCard(
              title: 'الاهتزاز',
              subtitle: 'تفعيل الاهتزاز عند وجود تحذيرات',
              child: Switch(
                value: _enableVibration,
                onChanged: (value) {
                  setState(() {
                    _enableVibration = value;
                  });
                  _saveSettings();
                },
                activeColor: Colors.blue.shade700,
              ),
            ),

            const SizedBox(height: 16),

            // Sound
            _buildSettingCard(
              title: 'الأصوات',
              subtitle: 'تفعيل الأصوات للتحذيرات',
              child: Switch(
                value: _enableSound,
                onChanged: (value) {
                  setState(() {
                    _enableSound = value;
                  });
                  _saveSettings();
                },
                activeColor: Colors.blue.shade700,
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _saveSettings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حفظ الإعدادات بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'حفظ الإعدادات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
              fontFamily: 'NotoSansArabic',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontFamily: 'NotoSansArabic',
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}