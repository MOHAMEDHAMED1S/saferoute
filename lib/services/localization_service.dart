import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/localization_model.dart';

/// خدمة التوطين ودعم اللغات المتعددة
class LocalizationService {
  static LocalizationService? _instance;
  static LocalizationService get instance => _instance ??= LocalizationService._();
  
  LocalizationService._();
  
  // Controllers
  final StreamController<LocalizationState> _stateController = 
      StreamController<LocalizationState>.broadcast();
  final StreamController<Locale> _localeController = 
      StreamController<Locale>.broadcast();
  
  // State
  LocalizationState _currentState = LocalizationState(
    settings: LocalizationSettings(
      currentLanguageCode: LocalizationConstants.defaultLanguageCode,
      currentCountryCode: LocalizationConstants.defaultCountryCode,
      lastUpdated: DateTime.now(),
    ),
  );
  
  bool _isInitialized = false;
  SharedPreferences? _prefs;
  
  // Getters
  Stream<LocalizationState> get stateStream => _stateController.stream;
  Stream<Locale> get localeStream => _localeController.stream;
  LocalizationState get currentState => _currentState;
  Locale get currentLocale => _currentState.settings.currentLocale;
  bool get isInitialized => _isInitialized;
  bool get isRTL => _currentState.currentLanguage?.isRTL ?? false;
  
  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _updateState(_currentState.copyWith(
        loadingState: TranslationLoadingState.loading,
      ));
      
      // تحميل الإعدادات المحفوظة
      await _loadSavedSettings();
      
      // تحميل اللغات المتاحة
      await _loadAvailableLanguages();
      
      // تحميل الترجمات
      await _loadTranslations(_currentState.settings.currentLanguageCode);
      
      // اكتشاف اللغة تلقائياً إذا كان مفعلاً
      if (_currentState.settings.autoDetectLanguage) {
        await _autoDetectLanguage();
      }
      
      _updateState(_currentState.copyWith(
        loadingState: TranslationLoadingState.loaded,
      ));
      
      _isInitialized = true;
      
    } catch (e) {
      _updateState(_currentState.copyWith(
        loadingState: TranslationLoadingState.error,
        errorMessage: 'فشل في تهيئة خدمة التوطين: $e',
      ));
    }
  }
  
  /// تحميل الإعدادات المحفوظة
  Future<void> _loadSavedSettings() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    final settingsJson = _prefs!.getString('localization_settings');
    if (settingsJson != null) {
      try {
        final settings = LocalizationSettings.fromJson(
          json.decode(settingsJson),
        );
        
        _updateState(_currentState.copyWith(settings: settings));
      } catch (e) {
        debugPrint('خطأ في تحميل إعدادات التوطين: $e');
      }
    }
  }
  
  /// حفظ الإعدادات
  Future<void> _saveSettings() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    try {
      final settingsJson = json.encode(_currentState.settings.toJson());
      await _prefs!.setString('localization_settings', settingsJson);
    } catch (e) {
      debugPrint('خطأ في حفظ إعدادات التوطين: $e');
    }
  }
  
  /// تحميل اللغات المتاحة
  Future<void> _loadAvailableLanguages() async {
    try {
      final List<LocalizationModel> languages = [];
      
      // إضافة اللغات المدعومة
      for (final languageCode in LocalizationConstants.supportedLanguageCodes) {
        final countryCode = _getDefaultCountryCode(languageCode);
        final language = LocalizationModel(
          languageCode: languageCode,
          countryCode: countryCode,
          displayName: LocalizationConstants.languageNames[languageCode] ?? languageCode,
          nativeName: LocalizationConstants.languageNames[languageCode] ?? languageCode,
          isRTL: LocalizationConstants.rtlLanguages[languageCode] ?? false,
          isSupported: true,
          flagEmoji: LocalizationConstants.countryFlags[countryCode] ?? '🌐',
          translations: {},
          lastUpdated: DateTime.now(),
        );
        
        languages.add(language);
      }
      
      _updateState(_currentState.copyWith(availableLanguages: languages));
      
    } catch (e) {
      throw Exception('فشل في تحميل اللغات المتاحة: $e');
    }
  }
  
  /// الحصول على رمز الدولة الافتراضي للغة
  String _getDefaultCountryCode(String languageCode) {
    switch (languageCode) {
      case 'ar': return 'SA';
      case 'en': return 'US';
      case 'fr': return 'FR';
      case 'es': return 'ES';
      case 'de': return 'DE';
      case 'it': return 'IT';
      case 'ru': return 'RU';
      case 'zh': return 'CN';
      case 'ja': return 'JP';
      case 'ko': return 'KR';
      default: return 'US';
    }
  }
  
  /// تحميل الترجمات
  Future<void> _loadTranslations(String languageCode) async {
    try {
      // محاولة تحميل الترجمات من الملفات المحلية
      final translations = await _loadTranslationsFromAssets(languageCode);
      
      _updateState(_currentState.copyWith(translations: translations));
      
    } catch (e) {
      // في حالة فشل التحميل، استخدم الترجمات الافتراضية
      final defaultTranslations = _getDefaultTranslations(languageCode);
      _updateState(_currentState.copyWith(translations: defaultTranslations));
    }
  }
  
  /// تحميل الترجمات من ملفات الأصول
  Future<Map<String, TranslationModel>> _loadTranslationsFromAssets(String languageCode) async {
    try {
      final String translationsJson = await rootBundle.loadString(
        'assets/translations/$languageCode.json',
      );
      
      final Map<String, dynamic> translationsData = json.decode(translationsJson);
      final Map<String, TranslationModel> translations = {};
      
      for (final entry in translationsData.entries) {
        if (entry.value is Map<String, dynamic>) {
          translations[entry.key] = TranslationModel.fromJson(entry.value);
        } else if (entry.value is String) {
          // ترجمة بسيطة
          translations[entry.key] = TranslationModel(
            key: entry.key,
            translations: {languageCode: entry.value},
            category: 'general',
            description: '',
            lastUpdated: DateTime.now(),
          );
        }
      }
      
      return translations;
      
    } catch (e) {
      throw Exception('فشل في تحميل ترجمات $languageCode: $e');
    }
  }
  
  /// الحصول على الترجمات الافتراضية
  Map<String, TranslationModel> _getDefaultTranslations(String languageCode) {
    final Map<String, Map<String, String>> defaultTranslations = {
      'ar': {
        'app_name': 'سيف روت',
        'welcome': 'مرحباً',
        'home': 'الرئيسية',
        'navigation': 'الملاحة',
        'reports': 'التقارير',
        'settings': 'الإعدادات',
        'profile': 'الملف الشخصي',
        'analytics': 'التحليلات',
        'community': 'المجتمع',
        'driving_mode': 'وضع القيادة',
        'start_navigation': 'بدء الملاحة',
        'stop_navigation': 'إيقاف الملاحة',
        'current_location': 'الموقع الحالي',
        'destination': 'الوجهة',
        'route': 'المسار',
        'distance': 'المسافة',
        'duration': 'المدة',
        'speed': 'السرعة',
        'safety_alerts': 'تنبيهات الأمان',
        'weather': 'الطقس',
        'traffic': 'حركة المرور',
        'save': 'حفظ',
        'cancel': 'إلغاء',
        'ok': 'موافق',
        'error': 'خطأ',
        'loading': 'جاري التحميل...',
        'retry': 'إعادة المحاولة',
      },
      'en': {
        'app_name': 'SafeRoute',
        'welcome': 'Welcome',
        'home': 'Home',
        'navigation': 'Navigation',
        'reports': 'Reports',
        'settings': 'Settings',
        'profile': 'Profile',
        'analytics': 'Analytics',
        'community': 'Community',
        'driving_mode': 'Driving Mode',
        'start_navigation': 'Start Navigation',
        'stop_navigation': 'Stop Navigation',
        'current_location': 'Current Location',
        'destination': 'Destination',
        'route': 'Route',
        'distance': 'Distance',
        'duration': 'Duration',
        'speed': 'Speed',
        'safety_alerts': 'Safety Alerts',
        'weather': 'Weather',
        'traffic': 'Traffic',
        'save': 'Save',
        'cancel': 'Cancel',
        'ok': 'OK',
        'error': 'Error',
        'loading': 'Loading...',
        'retry': 'Retry',
      },
    };
    
    final translations = defaultTranslations[languageCode] ?? defaultTranslations['en']!;
    final Map<String, TranslationModel> result = {};
    
    for (final entry in translations.entries) {
      result[entry.key] = TranslationModel(
        key: entry.key,
        translations: {languageCode: entry.value},
        category: 'default',
        description: 'Default translation',
        lastUpdated: DateTime.now(),
      );
    }
    
    return result;
  }
  
  /// اكتشاف اللغة تلقائياً
  Future<void> _autoDetectLanguage() async {
    try {
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final detectedLanguageCode = deviceLocale.languageCode;
      final detectedCountryCode = deviceLocale.countryCode ?? 
          _getDefaultCountryCode(detectedLanguageCode);
      
      // التحقق من دعم اللغة المكتشفة
      final isSupported = LocalizationConstants.supportedLanguageCodes
          .contains(detectedLanguageCode);
      
      if (isSupported) {
        await changeLanguage(detectedLanguageCode, detectedCountryCode);
      }
      
    } catch (e) {
      debugPrint('خطأ في اكتشاف اللغة تلقائياً: $e');
    }
  }
  
  /// تغيير اللغة
  Future<void> changeLanguage(String languageCode, [String? countryCode]) async {
    try {
      final newCountryCode = countryCode ?? _getDefaultCountryCode(languageCode);
      
      // التحقق من دعم اللغة
      if (!LocalizationConstants.supportedLanguageCodes.contains(languageCode)) {
        throw Exception('اللغة $languageCode غير مدعومة');
      }
      
      _updateState(_currentState.copyWith(
        loadingState: TranslationLoadingState.loading,
      ));
      
      // تحديث الإعدادات
      final newSettings = _currentState.settings.copyWith(
        currentLanguageCode: languageCode,
        currentCountryCode: newCountryCode,
        lastUpdated: DateTime.now(),
      );
      
      _updateState(_currentState.copyWith(settings: newSettings));
      
      // تحميل الترجمات الجديدة
      await _loadTranslations(languageCode);
      
      // حفظ الإعدادات
      await _saveSettings();
      
      _updateState(_currentState.copyWith(
        loadingState: TranslationLoadingState.loaded,
      ));
      
      // إشعار بتغيير اللغة
      _localeController.add(Locale(languageCode, newCountryCode));
      
    } catch (e) {
      _updateState(_currentState.copyWith(
        loadingState: TranslationLoadingState.error,
        errorMessage: 'فشل في تغيير اللغة: $e',
      ));
    }
  }
  
  /// الحصول على ترجمة
  String translate(String key, {Map<String, String>? params}) {
    final translation = _currentState.translations[key];
    if (translation == null) {
      // محاولة الرجوع للإنجليزية
      if (_currentState.settings.fallbackToEnglish && 
          _currentState.settings.currentLanguageCode != 'en') {
        return _translateWithFallback(key, params);
      }
      return key;
    }
    
    String result = translation.getTranslation(
      _currentState.settings.currentLanguageCode,
    );
    
    // استبدال المعاملات
    if (params != null) {
      for (final entry in params.entries) {
        result = result.replaceAll('{${entry.key}}', entry.value);
      }
    }
    
    return result;
  }
  
  /// الحصول على ترجمة مع الجمع
  String translatePlural(String key, int count, {Map<String, String>? params}) {
    final translation = _currentState.translations[key];
    if (translation == null) {
      if (_currentState.settings.fallbackToEnglish && 
          _currentState.settings.currentLanguageCode != 'en') {
        return _translatePluralWithFallback(key, count, params);
      }
      return key;
    }
    
    String result = translation.getTranslation(
      _currentState.settings.currentLanguageCode,
      count: count,
    );
    
    // استبدال المعاملات
    if (params != null) {
      for (final entry in params.entries) {
        result = result.replaceAll('{${entry.key}}', entry.value);
      }
    }
    
    // استبدال عدد العناصر
    result = result.replaceAll('{count}', count.toString());
    
    return result;
  }
  
  /// ترجمة مع الرجوع للإنجليزية
  String _translateWithFallback(String key, Map<String, String>? params) {
    // محاولة البحث في الترجمات الإنجليزية
    final translation = _currentState.translations[key];
    if (translation != null) {
      String result = translation.getTranslation('en');
      
      if (params != null) {
        for (final entry in params.entries) {
          result = result.replaceAll('{${entry.key}}', entry.value);
        }
      }
      
      return result;
    }
    
    return key;
  }
  
  /// ترجمة الجمع مع الرجوع للإنجليزية
  String _translatePluralWithFallback(String key, int count, Map<String, String>? params) {
    final translation = _currentState.translations[key];
    if (translation != null) {
      String result = translation.getTranslation('en', count: count);
      
      if (params != null) {
        for (final entry in params.entries) {
          result = result.replaceAll('{${entry.key}}', entry.value);
        }
      }
      
      result = result.replaceAll('{count}', count.toString());
      return result;
    }
    
    return key;
  }
  
  /// تحديث إعدادات التوطين
  Future<void> updateSettings(LocalizationSettings newSettings) async {
    try {
      _updateState(_currentState.copyWith(settings: newSettings));
      await _saveSettings();
      
      // إعادة تحميل الترجمات إذا تغيرت اللغة
      if (newSettings.currentLanguageCode != _currentState.settings.currentLanguageCode) {
        await _loadTranslations(newSettings.currentLanguageCode);
        _localeController.add(newSettings.currentLocale);
      }
      
    } catch (e) {
      _updateState(_currentState.copyWith(
        loadingState: TranslationLoadingState.error,
        errorMessage: 'فشل في تحديث الإعدادات: $e',
      ));
    }
  }
  
  /// تحميل ترجمات إضافية
  Future<void> downloadTranslations(String languageCode) async {
    try {
      _updateState(_currentState.copyWith(
        loadingState: TranslationLoadingState.loading,
        downloadProgress: 0.0,
      ));
      
      // محاكاة تحميل الترجمات
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        _updateState(_currentState.copyWith(downloadProgress: i / 100));
      }
      
      // تحميل الترجمات
      await _loadTranslations(languageCode);
      
      _updateState(_currentState.copyWith(
        loadingState: TranslationLoadingState.loaded,
        downloadProgress: 1.0,
      ));
      
    } catch (e) {
      _updateState(_currentState.copyWith(
        loadingState: TranslationLoadingState.error,
        errorMessage: 'فشل في تحميل الترجمات: $e',
      ));
    }
  }
  
  /// الحصول على اللغات المتاحة
  List<LocalizationModel> getAvailableLanguages() {
    return _currentState.availableLanguages;
  }
  
  /// التحقق من دعم اللغة
  bool isLanguageSupported(String languageCode) {
    return LocalizationConstants.supportedLanguageCodes.contains(languageCode);
  }
  
  /// الحصول على اتجاه النص
  TextDirection getTextDirection() {
    return isRTL ? TextDirection.rtl : TextDirection.ltr;
  }
  
  /// تحديث الحالة
  void _updateState(LocalizationState newState) {
    _currentState = newState;
    _stateController.add(_currentState);
  }
  
  /// تنظيف الموارد
  void dispose() {
    _stateController.close();
    _localeController.close();
  }
}

/// امتدادات مساعدة للترجمة
extension LocalizationExtension on String {
  /// ترجمة النص
  String get tr {
    return LocalizationService.instance.translate(this);
  }
  
  /// ترجمة النص مع معاملات
  String trParams(Map<String, String> params) {
    return LocalizationService.instance.translate(this, params: params);
  }
  
  /// ترجمة النص مع الجمع
  String trPlural(int count) {
    return LocalizationService.instance.translatePlural(this, count);
  }
  
  /// ترجمة النص مع الجمع ومعاملات
  String trPluralParams(int count, Map<String, String> params) {
    return LocalizationService.instance.translatePlural(this, count, params: params);
  }
}