import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as AuthProviderCustom;
import '../../providers/reports_provider.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';
import '../settings/notifications_settings_screen.dart';
import '../settings/help_support_screen.dart';
import '../../models/report_model.dart';
import '../../models/rewards_model.dart';
import '../../services/rewards_service.dart';
import '../../services/user_service.dart';
import '../../services/user_statistics_service.dart';
import '../../models/user_statistics_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saferoute/models/user_model.dart';

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

  // خدمة المستخدم للتعامل مع Firestore
  final UserService _userService = UserService();
  final UserStatisticsService _statisticsService = UserStatisticsService();

  // متغيرات نظام النقاط والمكافآت
  final RewardsService _rewardsService = RewardsService();
  PointsModel? _userPoints;
  List<RewardModel> _availableRewards = [];
  List<UserRewardModel> _userRewards = [];
  bool _isLoading = false;

  // متغيرات الإحصائيات
  UserStatistics? _userStatistics;
  int _activeReports = 0;
  int _confirmedReports = 0;
  double _accuracyRate = 0.0;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // تأخير استدعاء الدوال التي تحتوي على setState لتجنب مشكلة setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _loadUserReports();
      _loadUserPoints();
    });
  }

  // إشعار توضيحي للمكافآت التجريبية
  Widget _buildDemoNotice() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: LiquidGlassContainer(
        type: LiquidGlassType.secondary,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: Colors.amber.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نسخة تجريبية - فكرة للمستقبل',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: LiquidGlassTheme.getTextColor('primary'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'مكافآت الشراكات مع البراندات',
                        style: TextStyle(
                          fontSize: 14,
                          color: LiquidGlassTheme.getTextColor('secondary'),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LiquidGlassTheme.getGradientByName('primary').colors.first.withAlpha(12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: LiquidGlassTheme.getGradientByName('primary').colors.first.withAlpha(50),
                  width: 1,
                ),
              ),
              child: Text(
                'هذه مجرد فكرة بسيطة يمكن التوسع فيها مستقبلاً عند نمو المشروع. الشراكات مع البراندات والمتاجر ستكون متاحة عند زيادة عدد المستخدمين وتطوير النظام أكثر.',
                style: TextStyle(
                  fontSize: 15,
                  color: LiquidGlassTheme.getTextColor('primary'),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء مكافآت البراندات التجريبية
  Widget _buildDemoBrandRewards() {
    final demoBrands = [
      {
        'name': 'كارفور',
        'discount': '15%',
        'points': 0, // تقليل النقاط المطلوبة
        'code': 'SAFE15',
        'icon': '🛒',
        'description': 'خصم على جميع المنتجات',
        'color': Colors.blue,
      },
      {
        'name': 'ماكدونالدز',
        'discount': '20%',
        'points': 50, // تقليل النقاط المطلوبة
        'code': 'SAFE20',
        'icon': '🍔',
        'description': 'خصم على الوجبات',
        'color': Colors.red,
      },
      {
        'name': 'أوبر',
        'discount': '25 جنيه',
        'points': 150, // تقليل النقاط المطلوبة
        'code': 'SAFEUBER',
        'icon': '🚗',
        'description': 'خصم على الرحلات',
        'color': Colors.black,
      },
      {
        'name': 'نون',
        'discount': '10%',
        'points': 75, // تقليل النقاط المطلوبة
        'code': 'NOON10',
        'icon': '📦',
        'description': 'خصم على التسوق الإلكتروني',
        'color': Colors.purple,
      },
      {
        'name': 'ستاربكس',
        'discount': '30%',
        'points': 25, // تقليل النقاط المطلوبة
        'code': 'COFFEE30',
        'icon': '☕',
        'description': 'خصم على المشروبات',
        'color': Colors.green,
      },
    ];

    return Column(
      children: demoBrands.map((brand) => _buildDemoBrandCard(brand)).toList(),
    );
  }

  // بطاقة براند تجريبية
  Widget _buildDemoBrandCard(Map<String, dynamic> brand) {
    final userPoints = _userPoints?.points ?? 0;
    final canRedeem = userPoints >= brand['points'];

    return LiquidGlassContainer(
      type: LiquidGlassType.secondary,
      isInteractive: true,
      borderRadius: BorderRadius.circular(16),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (brand['color'] as Color).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    brand['icon'],
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          brand['name'],
                          style: LiquidGlassTheme.headerTextStyle.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'تجريبي',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      brand['description'],
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                        color: LiquidGlassTheme.getTextColor('secondary'),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (brand['color'] as Color).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'خصم ${brand['discount']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: brand['color'],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${brand['points']} نقطة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LiquidGlassTheme.getGradientByName(
                    'primary',
                  ).colors.first,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // عرض النقاط المطلوبة والحالية
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: canRedeem 
                  ? Colors.green.withAlpha(25)
                  : Colors.orange.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: canRedeem 
                    ? Colors.green.shade300
                    : Colors.orange.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  canRedeem ? Icons.check_circle : Icons.info_outline,
                  color: canRedeem 
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    canRedeem 
                        ? 'يمكنك استبدال هذه المكافأة!'
                        : 'تحتاج ${brand['points'] - userPoints} نقطة إضافية',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: canRedeem 
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
                Text(
                  '$userPoints / ${brand['points']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: canRedeem 
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: canRedeem 
                        ? Colors.grey.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: canRedeem 
                          ? Colors.grey.shade300
                          : Colors.grey.shade400,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'الكود: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      canRedeem 
                          ? Text(
                              brand['code'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '••••••',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                      const Spacer(),
                      Icon(
                        canRedeem ? Icons.copy : Icons.lock,
                        size: 16,
                        color: canRedeem 
                            ? Colors.grey.shade600
                            : Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              LiquidGlassButton(
                onPressed: canRedeem ? () => _showDemoRedeemDialog(brand) : null,
                text: canRedeem ? 'استبدال' : 'نقاط غير كافية',
                type: canRedeem
                    ? LiquidGlassType.primary
                    : LiquidGlassType.secondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // عرض حوار الاستبدال التجريبي
  void _showDemoRedeemDialog(Map<String, dynamic> brand) {
    final userPoints = _userPoints?.points ?? 0;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Text(brand['icon'], style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'استبدال مكافأة ${brand['name']}',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'هذه نسخة تجريبية. في النسخة الحقيقية ستحصل على كود خصم فعلي.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تفاصيل المكافأة:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text('• خصم: ${brand['discount']}'),
              Text('• النقاط المطلوبة: ${brand['points']}'),
              Text('• نقاطك الحالية: $userPoints'),
              Text('• الكود التجريبي: ${brand['code']}'),
              Text('• ${brand['description']}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيتم خصم ${brand['points']} نقطة من رصيدك',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessSnackBar(
                  'تم الاستبدال التجريبي بنجاح! الكود: ${brand['code']}',
                );
                // في التطبيق الحقيقي، سيتم خصم النقاط هنا
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LiquidGlassTheme.getGradientByName(
                  'primary',
                ).colors.first,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('استبدال تجريبي'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // تحميل نقاط المستخدم والمكافآت المتاحة
  Future<void> _loadUserPoints() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // تحميل نقاط المستخدم
      final points = await _rewardsService.getUserPoints(
        FirebaseAuth.instance.currentUser!.uid,
      );

      // تحميل المكافآت المتاحة
      final rewards = await _rewardsService.getAvailableRewards();

      // تحميل مكافآت المستخدم المستخدمة
      final userRewards = await _rewardsService.getUserRewards(
        FirebaseAuth.instance.currentUser!.uid,
      );

      if (mounted) {
        setState(() {
          _userPoints = points;
          _availableRewards = rewards;
          _userRewards = userRewards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading user points: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProviderCustom.AuthProvider>(
        context,
        listen: false,
      );

      // استخدام خدمة المستخدم للحصول على البيانات من Firestore
      final userData = await _userService.getCurrentUserData();

      if (userData != null) {
        if (mounted) {
          setState(() {
            _nameController.text = userData.name;
            _phoneController.text = userData.phone ?? '';
          });
        }
      } else if (authProvider.userModel != null) {
        // استخدام البيانات من AuthProvider كاحتياطي
        if (mounted) {
          setState(() {
            _nameController.text = authProvider.userModel?.name ?? '';
            _phoneController.text = authProvider.userModel?.phone ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Fallback to empty values
      if (mounted) {
        setState(() {
          _nameController.text = '';
          _phoneController.text = '';
        });
      }
    }
  }

  Future<void> _loadUserReports() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      print('ProfileScreen: _loadUserReports called');
      final authProvider = Provider.of<AuthProviderCustom.AuthProvider>(
        context,
        listen: false,
      );
      
      print('ProfileScreen: userId = ${authProvider.userId}');
      
      if (authProvider.userId != null) {
        final reportsProvider = Provider.of<ReportsProvider>(
          context,
          listen: false,
        );
        
        print('ProfileScreen: Loading user reports for userId: ${authProvider.userId}');
        await reportsProvider.loadUserReports(authProvider.userId!);
        
        // حساب الإحصائيات بعد تحميل البلاغات
        if (reportsProvider.userReports.isNotEmpty) {
          _calculateUserStatistics(reportsProvider.userReports);
          print('ProfileScreen: Calculated statistics for ${reportsProvider.userReports.length} reports');
        } else {
          print('ProfileScreen: No reports found for user');
          // إنشاء إحصائيات فارغة
          if (mounted) {
            setState(() {
              _userStatistics = UserStatistics(
                totalReports: 0,
                confirmedReports: 0,
                rejectedReports: 0,
                activeReports: 0,
                expiredReports: 0,
                confirmationRate: 0.0,
                reportsByType: {},
                reportsByStatus: {},
              );
            });
          }
        }
      } else {
        print('ProfileScreen: userId is null, cannot load reports');
      }
    } catch (e) {
      print('ProfileScreen: Error loading user reports: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    final authProvider = Provider.of<AuthProviderCustom.AuthProvider>(
      context,
      listen: false,
    );
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      _showErrorSnackBar('لم يتم العثور على المستخدم');
      return;
    }

    // استخدام خدمة المستخدم لتحديث البيانات في Firestore
    final success = await _userService.updateUserProfile(
      userId: userId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    // تحديث البيانات في AuthProvider أيضًا للتوافق
    if (success) {
      await authProvider.updateUserProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        _showSuccessSnackBar('تم تحديث الملف الشخصي بنجاح');
      }
    } else {
      if (mounted) {
        _showErrorSnackBar('خطأ في تحديث الملف الشخصي');
      }
    }
  }

  // حساب إحصائيات المستخدم
  void _calculateUserStatistics(List<ReportModel> reports) {
    if (mounted) {
      setState(() {
        _userStatistics = _statisticsService.calculateUserStatistics(reports);
        _activeReports = _userStatistics?.activeReports ?? 0;
        _confirmedReports = _userStatistics?.confirmedReports ?? 0;
        _accuracyRate = _userStatistics?.confirmationRate ?? 0.0;
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await _showConfirmDialog(
      'تسجيل الخروج',
      'هل أنت متأكد من تسجيل الخروج؟',
    );
    if (confirmed) {
      final authProvider = Provider.of<AuthProviderCustom.AuthProvider>(
        context,
        listen: false,
      );
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
                child: Text(
                  'إلغاء',
                  style: TextStyle(
                    color: LiquidGlassTheme.getTextColor('secondary'),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'تأكيد',
                  style: TextStyle(
                    color: LiquidGlassTheme.getGradientByName(
                      'danger',
                    ).colors.first,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LiquidGlassTheme.getGradientByName(
          'danger',
        ).colors.first,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LiquidGlassTheme.getGradientByName(
          'success',
        ).colors.first,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      body: Consumer<AuthProviderCustom.AuthProvider>(
        builder: (context, authProvider, child) {
          // استخدام AuthProvider مباشرة بدلاً من StreamBuilder
          final user = authProvider.userModel ?? UserModel(
            id: '',
            email: '',
            name: 'Guest',
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

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
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LiquidGlassTheme.getGradientByName(
                        'primary',
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Profile Avatar
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(51),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
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
                                color: Colors.white.withAlpha(204),
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
                            color:
                                (LiquidGlassTheme.getTextColor(
                                          'secondary',
                                        ) ??
                                        Colors.grey)
                                    .withAlpha(25),
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: LiquidGlassTheme.getGradientByName(
                          'primary',
                        ).colors.first,
                        unselectedLabelColor:
                            LiquidGlassTheme.getTextColor('secondary'),
                        indicatorColor:
                            LiquidGlassTheme.getGradientByName(
                              'primary',
                            ).colors.first,
                        indicatorWeight: 2,
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.person, size: 20),
                            text: 'المعلومات',
                          ),
                          Tab(
                            icon: Icon(Icons.report, size: 20),
                            text: 'البلاغات',
                          ),
                          Tab(
                            icon: Icon(Icons.card_giftcard, size: 20),
                            text: 'المكافآت',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Tab Content
              SliverFillRemaining(child: _buildTabBarView()),
            ],
          );
        },
      ),
    );
  }


  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildProfileTab(),
        _buildReportsTab(),
        _buildRewardsTab(),
      ],
    );
  }

  // بناء بطاقة إحصائية
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء علامة تبويب الإنجازات
  // بناء شارة الإنجاز
  Widget _buildBadge({
    required String title,
    required String description,
    required IconData icon,
    required bool isUnlocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? LiquidGlassTheme.getGradientByName(
                      'primary',
                    ).colors.first.withAlpha(25)
                  : Colors.grey.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isUnlocked
                  ? LiquidGlassTheme.getGradientByName('primary').colors.first
                  : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.black : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isUnlocked ? Colors.grey.shade600 : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatsSection() {
    // التحقق من وجود الإحصائيات قبل عرضها
    if (_userStatistics == null) {
      return LiquidGlassContainer(
        type: LiquidGlassType.ultraLight,
        isInteractive: false,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: LiquidGlassTheme.getTextColor('secondary'),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد إحصائيات متاحة',
              style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'قم بإرسال بعض البلاغات لرؤية الإحصائيات',
              style: LiquidGlassTheme.bodyTextStyle.copyWith(
                color: LiquidGlassTheme.getTextColor('secondary'),
              ),
            ),
          ],
        ),
      );
    }

    return LiquidGlassContainer(
      type: LiquidGlassType.ultraLight,
      isInteractive: false,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإحصائيات المفصلة',
            style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          
          // الإحصائيات الأساسية
          Row(
            children: [
              Flexible(
                child: _buildStatCard(
                  title: 'إجمالي البلاغات',
                  value: '${_userStatistics?.totalReports ?? 0}',
                  icon: Icons.report,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _buildStatCard(
                  title: 'البلاغات المؤكدة',
                  value: '${_userStatistics?.confirmedReports ?? 0}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: _buildStatCard(
                  title: 'البلاغات المرفوضة',
                  value: '${_userStatistics?.rejectedReports ?? 0}',
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _buildStatCard(
                  title: 'معدل التأكيد',
                  value: '${(_userStatistics?.confirmationRate ?? 0.0).toStringAsFixed(1)}%',
                  icon: Icons.analytics,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          
          // إحصائيات حسب النوع
          if (_userStatistics?.reportsByType.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Text(
              'البلاغات حسب النوع',
              style: LiquidGlassTheme.headerTextStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: LiquidGlassTheme.getTextColor('primary'),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: (_userStatistics?.reportsByType.entries ?? <MapEntry<String, int>>[]).map((entry) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key, 
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${entry.value}', 
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserLevelSection() {
    // التحقق من وجود الإحصائيات قبل حساب النقاط والمستوى
    if (_userStatistics == null) {
      return LiquidGlassContainer(
        type: LiquidGlassType.ultraLight,
        isInteractive: false,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outline,
              size: 48,
              color: LiquidGlassTheme.getTextColor('secondary'),
            ),
            const SizedBox(height: 16),
            Text(
              'مستوى المستخدم غير متاح',
              style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'قم بإرسال بعض البلاغات لرؤية مستواك',
              style: LiquidGlassTheme.bodyTextStyle.copyWith(
                color: LiquidGlassTheme.getTextColor('secondary'),
              ),
            ),
          ],
        ),
      );
    }

    final points = _statisticsService.calculateUserPoints(_userStatistics!);
    final level = _statisticsService.getUserLevel(points);
    final levelColor = Color(int.parse(_statisticsService.getUserLevelColor(level).replaceFirst('#', '0xFF')));
    
    return LiquidGlassContainer(
      type: LiquidGlassType.ultraLight,
      isInteractive: false,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مستوى المستخدم',
            style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.star,
                  color: levelColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level,
                      style: LiquidGlassTheme.headerTextStyle.copyWith(
                        fontSize: 16,
                        color: levelColor,
                      ),
                    ),
                    Text(
                      '$points نقطة',
                      style: LiquidGlassTheme.bodyTextStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإنجازات',
          style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildBadge(
              title: 'المبلغ النشط',
              description: 'قم بإرسال 5 بلاغات',
              icon: Icons.star,
              isUnlocked: (_userStatistics?.totalReports ?? 0) >= 5,
            ),
            _buildBadge(
              title: 'المبلغ الخبير',
              description: 'قم بإرسال 20 بلاغ',
              icon: Icons.workspace_premium,
              isUnlocked: (_userStatistics?.totalReports ?? 0) >= 20,
            ),
            _buildBadge(
              title: 'دقة عالية',
              description: 'حقق نسبة دقة 80%',
              icon: Icons.verified,
              isUnlocked: (_userStatistics?.confirmationRate ?? 0) >= 80,
            ),
            _buildBadge(
              title: 'مبلغ موثوق',
              description: 'حقق 10 بلاغات مؤكدة',
              icon: Icons.security,
              isUnlocked: (_userStatistics?.confirmedReports ?? 0) >= 10,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOldAchievementsTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatCard(
                title: 'البلاغات النشطة',
                value: _activeReports.toString(),
                icon: Icons.report_problem,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                title: 'البلاغات المؤكدة',
                value: _confirmedReports.toString(),
                icon: Icons.verified,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                title: 'نسبة الدقة',
                value: '${(_accuracyRate * 100).toStringAsFixed(1)}%',
                icon: Icons.analytics,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'الإنجازات',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildBadge(
                    title: 'المبلغ النشط',
                    description: 'قم بإرسال 5 بلاغات',
                    icon: Icons.star,
                    isUnlocked: _activeReports >= 5,
                  ),
                  _buildBadge(
                    title: 'المبلغ الخبير',
                    description: 'قم بإرسال 20 بلاغ',
                    icon: Icons.workspace_premium,
                    isUnlocked: _activeReports >= 20,
                  ),
                  _buildBadge(
                    title: 'دقة عالية',
                    description: 'حقق نسبة دقة 80%',
                    icon: Icons.verified,
                    isUnlocked: _accuracyRate >= 0.8,
                  ),
                  _buildBadge(
                    title: 'مبلغ موثوق',
                    description: 'حقق 10 بلاغات مؤكدة',
                    icon: Icons.security,
                    isUnlocked: _confirmedReports >= 10,
                  ),
                ],
              ),
            ],
          );
  }

  Widget _buildProfileTab() {
    return Consumer<AuthProviderCustom.AuthProvider>(
      builder: (context, authProvider, child) {
        try {
          final user =
              authProvider.userModel ??
              UserModel(
                id: '',
                email: '',
                name: 'Guest',
                createdAt: DateTime.now(),
                lastLogin: DateTime.now(),
              );

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
                                color: LiquidGlassTheme.getGradientByName(
                                  'primary',
                                ).colors.first.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: LiquidGlassTheme.getGradientByName(
                                  'primary',
                                ).colors.first,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_isEditing) ...[
                      _buildEditableField(
                        'الاسم',
                        _nameController,
                        Icons.person,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        'رقم الهاتف',
                        _phoneController,
                        Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
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
                      _buildInfoTile(
                        Icons.email,
                        'البريد الإلكتروني',
                        user.email,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoTile(
                        Icons.phone,
                        'رقم الهاتف',
                        user.phone ?? 'غير محدد',
                      ),
                      const SizedBox(height: 16),
                      _buildInfoTile(
                        Icons.calendar_today,
                        'تاريخ التسجيل',
                        _formatDate(user.createdAt),
                      ),
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
                    _buildSettingsTile(
                      Icons.notifications,
                      'الإشعارات',
                      'إدارة إشعارات التطبيق',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationsSettingsScreen(),
                          ),
                        );
                      },
                    ),

                    _buildSettingsTile(
                      Icons.help,
                      'المساعدة',
                      'الحصول على المساعدة والدعم',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      Icons.logout,
                      'تسجيل الخروج',
                      'تسجيل الخروج من الحساب',
                      _signOut,
                      textColor: LiquidGlassTheme.getGradientByName(
                        'danger',
                      ).colors.first,
                    ),
                  ],
                ),
              ),

              // Bottom spacing for navigation bar
              const SizedBox(height: 100),
            ],
          ),
        );
        } catch (e) {
          print('Error in _buildProfileTab: $e');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ في تحميل الملف الشخصي: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: LiquidGlassTheme.bodyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
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
              prefixIcon: Icon(
                icon,
                color: LiquidGlassTheme.getTextColor('secondary'),
              ),
              border: InputBorder.none,
              hintText: 'أدخل $label',
              hintStyle: TextStyle(
                color: LiquidGlassTheme.getTextColor('secondary'),
              ),
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
        color: LiquidGlassTheme.getGradientByName(
          'primary',
        ).colors.first.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LiquidGlassTheme.getGradientByName(
                'primary',
              ).colors.first.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: LiquidGlassTheme.getGradientByName('primary').colors.first,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: LiquidGlassTheme.headerTextStyle.copyWith(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (textColor ?? LiquidGlassTheme.getTextColor('primary'))
                .withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: textColor ?? LiquidGlassTheme.getTextColor('primary'),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: LiquidGlassTheme.headerTextStyle.copyWith(
            color: textColor,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 12),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: LiquidGlassTheme.getTextColor('secondary'),
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRewardsTab() {
    try {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // إشعار توضيحي
            _buildDemoNotice(),
            const SizedBox(height: 24),

            // قسم المكافآت التجريبية من الشراكات
            Text(
              'مكافآت الشراكات مع البراندات',
              style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildDemoBrandRewards(),
            
            // مسافة فارغة في الأسفل لمنع التداخل مع القائمة السفلية
            const SizedBox(height: 100),
          ],
        ),
      );
    } catch (e) {
      print('Error in _buildRewardsTab: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('خطأ في تحميل المكافآت: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
  }

  // بطاقة المكافأة المتاحة
  Widget _buildRewardCard(RewardModel reward) {
    final bool canRedeem =
        _userPoints != null && _userPoints!.points >= reward.requiredPoints;

    return LiquidGlassContainer(
      type: LiquidGlassType.secondary,
      isInteractive: true,
      borderRadius: BorderRadius.circular(16),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: LiquidGlassTheme.getGradientByName(
                    'primary',
                  ).colors.first.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: reward.imageUrl.isNotEmpty
                      ? Image.network(
                          reward.imageUrl,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.card_giftcard,
                              size: 30,
                              color: LiquidGlassTheme.getGradientByName(
                                'primary',
                              ).colors.first,
                            );
                          },
                        )
                      : Icon(
                          Icons.card_giftcard,
                          size: 30,
                          color: LiquidGlassTheme.getGradientByName(
                            'primary',
                          ).colors.first,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.brandName,
                      style: LiquidGlassTheme.headerTextStyle.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reward.description,
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                        color: LiquidGlassTheme.getTextColor('secondary'),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${reward.requiredPoints} نقطة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LiquidGlassTheme.getGradientByName(
                    'primary',
                  ).colors.first,
                ),
              ),
              LiquidGlassButton(
                onPressed: canRedeem ? () => _redeemReward(reward) : null,
                text: canRedeem ? 'استبدال' : 'نقاط غير كافية',
                type: canRedeem
                    ? LiquidGlassType.primary
                    : LiquidGlassType.secondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بطاقة مكافأة المستخدم
  Widget _buildUserRewardCard(UserRewardModel userReward) {
    final bool isExpired = userReward.expiryDate.isBefore(DateTime.now());

    return LiquidGlassContainer(
      type: LiquidGlassType.secondary,
      borderRadius: BorderRadius.circular(16),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'كود الخصم:',
                style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isExpired || userReward.isUsed
                      ? Colors.grey
                      : LiquidGlassTheme.getGradientByName(
                          'primary',
                        ).colors.first,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  userReward.discountCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تاريخ الانتهاء: ${_formatDate(userReward.expiryDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: isExpired
                      ? Colors.red
                      : LiquidGlassTheme.getTextColor('secondary'),
                ),
              ),
              Text(
                userReward.isUsed
                    ? 'مستخدم'
                    : isExpired
                    ? 'منتهي الصلاحية'
                    : 'صالح',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: userReward.isUsed || isExpired
                      ? Colors.red
                      : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // دالة تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // دالة استبدال المكافأة
  Future<void> _redeemReward(RewardModel reward) async {
    final authProvider = Provider.of<AuthProviderCustom.AuthProvider>(
      context,
      listen: false,
    );
    if (authProvider.userId == null) return;

    try {
      final userReward = await _rewardsService.redeemReward(
        authProvider.userId!,
        reward.id,
      );

      if (userReward != null) {
        // تحديث النقاط والمكافآت
        _loadUserPoints();
        _showSuccessSnackBar('تم استبدال المكافأة بنجاح!');
      } else {
        _showErrorSnackBar('فشل استبدال المكافأة. يرجى المحاولة مرة أخرى.');
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء استبدال المكافأة.');
    }
  }

  Widget _buildReportsTab() {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, child) {
        try {
          final userReports = reportsProvider.userReports;
          
          // إضافة تسجيل للتشخيص
          print('ProfileScreen: _buildReportsTab - userReports.length = ${userReports.length}');
          print('ProfileScreen: _buildReportsTab - isLoading = ${reportsProvider.isLoading}');
          print('ProfileScreen: _buildReportsTab - errorMessage = ${reportsProvider.errorMessage}');

        return RefreshIndicator(
          onRefresh: _loadUserReports,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // إحصائيات مفصلة
                if (_userStatistics != null) ...[
                  _buildDetailedStatsSection(),
                  const SizedBox(height: 16),
                ],
                
                // مستوى المستخدم
                if (_userStatistics != null) ...[
                  _buildUserLevelSection(),
                  const SizedBox(height: 16),
                ],
                
                // الإنجازات
                _buildAchievementsSection(),
                const SizedBox(height: 24),
                
                // قائمة البلاغات
                Text(
                  'بلاغاتي',
                  style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 16),
                
                // إضافة معلومات التشخيص في وضع التطوير
                if (kDebugMode) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('معلومات التشخيص:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('عدد البلاغات: ${userReports.length}'),
                        Text('حالة التحميل: ${reportsProvider.isLoading ? "جاري التحميل" : "مكتمل"}'),
                        if (reportsProvider.errorMessage != null)
                          Text('خطأ: ${reportsProvider.errorMessage}', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (userReports.isEmpty)
                  _buildEmptyReportsState()
                else
                  _buildReportsListSection(userReports),
                
                // مسافة فارغة في الأسفل لمنع التداخل مع القائمة السفلية
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
        } catch (e) {
          print('Error in _buildReportsTab: $e');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ في تحميل البلاغات: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildEmptyReportsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (LiquidGlassTheme.getTextColor('secondary') ?? Colors.grey)
                    .withAlpha(25),
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

  Widget _buildReportsListSection(List<ReportModel> userReports) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'بلاغاتي (${userReports.length})',
          style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: userReports.length,
          itemBuilder: (context, index) {
            final report = userReports[index];
            return _buildReportCard(report);
          },
        ),
      ],
    );
  }

  Widget _buildOldReportsTab() {
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
                      color:
                          (LiquidGlassTheme.getTextColor('secondary') ??
                                  Colors.grey)
                              .withAlpha(25),
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
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: 18,
                    ),
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
        final activeReports = userReports
            .where((r) => r.status == ReportStatus.active)
            .length;
        final confirmedReports = userReports
            .where(
              (r) =>
                  (r.confirmations?.trueVotes ?? 0) >
                  (r.confirmations?.falseVotes ?? 0),
            )
            .length;
        final accuracy = totalReports > 0
            ? (confirmedReports / totalReports * 100)
            : 0.0;

        // تصنيف البلاغات حسب النوع
        final Map<String, int> reportsByType = {};
        for (var report in userReports) {
          final type = report.type.toString().split('.').last;
          reportsByType[type] = (reportsByType[type] ?? 0) + 1;
        }

        // حساب مستوى المستخدم
        final int userLevel = _calculateUserLevel(totalReports);
        final double progressToNextLevel = _calculateProgressToNextLevel(
          totalReports,
        );

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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LiquidGlassTheme.getGradientByName(
                              'primary',
                            ),
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
                            color: Colors.grey.withAlpha(51),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Container(
                          height: 10,
                          width:
                              MediaQuery.of(context).size.width *
                              progressToNextLevel *
                              0.8, // 0.8 to account for padding
                          decoration: BoxDecoration(
                            gradient: LiquidGlassTheme.getGradientByName(
                              'primary',
                            ),
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
                        Expanded(
                          child: _buildStatCard(
                            title: 'إجمالي البلاغات',
                            value: totalReports.toString(),
                            icon: Icons.report,
                            color: LiquidGlassTheme.getGradientByName(
                              'primary',
                            ).colors.first,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'النشطة',
                            value: activeReports.toString(),
                            icon: Icons.check_circle,
                            color: LiquidGlassTheme.getGradientByName(
                              'success',
                            ).colors.first,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'المؤكدة',
                            value: confirmedReports.toString(),
                            icon: Icons.verified,
                            color: LiquidGlassTheme.getGradientByName(
                              'warning',
                            ).colors.first,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'الدقة',
                            value: '${accuracy.toStringAsFixed(1)}%',
                            icon: Icons.trending_up,
                            color: LiquidGlassTheme.getGradientByName(
                              'info',
                            ).colors.first,
                          ),
                        ),
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
                      ...reportsByType.entries
                          .map(
                            (entry) => _buildReportTypeItem(
                              entry.key,
                              entry.value,
                              totalReports,
                              _getColorForReportType(entry.key),
                            ),
                          )
                          .toList(),
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
                          if (totalReports >= 5)
                            _buildEnhancedBadge(
                              '🥉',
                              'مبلغ برونزي',
                              'أول 5 بلاغات',
                              Colors.brown.shade300,
                            ),
                          if (totalReports >= 10)
                            _buildEnhancedBadge(
                              '🥈',
                              'مبلغ فضي',
                              'أول 10 بلاغات',
                              Colors.grey.shade400,
                            ),
                          if (totalReports >= 25)
                            _buildEnhancedBadge(
                              '🥇',
                              'مبلغ ذهبي',
                              'أول 25 بلاغ',
                              Colors.amber,
                            ),
                          if (accuracy >= 80)
                            _buildEnhancedBadge(
                              '🎯',
                              'دقة عالية',
                              'دقة أكثر من 80%',
                              Colors.blue,
                            ),
                          if (activeReports >= 5)
                            _buildEnhancedBadge(
                              '🔥',
                              'مساهم نشط',
                              '5 بلاغات نشطة',
                              Colors.orange,
                            ),
                          if (totalReports >= 50)
                            _buildEnhancedBadge(
                              '💎',
                              'مبلغ ماسي',
                              'أول 50 بلاغ',
                              Colors.cyan,
                            ),
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
                      LiquidGlassTheme.getGradientByName(
                        'primary',
                      ).colors.first,
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
                      userReports
                          .where((r) => r.type == ReportType.accident)
                          .length,
                      20,
                      Icons.security,
                      LiquidGlassTheme.getGradientByName('danger').colors.first,
                    ),
                    const SizedBox(height: 12),
                    _buildAchievementItem(
                      'مستكشف المدينة',
                      'أبلغ في 5 مناطق مختلفة',
                      userReports.length > 0
                          ? math.min(5, userReports.length)
                          : 0,
                      5,
                      Icons.explore,
                      LiquidGlassTheme.getGradientByName(
                        'warning',
                      ).colors.first,
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
    final reportsForCurrentLevel = math
        .pow(((currentLevel - 1) * 2), 2)
        .toInt();
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
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'إبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

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
            year == now.year - 1 &&
                now.month < 6 &&
                month > 12 - (6 - now.month)) {
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
                style: LiquidGlassTheme.bodyTextStyle.copyWith(
                  fontWeight: FontWeight.w500,
                ),
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
                  color: Colors.grey.withAlpha(51),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width:
                    MediaQuery.of(context).size.width *
                    (percentage / 100) *
                    0.8, // 0.8 to account for padding
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
      case 'accident':
        return 'حادث';
      case 'traffic':
        return 'ازدحام';
      case 'roadClosure':
        return 'إغلاق طريق';
      case 'roadwork':
        return 'أعمال طريق';
      case 'hazard':
        return 'خطر';
      case 'police':
        return 'نقطة أمنية';
      case 'flood':
        return 'فيضان';
      case 'fire':
        return 'حريق';
      case 'speedBump':
        return 'مطب';
      case 'construction':
        return 'إنشاءات';
      default:
        return type;
    }
  }

  // دالة للحصول على لون مناسب لنوع البلاغ
  Color _getColorForReportType(String type) {
    switch (type) {
      case 'accident':
        return Colors.red;
      case 'traffic':
        return Colors.orange;
      case 'roadClosure':
        return Colors.purple;
      case 'roadwork':
        return Colors.amber;
      case 'hazard':
        return Colors.red.shade800;
      case 'police':
        return Colors.blue;
      case 'flood':
        return Colors.blue.shade700;
      case 'fire':
        return Colors.deepOrange;
      case 'speedBump':
        return Colors.brown;
      case 'construction':
        return Colors.amber.shade800;
      default:
        return LiquidGlassTheme.getGradientByName('primary').colors.first;
    }
  }

  // دالة لإنشاء شارة محسنة
  Widget _buildEnhancedBadge(
    String emoji,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.28,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77), width: 1),
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
  Widget _buildAchievementItem(
    String title,
    String description,
    int current,
    int target,
    IconData icon,
    Color color,
  ) {
    final progress = (current / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
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
                      style: LiquidGlassTheme.headerTextStyle.copyWith(
                        fontSize: 14,
                      ),
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
                  color: progress >= 1.0
                      ? color
                      : LiquidGlassTheme.getTextColor('secondary'),
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
                  color: Colors.grey.withAlpha(51),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                height: 6,
                width:
                    MediaQuery.of(context).size.width *
                    progress *
                    0.8, // 0.8 to account for padding
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

  // تم حذف التعريف المكرر لدالة _buildStatCard

  // تم حذف التعريف المكرر لدالة _buildBadge

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
                color: _getReportColor(report.type).withAlpha(38),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getReportIcon(report.type),
                color: _getReportColor(report.type),
                size: 20,
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
                color: _getStatusColor(report.status).withAlpha(38),
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

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.jam:
        return Icons.traffic;
      case ReportType.carBreakdown:
        return Icons.car_repair;
      case ReportType.bump:
        return Icons.warning;
      case ReportType.closedRoad:
        return Icons.block;
      case ReportType.accident:
        return Icons.car_crash;
      case ReportType.hazard:
        return Icons.warning_amber;
      case ReportType.police:
        return Icons.local_police;
      case ReportType.traffic:
        return Icons.traffic;
      case ReportType.other:
        return Icons.report;
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
      case ReportType.hazard:
        return LiquidGlassTheme.getGradientByName('warning').colors.first;
      case ReportType.police:
        return LiquidGlassTheme.getGradientByName('info').colors.last;
      case ReportType.traffic:
        return LiquidGlassTheme.getGradientByName('warning').colors.first;
      case ReportType.other:
        return LiquidGlassTheme.getTextColor('secondary');
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
      case ReportType.hazard:
        return 'خطر';
      case ReportType.police:
        return 'شرطة';
      case ReportType.traffic:
        return 'حركة مرور';
      case ReportType.other:
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
        return LiquidGlassTheme.getTextColor('secondary');
      case ReportStatus.pending:
        return LiquidGlassTheme.getGradientByName('warning').colors.first;
      case ReportStatus.verified:
        return LiquidGlassTheme.getGradientByName('success').colors.first;
      case ReportStatus.rejected:
        return LiquidGlassTheme.getGradientByName('danger').colors.first;
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
      case ReportStatus.pending:
        return 'قيد المراجعة';
      case ReportStatus.verified:
        return 'مؤكد';
      case ReportStatus.rejected:
        return 'مرفوض';
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
