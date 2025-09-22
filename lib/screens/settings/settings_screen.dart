import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/glass_container.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/language_settings_widget.dart';
import '../language/language_settings_screen.dart';
import '../ar/ar_settings_screen.dart';
import '../performance/performance_settings_screen.dart';
import '../driving/driving_settings_screen.dart';
import '../reports/advanced_reports_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // State
  bool _isLocationEnabled = true;
  bool _isLanguageSettingsExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }
  
  void _loadSettings() {
    // تحميل الإعدادات المحفوظة
    // يمكن تنفيذها لاحقاً مع SharedPreferences
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
              Color(0xFF2D3561),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUserSection(),
                          const SizedBox(height: 24),
                          
                          _buildGeneralSettings(),
                          const SizedBox(height: 20),
                          
                          _buildAppSettings(),
                          const SizedBox(height: 20),
                          
                          _buildAdvancedSettings(),
                          const SizedBox(height: 20),
                          
                          _buildAboutSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإعدادات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'تخصيص تجربة التطبيق',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Settings icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserSection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            
            // User info
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مستخدم SafeRoute',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'user@saferoute.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Edit button
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGeneralSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإعدادات العامة',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        GlassContainer(
          child: Column(
            children: [
              _buildSettingCard(
                'اللغة',
                'تغيير لغة التطبيق',
                Icons.language,
                () => _navigateToLanguageSettings(),
              ),
              const Divider(color: Colors.white24),
              
              Consumer<AppSettingsProvider>(
                builder: (context, settings, child) {
                  return _buildSwitchCard(
                    'الوضع الليلي',
                    'تفعيل المظهر الداكن',
                    Icons.dark_mode,
                    settings.isDarkMode,
                    (value) {
                      settings.toggleDarkMode();
                    },
                  );
                },
              ),
              const Divider(color: Colors.white24),
              
              _buildSettingCard(
                'الإشعارات',
                'إدارة إشعارات التطبيق',
                Icons.notifications,
                () => _navigateToNotificationSettings(),
              ),
              const Divider(color: Colors.white24),
              
              _buildSwitchCard(
                'خدمات الموقع',
                'السماح بالوصول للموقع',
                Icons.location_on,
                _isLocationEnabled,
                (value) {
                  setState(() {
                    _isLocationEnabled = value;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Language Settings Widget
        LanguageSettingsWidget(
          isExpanded: _isLanguageSettingsExpanded,
          onToggle: () {
            setState(() {
              _isLanguageSettingsExpanded = !_isLanguageSettingsExpanded;
            });
          },
          showAdvancedOptions: false,
        ),
      ],
    );
  }
  
  Widget _buildAppSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إعدادات التطبيق',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        GlassContainer(
          child: Column(
            children: [
              _buildSettingCard(
                'إعدادات القيادة',
                'تخصيص تجربة القيادة',
                Icons.drive_eta,
                () => _navigateToDrivingSettings(),
              ),
              const Divider(color: Colors.white24),
              
              _buildSettingCard(
                'الواقع المعزز',
                'إعدادات ميزات AR',
                Icons.view_in_ar,
                () => _navigateToARSettings(),
              ),
              const Divider(color: Colors.white24),
              
              _buildSettingCard(
                'مراقب الأداء',
                'إعدادات الأداء والذاكرة',
                Icons.speed,
                () => _navigateToPerformanceSettings(),
              ),
              const Divider(color: Colors.white24),
              
              _buildSettingCard(
                'التقارير المتقدمة',
                'عرض تقارير مفصلة عن الاستخدام',
                Icons.analytics,
                () => _navigateToAdvancedReports(),
              ),
              const Divider(color: Colors.white24),
              
              _buildSettingCard(
                'الأمان والحماية',
                'مراقبة الأمان وإعدادات الحماية',
                Icons.security,
                () => _navigateToSecurityMonitor(),
              ),
              const Divider(color: Colors.white24),
              
              _buildSettingCard(
                'الخصوصية والأمان',
                'إدارة بيانات الخصوصية',
                Icons.security,
                () => _navigateToPrivacySettings(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإعدادات المتقدمة',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        GlassContainer(
          child: Column(
            children: [
              _buildSettingCard(
                'النسخ الاحتياطي',
                'نسخ احتياطي للبيانات',
                Icons.backup,
                () => _showBackupDialog(),
              ),
              const Divider(color: Colors.white24),
              
              _buildSettingCard(
                'مسح البيانات',
                'حذف جميع البيانات المحلية',
                Icons.delete_forever,
                () => _showClearDataDialog(),
              ),
              const Divider(color: Colors.white24),
              
              _buildSettingCard(
                'إعادة تعيين التطبيق',
                'استعادة الإعدادات الافتراضية',
                Icons.restore,
                () => _showResetDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'حول التطبيق',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        GlassContainer(
          child: Column(
            children: [
              _buildSettingCard(
                'معلومات التطبيق',
                'الإصدار والتحديثات',
                Icons.info,
                () => _showAppInfoDialog(),
              ),
              const Divider(color: Colors.white24),
              
              _buildSettingCard(
                'المساعدة والدعم',
                'الحصول على المساعدة',
                Icons.help,
                () => _navigateToHelp(),
              ),
              const Divider(color: Colors.white24),
              
              _buildSettingCard(
                'تقييم التطبيق',
                'تقييم التطبيق في المتجر',
                Icons.star,
                () => _rateApp(),
              ),
              const Divider(color: Colors.white24),
              
              _buildSettingCard(
                'شروط الاستخدام',
                'قراءة شروط الاستخدام',
                Icons.description,
                () => _showTermsDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSettingCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white70,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white60,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSwitchCard(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white70,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
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
            inactiveThumbColor: Colors.white60,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
  
  // Navigation methods
  void _navigateToLanguageSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LanguageSettingsScreen(),
      ),
    );
  }
  
  void _navigateToNotificationSettings() {
    // تنفيذ لاحقاً
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('إعدادات الإشعارات ستكون متاحة قريباً'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _navigateToDrivingSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DrivingSettingsScreen(),
      ),
    );
  }
  
  void _navigateToARSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ARSettingsScreen(),
      ),
    );
  }
  
  void _navigateToPerformanceSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PerformanceSettingsScreen(),
      ),
    );
  }
  
  void _navigateToPrivacySettings() {
    // تنفيذ لاحقاً
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('إعدادات الخصوصية ستكون متاحة قريباً'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _navigateToAdvancedReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdvancedReportsScreen(),
      ),
    );
  }
  
  void _navigateToSecurityMonitor() {
    Navigator.pushNamed(context, '/security-monitor');
  }
  
  void _navigateToHelp() {
    // تنفيذ لاحقاً
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('صفحة المساعدة ستكون متاحة قريباً'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  // Dialog methods
  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'النسخ الاحتياطي',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'هل تريد إنشاء نسخة احتياطية من بياناتك؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // تنفيذ النسخ الاحتياطي
            },
            child: const Text('نسخ احتياطي'),
          ),
        ],
      ),
    );
  }
  
  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'مسح البيانات',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'تحذير: سيتم حذف جميع البيانات المحلية. هذا الإجراء لا يمكن التراجع عنه.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // تنفيذ مسح البيانات
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }
  
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'إعادة تعيين التطبيق',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'سيتم استعادة جميع الإعدادات إلى القيم الافتراضية.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // تنفيذ إعادة التعيين
            },
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );
  }
  
  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'معلومات التطبيق',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SafeRoute',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'الإصدار: 1.0.0',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'تاريخ الإصدار: 2024',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              'تطبيق ملاحة ذكي مع ميزات الواقع المعزز والذكاء الاصطناعي.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
  
  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'شروط الاستخدام',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'شروط الاستخدام وسياسة الخصوصية...\n\n'
            'يرجى قراءة هذه الشروط بعناية قبل استخدام التطبيق.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
  
  void _rateApp() {
    // تنفيذ تقييم التطبيق
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('شكراً لك! سيتم توجيهك لتقييم التطبيق'),
        backgroundColor: Colors.green,
      ),
    );
  }
}