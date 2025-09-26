import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/reports_provider.dart';
import '../../../models/report_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../theme/liquid_glass_theme.dart';
import '../../../widgets/liquid_glass_widgets.dart';

class FilterBottomSheet extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onFiltersChanged;

  const FilterBottomSheet({
    Key? key,
    required this.onClose,
    required this.onFiltersChanged,
  }) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  Set<ReportType> _selectedTypes = {};
  double _searchRadius = 5.0; // km
  bool _showActiveOnly = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentFilters();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  void _loadCurrentFilters() {
    final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
    _searchRadius = reportsProvider.searchRadius;
    // Initialize with all types selected
    _selectedTypes = Set.from(ReportType.values);
  }

  void _closeSheet() async {
    await _animationController.reverse();
    widget.onClose();
  }

  void _applyFilters() {
    final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
    reportsProvider.setSearchRadius(_searchRadius);
    widget.onFiltersChanged();
    _closeSheet();
  }

  void _resetFilters() {
    setState(() {
      _selectedTypes = Set.from(ReportType.values);
      _searchRadius = 5.0;
      _showActiveOnly = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Background overlay
            GestureDetector(
              onTap: _closeSheet,
              child: Container(
                color: LiquidGlassTheme.getGradientByName('shadow').colors.first.withOpacity(_fadeAnimation.value),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            
            // Bottom sheet
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Transform.translate(
                offset: Offset(0, MediaQuery.of(context).size.height * 0.7 * _slideAnimation.value),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: const BoxDecoration(
                    color: LiquidGlassTheme.backgroundColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: LiquidGlassTheme.getTextColor('secondary')?.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'تصفية البلاغات',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: LiquidGlassTheme.getTextColor('primary') ?? Colors.black,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _resetFilters,
                              child: Text(
                                'إعادة تعيين',
                                style: TextStyle(
                                  color: LiquidGlassTheme.getGradientByName('primary').colors.first,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _closeSheet,
                              icon: Icon(
                                Icons.close,
                                color: LiquidGlassTheme.getTextColor('secondary'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Report Types Section
                              Text(
                                'نوع البلاغ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: LiquidGlassTheme.getTextColor('primary'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildReportTypesGrid(),
                              
                              const SizedBox(height: 32),
                              
                              // Search Radius Section
                              Text(
                                'نطاق البحث',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: LiquidGlassTheme.getTextColor('primary'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSearchRadiusSlider(),
                              
                              const SizedBox(height: 32),
                              
                              // Status Filter Section
                              Text(
                                'حالة البلاغ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: LiquidGlassTheme.getTextColor('primary'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildStatusFilter(),
                              
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      
                      // Apply Button
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: CustomButton(
                          text: 'تطبيق التصفية',
                          onPressed: _applyFilters,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportTypesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: ReportType.values.map((type) {
        final isSelected = _selectedTypes.contains(type);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTypes.remove(type);
              } else {
                _selectedTypes.add(type);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? LiquidGlassTheme.getGradientByName('primary').colors.first : LiquidGlassTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? LiquidGlassTheme.getGradientByName('primary').colors.first : (LiquidGlassTheme.getTextColor('secondary') ?? Colors.grey).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getReportIcon(type),
                  size: 16,
                  color: isSelected ? LiquidGlassTheme.getIconColor('primary') : _getReportColor(type),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _getReportTypeTitle(type),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? LiquidGlassTheme.getIconColor('primary') : LiquidGlassTheme.getTextColor('primary'),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchRadiusSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1 كم',
              style: TextStyle(
                fontSize: 12,
                color: LiquidGlassTheme.getTextColor('secondary'),
              ),
            ),
            Text(
              '${_searchRadius.toStringAsFixed(1)} كم',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: LiquidGlassTheme.getTextColor('primary'),
              ),
            ),
            Text(
              '20 كم',
              style: TextStyle(
                fontSize: 12,
                color: LiquidGlassTheme.getTextColor('secondary'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: LiquidGlassTheme.getGradientByName('primary').colors.first,
          inactiveTrackColor: LiquidGlassTheme.getTextColor('secondary')?.withOpacity(0.3),
          thumbColor: LiquidGlassTheme.getGradientByName('primary').colors.first,
          overlayColor: LiquidGlassTheme.getGradientByName('primary').colors.first.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: _searchRadius,
            min: 1.0,
            max: 20.0,
            divisions: 19,
            onChanged: (value) {
              setState(() {
                _searchRadius = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LiquidGlassTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LiquidGlassTheme.getTextColor('secondary')?.withOpacity(0.2) ?? Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: LiquidGlassTheme.getTextColor('secondary'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'البلاغات النشطة فقط',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: LiquidGlassTheme.getTextColor('primary'),
                  ),
                ),
                Text(
                  'إظهار البلاغات النشطة وغير المنتهية الصلاحية فقط',
                  style: TextStyle(
                    fontSize: 12,
                    color: LiquidGlassTheme.getTextColor('secondary'),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _showActiveOnly,
            onChanged: (value) {
              setState(() {
                _showActiveOnly = value;
              });
            },
            activeColor: LiquidGlassTheme.getGradientByName('primary').colors.first,
          ),
        ],
      ),
    );
  }

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return Icons.car_crash;
      case ReportType.jam:
        return Icons.traffic;
      case ReportType.carBreakdown:
        return Icons.car_repair;
      case ReportType.bump:
        return Icons.warning;
      case ReportType.closedRoad:
        return Icons.block;
      default:
        return Icons.report;
    }
  }

  Color _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return LiquidGlassTheme.getGradientByName('danger').colors.first;
      case ReportType.jam:
        return LiquidGlassTheme.getGradientByName('warning').colors.first;
      case ReportType.carBreakdown:
        return LiquidGlassTheme.getGradientByName('info').colors.first;
      case ReportType.bump:
        return LiquidGlassTheme.getGradientByName('warning').colors.last;
      case ReportType.closedRoad:
        return LiquidGlassTheme.getGradientByName('primary').colors.first;
      default:
        return LiquidGlassTheme.getTextColor('secondary') ?? Colors.grey;
    }
  }

  String _getReportTypeTitle(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return 'حادث مروري';
      case ReportType.jam:
        return 'ازدحام مروري';
      case ReportType.carBreakdown:
        return 'عطل مركبة';
      case ReportType.bump:
        return 'مطب';
      case ReportType.closedRoad:
        return 'طريق مغلق';
      default:
        return 'بلاغ';
    }
  }
}