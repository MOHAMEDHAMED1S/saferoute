import 'package:flutter/material.dart';
import 'dart:async';
import '../services/adaptive_interface_service.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import '../theme/liquid_glass_theme.dart';
import '../widgets/liquid_glass_widgets.dart';

class AdaptiveInterfaceWidget extends StatefulWidget {
  final Widget child;
  final bool enableAdaptation;
  
  const AdaptiveInterfaceWidget({
    super.key,
    required this.child,
    this.enableAdaptation = true,
  });
  
  @override
  State<AdaptiveInterfaceWidget> createState() => _AdaptiveInterfaceWidgetState();
}

class _AdaptiveInterfaceWidgetState extends State<AdaptiveInterfaceWidget>
    with TickerProviderStateMixin {
  late AdaptiveInterfaceService _adaptiveService;
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  
  AdaptiveTheme _currentTheme = AdaptiveTheme.standard;
  AdaptiveLayout _currentLayout = AdaptiveLayout.standard;
  AdaptiveColors _currentColors = AdaptiveColors.standard;
  
  StreamSubscription<AdaptiveTheme>? _themeSubscription;
  StreamSubscription<AdaptiveLayout>? _layoutSubscription;
  StreamSubscription<AdaptiveColors>? _colorsSubscription;
  
  @override
  void initState() {
    super.initState();
    
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));
    
    _initializeAdaptiveService();
  }
  
  Future<void> _initializeAdaptiveService() async {
    _adaptiveService = AdaptiveInterfaceService();
    await _adaptiveService.initialize();
    
    if (widget.enableAdaptation) {
      _setupSubscriptions();
    }
    
    _transitionController.forward();
  }
  
  void _setupSubscriptions() {
    _themeSubscription = _adaptiveService.themeStream.listen((theme) {
      if (mounted && theme != _currentTheme) {
        setState(() {
          _currentTheme = theme;
        });
        _animateTransition();
      }
    });
    
    _layoutSubscription = _adaptiveService.layoutStream.listen((layout) {
      if (mounted && layout != _currentLayout) {
        setState(() {
          _currentLayout = layout;
        });
        _animateTransition();
      }
    });
    
    _colorsSubscription = _adaptiveService.colorsStream.listen((colors) {
      if (mounted && colors != _currentColors) {
        setState(() {
          _currentColors = colors;
        });
        _animateTransition();
      }
    });
  }
  
  void _animateTransition() {
    _transitionController.reset();
    _transitionController.forward();
  }
  
  @override
  void dispose() {
    _transitionController.dispose();
    _themeSubscription?.cancel();
    _layoutSubscription?.cancel();
    _colorsSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final themeData = _adaptiveService.getAdaptiveThemeData();
    final colorScheme = _adaptiveService.getAdaptiveColorScheme();
    final layoutProperties = _adaptiveService.getAdaptiveLayoutProperties();
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Theme(
          data: themeData.copyWith(colorScheme: colorScheme),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: _getAdaptiveGradient(),
            ),
            child: Stack(
              children: [
                // Background effects
                _buildBackgroundEffects(),
                
                // Main content with adaptive properties
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildAdaptiveContent(layoutProperties),
                ),
                
                // Adaptive overlay indicators
                if (widget.enableAdaptation)
                  _buildAdaptationIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAdaptiveContent(Map<String, dynamic> layoutProperties) {
    return DefaultTextStyle(
      style: TextStyle(
        fontSize: layoutProperties['fontSize']?.toDouble() ?? 16.0,
        color: _adaptiveService.getAdaptiveColorScheme().onBackground,
      ),
      child: IconTheme(
        data: IconThemeData(
          size: layoutProperties['iconSize']?.toDouble() ?? 24.0,
          color: _adaptiveService.getAdaptiveColorScheme().onBackground,
        ),
        child: widget.child,
      ),
    );
  }
  
  Widget _buildBackgroundEffects() {
    switch (_currentTheme) {
      case AdaptiveTheme.rain:
        return _buildRainEffect();
      case AdaptiveTheme.fog:
        return _buildFogEffect();
      case AdaptiveTheme.night:
        return _buildNightEffect();
      case AdaptiveTheme.highway:
        return _buildHighwayEffect();
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildRainEffect() {
    return Positioned.fill(
      child: CustomPaint(
        painter: RainEffectPainter(
          animation: _transitionController,
        ),
      ),
    );
  }
  
  Widget _buildFogEffect() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withAlpha(25),
        Colors.grey.withAlpha(12),
        Colors.white.withAlpha(25),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNightEffect() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Colors.amber.withAlpha(25),
              Colors.transparent,
              Colors.indigo.withAlpha(51),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHighwayEffect() {
    return Positioned.fill(
      child: CustomPaint(
        painter: HighwayEffectPainter(
          animation: _transitionController,
        ),
      ),
    );
  }
  
  Widget _buildAdaptationIndicator() {
    return Positioned(
      top: 40,
      left: 16,
      child: AnimatedOpacity(
        opacity: _fadeAnimation.value,
        duration: const Duration(milliseconds: 300),
        child: LiquidGlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getAdaptationIcon(),
                size: 16,
                color: _adaptiveService.getAdaptiveColorScheme().primary,
              ),
              const SizedBox(width: 6),
              Text(
                _getAdaptationText(),
                style: TextStyle(
                  fontSize: 12,
                  color: _adaptiveService.getAdaptiveColorScheme().onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  LinearGradient _getAdaptiveGradient() {
    switch (_currentTheme) {
      case AdaptiveTheme.night:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0D1B2A),
            const Color(0xFF1B263B),
            const Color(0xFF415A77),
          ],
        );
      case AdaptiveTheme.rain:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2C3E50),
            const Color(0xFF3498DB),
            const Color(0xFF5DADE2),
          ],
        );
      case AdaptiveTheme.fog:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFECF0F1),
            const Color(0xFFBDC3C7),
            const Color(0xFF95A5A6),
          ],
        );
      case AdaptiveTheme.highway:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF27AE60),
            const Color(0xFF2ECC71),
            const Color(0xFF58D68D),
          ],
        );
      default:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LiquidGlassTheme.backgroundColor,
            LiquidGlassTheme.primaryColor,
          ],
        );
    }
  }
  
  IconData _getAdaptationIcon() {
    switch (_currentTheme) {
      case AdaptiveTheme.night:
        return Icons.nights_stay;
      case AdaptiveTheme.rain:
        return Icons.water_drop;
      case AdaptiveTheme.fog:
        return Icons.cloud;
      case AdaptiveTheme.highway:
        return Icons.speed;
      default:
        return Icons.wb_sunny;
    }
  }
  
  String _getAdaptationText() {
    switch (_currentTheme) {
      case AdaptiveTheme.night:
        return 'وضع ليلي';
      case AdaptiveTheme.rain:
        return 'وضع مطر';
      case AdaptiveTheme.fog:
        return 'وضع ضباب';
      case AdaptiveTheme.highway:
        return 'وضع طريق سريع';
      default:
        return 'وضع عادي';
    }
  }
}

// Custom painters for visual effects
class RainEffectPainter extends CustomPainter {
  final Animation<double> animation;
  
  RainEffectPainter({required this.animation}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withAlpha(76)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    final random = DateTime.now().millisecondsSinceEpoch;
    
    for (int i = 0; i < 50; i++) {
      final x = (random * i * 0.1) % size.width;
      final y = ((random * i * 0.2 + animation.value * size.height * 2) % (size.height + 100)) - 100;
      
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 5, y + 20),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HighwayEffectPainter extends CustomPainter {
  final Animation<double> animation;
  
  HighwayEffectPainter({required this.animation}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(153)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    // Draw moving dashed lines to simulate highway speed
    final dashLength = 20.0;
    final dashSpace = 15.0;
    final totalLength = dashLength + dashSpace;
    final offset = (animation.value * totalLength * 2) % totalLength;
    
    for (double y = -offset; y < size.height + totalLength; y += totalLength) {
      canvas.drawLine(
        Offset(size.width * 0.3, y),
        Offset(size.width * 0.3, y + dashLength),
        paint,
      );
      
      canvas.drawLine(
        Offset(size.width * 0.7, y),
        Offset(size.width * 0.7, y + dashLength),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Adaptive layout helper widget
class AdaptiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Map<String, dynamic> layoutProperties) builder;
  
  const AdaptiveLayoutBuilder({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    final adaptiveService = AdaptiveInterfaceService();
    final layoutProperties = adaptiveService.getAdaptiveLayoutProperties();
    
    return builder(context, layoutProperties);
  }
}

// Adaptive color helper widget
class AdaptiveColorBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ColorScheme colorScheme) builder;
  
  const AdaptiveColorBuilder({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    final adaptiveService = AdaptiveInterfaceService();
    final colorScheme = adaptiveService.getAdaptiveColorScheme();
    
    return builder(context, colorScheme);
  }
}

// Weather-aware widget
class WeatherAwareWidget extends StatefulWidget {
  final Widget Function(BuildContext context, WeatherData? weather) builder;
  
  const WeatherAwareWidget({
    super.key,
    required this.builder,
  });
  
  @override
  State<WeatherAwareWidget> createState() => _WeatherAwareWidgetState();
}

class _WeatherAwareWidgetState extends State<WeatherAwareWidget> {
  WeatherData? _currentWeather;
  StreamSubscription<WeatherData>? _weatherSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeWeatherService();
  }
  
  Future<void> _initializeWeatherService() async {
    final weatherService = WeatherService();
    await weatherService.initialize();
    
    _weatherSubscription = weatherService.weatherStream.listen((weather) {
      if (mounted) {
        setState(() {
          _currentWeather = weather;
        });
      }
    });
    
    setState(() {
      _currentWeather = weatherService.currentWeather;
    });
  }
  
  @override
  void dispose() {
    _weatherSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentWeather);
  }
}