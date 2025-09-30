import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مستويات التسجيل المختلفة
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// خدمة التسجيل المتقدمة
class LoggingService {
  static LoggingService? _instance;
  static LoggingService get instance => _instance ??= LoggingService._();
  
  LoggingService._();
  
  late SharedPreferences _prefs;
  final List<LogEntry> _logs = [];
  final int _maxLogs = 1000; // الحد الأقصى للسجلات المحفوظة
  
  /// تهيئة خدمة التسجيل
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadStoredLogs();
  }
  
  /// تسجيل رسالة تصحيح
  void logDebug(String message, [dynamic error]) {
    _log(LogLevel.debug, message, error);
  }
  
  /// تسجيل رسالة معلومات
  void logInfo(String message, [dynamic error]) {
    _log(LogLevel.info, message, error);
  }
  
  /// تسجيل رسالة تحذير
  void logWarning(String message, [dynamic error]) {
    _log(LogLevel.warning, message, error);
  }
  
  /// تسجيل رسالة خطأ
  void logError(String message, [dynamic error]) {
    _log(LogLevel.error, message, error);
  }
  
  /// تسجيل رسالة خطأ حرج
  void logCritical(String message, [dynamic error]) {
    _log(LogLevel.critical, message, error);
  }
  
  /// تسجيل رسالة مع مستوى محدد
  void _log(LogLevel level, String message, [dynamic error]) {
    final entry = LogEntry(
      level: level,
      message: message,
      error: error?.toString(),
      timestamp: DateTime.now(),
    );
    
    _logs.add(entry);
    
    // طباعة في وضع التطوير
    if (level == LogLevel.error || level == LogLevel.critical) {
      print('[${level.name.toUpperCase()}] $message${error != null ? ' - Error: $error' : ''}');
    }
    
    // حفظ السجلات إذا تجاوزت الحد الأقصى
    if (_logs.length > _maxLogs) {
      _logs.removeRange(0, _logs.length - _maxLogs);
    }
    
    _saveLogsToStorage();
  }
  
  /// حفظ السجلات في التخزين المحلي
  Future<void> _saveLogsToStorage() async {
    try {
      final logsJson = _logs.map((log) => log.toJson()).toList();
      await _prefs.setString('app_logs', jsonEncode(logsJson));
    } catch (e) {
      print('خطأ في حفظ السجلات: $e');
    }
  }
  
  /// تحميل السجلات من التخزين المحلي
  Future<void> _loadStoredLogs() async {
    try {
      final logsString = _prefs.getString('app_logs');
      if (logsString != null) {
        final logsJson = jsonDecode(logsString) as List;
        _logs.clear();
        _logs.addAll(logsJson.map((json) => LogEntry.fromJson(json)));
      }
    } catch (e) {
      print('خطأ في تحميل السجلات: $e');
    }
  }
  
  /// الحصول على جميع السجلات
  List<LogEntry> getAllLogs() => List.unmodifiable(_logs);
  
  /// الحصول على السجلات حسب المستوى
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }
  
  /// تصدير السجلات إلى ملف
  Future<String?> exportLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/app_logs_${DateTime.now().millisecondsSinceEpoch}.txt');
      
      final buffer = StringBuffer();
      for (final log in _logs) {
        buffer.writeln('${log.timestamp.toIso8601String()} [${log.level.name.toUpperCase()}] ${log.message}');
        if (log.error != null) {
          buffer.writeln('  Error: ${log.error}');
        }
        buffer.writeln();
      }
      
      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      logError('خطأ في تصدير السجلات', e);
      return null;
    }
  }
  
  /// مسح جميع السجلات
  Future<void> clearLogs() async {
    _logs.clear();
    await _prefs.remove('app_logs');
  }
}

/// نموذج إدخال السجل
class LogEntry {
  final LogLevel level;
  final String message;
  final String? error;
  final DateTime timestamp;
  
  LogEntry({
    required this.level,
    required this.message,
    this.error,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'level': level.index,
    'message': message,
    'error': error,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    level: LogLevel.values[json['level']],
    message: json['message'],
    error: json['error'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}