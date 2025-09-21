import 'package:flutter/material.dart';
import 'dart:async';
import '../models/ml_models.dart';
import '../theme/liquid_glass_theme.dart';
import '../widgets/liquid_glass_widgets.dart';

class SmartInsightsWidget extends StatefulWidget {
  const SmartInsightsWidget({super.key});
  
  @override
  State<SmartInsightsWidget> createState() => _SmartInsightsWidgetState();
}

class _SmartInsightsWidgetState extends State<SmartInsightsWidget>
    with TickerProviderStateMixin {
  // MLService instance for future use
  // late MLService _mlService;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Subscriptions
  StreamSubscription<DrivingAnalysis>? _analysisSubscription;
  StreamSubscription<List<SmartRecommendation>>? _recommendationsSubscription;
  StreamSubscription<RiskAssessment>? _riskSubscription;
  
  // State
  DrivingAnalysis? _currentAnalysis;
  List<SmartRecommendation> _recommendations = [];
  RiskAssessment? _riskAssessment;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    
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
    
    _initializeML();
  }
  
  Future<void> _initializeML() async {
    // Initialize with mock data
    _setupSubscriptions();
    
    setState(() {
      _isInitialized = true;
    });
    
    _fadeController.forward();
    _slideController.forward();
  }
  
  void _setupSubscriptions() {
    // Mock data for demonstration
    _currentAnalysis = DrivingAnalysis(
      safetyScore: 85.0,
      fuelEfficiency: 12.5,
      averageSpeed: 65.0,
      totalDistance: 125.3,
      timestamp: DateTime.now(),
    );
    
    _recommendations = [
      SmartRecommendation(
        id: '1',
        type: RecommendationType.safety,
        priority: RecommendationPriority.high,
        title: 'تحسين السلامة',
        description: 'قلل من السرعة في المناطق المزدحمة',
        actionText: 'تطبيق',
        confidence: 0.85,
      ),
    ];
    
    _riskAssessment = RiskAssessment(
      overallRisk: RiskLevel.medium,
      factors: [],
      timestamp: DateTime.now(),
    );
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _analysisSubscription?.cancel();
    _recommendationsSubscription?.cancel();
    _riskSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildInsightsContent(),
          ),
        );
      },
    );
  }
  
  Widget _buildInsightsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildPerformanceOverview(),
          const SizedBox(height: 20),
          _buildRiskAssessment(),
          const SizedBox(height: 20),
          _buildSmartRecommendations(),
          const SizedBox(height: 20),
          _buildDrivingPatterns(),
          const SizedBox(height: 20),
          _buildPredictiveInsights(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  LiquidGlassTheme.primaryColor,
                  LiquidGlassTheme.primaryColor.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرؤى الذكية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'تحليل ذكي لأنماط القيادة والتوصيات المخصصة',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildRefreshButton(),
        ],
      ),
    );
  }
  
  Widget _buildRefreshButton() {
    return GestureDetector(
      onTap: () {}, // Method not available
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: const Icon(
          Icons.refresh,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
  
  Widget _buildPerformanceOverview() {
    if (_currentAnalysis == null) {
      return _buildLoadingCard('تحليل الأداء');
    }
    
    final analysis = _currentAnalysis!;
    
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نظرة عامة على الأداء',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'نقاط الأمان',
                  '${analysis.safetyScore.toInt()}/100',
                  Icons.security,
                  _getScoreColor(analysis.safetyScore),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'كفاءة الوقود',
                  '${analysis.fuelEfficiency.toStringAsFixed(1)} كم/ل',
                  Icons.local_gas_station,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'السرعة المتوسطة',
                  '${analysis.averageSpeed.toInt()} كم/س',
                  Icons.speed,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'المسافة الكلية',
                  '${analysis.totalDistance.toStringAsFixed(1)} كم',
                  Icons.straighten,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRiskAssessment() {
    if (_riskAssessment == null) {
      return _buildLoadingCard('تقييم المخاطر');
    }
    
    final risk = _riskAssessment!;
    
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'تقييم المخاطر',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildRiskBadge(risk.overallRisk),
            ],
          ),
          const SizedBox(height: 16),
          _buildRiskIndicator(risk.overallRisk),
          const SizedBox(height: 16),
          const Text(
            'عوامل المخاطر قيد التحليل...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRiskBadge(RiskLevel level) {
    Color color;
    String text;
    
    switch (level) {
      case RiskLevel.low:
        color = Colors.green;
        text = 'منخفض';
        break;
      case RiskLevel.medium:
        color = Colors.orange;
        text = 'متوسط';
        break;
      case RiskLevel.high:
        color = Colors.red;
        text = 'عالي';
        break;
      case RiskLevel.critical:
        color = Colors.red[900]!;
        text = 'حرج';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildRiskIndicator(RiskLevel level) {
    double progress;
    Color color;
    
    switch (level) {
      case RiskLevel.low:
        progress = 0.3;
        color = Colors.green;
        break;
      case RiskLevel.medium:
        progress = 0.6;
        color = Colors.orange;
        break;
      case RiskLevel.high:
        progress = 0.9;
        color = Colors.red;
        break;
      case RiskLevel.critical:
        progress = 1.0;
        color = Colors.red;
        break;
    }
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'مستوى المخاطر الإجمالي',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
  
  Widget _buildRiskFactor(Map<String, dynamic> factor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getRiskFactorIcon(factor['type'] ?? 'default'),
            color: _getRiskFactorColor(factor['severity'] ?? 0.5),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              factor['description'] ?? 'عامل خطر',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getRiskFactorColor(factor['severity'] ?? 0.5),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSmartRecommendations() {
    if (_recommendations.isEmpty) {
      return _buildLoadingCard('التوصيات الذكية');
    }
    
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التوصيات الذكية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._recommendations.take(3).map((recommendation) => 
            _buildRecommendationCard(recommendation)
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationCard(SmartRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getRecommendationColor(recommendation.priority).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRecommendationColor(recommendation.priority).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getRecommendationIcon(recommendation.type),
            color: _getRecommendationColor(recommendation.priority),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRecommendationColor(recommendation.priority).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getPriorityText(recommendation.priority),
              style: TextStyle(
                color: _getRecommendationColor(recommendation.priority),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrivingPatterns() {
    if (_currentAnalysis == null) {
      return _buildLoadingCard('أنماط القيادة');
    }
    
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أنماط القيادة المكتشفة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPatternChart(),
        ],
      ),
    );
  }
  
  Widget _buildPatternChart() {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          Expanded(
            child: _buildPatternBar('القيادة الآمنة', 0.8, Colors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPatternBar('القيادة السريعة', 0.3, Colors.orange),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPatternBar('القيادة الاقتصادية', 0.6, Colors.blue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPatternBar('القيادة الليلية', 0.4, Colors.purple),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPatternBar(String label, double value, Color color) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          '${(value * 100).toInt()}%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPredictiveInsights() {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التوقعات الذكية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPredictionCard(
            'توقع استهلاك الوقود',
            '15.2 لتر',
            'للرحلة القادمة',
            Icons.local_gas_station,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildPredictionCard(
            'أفضل وقت للمغادرة',
            '8:30 صباحاً',
            'لتجنب الازدحام',
            Icons.schedule,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildPredictionCard(
            'احتمالية المطر',
            '25%',
            'خلال الساعتين القادمتين',
            Icons.cloud,
            Colors.orange,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPredictionCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingCard(String title) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 8),
          const Text(
            'جاري التحليل...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper methods
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
  
  IconData _getRiskFactorIcon(String type) {
    switch (type) {
      case 'speed':
        return Icons.speed;
      case 'weather':
        return Icons.cloud;
      case 'traffic':
        return Icons.traffic;
      case 'time':
        return Icons.schedule;
      default:
        return Icons.warning;
    }
  }
  
  Color _getRiskFactorColor(double severity) {
    if (severity >= 0.7) return Colors.red;
    if (severity >= 0.4) return Colors.orange;
    return Colors.green;
  }
  
  IconData _getRecommendationIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.safety:
        return Icons.security;
      case RecommendationType.efficiency:
        return Icons.speed;
      case RecommendationType.comfort:
        return Icons.airline_seat_recline_normal;
      case RecommendationType.eco:
        return Icons.eco;
    }
  }
  
  Color _getRecommendationColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.high:
        return Colors.red;
      case RecommendationPriority.medium:
        return Colors.orange;
      case RecommendationPriority.low:
        return Colors.green;
      case RecommendationPriority.critical:
        return Colors.red[900]!;
    }
  }
  
  String _getPriorityText(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.high:
        return 'عالي';
      case RecommendationPriority.medium:
        return 'متوسط';
      case RecommendationPriority.low:
        return 'منخفض';
      case RecommendationPriority.critical:
        return 'حرج';
    }
  }
}