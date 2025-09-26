import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_service.dart';
import '../../models/chat_message.dart';
import '../../models/leaderboard_user.dart';
import '../../models/incident_report.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  bool _isLoading = true;
  bool _isSendingMessage = false;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  // Data from Backend
  List<ChatMessage> _messages = [];
  List<LeaderboardUser> _leaderboardUsers = [];
  int _onlineUsersCount = 0;

  // Services
  final CommunityService _communityService = CommunityService();

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _loadInitialData();
  }

  void _setupControllers() {
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });

    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus) {
        _scrollToBottom();
      }
    });

    // تهيئة خدمة المجتمع
    _communityService
        .initialize()
        .then((_) {
          // الاستماع إلى تحديثات الرسائل في الوقت الحقيقي
          _communityService.messageStream.listen((newMessage) {
            if (mounted) {
              setState(() {
                // تجنب إضافة الرسائل المكررة
                final existingIndex = _messages.indexWhere(
                  (msg) => msg.id == newMessage.id,
                );
                if (existingIndex != -1) {
                  // تحديث الرسالة الموجودة
                  _messages[existingIndex] = newMessage;
                } else {
                  // إضافة رسالة جديدة فقط إذا لم تكن موجودة
                  // وتجنب إضافة الرسائل المؤقتة مرة أخرى
                  final tempIndex = _messages.indexWhere(
                    (msg) =>
                        msg.userId == newMessage.userId &&
                        msg.message == newMessage.message &&
                        msg.id.startsWith('temp_') &&
                        msg.timestamp
                                .difference(newMessage.timestamp)
                                .abs()
                                .inSeconds <
                            5,
                  );

                  if (tempIndex != -1) {
                    // استبدال الرسالة المؤقتة بالرسالة الحقيقية
                    _messages[tempIndex] = newMessage;
                  } else {
                    // إضافة رسالة جديدة
                    _messages.add(newMessage);
                  }
                }
              });
              _scrollToBottom();
            }
          });

          // الاستماع إلى تحديثات عدد المستخدمين المتصلين
          _communityService.onlineCountStream.listen((count) {
            if (mounted) {
              setState(() {
                _onlineUsersCount = count;
              });
            }
          });
        })
        .catchError((error) {
          if (mounted) {
            _showErrorSnackBar('فشل في الاتصال بخدمة المجتمع');
          }
        });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load chat messages
      final messages = await _communityService.getChatMessages();

      // Load leaderboard
      final leaderboard = await _communityService.getLeaderboard();

      // Get online users count
      final onlineCount = await _communityService.getOnlineUsersCount();

      if (mounted) {
        setState(() {
          _messages = messages;
          _leaderboardUsers = leaderboard;
          _onlineUsersCount = onlineCount;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('حدث خطأ في تحميل البيانات');
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSendingMessage) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // إنشاء رسالة مؤقتة لعرضها فوراً
      final tempMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        userId: authProvider.userModel?.id ?? '',
        userName: authProvider.userModel?.name ?? 'مستخدم',
        message: messageText,
        timestamp: DateTime.now(),
        userAvatar: authProvider.userModel?.photoUrl,
        isDelivered: false, // مؤقتة - لم يتم التأكيد بعد
        isRead: false,
      );

      // إضافة الرسالة فوراً للواجهة
      setState(() {
        _messages.add(tempMessage);
      });
      _scrollToBottom();
      _messageController.clear();

      // إرسال الرسالة للخادم
      final sentMessage = await _communityService.sendChatMessage(
        userId: authProvider.userModel?.id ?? '',
        userName: authProvider.userModel?.name ?? 'مستخدم',
        message: messageText,
        userAvatar: authProvider.userModel?.photoUrl,
      );

      // تحديث الرسالة المؤقتة بالرسالة الحقيقية
      setState(() {
        final tempIndex = _messages.indexWhere(
          (msg) => msg.id == tempMessage.id,
        );
        if (tempIndex != -1) {
          _messages[tempIndex] = sentMessage.copyWith(
            isDelivered: true,
            isRead: false,
          );
        }
      });
    } catch (e) {
      // إزالة الرسالة المؤقتة في حالة الفشل
      setState(() {
        _messages.removeWhere((msg) => msg.id.startsWith('temp_'));
      });
      _showErrorSnackBar('فشل في إرسال الرسالة');
    } finally {
      setState(() {
        _isSendingMessage = false;
      });
    }
  }

  Future<void> _sendIncidentReport(IncidentType type) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await _communityService.sendIncidentReport(
        userId: authProvider.userModel?.id ?? '',
        userName: authProvider.userModel?.name ?? 'مستخدم',
        incidentType: type,
        // يمكن إضافة الموقع الحالي هنا
        // location: {'lat': latitude, 'lng': longitude},
      );

      _showSuccessSnackBar('تم إرسال البلاغ بنجاح');
    } catch (e) {
      _showErrorSnackBar('فشل في إرسال البلاغ');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    _messageFocusNode.dispose();
    _communityService.dispose();
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
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
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingWidget()
                      : TabBarView(
                          controller: _tabController,
                          children: [_buildChatTab(), _buildLeaderboardTab()],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LiquidGlassContainer(
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
                        color: LiquidGlassTheme.getGradientByName(
                          'primary',
                        ).colors.first,
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
                  // Navigate to notifications
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chat_bubble),
                color: Colors.white,
                onPressed: () {
                  // Navigate to community chat
                  Navigator.pushNamed(context, '/community-chat');
                },
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
                Tab(icon: Icon(Icons.chat, size: 20), text: 'مجتمع التواصل'),
                Tab(icon: Icon(Icons.leaderboard, size: 20), text: 'المتصدرين'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              LiquidGlassTheme.getGradientByName('primary').colors.first,
            ),
          ),
          const SizedBox(height: 16),
          Text('جاري تحميل البيانات...', style: LiquidGlassTheme.bodyTextStyle),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        _buildChatInfoBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadInitialData,
            child: _messages.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
                    controller: _chatScrollController,
                    // زيادة المساحة السفلية لمنع التداخل مع شريط الكتابة وقائمة التحذيرات
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
        ),
        _buildMessageInput(),
        // زيادة المساحة أسفل شريط الكتابة
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildChatInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
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
                  '$_onlineUsersCount متصل',
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
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: LiquidGlassTheme.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text('لا توجد رسائل بعد', style: LiquidGlassTheme.headerTextStyle),
          const SizedBox(height: 8),
          Text(
            'كن أول من يبدأ المحادثة',
            style: LiquidGlassTheme.bodyTextStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCurrentUser = message.userId == authProvider.userModel?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blueAccent.withAlpha((255 * 0.3).toInt()),
              backgroundImage: message.userAvatar != null
                  ? NetworkImage(message.userAvatar!)
                  : null,
              child: message.userAvatar == null
                  ? Text(
                      message.userName.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
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
                  type: isCurrentUser
                      ? LiquidGlassType.secondary
                      : LiquidGlassType.ultraLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isCurrentUser
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                    bottomRight: isCurrentUser
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
                          color: isCurrentUser
                              ? Colors.white
                              : LiquidGlassTheme.primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: LiquidGlassTheme.bodyTextStyle.copyWith(
                              fontSize: 10,
                              color: isCurrentUser
                                  ? Colors.white60
                                  : LiquidGlassTheme.secondaryTextColor,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isDelivered
                                  ? (message.isRead
                                        ? Icons.done_all
                                        : Icons.done)
                                  : Icons.access_time,
                              size: 12,
                              color: message.isRead
                                  ? Colors.blue
                                  : Colors.white60,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blueAccent,
              backgroundImage: authProvider.userModel?.photoUrl != null
                  ? NetworkImage(authProvider.userModel!.photoUrl!)
                  : null,
              child: authProvider.userModel?.photoUrl == null
                  ? const Icon(Icons.person, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 85),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          // Text input فقط
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 0.7),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                textDirection: TextDirection.rtl,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 4,
                minLines: 1,
              ),
            ),
          ),
          // زر الإرسال فقط
          Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _isSendingMessage
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF667eea),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: Color(0xFF667eea),
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                      padding: EdgeInsets.zero,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
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
            if (_leaderboardUsers.isEmpty)
              _buildEmptyLeaderboard()
            else
              ..._leaderboardUsers.asMap().entries.map((entry) {
                final index = entry.key;
                final user = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildLeaderboardItem(rank: index + 1, user: user),
                );
              }),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLeaderboard() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.leaderboard,
            size: 64,
            color: LiquidGlassTheme.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات متصدرين بعد',
            style: LiquidGlassTheme.headerTextStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    required LeaderboardUser user,
  }) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCurrentUser = user.userId == authProvider.userModel?.id;

    return LiquidGlassContainer(
      type: LiquidGlassType.secondary,
      isInteractive: true,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(16),
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? (rank == 1
                        ? Colors.amber
                        : rank == 2
                        ? Colors.grey[300]
                        : Colors.orange[300])
                  : Colors.blueAccent.withAlpha((255 * 0.15).toInt()),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      Icons.emoji_events,
                      color: rank == 1 ? Colors.white : Colors.grey[800],
                      size: 20,
                    )
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blueAccent.withAlpha((255 * 0.3).toInt()),
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.name.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: LiquidGlassTheme.headerTextStyle.copyWith(
                    fontSize: 15,
                    fontWeight: isCurrentUser
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: isCurrentUser ? Colors.blueAccent : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${user.points} نقطة',
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'أنت',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
