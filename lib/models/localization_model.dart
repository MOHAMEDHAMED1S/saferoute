import 'package:flutter/material.dart';

/// نموذج بيانات دعم اللغات المتعددة
class LocalizationModel {
  final String languageCode;
  final String countryCode;
  final String displayName;
  final String nativeName;
  final bool isRTL;
  final bool isSupported;
  final String flagEmoji;
  final Map<String, String> translations;
  final DateTime lastUpdated;
  
  const LocalizationModel({
    required this.languageCode,
    required this.countryCode,
    required this.displayName,
    required this.nativeName,
    required this.isRTL,
    required this.isSupported,
    required this.flagEmoji,
    required this.translations,
    required this.lastUpdated,
  });
  
  /// إنشاء Locale من البيانات
  Locale get locale => Locale(languageCode, countryCode);
  
  /// الحصول على اسم اللغة المحلي
  String get localizedName => nativeName;
  
  /// التحقق من دعم اللغة
  bool get isFullySupported => isSupported && translations.isNotEmpty;
  
  /// نسخ مع تعديل
  LocalizationModel copyWith({
    String? languageCode,
    String? countryCode,
    String? displayName,
    String? nativeName,
    bool? isRTL,
    bool? isSupported,
    String? flagEmoji,
    Map<String, String>? translations,
    DateTime? lastUpdated,
  }) {
    return LocalizationModel(
      languageCode: languageCode ?? this.languageCode,
      countryCode: countryCode ?? this.countryCode,
      displayName: displayName ?? this.displayName,
      nativeName: nativeName ?? this.nativeName,
      isRTL: isRTL ?? this.isRTL,
      isSupported: isSupported ?? this.isSupported,
      flagEmoji: flagEmoji ?? this.flagEmoji,
      translations: translations ?? this.translations,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'languageCode': languageCode,
      'countryCode': countryCode,
      'displayName': displayName,
      'nativeName': nativeName,
      'isRTL': isRTL,
      'isSupported': isSupported,
      'flagEmoji': flagEmoji,
      'translations': translations,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  /// إنشاء من JSON
  factory LocalizationModel.fromJson(Map<String, dynamic> json) {
    return LocalizationModel(
      languageCode: json['languageCode'] ?? '',
      countryCode: json['countryCode'] ?? '',
      displayName: json['displayName'] ?? '',
      nativeName: json['nativeName'] ?? '',
      isRTL: json['isRTL'] ?? false,
      isSupported: json['isSupported'] ?? false,
      flagEmoji: json['flagEmoji'] ?? '',
      translations: Map<String, String>.from(json['translations'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalizationModel &&
        other.languageCode == languageCode &&
        other.countryCode == countryCode;
  }
  
  @override
  int get hashCode => languageCode.hashCode ^ countryCode.hashCode;
  
  @override
  String toString() {
    return 'LocalizationModel(languageCode: $languageCode, countryCode: $countryCode, displayName: $displayName)';
  }
}

/// نموذج بيانات الترجمة
class TranslationModel {
  final String key;
  final Map<String, String> translations;
  final String category;
  final String description;
  final bool isPlural;
  final Map<String, String>? pluralForms;
  final DateTime lastUpdated;
  
  const TranslationModel({
    required this.key,
    required this.translations,
    required this.category,
    required this.description,
    this.isPlural = false,
    this.pluralForms,
    required this.lastUpdated,
  });
  
  /// الحصول على الترجمة للغة محددة
  String getTranslation(String languageCode, {int? count}) {
    if (isPlural && count != null && pluralForms != null) {
      final pluralKey = _getPluralKey(languageCode, count);
      return pluralForms![pluralKey] ?? translations[languageCode] ?? key;
    }
    
    return translations[languageCode] ?? key;
  }
  
  /// تحديد مفتاح الجمع
  String _getPluralKey(String languageCode, int count) {
    // قواعد الجمع للعربية
    if (languageCode == 'ar') {
      if (count == 0) return 'zero';
      if (count == 1) return 'one';
      if (count == 2) return 'two';
      if (count >= 3 && count <= 10) return 'few';
      if (count >= 11 && count <= 99) return 'many';
      return 'other';
    }
    
    // قواعد الجمع للإنجليزية
    if (languageCode == 'en') {
      return count == 1 ? 'one' : 'other';
    }
    
    return 'other';
  }
  
  /// نسخ مع تعديل
  TranslationModel copyWith({
    String? key,
    Map<String, String>? translations,
    String? category,
    String? description,
    bool? isPlural,
    Map<String, String>? pluralForms,
    DateTime? lastUpdated,
  }) {
    return TranslationModel(
      key: key ?? this.key,
      translations: translations ?? this.translations,
      category: category ?? this.category,
      description: description ?? this.description,
      isPlural: isPlural ?? this.isPlural,
      pluralForms: pluralForms ?? this.pluralForms,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'translations': translations,
      'category': category,
      'description': description,
      'isPlural': isPlural,
      'pluralForms': pluralForms,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  /// إنشاء من JSON
  factory TranslationModel.fromJson(Map<String, dynamic> json) {
    return TranslationModel(
      key: json['key'] ?? '',
      translations: Map<String, String>.from(json['translations'] ?? {}),
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      isPlural: json['isPlural'] ?? false,
      pluralForms: json['pluralForms'] != null 
          ? Map<String, String>.from(json['pluralForms']) 
          : null,
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// نموذج بيانات إعدادات التوطين
class LocalizationSettings {
  final String currentLanguageCode;
  final String currentCountryCode;
  final bool autoDetectLanguage;
  final bool fallbackToEnglish;
  final bool downloadTranslationsOffline;
  final List<String> preferredLanguages;
  final Map<String, dynamic> customSettings;
  final DateTime lastUpdated;
  
  const LocalizationSettings({
    required this.currentLanguageCode,
    required this.currentCountryCode,
    this.autoDetectLanguage = true,
    this.fallbackToEnglish = true,
    this.downloadTranslationsOffline = false,
    this.preferredLanguages = const [],
    this.customSettings = const {},
    required this.lastUpdated,
  });
  
  /// الحصول على Locale الحالي
  Locale get currentLocale => Locale(currentLanguageCode, currentCountryCode);
  
  /// نسخ مع تعديل
  LocalizationSettings copyWith({
    String? currentLanguageCode,
    String? currentCountryCode,
    bool? autoDetectLanguage,
    bool? fallbackToEnglish,
    bool? downloadTranslationsOffline,
    List<String>? preferredLanguages,
    Map<String, dynamic>? customSettings,
    DateTime? lastUpdated,
  }) {
    return LocalizationSettings(
      currentLanguageCode: currentLanguageCode ?? this.currentLanguageCode,
      currentCountryCode: currentCountryCode ?? this.currentCountryCode,
      autoDetectLanguage: autoDetectLanguage ?? this.autoDetectLanguage,
      fallbackToEnglish: fallbackToEnglish ?? this.fallbackToEnglish,
      downloadTranslationsOffline: downloadTranslationsOffline ?? this.downloadTranslationsOffline,
      preferredLanguages: preferredLanguages ?? this.preferredLanguages,
      customSettings: customSettings ?? this.customSettings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'currentLanguageCode': currentLanguageCode,
      'currentCountryCode': currentCountryCode,
      'autoDetectLanguage': autoDetectLanguage,
      'fallbackToEnglish': fallbackToEnglish,
      'downloadTranslationsOffline': downloadTranslationsOffline,
      'preferredLanguages': preferredLanguages,
      'customSettings': customSettings,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  /// إنشاء من JSON
  factory LocalizationSettings.fromJson(Map<String, dynamic> json) {
    return LocalizationSettings(
      currentLanguageCode: json['currentLanguageCode'] ?? 'ar',
      currentCountryCode: json['currentCountryCode'] ?? 'SA',
      autoDetectLanguage: json['autoDetectLanguage'] ?? true,
      fallbackToEnglish: json['fallbackToEnglish'] ?? true,
      downloadTranslationsOffline: json['downloadTranslationsOffline'] ?? false,
      preferredLanguages: List<String>.from(json['preferredLanguages'] ?? []),
      customSettings: Map<String, dynamic>.from(json['customSettings'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// تعداد اتجاه النص
enum TextDirection {
  ltr,
  rtl,
}

/// تعداد حالة التحميل
enum TranslationLoadingState {
  idle,
  loading,
  loaded,
  error,
}

/// نموذج بيانات حالة التوطين
class LocalizationState {
  final LocalizationSettings settings;
  final List<LocalizationModel> availableLanguages;
  final Map<String, TranslationModel> translations;
  final TranslationLoadingState loadingState;
  final String? errorMessage;
  final double downloadProgress;
  
  const LocalizationState({
    required this.settings,
    this.availableLanguages = const [],
    this.translations = const {},
    this.loadingState = TranslationLoadingState.idle,
    this.errorMessage,
    this.downloadProgress = 0.0,
  });
  
  /// الحصول على اللغة الحالية
  LocalizationModel? get currentLanguage {
    try {
      return availableLanguages.firstWhere(
        (lang) => lang.languageCode == settings.currentLanguageCode &&
                   lang.countryCode == settings.currentCountryCode,
      );
    } catch (e) {
      return availableLanguages.isNotEmpty ? availableLanguages.first : null;
    }
  }
  
  /// التحقق من حالة التحميل
  bool get isLoading => loadingState == TranslationLoadingState.loading;
  bool get hasError => loadingState == TranslationLoadingState.error;
  bool get isLoaded => loadingState == TranslationLoadingState.loaded;
  
  /// نسخ مع تعديل
  LocalizationState copyWith({
    LocalizationSettings? settings,
    List<LocalizationModel>? availableLanguages,
    Map<String, TranslationModel>? translations,
    TranslationLoadingState? loadingState,
    String? errorMessage,
    double? downloadProgress,
  }) {
    return LocalizationState(
      settings: settings ?? this.settings,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      translations: translations ?? this.translations,
      loadingState: loadingState ?? this.loadingState,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}

/// امتدادات مساعدة للتوطين
extension LocalizationExtensions on String {
  /// ترجمة النص
  String tr(Map<String, TranslationModel> translations, String languageCode) {
    final translation = translations[this];
    return translation?.getTranslation(languageCode) ?? this;
  }
  
  /// ترجمة النص مع الجمع
  String trPlural(Map<String, TranslationModel> translations, String languageCode, int count) {
    final translation = translations[this];
    return translation?.getTranslation(languageCode, count: count) ?? this;
  }
}

/// ثوابت التوطين
class LocalizationConstants {
  static const String defaultLanguageCode = 'ar';
  static const String defaultCountryCode = 'SA';
  static const String fallbackLanguageCode = 'en';
  static const String fallbackCountryCode = 'US';
  
  static const List<String> supportedLanguageCodes = [
    'ar', // العربية
    'en', // English
    'fr', // Français
    'es', // Español
    'de', // Deutsch
    'it', // Italiano
    'ru', // Русский
    'zh', // 中文
    'ja', // 日本語
    'ko', // 한국어
  ];
  
  static const Map<String, String> languageNames = {
    'ar': 'العربية',
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'de': 'Deutsch',
    'it': 'Italiano',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
  };
  
  static const Map<String, String> countryFlags = {
    'SA': '🇸🇦',
    'US': '🇺🇸',
    'FR': '🇫🇷',
    'ES': '🇪🇸',
    'DE': '🇩🇪',
    'IT': '🇮🇹',
    'RU': '🇷🇺',
    'CN': '🇨🇳',
    'JP': '🇯🇵',
    'KR': '🇰🇷',
  };
  
  static const Map<String, bool> rtlLanguages = {
    'ar': true,
    'he': true,
    'fa': true,
    'ur': true,
  };
}