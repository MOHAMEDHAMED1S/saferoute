import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/reports_provider.dart';
import '../../../models/report_model.dart';
import '../../../widgets/custom_button.dart';

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
                color: Colors.black.withOpacity(_fadeAnimation.value),
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
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
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
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'البلاغات القريبة',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E3A59),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _closeSheet,
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFF8B9DC3),
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
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF4A90E2),
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
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      reportsProvider.errorMessage!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    CustomButton(
                                      text: 'إعادة المحاولة',
                                      onPressed: () {
                                        reportsProvider.initialize();
                                      },
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
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لا توجد بلاغات قريبة',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E3A59),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(report.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_calculateDistance(report)} كم',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2E3A59),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.thumb_up_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${report.confirmations.trueVotes}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.thumb_down_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${report.confirmations.falseVotes}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
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
        return Colors.red;
      case ReportType.jam:
        return Colors.orange;
      case ReportType.carBreakdown:
        return Colors.blue;
      case ReportType.bump:
        return Colors.amber;
      case ReportType.closedRoad:
        return Colors.purple;
      default:
        return Colors.grey;
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