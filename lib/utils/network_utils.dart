import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Network connectivity manager
class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;
  NetworkManager._internal();

  final StreamController<NetworkStatus> _statusController = StreamController.broadcast();
  NetworkStatus _currentStatus = NetworkStatus.unknown;
  Timer? _connectivityTimer;
  final List<NetworkRequest> _pendingRequests = [];
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  Stream<NetworkStatus> get statusStream => _statusController.stream;
  NetworkStatus get currentStatus => _currentStatus;

  void initialize() {
    _startConnectivityMonitoring();
    _checkInitialConnectivity();
  }

  void _startConnectivityMonitoring() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkInitialConnectivity() async {
    // Start with unknown status to allow app to load
    _currentStatus = NetworkStatus.unknown;
    _statusController.add(_currentStatus);
    
    // Check connectivity after a short delay to allow app initialization
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      final newStatus = result.isNotEmpty && result[0].rawAddress.isNotEmpty
          ? NetworkStatus.connected
          : NetworkStatus.disconnected;
      
      if (newStatus != _currentStatus) {
        _currentStatus = newStatus;
        _statusController.add(_currentStatus);
        
        if (_currentStatus == NetworkStatus.connected) {
          _processPendingRequests();
        }
      }
    } catch (e) {
      // Only set to disconnected if we were previously connected
      // This prevents showing offline screen on app startup
      if (_currentStatus == NetworkStatus.connected) {
        _currentStatus = NetworkStatus.disconnected;
        _statusController.add(_currentStatus);
      }
    }
  }

  void _processPendingRequests() {
    final requests = List<NetworkRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    
    for (final request in requests) {
      request.retry();
    }
  }

  void addPendingRequest(NetworkRequest request) {
    _pendingRequests.add(request);
  }

  void removePendingRequest(NetworkRequest request) {
    _pendingRequests.remove(request);
  }

  // Cache management
  void cacheData(String key, dynamic data, {Duration? ttl}) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    
    if (ttl != null) {
      Timer(ttl, () {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      });
    }
  }

  T? getCachedData<T>(String key, {Duration? maxAge}) {
    if (!_cache.containsKey(key)) return null;
    
    if (maxAge != null && _cacheTimestamps.containsKey(key)) {
      final age = DateTime.now().difference(_cacheTimestamps[key]!);
      if (age > maxAge) {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
        return null;
      }
    }
    
    return _cache[key] as T?;
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  void dispose() {
    _connectivityTimer?.cancel();
    _statusController.close();
    _pendingRequests.clear();
    clearCache();
  }
}

enum NetworkStatus {
  unknown,
  connected,
  disconnected,
}

// Network request wrapper
class NetworkRequest {
  final String url;
  final String method;
  final Map<String, String>? headers;
  final dynamic body;
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;
  final Completer<dynamic> _completer = Completer();
  
  int _retryCount = 0;
  bool _cancelled = false;

  NetworkRequest({
    required this.url,
    this.method = 'GET',
    this.headers,
    this.body,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  });

  Future<dynamic> execute() {
    _performRequest();
    return _completer.future;
  }

  void _performRequest() async {
    if (_cancelled) return;

    try {
      // Check network connectivity
      if (NetworkManager().currentStatus == NetworkStatus.disconnected) {
        NetworkManager().addPendingRequest(this);
        return;
      }

      // Check cache first for GET requests
      if (method == 'GET') {
        final cachedData = NetworkManager().getCachedData(
          url,
          maxAge: const Duration(minutes: 5),
        );
        if (cachedData != null) {
          _completer.complete(cachedData);
          return;
        }
      }

      final client = HttpClient();
      client.connectionTimeout = timeout;
      
      late HttpClientRequest request;
      
      switch (method.toUpperCase()) {
        case 'GET':
          request = await client.getUrl(Uri.parse(url));
          break;
        case 'POST':
          request = await client.postUrl(Uri.parse(url));
          break;
        case 'PUT':
          request = await client.putUrl(Uri.parse(url));
          break;
        case 'DELETE':
          request = await client.deleteUrl(Uri.parse(url));
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported');
      }

      // Add headers
      headers?.forEach((key, value) {
        request.headers.add(key, value);
      });

      // Add body for POST/PUT requests
      if (body != null && (method == 'POST' || method == 'PUT')) {
        if (body is String) {
          request.write(body);
        } else {
          request.write(jsonEncode(body));
          request.headers.contentType = ContentType.json;
        }
      }

      final response = await request.close().timeout(timeout);
      final responseBody = await response.transform(utf8.decoder).join();
      
      client.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        dynamic data;
        try {
          data = jsonDecode(responseBody);
        } catch (e) {
          data = responseBody;
        }
        
        // Cache successful GET responses
        if (method == 'GET') {
          NetworkManager().cacheData(url, data);
        }
        
        _completer.complete(data);
      } else {
        throw HttpException('HTTP ${response.statusCode}: $responseBody');
      }
    } catch (e) {
      if (_cancelled) return;
      
      if (_retryCount < maxRetries) {
        _retryCount++;
        if (kDebugMode) {
          print('Request failed, retrying in ${retryDelay.inSeconds}s (attempt $_retryCount/$maxRetries)');
        }
        Timer(retryDelay, _performRequest);
      } else {
        _completer.completeError(e);
      }
    }
  }

  void retry() {
    if (!_completer.isCompleted && !_cancelled) {
      _retryCount = 0;
      _performRequest();
    }
  }

  void cancel() {
    _cancelled = true;
    NetworkManager().removePendingRequest(this);
    if (!_completer.isCompleted) {
      _completer.completeError('Request cancelled');
    }
  }
}

// Network-aware widget
class NetworkAwareWidget extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext)? offlineBuilder;
  final bool showOfflineIndicator;

  const NetworkAwareWidget({
    Key? key,
    required this.child,
    this.offlineBuilder,
    this.showOfflineIndicator = true,
  }) : super(key: key);

  @override
  State<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends State<NetworkAwareWidget> {
  StreamSubscription<NetworkStatus>? _subscription;
  NetworkStatus _status = NetworkStatus.unknown;

  @override
  void initState() {
    super.initState();
    _status = NetworkManager().currentStatus;
    _subscription = NetworkManager().statusStream.listen((status) {
      setState(() {
        _status = status;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show offline widget if explicitly disconnected (not unknown)
    if (_status == NetworkStatus.disconnected) {
      return widget.offlineBuilder?.call(context) ?? _buildOfflineWidget();
    }

    return Stack(
      children: [
        widget.child,
        if (widget.showOfflineIndicator && _status == NetworkStatus.disconnected)
          _buildOfflineIndicator(),
      ],
    );
  }

  Widget _buildOfflineWidget() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد اتصال بالإنترنت',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await NetworkManager()._checkConnectivity();
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineIndicator() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.red,
        child: const Text(
          'لا يوجد اتصال بالإنترنت',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// Smart HTTP client
class SmartHttpClient {
  static final SmartHttpClient _instance = SmartHttpClient._internal();
  factory SmartHttpClient() => _instance;
  SmartHttpClient._internal();

  final Map<String, NetworkRequest> _activeRequests = {};

  Future<T> get<T>(String url, {
    Map<String, String>? headers,
    Duration? timeout,
    bool useCache = true,
  }) async {
    return _makeRequest<T>(
      url: url,
      method: 'GET',
      headers: headers,
      timeout: timeout,
    );
  }

  Future<T> post<T>(String url, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    return _makeRequest<T>(
      url: url,
      method: 'POST',
      headers: headers,
      body: body,
      timeout: timeout,
    );
  }

  Future<T> put<T>(String url, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    return _makeRequest<T>(
      url: url,
      method: 'PUT',
      headers: headers,
      body: body,
      timeout: timeout,
    );
  }

  Future<T> delete<T>(String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return _makeRequest<T>(
      url: url,
      method: 'DELETE',
      headers: headers,
      timeout: timeout,
    );
  }

  Future<T> _makeRequest<T>({
    required String url,
    required String method,
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    final requestKey = '$method:$url';
    
    // Cancel existing request if any
    _activeRequests[requestKey]?.cancel();
    
    final request = NetworkRequest(
      url: url,
      method: method,
      headers: headers,
      body: body,
      timeout: timeout ?? const Duration(seconds: 30),
    );
    
    _activeRequests[requestKey] = request;
    
    try {
      final result = await request.execute();
      _activeRequests.remove(requestKey);
      return result as T;
    } catch (e) {
      _activeRequests.remove(requestKey);
      rethrow;
    }
  }

  void cancelRequest(String url, {String method = 'GET'}) {
    final requestKey = '$method:$url';
    _activeRequests[requestKey]?.cancel();
    _activeRequests.remove(requestKey);
  }

  void cancelAllRequests() {
    for (final request in _activeRequests.values) {
      request.cancel();
    }
    _activeRequests.clear();
  }
}

// Network optimization utilities
class NetworkOptimizer {
  static const int _maxConcurrentRequests = 6;
  static final List<NetworkRequest> _requestQueue = [];
  static int _activeRequests = 0;

  static Future<T> optimizedRequest<T>(NetworkRequest request) async {
    if (_activeRequests >= _maxConcurrentRequests) {
      final completer = Completer<T>();
      _requestQueue.add(request);
      
      // Wait for a slot to become available
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_activeRequests < _maxConcurrentRequests) {
          timer.cancel();
          _processRequest<T>(request, completer);
        }
      });
      
      return completer.future;
    } else {
      final completer = Completer<T>();
      _processRequest<T>(request, completer);
      return completer.future;
    }
  }

  static void _processRequest<T>(NetworkRequest request, Completer<T> completer) async {
    _activeRequests++;
    
    try {
      final result = await request.execute();
      completer.complete(result as T);
    } catch (e) {
      completer.completeError(e);
    } finally {
      _activeRequests--;
      _processQueue();
    }
  }

  static void _processQueue() {
    while (_requestQueue.isNotEmpty && _activeRequests < _maxConcurrentRequests) {
      final request = _requestQueue.removeAt(0);
      final completer = Completer();
      _processRequest(request, completer);
    }
  }

  static void clearQueue() {
    _requestQueue.clear();
  }

  static int get queueLength => _requestQueue.length;
  static int get activeRequestCount => _activeRequests;
}

// Bandwidth monitor
class BandwidthMonitor {
  static final BandwidthMonitor _instance = BandwidthMonitor._internal();
  factory BandwidthMonitor() => _instance;
  BandwidthMonitor._internal();

  final List<BandwidthSample> _samples = [];
  Timer? _monitorTimer;
  int _totalBytesDownloaded = 0;
  int _totalBytesUploaded = 0;
  DateTime _lastSampleTime = DateTime.now();

  void startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _takeSample();
    });
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
  }

  void _takeSample() {
    final now = DateTime.now();
    final duration = now.difference(_lastSampleTime);
    
    if (duration.inMilliseconds > 0) {
      final downloadSpeed = _totalBytesDownloaded / duration.inSeconds;
      final uploadSpeed = _totalBytesUploaded / duration.inSeconds;
      
      _samples.add(BandwidthSample(
        timestamp: now,
        downloadSpeed: downloadSpeed,
        uploadSpeed: uploadSpeed,
      ));
      
      // Keep only last 60 samples (1 minute)
      if (_samples.length > 60) {
        _samples.removeAt(0);
      }
      
      _totalBytesDownloaded = 0;
      _totalBytesUploaded = 0;
      _lastSampleTime = now;
    }
  }

  void recordDownload(int bytes) {
    _totalBytesDownloaded += bytes;
  }

  void recordUpload(int bytes) {
    _totalBytesUploaded += bytes;
  }

  double get averageDownloadSpeed {
    if (_samples.isEmpty) return 0;
    return _samples.map((s) => s.downloadSpeed).reduce((a, b) => a + b) / _samples.length;
  }

  double get averageUploadSpeed {
    if (_samples.isEmpty) return 0;
    return _samples.map((s) => s.uploadSpeed).reduce((a, b) => a + b) / _samples.length;
  }

  NetworkQuality get networkQuality {
    final avgSpeed = averageDownloadSpeed;
    if (avgSpeed > 1000000) return NetworkQuality.excellent; // > 1 MB/s
    if (avgSpeed > 500000) return NetworkQuality.good;       // > 500 KB/s
    if (avgSpeed > 100000) return NetworkQuality.fair;       // > 100 KB/s
    return NetworkQuality.poor;
  }

  List<BandwidthSample> get samples => List.unmodifiable(_samples);

  void dispose() {
    stopMonitoring();
    _samples.clear();
  }
}

class BandwidthSample {
  final DateTime timestamp;
  final double downloadSpeed; // bytes per second
  final double uploadSpeed;   // bytes per second

  BandwidthSample({
    required this.timestamp,
    required this.downloadSpeed,
    required this.uploadSpeed,
  });
}

enum NetworkQuality {
  poor,
  fair,
  good,
  excellent,
}

// Network utilities
class NetworkUtils {
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String formatSpeed(double bytesPerSecond) {
    return '${formatBytes(bytesPerSecond.round())}/s';
  }

  static Color getQualityColor(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return Colors.green;
      case NetworkQuality.good:
        return Colors.lightGreen;
      case NetworkQuality.fair:
        return Colors.orange;
      case NetworkQuality.poor:
        return Colors.red;
    }
  }

  static String getQualityText(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return 'ممتاز';
      case NetworkQuality.good:
        return 'جيد';
      case NetworkQuality.fair:
        return 'متوسط';
      case NetworkQuality.poor:
        return 'ضعيف';
    }
  }

  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  static Map<String, String> getDefaultHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'SafeRoute/1.0',
    };
  }

  static Duration getTimeoutForQuality(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return const Duration(seconds: 10);
      case NetworkQuality.good:
        return const Duration(seconds: 15);
      case NetworkQuality.fair:
        return const Duration(seconds: 30);
      case NetworkQuality.poor:
        return const Duration(seconds: 60);
    }
  }

  static int getRetriesForQuality(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return 1;
      case NetworkQuality.good:
        return 2;
      case NetworkQuality.fair:
        return 3;
      case NetworkQuality.poor:
        return 5;
    }
  }
}