// تعدادات التقارير التحليلية
enum AnalyticsReportType {
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

enum AnalyticsCategory {
  driving,
  performance,
  safety,
  fuel,
  routes,
  usage,
}

enum ReportFormat {
  pdf,
  excel,
  csv,
  json,
}

enum ChartType {
  line,
  bar,
  pie,
  area,
  scatter,
  heatmap,
}

// نموذج التقرير التحليلي
class AnalyticsReportModel {
  final String id;
  final String title;
  final String description;
  final AnalyticsReportType type;
  final AnalyticsCategory category;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> data;
  final List<ChartData> charts;
  final ReportSettings settings;
  final bool isGenerated;
  final String? filePath;
  final int version;
  final ReportSummary summary;

  const AnalyticsReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.createdAt,
    this.updatedAt,
    required this.startDate,
    required this.endDate,
    required this.data,
    required this.charts,
    required this.settings,
    this.isGenerated = false,
    this.filePath,
    this.version = 1,
    required this.summary,
  });

  factory AnalyticsReportModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsReportModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: AnalyticsReportType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AnalyticsReportType.daily,
      ),
      category: AnalyticsCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AnalyticsCategory.driving,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      charts: (json['charts'] as List<dynamic>? ?? [])
          .map((chart) => ChartData.fromJson(chart))
          .toList(),
      settings: ReportSettings.fromJson(json['settings'] ?? {}),
      isGenerated: json['isGenerated'] ?? false,
      filePath: json['filePath'],
      version: json['version'] ?? 1,
      summary: ReportSummary.fromJson(json['summary'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'category': category.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'data': data,
      'charts': charts.map((chart) => chart.toJson()).toList(),
      'settings': settings.toJson(),
      'isGenerated': isGenerated,
      'filePath': filePath,
      'version': version,
      'summary': summary.toJson(),
    };
  }

  AnalyticsReportModel copyWith({
    String? id,
    String? title,
    String? description,
    AnalyticsReportType? type,
    AnalyticsCategory? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? data,
    List<ChartData>? charts,
    ReportSettings? settings,
    bool? isGenerated,
    String? filePath,
    int? version,
    ReportSummary? summary,
  }) {
    return AnalyticsReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      data: data ?? this.data,
      charts: charts ?? this.charts,
      settings: settings ?? this.settings,
      isGenerated: isGenerated ?? this.isGenerated,
      filePath: filePath ?? this.filePath,
      version: version ?? this.version,
      summary: summary ?? this.summary,
    );
  }
}

// ملخص التقرير
class ReportSummary {
  final String overview;
  final List<KeyMetric> keyMetrics;
  final List<String> insights;
  final List<String> recommendations;
  final double overallScore;

  const ReportSummary({
    required this.overview,
    required this.keyMetrics,
    required this.insights,
    required this.recommendations,
    required this.overallScore,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      overview: json['overview'] ?? '',
      keyMetrics: (json['keyMetrics'] as List<dynamic>? ?? [])
          .map((metric) => KeyMetric.fromJson(metric))
          .toList(),
      insights: List<String>.from(json['insights'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      overallScore: (json['overallScore'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overview': overview,
      'keyMetrics': keyMetrics.map((metric) => metric.toJson()).toList(),
      'insights': insights,
      'recommendations': recommendations,
      'overallScore': overallScore,
    };
  }
}

// المقياس الرئيسي
class KeyMetric {
  final String name;
  final String value;
  final String unit;
  final double? change;
  final String? changeType; // 'increase', 'decrease', 'stable'
  final String description;

  const KeyMetric({
    required this.name,
    required this.value,
    required this.unit,
    this.change,
    this.changeType,
    required this.description,
  });

  factory KeyMetric.fromJson(Map<String, dynamic> json) {
    return KeyMetric(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      unit: json['unit'] ?? '',
      change: json['change']?.toDouble(),
      changeType: json['changeType'],
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'change': change,
      'changeType': changeType,
      'description': description,
    };
  }
}

// بيانات الرسوم البيانية
class ChartData {
  final String id;
  final String title;
  final ChartType type;
  final List<DataPoint> dataPoints;
  final ChartStyle style;
  final Map<String, dynamic> options;

  const ChartData({
    required this.id,
    required this.title,
    required this.type,
    required this.dataPoints,
    required this.style,
    this.options = const {},
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: ChartType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChartType.line,
      ),
      dataPoints: (json['dataPoints'] as List<dynamic>? ?? [])
          .map((point) => DataPoint.fromJson(point))
          .toList(),
      style: ChartStyle.fromJson(json['style'] ?? {}),
      options: Map<String, dynamic>.from(json['options'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'dataPoints': dataPoints.map((point) => point.toJson()).toList(),
      'style': style.toJson(),
      'options': options,
    };
  }
}

// نقطة البيانات
class DataPoint {
  final String label;
  final double value;
  final DateTime? timestamp;
  final Map<String, dynamic> metadata;
  final String? color;

  const DataPoint({
    required this.label,
    required this.value,
    this.timestamp,
    this.metadata = const {},
    this.color,
  });

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'timestamp': timestamp?.toIso8601String(),
      'metadata': metadata,
      'color': color,
    };
  }
}

// أسلوب الرسم البياني
class ChartStyle {
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final double strokeWidth;
  final bool showGrid;
  final bool showLegend;
  final bool showLabels;
  final bool showAnimation;
  final Map<String, dynamic> customStyles;

  const ChartStyle({
    this.primaryColor = '#2196F3',
    this.secondaryColor = '#1976D2',
    this.backgroundColor = 'transparent',
    this.strokeWidth = 2.0,
    this.showGrid = true,
    this.showLegend = true,
    this.showLabels = true,
    this.showAnimation = true,
    this.customStyles = const {},
  });

  factory ChartStyle.fromJson(Map<String, dynamic> json) {
    return ChartStyle(
      primaryColor: json['primaryColor'] ?? '#2196F3',
      secondaryColor: json['secondaryColor'] ?? '#1976D2',
      backgroundColor: json['backgroundColor'] ?? 'transparent',
      strokeWidth: (json['strokeWidth'] ?? 2.0).toDouble(),
      showGrid: json['showGrid'] ?? true,
      showLegend: json['showLegend'] ?? true,
      showLabels: json['showLabels'] ?? true,
      showAnimation: json['showAnimation'] ?? true,
      customStyles: Map<String, dynamic>.from(json['customStyles'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'backgroundColor': backgroundColor,
      'strokeWidth': strokeWidth,
      'showGrid': showGrid,
      'showLegend': showLegend,
      'showLabels': showLabels,
      'showAnimation': showAnimation,
      'customStyles': customStyles,
    };
  }
}

// إعدادات التقرير
class ReportSettings {
  final bool includeCharts;
  final bool includeSummary;
  final bool includeDetails;
  final ReportFormat format;
  final String language;
  final bool autoGenerate;
  final Duration? autoGenerateInterval;
  final List<String> recipients;
  final bool enableNotifications;
  final Map<String, dynamic> customSettings;

  const ReportSettings({
    this.includeCharts = true,
    this.includeSummary = true,
    this.includeDetails = true,
    this.format = ReportFormat.pdf,
    this.language = 'ar',
    this.autoGenerate = false,
    this.autoGenerateInterval,
    this.recipients = const [],
    this.enableNotifications = true,
    this.customSettings = const {},
  });

  factory ReportSettings.fromJson(Map<String, dynamic> json) {
    return ReportSettings(
      includeCharts: json['includeCharts'] ?? true,
      includeSummary: json['includeSummary'] ?? true,
      includeDetails: json['includeDetails'] ?? true,
      format: ReportFormat.values.firstWhere(
        (e) => e.name == json['format'],
        orElse: () => ReportFormat.pdf,
      ),
      language: json['language'] ?? 'ar',
      autoGenerate: json['autoGenerate'] ?? false,
      autoGenerateInterval: json['autoGenerateInterval'] != null
          ? Duration(milliseconds: json['autoGenerateInterval'])
          : null,
      recipients: List<String>.from(json['recipients'] ?? []),
      enableNotifications: json['enableNotifications'] ?? true,
      customSettings: Map<String, dynamic>.from(json['customSettings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includeCharts': includeCharts,
      'includeSummary': includeSummary,
      'includeDetails': includeDetails,
      'format': format.name,
      'language': language,
      'autoGenerate': autoGenerate,
      'autoGenerateInterval': autoGenerateInterval?.inMilliseconds,
      'recipients': recipients,
      'enableNotifications': enableNotifications,
      'customSettings': customSettings,
    };
  }
}

// إحصائيات القيادة المتقدمة
class AdvancedDrivingStats {
  final double totalDistance;
  final Duration totalTime;
  final double averageSpeed;
  final double maxSpeed;
  final int tripCount;
  final double fuelConsumption;
  final double co2Emissions;
  final int safetyScore;
  final int ecoScore;
  final List<RouteAnalysis> routeAnalytics;
  final Map<String, dynamic> behaviorMetrics;

  const AdvancedDrivingStats({
    required this.totalDistance,
    required this.totalTime,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.tripCount,
    required this.fuelConsumption,
    required this.co2Emissions,
    required this.safetyScore,
    required this.ecoScore,
    required this.routeAnalytics,
    this.behaviorMetrics = const {},
  });

  factory AdvancedDrivingStats.fromJson(Map<String, dynamic> json) {
    return AdvancedDrivingStats(
      totalDistance: (json['totalDistance'] ?? 0).toDouble(),
      totalTime: Duration(milliseconds: json['totalTime'] ?? 0),
      averageSpeed: (json['averageSpeed'] ?? 0).toDouble(),
      maxSpeed: (json['maxSpeed'] ?? 0).toDouble(),
      tripCount: json['tripCount'] ?? 0,
      fuelConsumption: (json['fuelConsumption'] ?? 0).toDouble(),
      co2Emissions: (json['co2Emissions'] ?? 0).toDouble(),
      safetyScore: json['safetyScore'] ?? 0,
      ecoScore: json['ecoScore'] ?? 0,
      routeAnalytics: (json['routeAnalytics'] as List<dynamic>? ?? [])
          .map((route) => RouteAnalysis.fromJson(route))
          .toList(),
      behaviorMetrics: Map<String, dynamic>.from(json['behaviorMetrics'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDistance': totalDistance,
      'totalTime': totalTime.inMilliseconds,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'tripCount': tripCount,
      'fuelConsumption': fuelConsumption,
      'co2Emissions': co2Emissions,
      'safetyScore': safetyScore,
      'ecoScore': ecoScore,
      'routeAnalytics': routeAnalytics.map((route) => route.toJson()).toList(),
      'behaviorMetrics': behaviorMetrics,
    };
  }
}

// تحليل المسار
class RouteAnalysis {
  final String routeId;
  final String routeName;
  final double distance;
  final Duration duration;
  final int usageCount;
  final double averageSpeed;
  final double fuelEfficiency;
  final int trafficLevel;
  final List<String> insights;

  const RouteAnalysis({
    required this.routeId,
    required this.routeName,
    required this.distance,
    required this.duration,
    required this.usageCount,
    required this.averageSpeed,
    required this.fuelEfficiency,
    required this.trafficLevel,
    required this.insights,
  });

  factory RouteAnalysis.fromJson(Map<String, dynamic> json) {
    return RouteAnalysis(
      routeId: json['routeId'] ?? '',
      routeName: json['routeName'] ?? '',
      distance: (json['distance'] ?? 0).toDouble(),
      duration: Duration(milliseconds: json['duration'] ?? 0),
      usageCount: json['usageCount'] ?? 0,
      averageSpeed: (json['averageSpeed'] ?? 0).toDouble(),
      fuelEfficiency: (json['fuelEfficiency'] ?? 0).toDouble(),
      trafficLevel: json['trafficLevel'] ?? 0,
      insights: List<String>.from(json['insights'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'routeName': routeName,
      'distance': distance,
      'duration': duration.inMilliseconds,
      'usageCount': usageCount,
      'averageSpeed': averageSpeed,
      'fuelEfficiency': fuelEfficiency,
      'trafficLevel': trafficLevel,
      'insights': insights,
    };
  }
}

// قالب التقرير
class ReportTemplate {
  final String id;
  final String name;
  final String description;
  final AnalyticsCategory category;
  final List<String> sections;
  final Map<String, dynamic> defaultSettings;
  final bool isCustom;
  final String? iconPath;

  const ReportTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.sections,
    this.defaultSettings = const {},
    this.isCustom = false,
    this.iconPath,
  });

  factory ReportTemplate.fromJson(Map<String, dynamic> json) {
    return ReportTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: AnalyticsCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AnalyticsCategory.driving,
      ),
      sections: List<String>.from(json['sections'] ?? []),
      defaultSettings: Map<String, dynamic>.from(json['defaultSettings'] ?? {}),
      isCustom: json['isCustom'] ?? false,
      iconPath: json['iconPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'sections': sections,
      'defaultSettings': defaultSettings,
      'isCustom': isCustom,
      'iconPath': iconPath,
    };
  }
}

// امتدادات مفيدة
extension AnalyticsReportTypeExtension on AnalyticsReportType {
  String get displayName {
    switch (this) {
      case AnalyticsReportType.daily:
        return 'يومي';
      case AnalyticsReportType.weekly:
        return 'أسبوعي';
      case AnalyticsReportType.monthly:
        return 'شهري';
      case AnalyticsReportType.yearly:
        return 'سنوي';
      case AnalyticsReportType.custom:
        return 'مخصص';
    }
  }

  Duration get defaultDuration {
    switch (this) {
      case AnalyticsReportType.daily:
        return const Duration(days: 1);
      case AnalyticsReportType.weekly:
        return const Duration(days: 7);
      case AnalyticsReportType.monthly:
        return const Duration(days: 30);
      case AnalyticsReportType.yearly:
        return const Duration(days: 365);
      case AnalyticsReportType.custom:
        return const Duration(days: 1);
    }
  }
}

extension AnalyticsCategoryExtension on AnalyticsCategory {
  String get displayName {
    switch (this) {
      case AnalyticsCategory.driving:
        return 'القيادة';
      case AnalyticsCategory.performance:
        return 'الأداء';
      case AnalyticsCategory.safety:
        return 'السلامة';
      case AnalyticsCategory.fuel:
        return 'الوقود';
      case AnalyticsCategory.routes:
        return 'المسارات';
      case AnalyticsCategory.usage:
        return 'الاستخدام';
    }
  }

  String get icon {
    switch (this) {
      case AnalyticsCategory.driving:
        return '🚗';
      case AnalyticsCategory.performance:
        return '📊';
      case AnalyticsCategory.safety:
        return '🛡️';
      case AnalyticsCategory.fuel:
        return '⛽';
      case AnalyticsCategory.routes:
        return '🗺️';
      case AnalyticsCategory.usage:
        return '📱';
    }
  }
}

extension ReportFormatExtension on ReportFormat {
  String get displayName {
    switch (this) {
      case ReportFormat.pdf:
        return 'PDF';
      case ReportFormat.excel:
        return 'Excel';
      case ReportFormat.csv:
        return 'CSV';
      case ReportFormat.json:
        return 'JSON';
    }
  }

  String get fileExtension {
    switch (this) {
      case ReportFormat.pdf:
        return '.pdf';
      case ReportFormat.excel:
        return '.xlsx';
      case ReportFormat.csv:
        return '.csv';
      case ReportFormat.json:
        return '.json';
    }
  }
}

// ثوابت التقارير التحليلية
class AnalyticsReportConstants {
  static const List<ReportTemplate> defaultTemplates = [
    ReportTemplate(
      id: 'daily_driving_analytics',
      name: 'تحليلات القيادة اليومية',
      description: 'تقرير شامل عن أنشطة وسلوكيات القيادة اليومية',
      category: AnalyticsCategory.driving,
      sections: ['summary', 'trips', 'performance', 'safety', 'recommendations'],
    ),
    ReportTemplate(
      id: 'weekly_performance_analytics',
      name: 'تحليلات الأداء الأسبوعية',
      description: 'تحليل مفصل لأداء التطبيق والنظام أسبوعياً',
      category: AnalyticsCategory.performance,
      sections: ['metrics', 'trends', 'alerts', 'optimizations', 'insights'],
    ),
    ReportTemplate(
      id: 'monthly_comprehensive_analytics',
      name: 'التحليلات الشاملة الشهرية',
      description: 'تحليل شامل ومفصل للبيانات والإحصائيات الشهرية',
      category: AnalyticsCategory.usage,
      sections: ['overview', 'detailed_analysis', 'comparisons', 'predictions', 'actionable_insights'],
    ),
    ReportTemplate(
      id: 'fuel_efficiency_report',
      name: 'تقرير كفاءة الوقود',
      description: 'تحليل استهلاك الوقود وتوصيات التحسين',
      category: AnalyticsCategory.fuel,
      sections: ['consumption_analysis', 'efficiency_trends', 'cost_analysis', 'eco_recommendations'],
    ),
    ReportTemplate(
      id: 'safety_analytics_report',
      name: 'تقرير تحليلات السلامة',
      description: 'تحليل شامل لمؤشرات السلامة وسلوك القيادة',
      category: AnalyticsCategory.safety,
      sections: ['safety_score', 'incident_analysis', 'behavior_patterns', 'improvement_suggestions'],
    ),
  ];

  static const Map<String, String> sectionTitles = {
    'summary': 'الملخص التنفيذي',
    'trips': 'تحليل الرحلات',
    'performance': 'مؤشرات الأداء',
    'safety': 'تحليل السلامة',
    'recommendations': 'التوصيات',
    'metrics': 'المقاييس الرئيسية',
    'trends': 'الاتجاهات والأنماط',
    'alerts': 'التنبيهات والتحذيرات',
    'optimizations': 'التحسينات المقترحة',
    'insights': 'الرؤى التحليلية',
    'overview': 'نظرة عامة',
    'detailed_analysis': 'التحليل التفصيلي',
    'comparisons': 'المقارنات الزمنية',
    'predictions': 'التوقعات والتنبؤات',
    'actionable_insights': 'الرؤى القابلة للتنفيذ',
    'consumption_analysis': 'تحليل الاستهلاك',
    'efficiency_trends': 'اتجاهات الكفاءة',
    'cost_analysis': 'تحليل التكاليف',
    'eco_recommendations': 'التوصيات البيئية',
    'safety_score': 'نقاط السلامة',
    'incident_analysis': 'تحليل الحوادث',
    'behavior_patterns': 'أنماط السلوك',
    'improvement_suggestions': 'اقتراحات التحسين',
  };

  static const Map<String, String> metricUnits = {
    'distance': 'كم',
    'time': 'دقيقة',
    'speed': 'كم/ساعة',
    'fuel': 'لتر',
    'emissions': 'كجم CO2',
    'score': 'نقطة',
    'percentage': '%',
    'count': 'عدد',
  };
}