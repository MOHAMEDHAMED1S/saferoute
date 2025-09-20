import 'package:flutter/material.dart';
import '../theme/liquid_glass_theme.dart';

/// حاوية Liquid Glass الأساسية
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final LiquidGlassType type;
  final bool isInteractive;
  
  const LiquidGlassContainer({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.type = LiquidGlassType.primary,
    this.isInteractive = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration;
    
    switch (type) {
      case LiquidGlassType.primary:
        decoration = LiquidGlassTheme.primaryGlassDecoration;
        break;
      case LiquidGlassType.secondary:
        decoration = LiquidGlassTheme.secondaryGlassDecoration;
        break;
      case LiquidGlassType.toolbar:
        decoration = LiquidGlassTheme.toolbarGlassDecoration;
        break;
      case LiquidGlassType.ultraLight:
        decoration = LiquidGlassTheme.ultraLightGlassDecoration;
        break;
      case LiquidGlassType.adaptive:
        decoration = LiquidGlassTheme.adaptiveDecoration;
        break;
    }
    
    if (borderRadius != null) {
      decoration = decoration.copyWith(borderRadius: borderRadius);
    }
    
    Widget container = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child,
    );
    
    if (isInteractive) {
      return _InteractiveGlassContainer(
        decoration: decoration,
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        child: child,
      );
    }
    
    return container;
  }
}

/// حاوية تفاعلية مع تأثيرات Hover
class _InteractiveGlassContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxDecoration decoration;
  
  const _InteractiveGlassContainer({
    Key? key,
    required this.child,
    required this.decoration,
    this.padding,
    this.margin,
    this.width,
    this.height,
  }) : super(key: key);
  
  @override
  _InteractiveGlassContainerState createState() => _InteractiveGlassContainerState();
}

class _InteractiveGlassContainerState extends State<_InteractiveGlassContainer>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
        _animationController.forward();
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              margin: widget.margin,
              decoration: LiquidGlassTheme.getInteractiveDecoration(_isHovered),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// زر Liquid Glass
class LiquidGlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LiquidGlassType type;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double? borderRadius;
  
  const LiquidGlassButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.type = LiquidGlassType.primary,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      type: type,
      isInteractive: true,
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius ?? 50),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: LiquidGlassTheme.adaptiveTextColor,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: LiquidGlassTheme.primaryTextStyle,
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة Liquid Glass
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  
  const LiquidGlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      type: LiquidGlassType.secondary,
      isInteractive: onTap != null,
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }
}

/// شريط التطبيق Liquid Glass
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  
  const LiquidGlassAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LiquidGlassTheme.toolbarGlassDecoration,
      child: AppBar(
        title: Text(
          title,
          style: LiquidGlassTheme.primaryTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: centerTitle,
        backgroundColor: Colors.transparent,
        elevation: elevation,
        leading: leading,
        actions: actions,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// حقل النص Liquid Glass
class LiquidGlassTextField extends StatelessWidget {
  final String? hintText;
  final String? labelText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  
  const LiquidGlassTextField({
    Key? key,
    this.hintText,
    this.labelText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.validator,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      type: LiquidGlassType.ultraLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
        style: LiquidGlassTheme.primaryTextStyle,
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          hintStyle: LiquidGlassTheme.captionTextStyle,
          labelStyle: LiquidGlassTheme.secondaryTextStyle,
          border: InputBorder.none,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          prefixIconColor: LiquidGlassTheme.adaptiveTextColor,
          suffixIconColor: LiquidGlassTheme.adaptiveTextColor,
        ),
      ),
    );
  }
}

/// أنواع Liquid Glass
enum LiquidGlassType {
  primary,
  secondary,
  toolbar,
  ultraLight,
  adaptive,
}

/// مؤشر التحميل Liquid Glass
class LiquidGlassLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  
  const LiquidGlassLoadingIndicator({
    Key? key,
    this.size = 40,
    this.color,
  }) : super(key: key);
  
  @override
  _LiquidGlassLoadingIndicatorState createState() => _LiquidGlassLoadingIndicatorState();
}

class _LiquidGlassLoadingIndicatorState extends State<LiquidGlassLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      type: LiquidGlassType.ultraLight,
      width: widget.size + 20,
      height: widget.size + 20,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * 3.14159,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.color ?? LiquidGlassTheme.adaptiveTextColor,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}