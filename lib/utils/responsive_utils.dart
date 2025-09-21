import 'package:flutter/material.dart';
import 'dart:math' as math;

// Responsive breakpoints
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1800;
}

// Screen size helper
class ScreenSize {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.mobile && width < Breakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.tablet && width < Breakpoints.desktop;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.desktop;
  }

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.tablet;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.tablet;
  }

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.mobile) {
      return DeviceType.mobile;
    } else if (width < Breakpoints.tablet) {
      return DeviceType.tablet;
    } else if (width < Breakpoints.desktop) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }

  static Orientation getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }

  static bool isPortrait(BuildContext context) {
    return getOrientation(context) == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return getOrientation(context) == Orientation.landscape;
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;
  final Widget Function(BuildContext, DeviceType)? builder;

  const ResponsiveBuilder({
    Key? key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
    this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceType = ScreenSize.getDeviceType(context);
    
    if (builder != null) {
      return builder!(context, deviceType);
    }

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile ?? tablet ?? desktop ?? largeDesktop ?? Container();
      case DeviceType.tablet:
        return tablet ?? mobile ?? desktop ?? largeDesktop ?? Container();
      case DeviceType.desktop:
        return desktop ?? tablet ?? largeDesktop ?? mobile ?? Container();
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile ?? Container();
    }
  }
}

// Responsive value helper
class ResponsiveValue<T> {
  final T? mobile;
  final T? tablet;
  final T? desktop;
  final T? largeDesktop;
  final T defaultValue;

  const ResponsiveValue({
    required this.defaultValue,
    this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  T getValue(BuildContext context) {
    final deviceType = ScreenSize.getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile ?? defaultValue;
      case DeviceType.tablet:
        return tablet ?? mobile ?? defaultValue;
      case DeviceType.desktop:
        return desktop ?? tablet ?? defaultValue;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? defaultValue;
    }
  }
}

// Responsive spacing
class ResponsiveSpacing {
  static double getHorizontalSpacing(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return 16.0;
    } else if (ScreenSize.isTablet(context)) {
      return 24.0;
    } else if (ScreenSize.isDesktop(context)) {
      return 32.0;
    } else {
      return 48.0;
    }
  }

  static double getVerticalSpacing(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return 12.0;
    } else if (ScreenSize.isTablet(context)) {
      return 16.0;
    } else if (ScreenSize.isDesktop(context)) {
      return 24.0;
    } else {
      return 32.0;
    }
  }

  static EdgeInsets getPagePadding(BuildContext context) {
    final horizontal = getHorizontalSpacing(context);
    final vertical = getVerticalSpacing(context);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  static EdgeInsets getCardPadding(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return const EdgeInsets.all(12.0);
    } else if (ScreenSize.isTablet(context)) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(20.0);
    }
  }
}

// Responsive font sizes
class ResponsiveFontSize {
  static double getHeadline1(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return 24.0;
    } else if (ScreenSize.isTablet(context)) {
      return 28.0;
    } else if (ScreenSize.isDesktop(context)) {
      return 32.0;
    } else {
      return 36.0;
    }
  }

  static double getHeadline2(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return 20.0;
    } else if (ScreenSize.isTablet(context)) {
      return 24.0;
    } else if (ScreenSize.isDesktop(context)) {
      return 28.0;
    } else {
      return 32.0;
    }
  }

  static double getHeadline3(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return 18.0;
    } else if (ScreenSize.isTablet(context)) {
      return 20.0;
    } else if (ScreenSize.isDesktop(context)) {
      return 24.0;
    } else {
      return 28.0;
    }
  }

  static double getBodyText1(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return 16.0;
    } else if (ScreenSize.isTablet(context)) {
      return 17.0;
    } else {
      return 18.0;
    }
  }

  static double getBodyText2(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return 14.0;
    } else if (ScreenSize.isTablet(context)) {
      return 15.0;
    } else {
      return 16.0;
    }
  }

  static double getCaption(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return 12.0;
    } else if (ScreenSize.isTablet(context)) {
      return 13.0;
    } else {
      return 14.0;
    }
  }
}

// Responsive grid
class ResponsiveGrid {
  static int getColumnCount(BuildContext context, {
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 3,
    int largeDesktopColumns = 4,
  }) {
    if (ScreenSize.isMobile(context)) {
      return mobileColumns;
    } else if (ScreenSize.isTablet(context)) {
      return tabletColumns;
    } else if (ScreenSize.isDesktop(context)) {
      return desktopColumns;
    } else {
      return largeDesktopColumns;
    }
  }

  static double getChildAspectRatio(BuildContext context, {
    double mobileRatio = 1.0,
    double tabletRatio = 1.2,
    double desktopRatio = 1.5,
    double largeDesktopRatio = 1.8,
  }) {
    if (ScreenSize.isMobile(context)) {
      return mobileRatio;
    } else if (ScreenSize.isTablet(context)) {
      return tabletRatio;
    } else if (ScreenSize.isDesktop(context)) {
      return desktopRatio;
    } else {
      return largeDesktopRatio;
    }
  }

  static double getCrossAxisSpacing(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return 8.0;
    } else if (ScreenSize.isTablet(context)) {
      return 12.0;
    } else {
      return 16.0;
    }
  }

  static double getMainAxisSpacing(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return 8.0;
    } else if (ScreenSize.isTablet(context)) {
      return 12.0;
    } else {
      return 16.0;
    }
  }
}

// Responsive layout helper
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final bool centerContent;
  final EdgeInsetsGeometry? padding;

  const ResponsiveLayout({
    Key? key,
    required this.child,
    this.maxWidth,
    this.centerContent = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveMaxWidth = maxWidth ?? _getDefaultMaxWidth(context);
    final effectivePadding = padding ?? ResponsiveSpacing.getPagePadding(context);

    Widget content = Container(
      width: math.min(screenWidth, effectiveMaxWidth),
      padding: effectivePadding,
      child: child,
    );

    if (centerContent && screenWidth > effectiveMaxWidth) {
      content = Center(child: content);
    }

    return content;
  }

  double _getDefaultMaxWidth(BuildContext context) {
    if (ScreenSize.isMobile(context)) {
      return double.infinity;
    } else if (ScreenSize.isTablet(context)) {
      return 800;
    } else if (ScreenSize.isDesktop(context)) {
      return 1200;
    } else {
      return 1600;
    }
  }
}

// Responsive card
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;

  const ResponsiveCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? ResponsiveSpacing.getCardPadding(context);
    final effectiveMargin = margin ?? EdgeInsets.all(ResponsiveSpacing.getVerticalSpacing(context) / 2);
    final effectiveElevation = elevation ?? (ScreenSize.isMobile(context) ? 2.0 : 4.0);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(ScreenSize.isMobile(context) ? 8.0 : 12.0);

    return Card(
      color: color,
      elevation: effectiveElevation,
      margin: effectiveMargin,
      shape: RoundedRectangleBorder(
        borderRadius: effectiveBorderRadius,
      ),
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );
  }
}

// Responsive text
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final ResponsiveTextType type;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.type = ResponsiveTextType.body1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fontSize = _getFontSize(context);
    final effectiveStyle = (style ?? const TextStyle()).copyWith(fontSize: fontSize);

    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  double _getFontSize(BuildContext context) {
    switch (type) {
      case ResponsiveTextType.headline1:
        return ResponsiveFontSize.getHeadline1(context);
      case ResponsiveTextType.headline2:
        return ResponsiveFontSize.getHeadline2(context);
      case ResponsiveTextType.headline3:
        return ResponsiveFontSize.getHeadline3(context);
      case ResponsiveTextType.body1:
        return ResponsiveFontSize.getBodyText1(context);
      case ResponsiveTextType.body2:
        return ResponsiveFontSize.getBodyText2(context);
      case ResponsiveTextType.caption:
        return ResponsiveFontSize.getCaption(context);
    }
  }
}

enum ResponsiveTextType {
  headline1,
  headline2,
  headline3,
  body1,
  body2,
  caption,
}

// Responsive safe area
class ResponsiveSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const ResponsiveSafeArea({
    Key? key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // On larger screens, we might not need safe area
    if (ScreenSize.isDesktop(context) || ScreenSize.isLargeDesktop(context)) {
      return child;
    }

    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}

// Responsive utilities
class ResponsiveUtils {
  static EdgeInsets getResponsivePadding(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16.0);
      case DeviceType.tablet:
        return const EdgeInsets.all(20.0);
      case DeviceType.desktop:
        return const EdgeInsets.all(24.0);
      case DeviceType.largeDesktop:
        return const EdgeInsets.all(32.0);
    }
  }
  
  static double getResponsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }
  
  static double getResponsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }
}

// Responsive app bar
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final double? elevation;
  final bool centerTitle;

  const ResponsiveAppBar({
    Key? key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.elevation,
    this.centerTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final titleFontSize = ResponsiveFontSize.getHeadline3(context);
    
    return AppBar(
      title: title != null
          ? Text(
              title!,
              style: TextStyle(fontSize: titleFontSize),
            )
          : null,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      toolbarHeight: ScreenSize.isMobile(context) ? 56.0 : 64.0,
    );
  }

  @override
  Size get preferredSize {
    return Size.fromHeight(56.0); // Default AppBar height
  }
}