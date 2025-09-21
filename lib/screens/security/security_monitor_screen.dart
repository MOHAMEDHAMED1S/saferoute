import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../models/security_model.dart';
import '../../services/security_service.dart';

class SecurityMonitorScreen extends StatefulWidget {
  const SecurityMonitorScreen({Key? key}) : super(key: key);

  @override
  State<SecurityMonitorScreen> createState() => _SecurityMonitorScreenState();
}

class _SecurityMonitorScreenState extends State<SecurityMonitorScreen>
    with TickerProviderStateMixin {
  final SecurityService _securityService = SecurityService();
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  ProtectionState _protectionState = ProtectionState(lastScan: DateTime.now());
  List<SecurityThreat> _threats = [];
  List<SecurityEvent> _events = [];
  bool _isLoading = true;
  bool _isScanning = false;
  double _scanProgress = 0.0;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _threatsSubscription;
  StreamSubscription? _eventsSubscription;
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeService();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeService() async {
    try {
      await _securityService.initialize();
      
      _stateSubscription = _securityService.securityStateStream.listen((state) {
        setState(() {
          _protectionState = state;
        });
      });
      
      _threatsSubscription = _securityService.threatsStream.listen((threats) {
        setState(() {
          _threats = threats;
        });
      });
      
      _eventsSubscription = _securityService.eventsStream.listen((events) {
        setState(() {
          _events = events;
        });
      });
      
      _scanSubscription = _securityService.scanProgressStream.listen((progress) {
        setState(() {
          _scanProgress = progress;
          _isScanning = progress < 1.0;
        });
      });
      
      setState(() {
        _protectionState = _securityService.currentState;
        _threats = _securityService.threats;
        _events = _securityService.events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('خطأ في تهيئة نظام الأمان');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _stateSubscription?.cancel();
    _threatsSubscription?.cancel();
    _eventsSubscription?.cancel();
    _scanSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF3949AB),
              Color(0xFF5C6BC0),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _isLoading ? _buildLoadingView() : _buildMainView(),
          ),
        ),
      ),
      floatingActionButton: _isLoading ? null : _buildScanButton(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'جاري تهيئة نظام المراقبة...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSecurityStatusCard(),
              const SizedBox(height: 16),
              _buildQuickStatsRow(),
              const SizedBox(height: 16),
              _buildActiveThreatsSection(),
              const SizedBox(height: 16),
              _buildRecentEventsSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.security,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'مراقب الأمان',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/threat-management'),
            icon: const Icon(
              Icons.bug_report,
              color: Colors.white,
            ),
            tooltip: 'إدارة التهديدات',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/security-settings'),
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            tooltip: 'إعدادات الأمان',
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _protectionState.status.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _protectionState.status.color.withAlpha(76),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _protectionState.status.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'مستوى الأمان: ${_protectionState.currentLevel.displayName}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(204),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSecurityScoreIndicator(),
          const SizedBox(height: 16),
          Text(
            'آخر فحص: ${_formatDateTime(_protectionState.lastScan)}',
            style: TextStyle(
              color: Colors.white.withAlpha(178),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityScoreIndicator() {
    final score = _protectionState.securityScore;
    final color = _getScoreColor(score);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'نقاط الأمان',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${score.toInt()}/100',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: Colors.white.withAlpha(51),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildQuickStatsRow() {
    final activeThreats = _threats.where((t) => !t.isResolved).length;
    final recentEvents = _events.where((e) => 
        DateTime.now().difference(e.timestamp).inHours < 24).length;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'التهديدات النشطة',
            value: activeThreats.toString(),
            icon: Icons.warning,
            color: activeThreats > 0 ? Colors.red : Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'الأحداث اليوم',
            value: recentEvents.toString(),
            icon: Icons.event,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'حالة النظام',
            value: _protectionState.status == ProtectionStatus.active ? 'آمن' : 'تحذير',
            icon: Icons.shield,
            color: _protectionState.status.color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withAlpha(51),
          width: 1,
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
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withAlpha(204),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveThreatsSection() {
    final activeThreats = _threats.where((t) => !t.isResolved).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'التهديدات النشطة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (activeThreats.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activeThreats.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeThreats.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withAlpha(76),
                width: 1,
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  'لا توجد تهديدات نشطة',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'نظامك آمن حالياً',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ...activeThreats.take(3).map((threat) => _buildThreatCard(threat)),
        if (activeThreats.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () => _showAllThreatsDialog(),
              child: Text(
                'عرض جميع التهديدات (${activeThreats.length})',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThreatCard(SecurityThreat threat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: threat.level.color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: threat.level.color.withAlpha(76),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            threat.type.icon,
            color: threat.level.color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  threat.title,
                  style: TextStyle(
                    color: threat.level.color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  threat.description,
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDateTime(threat.detectedAt),
                  style: TextStyle(
                    color: Colors.white.withAlpha(153),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showThreatDetailsDialog(threat),
            icon: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEventsSection() {
    final recentEvents = _events.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.history,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'الأحداث الأخيرة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentEvents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withAlpha(51),
                width: 1,
              ),
            ),
            child: Text(
              'لا توجد أحداث حديثة',
              style: TextStyle(
                color: Colors.white.withAlpha(178),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...recentEvents.map((event) => _buildEventCard(event)),
      ],
    );
  }

  Widget _buildEventCard(SecurityEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withAlpha(25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: event.riskLevel.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  event.description,
                  style: TextStyle(
                    color: Colors.white.withAlpha(178),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(event.timestamp),
            style: TextStyle(
              color: Colors.white.withAlpha(127),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return FloatingActionButton.extended(
      onPressed: _isScanning ? null : _performSecurityScan,
      backgroundColor: _isScanning ? Colors.grey : Colors.blue,
      icon: _isScanning
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: _scanProgress,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.security),
      label: Text(
        _isScanning ? 'جاري الفحص...' : 'فحص أمني',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Future<void> _performSecurityScan() async {
    try {
      HapticFeedback.lightImpact();
      await _securityService.performFullSecurityScan();
      _showSuccessSnackBar('تم إكمال الفحص الأمني بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في إجراء الفحص الأمني');
    }
  }

  void _showThreatDetailsDialog(SecurityThreat threat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(threat.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('النوع: ${threat.type.displayName}'),
            Text('المستوى: ${threat.level.displayName}'),
            Text('المصدر: ${threat.source}'),
            Text('وقت الاكتشاف: ${_formatDateTime(threat.detectedAt)}'),
            const SizedBox(height: 8),
            Text('الوصف:'),
            Text(threat.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resolveThreatDialog(threat);
            },
            child: const Text('حل التهديد'),
          ),
        ],
      ),
    );
  }

  void _resolveThreatDialog(SecurityThreat threat) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حل التهديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('كيف تم حل هذا التهديد؟'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'اكتب وصف الحل...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _securityService.resolveThreat(threat.id, controller.text);
                Navigator.pop(context);
                _showSuccessSnackBar('تم حل التهديد بنجاح');
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showAllThreatsDialog() {
    final activeThreats = _threats.where((t) => !t.isResolved).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('جميع التهديدات النشطة'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: activeThreats.length,
            itemBuilder: (context, index) {
              final threat = activeThreats[index];
              return ListTile(
                leading: Icon(
                  threat.type.icon,
                  color: threat.level.color,
                ),
                title: Text(threat.title),
                subtitle: Text(threat.description),
                trailing: Text(threat.level.displayName),
                onTap: () {
                  Navigator.pop(context);
                  _showThreatDetailsDialog(threat);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (_protectionState.status) {
      case ProtectionStatus.active:
        return Icons.shield;
      case ProtectionStatus.inactive:
        return Icons.shield_outlined;
      case ProtectionStatus.warning:
        return Icons.warning;
      case ProtectionStatus.error:
        return Icons.error;
      case ProtectionStatus.updating:
        return Icons.refresh;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}