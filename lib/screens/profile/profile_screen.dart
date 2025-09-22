import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reports_provider.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';
import '../settings/notifications_settings_screen.dart';
import '../settings/privacy_settings_screen.dart';
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

  Future<void> _updateProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.updateUserProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (success) {
      setState(() {
        _isEditing = false;
      });
      _showSuccessSnackBar('تم تحديث الملف الشخصي بنجاح');
    } else {
      _showErrorSnackBar(authProvider.errorMessage ?? 'خطأ في تحديث الملف الشخصي');
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
                            onTap: () => setState(() => _isEditing = true),
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
                                setState(() {
                                  _isEditing = false;
                                  _loadUserData();
                                });
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
                    _buildSettingsTile(Icons.privacy_tip, 'الخصوصية', 'إعدادات الخصوصية والأمان', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacySettingsScreen(),
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
                      color: LiquidGlassTheme.getTextColor('secondary')?.withOpacity(0.1),
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
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Statistics Cards
              LiquidGlassContainer(
                type: LiquidGlassType.ultraLight,
                isInteractive: true,
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(20),
                child: Column(
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
              
              // Badges
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
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (totalReports >= 5) _buildBadge('🥉', 'أول 5 بلاغات'),
                          if (totalReports >= 10) _buildBadge('🥈', 'أول 10 بلاغات'),
                          if (totalReports >= 25) _buildBadge('🥇', 'أول 25 بلاغ'),
                          if (accuracy >= 80) _buildBadge('🎯', 'دقة عالية'),
                          if (activeReports >= 5) _buildBadge('🔥', 'مساهم نشط'),
                        ],
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