import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../maps/basic_map_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/add_report_screen.dart';
import '../community/community_screen.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart' as auth_provider;
import '../../providers/reports_provider.dart';
import '../../models/dashboard_models.dart';
import '../../models/nearby_report.dart';
import '../../models/report_model.dart';
import '../../widgets/common/bottom_navigation_widget.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';
import 'prayer_times_section.dart';
import '../../services/weather_service.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/dashboard';

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _screens = [
    const DashboardHomeWidget(),
    const BasicMapScreen(),
    const AddReportScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // فحص حالة المصادقة عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthenticationStatus();
    });
  }

  void _checkAuthenticationStatus() async {
    try {
      final authProvider = context.read<auth_provider.AuthProvider>();

      // فحص إذا كان المستخدم مسجل دخول
      if (!authProvider.isLoggedIn) {
        debugPrint(
          'DashboardScreen: المستخدم غير مسجل دخول، إعادة توجيه لصفحة تسجيل الدخول',
        );
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // فحص صحة بيانات المستخدم
      if (authProvider.userModel == null) {
        debugPrint(
          'DashboardScreen: بيانات المستخدم غير متوفرة، إعادة توجيه لصفحة تسجيل الدخول',
        );
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // فحص البيانات الأساسية
      if (authProvider.userModel?.name.isEmpty == true ||
          authProvider.userModel?.email.isEmpty == true) {
        debugPrint(
          'DashboardScreen: بيانات المستخدم غير مكتملة، إعادة توجيه لصفحة تسجيل الدخول',
        );
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      debugPrint('DashboardScreen: المصادقة صحيحة، يمكن المتابعة');
    } catch (e) {
      debugPrint('DashboardScreen: خطأ في فحص المصادقة: $e');
      // إزالة إعادة التوجيه التلقائي عند الخطأ لتجنب تسجيل الخروج غير المرغوب فيه
      // if (mounted) {
      //   Navigator.of(context).pushReplacementNamed('/login');
      // }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: LiquidGlassTheme.backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class DashboardHomeWidget extends StatefulWidget {
  const DashboardHomeWidget({super.key});

  @override
  State<DashboardHomeWidget> createState() => _DashboardHomeWidgetState();
}

class _DashboardHomeWidgetState extends State<DashboardHomeWidget>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  String _selectedFilter = 'الكل'; // New state variable for selected filter

  @override
  void initState() {
    super.initState();

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _cardAnimationController.forward();
    _pulseAnimationController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _switchToMap() {
    final dashboardState = context
        .findAncestorStateOfType<_DashboardScreenState>();
    if (dashboardState != null) {
      dashboardState.setState(() {
        dashboardState._currentIndex = 1;
      });
    }
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.95),
              Colors.white.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 50,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 20),
                
                // User Info
                Consumer<auth_provider.AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.userModel;
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade100,
                                Colors.blue.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'مستخدم',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                user?.email ?? 'user@example.com',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Menu Items
                _buildMenuButton(
                  icon: Icons.notifications_outlined,
                  title: 'الإشعارات',
                  onTap: () {
                    Navigator.pop(context);
                    _showNotifications(context);
                  },
                ),
                _buildMenuButton(
                  icon: Icons.person_outline,
                  title: 'الملف الشخصي',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                _buildMenuButton(
                  icon: Icons.settings_outlined,
                  title: 'الإعدادات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                _buildMenuButton(
                  icon: Icons.logout,
                  title: 'تسجيل الخروج',
                  onTap: () {
                    Navigator.pop(context);
                    _logout(context);
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.6),
              Colors.white.withValues(alpha: 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red.shade600 : Colors.grey.shade700,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDestructive ? Colors.red.shade600 : Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final dashboardProvider = context.read<DashboardProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final reports = dashboardProvider.nearbyReports.take(5).toList();
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 50,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        color: Colors.grey.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'آخر البلاغات',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  if (reports.isEmpty)
                    Container(
                      height: 120,
                      alignment: Alignment.center,
                      child: Text(
                        'لا توجد بلاغات حديثة',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: reports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final r = reports[i];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.8),
                                  Colors.white.withValues(alpha: 0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    r.type.icon,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.title,
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        r.timeAgo,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    try {
      final authProvider = context.read<auth_provider.AuthProvider>();
      await authProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الخروج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, dashboardProvider, child) {
            if (dashboardProvider.isLoading) {
              return const Center(child: LiquidGlassLoadingIndicator());
            }

            return RefreshIndicator(
              onRefresh: dashboardProvider.refreshData,
              color: LiquidGlassTheme.getGradientByName('primary').colors.first,
              backgroundColor: Colors.white,
              displacement: 80,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Emergency Alert (if any)
                  if (dashboardProvider.currentAlert != null)
                    SliverToBoxAdapter(
                      child: _buildEmergencyAlert(
                        context,
                        dashboardProvider.currentAlert!,
                      ),
                    ),

                  // Enhanced Header
                  SliverToBoxAdapter(child: _buildEnhancedHeader(context)),

                  // Spacing after header - محسن
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Enhanced Welcome Section
                  SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: _buildEnhancedWelcomeSection(
                            dashboardProvider.weather,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Spacing after welcome section - محسن
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // Statistics Cards
                  const SliverToBoxAdapter(child: PrayerTimesSection()),

                  // Spacing after statistics - محسن
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // Around You Section
                  SliverToBoxAdapter(
                    child: _buildAroundYouSection(
                      context,
                      dashboardProvider,
                      _selectedFilter,
                      (filter) {
                        setState(() {
                          _selectedFilter = filter;
                          dashboardProvider.filterReports(filter);
                        });
                      },
                    ),
                  ),

                  // Safety Tip
                  SliverToBoxAdapter(
                    child: _buildSafetyTip(dashboardProvider.dailyTip),
                  ),

                  // Bottom padding for navigation - محسن
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // App Logo
          Hero(
            tag: 'app_logo',
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.8),
                    Colors.white.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.shield_outlined,
                      color: Colors.grey.shade700,
                      size: 24,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // App Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سلامة السائقين',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade800,
                    height: 1.2,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'قيادة آمنة، مستقبل أفضل',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Notifications
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => _showNotifications(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: Colors.grey.shade700,
                      size: 20,
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Consumer<DashboardProvider>(
                    builder: (context, provider, child) {
                      final count = provider.nearbyReports.length;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade500,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // User Profile Menu
          GestureDetector(
            onTap: () => _showUserMenu(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Consumer<auth_provider.AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.userModel;
                  if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        user.photoUrl!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person_outline,
                            color: Colors.grey.shade700,
                            size: 24,
                          );
                        },
                      ),
                    );
                  }
                  return Icon(
                    Icons.person_outline,
                    color: Colors.grey.shade700,
                    size: 24,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedWelcomeSection(WeatherInfo weather) {
    final now = DateTime.now();
    // تغيير تنسيق الوقت إلى نظام 12 ساعة بدلاً من 24 ساعة
    final weatherService = WeatherService();
    final timeString = weatherService.formatTimeIn12Hour(now);
    final dateFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50.withValues(alpha: 0.8),
            const Color.fromARGB(16, 61, 128, 244).withValues(alpha: 0.1),
            const Color.fromARGB(255, 228, 233, 252).withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.purple.shade50.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(-5, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            Text(
              'مرحباً بك في تطبيق سلامة السائقين',
              style: TextStyle(
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.w800,
                color: const Color.fromARGB(255, 12, 12, 12),
                height: 1.3,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'نحن هنا لضمان رحلتك الآمنة',
              style: TextStyle(
                fontSize: screenWidth * 0.032,
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Time and Weather Row
            Row(
              children: [
                // Time Info
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.blue.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeString,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color.fromARGB(255, 16, 16, 16),
                              shadows: [
                                Shadow(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            dateFormat.format(now),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Weather Widget
                Row(
                  children: [
                    Text(
                      weather.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather.temperature}°',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 15, 15, 15),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.7),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          weather.condition,
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Row(
              children: [
                // Driving Mode Button
                Expanded(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/driving-mode');
                        },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.8),
                                const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade200.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.6),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.navigation,
                                  color: const Color.fromARGB(255, 2, 2, 2),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'وضع القيادة',
                                  style: TextStyle(
                                    color: const Color.fromARGB(255, 13, 13, 13),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    shadows: [
                                      Shadow(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Map Button
                Expanded(
                  child: GestureDetector(
                    onTap: _switchToMap,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.8),
                            const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color.fromARGB(255, 233, 233, 233).withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              color: const Color.fromARGB(255, 0, 0, 0),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'الخريطة',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 0, 0, 0),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAroundYouSection(
    BuildContext context,
    DashboardProvider dashboardProvider,
    String selectedFilter,
    Function(String) onFilterSelected,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.6),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade100,
                            Colors.blue.shade200,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blue.shade300.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ماذا يحدث حولك؟',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.3,
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _switchToMap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade100,
                          Colors.blue.shade200,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blue.shade300.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_rounded, 
                          color: Colors.blue.shade700, 
                          size: 16
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'خريطة',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            fontFamily: 'NotoSansArabic',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Enhanced filter chips - محسن
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildEnhancedFilterChip(
                    label: 'الكل',
                    icon: Icons.filter_list,
                    isSelected: selectedFilter == 'الكل',
                    onTap: () {
                      onFilterSelected('الكل');
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildEnhancedFilterChip(
                    label: '500م',
                    icon: Icons.location_on,
                    isSelected: selectedFilter == '500م',
                    onTap: () {
                      onFilterSelected('500م');
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildEnhancedFilterChip(
                    label: '1كم',
                    icon: Icons.location_on,
                    isSelected: selectedFilter == '1كم',
                    onTap: () {
                      onFilterSelected('1كم');
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildEnhancedFilterChip(
                    label: 'حوادث',
                    icon: Icons.car_crash,
                    isSelected: selectedFilter == 'حوادث',
                    onTap: () {
                      onFilterSelected('حوادث');
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildEnhancedFilterChip(
                    label: 'ازدحام',
                    icon: Icons.traffic,
                    isSelected: selectedFilter == 'ازدحام',
                    onTap: () {
                      onFilterSelected('ازدحام');
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildEnhancedFilterChip(
                    label: 'صيانة',
                    icon: Icons.build,
                    isSelected: selectedFilter == 'صيانة',
                    onTap: () {
                      onFilterSelected('صيانة');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Reports list - محسن
            ...dashboardProvider.filteredReports.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildEnhancedReportCard(
                  report.title,
                  report.distance,
                  report.timeAgo,
                  report.type.icon,
                  severity: 'متوسط',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedFilterChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                )
              : null,
          color: isSelected ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedReportCard(
    String title,
    String distance,
    String time,
    IconData icon, {
    required String severity,
  }) {
    final severityColor = _getSeverityColor(severity);

    return GestureDetector(
      onTap: () {
        // عرض التفاصيل المحسنة
        _showEnhancedReportDetails(title, distance, time, icon, severity);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: severityColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: severityColor.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        severityColor,
                        severityColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: severityColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.grey.shade500,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            time,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: severityColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    severity,
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Colors.grey.shade500,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  distance,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // عرض التفاصيل المحسنة
                      _showEnhancedReportDetails(
                        title,
                        distance,
                        time,
                        icon,
                        severity,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Text(
                        'عرض التفاصيل',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _shareEnhancedReport(
                        title,
                        distance,
                        time,
                        severity,
                        null,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'مشاركة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'عالي':
        return Colors.red.shade500;
      case 'متوسط':
        return Colors.orange.shade500;
      case 'منخفض':
      default:
        return Colors.green.shade500;
    }
  }


  Widget _buildEmergencyAlert(BuildContext context, dynamic alert) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تنبيه طارئ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert?.message ?? 'يرجى توخي الحذر الشديد',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
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

  Widget _buildSafetyTip(dynamic tip) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'نصيحة اليوم للأمان',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tip != null && tip is SafetyTip
                      ? tip.content
                      : 'احتفظ بمسافة آمنة بينك وبين السيارة التي أمامك',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.grey.shade600, size: 18),
        const SizedBox(width: 10),
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: color ?? Colors.grey.shade600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _showEnhancedReportDetails(
    String title,
    String distance,
    String time,
    IconData icon,
    String severity,
  ) async {
    // البحث عن البلاغ في قائمة البلاغات المفلترة للحصول على معلومات إضافية
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    NearbyReport? reportData;
    Map<String, dynamic>? fullReportData;

    try {
      reportData = dashboardProvider.filteredReports.firstWhere(
        (report) => report.title == title,
        orElse: () => throw StateError('Report not found'),
      );

      // جلب البيانات الكاملة من Firebase للحصول على التأكيدات والرفض
      try {
        final doc = await FirebaseFirestore.instance
            .collection('reports')
            .doc(reportData.relatedReportId ?? reportData.id)
            .get();
        if (doc.exists) {
          fullReportData = doc.data();
        }
      } catch (e) {
        debugPrint('Error fetching full report data: $e');
      }
    } catch (e) {
      // إذا لم يتم العثور على البلاغ، استخدم البيانات المتاحة
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 400;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 20,
            vertical: screenHeight * 0.08,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.85,
              maxWidth: isSmallScreen ? screenWidth - 24 : 400,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.98),
                  Colors.grey.shade50.withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
              border: Border.all(
                color: Colors.grey.shade300.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? 16 : 20,
                    isSmallScreen ? 16 : 20,
                    isSmallScreen ? 16 : 20,
                    isSmallScreen ? 12 : 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getSeverityColor(severity).withValues(alpha: 0.08),
                        _getSeverityColor(severity).withValues(alpha: 0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isSmallScreen ? 16 : 20),
                      topRight: Radius.circular(isSmallScreen ? 16 : 20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getSeverityColor(severity),
                              _getSeverityColor(
                                severity,
                              ).withValues(alpha: 0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            isSmallScreen ? 12 : 16,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getSeverityColor(
                                severity,
                              ).withValues(alpha: 0.25),
                              blurRadius: isSmallScreen ? 8 : 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تفاصيل البلاغ',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Text(
                              title.split(' - ').first,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Severity Badge
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 20,
                    vertical: isSmallScreen ? 8 : 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 10 : 12,
                          vertical: isSmallScreen ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(
                            severity,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            isSmallScreen ? 8 : 10,
                          ),
                          border: Border.all(
                            color: _getSeverityColor(
                              severity,
                            ).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          severity,
                          style: TextStyle(
                            color: _getSeverityColor(severity),
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: Colors.grey.shade300, height: 1),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isSmallScreen ? 16 : 20,
                      isSmallScreen ? 8 : 12,
                      isSmallScreen ? 16 : 20,
                      isSmallScreen ? 16 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الوصف
                        if (reportData?.description != null) ...[
                          _buildEnhancedDetailSection(
                            'الوصف',
                            Icons.description_outlined,
                            reportData!.description,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // معلومات البلاغ
                        _buildEnhancedDetailSection(
                          'معلومات البلاغ',
                          Icons.info_outline,
                          null,
                          children: [
                            _buildDetailRow(
                              Icons.location_on,
                              'المسافة:',
                              distance,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(Icons.access_time, 'الوقت:', time),
                            if (reportData != null) ...[
                              const SizedBox(height: 20),
                              // إحصائيات التحقق
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.grey.shade50, Colors.white],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.analytics_outlined,
                                          color: Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'إحصائيات التحقق',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatCard(
                                            Icons.verified_user,
                                            'التأكيدات',
                                            '${fullReportData != null ? (fullReportData['verifications'] as List?)?.length ?? reportData.confirmations : reportData.confirmations}',
                                            Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildStatCard(
                                            Icons.cancel,
                                            'الرفض',
                                            '${fullReportData != null ? (fullReportData['rejections'] as List?)?.length ?? 0 : 0}',
                                            Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),

                        // إحداثيات الموقع
                        if (reportData != null) ...[
                          const SizedBox(height: 20),
                          _buildEnhancedDetailSection(
                            'إحداثيات الموقع',
                            Icons.gps_fixed,
                            null,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // الانتقال إلى صفحة الخريطة مع إظهار الموقع
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BasicMapScreen(
                                        initialLatitude: reportData?.latitude,
                                        initialLongitude: reportData?.longitude,
                                        showMarker: true,
                                        markerTitle: 'موقع البلاغ',
                                        markerDescription:
                                            reportData?.description,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.map_outlined,
                                        color: Colors.blue.shade600,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'عرض الموقع على الخريطة',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'خط العرض: ${reportData.latitude.toStringAsFixed(6)}°\nخط الطول: ${reportData.longitude.toStringAsFixed(6)}°',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.blue.shade400,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                Divider(color: Colors.grey.shade300, height: 1),

                // Action Buttons
                Container(
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? 16 : 20,
                    isSmallScreen ? 12 : 16,
                    isSmallScreen ? 16 : 20,
                    isSmallScreen ? 16 : 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(isSmallScreen ? 16 : 20),
                      bottomRight: Radius.circular(isSmallScreen ? 16 : 20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Verification Buttons
                      Row(
                        children: [
                          // تأكيد البلاغ
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _verifyReport(reportData, true);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 12 : 16,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: isSmallScreen ? 8 : 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: isSmallScreen ? 18 : 20,
                                    ),
                                    SizedBox(width: isSmallScreen ? 6 : 8),
                                    Text(
                                      'تأكيد البلاغ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 13 : 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: isSmallScreen ? 10 : 12),

                          // رفض البلاغ
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _verifyReport(reportData, false);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.shade400,
                                      Colors.red.shade600,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 12 : 16,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.25),
                                      blurRadius: isSmallScreen ? 8 : 10,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.red.shade300.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cancel_rounded,
                                      color: Colors.white,
                                      size: isSmallScreen ? 18 : 20,
                                    ),
                                    SizedBox(width: isSmallScreen ? 6 : 8),
                                    Text(
                                      'رفض البلاغ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 13 : 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 8 : 10),

                      // Other Action Buttons
                      Row(
                        children: [

                          // مشاركة
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                _shareEnhancedReport(
                                  title,
                                  distance,
                                  time,
                                  severity,
                                  reportData,
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.shade400,
                                      Colors.orange.shade600,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 12 : 16,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: isSmallScreen ? 8 : 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.orange.shade300.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.share_rounded,
                                      color: Colors.white,
                                      size: screenWidth < 600 ? 18 : 20,
                                    ),
                                    SizedBox(width: screenWidth < 600 ? 8 : 10),
                                    Text(
                                      'مشاركة',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth < 600 ? 13 : 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // إغلاق
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: EdgeInsets.all(
                                screenWidth < 600 ? 12 : 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey.shade100,
                                    Colors.grey.shade200,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                  screenWidth < 600 ? 16 : 20,
                                ),
                                border: Border.all(
                                  color: Colors.grey.shade300.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.grey.shade700,
                                size: screenWidth < 600 ? 18 : 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // دالة التحقق من البلاغ
  void _verifyReport(NearbyReport? reportData, bool isVerified) async {
    if (reportData == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // استخدام ReportsProvider للتصويت على البلاغ
      final reportsProvider = Provider.of<ReportsProvider>(
        context,
        listen: false,
      );

      // التحقق من إمكانية التصويت
      // إن كان البلاغ من Realtime DB قد يحمل معرف تقرير Firestore
      final targetId = reportData.relatedReportId ?? reportData.id;
      final reportDoc = await FirebaseFirestore.instance
          .collection('reports')
          .doc(targetId)
          .get();

      if (!reportDoc.exists) {
        throw 'البلاغ غير موجود';
      }

      final report = ReportModel.fromFirestore(reportDoc);

      // التحقق من التصويت المسبق
      if (report.confirmedBy.contains(currentUser.uid) ||
          report.deniedBy.contains(currentUser.uid)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لقد قمت بالتصويت على هذا البلاغ من قبل'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      // التحقق من أن المستخدم ليس منشئ البلاغ
      if (report.createdBy == currentUser.uid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكنك التصويت على بلاغك الخاص'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      // التصويت على البلاغ - استخدام relatedReportId إذا كان متاحاً، وإلا استخدام id
      bool success = await reportsProvider.voteOnReport(
        reportId: reportData.relatedReportId ?? reportData.id,
        userId: currentUser.uid,
        isTrue: isVerified,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isVerified ? 'تم تأكيد البلاغ بنجاح' : 'تم رفض البلاغ بنجاح',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: isVerified ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );

        // تحديث البيانات
        _loadReports();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reportsProvider.errorMessage ?? 'حدث خطأ في التصويت'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // دالة تحديث البلاغات
  void _loadReports() {
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    dashboardProvider.loadDashboardData();
  }


  // دالة مشاركة البلاغ
  void _shareEnhancedReport(
    String title,
    String distance,
    String time,
    String severity,
    NearbyReport? reportData,
  ) {
    final shareText =
        '''
تفاصيل البلاغ:
العنوان: $title
المسافة: $distance
الوقت: $time
الخطورة: $severity
${reportData != null ? 'الموقع: ${reportData.latitude}, ${reportData.longitude}' : ''}
    ''';

    // استخدام مكتبة share_plus لمشاركة البلاغ
    Share.share(shareText, subject: 'بلاغ من تطبيق SafeRoute');
  }

  // دالة بناء بطاقة الإحصائيات
  Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// Global function for building enhanced detail sections
Widget _buildEnhancedDetailSection(
  String title,
  IconData icon,
  String? content, {
  List<Widget>? children,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LiquidGlassTheme.getGradientByName(
                  'primary',
                ).colors.first.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: LiquidGlassTheme.getGradientByName(
                  'primary',
                ).colors.first,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        if (content != null) ...[
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
        if (children != null) ...[const SizedBox(height: 12), ...children],
      ],
    ),
  );
}
