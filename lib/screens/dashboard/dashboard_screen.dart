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
              return const Center(child: LiquidGlassLoadingIndicator());
            }

            return RefreshIndicator(
              onRefresh: dashboardProvider.refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Emergency Alert (if any)
                    if (dashboardProvider.currentAlert != null)
                      _buildEmergencyAlert(
                        context,
                        dashboardProvider.currentAlert!,
                      ),

                    // Header Section
                    _buildHeader(context),

                    // Welcome Section
                    _buildWelcomeSection(dashboardProvider.weather),

                    // Statistics Cards
                    _buildStatisticsCards(dashboardProvider.stats),

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
                        colors: LiquidGlassTheme.getGradientByName(
                          'danger',
                        ).colors,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: LiquidGlassTheme.getGradientByName(
                            'danger',
                          ).colors.first.withAlpha(127),
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
            color: LiquidGlassTheme.getGradientByName(
              'primary',
            ).colors.first.withAlpha(76),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(weather.icon, style: const TextStyle(fontSize: 20)),
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
                Icon(
                  Icons.directions_car,
                  color: LiquidGlassTheme.getIconColor('primary'),
                  size: 24,
                ),
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
            // زر وضع القيادة المحسن
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 350;
                return Container(
                  width: double.infinity,
                  height: isSmallScreen ? 70 : 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        LiquidGlassTheme.getGradientByName('primary').colors.first,
                        LiquidGlassTheme.getGradientByName('primary').colors.last,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: LiquidGlassTheme.getGradientByName(
                          'primary',
                        ).colors.first.withAlpha(102),
                        blurRadius: isSmallScreen ? 15 : 20,
                        offset: Offset(0, isSmallScreen ? 6 : 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/driving-mode');
                      },
                      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                              ),
                              child: Icon(
                                Icons.drive_eta,
                                color: Colors.white,
                                size: isSmallScreen ? 24 : 28,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '⚡ وضع القيادة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: isSmallScreen ? 2 : 4),
                                  Flexible(
                                    child: Text(
                                      'ملاحة ذكية مع تحذيرات فورية',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(229),
                                        fontSize: isSmallScreen ? 12 : 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Gradient gradient,
  ) {
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



  Widget _buildDestinationSearch(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDestinationSearchDialog(context),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey.shade50, Colors.grey.shade100],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'إلى أين تريد الذهاب؟',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.my_location_rounded,
                color: Colors.orange.shade600,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDestinationSearchDialog(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    final List<String> suggestions = [
      'مول العرب',
      'مطار القاهرة الدولي',
      'جامعة القاهرة',
      'ميدان التحرير',
      'مدينة نصر',
      'المعادي',
      'الزمالك',
      'مصر الجديدة',
      'شارع التحرير',
      'كوبري أكتوبر',
    ];

    List<String> filteredSuggestions = suggestions;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: LiquidGlassContainer(
            type: LiquidGlassType.primary,
            padding: const EdgeInsets.all(20),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'اختر وجهتك',
                        style: LiquidGlassTheme.headerTextStyle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: LiquidGlassTheme.getIconColor('primary'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      filteredSuggestions = suggestions
                          .where((suggestion) => suggestion.contains(value))
                          .toList();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مكان...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: LiquidGlassTheme.getIconColor('secondary'),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: LiquidGlassTheme.getIconColor('secondary'),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: LiquidGlassTheme.getIconColor('accent'),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = filteredSuggestions[index];
                      return ListTile(
                        leading: Icon(
                          Icons.location_on,
                          color: LiquidGlassTheme.getIconColor('accent'),
                        ),
                        title: Text(
                          suggestion,
                          style: LiquidGlassTheme.bodyTextStyle,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToDestination(context, suggestion);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDestination(BuildContext context, String destination) {
    // Navigate to map with destination
    Navigator.pushNamed(
      context,
      HomeScreen.routeName,
      arguments: {'destination': destination},
    );
  }


  Widget _buildAroundYouSection(List<NearbyReport> reports) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withAlpha(240), Colors.white.withAlpha(220)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.blue.withAlpha(12),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
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
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(76),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.map_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      const Text(
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
            const SizedBox(height: 20),
            // فلاتر ذكية محسنة
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildEnhancedFilterChip('الكل', true, Icons.apps_rounded),
                  const SizedBox(width: 10),
                  _buildEnhancedFilterChip(
                    '500م',
                    false,
                    Icons.near_me_rounded,
                  ),
                  const SizedBox(width: 10),
                  _buildEnhancedFilterChip(
                    '1كم',
                    false,
                    Icons.location_searching_rounded,
                  ),
                  const SizedBox(width: 10),
                  _buildEnhancedFilterChip(
                    'حوادث',
                    false,
                    Icons.warning_rounded,
                  ),
                  const SizedBox(width: 10),
                  _buildEnhancedFilterChip(
                    'ازدحام',
                    false,
                    Icons.traffic_rounded,
                  ),
                  const SizedBox(width: 10),
                  _buildEnhancedFilterChip(
                    'صيانة',
                    false,
                    Icons.construction_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...reports.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEnhancedReportCard(
                  '${report.type.displayName} - ${report.title}',
                  '${report.distance}م',
                  report.timeAgo,
                  report.type.icon,
                  severity: 'متوسط',
                  affectedCars: 5,
                ),
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
    required int affectedCars,
  }) {
    final severityColor = _getSeverityColor(severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withAlpha(76), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: severityColor.withAlpha(29),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(12),
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
                  color: severityColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: severityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.grey.shade500,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                distance,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.directions_car_outlined,
                color: Colors.grey.shade500,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '$affectedCars سيارات متأثرة',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(76),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'تفاصيل',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Text(
                    'مشاركة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFilterChip(
    String label,
    bool isSelected,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              )
            : null,
        color: isSelected ? null : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? null
            : Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.blue.withAlpha(76),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey.shade600,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'عالي':
        return LiquidGlassTheme.getGradientByName('danger').colors.first;
      case 'متوسط':
        return LiquidGlassTheme.getGradientByName('warning').colors.first;
      case 'منخفض':
      default:
        return LiquidGlassTheme.getGradientByName('success').colors.first;
    }
  }

  Widget _buildEmergencyAlert(BuildContext context, dynamic alert) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red.shade700, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert?.message ?? 'تنبيه طارئ!',
              style: TextStyle(
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(dynamic tip) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: Colors.green.shade700, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip != null && tip is SafetyTip
                  ? tip.content
                  : 'تأكد من ربط حزام الأمان دائماً!',
              style: TextStyle(
                color: Colors.green.shade900,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}