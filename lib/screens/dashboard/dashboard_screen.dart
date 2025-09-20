import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/add_report_screen.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/common/bottom_navigation_widget.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/dashboard';

  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String userName = "زياد";

  final List<Widget> _screens = [
    const DashboardHomeWidget(),
    const HomeScreen(),
    const AddReportScreen(),
    const Center(child: Text('المجتمع', style: TextStyle(fontSize: 24))),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF0A0E27),
      body: _screens[_currentIndex],
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
  const DashboardHomeWidget({Key? key}) : super(key: key);

  @override
  State<DashboardHomeWidget> createState() => _DashboardHomeWidgetState();
}

class _DashboardHomeWidgetState extends State<DashboardHomeWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, dashboardProvider, child) {
            if (dashboardProvider.isLoading) {
              return const Center(
                child: LiquidGlassLoadingIndicator(),
              );
            }

            return RefreshIndicator(
              onRefresh: dashboardProvider.refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Emergency Alert (if any)
                    if (dashboardProvider.currentAlert != null)
                      _buildEmergencyAlert(context, dashboardProvider.currentAlert!),
                    
                    // Header Section
                    _buildHeader(context),
                    
                    // Welcome Section
                    _buildWelcomeSection(dashboardProvider.weather),
                    
                    // Statistics Cards
                    _buildStatisticsCards(dashboardProvider.stats),
                    
                    // Quick Actions
                    _buildQuickActions(context),
                    
                    // Around You Section
                    _buildAroundYouSection(dashboardProvider.nearbyReports),
                    
                    // Safety Tip
                    _buildSafetyTip(dashboardProvider.dailyTip),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LiquidGlassContainer(
      type: LiquidGlassType.primary,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Row(
        children: [
          LiquidGlassContainer(
            type: LiquidGlassType.secondary,
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(16),
            child: const Icon(
              Icons.shield,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'سلامة السائقين',
              style: LiquidGlassTheme.primaryTextStyle.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          LiquidGlassContainer(
            type: LiquidGlassType.ultraLight,
            isInteractive: true,
            padding: const EdgeInsets.all(8),
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53935).withOpacity(0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          LiquidGlassContainer(
            type: LiquidGlassType.ultraLight,
            isInteractive: true,
            padding: const EdgeInsets.all(8),
            borderRadius: BorderRadius.circular(12),
            child: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(WeatherInfo weather) {
    final now = DateTime.now();
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');
    
    return LiquidGlassContainer(
      type: LiquidGlassType.secondary,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
                children: [
                  Text(
                    'مرحباً زياد! 👋',
                    style: LiquidGlassTheme.primaryTextStyle.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  LiquidGlassContainer(
                    type: LiquidGlassType.ultraLight,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          weather.icon,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${weather.temperature}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${timeFormat.format(now)} • ${dateFormat.format(now)}',
            style: LiquidGlassTheme.secondaryTextStyle.copyWith(
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                'رحلة آمنة اليوم • ${weather.drivingCondition}',
                style: LiquidGlassTheme.primaryTextStyle.copyWith(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(DashboardStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'المخاطر القريبة',
              '${stats.nearbyRisks}',
              'في دائرة 2 كم',
              Icons.warning,
              const Color(0xFFFFEBEE),
              const Color(0xFFE53935),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'نقاط الثقة',
              '${stats.trustPoints}',
              stats.trustLevel,
              Icons.star,
              const Color(0xFFE8F5E8),
              const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'البلاغات',
              '${stats.monthlyReports}',
              'هذا الشهر',
              Icons.report,
              const Color(0xFFE3F2FD),
              const Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, 
                       IconData icon, Color bgColor, Color iconColor) {
    return LiquidGlassContainer(
      type: LiquidGlassType.ultraLight,
      isInteractive: true,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          LiquidGlassContainer(
            type: LiquidGlassType.secondary,
            padding: const EdgeInsets.all(8),
            borderRadius: BorderRadius.circular(12),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: LiquidGlassTheme.primaryTextStyle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: LiquidGlassTheme.primaryTextStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: LiquidGlassTheme.secondaryTextStyle.copyWith(
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return LiquidGlassContainer(
      type: LiquidGlassType.ultraLight,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإجراءات السريعة',
            style: LiquidGlassTheme.primaryTextStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'إبلاغ سريع',
                  Icons.report_problem,
                  const Color(0xFFE53935),
                  () {
                    Navigator.pushNamed(context, AddReportScreen.routeName);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'عرض الخريطة',
                  Icons.map,
                  const Color(0xFF2196F3),
                  () {
                    Navigator.pushNamed(context, HomeScreen.routeName);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'إحصائياتي',
                  Icons.bar_chart,
                  const Color(0xFF4CAF50),
                  () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'المجتمع',
                  Icons.people,
                  const Color(0xFF9C27B0),
                  () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlassContainer(
        type: LiquidGlassType.secondary,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            LiquidGlassContainer(
              type: LiquidGlassType.primary,
              padding: const EdgeInsets.all(10),
              borderRadius: BorderRadius.circular(12),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
                title,
                style: LiquidGlassTheme.primaryTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildAroundYouSection(List<NearbyReport> reports) {
    return LiquidGlassContainer(
      type: LiquidGlassType.ultraLight,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ماذا يحدث حولك؟',
            style: LiquidGlassTheme.primaryTextStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...reports.map((report) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildReportCard(
              '${report.type.displayName} - ${report.title}',
              '${report.distance}م',
              report.timeAgo,
              report.confirmations,
              report.type.icon,
              report.type.color,
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String distance, String time, 
                         int confirmations, IconData icon, Color color) {
    return LiquidGlassContainer(
      type: LiquidGlassType.secondary,
      isInteractive: true,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(16),
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          LiquidGlassContainer(
            type: LiquidGlassType.primary,
            padding: const EdgeInsets.all(10),
            borderRadius: BorderRadius.circular(12),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LiquidGlassTheme.primaryTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$distance • $time',
                  style: LiquidGlassTheme.secondaryTextStyle.copyWith(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          LiquidGlassContainer(
            type: LiquidGlassType.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$confirmations',
                  style: LiquidGlassTheme.primaryTextStyle.copyWith(
                    fontSize: 13,
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

  Widget _buildSafetyTip(SafetyTip tip) {
    return LiquidGlassContainer(
      type: LiquidGlassType.secondary,
      isInteractive: true,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        children: [
          LiquidGlassContainer(
            type: LiquidGlassType.primary,
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(14),
            child: const Icon(
              Icons.lightbulb,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: LiquidGlassTheme.primaryTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tip.content,
                  style: LiquidGlassTheme.secondaryTextStyle.copyWith(
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

  Widget _buildEmergencyAlert(BuildContext context, EmergencyAlert alert) {
    Color alertColor;
    IconData alertIcon;
    
    switch (alert.severity) {
      case AlertSeverity.low:
        alertColor = Colors.yellow;
        alertIcon = Icons.info;
        break;
      case AlertSeverity.medium:
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        break;
      case AlertSeverity.high:
        alertColor = Colors.red;
        alertIcon = Icons.error;
        break;
      case AlertSeverity.critical:
        alertColor = Colors.red.shade900;
        alertIcon = Icons.dangerous;
        break;
    }

    return LiquidGlassContainer(
      type: LiquidGlassType.primary,
      isInteractive: true,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        children: [
          LiquidGlassContainer(
            type: LiquidGlassType.secondary,
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(14),
            child: Icon(
              alertIcon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تنبيه طوارئ',
                  style: LiquidGlassTheme.primaryTextStyle.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.message,
                  style: LiquidGlassTheme.primaryTextStyle.copyWith(
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${alert.location} • ${alert.distanceText}',
                  style: LiquidGlassTheme.secondaryTextStyle.copyWith(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          LiquidGlassButton(
            text: '',
            onPressed: () {
              // إخفاء التنبيه
            },
            type: LiquidGlassType.secondary,
            borderRadius: 12,
            padding: const EdgeInsets.all(8),
            icon: Icons.close,
          ),
        ],
      ),
    );
  }
}