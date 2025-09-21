import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/ai_assistant_service.dart';
import '../models/ai_assistant_model.dart';
import '../theme/liquid_glass_theme.dart';
import '../widgets/liquid_glass_widgets.dart';

class AIChatWidget extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  
  const AIChatWidget({
    super.key,
    this.isExpanded = false,
    this.onToggleExpand,
  });
  
  @override
  State<AIChatWidget> createState() => _AIChatWidgetState();
}

class _AIChatWidgetState extends State<AIChatWidget>
    with TickerProviderStateMixin {
  late AIAssistantService _aiService;
  late AnimationController _expandController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _expandAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFocusNode = FocusNode();
  
  // Subscriptions
  StreamSubscription<ConversationMessage>? _messageSubscription;
  StreamSubscription<bool>? _listeningSubscription;
  
  // State
  List<ConversationMessage> _messages = [];
  bool _isListening = false;
  bool _isTyping = false;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));
    
    _initializeAI();
    
    if (widget.isExpanded) {
      _expandController.forward();
    }
  }
  
  Future<void> _initializeAI() async {
    _aiService = AIAssistantService.instance;
    
    if (!_aiService.isInitialized) {
      await _aiService.initialize();
    }
    
    _setupSubscriptions();
    
    setState(() {
      _isInitialized = true;
      _messages = _aiService.currentContext.messages;
    });
    
    _scrollToBottom();
  }
  
  void _setupSubscriptions() {
    _messageSubscription = _aiService.messageStream.listen((message) {
      if (mounted) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
        
        if (message.sender == MessageSender.assistant) {
          _startTypingAnimation();
        }
      }
    });
    
    _listeningSubscription = _aiService.listeningStream.listen((isListening) {
      if (mounted) {
        setState(() {
          _isListening = isListening;
        });
        
        if (isListening) {
          _pulseController.repeat(reverse: true);
          _waveController.repeat();
        } else {
          _pulseController.stop();
          _waveController.stop();
        }
      }
    });
  }
  
  void _startTypingAnimation() {
    setState(() {
      _isTyping = true;
    });
    
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    });
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  @override
  void didUpdateWidget(AIChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _expandController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _textFocusNode.dispose();
    _messageSubscription?.cancel();
    _listeningSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Container(
          height: widget.isExpanded ? 400 : 60,
          child: widget.isExpanded ? _buildExpandedChat() : _buildCollapsedChat(),
        );
      },
    );
  }
  
  Widget _buildCollapsedChat() {
    return GestureDetector(
      onTap: widget.onToggleExpand,
      child: LiquidGlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildAvatarWithAnimation(),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'اضغط للتحدث مع سلامة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _buildVoiceButton(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExpandedChat() {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildChatHeader(),
          const SizedBox(height: 12),
          Expanded(
            child: _buildMessagesList(),
          ),
          const SizedBox(height: 12),
          _buildInputArea(),
        ],
      ),
    );
  }
  
  Widget _buildChatHeader() {
    return Row(
      children: [
        _buildAvatarWithAnimation(),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سلامة - المساعد الذكي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'متصل ومستعد للمساعدة',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: widget.onToggleExpand,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAvatarWithAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse animation when listening
        if (_isListening)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LiquidGlassTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
              );
            },
          ),
        // Wave animation when listening
        if (_isListening)
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(60, 60),
                painter: WaveAnimationPainter(
                  animation: _waveAnimation.value,
                  color: LiquidGlassTheme.primaryColor,
                ),
              );
            },
          ),
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                LiquidGlassTheme.primaryColor,
                LiquidGlassTheme.primaryColor.withValues(alpha: 0.7),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.assistant,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMessagesList() {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }
  
  Widget _buildMessageBubble(ConversationMessage message) {
    final isUser = message.sender == MessageSender.user;
    final isSystem = message.sender == MessageSender.system;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildMessageAvatar(message.sender),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? LiquidGlassTheme.primaryColor
                    : isSystem
                        ? Colors.orange.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUser
                      ? LiquidGlassTheme.primaryColor.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (message.actions != null && message.actions!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildMessageActions(message.actions!),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildMessageAvatar(message.sender),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMessageAvatar(MessageSender sender) {
    IconData icon;
    Color color;
    
    switch (sender) {
      case MessageSender.user:
        icon = Icons.person;
        color = Colors.blue;
        break;
      case MessageSender.assistant:
        icon = Icons.assistant;
        color = LiquidGlassTheme.primaryColor;
        break;
      case MessageSender.system:
        icon = Icons.info;
        color = Colors.orange;
        break;
    }
    
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Icon(
        icon,
        size: 12,
        color: color,
      ),
    );
  }
  
  Widget _buildMessageActions(List<MessageAction> actions) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: actions.map((action) {
        return GestureDetector(
          onTap: () => _handleActionTap(action),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Text(
              action.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _buildMessageAvatar(MessageSender.assistant),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final delay = index * 0.2;
        final animationValue = (_pulseController.value + delay) % 1.0;
        final opacity = (math.sin(animationValue * math.pi * 2) + 1) / 2;
        
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.3 + (opacity * 0.7)),
          ),
        );
      },
    );
  }
  
  Widget _buildInputArea() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: TextField(
              controller: _textController,
              focusNode: _textFocusNode,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'اكتب رسالتك هنا...',
                hintStyle: TextStyle(color: Colors.white60),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _sendTextMessage,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildSendButton(),
        const SizedBox(width: 8),
        _buildVoiceButton(),
      ],
    );
  }
  
  Widget _buildSendButton() {
    return GestureDetector(
      onTap: () => _sendTextMessage(_textController.text),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: LiquidGlassTheme.primaryColor,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: const Icon(
          Icons.send,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
  
  Widget _buildVoiceButton() {
    return GestureDetector(
      onTap: _toggleVoiceListening,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isListening
              ? Colors.red
              : LiquidGlassTheme.primaryColor.withValues(alpha: 0.8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
  
  // Event handlers
  void _sendTextMessage(String text) {
    if (text.trim().isEmpty) return;
    
    _aiService.sendTextMessage(text.trim());
    _textController.clear();
  }
  
  void _toggleVoiceListening() {
    if (_isListening) {
      _aiService.stopListening();
    } else {
      _aiService.startListening();
      // Simulate voice input after a delay
      Timer(const Duration(seconds: 3), () {
        _aiService.processVoiceInput('simulated_audio_data');
      });
    }
  }
  
  void _handleActionTap(MessageAction action) {
    switch (action.type) {
      case ActionType.navigate:
        // Handle navigation action
        break;
      case ActionType.call:
        // Handle call action
        break;
      case ActionType.message:
        // Handle message action
        break;
      case ActionType.settings:
        // Handle settings action
        break;
      case ActionType.emergency:
        // Handle emergency action
        break;
      case ActionType.reminder:
        // Handle reminder action
        break;
      case ActionType.route:
        // Handle route action
        break;
      case ActionType.weather:
        // Handle weather action
        break;
    }
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} د';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} س';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

class WaveAnimationPainter extends CustomPainter {
  final double animation;
  final Color color;
  
  WaveAnimationPainter({
    required this.animation,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * animation;
    
    if (radius > 0) {
      canvas.drawCircle(center, radius, paint);
    }
    
    // Draw multiple waves
    for (int i = 1; i <= 3; i++) {
      final waveRadius = radius + (i * 10);
      if (waveRadius <= size.width / 2) {
        paint.color = color.withValues(alpha: 0.3 / i);
        canvas.drawCircle(center, waveRadius, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(WaveAnimationPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}