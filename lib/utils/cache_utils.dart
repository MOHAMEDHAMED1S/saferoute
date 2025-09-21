import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

// For unawaited function
void unawaited(Future<void> future) {
  // Intentionally ignore the future
}

// Advanced cache manager
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, CacheEntry> _cache = {};
  final Map<String, int> _accessCount = {};
  final Map<String, DateTime> _lastAccess = {};
  Timer? _cleanupTimer;
  
  static const int _maxCacheSize = 100;
  static const Duration _defaultTtl = Duration(hours: 1);
  static const Duration _cleanupInterval = Duration(minutes: 10);

  void initialize() {
    _startPeriodicCleanup();
  }

  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _performCleanup();
    });
  }

  void _performCleanup() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    // Remove expired entries
    for (final entry in _cache.entries) {
      if (entry.value.isExpired(now)) {
        keysToRemove.add(entry.key);
      }
    }

    // Remove least recently used entries if cache is too large
    if (_cache.length - keysToRemove.length > _maxCacheSize) {
      final sortedKeys = _lastAccess.entries
          .where((e) => !keysToRemove.contains(e.key))
          .toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final excessCount = _cache.length - keysToRemove.length - _maxCacheSize;
      for (int i = 0; i < excessCount && i < sortedKeys.length; i++) {
        keysToRemove.add(sortedKeys[i].key);
      }
    }

    // Remove selected keys
    for (final key in keysToRemove) {
      _cache.remove(key);
      _accessCount.remove(key);
      _lastAccess.remove(key);
    }

    if (kDebugMode && keysToRemove.isNotEmpty) {
      print('Cache cleanup: removed ${keysToRemove.length} entries');
    }
  }

  void put<T>(String key, T value, {Duration? ttl, CachePriority priority = CachePriority.normal}) {
    final entry = CacheEntry<T>(
      value: value,
      createdAt: DateTime.now(),
      ttl: ttl ?? _defaultTtl,
      priority: priority,
    );

    _cache[key] = entry;
    _accessCount[key] = 0;
    _lastAccess[key] = DateTime.now();

    // Immediate cleanup if cache is too large
    if (_cache.length > _maxCacheSize * 1.2) {
      _performCleanup();
    }
  }

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired(DateTime.now())) {
      remove(key);
      return null;
    }

    // Update access statistics
    _accessCount[key] = (_accessCount[key] ?? 0) + 1;
    _lastAccess[key] = DateTime.now();

    return entry.value as T?;
  }

  bool contains(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (entry.isExpired(DateTime.now())) {
      remove(key);
      return false;
    }
    
    return true;
  }

  void remove(String key) {
    _cache.remove(key);
    _accessCount.remove(key);
    _lastAccess.remove(key);
  }

  void clear() {
    _cache.clear();
    _accessCount.clear();
    _lastAccess.clear();
  }

  void clearExpired() {
    final now = DateTime.now();
    final keysToRemove = _cache.entries
        .where((entry) => entry.value.isExpired(now))
        .map((entry) => entry.key)
        .toList();

    for (final key in keysToRemove) {
      remove(key);
    }
  }

  CacheStats getStats() {
    final now = DateTime.now();
    final expiredCount = _cache.values.where((entry) => entry.isExpired(now)).length;
    
    return CacheStats(
      totalEntries: _cache.length,
      expiredEntries: expiredCount,
      memoryUsage: _estimateMemoryUsage(),
      hitRate: _calculateHitRate(),
    );
  }

  int _estimateMemoryUsage() {
    int totalSize = 0;
    for (final entry in _cache.values) {
      totalSize += _estimateEntrySize(entry);
    }
    return totalSize;
  }

  int _estimateEntrySize(CacheEntry entry) {
    // Rough estimation of memory usage
    if (entry.value is String) {
      return (entry.value as String).length * 2; // UTF-16
    } else if (entry.value is List) {
      return (entry.value as List).length * 8; // Rough estimate
    } else if (entry.value is Map) {
      return (entry.value as Map).length * 16; // Rough estimate
    }
    return 64; // Default estimate for other types
  }

  double _calculateHitRate() {
    if (_accessCount.isEmpty) return 0.0;
    
    final totalAccesses = _accessCount.values.reduce((a, b) => a + b);
    final hits = _accessCount.length;
    
    return hits / totalAccesses;
  }

  void dispose() {
    _cleanupTimer?.cancel();
    clear();
  }
}

class CacheEntry<T> {
  final T value;
  final DateTime createdAt;
  final Duration ttl;
  final CachePriority priority;

  CacheEntry({
    required this.value,
    required this.createdAt,
    required this.ttl,
    required this.priority,
  });

  bool isExpired(DateTime now) {
    return now.difference(createdAt) > ttl;
  }

  DateTime get expiresAt => createdAt.add(ttl);
}

enum CachePriority {
  low,
  normal,
  high,
  critical,
}

class CacheStats {
  final int totalEntries;
  final int expiredEntries;
  final int memoryUsage;
  final double hitRate;

  CacheStats({
    required this.totalEntries,
    required this.expiredEntries,
    required this.memoryUsage,
    required this.hitRate,
  });

  int get activeEntries => totalEntries - expiredEntries;
  
  String get formattedMemoryUsage {
    if (memoryUsage < 1024) return '$memoryUsage B';
    if (memoryUsage < 1024 * 1024) return '${(memoryUsage / 1024).toStringAsFixed(1)} KB';
    return '${(memoryUsage / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  String get formattedHitRate => '${(hitRate * 100).toStringAsFixed(1)}%';
}

// Image cache manager
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  final Map<String, ImageCacheEntry> _imageCache = {};
  static const int _maxImageCacheSize = 50;
  static const Duration _imageCacheTtl = Duration(hours: 24);

  void cacheImage(String url, ImageProvider image, {int? sizeBytes}) {
    if (_imageCache.length >= _maxImageCacheSize) {
      _evictOldestImage();
    }

    _imageCache[url] = ImageCacheEntry(
      image: image,
      cachedAt: DateTime.now(),
      sizeBytes: sizeBytes ?? 0,
    );
  }

  ImageProvider? getCachedImage(String url) {
    final entry = _imageCache[url];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.cachedAt) > _imageCacheTtl) {
      _imageCache.remove(url);
      return null;
    }

    return entry.image;
  }

  void _evictOldestImage() {
    if (_imageCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _imageCache.entries) {
      if (oldestTime == null || entry.value.cachedAt.isBefore(oldestTime)) {
        oldestTime = entry.value.cachedAt;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _imageCache.remove(oldestKey);
    }
  }

  void clearImageCache() {
    _imageCache.clear();
  }

  int get imageCacheSize => _imageCache.length;
  
  int get totalImageCacheBytes {
    return _imageCache.values
        .map((entry) => entry.sizeBytes)
        .fold(0, (sum, size) => sum + size);
  }
}

class ImageCacheEntry {
  final ImageProvider image;
  final DateTime cachedAt;
  final int sizeBytes;

  ImageCacheEntry({
    required this.image,
    required this.cachedAt,
    required this.sizeBytes,
  });
}

// Persistent cache using shared preferences simulation
class PersistentCache {
  static final PersistentCache _instance = PersistentCache._internal();
  factory PersistentCache() => _instance;
  PersistentCache._internal();

  final Map<String, String> _storage = {}; // Simulated persistent storage
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    // In a real implementation, this would load from SharedPreferences or similar
    await Future.delayed(const Duration(milliseconds: 100));
    _initialized = true;
  }

  Future<void> setString(String key, String value) async {
    await initialize();
    _storage[key] = value;
  }

  Future<void> setObject<T>(String key, T object) async {
    await initialize();
    _storage[key] = jsonEncode(object);
  }

  Future<String?> getString(String key) async {
    await initialize();
    return _storage[key];
  }

  Future<T?> getObject<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    await initialize();
    final jsonString = _storage[key];
    if (jsonString == null) return null;
    
    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  Future<void> remove(String key) async {
    await initialize();
    _storage.remove(key);
  }

  Future<void> clear() async {
    await initialize();
    _storage.clear();
  }

  Future<Set<String>> getKeys() async {
    await initialize();
    return _storage.keys.toSet();
  }

  Future<bool> containsKey(String key) async {
    await initialize();
    return _storage.containsKey(key);
  }
}

// Memory pool for object reuse
class ObjectPool<T> {
  final List<T> _pool = [];
  final T Function() _factory;
  final void Function(T)? _reset;
  final int _maxSize;
  int _created = 0;
  int _reused = 0;

  ObjectPool({
    required T Function() factory,
    void Function(T)? reset,
    int maxSize = 20,
  }) : _factory = factory, _reset = reset, _maxSize = maxSize;

  T acquire() {
    if (_pool.isNotEmpty) {
      final obj = _pool.removeLast();
      _reset?.call(obj);
      _reused++;
      return obj;
    }
    
    _created++;
    return _factory();
  }

  void release(T object) {
    if (_pool.length < _maxSize) {
      _pool.add(object);
    }
  }

  void clear() {
    _pool.clear();
  }

  int get poolSize => _pool.length;
  int get totalCreated => _created;
  int get totalReused => _reused;
  double get reuseRate => _created > 0 ? _reused / (_created + _reused) : 0.0;
}

// Smart preloader for data
class DataPreloader {
  static final DataPreloader _instance = DataPreloader._internal();
  factory DataPreloader() => _instance;
  DataPreloader._internal();

  final Map<String, Future<dynamic>> _preloadingTasks = {};
  final Set<String> _preloadedKeys = {};

  Future<T> preload<T>(String key, Future<T> Function() loader) async {
    if (_preloadedKeys.contains(key)) {
      final cached = CacheManager().get<T>(key);
      if (cached != null) return cached;
    }

    if (_preloadingTasks.containsKey(key)) {
      return await _preloadingTasks[key] as T;
    }

    final task = loader();
    _preloadingTasks[key] = task;

    try {
      final result = await task;
      CacheManager().put(key, result, ttl: const Duration(hours: 1));
      _preloadedKeys.add(key);
      return result;
    } finally {
      _preloadingTasks.remove(key);
    }
  }

  void preloadInBackground<T>(String key, Future<T> Function() loader) {
    if (_preloadedKeys.contains(key) || _preloadingTasks.containsKey(key)) {
      return;
    }

    preload(key, loader).catchError((error) {
      if (kDebugMode) {
        print('Background preload failed for $key: $error');
      }
    });
  }

  bool isPreloaded(String key) => _preloadedKeys.contains(key);
  bool isPreloading(String key) => _preloadingTasks.containsKey(key);

  void cancelPreload(String key) {
    _preloadingTasks.remove(key);
  }

  void clearPreloaded() {
    _preloadedKeys.clear();
    _preloadingTasks.clear();
  }
}

// Cache-aware widget
class CacheAwareWidget<T> extends StatefulWidget {
  final String cacheKey;
  final Future<T> Function() loader;
  final Widget Function(BuildContext, T) builder;
  final Widget Function(BuildContext)? loadingBuilder;
  final Widget Function(BuildContext, Object)? errorBuilder;
  final Duration? cacheTtl;
  final bool preloadInBackground;

  const CacheAwareWidget({
    Key? key,
    required this.cacheKey,
    required this.loader,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.cacheTtl,
    this.preloadInBackground = false,
  }) : super(key: key);

  @override
  State<CacheAwareWidget<T>> createState() => _CacheAwareWidgetState<T>();
}

class _CacheAwareWidgetState<T> extends State<CacheAwareWidget<T>> {
  T? _data;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    // Check cache first
    final cached = CacheManager().get<T>(widget.cacheKey);
    if (cached != null) {
      setState(() {
        _data = cached;
        _loading = false;
        _error = null;
      });
      
      // Optionally refresh in background
      if (widget.preloadInBackground) {
        DataPreloader().preloadInBackground(widget.cacheKey, widget.loader);
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await DataPreloader().preload(widget.cacheKey, widget.loader);
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _data == null) {
      return widget.errorBuilder?.call(context, _error!) ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(height: 8),
                Text('خطأ في التحميل: $_error'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
    }

    if (_data != null) {
      return widget.builder(context, _data!);
    }

    return const SizedBox.shrink();
  }
}

// Cache utilities
class CacheUtils {
  static String generateCacheKey(String prefix, Map<String, dynamic> params) {
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final paramsString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '$prefix:$paramsString';
  }

  static void warmUpCache(List<String> keys, Map<String, Future<dynamic> Function()> loaders) {
    for (final key in keys) {
      final loader = loaders[key];
      if (loader != null && !CacheManager().contains(key)) {
        DataPreloader().preloadInBackground(key, loader);
      }
    }
  }

  static Future<void> preloadCriticalData() async {
    // Preload commonly used data
    final criticalKeys = [
      'user_profile',
      'app_settings',
      'recent_routes',
      'security_status',
    ];

    for (final key in criticalKeys) {
      if (!CacheManager().contains(key)) {
        // In a real app, you would have actual loaders for these
        DataPreloader().preloadInBackground(key, () async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'cached_$key';
        });
      }
    }
  }

  static void optimizeMemoryUsage() {
    CacheManager()._performCleanup();
    ImageCacheManager().clearImageCache();
    
    // Force garbage collection in debug mode
    if (kDebugMode) {
      print('Memory optimization performed');
    }
  }

  static Map<String, dynamic> getCacheReport() {
    final cacheStats = CacheManager().getStats();
    final imageCacheSize = ImageCacheManager().imageCacheSize;
    final imageCacheBytes = ImageCacheManager().totalImageCacheBytes;
    
    return {
      'cache_entries': cacheStats.totalEntries,
      'active_entries': cacheStats.activeEntries,
      'expired_entries': cacheStats.expiredEntries,
      'memory_usage': cacheStats.formattedMemoryUsage,
      'hit_rate': cacheStats.formattedHitRate,
      'image_cache_size': imageCacheSize,
      'image_cache_bytes': imageCacheBytes,
    };
  }
  
}

// Extension for DataPreloader to add background preloading
extension DataPreloaderExtension on DataPreloader {
  Future<void> preloadInBackground<T>(String key, Future<T> Function() loader) async {
    // Run in background without blocking
    unawaited(preload(key, loader));
  }
}