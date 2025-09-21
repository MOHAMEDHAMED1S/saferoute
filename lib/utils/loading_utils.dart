import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

// Smart loading manager
class LoadingManager {
  static final Map<String, LoadingState> _loadingStates = {};
  static final StreamController<LoadingEvent> _eventController = StreamController.broadcast();
  
  static Stream<LoadingEvent> get events => _eventController.stream;

  static void startLoading(String key, {String? message, bool cancellable = true}) {
    _loadingStates[key] = LoadingState(
      key: key,
      isLoading: true,
      message: message,
      cancellable: cancellable,
      startTime: DateTime.now(),
    );
    _eventController.add(LoadingEvent(key: key, type: LoadingEventType.started));
  }

  static void updateLoading(String key, {String? message, double? progress}) {
    final state = _loadingStates[key];
    if (state != null) {
      _loadingStates[key] = state.copyWith(
        message: message,
        progress: progress,
      );
      _eventController.add(LoadingEvent(key: key, type: LoadingEventType.updated));
    }
  }

  static void stopLoading(String key, {String? result}) {
    final state = _loadingStates[key];
    if (state != null) {
      _loadingStates[key] = state.copyWith(
        isLoading: false,
        result: result,
        endTime: DateTime.now(),
      );
      _eventController.add(LoadingEvent(key: key, type: LoadingEventType.completed));
      
      // Auto-remove after 5 seconds
      Timer(const Duration(seconds: 5), () {
        _loadingStates.remove(key);
      });
    }
  }

  static void cancelLoading(String key) {
    final state = _loadingStates[key];
    if (state != null && state.cancellable) {
      _loadingStates.remove(key);
      _eventController.add(LoadingEvent(key: key, type: LoadingEventType.cancelled));
    }
  }

  static LoadingState? getLoadingState(String key) => _loadingStates[key];
  
  static bool isLoading(String key) => _loadingStates[key]?.isLoading ?? false;
  
  static List<LoadingState> getAllLoadingStates() => _loadingStates.values.toList();
  
  static void clearAll() {
    _loadingStates.clear();
    _eventController.add(LoadingEvent(key: 'all', type: LoadingEventType.cleared));
  }

  static void dispose() {
    _eventController.close();
    _loadingStates.clear();
  }
}

class LoadingState {
  final String key;
  final bool isLoading;
  final String? message;
  final double? progress;
  final bool cancellable;
  final DateTime startTime;
  final DateTime? endTime;
  final String? result;

  LoadingState({
    required this.key,
    required this.isLoading,
    this.message,
    this.progress,
    required this.cancellable,
    required this.startTime,
    this.endTime,
    this.result,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  LoadingState copyWith({
    bool? isLoading,
    String? message,
    double? progress,
    bool? cancellable,
    DateTime? endTime,
    String? result,
  }) {
    return LoadingState(
      key: key,
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      cancellable: cancellable ?? this.cancellable,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      result: result ?? this.result,
    );
  }
}

class LoadingEvent {
  final String key;
  final LoadingEventType type;
  final DateTime timestamp;

  LoadingEvent({
    required this.key,
    required this.type,
  }) : timestamp = DateTime.now();
}

enum LoadingEventType {
  started,
  updated,
  completed,
  cancelled,
  cleared,
}

// Smart loading overlay
class SmartLoadingOverlay extends StatefulWidget {
  final Widget child;
  final String? loadingKey;
  final bool showGlobalLoading;
  final Widget Function(BuildContext, LoadingState)? loadingBuilder;

  const SmartLoadingOverlay({
    Key? key,
    required this.child,
    this.loadingKey,
    this.showGlobalLoading = false,
    this.loadingBuilder,
  }) : super(key: key);

  @override
  State<SmartLoadingOverlay> createState() => _SmartLoadingOverlayState();
}

class _SmartLoadingOverlayState extends State<SmartLoadingOverlay> {
  StreamSubscription<LoadingEvent>? _subscription;
  LoadingState? _currentState;

  @override
  void initState() {
    super.initState();
    _subscription = LoadingManager.events.listen(_onLoadingEvent);
    _updateCurrentState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onLoadingEvent(LoadingEvent event) {
    if (widget.loadingKey == null || event.key == widget.loadingKey) {
      _updateCurrentState();
    }
  }

  void _updateCurrentState() {
    setState(() {
      if (widget.loadingKey != null) {
        _currentState = LoadingManager.getLoadingState(widget.loadingKey!);
      } else if (widget.showGlobalLoading) {
        final states = LoadingManager.getAllLoadingStates();
        _currentState = states.where((s) => s.isLoading).isNotEmpty 
            ? states.first 
            : null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentState?.isLoading == true)
          widget.loadingBuilder?.call(context, _currentState!) ??
          _buildDefaultLoading(_currentState!),
      ],
    );
  }

  Widget _buildDefaultLoading(LoadingState state) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (state.message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.message!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (state.progress != null) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: state.progress),
                  const SizedBox(height: 8),
                  Text(
                    '${(state.progress! * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (state.cancellable) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => LoadingManager.cancelLoading(state.key),
                    child: const Text('إلغاء'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Adaptive loading indicator
class AdaptiveLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final LoadingStyle style;
  final Duration animationDuration;

  const AdaptiveLoadingIndicator({
    Key? key,
    this.size = 24.0,
    this.color,
    this.style = LoadingStyle.circular,
    this.animationDuration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  State<AdaptiveLoadingIndicator> createState() => _AdaptiveLoadingIndicatorState();
}

class _AdaptiveLoadingIndicatorState extends State<AdaptiveLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;
    
    switch (widget.style) {
      case LoadingStyle.circular:
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            color: color,
            strokeWidth: 2.0,
          ),
        );
      
      case LoadingStyle.dots:
        return _buildDotsIndicator(color);
      
      case LoadingStyle.pulse:
        return _buildPulseIndicator(color);
      
      case LoadingStyle.wave:
        return _buildWaveIndicator(color);
      
      case LoadingStyle.spinner:
        return _buildSpinnerIndicator(color);
    }
  }

  Widget _buildDotsIndicator(Color color) {
    return SizedBox(
      width: widget.size * 3,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = math.sin((_animation.value * 2 * math.pi) + delay);
              return Transform.translate(
                offset: Offset(0, value * 5),
                child: Container(
                  width: widget.size / 4,
                  height: widget.size / 4,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPulseIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final scale = 0.5 + (_animation.value * 0.5);
        final opacity = 1.0 - _animation.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withAlpha((opacity * 255).round()),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveIndicator(Color color) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final delay = index * 0.1;
              final height = widget.size * (0.3 + 0.7 * math.sin((_animation.value * 2 * math.pi) + delay));
              return Container(
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildSpinnerIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 2 * math.pi,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              border: Border.all(
                color: color.withAlpha(76),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(widget.size / 2),
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: 2),
                  right: BorderSide.none,
                  bottom: BorderSide.none,
                  left: BorderSide.none,
                ),
                borderRadius: BorderRadius.circular(widget.size / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum LoadingStyle {
  circular,
  dots,
  pulse,
  wave,
  spinner,
}

// Progressive loading widget
class ProgressiveLoader<T> extends StatefulWidget {
  final Future<T> Function() loader;
  final Widget Function(BuildContext, T) builder;
  final Widget Function(BuildContext)? loadingBuilder;
  final Widget Function(BuildContext, Object)? errorBuilder;
  final Duration? timeout;
  final bool retryOnError;
  final int maxRetries;

  const ProgressiveLoader({
    Key? key,
    required this.loader,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.timeout,
    this.retryOnError = true,
    this.maxRetries = 3,
  }) : super(key: key);

  @override
  State<ProgressiveLoader<T>> createState() => _ProgressiveLoaderState<T>();
}

class _ProgressiveLoaderState<T> extends State<ProgressiveLoader<T>> {
  late Future<T> _future;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _future = widget.timeout != null
        ? widget.loader().timeout(widget.timeout!)
        : widget.loader();
  }

  void _retry() {
    if (_retryCount < widget.maxRetries) {
      setState(() {
        _retryCount++;
        _loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ??
              const Center(child: AdaptiveLoadingIndicator());
        }

        if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error!) ??
              _buildDefaultError(snapshot.error!);
        }

        if (snapshot.hasData) {
          return widget.builder(context, snapshot.data!);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDefaultError(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ أثناء التحميل',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (widget.retryOnError && _retryCount < widget.maxRetries) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _retry,
              child: Text('إعادة المحاولة (${_retryCount + 1}/${widget.maxRetries})'),
            ),
          ],
        ],
      ),
    );
  }
}

// Skeleton loading widget
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration animationDuration;

  const SkeletonLoader({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
    this.animationDuration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                math.max(0.0, _animation.value - 0.3),
                _animation.value,
                math.min(1.0, _animation.value + 0.3),
              ],
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}

// Batch loader for multiple items
class BatchLoader<T> {
  final Future<List<T>> Function(List<String>) batchLoader;
  final Duration batchDelay;
  final int maxBatchSize;
  
  final Map<String, Completer<T>> _pendingRequests = {};
  Timer? _batchTimer;

  BatchLoader({
    required this.batchLoader,
    this.batchDelay = const Duration(milliseconds: 50),
    this.maxBatchSize = 10,
  });

  Future<T> load(String key) {
    if (_pendingRequests.containsKey(key)) {
      return _pendingRequests[key]!.future;
    }

    final completer = Completer<T>();
    _pendingRequests[key] = completer;

    _scheduleBatch();
    return completer.future;
  }

  void _scheduleBatch() {
    _batchTimer?.cancel();
    
    if (_pendingRequests.length >= maxBatchSize) {
      _executeBatch();
    } else {
      _batchTimer = Timer(batchDelay, _executeBatch);
    }
  }

  void _executeBatch() async {
    if (_pendingRequests.isEmpty) return;

    final batch = Map<String, Completer<T>>.from(_pendingRequests);
    _pendingRequests.clear();
    _batchTimer?.cancel();

    try {
      final results = await batchLoader(batch.keys.toList());
      
      int index = 0;
      for (final entry in batch.entries) {
        if (index < results.length) {
          entry.value.complete(results[index]);
        } else {
          entry.value.completeError('Batch result missing for key: ${entry.key}');
        }
        index++;
      }
    } catch (error) {
      for (final completer in batch.values) {
        completer.completeError(error);
      }
    }
  }

  void dispose() {
    _batchTimer?.cancel();
    for (final completer in _pendingRequests.values) {
      completer.completeError('BatchLoader disposed');
    }
    _pendingRequests.clear();
  }
}

// Loading utilities
class LoadingUtils {
  static Widget buildSkeletonList({
    required int itemCount,
    double itemHeight = 80,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SkeletonLoader(
                width: 60,
                height: 60,
                borderRadius: BorderRadius.circular(30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    SkeletonLoader(
                      width: 200,
                      height: 14,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    const SizedBox(height: 8),
                    SkeletonLoader(
                      width: 150,
                      height: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget buildSkeletonCard({
    double? width,
    double height = 200,
    EdgeInsets? margin,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(
                width: double.infinity,
                height: 100,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 16),
              SkeletonLoader(
                width: double.infinity,
                height: 16,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              SkeletonLoader(
                width: 200,
                height: 14,
                borderRadius: BorderRadius.circular(7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showLoadingDialog(BuildContext context, {
    String? message,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AdaptiveLoadingIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}