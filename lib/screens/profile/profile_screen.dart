import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reports_provider.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';
import '../settings/notifications_settings_screen.dart';
import '../settings/help_support_screen.dart';
import '../../models/report_model.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _loadUserReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel != null) {
      _nameController.text = authProvider.userModel!.name;
      _phoneController.text = authProvider.userModel!.phone ?? '';
    }
  }

  void _loadUserReports() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userId != null) {
      final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
      reportsProvider.loadUserReports(authProvider.userId!);
    }
  }

  Future<void> _updateProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.updateUserProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (success) {
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        _showSuccessSnackBar('تم تحديث الملف الشخصي بنجاح');
      }
    } else {
      if (mounted) {
        _showErrorSnackBar(authProvider.errorMessage ?? 'خطأ في تحديث الملف الشخصي');
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await _showConfirmDialog('تسجيل الخروج', 'هل أنت متأكد من تسجيل الخروج؟');
    if (confirmed) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LiquidGlassTheme.backgroundColor,
        title: Text(title, style: LiquidGlassTheme.headerTextStyle),
        content: Text(content, style: LiquidGlassTheme.bodyTextStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('إلغاء', style: TextStyle(color: LiquidGlassTheme.getTextColor('secondary'))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('تأكيد', style: TextStyle(color: LiquidGlassTheme.getGradientByName('danger').colors.first)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LiquidGlassTheme.getGradientByName('danger').colors.first,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LiquidGlassTheme.getGradientByName('success').colors.first,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.userModel == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authProvider.userModel!;
          
          return CustomScrollView(
            slivers: [
              // Modern Profile Header
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: IconButton(
                      onPressed: _signOut,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.logout, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LiquidGlassTheme.getGradientByName('primary'),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Profile Avatar
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // User Name
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            // User Email
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Tab Navigation
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 60,
                  maxHeight: 60,
                  child: Container(
                    color: LiquidGlassTheme.backgroundColor,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: (LiquidGlassTheme.getTextColor('secondary') ?? Colors.grey).withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: LiquidGlassTheme.getGradientByName('primary').colors.first,
                        unselectedLabelColor: LiquidGlassTheme.getTextColor('secondary'),
                        indicatorColor: LiquidGlassTheme.getGradientByName('primary').colors.first,
                        indicatorWeight: 2,
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        tabs: const [
                          Tab(icon: Icon(Icons.person, size: 20), text: 'المعلومات'),
                          Tab(icon: Icon(Icons.report, size: 20), text: 'البلاغات'),
                          Tab(icon: Icon(Icons.analytics, size: 20), text: 'الإحصائيات'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Tab Content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProfileTab(),
                    _buildReportsTab(),
                    _buildStatsTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel!;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Personal Information Card
              LiquidGlassContainer(
                type: LiquidGlassType.secondary,
                isInteractive: true,
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المعلومات الشخصية',
                          style: LiquidGlassTheme.headerTextStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isEditing)
                          GestureDetector(
                            onTap: () {
                              if (mounted) {
                                setState(() => _isEditing = true);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: LiquidGlassTheme.getGradientByName('primary').colors.first.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: LiquidGlassTheme.getGradientByName('primary').colors.first,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    if (_isEditing) ...[
                      _buildEditableField('الاسم', _nameController, Icons.person),
                      const SizedBox(height: 16),
                      _buildEditableField('رقم الهاتف', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: LiquidGlassButton(
                              text: 'حفظ',
                              onPressed: _updateProfile,
                              type: LiquidGlassType.primary,
                              borderRadius: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LiquidGlassButton(
                              text: 'إلغاء',
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    _isEditing = false;
                                    _loadUserData();
                                  });
                                }
                              },
                              type: LiquidGlassType.secondary,
                              borderRadius: 12,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildInfoTile(Icons.person, 'الاسم', user.name),
                      const SizedBox(height: 16),
                      _buildInfoTile(Icons.email, 'البريد الإلكتروني', user.email),
                      const SizedBox(height: 16),
                      _buildInfoTile(Icons.phone, 'رقم الهاتف', user.phone ?? 'غير محدد'),
                      const SizedBox(height: 16),
                      _buildInfoTile(Icons.calendar_today, 'تاريخ التسجيل', _formatDate(user.createdAt)),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Settings Card
              LiquidGlassContainer(
                type: LiquidGlassType.secondary,
                isInteractive: true,
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإعدادات',
                      style: LiquidGlassTheme.headerTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsTile(Icons.notifications, 'الإشعارات', 'إدارة إشعارات التطبيق', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsSettingsScreen(),
                        ),
                      );
                    }),
                    
                    _buildSettingsTile(Icons.help, 'المساعدة', 'الحصول على المساعدة والدعم', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    }),
                    _buildSettingsTile(
                      Icons.logout, 
                      'تسجيل الخروج', 
                      'تسجيل الخروج من الحساب',
                      _signOut,
                      textColor: LiquidGlassTheme.getGradientByName('danger').colors.first,
                    ),
                  ],
                ),
              ),
              
              // Bottom spacing for navigation bar
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: LiquidGlassTheme.bodyTextStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        LiquidGlassContainer(
          type: LiquidGlassType.primary,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: LiquidGlassTheme.primaryTextStyle,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: LiquidGlassTheme.getTextColor('secondary')),
              border: InputBorder.none,
              hintText: 'أدخل $label',
              hintStyle: TextStyle(color: LiquidGlassTheme.getTextColor('secondary')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LiquidGlassTheme.getGradientByName('primary').colors.first.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LiquidGlassTheme.getGradientByName('primary').colors.first.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: LiquidGlassTheme.getGradientByName('primary').colors.first),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback onTap, {Color? textColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (textColor ?? LiquidGlassTheme.getTextColor('primary')).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: textColor ?? LiquidGlassTheme.getTextColor('primary'), size: 20),
        ),
        title: Text(title, style: LiquidGlassTheme.headerTextStyle.copyWith(color: textColor, fontSize: 14)),
        subtitle: Text(subtitle, style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: LiquidGlassTheme.getTextColor('secondary'), size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildReportsTab() {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, child) {
        final userReports = reportsProvider.userReports;
        
        if (userReports.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (LiquidGlassTheme.getTextColor('secondary') ?? Colors.grey).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.report_outlined,
                      size: 48,
                      color: LiquidGlassTheme.getTextColor('secondary'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد بلاغات',
                    style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ابدأ بالإبلاغ عن المخاطر لتحسين السلامة',
                    style: LiquidGlassTheme.bodyTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: userReports.length,
          itemBuilder: (context, index) {
            final report = userReports[index];
            return _buildReportCard(report);
          },
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, child) {
        final userReports = reportsProvider.userReports;
        final totalReports = userReports.length;
        final activeReports = userReports.where((r) => r.status == ReportStatus.active).length;
        final confirmedReports = userReports.where((r) => r.confirmations.trueVotes > r.confirmations.falseVotes).length;
        final accuracy = totalReports > 0 ? (confirmedReports / totalReports * 100) : 0.0;
        
        // تصنيف البلاغات حسب النوع
        final Map<String, int> reportsByType = {};
        for (var report in userReports) {
          final type = report.type.toString().split('.').last;
          reportsByType[type] = (reportsByType[type] ?? 0) + 1;
        }
        
        // حساب مستوى المستخدم
        final int userLevel = _calculateUserLevel(totalReports);
        final double progressToNextLevel = _calculateProgressToNextLevel(totalReports);
        
        // تجميع البلاغات حسب الشهر للرسم البياني
        final Map<String, int> reportsByMonth = _getReportsByMonth(userReports);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مستوى المستخدم وتقدمه
              LiquidGlassContainer(
                type: LiquidGlassType.ultraLight,
                isInteractive: true,
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المستوى $userLevel',
                          style: LiquidGlassTheme.headerTextStyle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LiquidGlassTheme.getGradientByName('primary'),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getUserRank(userLevel),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'التقدم للمستوى التالي',
                      style: LiquidGlassTheme.bodyTextStyle,
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Container(
                          height: 10,
                          width: MediaQuery.of(context).size.width * progressToNextLevel * 0.8, // 0.8 to account for padding
                          decoration: BoxDecoration(
                            gradient: LiquidGlassTheme.getGradientByName('primary'),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progressToNextLevel * 100).toStringAsFixed(0)}% مكتمل',
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                        fontSize: 12,
                        color: LiquidGlassTheme.getTextColor('secondary'),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Statistics Cards
              LiquidGlassContainer(
                type: LiquidGlassType.ultraLight,
                isInteractive: true,
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إحصائياتك',
                      style: LiquidGlassTheme.headerTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('إجمالي البلاغات', totalReports.toString(), Icons.report, LiquidGlassTheme.getGradientByName('primary').colors.first)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('النشطة', activeReports.toString(), Icons.check_circle, LiquidGlassTheme.getGradientByName('success').colors.first)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('المؤكدة', confirmedReports.toString(), Icons.verified, LiquidGlassTheme.getGradientByName('warning').colors.first)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('الدقة', '${accuracy.toStringAsFixed(1)}%', Icons.trending_up, LiquidGlassTheme.getGradientByName('info').colors.first)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // رسم بياني لتطور البلاغات
              if (reportsByMonth.isNotEmpty)
                LiquidGlassContainer(
                  type: LiquidGlassType.ultraLight,
                  isInteractive: true,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تطور البلاغات',
                        style: LiquidGlassTheme.headerTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: _buildReportsChart(reportsByMonth),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // تصنيف البلاغات حسب النوع
              if (reportsByType.isNotEmpty)
                LiquidGlassContainer(
                  type: LiquidGlassType.ultraLight,
                  isInteractive: true,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أنواع البلاغات',
                        style: LiquidGlassTheme.headerTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...reportsByType.entries.map((entry) => _buildReportTypeItem(
                        entry.key, 
                        entry.value, 
                        totalReports,
                        _getColorForReportType(entry.key),
                      )).toList(),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // الشارات المكتسبة
              if (totalReports > 0) 
                LiquidGlassContainer(
                  type: LiquidGlassType.ultraLight,
                  isInteractive: true,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الشارات المكتسبة',
                        style: LiquidGlassTheme.headerTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (totalReports >= 5) _buildEnhancedBadge('🥉', 'مبلغ برونزي', 'أول 5 بلاغات', Colors.brown.shade300),
                          if (totalReports >= 10) _buildEnhancedBadge('🥈', 'مبلغ فضي', 'أول 10 بلاغات', Colors.grey.shade400),
                          if (totalReports >= 25) _buildEnhancedBadge('🥇', 'مبلغ ذهبي', 'أول 25 بلاغ', Colors.amber),
                          if (accuracy >= 80) _buildEnhancedBadge('🎯', 'دقة عالية', 'دقة أكثر من 80%', Colors.blue),
                          if (activeReports >= 5) _buildEnhancedBadge('🔥', 'مساهم نشط', '5 بلاغات نشطة', Colors.orange),
                          if (totalReports >= 50) _buildEnhancedBadge('💎', 'مبلغ ماسي', 'أول 50 بلاغ', Colors.cyan),
                        ],
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // الإنجازات والتحديات
              LiquidGlassContainer(
                type: LiquidGlassType.ultraLight,
                isInteractive: true,
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإنجازات والتحديات',
                      style: LiquidGlassTheme.headerTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAchievementItem(
                      'مبلغ متميز',
                      'أبلغ عن 100 حادث',
                      totalReports,
                      100,
                      Icons.star,
                      LiquidGlassTheme.getGradientByName('primary').colors.first,
                    ),
                    const SizedBox(height: 12),
                    _buildAchievementItem(
                      'عين الصقر',
                      'حقق دقة 90% في البلاغات',
                      accuracy.toInt(),
                      90,
                      Icons.visibility,
                      LiquidGlassTheme.getGradientByName('info').colors.first,
                    ),
                    const SizedBox(height: 12),
                    _buildAchievementItem(
                      'حامي الطريق',
                      'أبلغ عن 20 حادث',
                      userReports.where((r) => r.type == ReportType.accident).length,
                      20,
                      Icons.security,
                      LiquidGlassTheme.getGradientByName('danger').colors.first,
                    ),
                    const SizedBox(height: 12),
                    _buildAchievementItem(
                      'مستكشف المدينة',
                      'أبلغ في 5 مناطق مختلفة',
                      userReports.length > 0 ? math.min(5, userReports.length) : 0,
                      5,
                      Icons.explore,
                      LiquidGlassTheme.getGradientByName('warning').colors.first,
                    ),
                  ],
                ),
              ),
              
              // Bottom spacing
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }
  
  // دالة لحساب مستوى المستخدم بناءً على عدد البلاغات
  int _calculateUserLevel(int totalReports) {
    if (totalReports <= 0) return 1;
    return (math.sqrt(totalReports) / 2).ceil() + 1;
  }
  
  // دالة لحساب نسبة التقدم للمستوى التالي
  double _calculateProgressToNextLevel(int totalReports) {
    final currentLevel = _calculateUserLevel(totalReports);
    final reportsForCurrentLevel = math.pow(((currentLevel - 1) * 2), 2).toInt();
    final reportsForNextLevel = math.pow((currentLevel * 2), 2).toInt();
    final reportsNeeded = reportsForNextLevel - reportsForCurrentLevel;
    final progress = (totalReports - reportsForCurrentLevel) / reportsNeeded;
    return progress.clamp(0.0, 1.0);
  }
  
  // دالة لتحديد رتبة المستخدم بناءً على المستوى
  String _getUserRank(int level) {
    if (level <= 2) return 'مبتدئ';
    if (level <= 4) return 'متوسط';
    if (level <= 6) return 'متقدم';
    if (level <= 8) return 'خبير';
    if (level <= 10) return 'محترف';
    return 'أسطورة';
  }
  
  // دالة لتجميع البلاغات حسب الشهر
  Map<String, int> _getReportsByMonth(List<ReportModel> reports) {
    final Map<String, int> result = {};
    final months = ['يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    
    // تجميع آخر 6 أشهر فقط
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final month = now.month - i <= 0 ? now.month - i + 12 : now.month - i;
      final year = now.month - i <= 0 ? now.year - 1 : now.year;
      final key = '${months[month - 1]}';
      result[key] = 0;
    }
    
    for (var report in reports) {
      final reportDate = report.createdAt;
      if (reportDate != null) {
        final month = reportDate.month;
        final year = reportDate.year;
        final now = DateTime.now();
        
        // فقط البلاغات من آخر 6 أشهر
        if (year == now.year && month > now.month - 6 || 
            year == now.year - 1 && now.month < 6 && month > 12 - (6 - now.month)) {
          final key = '${months[month - 1]}';
          result[key] = (result[key] ?? 0) + 1;
        }
      }
    }
    
    return result;
  }
  
  // دالة لإنشاء رسم بياني للبلاغات
  Widget _buildReportsChart(Map<String, int> reportsByMonth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: reportsByMonth.entries.map((entry) {
        final maxValue = reportsByMonth.values.reduce((a, b) => a > b ? a : b);
        final height = maxValue > 0 ? (entry.value / maxValue) * 150 : 0.0;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 30,
              height: height,
              decoration: BoxDecoration(
                gradient: LiquidGlassTheme.getGradientByName('primary'),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.key,
              style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 4),
            Text(
              entry.value.toString(),
              style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
  
  // دالة لإنشاء عنصر نوع البلاغ
  Widget _buildReportTypeItem(String type, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getArabicReportType(type),
                style: LiquidGlassTheme.bodyTextStyle.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                '$count (${percentage.toStringAsFixed(1)}%)',
                style: LiquidGlassTheme.bodyTextStyle.copyWith(
                  color: LiquidGlassTheme.getTextColor('secondary'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width: MediaQuery.of(context).size.width * (percentage / 100) * 0.8, // 0.8 to account for padding
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // دالة للحصول على اسم نوع البلاغ بالعربية
  String _getArabicReportType(String type) {
    switch (type) {
      case 'accident': return 'حادث';
      case 'traffic': return 'ازدحام';
      case 'roadClosure': return 'إغلاق طريق';
      case 'roadwork': return 'أعمال طريق';
      case 'hazard': return 'خطر';
      case 'police': return 'نقطة أمنية';
      case 'flood': return 'فيضان';
      case 'fire': return 'حريق';
      case 'speedBump': return 'مطب';
      case 'construction': return 'إنشاءات';
      default: return type;
    }
  }
  
  // دالة للحصول على لون مناسب لنوع البلاغ
  Color _getColorForReportType(String type) {
    switch (type) {
      case 'accident': return Colors.red;
      case 'traffic': return Colors.orange;
      case 'roadClosure': return Colors.purple;
      case 'roadwork': return Colors.amber;
      case 'hazard': return Colors.red.shade800;
      case 'police': return Colors.blue;
      case 'flood': return Colors.blue.shade700;
      case 'fire': return Colors.deepOrange;
      case 'speedBump': return Colors.brown;
      case 'construction': return Colors.amber.shade800;
      default: return LiquidGlassTheme.getGradientByName('primary').colors.first;
    }
  }
  
  // دالة لإنشاء شارة محسنة
  Widget _buildEnhancedBadge(String emoji, String title, String description, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.28,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            title,
            style: LiquidGlassTheme.headerTextStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: LiquidGlassTheme.bodyTextStyle.copyWith(
              fontSize: 10,
              color: LiquidGlassTheme.getTextColor('secondary'),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // دالة لإنشاء عنصر إنجاز
  Widget _buildAchievementItem(String title, String description, int current, int target, IconData icon, Color color) {
    final progress = (current / target).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 14),
                    ),
                    Text(
                      description,
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                        fontSize: 12,
                        color: LiquidGlassTheme.getTextColor('secondary'),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$current/$target',
                style: LiquidGlassTheme.headerTextStyle.copyWith(
                  fontSize: 14,
                  color: progress >= 1.0 ? color : LiquidGlassTheme.getTextColor('secondary'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                height: 6,
                width: MediaQuery.of(context).size.width * progress * 0.8, // 0.8 to account for padding
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return LiquidGlassContainer(
      type: LiquidGlassType.ultraLight,
      isInteractive: true,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: LiquidGlassTheme.headerTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LiquidGlassTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: LiquidGlassTheme.headerTextStyle.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: LiquidGlassTheme.primaryTextColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String emoji, String title) {
    return LiquidGlassContainer(
      type: LiquidGlassType.ultraLight,
      isInteractive: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              title,
              style: LiquidGlassTheme.headerTextStyle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: LiquidGlassContainer(
        type: LiquidGlassType.secondary,
        isInteractive: true,
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getReportColor(report.type).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getReportIcon(report.type), 
                color: _getReportColor(report.type), 
                size: 20
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getReportTypeTitle(report.type),
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(report.createdAt),
                    style: LiquidGlassTheme.bodyTextStyle.copyWith(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(report.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusTitle(report.status),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(report.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return Icons.car_crash;
      case ReportType.jam:
        return Icons.traffic;
      case ReportType.carBreakdown:
        return Icons.car_repair;
      case ReportType.bump:
        return Icons.warning;
      case ReportType.closedRoad:
        return Icons.block;
      default:
        return Icons.report;
    }
  }

  Color _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return LiquidGlassTheme.getGradientByName('danger').colors.first;
      case ReportType.jam:
        return LiquidGlassTheme.getGradientByName('warning').colors.first;
      case ReportType.carBreakdown:
        return LiquidGlassTheme.getGradientByName('info').colors.first;
      case ReportType.bump:
        return LiquidGlassTheme.getGradientByName('warning').colors.last;
      case ReportType.closedRoad:
        return LiquidGlassTheme.getGradientByName('primary').colors.first;
      default:
        return LiquidGlassTheme.getTextColor('secondary') ?? Colors.grey;
    }
  }

  String _getReportTypeTitle(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return 'حادث مروري';
      case ReportType.jam:
        return 'ازدحام مروري';
      case ReportType.carBreakdown:
        return 'عطل مركبة';
      case ReportType.bump:
        return 'مطب';
      case ReportType.closedRoad:
        return 'طريق مغلق';
      default:
        return 'بلاغ';
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.active:
        return LiquidGlassTheme.getGradientByName('success').colors.first;
      case ReportStatus.removed:
        return LiquidGlassTheme.getGradientByName('info').colors.first;
      case ReportStatus.expired:
        return LiquidGlassTheme.getTextColor('secondary') ?? Colors.grey;
      default:
        return LiquidGlassTheme.getTextColor('secondary') ?? Colors.grey;
    }
  }

  String _getStatusTitle(ReportStatus status) {
    switch (status) {
      case ReportStatus.active:
        return 'نشط';
      case ReportStatus.removed:
        return 'محذوف';
      case ReportStatus.expired:
        return 'منتهي الصلاحية';
      default:
        return 'غير معروف';
    }
  }
}

// Helper for SliverAppBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}