import 'package:flutter/material.dart';
import '../theme/liquid_glass_theme.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final Color? borderColor;
  final double borderRadius;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
    this.fillColor,
    this.borderColor,
    this.borderRadius = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E3A59),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          onTap: onTap,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          focusNode: focusNode,
          textCapitalization: textCapitalization,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2E3A59),
          ),
          decoration: InputDecoration(
            hintText: hintText ?? label,
            hintStyle: const TextStyle(
              color: Color(0xFF8B9DC3),
              fontSize: 16,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: const Color(0xFF8B9DC3),
                    size: 20,
                  )
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor ?? const Color(0xFFF8F9FA),
            contentPadding: contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: borderColor ?? const Color(0xFFE0E6ED),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: borderColor ?? const Color(0xFFE0E6ED),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(
                color: Color(0xFF4A90E2),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: LiquidGlassTheme.getGradientByName('danger').colors.first,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: LiquidGlassTheme.getGradientByName('danger').colors.first,
                width: 2,
              ),
            ),
            counterText: maxLength != null ? null : '',
          ),
        ),
      ],
    );
  }
}

class CustomSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final VoidCallback? onClear;
  final bool showClearButton;

  const CustomSearchField({
    Key? key,
    required this.controller,
    this.hintText = 'البحث...',
    this.onChanged,
    this.onClear,
    this.showClearButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E6ED),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2E3A59),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF8B9DC3),
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF8B9DC3),
            size: 20,
          ),
          suffixIcon: showClearButton && controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Color(0xFF8B9DC3),
                    size: 20,
                  ),
                  onPressed: () {
                    controller.clear();
                    if (onClear != null) onClear!();
                    if (onChanged != null) onChanged!('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}