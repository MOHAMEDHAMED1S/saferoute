import 'package:flutter/material.dart';
import 'dart:async';
import '../services/localization_service.dart';
import '../models/localization_model.dart';
import 'glass_container.dart';
import 'animated_button.dart';

class LanguageSettingsWidget extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onToggle;
  final bool showAdvancedOptions;
  
  const LanguageSettingsWidget({
    super.key,
    this.isExpanded = false,
    this.onToggle,
    this.showAdvancedOptions = false,
  });

  @override
  State<LanguageSettingsWidget> createState() => _LanguageSettingsWidgetState();
}

class _LanguageSettingsWidgetState extends State<LanguageSettingsWidget>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _fadeController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;
  
  final LocalizationService _localizationService = LocalizationService.instance;
  
  // Subscriptions
  StreamSubscription<LocalizationState>? _stateSubscription;
  
  // State
  LocalizationState? _currentState;
  bool _isChangingLanguage = false;
  String? _selectedLanguageCode;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLocalizationService();
    _subscribeToLocalizationState();
  }
  
  void _initializeAnimations() {
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    if (widget.isExpanded) {
      _expandController.forward();
    }
    
    _fadeController.forward();
  }
  
  void _initializeLocalizationService() async {
    if (!_localizationService.isInitialized) {
      await _localizationService.initialize();
    }
  }
  
  void _subscribeToLocalizationState() {
    _stateSubscription = _localizationService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
          _isChangingLanguage = state.isLoading;
        });
      }
    });
    
    // الحصول على الحالة الحالية
    setState(() {
      _currentState = _localizationService.currentState;
      _selectedLanguageCode = _currentState?.settings.currentLanguageCode;
    });
  }
  
  @override
  void didUpdateWidget(LanguageSettingsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _expandController.dispose();
    _fadeController.dispose();
    _stateSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GlassContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: _buildExpandedContent(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    final currentLanguage = _currentState?.currentLanguage;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Language icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.language,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Title and current language
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اللغة والتوطين',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (currentLanguage != null)
                  Row(
                    children: [
                      Text(
                        currentLanguage.flagEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentLanguage.nativeName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Loading indicator
          if (_isChangingLanguage)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          
          // Expand/collapse button
          if (widget.onToggle != null) ...[
            const SizedBox(width: 8),
            AnimatedButton(
              onPressed: widget.onToggle!,
              text: '',
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildExpandedContent() {
    if (_currentState == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          
          _buildLanguageSelection(),
          const SizedBox(height: 16),
          
          if (widget.showAdvancedOptions) ...[
            _buildAdvancedSettings(),
            const SizedBox(height: 16),
          ],
          
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildLanguageSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختيار اللغة',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Language grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _currentState!.availableLanguages.length,
          itemBuilder: (context, index) {
            final language = _currentState!.availableLanguages[index];
            return _buildLanguageCard(language);
          },
        ),
      ],
    );
  }
  
  Widget _buildLanguageCard(LocalizationModel language) {
    final isSelected = language.languageCode == _currentState!.settings.currentLanguageCode;
    final isChanging = _isChangingLanguage && _selectedLanguageCode == language.languageCode;
    
    return AnimatedButton(
      onPressed: isChanging ? null : () => _changeLanguage(language),
      text: '',

    );
  }
  
  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإعدادات المتقدمة',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Auto detect language
        _buildSettingSwitch(
          'اكتشاف اللغة تلقائياً',
          'استخدام لغة النظام عند بدء التطبيق',
          _currentState!.settings.autoDetectLanguage,
          (value) => _updateSetting('autoDetectLanguage', value),
          Icons.auto_awesome,
        ),
        
        const SizedBox(height: 8),
        
        // Fallback to English
        _buildSettingSwitch(
          'الرجوع للإنجليزية',
          'استخدام الإنجليزية عند عدم توفر الترجمة',
          _currentState!.settings.fallbackToEnglish,
          (value) => _updateSetting('fallbackToEnglish', value),
          Icons.translate,
        ),
        
        const SizedBox(height: 8),
        
        // Download offline translations
        _buildSettingSwitch(
          'تحميل الترجمات للاستخدام دون اتصال',
          'حفظ الترجمات محلياً للوصول السريع',
          _currentState!.settings.downloadTranslationsOffline,
          (value) => _updateSetting('downloadTranslationsOffline', value),
          Icons.download,
        ),
      ],
    );
  }
  
  Widget _buildSettingSwitch(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.blue,
            inactiveThumbColor: Colors.white60,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AnimatedButton(
            onPressed: _downloadCurrentLanguage,
            text: 'تحميل',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedButton(
            onPressed: _resetToDefault,
            text: 'إعادة تعيين',

          ),
        ),
      ],
    );
  }
  
  void _changeLanguage(LocalizationModel language) async {
    if (_isChangingLanguage) return;
    
    setState(() {
      _selectedLanguageCode = language.languageCode;
    });
    
    try {
      await _localizationService.changeLanguage(
        language.languageCode,
        language.countryCode,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تغيير اللغة إلى ${language.nativeName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تغيير اللغة: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _selectedLanguageCode = null;
      });
    }
  }
  
  void _updateSetting(String setting, bool value) async {
    try {
      LocalizationSettings newSettings;
      
      switch (setting) {
        case 'autoDetectLanguage':
          newSettings = _currentState!.settings.copyWith(autoDetectLanguage: value);
          break;
        case 'fallbackToEnglish':
          newSettings = _currentState!.settings.copyWith(fallbackToEnglish: value);
          break;
        case 'downloadTranslationsOffline':
          newSettings = _currentState!.settings.copyWith(downloadTranslationsOffline: value);
          break;
        default:
          return;
      }
      
      await _localizationService.updateSettings(newSettings);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الإعدادات: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  void _downloadCurrentLanguage() async {
    try {
      await _localizationService.downloadTranslations(
        _currentState!.settings.currentLanguageCode,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحميل الترجمات بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الترجمات: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  void _resetToDefault() async {
    try {
      await _localizationService.changeLanguage(
        LocalizationConstants.defaultLanguageCode,
        LocalizationConstants.defaultCountryCode,
      );
      
      final defaultSettings = LocalizationSettings(
        currentLanguageCode: LocalizationConstants.defaultLanguageCode,
        currentCountryCode: LocalizationConstants.defaultCountryCode,
        lastUpdated: DateTime.now(),
      );
      
      await _localizationService.updateSettings(defaultSettings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعادة تعيين إعدادات اللغة'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إعادة التعيين: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}