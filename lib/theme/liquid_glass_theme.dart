import 'package:flutter/material.dart';

/// تصميم Liquid Glass المستوحى من iOS 26 - White Background + Glass Elements
class LiquidGlassTheme {
  // الخلفية الرئيسية - أبيض كامل
  static const Color backgroundColor = Color(0xFFFFFFFF);
  
  // الخلفية الرئيسية (لا تستخدم تدرجات)
  static const LinearGradient mainBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
    ],
  );
  
  // ألوان الزجاج - iOS 26 Glass Design
  static const Color primaryGlass = Color(0xF2FFFFFF);      // أبيض شفاف 95% للعناصر الرئيسية
  static const Color secondaryGlass = Color(0xE6FFFFFF);    // أبيض شفاف 90% للعناصر الثانوية
  static const Color toolbarGlass = Color(0xF5FFFFFF);      // أبيض شفاف 96% لشريط التنقل
  static const Color borderLight = Color(0x1AE5E7EB);       // رمادي خفيف 10% للحدود الرئيسية
  static const Color borderSecondary = Color(0x40FFFFFF);   // أبيض شفاف 25% للحدود الثانوية
  static const Color borderNavigation = Color(0x26E5E7EB);  // رمادي خفيف 15% لشريط التنقل
  
  // ألوان الوضع المظلم
  static const Color darkPrimaryGlass = Color(0xE61A1A2E); // rgba(26, 26, 46, 0.9)
  static const Color darkSecondaryGlass = Color(0xCC16213E); // rgba(22, 33, 62, 0.8)
  
  // Header Card (سلامة السائقين)
  static const Color headerCardBackground = Color(0xF2FFFFFF); // rgba(255, 255, 255, 0.95)
  static const Color headerCardBorder = Color(0x1AE5E7EB); // rgba(229, 231, 235, 0.1)
  
  // ألوان البطاقات الملونة - iOS 26 Glass Design
  static const LinearGradient welcomeCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6), // أزرق حيوي
      Color(0xFF06B6D4), // فيروزي حيوي
    ],
  );

  static const LinearGradient headerCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromARGB(99, 59, 131, 246), // أزرق حيوي
      Color.fromARGB(104, 6, 181, 212), // فيروزي حيوي
    ],
  );
  static const Color welcomeCardBorder = Color(0x40FFFFFF); // rgba(255, 255, 255, 0.25)
  
  // إحصائيات البطاقات - iOS 26 Glass Design
  static const LinearGradient reportsCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981),  // أخضر حيوي - بطاقة البلاغات
      Color(0xFF059669),  // أخضر داكن
    ],
  );
  static const Color reportsCardBorder = Color(0x40FFFFFF); // rgba(255, 255, 255, 0.25)
  
  static const LinearGradient trustPointsCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B),  // ذهبي حيوي - بطاقة نقاط الثقة
      Color(0xFFD97706),  // ذهبي داكن
    ],
  );
  static const Color trustPointsCardBorder = Color(0x40FFFFFF); // rgba(255, 255, 255, 0.25)
  
  static const LinearGradient nearbyRisksCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEF4444),  // أحمر حيوي - بطاقة المخاطر القريبة
      Color(0xFFDC2626),  // أحمر داكن
    ],
  );

  // أسماء بديلة للتوافق مع الكود الحالي
  static const LinearGradient statisticsCard1Gradient = reportsCardGradient;
  static const LinearGradient statisticsCard2Gradient = trustPointsCardGradient;
  static const LinearGradient statisticsCard3Gradient = nearbyRisksCardGradient;
  static const Color nearbyRisksCardBorder = Color(0x40FFFFFF); // rgba(255, 255, 255, 0.25)
  
  // Quick Actions Section
  static const Color quickActionsBackground = Color(0xF2FFFFFF); // rgba(255, 255, 255, 0.95)
  static const Color quickActionsBorder = Color(0x1AE5E7EB); // rgba(229, 231, 235, 0.1)
  
  // أزرار الإجراءات السريعة - iOS 26 Glass Design
  static const LinearGradient mapViewActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981),  // أخضر حيوي - عرض الخريطة
      Color(0xFF059669),  // أخضر داكن
    ],
  );
  static const Color mapViewBorder = Color(0x40FFFFFF); // rgba(255, 255, 255, 0.25)
  
  static const LinearGradient quickReportActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEF4444),  // أحمر حيوي - إبلاغ سريع
      Color(0xFFDC2626),  // أحمر داكن
    ],
  );
  static const Color quickReportBorder = Color(0x40FFFFFF); // rgba(255, 255, 255, 0.25)
  
  static const LinearGradient communityActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF06B6D4),  // فيروزي حيوي - المجتمع
      Color(0xFF0891B2),  // فيروزي داكن
    ],
  );
  static const Color communityBorder = Color(0x40FFFFFF); // rgba(255, 255, 255, 0.25)
  
  static const LinearGradient statisticsActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFA855F7),  // وردي حيوي - إحصائياتي
      Color(0xFF9333EA),  // وردي داكن
    ],
  );

  // أسماء بديلة للتوافق مع الكود الحالي
  static const LinearGradient mapViewGradient = mapViewActionGradient;
  static const LinearGradient quickReportGradient = quickReportActionGradient;
  static const LinearGradient communityGradient = communityActionGradient;
  static const LinearGradient myStatsGradient = statisticsActionGradient;
  static const LinearGradient quickAction1Gradient = mapViewActionGradient;
  static const LinearGradient quickAction2Gradient = quickReportActionGradient;
  static const LinearGradient quickAction3Gradient = communityActionGradient;
  static const LinearGradient quickAction4Gradient = statisticsActionGradient;
  static const Color myStatsBorder = Color(0x40FFFFFF); // rgba(255, 255, 255, 0.25)
  
  // Bottom Navigation Bar - iOS 26 Glass Design
  static const Color bottomNavBackground = Color(0xF5FFFFFF);  // أبيض شفاف 96%
  static const Color bottomNavBorder = Color(0x26E5E7EB);      // رمادي خفيف 15%
  static const Color bottomNavInactive = Color(0xFF475569);    // أزرق رمادي متوسط - الأيقونات غير النشطة
  static const Color bottomNavActiveText = Color(0xFFFFFFFF);  // أبيض كامل - النص النشط
  
  // التبويب النشط
  static const LinearGradient bottomNavActiveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6),  // أزرق حيوي - التبويب النشط
      Color(0xFF2563EB),  // أزرق أغمق
    ],
  );
  
  // للتوافق مع الكود الحالي
  static const Color bottomNavActive = Color.fromARGB(97, 59, 131, 246);
  
  // App Icons - iOS 26 Glass Design
  static const Color iconPrimary = Color(0xFF475569);         // أزرق رمادي متوسط - الأيقونات الرئيسية
  static const Color iconSecondary = Color(0xFF64748B);       // أزرق رمادي فاتح - الأيقونات الثانوية
  static const Color iconAccent = Color.fromARGB(144, 59, 131, 246);          // أزرق حيوي - الأيقونات المميزة
  static const Color iconSuccess = Color(0xFF10B981);
  static const Color iconWarning = Color(0xFFF59E0B);
  static const Color iconDanger = Color(0xFFEF4444);
  
  // أيقونات خاصة
  static const LinearGradient settingsIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF475569),  // أزرق رمادي متوسط - أيقونة الإعدادات
      Color(0xFF334155),  // أزرق رمادي داكن
    ],
  );
  
  static const LinearGradient notificationIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF334155),  // أزرق رمادي داكن - أيقونة الإشعارات
      Color(0xFF1E293B),  // أزرق رمادي أغمق
    ],
  );
  
  static const LinearGradient notificationBadgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEF4444),  // أحمر حيوي - شارة الإشعارات
      Color(0xFFDC2626),  // أحمر داكن
    ],
  );
  
  static const LinearGradient protectionIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF64748B),  // أزرق رمادي فاتح - أيقونة الحماية
      Color(0xFF475569),  // أزرق رمادي متوسط
    ],
  );
  
  // اسم بديل للتوافق مع الكود الحالي
  static const LinearGradient shieldIconGradient = protectionIconGradient;
  
  // Text Colors - iOS 26 Glass Design
  // النصوص على الخلفيات البيضاء/الشفافة
  static const Color primaryTextColor = Color(0xFF0F172A);    // أزرق داكن تقريباً - النص الرئيسي
  static const Color secondaryTextColor = Color(0xFF475569);  // أزرق رمادي متوسط - النص الثانوي
  static const Color accentTextColor = Color(0xFF1E293B);     // أزرق رمادي داكن - النص المميز
  static const Color subtitleTextColor = Color(0xFF475569);   // أزرق رمادي متوسط - النصوص الفرعية
  
  // Compatibility aliases for community screen
  static const Color textColor = primaryTextColor;
  static const Color textSecondaryColor = secondaryTextColor;
  static const Color primaryColor = Color(0xFF3B82F6);  // أزرق حيوي
  static const Color accentColor = Color(0xFF06B6D4);   // فيروزي حيوي
  static const Color cardColor = primaryGlass;          // أبيض شفاف للبطاقات
  static const Color borderColor = borderLight;         // رمادي خفيف للحدود
  static const Color successColor = Color(0xFF10B981);  // أخضر حيوي
  static const Color errorColor = Color(0xFFEF4444);    // أحمر حيوي
  
  // النصوص على الخلفيات الملونة
  static const Color whiteTextColor = Color(0xFFFFFFFF);      // أبيض كامل - جميع النصوص على الخلفيات الملونة
  static const Color successTextColor = Color(0xFFFFFFFF);    // أبيض للخلفيات الخضراء
  static const Color warningTextColor = Color(0xFFFFFFFF);    // أبيض للخلفيات الذهبية
  static const Color dangerTextColor = Color(0xFFFFFFFF);     // أبيض للخلفيات الحمراء
  
  // نصوص خاصة
  static const Color temperatureTextColor = Color(0xFF3B82F6); // أزرق حيوي - درجة الحرارة
  static const Color weatherTextColor = Color(0xFF475569);     // أزرق رمادي متوسط - وصف الطقس
  
  // Weather Colors - iOS 26 Glass Design
  static const Color temperatureColor = Color(0xFF3B82F6);  // أزرق حيوي - درجة الحرارة
  static const Color weatherDescriptionColor = Color(0xFF475569);  // أزرق رمادي متوسط - وصف الطقس
  
  // تدرجات الألوان - iOS 26 Glass Design
  
  // بطاقة الترحيب (Welcome Card)
  static const LinearGradient welcomeCardGradientNew = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6), // أزرق حيوي
      Color(0xFF06B6D4), // فيروزي حيوي
    ],
  );
  
  // بطاقة البلاغات (Reports)
  static const LinearGradient reportsCardGradientNew = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981), // أخضر حيوي
      Color(0xFF059669), // أخضر داكن
    ],
  );
  
  // بطاقة نقاط الثقة (Trust Points)
  static const LinearGradient trustPointsCardGradientNew = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B), // ذهبي حيوي
      Color(0xFFD97706), // ذهبي داكن
    ],
  );
  
  // بطاقة المخاطر القريبة (Nearby Risks)
  static const LinearGradient nearbyRisksCardGradientNew = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEF4444), // أحمر حيوي
      Color(0xFFDC2626), // أحمر داكن
    ],
  );
  
  // أزرار الإجراءات السريعة
  
  // عرض الخريطة
  static const LinearGradient mapViewButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981), // أخضر حيوي
      Color(0xFF059669), // أخضر داكن
    ],
  );
  
  // إبلاغ سريع
  static const LinearGradient quickReportButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEF4444), // أحمر حيوي
      Color(0xFFDC2626), // أحمر داكن
    ],
  );
  
  // المجتمع
  static const LinearGradient communityButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF06B6D4), // فيروزي حيوي
      Color(0xFF0891B2), // فيروزي داكن
    ],
  );
  
  // إحصائياتي
  static const LinearGradient myStatsButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFA855F7), // وردي حيوي
      Color(0xFF9333EA), // وردي داكن
    ],
  );
  
  // للتوافق مع الكود الحالي
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
  
  // تدرجات إضافية للتوافق
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981), // أخضر حيوي
      Color(0xFF059669), // أخضر داكن
    ],
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B), // ذهبي حيوي
      Color(0xFFD97706), // ذهبي داكن
    ],
  );
  
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEF4444), // أحمر حيوي
      Color(0xFFDC2626), // أحمر داكن
    ],
  );
  
  // Active States
  static const LinearGradient activeTabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6), // أزرق حيوي
      Color(0xFF2563EB), // أزرق داكن
    ],
  );
  
  // الظلال - iOS 26 Glass Design
  static const List<BoxShadow> glassBoxShadow = [
    BoxShadow(
      color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x05000000), // rgba(0, 0, 0, 0.02)
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> lightGlassBoxShadow = [
    BoxShadow(
      color: Color(0x0A000000),  // أسود شفاف 4% - للبطاقات الثانوية
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
  
  // ظلال البطاقات الملونة
  static const List<BoxShadow> welcomeCardShadow = [
    BoxShadow(
      color: Color(0x333B82F6),  // أزرق شفاف 20%
      blurRadius: 15,
      offset: Offset(0, 8),
    ),
  ];
  
  static const List<BoxShadow> reportsCardShadow = [
    BoxShadow(
      color: Color(0x3310B981),  // أخضر شفاف 20%
      blurRadius: 15,
      offset: Offset(0, 8),
    ),
  ];
  
  static const List<BoxShadow> trustPointsCardShadow = [
    BoxShadow(
      color: Color(0x33F59E0B),  // ذهبي شفاف 20%
      blurRadius: 15,
      offset: Offset(0, 8),
    ),
  ];
  
  static const List<BoxShadow> nearbyRisksCardShadow = [
    BoxShadow(
      color: Color(0x33EF4444),  // أحمر شفاف 20%
      blurRadius: 15,
      offset: Offset(0, 8),
    ),
  ];
  
  static const List<BoxShadow> interactiveBoxShadow = [
    BoxShadow(
      color: Color(0x14000000), // rgba(0, 0, 0, 0.08)
      blurRadius: 15,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
      blurRadius: 30,
      offset: Offset(0, 8),
    ),
  ];
  
  // Box Shadows
  static const List<BoxShadow> headerCardShadow = [
    BoxShadow(
      color: Color(0x14000000), // rgba(0, 0, 0, 0.08)
      blurRadius: 15,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> bottomNavShadow = [
    BoxShadow(
      color: Color(0x1A000000), // rgba(0, 0, 0, 0.1)
      blurRadius: 20,
      offset: Offset(0, -4),
    ),
  ];
  
  static const List<BoxShadow> settingsIconShadow = [
    BoxShadow(
      color: Color(0x266B7280), // rgba(107, 114, 128, 0.15)
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> activeTabShadow = [
    BoxShadow(
      color: Color(0x4D3B82F6), // rgba(59, 130, 246, 0.3)
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
  
  // Hover Effects Shadows
  static const List<BoxShadow> cardHoverShadow = [
    BoxShadow(
      color: Color(0x1A000000), // rgba(0, 0, 0, 0.1)
      blurRadius: 25,
      offset: Offset(0, 8),
    ),
  ];
  
  static const List<BoxShadow> buttonHoverShadow = [
    BoxShadow(
      color: Color(0x333B82F6), // rgba(59, 130, 246, 0.2)
      blurRadius: 15,
      offset: Offset(0, 6),
    ),
  ];
  
  // Pressed Button Shadow
  static const List<BoxShadow> pressedButtonShadow = [
    BoxShadow(
      color: Color(0x26000000), // rgba(0, 0, 0, 0.15)
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  // أنماط الحاويات الجديدة
  static BoxDecoration get primaryGlassDecoration => BoxDecoration(
    color: primaryGlass,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: borderLight,
      width: 1,
    ),
    boxShadow: glassBoxShadow,
  );
  
  static BoxDecoration get headerCardDecoration => BoxDecoration(
    color: headerCardBackground,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: headerCardBorder,
      width: 1,
    ),
    boxShadow: headerCardShadow,
  );
  
  static BoxDecoration get welcomeCardDecoration => BoxDecoration(
    gradient: welcomeCardGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: welcomeCardBorder,
      width: 1,
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x333B82F6), // rgba(59, 130, 246, 0.2)
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration get reportsCardDecoration => BoxDecoration(
    gradient: reportsCardGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: reportsCardBorder,
      width: 1,
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x3310B981), // rgba(16, 185, 129, 0.2)
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration get trustPointsCardDecoration => BoxDecoration(
    gradient: trustPointsCardGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: trustPointsCardBorder,
      width: 1,
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x33F59E0B), // rgba(245, 158, 11, 0.2)
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration get nearbyRisksCardDecoration => BoxDecoration(
    gradient: nearbyRisksCardGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: nearbyRisksCardBorder,
      width: 1,
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x33EF4444), // rgba(239, 68, 68, 0.2)
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration get quickActionsDecoration => BoxDecoration(
    color: quickActionsBackground,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: quickActionsBorder,
      width: 1,
    ),
    boxShadow: glassBoxShadow,
  );
  
  static BoxDecoration get mapViewButtonDecoration => BoxDecoration(
    gradient: mapViewGradient,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: mapViewBorder,
      width: 1,
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x3310B981), // rgba(16, 185, 129, 0.2)
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get quickReportButtonDecoration => BoxDecoration(
    gradient: quickReportGradient,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: quickReportBorder,
      width: 1,
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x33EF4444), // rgba(239, 68, 68, 0.2)
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get communityButtonDecoration => BoxDecoration(
    gradient: communityGradient,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: communityBorder,
      width: 1,
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x336366F1), // rgba(99, 102, 241, 0.2)
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get myStatsButtonDecoration => BoxDecoration(
    gradient: myStatsGradient,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: myStatsBorder,
      width: 1,
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x33A855F7), // rgba(168, 85, 247, 0.2)
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get bottomNavDecoration => BoxDecoration(
    color: bottomNavBackground,
    border: Border.all(
      color: bottomNavBorder,
      width: 1,
    ),
    boxShadow: bottomNavShadow,
  );
  
  static BoxDecoration get activeTabDecoration => BoxDecoration(
    gradient: activeTabGradient,
    borderRadius: BorderRadius.circular(12),
    boxShadow: activeTabShadow,
  );

  static BoxDecoration get settingsCardDecoration => BoxDecoration(
    color: primaryGlass,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: borderLight,
      width: 1,
    ),
    boxShadow: glassBoxShadow,
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
  
  // أنماط النصوص الجديدة
  static const TextStyle primaryTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle secondaryTextStyle = TextStyle(
    color: secondaryTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  // أنماط النصوص المطلوبة للتطبيق
  static const TextStyle headerTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    color: secondaryTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  static const TextStyle subtitleTextStyle = TextStyle(
    color: secondaryTextColor,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
  
  static const TextStyle accentTextStyle = TextStyle(
    color: accentTextColor,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
  
  static const TextStyle successTextStyle = TextStyle(
    color: successTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  static const TextStyle warningTextStyle = TextStyle(
    color: warningTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  static const TextStyle dangerTextStyle = TextStyle(
    color: dangerTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  static const TextStyle temperatureTextStyle = TextStyle(
    color: temperatureColor,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
  
  static const TextStyle weatherDescriptionTextStyle = TextStyle(
    color: weatherDescriptionColor,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
  
  static const TextStyle activeTabTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
  
  // أنماط الأزرار الجديدة
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: primaryTextColor,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
  
  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: secondaryTextColor,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
  
  static ButtonStyle get activeTabButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
  
  // تأثيرات التفاعل
  static BoxDecoration getInteractiveDecoration(bool isHovered) {
    return BoxDecoration(
      color: isHovered ? const Color(0xE6FFFFFF) : toolbarGlass,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isHovered ? const Color(0x26E5E7EB) : borderLight,
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
    return _isDarkMode ? const Color(0xE6FFFFFF) : primaryTextColor;
  }
  
  // دوال مساعدة للتأثيرات التفاعلية
  
  /// تطبيق تأثير الـ hover على البطاقات
  static BoxDecoration getCardHoverDecoration(BoxDecoration originalDecoration) {
    return originalDecoration.copyWith(
      boxShadow: cardHoverShadow,
    );
  }
  
  /// تطبيق تأثير الـ hover على الأزرار
  static BoxDecoration getButtonHoverDecoration(BoxDecoration originalDecoration) {
    return originalDecoration.copyWith(
      boxShadow: buttonHoverShadow,
    );
  }
  
  /// تطبيق تأثير الضغط على الأزرار
  static BoxDecoration getPressedButtonDecoration(BoxDecoration originalDecoration) {
    return originalDecoration.copyWith(
      boxShadow: pressedButtonShadow,
    );
  }
  
  /// الحصول على تدرج الأيقونة حسب النوع
  static LinearGradient getIconGradient(String iconType) {
    switch (iconType) {
      case 'settings':
        return settingsIconGradient;
      case 'notification':
        return notificationIconGradient;
      case 'shield':
        return protectionIconGradient;
      case 'badge':
        return notificationBadgeGradient;
      default:
        return settingsIconGradient;
    }
  }
  
  /// الحصول على تدرج البطاقة حسب النوع
  static LinearGradient getCardGradient(String cardType) {
    switch (cardType) {
      case 'welcome':
        return welcomeCardGradient;
      case 'reports':
        return reportsCardGradient;
      case 'trustPoints':
        return trustPointsCardGradient;
      case 'nearbyRisks':
        return nearbyRisksCardGradient;
      case 'mapView':
        return mapViewGradient;
      case 'quickReport':
        return quickReportGradient;
      case 'community':
        return communityGradient;
      case 'myStats':
        return myStatsGradient;
      case 'activeTab':
        return activeTabGradient;
      default:
        return welcomeCardGradient;
    }
  }
  
  /// الحصول على لون النص حسب النوع
  static Color getTextColor(String textType) {
    switch (textType) {
      case 'primary':
        return primaryTextColor;
      case 'secondary':
        return secondaryTextColor;
      case 'accent':
        return accentTextColor;
      case 'success':
        return successTextColor;
      case 'warning':
        return warningTextColor;
      case 'danger':
        return dangerTextColor;
      case 'temperature':
        return temperatureColor;
      case 'weather':
        return weatherDescriptionColor;
      default:
        return primaryTextColor;
    }
  }

  /// الحصول على لون الأيقونة حسب النوع
  static Color getIconColor(String iconType) {
    switch (iconType) {
      case 'primary':
        return iconPrimary;
      case 'secondary':
        return iconSecondary;
      case 'accent':
        return iconAccent;
      case 'success':
        return iconSuccess;
      case 'warning':
        return iconWarning;
      case 'danger':
        return iconDanger;
      default:
        return iconPrimary;
    }
  }
  
  /// خلفية التطبيق الرئيسية
  static Widget get backgroundWidget => Container(
    decoration: const BoxDecoration(
      gradient: mainBackgroundGradient,
    ),
  );
  
  // Helper method to get gradient by name
  static LinearGradient getGradientByName(String name) {
    switch (name) {
      case 'highlight':
        return highlightGradient;
      case 'success':
        return successGradient;
      case 'warning':
        return warningGradient;
      case 'danger':
        return dangerGradient;
      case 'primary':
        return welcomeCardGradient;
      case 'info':
        return communityGradient;
      case 'activeTab':
        return activeTabGradient;
      case 'shadow':
        return LinearGradient(
          colors: [Color(0x1A000000), Color(0x0A000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      // البطاقات الجديدة
      case 'welcomeCard':
        return welcomeCardGradientNew;
      case 'reportsCard':
        return reportsCardGradientNew;
      case 'trustPointsCard':
        return trustPointsCardGradientNew;
      case 'nearbyRisksCard':
        return nearbyRisksCardGradientNew;
      // الأزرار السريعة
      case 'mapViewButton':
        return mapViewButtonGradient;
      case 'quickReportButton':
        return quickReportButtonGradient;
      case 'communityButton':
        return communityButtonGradient;
      case 'myStatsButton':
        return myStatsButtonGradient;
      default:
        return highlightGradient;
    }
  }
  
  // Helper method to get shadow by card type
  static List<BoxShadow> getShadowByCardType(String cardType) {
    switch (cardType) {
      case 'welcomeCard':
        return welcomeCardShadow;
      case 'reportsCard':
        return reportsCardShadow;
      case 'trustPointsCard':
        return trustPointsCardShadow;
      case 'nearbyRisksCard':
        return nearbyRisksCardShadow;
      case 'lightGlass':
        return lightGlassBoxShadow;
      case 'glass':
      default:
        return glassBoxShadow;
    }
  }
  
}