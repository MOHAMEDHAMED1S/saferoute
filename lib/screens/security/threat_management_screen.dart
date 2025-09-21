import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../models/security_model.dart';
import '../../services/security_service.dart';

class ThreatManagementScreen extends StatefulWidget {
  const ThreatManagementScreen({Key? key}) : super(key: key);

  @override
  State<ThreatManagementScreen> createState() => _ThreatManagementScreenState();
}

class _ThreatManagementScreenState extends State<ThreatManagementScreen>
    with TickerProviderStateMixin {
  final SecurityService _securityService = SecurityService();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<SecurityThreat> _allThreats = [];
  List<SecurityThreat> _filteredThreats = [];
  bool _isLoading = true;
  String _searchQuery = '';
  ThreatType? _selectedType;
  SecurityLevel? _selectedLevel;
  bool _showResolvedOnly = false;
  StreamSubscription? _threatsSubscription;

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
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeService() async {
    try {
      await _securityService.initialize();
      
      _threatsSubscription = _securityService.threatsStream.listen((threats) {
        setState(() {
          _allThreats = threats;
          _applyFilters();
        });
      });
      
      setState(() {
        _allThreats = _securityService.threats;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('خطأ في تحميل التهديدات');
    }
  }

  void _applyFilters() {
    _filteredThreats = _allThreats.where((threat) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!threat.title.toLowerCase().contains(query) &&
            !threat.description.toLowerCase().contains(query) &&
            !threat.source.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Type filter
      if (_selectedType != null && threat.type != _selectedType) {
        return false;
      }
      
      // Level filter
      if (_selectedLevel != null && threat.level != _selectedLevel) {
        return false;
      }
      
      // Resolved filter
      if (_showResolvedOnly && !threat.isResolved) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Sort by detection time (newest first)
    _filteredThreats.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
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
    _slideController.dispose();
    _threatsSubscription?.cancel();
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
      floatingActionButton: _isLoading ? null : _buildActionButton(),
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
            'جاري تحميل التهديدات...',
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
        _buildSearchAndFilters(),
        _buildStatsRow(),
        Expanded(
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildThreatsList(),
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
            Icons.bug_report,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'إدارة التهديدات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(
              Icons.filter_list,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'البحث في التهديدات...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  label: _selectedType?.displayName ?? 'جميع الأنواع',
                  isSelected: _selectedType != null,
                  onTap: _showTypeFilterDialog,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  label: _selectedLevel?.displayName ?? 'جميع المستويات',
                  isSelected: _selectedLevel != null,
                  onTap: _showLevelFilterDialog,
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: _showResolvedOnly ? 'المحلولة' : 'الكل',
                isSelected: _showResolvedOnly,
                onTap: () {
                  setState(() {
                    _showResolvedOnly = !_showResolvedOnly;
                    _applyFilters();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalThreats = _allThreats.length;
    final activeThreats = _allThreats.where((t) => !t.isResolved).length;
    final resolvedThreats = _allThreats.where((t) => t.isResolved).length;
    final highRiskThreats = _allThreats.where((t) => 
        t.level == SecurityLevel.critical || t.level == SecurityLevel.high).length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'المجموع',
              value: totalThreats.toString(),
              color: Colors.blue,
              icon: Icons.list,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              title: 'نشطة',
              value: activeThreats.toString(),
              color: Colors.red,
              icon: Icons.warning,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              title: 'محلولة',
              value: resolvedThreats.toString(),
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              title: 'عالية الخطر',
              value: highRiskThreats.toString(),
              color: Colors.orange,
              icon: Icons.priority_high,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildThreatsList() {
    if (_filteredThreats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد تهديدات تطابق البحث',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredThreats.length,
      itemBuilder: (context, index) {
        final threat = _filteredThreats[index];
        return _buildThreatCard(threat, index);
      },
    );
  }

  Widget _buildThreatCard(SecurityThreat threat, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: threat.level.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showThreatDetailsDialog(threat),
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
                        color: threat.level.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        threat.type.icon,
                        color: threat.level.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            threat.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            threat.type.displayName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: threat.level.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        threat.level.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  threat.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(threat.detectedAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (threat.isResolved)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'محلول',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _resolveThreatDialog(threat),
                            icon: const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 20,
                            ),
                            tooltip: 'حل التهديد',
                          ),
                          IconButton(
                            onPressed: () => _deleteThreatDialog(threat),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            tooltip: 'حذف التهديد',
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return FloatingActionButton(
      onPressed: _showAddThreatDialog,
      backgroundColor: Colors.blue,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية التهديدات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('إعادة تعيين الفلاتر'),
              leading: const Icon(Icons.refresh),
              onTap: () {
                setState(() {
                  _selectedType = null;
                  _selectedLevel = null;
                  _showResolvedOnly = false;
                  _searchQuery = '';
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
          ],
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

  void _showTypeFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية حسب النوع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('جميع الأنواع'),
              leading: Radio<ThreatType?>(
                value: null,
                groupValue: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ...ThreatType.values.map((type) => ListTile(
              title: Text(type.displayName),
              leading: Radio<ThreatType?>(
                value: type,
                groupValue: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showLevelFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية حسب المستوى'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('جميع المستويات'),
              leading: Radio<SecurityLevel?>(
                value: null,
                groupValue: _selectedLevel,
                onChanged: (value) {
                  setState(() {
                    _selectedLevel = value;
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ...SecurityLevel.values.map((level) => ListTile(
              title: Text(level.displayName),
              leading: Radio<SecurityLevel?>(
                value: level,
                groupValue: _selectedLevel,
                onChanged: (value) {
                  setState(() {
                    _selectedLevel = value;
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showThreatDetailsDialog(SecurityThreat threat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(threat.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('النوع', threat.type.displayName),
              _buildDetailRow('المستوى', threat.level.displayName),
              _buildDetailRow('المصدر', threat.source),
              _buildDetailRow('وقت الاكتشاف', _formatDateTime(threat.detectedAt)),
              if (threat.isResolved) ...[
                _buildDetailRow('وقت الحل', _formatDateTime(threat.resolvedAt!)),
                _buildDetailRow('طريقة الحل', threat.resolutionMethod ?? 'غير محدد'),
              ],
              const SizedBox(height: 8),
              const Text(
                'الوصف:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(threat.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          if (!threat.isResolved)
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
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
            Text('كيف تم حل التهديد "${threat.title}"؟'),
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
                HapticFeedback.lightImpact();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteThreatDialog(SecurityThreat threat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التهديد'),
        content: Text('هل أنت متأكد من حذف التهديد "${threat.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _securityService.deleteThreat(threat.id);
              Navigator.pop(context);
              _showSuccessSnackBar('تم حذف التهديد بنجاح');
              HapticFeedback.lightImpact();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showAddThreatDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final sourceController = TextEditingController();
    ThreatType selectedType = ThreatType.malware;
    SecurityLevel selectedLevel = SecurityLevel.medium;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة تهديد جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان التهديد',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'وصف التهديد',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sourceController,
                  decoration: const InputDecoration(
                    labelText: 'مصدر التهديد',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ThreatType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'نوع التهديد',
                    border: OutlineInputBorder(),
                  ),
                  items: ThreatType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SecurityLevel>(
                  value: selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'مستوى الخطر',
                    border: OutlineInputBorder(),
                  ),
                  items: SecurityLevel.values.map((level) => DropdownMenuItem(
                    value: level,
                    child: Text(level.displayName),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedLevel = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    sourceController.text.isNotEmpty) {
                  final threat = SecurityThreat(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: selectedType,
                    level: selectedLevel,
                    title: titleController.text,
                    description: descriptionController.text,
                    source: sourceController.text,
                    detectedAt: DateTime.now(),
                  );
                  
                  await _securityService.addThreat(threat);
                  Navigator.pop(context);
                  _showSuccessSnackBar('تم إضافة التهديد بنجاح');
                  HapticFeedback.lightImpact();
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
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
}