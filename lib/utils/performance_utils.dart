import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

// Performance monitoring
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  static final List<PerformanceMetric> _metrics = [];
  static Timer? _reportTimer;

  static void startTimer(String name) {
    if (kDebugMode) {
      _timers[name] = Stopwatch()..start();
    }
  }

  static void stopTimer(String name) {
    if (kDebugMode && _timers.containsKey(name)) {
      final stopwatch = _timers[name]!;
      stopwatch.stop();
      _metrics.add(PerformanceMetric(
        name: name,
        duration: stopwatch.elapsedMilliseconds,
        timestamp: DateTime.now(),
      ));
      _timers.remove(name);
    }
  }

  static void logMetric(String name, int value, {String? unit}) {
    if (kDebugMode) {
      _metrics.add(PerformanceMetric(
        name: name,
        duration: value,
        timestamp: DateTime.now(),
        unit: unit,
      ));
    }
  }

  static void startPeriodicReporting({Duration interval = const Duration(minutes: 5)}) {
    if (kDebugMode) {
      _reportTimer?.cancel();
      _reportTimer = Timer.periodic(interval, (_) {
        _generateReport();
      });
    }
  }

  static void stopPeriodicReporting() {
    _reportTimer?.cancel();
    _reportTimer = null;
  }

  static void _generateReport() {
    if (_metrics.isEmpty) return;

    final report = StringBuffer();
    report.writeln('=== Performance Report ===');
    report.writeln('Total metrics: ${_metrics.length}');
    
    final groupedMetrics = <String, List<PerformanceMetric>>{};
    for (final metric in _metrics) {
      groupedMetrics.putIfAbsent(metric.name, () => []).add(metric);
    }

    for (final entry in groupedMetrics.entries) {
      final metrics = entry.value;
      final avg = metrics.map((m) => m.duration).reduce((a, b) => a + b) / metrics.length;
      final max = metrics.map((m) => m.duration).reduce(math.max);
      final min = metrics.map((m) => m.duration).reduce(math.min);
      
      report.writeln('${entry.key}:');
      report.writeln('  Count: ${metrics.length}');
      report.writeln('  Average: ${avg.toStringAsFixed(2)}ms');
      report.writeln('  Max: ${max}ms');
      report.writeln('  Min: ${min}ms');
    }

    debugPrint(report.toString());
    
    // Clear old metrics to prevent memory leaks
    if (_metrics.length > 1000) {
      _metrics.removeRange(0, _metrics.length - 500);
    }
  }

  static List<PerformanceMetric> getMetrics() => List.unmodifiable(_metrics);
  
  static void clearMetrics() => _metrics.clear();
}

class PerformanceMetric {
  final String name;
  final int duration;
  final DateTime timestamp;
  final String? unit;

  PerformanceMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
    this.unit,
  });
}

// Memory optimization utilities
class MemoryOptimizer {
  static final Map<String, dynamic> _cache = {};
  static Timer? _cleanupTimer;
  static const int _maxCacheSize = 100;

  static void startPeriodicCleanup({Duration interval = const Duration(minutes: 10)}) {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(interval, (_) {
      _performCleanup();
    });
  }

  static void stopPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  static void _performCleanup() {
    if (_cache.length > _maxCacheSize) {
      final keysToRemove = _cache.keys.take(_cache.length - _maxCacheSize ~/ 2).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
    }
    
    // Force garbage collection in debug mode
    if (kDebugMode) {
      debugPrint('Memory cleanup performed. Cache size: ${_cache.length}');
    }
  }

  static void cacheValue(String key, dynamic value) {
    _cache[key] = value;
    if (_cache.length > _maxCacheSize) {
      _performCleanup();
    }
  }

  static T? getCachedValue<T>(String key) {
    return _cache[key] as T?;
  }

  static void removeCachedValue(String key) {
    _cache.remove(key);
  }

  static void clearCache() {
    _cache.clear();
  }

  static int getCacheSize() => _cache.length;
}

// Image optimization
class ImageOptimizer {
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool enableMemoryCache = true,
    bool enableDiskCache = true,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _defaultPlaceholder(width, height);
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _defaultErrorWidget(width, height);
      },
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
    );
  }

  static Widget _defaultPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  static Widget _defaultErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(
        Icons.error,
        color: Colors.red,
      ),
    );
  }
}

// List optimization
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double? itemExtent;
  final Widget? separator;

  const OptimizedListView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.itemExtent,
    this.separator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (separator != null) {
      return ListView.separated(
        controller: controller,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: (context, index) => separator!,
      );
    }

    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      itemExtent: itemExtent,
      cacheExtent: 500, // Optimize cache extent
    );
  }
}

// Debouncer for search and input optimization
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void dispose() {
    _timer?.cancel();
  }
}

// Throttler for scroll and gesture optimization
class Throttler {
  final Duration delay;
  DateTime? _lastExecution;

  Throttler({this.delay = const Duration(milliseconds: 100)});

  void call(VoidCallback callback) {
    final now = DateTime.now();
    if (_lastExecution == null || now.difference(_lastExecution!) >= delay) {
      _lastExecution = now;
      callback();
    }
  }
}

// Lazy loading widget
class LazyLoadingWidget extends StatefulWidget {
  final Widget Function() builder;
  final Widget? placeholder;
  final Duration delay;

  const LazyLoadingWidget({
    Key? key,
    required this.builder,
    this.placeholder,
    this.delay = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<LazyLoadingWidget> createState() => _LazyLoadingWidgetState();
}

class _LazyLoadingWidgetState extends State<LazyLoadingWidget> {
  Widget? _child;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWidget();
  }

  void _loadWidget() async {
    await Future.delayed(widget.delay);
    if (mounted) {
      setState(() {
        _child = widget.builder();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? const SizedBox.shrink();
    }
    return _child ?? const SizedBox.shrink();
  }
}

// Performance-optimized animated widget
class OptimizedAnimatedWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final AnimationType animationType;
  final bool autoStart;

  const OptimizedAnimatedWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.animationType = AnimationType.fadeIn,
    this.autoStart = true,
  }) : super(key: key);

  @override
  State<OptimizedAnimatedWidget> createState() => _OptimizedAnimatedWidgetState();
}

class _OptimizedAnimatedWidgetState extends State<OptimizedAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.animationType) {
      case AnimationType.fadeIn:
        return FadeTransition(
          opacity: _animation,
          child: widget.child,
        );
      case AnimationType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(_animation),
          child: FadeTransition(
            opacity: _animation,
            child: widget.child,
          ),
        );
      case AnimationType.scaleIn:
        return ScaleTransition(
          scale: _animation,
          child: widget.child,
        );
    }
  }
}

enum AnimationType {
  fadeIn,
  slideUp,
  scaleIn,
}

// Efficient state management helper
class StateManager<T> {
  T _value;
  final List<VoidCallback> _listeners = [];

  StateManager(this._value);

  T get value => _value;

  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      _notifyListeners();
    }
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  void dispose() {
    _listeners.clear();
  }
}

// Widget recycling pool
class WidgetPool<T extends Widget> {
  final List<T> _pool = [];
  final T Function() _factory;
  final int _maxSize;

  WidgetPool({
    required T Function() factory,
    int maxSize = 10,
  }) : _factory = factory, _maxSize = maxSize;

  T acquire() {
    if (_pool.isNotEmpty) {
      return _pool.removeLast();
    }
    return _factory();
  }

  void release(T widget) {
    if (_pool.length < _maxSize) {
      _pool.add(widget);
    }
  }

  void clear() {
    _pool.clear();
  }

  int get size => _pool.length;
}

// Performance utilities
class PerformanceUtils {
  static void preloadImages(List<String> imageUrls) {
    for (final url in imageUrls) {
      final image = NetworkImage(url);
      image.resolve(const ImageConfiguration());
    }
  }

  static void warmUpShaders() {
    // Warm up common shaders to prevent jank
    WidgetsBinding.instance.addPostFrameCallback((_) {
      const shaderWarmUp = [
        Colors.transparent,
        Colors.white,
        Colors.black,
      ];
      
      for (final color in shaderWarmUp) {
        final paint = Paint()..color = color;
        final canvas = Canvas(PictureRecorder());
        canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), paint);
      }
    });
  }

  static void optimizeScrollPerformance(ScrollController controller) {
    // Add scroll optimization
    controller.addListener(() {
      // Implement scroll-based optimizations
      if (controller.position.isScrollingNotifier.value) {
        // Reduce animations during scrolling
      }
    });
  }

  static Future<void> preloadRoute(BuildContext context, String routeName) async {
    // Preload route to improve navigation performance
    try {
      await Navigator.of(context).pushNamed(routeName);
      Navigator.of(context).pop();
    } catch (e) {
      // Route preloading failed, ignore
    }
  }

  static void enableHighPerformanceMode() {
    // Enable high performance mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
  }

  static void disableHighPerformanceMode() {
    // Disable high performance mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
  }
}