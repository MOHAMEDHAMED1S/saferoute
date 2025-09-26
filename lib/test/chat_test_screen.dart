import 'package:flutter/material.dart';
import 'package:saferoute/services/community_service.dart';
import 'package:saferoute/models/chat_message.dart';

/// ملف تجريبي لاختبار وظائف الشات المجتمعي
/// يمكن استخدام هذا الملف لاختبار جميع وظائف الشات
class ChatTestScreen extends StatefulWidget {
  const ChatTestScreen({super.key});

  @override
  State<ChatTestScreen> createState() => _ChatTestScreenState();
}

class _ChatTestScreenState extends State<ChatTestScreen> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  int _onlineUsersCount = 0;
  bool _isInitialized = false;
  String currentUserName = 'أحمد'; // اسم المستخدم الفعلي
  final TextEditingController _nameController = TextEditingController(
    text: 'أحمد',
  );

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      await _communityService.initialize();

      // الاستماع للرسائل الجديدة
      _communityService.messageStream.listen((message) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == message.id);
          if (idx == -1) {
            _messages.add(message); // رسالة جديدة
          } else {
            _messages[idx] = message; // تحديث رسالة معدلة
          }
          // ترتيب الرسائل دائماً حسب timestamp
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
      });

      // الاستماع لتحديث عدد المستخدمين المتصلين
      _communityService.onlineCountStream.listen((count) {
        debugPrint('تحديث عدد المستخدمين المتصلين: $count');
        setState(() {
          _onlineUsersCount = count;
        });
      });

      // جلب الرسائل الموجودة
      final messages = await _communityService.getChatMessages();
      debugPrint('تم جلب ${messages.length} رسالة موجودة');
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isInitialized = true;
      });

      // جلب عدد المستخدمين المتصلين
      final onlineCount = await _communityService.getOnlineUsersCount();
      setState(() {
        _onlineUsersCount = onlineCount;
      });
    } catch (e) {
      debugPrint('خطأ في تهيئة الشات: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      debugPrint('إرسال رسالة: $messageText');
      final sentMessage = await _communityService.sendChatMessage(
        userId: 'test_user_123',
        userName: currentUserName, // استخدم الاسم الفعلي
        message: messageText,
        userAvatar: null,
      );
      debugPrint('تم إرسال الرسالة بنجاح: ${sentMessage.id}');
    } catch (e) {
      debugPrint('خطأ في إرسال الرسالة: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل في إرسال الرسالة: $e')));
    }
  }

  Future<void> _addReaction(String messageId, String emoji) async {
    try {
      await _communityService.addReaction(messageId, 'test_user_123', emoji);
    } catch (e) {
      debugPrint('خطأ في إضافة التفاعل: $e');
    }
  }

  Future<void> _editMessage(String messageId) async {
    final newMessage = await _showEditDialog();
    if (newMessage != null) {
      try {
        await _communityService.editMessage(messageId, newMessage);
      } catch (e) {
        debugPrint('خطأ في تعديل الرسالة: $e');
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _communityService.deleteMessage(messageId);
    } catch (e) {
      debugPrint('خطأ في حذف الرسالة: $e');
    }
  }

  Future<String?> _showEditDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الرسالة'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'أدخل النص الجديد'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.thumb_up),
              title: const Text('إضافة تفاعل 👍'),
              onTap: () {
                Navigator.pop(context);
                _addReaction(message.id, '👍');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('إضافة تفاعل ❤️'),
              onTap: () {
                Navigator.pop(context);
                _addReaction(message.id, '❤️');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sentiment_very_satisfied),
              title: const Text('إضافة تفاعل 😂'),
              onTap: () {
                Navigator.pop(context);
                _addReaction(message.id, '😂');
              },
            ),
            if (message.userId == 'test_user_123') ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('تعديل الرسالة'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'حذف الرسالة',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message.id);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار الشات المجتمعي'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_onlineUsersCount متصل',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'اسم المستخدم: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'أدخل اسمك',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    onChanged: (val) {
                      setState(() {
                        currentUserName = val.trim().isEmpty
                            ? 'بدون اسم'
                            : val.trim();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // منطقة الرسائل
          Expanded(
            child: _isInitialized
                ? ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageCard(message);
                    },
                  )
                : const Center(child: CircularProgressIndicator()),
          ),

          // منطقة إرسال الرسالة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالتك هنا...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
                      iconSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(ChatMessage message) {
    final isCurrentUser = message.userId == 'test_user_123';
    final Color userColor = isCurrentUser
        ? Theme.of(context).primaryColor
        : Colors.blue.shade700;
    final Color bubbleColor = isCurrentUser
        ? Theme.of(context).primaryColor.withOpacity(0.90)
        : Colors.white;
    final Color textColor = isCurrentUser ? Colors.white : Colors.black87;
    final Color nameColor = isCurrentUser ? Colors.white : userColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 22,
              backgroundColor: userColor.withOpacity(0.15),
              backgroundImage: message.userAvatar != null
                  ? NetworkImage(message.userAvatar!)
                  : null,
              child: message.userAvatar == null
                  ? Text(
                      message.userName.isNotEmpty
                          ? message.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: userColor,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // اسم المستخدم دائماً فوق الفقاعة
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 4.0,
                    right: 2,
                    left: 2,
                  ),
                  child: Text(
                    message.userName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: nameColor,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Material(
                  color: bubbleColor,
                  elevation: 2,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: isCurrentUser
                        ? const Radius.circular(18)
                        : const Radius.circular(4),
                    bottomRight: isCurrentUser
                        ? const Radius.circular(4)
                        : const Radius.circular(18),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isCurrentUser
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isCurrentUser
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    onLongPress: () => _showMessageOptions(context, message),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: isCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.message,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 17,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(message.timestamp),
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                              if (message.editedAt != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(معدلة)',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (message.reactions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: message.reactions.entries.map((entry) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrentUser
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${entry.key} ${entry.value.length}',
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 22,
              backgroundColor: userColor.withOpacity(0.15),
              backgroundImage: message.userAvatar != null
                  ? NetworkImage(message.userAvatar!)
                  : null,
              child: message.userAvatar == null
                  ? Text(
                      message.userName.isNotEmpty
                          ? message.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: userColor,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _communityService.dispose();
    super.dispose();
  }
}
