import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _emergencyNotifications = true;
  bool _speedWarnings = true;
  bool _fatigueAlerts = true;
  bool _reportUpdates = true;
  bool _systemNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _doNotDisturb = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyNotifications = prefs.getBool('emergency_notifications') ?? true;
      _speedWarnings = prefs.getBool('speed_warnings') ?? true;
      _fatigueAlerts = prefs.getBool('fatigue_alerts') ?? true;
      _reportUpdates = prefs.getBool('report_updates') ?? true;
      _systemNotifications = prefs.getBool('system_notifications') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _doNotDisturb = prefs.getBool('do_not_disturb') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'إعدادات الإشعارات',
          style: LiquidGlassTheme.headerTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: LiquidGlassTheme.getTextColor('primary'),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // إعدادات الإشعارات الأساسية
            LiquidGlassContainer(
          type: LiquidGlassType.ultraLight,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إشعارات السلامة',
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildNotificationTile(
                    'إشعارات الطوارئ',
                    'تنبيهات فورية في حالات الطوارئ',
                    Icons.emergency,
                    _emergencyNotifications,
                    (value) {
                      setState(() => _emergencyNotifications = value);
                      _saveSetting('emergency_notifications', value);
                    },
                  ),
                  _buildNotificationTile(
                    'تحذيرات السرعة',
                    'تنبيهات عند تجاوز الحد المسموح',
                    Icons.speed,
                    _speedWarnings,
                    (value) {
                      setState(() => _speedWarnings = value);
                      _saveSetting('speed_warnings', value);
                    },
                  ),
                  _buildNotificationTile(
                    'تنبيهات التعب',
                    'تذكيرات للراحة عند القيادة المطولة',
                    Icons.bedtime,
                    _fatigueAlerts,
                    (value) {
                      setState(() => _fatigueAlerts = value);
                      _saveSetting('fatigue_alerts', value);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // إعدادات البلاغات
            LiquidGlassContainer(
              type: LiquidGlassType.ultraLight,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إشعارات البلاغات',
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildNotificationTile(
                    'تحديثات البلاغات',
                    'إشعارات عند تأكيد أو رفض بلاغاتك',
                    Icons.report,
                    _reportUpdates,
                    (value) {
                      setState(() => _reportUpdates = value);
                      _saveSetting('report_updates', value);
                    },
                  ),
                  _buildNotificationTile(
                    'إشعارات النظام',
                    'تحديثات التطبيق والصيانة',
                    Icons.system_update,
                    _systemNotifications,
                    (value) {
                      setState(() => _systemNotifications = value);
                      _saveSetting('system_notifications', value);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // إعدادات الصوت والاهتزاز
            LiquidGlassContainer(
            type: LiquidGlassType.ultraLight,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إعدادات الصوت',
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildNotificationTile(
                    'الصوت',
                    'تفعيل الأصوات للإشعارات',
                    Icons.volume_up,
                    _soundEnabled,
                    (value) {
                      setState(() => _soundEnabled = value);
                      _saveSetting('sound_enabled', value);
                    },
                  ),
                  _buildNotificationTile(
                    'الاهتزاز',
                    'تفعيل الاهتزاز للإشعارات',
                    Icons.vibration,
                    _vibrationEnabled,
                    (value) {
                      setState(() => _vibrationEnabled = value);
                      _saveSetting('vibration_enabled', value);
                    },
                  ),
                  _buildNotificationTile(
                    'عدم الإزعاج',
                    'إيقاف جميع الإشعارات مؤقتاً',
                    Icons.do_not_disturb,
                    _doNotDisturb,
                    (value) {
                      setState(() => _doNotDisturb = value);
                      _saveSetting('do_not_disturb', value);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // معلومات إضافية
            LiquidGlassContainer(
              type: LiquidGlassType.ultraLight,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: LiquidGlassTheme.getGradientByName('info').colors.first,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'معلومات مهمة',
                        style: LiquidGlassTheme.headerTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'إشعارات الطوارئ لا يمكن إيقافها تماماً لضمان سلامتك. يمكنك تقليل مستوى الصوت فقط.',
                    style: LiquidGlassTheme.bodyTextStyle.copyWith(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LiquidGlassTheme.getGradientByName('primary').colors.first.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: LiquidGlassTheme.getGradientByName('primary').colors.first,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LiquidGlassTheme.headerTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: LiquidGlassTheme.getGradientByName('primary').colors.first,
            activeTrackColor: LiquidGlassTheme.getGradientByName('primary').colors.first.withAlpha(102),
          ),
        ],
      ),
    );
  }
}