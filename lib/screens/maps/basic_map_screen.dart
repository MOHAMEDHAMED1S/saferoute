import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../widgets/liquid_glass_widgets.dart';
import '../../models/report_model.dart';
import '../../models/nearby_report.dart';
import '../../services/realtime_reports_service.dart';
import '../../widgets/common/bottom_navigation_widget.dart';
import '../home/widgets/mapbox_widget.dart';

class BasicMapScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final bool showMarker;
  final String? markerTitle;
  final String? markerDescription;

  const BasicMapScreen({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.showMarker = false,
    this.markerTitle,
    this.markerDescription,
  }) : super(key: key);

  @override
  State<BasicMapScreen> createState() => _BasicMapScreenState();
}

class _BasicMapScreenState extends State<BasicMapScreen> {
  final Set<ReportType> _activeFilters = Set.from(ReportType.values);
  int _currentBottomNavIndex = 1; // Set to 1 for "الخريطة" tab
  Position? _currentPosition;

  // Real-time service
  final RealtimeReportsService _realtimeService = RealtimeReportsService();
  StreamSubscription<List<NearbyReport>>? _reportsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _startRealtimeReports();
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition();
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _startRealtimeReports() {
    if (_currentPosition != null) {
      _reportsSubscription = _realtimeService
          .listenToNearbyReports(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            radiusKm: 10.0,
          )
          .listen((nearbyReports) {
        // Handle real-time reports
        debugPrint('Received ${nearbyReports.length} nearby reports');
      });
    }
  }

  String _getReportTypeTitle(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return 'حوادث مرورية';
      case ReportType.jam:
        return 'ازدحام مروري';
      case ReportType.carBreakdown:
        return 'عطل مركبة';
      case ReportType.bump:
        return 'مطب';
      case ReportType.closedRoad:
        return 'طريق مغلق';
      case ReportType.hazard:
        return 'خطر على الطريق';
      case ReportType.police:
        return 'نقطة شرطة';
      case ReportType.traffic:
        return 'حركة مرور كثيفة';
      case ReportType.other:
        return 'أخرى';
    }
  }

  String _getReportTypeDescription(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return 'حوادث السيارات والحوادث المرورية';
      case ReportType.jam:
        return 'ازدحام مروري واختناقات';
      case ReportType.carBreakdown:
        return 'عطل في المركبات';
      case ReportType.bump:
        return 'مطبات صناعية أو طبيعية';
      case ReportType.closedRoad:
        return 'طرق مغلقة أو مسدودة';
      case ReportType.hazard:
        return 'مخاطر على الطريق';
      case ReportType.police:
        return 'نقاط تفتيش شرطية';
      case ReportType.traffic:
        return 'حركة مرور مكثفة';
      case ReportType.other:
        return 'بلاغات أخرى';
    }
  }

  void _showSimpleFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'تحديد أنواع البلاغات',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: ReportType.values.map((type) {
                        final isActive = _activeFilters.contains(type);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isActive 
                                ? _getReportColor(type).withOpacity(0.1)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive 
                                  ? _getReportColor(type)
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: CheckboxListTile(
                            title: Row(
                              children: [
                                Icon(
                                  _getReportIcon(type),
                                  color: _getReportColor(type),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getReportTypeTitle(type),
                                    style: TextStyle(
                                      fontWeight: isActive 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                      color: isActive 
                                          ? _getReportColor(type)
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              _getReportTypeDescription(type),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            value: isActive,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _activeFilters.add(type);
                                } else {
                                  _activeFilters.remove(type);
                                }
                              });
                            },
                            activeColor: _getReportColor(type),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _activeFilters.clear();
                              _activeFilters.addAll(ReportType.values);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('الكل'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            _applySimpleFilters();
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('تطبيق الفلاتر'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _applySimpleFilters() {
    // Apply filters to reports
    debugPrint('Applied filters: ${_activeFilters.length} types selected');
  }

  Color _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return const Color(0xFFDC2626); // Red
      case ReportType.jam:
        return const Color(0xFFEA580C); // Orange
      case ReportType.carBreakdown:
        return const Color(0xFFD97706); // Amber
      case ReportType.bump:
        return const Color(0xFF7C3AED); // Purple
      case ReportType.closedRoad:
        return const Color(0xFFB91C1C); // Dark Red
      case ReportType.hazard:
        return const Color(0xFFC2410C); // Orange-Red
      case ReportType.police:
        return const Color(0xFF2563EB); // Blue
      case ReportType.traffic:
        return const Color(0xFFEA580C); // Orange
      case ReportType.other:
        return const Color(0xFF6B7280); // Gray
    }
  }

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return Icons.car_crash;
      case ReportType.jam:
        return Icons.traffic;
      case ReportType.carBreakdown:
        return Icons.build;
      case ReportType.bump:
        return Icons.speed;
      case ReportType.closedRoad:
        return Icons.block;
      case ReportType.hazard:
        return Icons.warning;
      case ReportType.police:
        return Icons.local_police;
      case ReportType.traffic:
        return Icons.traffic;
      case ReportType.other:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapbox Map
          MapboxWidget(),

          // Back Button - محسن
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: IgnorePointer(
              ignoring: false,
              child: LiquidGlassContainer(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // Simple Filter Button - زر الفلترة في الأسفل اليسار
          Positioned(
            bottom: 100,
            left: 16,
            child: IgnorePointer(
              ignoring: false,
              child: LiquidGlassButton(
                text: 'فلترة',
                icon: Icons.filter_list,
                onPressed: _showSimpleFilterDialog,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                borderRadius: 8,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() {
            _currentBottomNavIndex = index;
          });
          // Handle navigation
        },
      ),
    );
  }

}