import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/add_report_screen.dart';
import '../community/community_screen.dart';
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
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: LiquidGlassTheme.backgroundColor,
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
      backgroundColor: LiquidGlassTheme.backgroundColor,
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
            child: Icon(
              Icons.shield,
              color: LiquidGlassTheme.getIconColor('primary'),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'سلامة السائقين',
              style: LiquidGlassTheme.headerTextStyle.copyWith(
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
                Icon(
                  Icons.notifications_outlined,
                  color: LiquidGlassTheme.getTextColor('primary'),
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: LiquidGlassTheme.getGradientByName('danger').colors,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: LiquidGlassTheme.getGradientByName('danger').colors.first.withAlpha(127),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: LiquidGlassTheme.getIconColor('primary'),
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
            child: Icon(
              Icons.settings_outlined,
              color: LiquidGlassTheme.getTextColor('primary'),
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
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LiquidGlassTheme.getGradientByName('primary').colors.first,
            LiquidGlassTheme.getGradientByName('info').colors.first,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: LiquidGlassTheme.getGradientByName('primary').colors.first.withAlpha(76),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LiquidGlassContainer(
        type: LiquidGlassType.secondary,
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً زياد! 👋',
                      style: LiquidGlassTheme.headerTextStyle.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${timeFormat.format(now)} • ${dateFormat.format(now)}',
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ],
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
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Text(
                            '${weather.temperature}°',
                            style: TextStyle(
                              color: LiquidGlassTheme.getTextColor('primary'),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            weather.condition,
                            style: TextStyle(
                              color: LiquidGlassTheme.getTextColor('primary'),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.directions_car, color: LiquidGlassTheme.getIconColor('primary'), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'رحلة آمنة اليوم • ${weather.drivingCondition}',
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // زر وضع القيادة الجديد
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    LiquidGlassTheme.getGradientByName('primary').colors.first,
                    LiquidGlassTheme.getGradientByName('primary').colors.last,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: LiquidGlassTheme.getGradientByName('primary').colors.first.withAlpha(102),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/driving-mode');
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.drive_eta,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '⚡ وضع القيادة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ملاحة ذكية مع تحذيرات فورية',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(229),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
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
              Icons.dangerous,
              LiquidGlassTheme.getGradientByName('danger'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'نقاط الثقة',
              '${stats.trustPoints}',
              stats.trustLevel,
              Icons.star_rounded,
              LiquidGlassTheme.getGradientByName('warning'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'البلاغات',
              '${stats.monthlyReports}',
              'هذا الشهر',
              Icons.report_problem,
              LiquidGlassTheme.getGradientByName('info'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, 
                       IconData icon, Gradient gradient) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withAlpha(76),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LiquidGlassContainer(
        type: LiquidGlassType.ultraLight,
        isInteractive: true,
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: gradient.colors.first.withAlpha(51),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: gradient.colors.first, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: LiquidGlassTheme.headerTextStyle.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: LiquidGlassTheme.primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: LiquidGlassTheme.headerTextStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: LiquidGlassTheme.primaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: LiquidGlassTheme.bodyTextStyle.copyWith(
                fontSize: 11,
                color: LiquidGlassTheme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
            style: LiquidGlassTheme.headerTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: LiquidGlassTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          // الأزرار الرئيسية - أكبر حجماً
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'إبلاغ سريع',
                  Icons.report_problem,
                  LiquidGlassTheme.getGradientByName('danger'),
                  () {
                    Navigator.pushNamed(context, AddReportScreen.routeName);
                  },
                  isLarge: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'عرض الخريطة',
                  Icons.map,
                  LiquidGlassTheme.getGradientByName('info'),
                  () {
                    Navigator.pushNamed(context, HomeScreen.routeName);
                  },
                  isLarge: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // الأزرار الثانوية
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'طرق آمنة',
                  Icons.route,
                  LiquidGlassTheme.getGradientByName('success'),
                  () => Navigator.pushNamed(context, '/safe-routes'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'إعدادات سريعة',
                  Icons.settings,
                  LiquidGlassTheme.getGradientByName('secondary'),
                  () => Navigator.pushNamed(context, '/quick-settings'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'المجتمع',
                  Icons.people,
                  LiquidGlassTheme.getGradientByName('accent'),
                  () => Navigator.pushNamed(context, '/community'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Gradient gradient, VoidCallback onTap, {bool isLarge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(isLarge ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withAlpha(76),
              blurRadius: isLarge ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LiquidGlassContainer(
          type: LiquidGlassType.ultraLight,
          isInteractive: true,
          padding: EdgeInsets.all(isLarge ? 20 : 14),
          borderRadius: BorderRadius.circular(isLarge ? 20 : 16),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isLarge ? 14 : 10),
                decoration: BoxDecoration(
                  color: gradient.colors.first.withAlpha(51),
                  borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
                ),
                child: Icon(
                  icon, 
                  color: gradient.colors.first, 
                  size: isLarge ? 28 : 22,
                ),
              ),
              SizedBox(height: isLarge ? 14 : 10),
              Text(
                title,
                style: LiquidGlassTheme.bodyTextStyle.copyWith(
                  fontSize: isLarge ? 14 : 11,
                  fontWeight: FontWeight.w600,
                  color: LiquidGlassTheme.primaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ماذا يحدث حولك؟',
                style: LiquidGlassTheme.headerTextStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LiquidGlassTheme.getGradientByName('primary'),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'خريطة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // فلاتر ذكية
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('الكل', true),
                const SizedBox(width: 8),
                _buildFilterChip('500م', false),
                const SizedBox(width: 8),
                _buildFilterChip('1كم', false),
                const SizedBox(width: 8),
                _buildFilterChip('حوادث', false),
                const SizedBox(width: 8),
                _buildFilterChip('ازدحام', false),
                const SizedBox(width: 8),
                _buildFilterChip('صيانة', false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...reports.map((report) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildReportCard(
              '${report.type.displayName} - ${report.title}',
              '${report.distance}م',
              report.timeAgo,
              report.type.icon,
              LiquidGlassTheme.getGradientByName('primary'),
              severity: 'متوسط',
              affectedCars: 5,
              distance: '${report.distance}م',
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: isSelected 
            ? LiquidGlassTheme.getGradientByName('primary')
            : null,
        color: isSelected 
            ? null 
            : LiquidGlassTheme.getTextColor('primary').withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: isSelected 
            ? null 
            : Border.all(
                color: LiquidGlassTheme.getTextColor('primary').withAlpha(51),
                width: 1,
              ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected 
              ? Colors.white 
              : LiquidGlassTheme.getTextColor('primary'),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String location, String time, 
                          IconData icon, Gradient gradient, {
                          required String severity,
                          required int affectedCars,
                          required String distance}) {
    Color severityColor = severity == 'عالي' 
        ? LiquidGlassTheme.getGradientByName('danger').colors.first
        : severity == 'متوسط'
        ? LiquidGlassTheme.getGradientByName('warning').colors.first
        : LiquidGlassTheme.getGradientByName('success').colors.first;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LiquidGlassContainer(
        type: LiquidGlassType.secondary,
        isInteractive: true,
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: gradient.colors.first.withAlpha(51),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: gradient.colors.first, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: LiquidGlassTheme.headerTextStyle.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: LiquidGlassTheme.primaryTextColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: severityColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              severity,
                              style: TextStyle(
                                color: severityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        location,
                        style: LiquidGlassTheme.bodyTextStyle.copyWith(
                          fontSize: 13,
                          color: LiquidGlassTheme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: LiquidGlassTheme.secondaryTextColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              time,
                              style: LiquidGlassTheme.bodyTextStyle.copyWith(
                                fontSize: 10,
                                color: LiquidGlassTheme.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: LiquidGlassTheme.secondaryTextColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              distance,
                              style: LiquidGlassTheme.bodyTextStyle.copyWith(
                                fontSize: 10,
                                color: LiquidGlassTheme.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.directions_car,
                              size: 12,
                              color: LiquidGlassTheme.secondaryTextColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$affectedCars سيارة',
                              style: LiquidGlassTheme.bodyTextStyle.copyWith(
                                fontSize: 10,
                                color: LiquidGlassTheme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                // إذا كان العرض صغير جداً، استخدم عمود بدلاً من صف
                if (constraints.maxWidth < 250) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildReportActionButton(
                              'أؤكد',
                              Icons.check_circle,
                              LiquidGlassTheme.getGradientByName('success'),
                              () {},
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildReportActionButton(
                              'تفاصيل',
                              Icons.info,
                              LiquidGlassTheme.getGradientByName('secondary'),
                              () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildReportActionButton(
                        'طريق بديل',
                        Icons.alt_route,
                        LiquidGlassTheme.getGradientByName('primary'),
                        () {},
                      ),
                    ],
                  );
                }
                // العرض الطبيعي
                else {
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildReportActionButton(
                          'أؤكد',
                          Icons.check_circle,
                          LiquidGlassTheme.getGradientByName('success'),
                          () {},
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 3,
                        child: _buildReportActionButton(
                          'طريق بديل',
                          Icons.alt_route,
                          LiquidGlassTheme.getGradientByName('primary'),
                          () {},
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: _buildReportActionButton(
                          'تفاصيل',
                          Icons.info,
                          LiquidGlassTheme.getGradientByName('secondary'),
                          () {},
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportActionButton(String text, IconData icon, Gradient gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withAlpha(76),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LiquidGlassContainer(
          type: LiquidGlassType.ultraLight,
          isInteractive: true,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // إذا كان العرض صغير جداً، اعرض الأيقونة فقط
              if (constraints.maxWidth < 60) {
                return Icon(
                  icon,
                  color: Colors.white,
                  size: 12,
                );
              }
              // إذا كان العرض متوسط، اعرض الأيقونة والنص مع تقليل الحجم
              else if (constraints.maxWidth < 80) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 10,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              }
              // العرض الطبيعي
              else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
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
            child: Icon(
              Icons.lightbulb,
              color: LiquidGlassTheme.getTextColor('primary'),
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
                  style: LiquidGlassTheme.headerTextStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
                ),
                const SizedBox(height: 8),
                Text(
                  tip.content,
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(
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
        alertColor = LiquidGlassTheme.getGradientByName('warning').colors.first;
        alertIcon = Icons.info;
        break;
      case AlertSeverity.medium:
        alertColor = LiquidGlassTheme.getGradientByName('warning').colors.last;
        alertIcon = Icons.warning;
        break;
      case AlertSeverity.high:
        alertColor = LiquidGlassTheme.getGradientByName('danger').colors.first;
        alertIcon = Icons.error;
        break;
      case AlertSeverity.critical:
        alertColor = LiquidGlassTheme.getGradientByName('danger').colors.last;
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
              color: LiquidGlassTheme.getTextColor('primary'),
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
                  style: LiquidGlassTheme.headerTextStyle.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.message,
                  style: LiquidGlassTheme.headerTextStyle.copyWith(
                fontSize: 15,
              ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${alert.location} • ${alert.distanceText}',
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(
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