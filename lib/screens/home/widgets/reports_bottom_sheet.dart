import 'package:flutter/material.dart';
import '../../../theme/liquid_glass_theme.dart';
import 'package:provider/provider.dart';
import '../../../providers/reports_provider.dart';
import '../../../models/report_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../theme/liquid_glass_theme.dart';
import '../../../widgets/liquid_glass_widgets.dart';

class ReportsBottomSheet extends StatefulWidget {
  final VoidCallback onClose;

  const ReportsBottomSheet({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ReportsBottomSheet> createState() => _ReportsBottomSheetState();
}

class _ReportsBottomSheetState extends State<ReportsBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeSheet() async {
    await _animationController.reverse();
    widget.onClose();
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
                offset: Offset(0, MediaQuery.of(context).size.height * 0.6 * _slideAnimation.value),
                child: LiquidGlassContainer(
                  type: LiquidGlassType.secondary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  height: MediaQuery.of(context).size.height * 0.6,
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
                                'البلاغات القريبة',
                                style: LiquidGlassTheme.headerTextStyle.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
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
                      
                      // Reports list
                      Expanded(
                        child: Consumer<ReportsProvider>(
                          builder: (context, reportsProvider, child) {
                            if (reportsProvider.isLoading) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: LiquidGlassTheme.getTextColor('primary'),
                                ),
                              );
                            }
                            
                            if (reportsProvider.errorMessage != null) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: LiquidGlassTheme.getTextColor('secondary')?.withOpacity(0.6),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      reportsProvider.errorMessage!,
                                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    LiquidGlassButton(
                                      text: 'إعادة المحاولة',
                                      onPressed: () {
                                        reportsProvider.initialize();
                                      },
                                      type: LiquidGlassType.primary,
                                      borderRadius: 12,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            final reports = reportsProvider.nearbyReports;
                            
                            if (reports.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.report_off,
                                      size: 48,
                                      color: LiquidGlassTheme.secondaryTextStyle.color?.withOpacity(0.6),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لا توجد بلاغات قريبة',
                                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: reports.length,
                              itemBuilder: (context, index) {
                                final report = reports[index];
                                return _buildReportCard(report);
                              },
                            );
                          },
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

  Widget _buildReportCard(ReportModel report) {
    return LiquidGlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      type: LiquidGlassType.secondary,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getReportColor(report.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getReportIcon(report.type),
                  color: _getReportColor(report.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getReportTypeTitle(report.type),
                      style: LiquidGlassTheme.headerTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(report.createdAt),
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_calculateDistance(report)} كم',
                style: LiquidGlassTheme.secondaryTextStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.description,
            style: LiquidGlassTheme.headerTextStyle.copyWith(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.thumb_up_outlined,
                size: 16,
                color: LiquidGlassTheme.getTextColor('secondary'),
              ),
              const SizedBox(width: 4),
              Text(
                '${report.confirmations.trueVotes}',
                style: LiquidGlassTheme.secondaryTextStyle.copyWith(
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.thumb_down_outlined,
                size: 16,
                color: LiquidGlassTheme.getTextColor('secondary'),
              ),
              const SizedBox(width: 4),
              Text(
                '${report.confirmations.falseVotes}',
                style: LiquidGlassTheme.secondaryTextStyle.copyWith(
                  fontSize: 12,
                ),
              ),
            ],
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  String _calculateDistance(ReportModel report) {
    // TODO: Calculate actual distance using current location
    // For now, return a placeholder
    return '0.5';
  }
}