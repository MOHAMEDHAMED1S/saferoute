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
  bool _showFabMenu = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // قائمة الرسائل التجريبية
  List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      userName: 'أحمد محمد',
      message: 'مرحباً جميعاً، هل يوجد ازدحام في شارع فلسطين؟',
      time: DateTime.now().subtract(Duration(minutes: 30)),
      isCurrentUser: false,
    ),
    ChatMessage(
      id: '2',
      userName: 'فاطمة علي',
      message: 'نعم، يوجد ازدحام شديد بسبب حادث مروري',
      time: DateTime.now().subtract(Duration(minutes: 25)),
      isCurrentUser: false,
    ),
    ChatMessage(
      id: '3',
      userName: 'محمد سالم',
      message: 'الطريق البديل عبر شارع الجامعة أفضل',
      time: DateTime.now().subtract(Duration(minutes: 20)),
      isCurrentUser: false,
    ),
    ChatMessage(
      id: '4',
      userName: 'أنت',
      message: 'شكراً لكم على التنبيه، سأسلك طريق بديل',
      time: DateTime.now().subtract(Duration(minutes: 15)),
      isCurrentUser: true,
    ),
    ChatMessage(
      id: '5',
      userName: 'سارة أحمد',
      message: 'الآن الطريق أصبح أفضل، تم حل المشكلة',
      time: DateTime.now().subtract(Duration(minutes: 5)),
      isCurrentUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userName: 'أنت',
            message: _messageController.text.trim(),
            time: DateTime.now(),
            isCurrentUser: true,
          ),
        );
      });
      _messageController.clear();
      _scrollToBottom();
    }
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
                      // Welcome section with avatar + notifications
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: LiquidGlassTheme.getGradientByName('primary').colors.first,
                                    child: const Icon(
                                      Icons.people,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  );
                                },
                              ),
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
                                      'مرحباً، ${authProvider.userModel?.name ?? 'المستخدم'} 👋',
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
                          IconButton(
                            icon: const Icon(Icons.notifications),
                            color: Colors.white,
                            onPressed: () {
                              // إشعارات
                            },
                          )
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
                              icon: Icon(Icons.chat, size: 20),
                              text: 'مجتمع التواصل',
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
                      _buildChatTab(),
                      _buildLeaderboardTab(),
                    ],
                  ),
                ),
              ],
            ),
            _buildFloatingReportMenu(),
          ],
        ),
      ),
    );
  }

  // قسم مجتمع التواصل (الشات مباشرة)
  Widget _buildChatTab() {
    return Column(
      children: [
        // Chat info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha((255 * 0.8).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '127 متصل',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'شات مجتمع الطريق الآمن',
                style: LiquidGlassTheme.headerTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        // Chat messages area
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              controller: _chatScrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
        ),
        
        // Message input
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blueAccent.withAlpha((255 * 0.3).toInt()),
              child: Text(
                message.userName.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!message.isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 12),
                    child: Text(
                      message.userName,
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                        fontSize: 12,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                LiquidGlassContainer(
                  type: message.isCurrentUser
                      ? LiquidGlassType.secondary
                      : LiquidGlassType.ultraLight,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: message.isCurrentUser
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                    bottomRight: message.isCurrentUser
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.message,
                        style: LiquidGlassTheme.bodyTextStyle.copyWith(
                          fontSize: 14,
                          color: message.isCurrentUser
                              ? Colors.white
                              : LiquidGlassTheme.primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.time),
                        style: LiquidGlassTheme.bodyTextStyle.copyWith(
                          fontSize: 10,
                          color: message.isCurrentUser
                              ? Colors.white60
                              : LiquidGlassTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (message.isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blueAccent,
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return authProvider.userModel?.photoUrl != null
                      ? ClipOval(
                          child: Image.asset(
                            authProvider.userModel!.photoUrl!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person, size: 16, color: Colors.white);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2196F3), // أزرق فاتح
            Color(0xFF00BCD4), // أزرق مخضر
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // أيقونة الموقع
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.location_on, color: Colors.white, size: 18),
                onPressed: () {
                  // مشاركة الموقع
                },
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          
          // أيقونة الإرفاق
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.white, size: 18),
                onPressed: () {
                  // إرفاق ملف
                },
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // مربع النص
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                textDirection: TextDirection.rtl,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                minLines: 1,
              ),
            ),
          ),
          
          // زر الإرسال
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF2196F3), size: 20),
                onPressed: _sendMessage,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
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
        _buildLeaderboardItem(rank: 1, name: 'أحمد محمد', points: 2450, isCurrentUser: false),
        const SizedBox(height: 12),
        _buildLeaderboardItem(rank: 2, name: 'فاطمة علي', points: 2100, isCurrentUser: false),
        const SizedBox(height: 12),
        _buildLeaderboardItem(rank: 3, name: 'محمد سالم', points: 1890, isCurrentUser: false),
        const SizedBox(height: 12),
        _buildLeaderboardItem(rank: 12, name: 'أنت', points: 1250, isCurrentUser: true),
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
          CircleAvatar(
            backgroundColor: Colors.blueAccent.withAlpha((255 * 0.15).toInt()),
            child: Text(
              '#$rank',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
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
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                    color: isCurrentUser ? Colors.blueAccent : null,
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
            Icon(
              Icons.emoji_events,
              color: rank == 1 ? Colors.amber : rank == 2 ? Colors.grey : Colors.orange,
              size: 22,
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingReportMenu() {
    return Positioned(
      bottom: 180, // رفع الزر لأعلى بحيث يظهر فوق منطقة الكتابة
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_showFabMenu) ...[
            _buildFabOption(Icons.warning, "حادث", Colors.redAccent),
            const SizedBox(height: 10),
            _buildFabOption(Icons.traffic, "ازدحام", Colors.orange),
            const SizedBox(height: 10),
            _buildFabOption(Icons.speed, "مطب", Colors.green),
            const SizedBox(height: 16),
          ],
          FloatingActionButton(
            backgroundColor: Color(0xFF2196F3),
            foregroundColor: Colors.white,
            elevation: 6,
            onPressed: () {
              setState(() {
                _showFabMenu = !_showFabMenu;
              });
            },
            child: AnimatedRotation(
              turns: _showFabMenu ? 0.125 : 0, // دوران 45 درجة عند الفتح
              duration: Duration(milliseconds: 200),
              child: Icon(_showFabMenu ? Icons.close : Icons.add, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFabOption(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        // تنفيذ الإجراء
        setState(() {
          _showFabMenu = false;
        });
        // يمكنك إضافة منطق إرسال البلاغ هنا
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.9).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          FloatingActionButton(
            heroTag: label,
            mini: true,
            backgroundColor: color,
            onPressed: () {},
            child: Icon(icon, size: 20),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} د';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} س';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}

// نموذج الرسالة
class ChatMessage {
  final String id;
  final String userName;
  final String message;
  final DateTime time;
  final bool isCurrentUser;

  ChatMessage({
    required this.id,
    required this.userName,
    required this.message,
    required this.time,
    required this.isCurrentUser,
  });
}