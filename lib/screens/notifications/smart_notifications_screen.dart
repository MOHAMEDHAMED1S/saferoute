import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/smart_notification_service.dart';
import '../../widgets/common/enhanced_ui_components.dart';
import '../../utils/responsive_utils.dart';


import 'dart:async';

class SmartNotificationsScreen extends StatefulWidget {
  const SmartNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<SmartNotificationsScreen> createState() => _SmartNotificationsScreenState();
}

class _SmartNotificationsScreenState extends State<SmartNotificationsScreen>
    with TickerProviderStateMixin {
  final SmartNotificationService _notificationService = SmartNotificationService();
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<SmartNotification> _notifications = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  StreamSubscription? _notificationSubscription;
  NotificationChannel? _selectedChannel;
  NotificationPriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeNotifications();
    _setupNotificationListener();
    _loadStats();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 3, vsync: this);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  Future<void> _initializeNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      await _notificationService.initialize();
      _loadNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تهيئة نظام الإشعارات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تهيئة النظام: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupNotificationListener() {
    _notificationSubscription = _notificationService.notifications.listen(
      (notification) {
        if (mounted) {
          setState(() {
            _notifications.insert(0, notification);
          });
          
          _showNotificationSnackBar(notification);
          HapticFeedback.lightImpact();
        }
      },
    );
  }

  void _loadNotifications() {
    final history = _notificationService.getNotificationHistory(
      channel: _selectedChannel,
      priority: _selectedPriority,
    );
    
    setState(() {
      _notifications = history;
    });
  }

  void _loadStats() {
    final stats = _notificationService.getNotificationStats();
    setState(() {
      _stats = stats;
    });
  }

  void _showNotificationSnackBar(SmartNotification notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(notification.body),
          ],
        ),
        backgroundColor: _getPriorityColor(notification.priority),
        duration: Duration(
          seconds: notification.priority == NotificationPriority.critical ? 10 : 4,
        ),
        action: SnackBarAction(
          label: 'عرض',
          textColor: Colors.white,
          onPressed: () => _showNotificationDetails(notification),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات الذكية'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الإشعارات', icon: Icon(Icons.notifications)),
            Tab(text: 'الإعدادات', icon: Icon(Icons.settings)),
            Tab(text: 'الإحصائيات', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'تصفية',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildNotificationsTab(),
            _buildSettingsTab(),
            _buildStatsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendTestNotification,
        tooltip: 'إرسال إشعار تجريبي',
        child: const Icon(Icons.add_alert),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return ResponsiveBuilder(
      builder: (context, sizingInfo) {
        return SingleChildScrollView(
          padding: ResponsiveUtils.getResponsivePadding(sizingInfo),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationsSummary(),
              const SizedBox(height: 24),
              _buildNotificationsList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationsSummary() {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    final criticalCount = _notifications
        .where((n) => n.priority == NotificationPriority.critical && !n.isRead)
        .length;
    
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملخص الإشعارات',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'إجمالي: ${_notifications.length} | غير مقروءة: $unreadCount',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
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
                Expanded(
                  child: _buildSummaryCard(
                    'غير مقروءة',
                    '$unreadCount',
                    Icons.mark_email_unread,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'حرجة',
                    '$criticalCount',
                    Icons.priority_high,
                    Colors.red,
                  ),
                ),
              ],
            ),
            if (unreadCount > 0) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: EnhancedButton(
                  onPressed: () {
                    for (final notification in _notifications) {
                      notification.isRead = true;
                    }
                    setState(() {});
                  },
                  style: EnhancedButtonStyle.outlined,
                  child: const Text('تحديد الكل كمقروء'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(76),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: EnhancedLoadingIndicator(),
        ),
      );
    }
    
    if (_notifications.isEmpty) {
      return GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.notifications_none,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(76),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد إشعارات',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ستظهر الإشعارات الذكية هنا عند توفرها',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(127),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: _notifications.map((notification) => 
        _buildNotificationItem(notification)
      ).toList(),
    );
  }

  Widget _buildNotificationItem(SmartNotification notification) {
    final priorityColor = _getPriorityColor(notification.priority);
    final channelIcon = _getChannelIcon(notification.channel);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicCard(
        child: InkWell(
          onTap: () => _showNotificationDetails(notification),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: priorityColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        channelIcon,
                        color: priorityColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getChannelName(notification.channel),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: priorityColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getPriorityName(notification.priority),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(notification.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(127),
                          ),
                        ),
                      ],
                    ),
                    if (!notification.isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notification.body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(
                      notification.isRead ? 178 : 229,
                    ),
                  ),
                ),
                if (notification.actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: notification.actions.take(2).map((action) {
                      return EnhancedButton(
                        onPressed: () => _handleNotificationAction(notification, action),
                        style: EnhancedButtonStyle.outlined,
                        child: Text(_getActionName(action)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ResponsiveBuilder(
      builder: (context, sizingInfo) {
        return SingleChildScrollView(
          padding: ResponsiveUtils.getResponsivePadding(sizingInfo),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChannelSettings(),
              const SizedBox(height: 24),
              _buildNotificationPreferences(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChannelSettings() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'قنوات الإشعارات',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...NotificationChannel.values.map((channel) {
              final isEnabled = _notificationService.isChannelEnabled(channel);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      _getChannelIcon(channel),
                      color: _getChannelColor(channel),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getChannelName(channel),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getChannelDescription(channel),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isEnabled,
                      onChanged: (value) {
                        _notificationService.setChannelEnabled(channel, value);
                        setState(() {
                          // Update UI to reflect channel state change
                        });
                        
                        HapticFeedback.lightImpact();
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationPreferences() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفضيلات الإشعارات',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPreferenceItem(
              'الصوت',
              'تشغيل الأصوات مع الإشعارات',
              Icons.volume_up,
              true,
              (value) {},
            ),
            _buildPreferenceItem(
              'الاهتزاز',
              'تشغيل الاهتزاز مع الإشعارات',
              Icons.vibration,
              true,
              (value) {},
            ),
            _buildPreferenceItem(
              'الساعات الهادئة',
              'تقليل الإشعارات في أوقات محددة',
              Icons.bedtime,
              false,
              (value) {},
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: EnhancedButton(
                onPressed: _showAdvancedSettings,
                style: EnhancedButtonStyle.outlined,
                child: const Text('إعدادات متقدمة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceItem(
    String title,
    String description,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return ResponsiveBuilder(
      builder: (context, sizingInfo) {
        return SingleChildScrollView(
          padding: ResponsiveUtils.getResponsivePadding(sizingInfo),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverallStats(),
              const SizedBox(height: 24),
              _buildChannelStats(),
              const SizedBox(height: 24),
              _buildPriorityStats(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverallStats() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Colors.purple,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'إحصائيات عامة',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'إجمالي الإشعارات',
                    '${_stats['total_active'] ?? 0}',
                    Icons.notifications,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'آخر 24 ساعة',
                    '${_stats['last_24h'] ?? 0}',
                    Icons.schedule,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'القنوات المفعلة',
                    '${_stats['channels_enabled'] ?? 0}/${_stats['total_channels'] ?? 0}',
                    Icons.radio_button_checked,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelStats() {
    final byChannel = _stats['by_channel'] as Map<String, dynamic>? ?? {};
    
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات القنوات',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (byChannel.isEmpty)
              Text(
                'لا توجد بيانات متاحة',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                ),
              )
            else
              ...byChannel.entries.map((entry) {
                final channel = NotificationChannel.values
                    .firstWhere((c) => c.name == entry.key);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        _getChannelIcon(channel),
                        color: _getChannelColor(channel),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getChannelName(channel),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getChannelColor(channel).withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: TextStyle(
                            color: _getChannelColor(channel),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityStats() {
    final byPriority = _stats['by_priority'] as Map<String, dynamic>? ?? {};
    
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات الأولوية',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (byPriority.isEmpty)
              Text(
                'لا توجد بيانات متاحة',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                ),
              )
            else
              ...byPriority.entries.map((entry) {
                final priority = NotificationPriority.values
                    .firstWhere((p) => p.name == entry.key);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        _getPriorityIcon(priority),
                        color: _getPriorityColor(priority),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getPriorityName(priority),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(priority).withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: TextStyle(
                            color: _getPriorityColor(priority),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(76),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.green;
      case NotificationPriority.medium:
        return Colors.orange;
      case NotificationPriority.high:
        return Colors.red;
      case NotificationPriority.critical:
        return Colors.red.shade900;
    }
  }

  IconData _getPriorityIcon(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Icons.low_priority;
      case NotificationPriority.medium:
        return Icons.priority_high;
      case NotificationPriority.high:
        return Icons.warning;
      case NotificationPriority.critical:
        return Icons.dangerous;
    }
  }

  String _getPriorityName(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'منخفضة';
      case NotificationPriority.medium:
        return 'متوسطة';
      case NotificationPriority.high:
        return 'عالية';
      case NotificationPriority.critical:
        return 'حرجة';
    }
  }

  IconData _getChannelIcon(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.safety:
        return Icons.security;
      case NotificationChannel.traffic:
        return Icons.traffic;
      case NotificationChannel.weather:
        return Icons.cloud;
      case NotificationChannel.route:
        return Icons.route;
      case NotificationChannel.ai:
        return Icons.psychology;
      case NotificationChannel.emergency:
        return Icons.emergency;
    }
  }

  Color _getChannelColor(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.safety:
        return Colors.red;
      case NotificationChannel.traffic:
        return Colors.orange;
      case NotificationChannel.weather:
        return Colors.blue;
      case NotificationChannel.route:
        return Colors.green;
      case NotificationChannel.ai:
        return Colors.purple;
      case NotificationChannel.emergency:
        return Colors.red.shade900;
    }
  }

  String _getChannelName(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.safety:
        return 'الأمان';
      case NotificationChannel.traffic:
        return 'المرور';
      case NotificationChannel.weather:
        return 'الطقس';
      case NotificationChannel.route:
        return 'الطرق';
      case NotificationChannel.ai:
        return 'الذكاء الاصطناعي';
      case NotificationChannel.emergency:
        return 'الطوارئ';
    }
  }

  String _getChannelDescription(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.safety:
        return 'تحذيرات الأمان والمخاطر';
      case NotificationChannel.traffic:
        return 'معلومات الازدحام المروري';
      case NotificationChannel.weather:
        return 'تحديثات الأحوال الجوية';
      case NotificationChannel.route:
        return 'اقتراحات الطرق البديلة';
      case NotificationChannel.ai:
        return 'تنبؤات الذكاء الاصطناعي';
      case NotificationChannel.emergency:
        return 'تحذيرات الطوارئ العاجلة';
    }
  }

  String _getActionName(String action) {
    switch (action) {
      case 'view_details':
        return 'عرض التفاصيل';
      case 'find_alternative':
        return 'طريق بديل';
      case 'view_weather':
        return 'عرض الطقس';
      case 'delay_trip':
        return 'تأجيل الرحلة';
      case 'view_traffic':
        return 'عرض المرور';
      case 'view_prediction':
        return 'عرض التنبؤ';
      case 'ignore':
        return 'تجاهل';
      case 'use_alternative':
        return 'استخدام البديل';
      case 'keep_current':
        return 'الاحتفاظ بالحالي';
      case 'call_emergency':
        return 'اتصال طوارئ';
      default:
        return action;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  // Event handlers
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية الإشعارات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<NotificationChannel?>(
              initialValue: _selectedChannel,
              decoration: const InputDecoration(labelText: 'القناة'),
              items: [
                const DropdownMenuItem(value: null, child: Text('جميع القنوات')),
                ...NotificationChannel.values.map((channel) => 
                  DropdownMenuItem(
                    value: channel,
                    child: Text(_getChannelName(channel)),
                  ),
                ),
              ],
              onChanged: (value) => _selectedChannel = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<NotificationPriority?>(
              initialValue: _selectedPriority,
              decoration: const InputDecoration(labelText: 'الأولوية'),
              items: [
                const DropdownMenuItem(value: null, child: Text('جميع الأولويات')),
                ...NotificationPriority.values.map((priority) => 
                  DropdownMenuItem(
                    value: priority,
                    child: Text(_getPriorityName(priority)),
                  ),
                ),
              ],
              onChanged: (value) => _selectedPriority = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadNotifications();
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  void _refreshData() {
    _loadNotifications();
    _loadStats();
    
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تحديث البيانات'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sendTestNotification() {
    _notificationService.sendCustomNotification(
      title: 'إشعار تجريبي',
      body: 'هذا إشعار تجريبي لاختبار النظام',
      channel: NotificationChannel.safety,
      priority: NotificationPriority.medium,
      actions: ['view_details', 'ignore'],
    );
    
    HapticFeedback.mediumImpact();
  }

  void _showNotificationDetails(SmartNotification notification) {
    // Mark as read
    notification.isRead = true;
    setState(() {
      // Update UI to reflect notification read status
    });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getChannelIcon(notification.channel),
                  size: 16,
                  color: _getChannelColor(notification.channel),
                ),
                const SizedBox(width: 8),
                Text(
                  _getChannelName(notification.channel),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  _formatTime(notification.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
          if (notification.actions.isNotEmpty)
            ...notification.actions.take(2).map((action) => 
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleNotificationAction(notification, action);
                },
                child: Text(_getActionName(action)),
              ),
            ),
        ],
      ),
    );
  }

  void _handleNotificationAction(SmartNotification notification, String action) {
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تنفيذ الإجراء: ${_getActionName(action)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }



  void _showAdvancedSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات متقدمة'),
        content: const Text(
          'ستتوفر الإعدادات المتقدمة في التحديثات القادمة:\n\n'
          '• تخصيص أوقات الإشعارات\n'
          '• قواعد الإشعارات المخصصة\n'
          '• تكامل مع التطبيقات الخارجية\n'
          '• إعدادات الذكاء الاصطناعي',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }
}