import 'package:flutter/material.dart';
import '../../theme/liquid_glass_theme.dart';
import '../liquid_glass_widgets.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigationWidget({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: LiquidGlassTheme.bottomNavDecoration.copyWith(
        borderRadius: BorderRadius.circular(32),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: LiquidGlassTheme.getIconColor('primary'),
          unselectedItemColor: LiquidGlassTheme.getIconColor('secondary'),
          selectedLabelStyle: LiquidGlassTheme.headerTextStyle.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: LiquidGlassTheme.subtitleTextStyle.copyWith(
            fontSize: 11,
          ),
          items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'الخريطة',
          ),
          BottomNavigationBarItem(
            icon: LiquidGlassContainer(
              type: LiquidGlassType.primary,
              padding: const EdgeInsets.all(8),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LiquidGlassTheme.getGradientByName('quickReportButton'),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: LiquidGlassTheme.getGradientByName('quickReportButton').colors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add,
                  color: LiquidGlassTheme.getIconColor('primary'),
                  size: 24,
                ),
              ),
            ),
            label: 'إبلاغ',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'المجتمع',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ],
        ),
      ),
    );
  }
}