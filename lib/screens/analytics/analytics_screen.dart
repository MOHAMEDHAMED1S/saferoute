import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../services/ml_service.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';
import '../../widgets/adaptive_interface_widget.dart';
import '../../widgets/smart_insights_widget.dart';
import '../../widgets/performance_monitor_widget.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late MLService _mlService;
  late TabController _tabController;
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;
  
  // Data streams
  StreamSubscription<DrivingPattern>? _patternSubscription;
  StreamSubscription<List<SmartRecommendation>>? _recommendationsSubscription;
  StreamSubscription<RiskAssessment>? _riskSubscription;
  StreamSubscription<PerformanceMetrics>? _performanceSubscription;
  
  // Current data
  DrivingPattern? _currentPattern;
  List<SmartRecommendation> _recommendations = [];
  RiskAssessment? _riskAssessment;
  PerformanceMetrics? _performance;
  
  // UI state
  bool _isLoading = true;
  String _selectedTimeRange = '7d';
  int _selectedTabIndex = 0;
  
  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 6, vsync: this);
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _initializeMLService();
  }
  
  Future<void> _initializeMLService() async {
    _mlService = MLService();
    await _mlService.initialize();
    
    _setupSubscriptions();
    _loadInitialData();
    
    setState(() {
      _isLoading = false;
    });
    
    _chartAnimationController.forward();
  }
  
  void _setupSubscriptions() {
    _patternSubscription = _mlService.drivingPatternStream.listen((pattern) {
      if (mounted) {
        setState(() {
          _currentPattern = pattern;
        });
      }
    });
    
    _recommendationsSubscription = _mlService.recommendationsStream.listen((recommendations) {
      if (mounted) {
        setState(() {
          _recommendations = recommendations;
        });
      }
    });
    
    _riskSubscription = _mlService.riskAssessmentStream.listen((risk) {
      if (mounted) {
        setState(() {
          _riskAssessment = risk;
        });
      }
    });
    
    _performanceSubscription = _mlService.performanceStream.listen((performance) {
      if (mounted) {
        setState(() {
          _performance = performance;
        });
      }
    });
  }
  
  void _loadInitialData() {
    setState(() {
      _currentPattern = _mlService.currentPattern;
      _recommendations = _mlService.currentRecommendations;
      _riskAssessment = _mlService.currentRiskAssessment;
      _performance = _mlService.currentPerformance;
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _chartAnimationController.dispose();
    _patternSubscription?.cancel();
    _recommendationsSubscription?.cancel();
    _riskSubscription?.cancel();
    _performanceSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AdaptiveInterfaceWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: _isLoading ? _buildLoadingView() : _buildMainContent(),
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'التحليلات والإحصائيات',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        _buildTimeRangeSelector(),
        const SizedBox(width: 16),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: LiquidGlassTheme.primaryColor,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(text: 'الرؤى الذكية'),
          Tab(text: 'مراقب الأداء'),
          Tab(text: 'الأداء'),
          Tab(text: 'المخاطر'),
          Tab(text: 'التوصيات'),
          Tab(text: 'الأنماط'),
        ],
      ),
    );
  }
  
  Widget _buildTimeRangeSelector() {
    return LiquidGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: DropdownButton<String>(
        value: _selectedTimeRange,
        dropdownColor: LiquidGlassTheme.surfaceColor,
        underline: const SizedBox.shrink(),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: const [
          DropdownMenuItem(value: '1d', child: Text('يوم واحد')),
          DropdownMenuItem(value: '7d', child: Text('أسبوع')),
          DropdownMenuItem(value: '30d', child: Text('شهر')),
          DropdownMenuItem(value: '90d', child: Text('3 أشهر')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedTimeRange = value;
            });
          }
        },
      ),
    );
  }
  
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'جاري تحليل البيانات...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        const SmartInsightsWidget(),
        const PerformanceMonitorWidget(
          isExpanded: true,
          showDetailedView: true,
        ),
        _buildPerformanceTab(),
        _buildRiskTab(),
        _buildRecommendationsTab(),
        _buildPatternsTab(),
      ],
    );
  }
  
  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPerformanceOverview(),
          const SizedBox(height: 20),
          _buildPerformanceCharts(),
          const SizedBox(height: 20),
          _buildPerformanceTrends(),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceOverview() {
    if (_performance == null) return const SizedBox.shrink();
    
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نظرة عامة على الأداء',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'النقاط الإجمالية',
                  _performance!.overallScore,
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPerformanceCard(
                  'السلامة',
                  _performance!.safetyScore,
                  Icons.security,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'الكفاءة',
                  _performance!.efficiencyScore,
                  Icons.speed,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPerformanceCard(
                  'البيئة',
                  _performance!.ecoScore,
                  Icons.eco,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildImprovementIndicator(),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceCard(String title, double score, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(51), color.withAlpha(25)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${score.toInt()}',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImprovementIndicator() {
    if (_performance == null) return const SizedBox.shrink();
    
    final improvement = _performance!.improvement;
    final isImproving = improvement > 0;
    final color = isImproving ? Colors.green : improvement < 0 ? Colors.red : Colors.grey;
    final icon = isImproving ? Icons.trending_up : improvement < 0 ? Icons.trending_down : Icons.trending_flat;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            isImproving ? 'تحسن بنسبة ${improvement.abs().toStringAsFixed(1)}%' :
            improvement < 0 ? 'انخفاض بنسبة ${improvement.abs().toStringAsFixed(1)}%' :
            'أداء مستقر',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceCharts() {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تطور الأداء',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white.withAlpha(25),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
                            if (value.toInt() < days.length) {
                              return Text(
                                days[value.toInt()],
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _generatePerformanceSpots(),
                        isCurved: true,
                        color: LiquidGlassTheme.primaryColor,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: LiquidGlassTheme.primaryColor,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: LiquidGlassTheme.primaryColor.withAlpha(51),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: 100,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  List<FlSpot> _generatePerformanceSpots() {
    // Generate sample performance data
    return List.generate(7, (index) {
      final baseScore = 75.0;
      final variation = math.sin(index * 0.5) * 15;
      return FlSpot(index.toDouble(), baseScore + variation);
    });
  }
  
  Widget _buildPerformanceTrends() {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اتجاهات الأداء',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendItem('السرعة المتوسطة', '75 كم/س', Icons.speed, Colors.blue, '+5%'),
          _buildTrendItem('نقاط السلامة', '85/100', Icons.security, Colors.green, '+12%'),
          _buildTrendItem('استهلاك الوقود', '7.2 ل/100كم', Icons.local_gas_station, Colors.orange, '-8%'),
          _buildTrendItem('وقت الرحلة', '25 دقيقة', Icons.access_time, Colors.purple, '-3%'),
        ],
      ),
    );
  }
  
  Widget _buildTrendItem(String title, String value, IconData icon, Color color, String change) {
    final isPositive = change.startsWith('+');
    final changeColor = isPositive ? Colors.green : Colors.red;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: changeColor.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              change,
              style: TextStyle(
                color: changeColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRiskTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRiskOverview(),
          const SizedBox(height: 20),
          _buildRiskFactors(),
          const SizedBox(height: 20),
          _buildRiskRecommendations(),
        ],
      ),
    );
  }
  
  Widget _buildRiskOverview() {
    if (_riskAssessment == null) return const SizedBox.shrink();
    
    final risk = _riskAssessment!;
    final riskColor = _getRiskColor(risk.riskLevel);
    final riskText = _getRiskText(risk.riskLevel);
    
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'تقييم المخاطر',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  riskColor.withAlpha(76),
                  riskColor.withAlpha(25),
                ],
              ),
              border: Border.all(color: riskColor, width: 3),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(risk.overallRisk * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                  Text(
                    riskText,
                    style: TextStyle(
                      fontSize: 12,
                      color: riskColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'مستوى المخاطر: $riskText',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: riskColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRiskFactors() {
    if (_riskAssessment == null) return const SizedBox.shrink();
    
    final risk = _riskAssessment!;
    
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'عوامل المخاطر',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildRiskFactor('السرعة', risk.speedRisk, Icons.speed),
          _buildRiskFactor('السلوك', risk.behaviorRisk, Icons.psychology),
          _buildRiskFactor('الطقس', risk.weatherRisk, Icons.cloud),
          _buildRiskFactor('الوقت', risk.timeRisk, Icons.access_time),
          _buildRiskFactor('المسار', risk.routeRisk, Icons.route),
        ],
      ),
    );
  }
  
  Widget _buildRiskFactor(String title, double risk, IconData icon) {
    final riskLevel = risk * 100;
    final color = _getRiskColorByValue(risk);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: risk,
              backgroundColor: Colors.white.withAlpha(51),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${riskLevel.toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRiskRecommendations() {
    if (_riskAssessment == null || _riskAssessment!.recommendations.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'توصيات السلامة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ..._riskAssessment!.recommendations.map((recommendation) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_recommendations.isEmpty)
            _buildNoRecommendations()
          else
            ..._recommendations.map((recommendation) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildRecommendationCard(recommendation),
              );
            }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildNoRecommendations() {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(40),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'ممتاز!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'لا توجد توصيات في الوقت الحالي. استمر في القيادة الآمنة!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationCard(SmartRecommendation recommendation) {
    final priorityColor = _getPriorityColor(recommendation.priority);
    final typeIcon = _getTypeIcon(recommendation.type);
    
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: priorityColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  typeIcon,
                  color: priorityColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPriorityText(recommendation.priority),
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: recommendation.confidence,
                  backgroundColor: Colors.white.withAlpha(51),
                  valueColor: AlwaysStoppedAnimation<Color>(priorityColor),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ثقة ${(recommendation.confidence * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                // Handle recommendation action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: priorityColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(recommendation.actionText),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPatternsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDrivingStyleCard(),
          const SizedBox(height: 20),
          _buildPatternsAnalysis(),
          const SizedBox(height: 20),
          _buildImprovementAreas(),
        ],
      ),
    );
  }
  
  Widget _buildDrivingStyleCard() {
    if (_currentPattern == null) return const SizedBox.shrink();
    
    final style = _currentPattern!.drivingStyle;
    final styleColor = _getStyleColor(style);
    final styleText = _getStyleText(style);
    final styleIcon = _getStyleIcon(style);
    
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'نمط القيادة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  styleColor.withAlpha(76),
                  styleColor.withAlpha(25),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: styleColor.withAlpha(127)),
            ),
            child: Column(
              children: [
                Icon(
                  styleIcon,
                  color: styleColor,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  styleText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: styleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStyleDescription(style),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPatternsAnalysis() {
    if (_currentPattern == null) return const SizedBox.shrink();
    
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تحليل الأنماط',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildPatternSection('أنماط الوقت', _currentPattern!.timePatterns),
          const SizedBox(height: 16),
          _buildPatternSection('أنماط الطقس', _currentPattern!.weatherPatterns),
          const SizedBox(height: 16),
          _buildPatternSection('أنماط المسارات', _currentPattern!.routePatterns),
        ],
      ),
    );
  }
  
  Widget _buildPatternSection(String title, Map<String, double> patterns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ...patterns.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getPatternDisplayName(entry.key),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: LinearProgressIndicator(
                    value: entry.value,
                    backgroundColor: Colors.white.withAlpha(51),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      LiquidGlassTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(entry.value * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildImprovementAreas() {
    if (_currentPattern == null) return const SizedBox.shrink();
    
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نقاط القوة ومجالات التحسين',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_currentPattern!.strengths.isNotEmpty) ...[
            const Text(
              'نقاط القوة:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            ..._currentPattern!.strengths.map((strength) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strength,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
          if (_currentPattern!.improvementAreas.isNotEmpty) ...[
            const Text(
              'مجالات التحسين:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            ..._currentPattern!.improvementAreas.map((area) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      area,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
  
  // Helper methods for colors and text
  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
      case RiskLevel.critical:
        return Colors.red[900]!;
    }
  }
  
  String _getRiskText(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'منخفض';
      case RiskLevel.medium:
        return 'متوسط';
      case RiskLevel.high:
        return 'عالي';
      case RiskLevel.critical:
        return 'حرج';
    }
  }
  
  Color _getRiskColorByValue(double risk) {
    if (risk >= 0.8) return Colors.red;
    if (risk >= 0.5) return Colors.orange;
    return Colors.green;
  }
  
  Color _getPriorityColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.low:
        return Colors.blue;
      case RecommendationPriority.medium:
        return Colors.orange;
      case RecommendationPriority.high:
        return Colors.red;
      case RecommendationPriority.critical:
        return Colors.red[900]!;
    }
  }
  
  String _getPriorityText(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.low:
        return 'منخفض';
      case RecommendationPriority.medium:
        return 'متوسط';
      case RecommendationPriority.high:
        return 'عالي';
      case RecommendationPriority.critical:
        return 'حرج';
    }
  }
  
  IconData _getTypeIcon(RecommendationType type) {
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
  
  Color _getStyleColor(DrivingStyle style) {
    switch (style) {
      case DrivingStyle.conservative:
        return Colors.green;
      case DrivingStyle.balanced:
        return Colors.blue;
      case DrivingStyle.aggressive:
        return Colors.red;
    }
  }
  
  String _getStyleText(DrivingStyle style) {
    switch (style) {
      case DrivingStyle.conservative:
        return 'محافظ';
      case DrivingStyle.balanced:
        return 'متوازن';
      case DrivingStyle.aggressive:
        return 'عدواني';
    }
  }
  
  IconData _getStyleIcon(DrivingStyle style) {
    switch (style) {
      case DrivingStyle.conservative:
        return Icons.security;
      case DrivingStyle.balanced:
        return Icons.balance;
      case DrivingStyle.aggressive:
        return Icons.flash_on;
    }
  }
  
  String _getStyleDescription(DrivingStyle style) {
    switch (style) {
      case DrivingStyle.conservative:
        return 'تقود بحذر وتركز على السلامة';
      case DrivingStyle.balanced:
        return 'توازن جيد بين السلامة والكفاءة';
      case DrivingStyle.aggressive:
        return 'قيادة سريعة تحتاج إلى مزيد من الحذر';
    }
  }
  
  String _getPatternDisplayName(String key) {
    final displayNames = {
      'morning': 'الصباح',
      'afternoon': 'بعد الظهر',
      'evening': 'المساء',
      'night': 'الليل',
      'clear': 'صافي',
      'rain': 'مطر',
      'fog': 'ضباب',
      'snow': 'ثلج',
      'highway': 'طريق سريع',
      'city': 'مدينة',
      'rural': 'ريفي',
    };
    return displayNames[key] ?? key;
  }
}