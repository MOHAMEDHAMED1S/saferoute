import 'package:flutter/material.dart';

/// تصميم Liquid Glass المستوحى من iOS 26
class LiquidGlassTheme {
  // الألوان الأساسية
  static const Color primaryGlass = Color(0x40FFFFFF); // 25% opacity
  static const Color secondaryGlass = Color(0xB3FFFFFF); // 70% opacity
  static const Color toolbarGlass = Color(0x26FFFFFF); // 15% opacity
  static const Color ultraLightGlass = Color(0x14FFFFFF); // 8% opacity
  
  // الألوان للوضع المظلم
  static const Color darkPrimaryGlass = Color(0x40000000); // 25% opacity
  static const Color darkSecondaryGlass = Color(0x26101010); // 15% opacity
  static const Color darkUltraLightGlass = Color(0x1A080808); // 10% opacity
  
  // الحدود والخطوط
  static const Color borderLight = Color(0x2EFFFFFF); // 18% opacity
  static const Color borderDark = Color(0x1AFFFFFF); // 10% opacity
  
  // تدرجات الألوان
  static const LinearGradient highlightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x40FFFFFF), // 25% opacity
      Color(0x1AFFFFFF), // 10% opacity
    ],
  );
  
  static const LinearGradient borderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x4DFFFFFF), // 30% opacity
      Color(0x1AFFFFFF), // 10% opacity
      Color(0x4DFFFFFF), // 30% opacity
    ],
  );
  
  // الظلال
  static const List<BoxShadow> glassBoxShadow = [
    BoxShadow(
      color: Color(0x4D1F2687), // rgba(31, 38, 135, 0.3)
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];
  
  static const List<BoxShadow> interactiveBoxShadow = [
    BoxShadow(
      color: Color(0x401F2687), // rgba(31, 38, 135, 0.25)
      blurRadius: 40,
      offset: Offset(0, 12),
    ),
  ];
  
  // أنماط الحاويات
  static BoxDecoration get primaryGlassDecoration => BoxDecoration(
    gradient: highlightGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: borderLight,
      width: 1,
    ),
    boxShadow: glassBoxShadow,
  );
  
  static BoxDecoration get secondaryGlassDecoration => BoxDecoration(
    color: secondaryGlass,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: const Color(0x40FFFFFF), // 25% opacity
      width: 1,
    ),
  );
  
  static BoxDecoration get toolbarGlassDecoration => BoxDecoration(
    color: toolbarGlass,
    borderRadius: BorderRadius.circular(32),
    border: Border.all(
      color: const Color(0xCCFFFFFF), // 80% opacity
      width: 1,
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x331F2687), // rgba(31, 38, 135, 0.2)
        blurRadius: 32,
        offset: Offset(0, 8),
      ),
    ],
  );
  
  static BoxDecoration get ultraLightGlassDecoration => BoxDecoration(
    color: ultraLightGlass,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: const Color(0x1FFFFFFF), // 12% opacity
      width: 0.5,
    ),
  );
  
  // أنماط الوضع المظلم
  static BoxDecoration get darkPrimaryGlassDecoration => BoxDecoration(
    color: darkPrimaryGlass,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: const Color(0x1AFFFFFF), // 10% opacity
      width: 1,
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x4D000000), // rgba(0, 0, 0, 0.3)
        blurRadius: 32,
        offset: Offset(0, 8),
      ),
    ],
  );
  
  static BoxDecoration get darkSecondaryGlassDecoration => BoxDecoration(
    color: darkSecondaryGlass,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: const Color(0x14FFFFFF), // 8% opacity
      width: 0.5,
    ),
  );
  
  // أنماط النصوص
  static const TextStyle primaryTextStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );
  
  static const TextStyle secondaryTextStyle = TextStyle(
    color: Color(0xE6FFFFFF), // 90% opacity
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );
  
  static const TextStyle captionTextStyle = TextStyle(
    color: Color(0xB3FFFFFF), // 70% opacity
    fontWeight: FontWeight.w400,
    fontSize: 12,
  );
  
  // أنماط الأزرار
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );
  
  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: const Color(0xE6FFFFFF),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  );
  
  // تأثيرات التفاعل
  static BoxDecoration getInteractiveDecoration(bool isHovered) {
    return BoxDecoration(
      color: isHovered ? const Color(0x2EFFFFFF) : toolbarGlass, // 18% vs 15%
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isHovered ? const Color(0x40FFFFFF) : borderLight,
        width: 1,
      ),
      boxShadow: isHovered ? interactiveBoxShadow : glassBoxShadow,
    );
  }
  
  // تحويل للوضع المظلم
  static bool _isDarkMode = false;
  
  static bool get isDarkMode => _isDarkMode;
  
  static void setDarkMode(bool value) {
    _isDarkMode = value;
  }
  
  static BoxDecoration get adaptiveDecoration {
    return _isDarkMode ? darkPrimaryGlassDecoration : primaryGlassDecoration;
  }
  
  static Color get adaptiveTextColor {
    return _isDarkMode ? const Color(0xE6FFFFFF) : Colors.white;
  }
  
  // لون الخلفية الأساسي
  static Color get backgroundColor {
    return _isDarkMode ? const Color(0xFF0A0E27) : const Color(0xFF0A0E27);
  }
}