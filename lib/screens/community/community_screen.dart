import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';
import '../../providers/auth_provider.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LiquidGlassTheme.mainBackgroundGradient,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Header with user info and tabs
                LiquidGlassContainer(
                  type: LiquidGlassType.toolbar,
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  child: Column(
                    children: [
                      // Welcome section
                      Row(
                        children: [
                          LiquidGlassContainer(
                            type: LiquidGlassType.primary,
                            padding: const EdgeInsets.all(12),
                            borderRadius: BorderRadius.circular(16),
                            child: const Icon(
                              Icons.people,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, child) {
                                    return Text(
                                      'مرحباً، ${authProvider.userModel?.name ?? 'المستخدم'}',
                                      style: LiquidGlassTheme.primaryTextStyle.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'مجتمع الطريق الآمن',
                                  style: LiquidGlassTheme.bodyTextStyle.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Tab bar
                      LiquidGlassContainer(
                        type: LiquidGlassType.secondary,
                        borderRadius: BorderRadius.circular(16),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            gradient: LiquidGlassTheme.communityActionGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: LiquidGlassTheme.secondaryTextColor,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.timeline, size: 20),
                              text: 'النشاطات',
                            ),
                            Tab(
                              icon: Icon(Icons.leaderboard, size: 20),
                              text: 'المتصدرين',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActivityTab(),
                      _buildLeaderboardTab(),
                    ],
                  ),
                ),
              ],
            ),
            _buildFloatingReportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsSection(),
          const SizedBox(height: 24),
          _buildRecentActivitiesSection(),
          const SizedBox(height: 24),
          _buildAchievementsSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeaderboardSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إحصائياتك',
          style: LiquidGlassTheme.headerTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.report,
                title: 'البلاغات',
                value: '24',
                subtitle: 'هذا الشهر',
                color: LiquidGlassTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star,
                title: 'النقاط',
                value: '1,250',
                subtitle: 'المجموع',
                color: LiquidGlassTheme.accentColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up,
                title: 'الترتيب',
                value: '#12',
                subtitle: 'هذا الأسبوع',
                color: LiquidGlassTheme.successColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: LiquidGlassTheme.headerTextStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: LiquidGlassTheme.primaryTextStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: LiquidGlassTheme.bodyTextStyle.copyWith(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'النشاطات الحديثة',
          style: LiquidGlassTheme.headerTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActivityCard(
          icon: Icons.report_problem,
          title: 'بلاغ جديد',
          description: 'تم إرسال بلاغ حادث مروري',
          time: 'منذ 5 دقائق',
          color: LiquidGlassTheme.primaryColor,
        ),
        const SizedBox(height: 12),
        _buildActivityCard(
          icon: Icons.star,
          title: 'نقاط جديدة',
          description: 'حصلت على 50 نقطة',
          time: 'منذ ساعة',
          color: LiquidGlassTheme.accentColor,
        ),
        const SizedBox(height: 12),
        _buildActivityCard(
          icon: Icons.verified,
          title: 'تأكيد بلاغ',
          description: 'تم تأكيد بلاغك من قبل المجتمع',
          time: 'منذ 3 ساعات',
          color: LiquidGlassTheme.successColor,
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required Color color,
  }) {
    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LiquidGlassTheme.primaryTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(
                    fontSize: 12,
                    color: LiquidGlassTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
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
          style: LiquidGlassTheme.headerTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAchievementCard(
                icon: '🏆',
                title: 'مبلغ نشط',
                description: '10 بلاغات',
                isUnlocked: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAchievementCard(
                icon: '⭐',
                title: 'نجم المجتمع',
                description: '100 نقطة',
                isUnlocked: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAchievementCard(
                icon: '🎯',
                title: 'هدف الشهر',
                description: '50 بلاغ',
                isUnlocked: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementCard({
    required String icon,
    required String title,
    required String description,
    required bool isUnlocked,
  }) {
    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: 32,
              color: isUnlocked ? null : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: LiquidGlassTheme.primaryTextStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? null : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: LiquidGlassTheme.bodyTextStyle.copyWith(
              fontSize: 12,
              color: isUnlocked ? LiquidGlassTheme.secondaryTextColor : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المتصدرين هذا الأسبوع',
          style: LiquidGlassTheme.headerTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildLeaderboardItem(
          rank: 1,
          name: 'أحمد محمد',
          points: 2450,
          avatar: '👨',
          isCurrentUser: false,
        ),
        const SizedBox(height: 12),
        _buildLeaderboardItem(
          rank: 2,
          name: 'فاطمة علي',
          points: 2100,
          avatar: '👩',
          isCurrentUser: false,
        ),
        const SizedBox(height: 12),
        _buildLeaderboardItem(
          rank: 3,
          name: 'محمد سالم',
          points: 1890,
          avatar: '👨',
          isCurrentUser: false,
        ),
        const SizedBox(height: 12),
        _buildLeaderboardItem(
          rank: 12,
          name: 'أنت',
          points: 1250,
          avatar: '👤',
          isCurrentUser: true,
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    required String name,
    required int points,
    required String avatar,
    required bool isCurrentUser,
  }) {
    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? LiquidGlassTheme.primaryColor.withOpacity(0.1)
                  : LiquidGlassTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: LiquidGlassTheme.primaryTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser 
                      ? LiquidGlassTheme.primaryColor
                      : LiquidGlassTheme.accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            avatar,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: LiquidGlassTheme.primaryTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser ? LiquidGlassTheme.primaryColor : null,
                  ),
                ),
                Text(
                  '$points نقطة',
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (rank <= 3)
            Text(
              rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
              style: const TextStyle(fontSize: 24),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingReportButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: LiquidGlassButton(
        text: 'إبلاغ',
        icon: Icons.report_problem,
        onPressed: () {
          // Navigate to report screen
        },
        type: LiquidGlassType.primary,
        borderRadius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}