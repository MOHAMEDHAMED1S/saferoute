// Performance Metrics Model
class PerformanceMetrics {
  final DateTime timestamp;
  final MemoryUsage memoryUsage;
  final BatteryInfo batteryInfo;
  final double cpuUsage;
  final NetworkUsage networkUsage;
  final double frameRate;
  final double responseTime;
  final double cacheHitRate;
  final double errorRate;

  const PerformanceMetrics({
    required this.timestamp,
    required this.memoryUsage,
    required this.batteryInfo,
    required this.cpuUsage,
    required this.networkUsage,
    required this.frameRate,
    required this.responseTime,
    required this.cacheHitRate,
    required this.errorRate,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'memoryUsage': memoryUsage.toJson(),
    'batteryInfo': batteryInfo.toJson(),
    'cpuUsage': cpuUsage,
    'networkUsage': networkUsage.toJson(),
    'frameRate': frameRate,
    'responseTime': responseTime,
    'cacheHitRate': cacheHitRate,
    'errorRate': errorRate,
  };

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) => PerformanceMetrics(
    timestamp: DateTime.parse(json['timestamp']),
    memoryUsage: MemoryUsage.fromJson(json['memoryUsage']),
    batteryInfo: BatteryInfo.fromJson(json['batteryInfo']),
    cpuUsage: json['cpuUsage']?.toDouble() ?? 0.0,
    networkUsage: NetworkUsage.fromJson(json['networkUsage']),
    frameRate: json['frameRate']?.toDouble() ?? 0.0,
    responseTime: json['responseTime']?.toDouble() ?? 0.0,
    cacheHitRate: json['cacheHitRate']?.toDouble() ?? 0.0,
    errorRate: json['errorRate']?.toDouble() ?? 0.0,
  );

  PerformanceMetrics copyWith({
    DateTime? timestamp,
    MemoryUsage? memoryUsage,
    BatteryInfo? batteryInfo,
    double? cpuUsage,
    NetworkUsage? networkUsage,
    double? frameRate,
    double? responseTime,
    double? cacheHitRate,
    double? errorRate,
  }) => PerformanceMetrics(
    timestamp: timestamp ?? this.timestamp,
    memoryUsage: memoryUsage ?? this.memoryUsage,
    batteryInfo: batteryInfo ?? this.batteryInfo,
    cpuUsage: cpuUsage ?? this.cpuUsage,
    networkUsage: networkUsage ?? this.networkUsage,
    frameRate: frameRate ?? this.frameRate,
    responseTime: responseTime ?? this.responseTime,
    cacheHitRate: cacheHitRate ?? this.cacheHitRate,
    errorRate: errorRate ?? this.errorRate,
  );
}

// Memory Usage Model
class MemoryUsage {
  final DateTime timestamp;
  final int totalMemory; // bytes
  final int usedMemory; // bytes
  final int freeMemory; // bytes
  final int appMemory; // bytes
  final int cacheSize; // number of cached items
  final int heapSize; // bytes
  final double usagePercentage;

  const MemoryUsage({
    required this.timestamp,
    required this.totalMemory,
    required this.usedMemory,
    required this.freeMemory,
    required this.appMemory,
    required this.cacheSize,
    required this.heapSize,
    required this.usagePercentage,
  });

  String get totalMemoryFormatted => _formatBytes(totalMemory);
  String get usedMemoryFormatted => _formatBytes(usedMemory);
  String get freeMemoryFormatted => _formatBytes(freeMemory);
  String get appMemoryFormatted => _formatBytes(appMemory);
  String get heapSizeFormatted => _formatBytes(heapSize);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'totalMemory': totalMemory,
    'usedMemory': usedMemory,
    'freeMemory': freeMemory,
    'appMemory': appMemory,
    'cacheSize': cacheSize,
    'heapSize': heapSize,
    'usagePercentage': usagePercentage,
  };

  factory MemoryUsage.fromJson(Map<String, dynamic> json) => MemoryUsage(
    timestamp: DateTime.parse(json['timestamp']),
    totalMemory: json['totalMemory'] ?? 0,
    usedMemory: json['usedMemory'] ?? 0,
    freeMemory: json['freeMemory'] ?? 0,
    appMemory: json['appMemory'] ?? 0,
    cacheSize: json['cacheSize'] ?? 0,
    heapSize: json['heapSize'] ?? 0,
    usagePercentage: json['usagePercentage']?.toDouble() ?? 0.0,
  );

  MemoryUsage copyWith({
    DateTime? timestamp,
    int? totalMemory,
    int? usedMemory,
    int? freeMemory,
    int? appMemory,
    int? cacheSize,
    int? heapSize,
    double? usagePercentage,
  }) => MemoryUsage(
    timestamp: timestamp ?? this.timestamp,
    totalMemory: totalMemory ?? this.totalMemory,
    usedMemory: usedMemory ?? this.usedMemory,
    freeMemory: freeMemory ?? this.freeMemory,
    appMemory: appMemory ?? this.appMemory,
    cacheSize: cacheSize ?? this.cacheSize,
    heapSize: heapSize ?? this.heapSize,
    usagePercentage: usagePercentage ?? this.usagePercentage,
  );
}

// Battery Info Model
class BatteryInfo {
  final DateTime timestamp;
  final double level; // percentage
  final bool isCharging;
  final ChargingState chargingState;
  final double temperature; // Celsius
  final double voltage; // Volts
  final BatteryHealth health;
  final Duration estimatedTimeRemaining;

  const BatteryInfo({
    required this.timestamp,
    required this.level,
    required this.isCharging,
    required this.chargingState,
    required this.temperature,
    required this.voltage,
    required this.health,
    required this.estimatedTimeRemaining,
  });

  String get levelFormatted => '${level.toStringAsFixed(0)}%';
  String get temperatureFormatted => '${temperature.toStringAsFixed(1)}°C';
  String get voltageFormatted => '${voltage.toStringAsFixed(2)}V';
  String get timeRemainingFormatted {
    final hours = estimatedTimeRemaining.inHours;
    final minutes = estimatedTimeRemaining.inMinutes % 60;
    return '$hoursس $minutesد';
  }

  String get chargingStateArabic {
    switch (chargingState) {
      case ChargingState.charging:
        return 'يشحن';
      case ChargingState.discharging:
        return 'يفرغ';
      case ChargingState.full:
        return 'مكتمل';
      case ChargingState.notCharging:
        return 'لا يشحن';
    }
  }

  String get healthArabic {
    switch (health) {
      case BatteryHealth.good:
        return 'جيدة';
      case BatteryHealth.overheat:
        return 'ساخنة';
      case BatteryHealth.dead:
        return 'تالفة';
      case BatteryHealth.overVoltage:
        return 'جهد عالي';
      case BatteryHealth.unspecifiedFailure:
        return 'عطل غير محدد';
      case BatteryHealth.cold:
        return 'باردة';
      case BatteryHealth.unknown:
        return 'غير معروف';
    }
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level,
    'isCharging': isCharging,
    'chargingState': chargingState.name,
    'temperature': temperature,
    'voltage': voltage,
    'health': health.name,
    'estimatedTimeRemaining': estimatedTimeRemaining.inMinutes,
  };

  factory BatteryInfo.fromJson(Map<String, dynamic> json) => BatteryInfo(
    timestamp: DateTime.parse(json['timestamp']),
    level: json['level']?.toDouble() ?? 0.0,
    isCharging: json['isCharging'] ?? false,
    chargingState: ChargingState.values.firstWhere(
      (e) => e.name == json['chargingState'],
      orElse: () => ChargingState.discharging,
    ),
    temperature: json['temperature']?.toDouble() ?? 0.0,
    voltage: json['voltage']?.toDouble() ?? 0.0,
    health: BatteryHealth.values.firstWhere(
      (e) => e.name == json['health'],
      orElse: () => BatteryHealth.unknown,
    ),
    estimatedTimeRemaining: Duration(minutes: json['estimatedTimeRemaining'] ?? 0),
  );

  BatteryInfo copyWith({
    DateTime? timestamp,
    double? level,
    bool? isCharging,
    ChargingState? chargingState,
    double? temperature,
    double? voltage,
    BatteryHealth? health,
    Duration? estimatedTimeRemaining,
  }) => BatteryInfo(
    timestamp: timestamp ?? this.timestamp,
    level: level ?? this.level,
    isCharging: isCharging ?? this.isCharging,
    chargingState: chargingState ?? this.chargingState,
    temperature: temperature ?? this.temperature,
    voltage: voltage ?? this.voltage,
    health: health ?? this.health,
    estimatedTimeRemaining: estimatedTimeRemaining ?? this.estimatedTimeRemaining,
  );
}

// Network Usage Model
class NetworkUsage {
  final DateTime timestamp;
  final int bytesReceived;
  final int bytesSent;
  final int packetsReceived;
  final int packetsSent;
  final NetworkType connectionType;
  final double signalStrength; // percentage

  const NetworkUsage({
    required this.timestamp,
    required this.bytesReceived,
    required this.bytesSent,
    required this.packetsReceived,
    required this.packetsSent,
    required this.connectionType,
    required this.signalStrength,
  });

  String get bytesReceivedFormatted => _formatBytes(bytesReceived);
  String get bytesSentFormatted => _formatBytes(bytesSent);
  String get totalBytesFormatted => _formatBytes(bytesReceived + bytesSent);
  String get signalStrengthFormatted => '${signalStrength.toStringAsFixed(0)}%';

  String get connectionTypeArabic {
    switch (connectionType) {
      case NetworkType.wifi:
        return 'واي فاي';
      case NetworkType.mobile:
        return 'بيانات الجوال';
      case NetworkType.ethernet:
        return 'إيثرنت';
      case NetworkType.bluetooth:
        return 'بلوتوث';
      case NetworkType.vpn:
        return 'في بي إن';
      case NetworkType.unknown:
        return 'غير معروف';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'bytesReceived': bytesReceived,
    'bytesSent': bytesSent,
    'packetsReceived': packetsReceived,
    'packetsSent': packetsSent,
    'connectionType': connectionType.name,
    'signalStrength': signalStrength,
  };

  factory NetworkUsage.fromJson(Map<String, dynamic> json) => NetworkUsage(
    timestamp: DateTime.parse(json['timestamp']),
    bytesReceived: json['bytesReceived'] ?? 0,
    bytesSent: json['bytesSent'] ?? 0,
    packetsReceived: json['packetsReceived'] ?? 0,
    packetsSent: json['packetsSent'] ?? 0,
    connectionType: NetworkType.values.firstWhere(
      (e) => e.name == json['connectionType'],
      orElse: () => NetworkType.unknown,
    ),
    signalStrength: json['signalStrength']?.toDouble() ?? 0.0,
  );

  NetworkUsage copyWith({
    DateTime? timestamp,
    int? bytesReceived,
    int? bytesSent,
    int? packetsReceived,
    int? packetsSent,
    NetworkType? connectionType,
    double? signalStrength,
  }) => NetworkUsage(
    timestamp: timestamp ?? this.timestamp,
    bytesReceived: bytesReceived ?? this.bytesReceived,
    bytesSent: bytesSent ?? this.bytesSent,
    packetsReceived: packetsReceived ?? this.packetsReceived,
    packetsSent: packetsSent ?? this.packetsSent,
    connectionType: connectionType ?? this.connectionType,
    signalStrength: signalStrength ?? this.signalStrength,
  );
}

// Performance Alert Model
class PerformanceAlert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isActive;
  final double threshold;
  final double currentValue;
  final List<String> suggestions;

  const PerformanceAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isActive,
    required this.threshold,
    required this.currentValue,
    required this.suggestions,
  });

  String get severityArabic {
    switch (severity) {
      case AlertSeverity.info:
        return 'معلومات';
      case AlertSeverity.warning:
        return 'تحذير';
      case AlertSeverity.critical:
        return 'حرج';
    }
  }

  String get typeArabic {
    switch (type) {
      case AlertType.memory:
        return 'ذاكرة';
      case AlertType.battery:
        return 'بطارية';
      case AlertType.cpu:
        return 'معالج';
      case AlertType.network:
        return 'شبكة';
      case AlertType.performance:
        return 'أداء';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'severity': severity.name,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isActive': isActive,
    'threshold': threshold,
    'currentValue': currentValue,
    'suggestions': suggestions,
  };

  factory PerformanceAlert.fromJson(Map<String, dynamic> json) => PerformanceAlert(
    id: json['id'] ?? '',
    type: AlertType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => AlertType.performance,
    ),
    severity: AlertSeverity.values.firstWhere(
      (e) => e.name == json['severity'],
      orElse: () => AlertSeverity.info,
    ),
    title: json['title'] ?? '',
    message: json['message'] ?? '',
    timestamp: DateTime.parse(json['timestamp']),
    isActive: json['isActive'] ?? true,
    threshold: json['threshold']?.toDouble() ?? 0.0,
    currentValue: json['currentValue']?.toDouble() ?? 0.0,
    suggestions: List<String>.from(json['suggestions'] ?? []),
  );

  PerformanceAlert copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isActive,
    double? threshold,
    double? currentValue,
    List<String>? suggestions,
  }) => PerformanceAlert(
    id: id ?? this.id,
    type: type ?? this.type,
    severity: severity ?? this.severity,
    title: title ?? this.title,
    message: message ?? this.message,
    timestamp: timestamp ?? this.timestamp,
    isActive: isActive ?? this.isActive,
    threshold: threshold ?? this.threshold,
    currentValue: currentValue ?? this.currentValue,
    suggestions: suggestions ?? this.suggestions,
  );
}

// Performance Log Model
class PerformanceLog {
  final DateTime timestamp;
  final PerformanceMetrics metrics;
  final List<PerformanceAlert> alerts;
  final List<String> optimizationsApplied;

  const PerformanceLog({
    required this.timestamp,
    required this.metrics,
    required this.alerts,
    required this.optimizationsApplied,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'metrics': metrics.toJson(),
    'alerts': alerts.map((alert) => alert.toJson()).toList(),
    'optimizationsApplied': optimizationsApplied,
  };

  factory PerformanceLog.fromJson(Map<String, dynamic> json) => PerformanceLog(
    timestamp: DateTime.parse(json['timestamp']),
    metrics: PerformanceMetrics.fromJson(json['metrics']),
    alerts: (json['alerts'] as List)
        .map((alert) => PerformanceAlert.fromJson(alert))
        .toList(),
    optimizationsApplied: List<String>.from(json['optimizationsApplied'] ?? []),
  );

  PerformanceLog copyWith({
    DateTime? timestamp,
    PerformanceMetrics? metrics,
    List<PerformanceAlert>? alerts,
    List<String>? optimizationsApplied,
  }) => PerformanceLog(
    timestamp: timestamp ?? this.timestamp,
    metrics: metrics ?? this.metrics,
    alerts: alerts ?? this.alerts,
    optimizationsApplied: optimizationsApplied ?? this.optimizationsApplied,
  );
}

// Performance Report Model
class PerformanceReport {
  final DateTime startTime;
  final DateTime endTime;
  final int totalLogs;
  final double averageMemoryUsage;
  final double averageBatteryLevel;
  final double averageCPUUsage;
  final double averageFrameRate;
  final int totalAlerts;
  final int optimizationsApplied;
  final List<String> recommendations;

  const PerformanceReport({
    required this.startTime,
    required this.endTime,
    required this.totalLogs,
    required this.averageMemoryUsage,
    required this.averageBatteryLevel,
    required this.averageCPUUsage,
    required this.averageFrameRate,
    required this.totalAlerts,
    required this.optimizationsApplied,
    required this.recommendations,
  });

  Duration get duration => endTime.difference(startTime);
  String get durationFormatted {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '$hoursس $minutesد';
  }

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'totalLogs': totalLogs,
    'averageMemoryUsage': averageMemoryUsage,
    'averageBatteryLevel': averageBatteryLevel,
    'averageCPUUsage': averageCPUUsage,
    'averageFrameRate': averageFrameRate,
    'totalAlerts': totalAlerts,
    'optimizationsApplied': optimizationsApplied,
    'recommendations': recommendations,
  };

  factory PerformanceReport.fromJson(Map<String, dynamic> json) => PerformanceReport(
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
    totalLogs: json['totalLogs'] ?? 0,
    averageMemoryUsage: json['averageMemoryUsage']?.toDouble() ?? 0.0,
    averageBatteryLevel: json['averageBatteryLevel']?.toDouble() ?? 0.0,
    averageCPUUsage: json['averageCPUUsage']?.toDouble() ?? 0.0,
    averageFrameRate: json['averageFrameRate']?.toDouble() ?? 0.0,
    totalAlerts: json['totalAlerts'] ?? 0,
    optimizationsApplied: json['optimizationsApplied'] ?? 0,
    recommendations: List<String>.from(json['recommendations'] ?? []),
  );

  PerformanceReport copyWith({
    DateTime? startTime,
    DateTime? endTime,
    int? totalLogs,
    double? averageMemoryUsage,
    double? averageBatteryLevel,
    double? averageCPUUsage,
    double? averageFrameRate,
    int? totalAlerts,
    int? optimizationsApplied,
    List<String>? recommendations,
  }) => PerformanceReport(
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    totalLogs: totalLogs ?? this.totalLogs,
    averageMemoryUsage: averageMemoryUsage ?? this.averageMemoryUsage,
    averageBatteryLevel: averageBatteryLevel ?? this.averageBatteryLevel,
    averageCPUUsage: averageCPUUsage ?? this.averageCPUUsage,
    averageFrameRate: averageFrameRate ?? this.averageFrameRate,
    totalAlerts: totalAlerts ?? this.totalAlerts,
    optimizationsApplied: optimizationsApplied ?? this.optimizationsApplied,
    recommendations: recommendations ?? this.recommendations,
  );
}

// Enums
enum ChargingState {
  charging,
  discharging,
  full,
  notCharging,
}

enum BatteryHealth {
  good,
  overheat,
  dead,
  overVoltage,
  unspecifiedFailure,
  cold,
  unknown,
}

enum NetworkType {
  wifi,
  mobile,
  ethernet,
  bluetooth,
  vpn,
  unknown,
}

enum AlertType {
  memory,
  battery,
  cpu,
  network,
  performance,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

// Extensions
extension ChargingStateExtension on ChargingState {
  String get arabicName {
    switch (this) {
      case ChargingState.charging:
        return 'يشحن';
      case ChargingState.discharging:
        return 'يفرغ';
      case ChargingState.full:
        return 'مكتمل';
      case ChargingState.notCharging:
        return 'لا يشحن';
    }
  }
}

extension BatteryHealthExtension on BatteryHealth {
  String get arabicName {
    switch (this) {
      case BatteryHealth.good:
        return 'جيدة';
      case BatteryHealth.overheat:
        return 'ساخنة';
      case BatteryHealth.dead:
        return 'تالفة';
      case BatteryHealth.overVoltage:
        return 'جهد عالي';
      case BatteryHealth.unspecifiedFailure:
        return 'عطل غير محدد';
      case BatteryHealth.cold:
        return 'باردة';
      case BatteryHealth.unknown:
        return 'غير معروف';
    }
  }
}

extension NetworkTypeExtension on NetworkType {
  String get arabicName {
    switch (this) {
      case NetworkType.wifi:
        return 'واي فاي';
      case NetworkType.mobile:
        return 'بيانات الجوال';
      case NetworkType.ethernet:
        return 'إيثرنت';
      case NetworkType.bluetooth:
        return 'بلوتوث';
      case NetworkType.vpn:
        return 'في بي إن';
      case NetworkType.unknown:
        return 'غير معروف';
    }
  }
}

extension AlertTypeExtension on AlertType {
  String get arabicName {
    switch (this) {
      case AlertType.memory:
        return 'ذاكرة';
      case AlertType.battery:
        return 'بطارية';
      case AlertType.cpu:
        return 'معالج';
      case AlertType.network:
        return 'شبكة';
      case AlertType.performance:
        return 'أداء';
    }
  }
}

extension AlertSeverityExtension on AlertSeverity {
  String get arabicName {
    switch (this) {
      case AlertSeverity.info:
        return 'معلومات';
      case AlertSeverity.warning:
        return 'تحذير';
      case AlertSeverity.critical:
        return 'حرج';
    }
  }
}