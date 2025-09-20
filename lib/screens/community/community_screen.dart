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
                color: Colors.white,
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
    return LiquidGlassContainer(
      type: LiquidGlassType.ultraLight,
      isInteractive: true,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: LiquidGlassTheme.headerTextStyle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: LiquidGlassTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: LiquidGlassTheme.headerTextStyle.copyWith(
              fontSize: 13,
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
            child: Icon(icon, color: LiquidGlassTheme.getIconColor('primary'), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LiquidGlassTheme.headerTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(
                    fontSize: 13,
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
                 icon: Icons.emoji_events,
                 title: 'مبلغ نشط',
                 description: '10 بلاغات',
                 isUnlocked: true,
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: _buildAchievementCard(
                 icon: Icons.star,
                 title: 'نجم المجتمع',
                 description: '100 نقطة',
                 isUnlocked: true,
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: _buildAchievementCard(
                 icon: Icons.track_changes,
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
     required IconData icon,
     required String title,
     required String description,
     required bool isUnlocked,
   }) {
     return LiquidGlassContainer(
       type: LiquidGlassType.ultraLight,
       isInteractive: true,
       padding: const EdgeInsets.all(18),
       borderRadius: BorderRadius.circular(16),
       child: Column(
         children: [
           LiquidGlassContainer(
             type: LiquidGlassType.primary,
             padding: const EdgeInsets.all(10),
             borderRadius: BorderRadius.circular(12),
             child: Icon(
               icon,
               size: 22,
               color: isUnlocked 
                   ? LiquidGlassTheme.getIconColor('primary')
                   : Colors.grey,
             ),
           ),
          const SizedBox(height: 12),
          Text(
            title,
            style: LiquidGlassTheme.headerTextStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? LiquidGlassTheme.primaryTextColor : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: LiquidGlassTheme.bodyTextStyle.copyWith(
              fontSize: 11,
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
           isCurrentUser: false,
         ),
         const SizedBox(height: 12),
         _buildLeaderboardItem(
           rank: 2,
           name: 'فاطمة علي',
           points: 2100,
           isCurrentUser: false,
         ),
         const SizedBox(height: 12),
         _buildLeaderboardItem(
           rank: 3,
           name: 'محمد سالم',
           points: 1890,
           isCurrentUser: false,
         ),
         const SizedBox(height: 12),
         _buildLeaderboardItem(
           rank: 12,
           name: 'أنت',
           points: 1250,
           isCurrentUser: true,
         ),
      ],
    );
  }

  Widget _buildLeaderboardItem({
     required int rank,
     required String name,
     required int points,
     required bool isCurrentUser,
   }) {
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
             child: Text(
               '#$rank',
               style: LiquidGlassTheme.headerTextStyle.copyWith(
                 fontSize: 14,
                 fontWeight: FontWeight.bold,
                 color: LiquidGlassTheme.getIconColor('primary'),
               ),
             ),
           ),
           const SizedBox(width: 16),
           LiquidGlassContainer(
             type: LiquidGlassType.primary,
             padding: const EdgeInsets.all(10),
             borderRadius: BorderRadius.circular(12),
             child: Icon(
               Icons.person,
               color: LiquidGlassTheme.getIconColor('primary'),
               size: 20,
             ),
           ),
           const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: LiquidGlassTheme.headerTextStyle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$points نقطة',
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (rank <= 3)
             LiquidGlassContainer(
               type: LiquidGlassType.primary,
               padding: const EdgeInsets.all(8),
               borderRadius: BorderRadius.circular(12),
               child: Icon(
                 Icons.emoji_events,
                 color: rank == 1 
                     ? Colors.amber
                     : rank == 2 
                         ? Colors.grey[600]
                         : Colors.orange,
                 size: 18,
               ),
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