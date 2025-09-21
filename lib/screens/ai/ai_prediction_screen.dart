import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ai_prediction_service.dart';
import '../../models/route_model.dart';
import '../../widgets/common/enhanced_ui_components.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/loading_utils.dart';
import '../../theme/enhanced_theme.dart';
import 'dart:async';

class AIPredictionScreen extends StatefulWidget {
  const AIPredictionScreen({Key? key}) : super(key: key);

  @override
  State<AIPredictionScreen> createState() => _AIPredictionScreenState();
}

class _AIPredictionScreenState extends State<AIPredictionScreen>
    with TickerProviderStateMixin {
  final AIPredictionService _aiService = AIPredictionService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  RiskPrediction? _currentPrediction;
  bool _isLoading = false;
  StreamSubscription? _predictionSubscription;
  String? _selectedRouteId;
  
  final List<RouteModel> _sampleRoutes = [
    RouteModel(
      id: 'route_1',
      name: 'الطريق الرئيسي',
      startPoint: 'الرياض',
      endPoint: 'جدة',
      distance: 950.0,
      estimatedTime: const Duration(hours: 9, minutes: 30),
      waypoints: [],
    ),
    RouteModel(
      id: 'route_2', 
      name: 'الطريق السريع',
      startPoint: 'الدمام',
      endPoint: 'الرياض',
      distance: 395.0,
      estimatedTime: const Duration(hours: 4, minutes: 15),
      waypoints: [],
    ),
    RouteModel(
      id: 'route_3',
      name: 'طريق المدينة',
      startPoint: 'مكة المكرمة',
      endPoint: 'المدينة المنورة',
      distance: 385.0,
      estimatedTime: const Duration(hours: 4, minutes: 0),
      waypoints: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAI();
    _setupPredictionListener();
  }

  void _initializeAnimations() {
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

  Future<void> _initializeAI() async {
    setState(() => _isLoading = true);
    
    try {
      await _aiService.initialize();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تهيئة نظام الذكاء الاصطناعي بنجاح'),
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

  void _setupPredictionListener() {
    _predictionSubscription = _aiService.predictionUpdates.listen(
      (update) {
        if (mounted && update.routeId == _selectedRouteId) {
          setState(() {
            _currentPrediction = update.prediction;
          });
          
          HapticFeedback.lightImpact();
        }
      },
    );
  }

  Future<void> _predictRoute(RouteModel route) async {
    setState(() {
      _isLoading = true;
      _selectedRouteId = route.id;
      _currentPrediction = null;
    });
    
    try {
      final prediction = await _aiService.predictRouteRisk(route);
      
      if (mounted) {
        setState(() {
          _currentPrediction = prediction;
        });
        
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التنبؤ: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنبؤات الذكاء الاصطناعي'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPredictions,
            tooltip: 'تحديث التنبؤات',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showAIInfo,
            tooltip: 'معلومات النظام',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ResponsiveBuilder(
          builder: (context, sizingInfo) {
            return SingleChildScrollView(
              padding: ResponsiveUtils.getResponsivePadding(sizingInfo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildRouteSelector(),
                  const SizedBox(height: 24),
                  if (_isLoading) _buildLoadingSection(),
                  if (_currentPrediction != null) ..._buildPredictionResults(),
                  const SizedBox(height: 24),
                  _buildAIInsights(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                    Icons.psychology,
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
                        'نظام التنبؤ الذكي',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تحليل المخاطر باستخدام الذكاء الاصطناعي',
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withAlpha(76),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يستخدم النظام خوارزميات متقدمة لتحليل البيانات والتنبؤ بالمخاطر المحتملة',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSelector() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر طريقاً للتحليل',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_sampleRoutes.length, (index) {
              final route = _sampleRoutes[index];
              final isSelected = _selectedRouteId == route.id;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EnhancedButton(
                  onPressed: () => _predictRoute(route),
                  style: EnhancedButtonStyle.outlined,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary.withAlpha(25)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.route,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withAlpha(178),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                route.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${route.startPoint} ← ${route.endPoint}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.straighten,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onSurface.withAlpha(127),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${route.distance.toStringAsFixed(0)} كم',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onSurface.withAlpha(127),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${route.estimatedTime.inHours}س ${route.estimatedTime.inMinutes % 60}د',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const EnhancedLoadingIndicator(),
            const SizedBox(height: 16),
            Text(
              'جاري تحليل البيانات...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'يتم تحليل عوامل الخطر والظروف المحيطة',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPredictionResults() {
    if (_currentPrediction == null) return [];
    
    return [
      _buildRiskOverview(),
      const SizedBox(height: 16),
      _buildRiskFactors(),
      const SizedBox(height: 16),
      _buildRecommendations(),
      const SizedBox(height: 16),
      _buildAlternativeRoutes(),
    ];
  }

  Widget _buildRiskOverview() {
    final prediction = _currentPrediction!;
    final riskColor = _getRiskColor(prediction.riskLevel);
    
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
                    color: riskColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getRiskIcon(prediction.riskLevel),
                    color: riskColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تقييم المخاطر',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRiskLevelText(prediction.riskLevel),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'نقاط الخطر',
                    '${(prediction.riskScore * 100).toStringAsFixed(0)}%',
                    Icons.warning,
                    riskColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'دقة التنبؤ',
                    '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                    Icons.gps_fixed,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withAlpha(127),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'صالح حتى: ${_formatTime(prediction.validUntil)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildRiskFactors() {
    final factors = _currentPrediction!.riskFactors;
    
    if (factors.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'عوامل الخطر المحددة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...factors.map((factor) => _buildRiskFactorItem(factor)),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskFactorItem(RiskFactor factor) {
    final severityColor = _getSeverityColor(factor.severity);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: severityColor.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: severityColor.withAlpha(76),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getFactorIcon(factor.type),
              color: severityColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    factor.description,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'التأثير: ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                        ),
                      ),
                      Text(
                        '${(factor.impact * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: severityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: severityColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getSeverityText(factor.severity),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _currentPrediction!.recommendations;
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'التوصيات والنصائح',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.asMap().entries.map((entry) {
              final index = entry.key;
              final recommendation = entry.value;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildAlternativeRoutes() {
    final alternatives = _currentPrediction!.alternativeRoutes;
    
    if (alternatives.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.alt_route,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'طرق بديلة مقترحة',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...alternatives.map((route) => _buildAlternativeRouteItem(route)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativeRouteItem(AlternativeRoute route) {
    final riskColor = _getRiskColorFromScore(route.riskScore);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withAlpha(76),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(51),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    route.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: riskColor.withAlpha(76),
                    ),
                  ),
                  child: Text(
                    'خطر: ${(route.riskScore * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.straighten,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(127),
                ),
                const SizedBox(width: 4),
                Text(
                  '${route.distance.toStringAsFixed(0)} كم',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(127),
                ),
                const SizedBox(width: 4),
                Text(
                  '${route.duration.toStringAsFixed(0)} دقيقة',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (route.advantages.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: route.advantages.map((advantage) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withAlpha(76),
                      ),
                    ),
                    child: Text(
                      advantage,
                      style: TextStyle(
                        color: Colors.green.shade700,
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
    );
  }

  Widget _buildAIInsights() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Colors.purple,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'إحصائيات النظام',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: Future.value(_aiService.getModelStats()),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final stats = snapshot.data!;
                
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'عينات التدريب',
                            '${stats['training_samples']}',
                            Icons.dataset,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            'التنبؤات النشطة',
                            '${stats['active_predictions']}',
                            Icons.trending_up,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatItem(
                      'إصدار النموذج',
                      stats['model_version'],
                      Icons.model_training,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.purple,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _refreshPredictions() {
    if (_selectedRouteId != null) {
      final route = _sampleRoutes.firstWhere((r) => r.id == _selectedRouteId);
      _predictRoute(route);
    }
  }

  void _showAIInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معلومات نظام الذكاء الاصطناعي'),
        content: const Text(
          'يستخدم هذا النظام خوارزميات التعلم الآلي المتقدمة لتحليل البيانات التاريخية والظروف الحالية للتنبؤ بالمخاطر المحتملة على الطرق.\n\n'
          'العوامل المدروسة:\n'
          '• الظروف الجوية\n'
          '• كثافة المرور\n'
          '• التاريخ الحادثي\n'
          '• أعمال الطرق\n'
          '• وقت السفر\n'
          '• نوع الطريق',
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

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
      case RiskLevel.critical:
        return Colors.red.shade900;
    }
  }

  Color _getRiskColorFromScore(double score) {
    if (score < 0.3) return Colors.green;
    if (score < 0.6) return Colors.orange;
    if (score < 0.8) return Colors.red;
    return Colors.red.shade900;
  }

  IconData _getRiskIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Icons.check_circle;
      case RiskLevel.medium:
        return Icons.warning;
      case RiskLevel.high:
        return Icons.error;
      case RiskLevel.critical:
        return Icons.dangerous;
    }
  }

  String _getRiskLevelText(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'خطر منخفض';
      case RiskLevel.medium:
        return 'خطر متوسط';
      case RiskLevel.high:
        return 'خطر عالي';
      case RiskLevel.critical:
        return 'خطر حرج';
    }
  }

  Color _getSeverityColor(RiskSeverity severity) {
    switch (severity) {
      case RiskSeverity.low:
        return Colors.green;
      case RiskSeverity.medium:
        return Colors.orange;
      case RiskSeverity.high:
        return Colors.red;
      case RiskSeverity.critical:
        return Colors.red.shade900;
    }
  }

  String _getSeverityText(RiskSeverity severity) {
    switch (severity) {
      case RiskSeverity.low:
        return 'منخفض';
      case RiskSeverity.medium:
        return 'متوسط';
      case RiskSeverity.high:
        return 'عالي';
      case RiskSeverity.critical:
        return 'حرج';
    }
  }

  IconData _getFactorIcon(RiskFactorType type) {
    switch (type) {
      case RiskFactorType.weather:
        return Icons.cloud;
      case RiskFactorType.traffic:
        return Icons.traffic;
      case RiskFactorType.visibility:
        return Icons.visibility;
      case RiskFactorType.historical:
        return Icons.history;
      case RiskFactorType.construction:
        return Icons.construction;
      case RiskFactorType.road:
        return Icons.route;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _predictionSubscription?.cancel();
    super.dispose();
  }
}