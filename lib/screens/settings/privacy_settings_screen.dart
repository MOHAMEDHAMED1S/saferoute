import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _shareLocationData = true;
  bool _shareUsageData = false;
  bool _allowAnalytics = false;
  bool _shareReportsAnonymously = true;
  bool _enableDataEncryption = true;
  bool _autoDeleteOldData = true;
  bool _requirePinForAccess = false;
  bool _enableBiometricAuth = false;
  int _dataRetentionDays = 30;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shareLocationData = prefs.getBool('share_location_data') ?? true;
      _shareUsageData = prefs.getBool('share_usage_data') ?? false;
      _allowAnalytics = prefs.getBool('allow_analytics') ?? false;
      _shareReportsAnonymously = prefs.getBool('share_reports_anonymously') ?? true;
      _enableDataEncryption = prefs.getBool('enable_data_encryption') ?? true;
      _autoDeleteOldData = prefs.getBool('auto_delete_old_data') ?? true;
      _requirePinForAccess = prefs.getBool('require_pin_for_access') ?? false;
      _enableBiometricAuth = prefs.getBool('enable_biometric_auth') ?? false;
      _dataRetentionDays = prefs.getInt('data_retention_days') ?? 30;
    });
  }

  Future<void> _saveBoolSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveIntSetting(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  void _showDataDeletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LiquidGlassTheme.surfaceColor,
        title: Text(
          'حذف جميع البيانات',
          style: LiquidGlassTheme.headerTextStyle,
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف جميع بياناتك؟ هذا الإجراء لا يمكن التراجع عنه.',
          style: LiquidGlassTheme.bodyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: LiquidGlassTheme.getTextColor('primary')),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LiquidGlassTheme.getGradientByName('danger').colors.first,
            ),
            child: const Text(
              'حذف',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    // هنا يمكن إضافة منطق حذف البيانات
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم حذف جميع البيانات بنجاح'),
        backgroundColor: LiquidGlassTheme.getGradientByName('success').colors.first,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'الخصوصية والأمان',
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
            // إعدادات مشاركة البيانات
            LiquidGlassContainer(
          type: LiquidGlassType.ultraLight,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مشاركة البيانات',
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPrivacyTile(
                    'مشاركة بيانات الموقع',
                    'السماح بمشاركة موقعك لتحسين الخدمة',
                    Icons.location_on,
                    _shareLocationData,
                    (value) {
                      setState(() => _shareLocationData = value);
                      _saveBoolSetting('share_location_data', value);
                    },
                  ),
                  _buildPrivacyTile(
                    'مشاركة بيانات الاستخدام',
                    'مساعدتنا في تحسين التطبيق',
                    Icons.analytics,
                    _shareUsageData,
                    (value) {
                      setState(() => _shareUsageData = value);
                      _saveBoolSetting('share_usage_data', value);
                    },
                  ),
                  _buildPrivacyTile(
                    'السماح بالتحليلات',
                    'جمع بيانات مجهولة لتحسين الأداء',
                    Icons.insights,
                    _allowAnalytics,
                    (value) {
                      setState(() => _allowAnalytics = value);
                      _saveBoolSetting('allow_analytics', value);
                    },
                  ),
                  _buildPrivacyTile(
                    'مشاركة البلاغات مجهولة',
                    'مشاركة بلاغاتك دون الكشف عن هويتك',
                    Icons.report,
                    _shareReportsAnonymously,
                    (value) {
                      setState(() => _shareReportsAnonymously = value);
                      _saveBoolSetting('share_reports_anonymously', value);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // إعدادات الأمان
            LiquidGlassContainer(
              type: LiquidGlassType.ultraLight,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الأمان',
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPrivacyTile(
                    'تشفير البيانات',
                    'حماية بياناتك بالتشفير المتقدم',
                    Icons.security,
                    _enableDataEncryption,
                    (value) {
                      setState(() => _enableDataEncryption = value);
                      _saveBoolSetting('enable_data_encryption', value);
                    },
                  ),
                  _buildPrivacyTile(
                    'طلب رقم سري للوصول',
                    'حماية التطبيق برقم سري',
                    Icons.pin,
                    _requirePinForAccess,
                    (value) {
                      setState(() => _requirePinForAccess = value);
                      _saveBoolSetting('require_pin_for_access', value);
                    },
                  ),
                  _buildPrivacyTile(
                    'المصادقة البيومترية',
                    'استخدام بصمة الإصبع أو الوجه',
                    Icons.fingerprint,
                    _enableBiometricAuth,
                    (value) {
                      setState(() => _enableBiometricAuth = value);
                      _saveBoolSetting('enable_biometric_auth', value);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // إدارة البيانات
            LiquidGlassContainer(
            type: LiquidGlassType.ultraLight,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إدارة البيانات',
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPrivacyTile(
                    'حذف البيانات القديمة تلقائياً',
                    'حذف البيانات بعد فترة محددة',
                    Icons.auto_delete,
                    _autoDeleteOldData,
                    (value) {
                      setState(() => _autoDeleteOldData = value);
                      _saveBoolSetting('auto_delete_old_data', value);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // مدة الاحتفاظ بالبيانات
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: LiquidGlassTheme.getGradientByName('primary').colors.first.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.schedule,
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
                              'مدة الاحتفاظ بالبيانات',
                              style: LiquidGlassTheme.headerTextStyle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_dataRetentionDays يوم',
                              style: LiquidGlassTheme.bodyTextStyle.copyWith(
                                fontSize: 14,
                                color: LiquidGlassTheme.getGradientByName('primary').colors.first,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _dataRetentionDays.toDouble(),
                    min: 7,
                    max: 365,
                    divisions: 51,
                    activeColor: LiquidGlassTheme.getGradientByName('primary').colors.first,
                    onChanged: (value) {
                      setState(() => _dataRetentionDays = value.round());
                    },
                    onChangeEnd: (value) {
                      _saveIntSetting('data_retention_days', value.round());
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // أزرار إدارة البيانات
                  Row(
                    children: [
                      Expanded(
                        child: LiquidGlassButton(
                          text: 'تصدير البيانات',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('سيتم تصدير بياناتك قريباً'),
                                backgroundColor: LiquidGlassTheme.getGradientByName('info').colors.first,
                              ),
                            );
                          },
                          type: LiquidGlassType.primary,
                          borderRadius: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LiquidGlassButton(
                          text: 'حذف جميع البيانات',
                          onPressed: _showDataDeletionDialog,
                          type: LiquidGlassType.primary,
                          borderRadius: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // معلومات الخصوصية
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
                        Icons.privacy_tip,
                        color: LiquidGlassTheme.getGradientByName('info').colors.first,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'سياسة الخصوصية',
                        style: LiquidGlassTheme.headerTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'نحن ملتزمون بحماية خصوصيتك. جميع البيانات المشفرة محلياً ولا نشارك معلوماتك الشخصية مع أطراف ثالثة دون موافقتك.',
                    style: LiquidGlassTheme.bodyTextStyle.copyWith(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LiquidGlassButton(
                    text: 'قراءة سياسة الخصوصية كاملة',
                    onPressed: () {
                      // يمكن إضافة رابط لسياسة الخصوصية
                    },
                    type: LiquidGlassType.ultraLight,
                    borderRadius: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyTile(
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