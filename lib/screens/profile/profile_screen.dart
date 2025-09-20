import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reports_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      extendBody: true,
      appBar: AppBar(
        title: Text(
          'الملف الشخصي',
          style: LiquidGlassTheme.primaryTextStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: LiquidGlassTheme.primaryTextStyle.color),
        actions: [
          if (_isEditing)
            LiquidGlassButton(
              text: 'إلغاء',
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadUserData(); // Reset data
                });
              },
              type: LiquidGlassType.secondary,
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          const SizedBox(width: 8),
          LiquidGlassButton(
            onPressed: _signOut,
            type: LiquidGlassType.primary,
            borderRadius: 12,
            padding: const EdgeInsets.all(8),
            icon: Icons.logout,
            text: '',
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: LiquidGlassTheme.secondaryTextStyle.color,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'المعلومات'),
            Tab(text: 'بلاغاتي'),
            Tab(text: 'الإحصائيات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildReportsTab(),
          _buildStatsTab(),
        ],
      ),

    );
  }

  Widget _buildProfileTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.userModel == null) {
          return const Center(
            child: Text('لا توجد معلومات مستخدم'),
          );
        }

        final user = authProvider.userModel!;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Picture
              LiquidGlassContainer(
                type: LiquidGlassType.primary,
                borderRadius: BorderRadius.circular(60),
                padding: const EdgeInsets.all(20),
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // User Info Card
              LiquidGlassContainer(
                type: LiquidGlassType.secondary,
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (_isEditing) ...[
                      CustomTextField(
                        controller: _nameController,
                        label: 'الاسم',
                        hintText: 'أدخل اسمك',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال الاسم';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'رقم الهاتف',
                        hintText: 'أدخل رقم هاتفك',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      LiquidGlassButton(
                        text: 'حفظ التغييرات',
                        onPressed: _updateProfile,
                        type: LiquidGlassType.primary,
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ] else ...[
                      _buildInfoRow('الاسم', user.name),
                      const Divider(height: 32),
                      _buildInfoRow('البريد الإلكتروني', user.email),
                      const Divider(height: 32),
                      _buildInfoRow('رقم الهاتف', user.phone ?? 'غير محدد'),
                      const Divider(height: 32),
                      _buildInfoRow('تاريخ التسجيل', _formatDate(user.createdAt)),
                      const SizedBox(height: 24),
                      LiquidGlassButton(
                        text: 'تعديل المعلومات',
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        type: LiquidGlassType.secondary,
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, child) {
        final userReports = reportsProvider.userReports;
        
        if (userReports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.report_outlined,
                  size: 64,
                  color: LiquidGlassTheme.secondaryTextStyle.color?.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد بلاغات',
                  style: LiquidGlassTheme.secondaryTextStyle.copyWith(
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
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
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildStatCard('إجمالي البلاغات', totalReports.toString(), Icons.report, LiquidGlassTheme.adaptiveTextColor),
              const SizedBox(height: 16),
              _buildStatCard('البلاغات النشطة', activeReports.toString(), Icons.check_circle, Colors.green),
              const SizedBox(height: 16),
              _buildStatCard('البلاغات المؤكدة', confirmedReports.toString(), Icons.verified, Colors.orange),
              const SizedBox(height: 16),
              _buildStatCard('معدل التأكيد', '${totalReports > 0 ? ((confirmedReports / totalReports) * 100).toStringAsFixed(1) : '0'}%', Icons.trending_up, Colors.purple),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: LiquidGlassTheme.secondaryTextStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: LiquidGlassTheme.primaryTextStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: LiquidGlassContainer(
        type: LiquidGlassType.secondary,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Icon(
                _getReportIcon(report.type),
                color: _getReportColor(report.type),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getReportTypeTitle(report.type),
                  style: LiquidGlassTheme.primaryTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(report.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusTitle(report.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(report.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.description,
            style: LiquidGlassTheme.secondaryTextStyle.copyWith(
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: LiquidGlassTheme.secondaryTextStyle.color,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(report.createdAt),
                style: LiquidGlassTheme.secondaryTextStyle.copyWith(
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.thumb_up,
                    size: 14,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    report.confirmations.trueVotes.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.thumb_down,
                    size: 14,
                    color: Colors.red[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    report.confirmations.falseVotes.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return LiquidGlassContainer(
      type: LiquidGlassType.secondary,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          LiquidGlassContainer(
            type: LiquidGlassType.primary,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LiquidGlassTheme.secondaryTextStyle.copyWith(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: LiquidGlassTheme.primaryTextStyle.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        return Colors.red;
      case ReportType.jam:
        return Colors.orange;
      case ReportType.carBreakdown:
        return Colors.blue;
      case ReportType.bump:
        return Colors.amber;
      case ReportType.closedRoad:
        return Colors.purple;
      default:
        return Colors.grey;
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
        return Colors.green;
      case ReportStatus.removed:
        return Colors.blue;
      case ReportStatus.expired:
        return Colors.grey;
      default:
        return Colors.grey;
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