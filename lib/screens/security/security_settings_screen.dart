import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/security_model.dart';
import '../../services/security_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen>
    with TickerProviderStateMixin {
  final SecurityService _securityService = SecurityService();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  SecuritySettings _settings = const SecuritySettings();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
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

  Future<void> _loadSettings() async {
    try {
      await _securityService.initialize();
      setState(() {
        _settings = _securityService.settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('خطأ في تحميل إعدادات الأمان');
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      await _securityService.updateSettings(_settings);
      _showSuccessSnackBar('تم حفظ الإعدادات بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في حفظ الإعدادات');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF3949AB),
              Color(0xFF5C6BC0),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _isLoading ? _buildLoadingView() : _buildMainView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'جاري تحميل إعدادات الأمان...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAuthenticationSection(),
              const SizedBox(height: 20),
              _buildDataProtectionSection(),
              const SizedBox(height: 20),
              _buildMonitoringSection(),
              const SizedBox(height: 20),
              _buildAdvancedSection(),
              const SizedBox(height: 20),
              _buildSaveButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.security,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'إعدادات الأمان والحماية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticationSection() {
    return _buildSection(
      title: 'المصادقة والتحقق',
      icon: Icons.verified_user,
      children: [
        _buildSwitchTile(
          title: 'البصمة الحيوية',
          subtitle: 'استخدام بصمة الإصبع أو الوجه للدخول',
          value: _settings.biometricEnabled,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(biometricEnabled: value);
            });
          },
          icon: Icons.fingerprint,
        ),
        _buildSwitchTile(
          title: 'المصادقة الثنائية',
          subtitle: 'طبقة حماية إضافية للحساب',
          value: _settings.twoFactorEnabled,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(twoFactorEnabled: value);
            });
          },
          icon: Icons.security,
        ),
        _buildSwitchTile(
          title: 'القفل التلقائي',
          subtitle: 'قفل التطبيق تلقائياً عند عدم الاستخدام',
          value: _settings.autoLock,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(autoLock: value);
            });
          },
          icon: Icons.lock_clock,
        ),
        if (_settings.autoLock)
          _buildSliderTile(
            title: 'مهلة القفل التلقائي',
            subtitle: '${_settings.autoLockTimeout} دقيقة',
            value: _settings.autoLockTimeout.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(autoLockTimeout: value.round());
              });
            },
          ),
      ],
    );
  }

  Widget _buildDataProtectionSection() {
    return _buildSection(
      title: 'حماية البيانات',
      icon: Icons.shield,
      children: [
        _buildSwitchTile(
          title: 'تشفير البيانات',
          subtitle: 'تشفير جميع البيانات المحفوظة محلياً',
          value: _settings.dataEncryption,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(dataEncryption: value);
            });
          },
          icon: Icons.enhanced_encryption,
        ),
        _buildSwitchTile(
          title: 'تشفير الموقع',
          subtitle: 'حماية بيانات الموقع من التتبع',
          value: _settings.locationEncryption,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(locationEncryption: value);
            });
          },
          icon: Icons.location_on,
        ),
        _buildSwitchTile(
          title: 'النسخ الاحتياطي الآمن',
          subtitle: 'تشفير النسخ الاحتياطية في السحابة',
          value: _settings.secureBackup,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(secureBackup: value);
            });
          },
          icon: Icons.backup,
        ),
      ],
    );
  }

  Widget _buildMonitoringSection() {
    return _buildSection(
      title: 'المراقبة والكشف',
      icon: Icons.monitor,
      children: [
        _buildSwitchTile(
          title: 'كشف التهديدات',
          subtitle: 'مراقبة النشاطات المشبوهة والتهديدات',
          value: _settings.threatDetection,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(threatDetection: value);
            });
          },
          icon: Icons.warning,
        ),
        _buildSwitchTile(
          title: 'المراقبة في الوقت الفعلي',
          subtitle: 'فحص مستمر للأنشطة الأمنية',
          value: _settings.realTimeMonitoring,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(realTimeMonitoring: value);
            });
          },
          icon: Icons.radar,
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return _buildSection(
      title: 'الإعدادات المتقدمة',
      icon: Icons.settings,
      children: [
        _buildDropdownTile(
          title: 'مستوى الأمان الأدنى',
          subtitle: _settings.minimumSecurityLevel.displayName,
          value: _settings.minimumSecurityLevel,
          items: SecurityLevel.values,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(minimumSecurityLevel: value);
            });
          },
        ),
        _buildActionTile(
          title: 'إدارة الأذونات',
          subtitle: 'مراجعة وتعديل أذونات التطبيق',
          icon: Icons.admin_panel_settings,
          onTap: () => _showPermissionsDialog(),
        ),
        _buildActionTile(
          title: 'طرق المصادقة',
          subtitle: 'إدارة طرق تسجيل الدخول المتاحة',
          icon: Icons.login,
          onTap: () => _showAuthMethodsDialog(),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withAlpha(178),
            fontSize: 12,
          ),
        ),
        secondary: Icon(
          icon,
          color: Colors.white.withAlpha(204),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withOpacity(0.3),
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withAlpha(178),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: Colors.blue,
            inactiveColor: Colors.grey.withAlpha(76),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            items: items.map((item) {
              String displayText = '';
              if (item is SecurityLevel) {
                displayText = item.displayName;
              } else {
                displayText = item.toString();
              }
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  displayText,
                  style: const TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            dropdownColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        leading: Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white.withAlpha(153),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isSaving
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('جاري الحفظ...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save),
                  SizedBox(width: 8),
                  Text(
                    'حفظ الإعدادات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showPermissionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدارة الأذونات'),
        content: const Text(
          'هذه الميزة ستتيح لك مراجعة وتعديل أذونات التطبيق المختلفة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // فتح إعدادات الأذونات
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  void _showAuthMethodsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طرق المصادقة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AuthenticationMethod.values.map((method) {
            final isEnabled = _settings.enabledMethods.contains(method);
            return CheckboxListTile(
              title: Text(method.displayName),
              value: isEnabled,
              onChanged: (value) {
                setState(() {
                  final methods = List<AuthenticationMethod>.from(_settings.enabledMethods);
                  if (value == true) {
                    methods.add(method);
                  } else {
                    methods.remove(method);
                  }
                  _settings = _settings.copyWith(enabledMethods: methods);
                });
                Navigator.pop(context);
                _showAuthMethodsDialog();
              },
            );
          }).toList(),
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
}