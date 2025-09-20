import 'package:flutter/material.dart';
import '../theme/liquid_glass_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Widget? icon;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 56,
    this.padding,
    this.borderRadius,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? LiquidGlassTheme.getGradientByName('primary').colors.first,
          foregroundColor: textColor ?? LiquidGlassTheme.getTextColor('primary'),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: LiquidGlassTheme.getGradientByName('shadow').colors.first.withOpacity(0.26),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(LiquidGlassTheme.getTextColor('primary') ?? Colors.blue),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...
                    [
                      icon!,
                      const SizedBox(width: 8),
                    ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? LiquidGlassTheme.getTextColor('primary'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class CustomOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? borderColor;
  final Color? textColor;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Widget? icon;

  const CustomOutlinedButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.borderColor,
    this.textColor,
    this.width,
    this.height = 56,
    this.padding,
    this.borderRadius,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? LiquidGlassTheme.getGradientByName('primary').colors.first,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(
            color: borderColor ?? LiquidGlassTheme.getGradientByName('primary').colors.first,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? LiquidGlassTheme.getGradientByName('primary').colors.first,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...
                    [
                      icon!,
                      const SizedBox(width: 8),
                    ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? LiquidGlassTheme.getGradientByName('primary').colors.first,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}