import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../providers/reports_provider.dart';
import '../../models/report_model.dart';
import '../../widgets/liquid_glass_widgets.dart';

import 'widgets/mapbox_widget.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isMapReady = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isInitialized = false;
  Position? _currentPosition;
  List<ReportModel> _reports = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    // Initialize location and reports in parallel for better performance
    await Future.wait([
      _initializeLocation(),
      _loadReports(),
    ]);
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeLocation() async {
    try {
      // Skip location initialization on web as it's handled by Mapbox
      if (kIsWeb) {
        debugPrint('Skipping location initialization on web - handled by Mapbox');
        return;
      }

      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('تم رفض إذن الموقع');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('تم رفض إذن الموقع نهائياً. يرجى تفعيله من الإعدادات');
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('خدمات الموقع غير مفعلة. يرجى تفعيلها');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        debugPrint('Current position updated: ${position.latitude}, ${position.longitude}');
      }

      // Start listening to position changes
      _startLocationUpdates();
    } catch (e) {
      debugPrint('خطأ في الحصول على الموقع: $e');
      // Show error to user only on mobile platforms
      if (mounted && !kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحصول على الموقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        debugPrint('Position stream updated: ${position.latitude}, ${position.longitude}');
      }
    });
  }

  Future<void> _loadReports() async {
    try {
      final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Initialize reports provider if not already done
      if (!reportsProvider.isLoading && reportsProvider.reports.isEmpty) {
        await reportsProvider.initialize();
      }
      
      // Load user reports if authenticated
      if (authProvider.userId != null) {
        await reportsProvider.loadUserReports(authProvider.userId!);
      }
      
      if (mounted) {
        setState(() {
          _reports = reportsProvider.reports;
        });
        debugPrint('Reports loaded: ${_reports.length} reports');
      }
    } catch (e) {
      debugPrint('خطأ في تحميل التقارير: $e');
    }
  }



  // Simple filter state
  Set<ReportType> _activeFilters = Set.from(ReportType.values);

  void _showSimpleFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تحديد أنواع البلاغات'),
          content: SingleChildScrollView(
        child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ReportType.values.map((type) {
                final isActive = _activeFilters.contains(type);
                return CheckboxListTile(
                  title: Text(_getReportTypeTitle(type)),
                  subtitle: Text(_getReportTypeDescription(type)),
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
                  secondary: Icon(
                    _getReportIcon(type),
                    color: _getReportColor(type),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _activeFilters.clear();
                  _activeFilters.addAll(ReportType.values);
                });
              },
              child: const Text('الكل'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                _applySimpleFilters();
                Navigator.of(context).pop();
              },
              child: const Text('تطبيق'),
            ),
          ],
        );
      },
    );
  }

  void _applySimpleFilters() async {
    try {
      final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
      await reportsProvider.initialize();
      debugPrint('Applied filters: ${_activeFilters.length} types selected');
    } catch (e) {
      debugPrint('Error applying filters: $e');
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

  Color _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return const Color(0xFFDC2626);
      case ReportType.jam:
        return const Color(0xFFEA580C);
      case ReportType.carBreakdown:
        return const Color(0xFFD97706);
      case ReportType.bump:
        return const Color(0xFF7C3AED);
      case ReportType.closedRoad:
        return const Color(0xFFB91C1C);
      case ReportType.hazard:
        return const Color(0xFFC2410C);
      case ReportType.police:
        return const Color(0xFF2563EB);
      case ReportType.traffic:
        return const Color(0xFFEA580C);
      case ReportType.other:
        return const Color(0xFF6B7280);
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

          // Loading overlay
          if (!_isInitialized)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
            child: LiquidGlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'جاري تحميل البيانات...',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_currentPosition != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'الموقع: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ),
            ),
          ),

          // Add Report Button - زر إضافة البلاغ
          if (_isMapReady && _isInitialized)
            Positioned(
              bottom: 100,
              right: 16,
              child: IgnorePointer(
                ignoring: false,
              child: AnimatedBuilder(
                animation: _fabAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _fabAnimation.value,
                      child: LiquidGlassButton(
                          text: 'إضافة بلاغ',
                          icon: Icons.add,
                          onPressed: () {
                            Navigator.pushNamed(context, '/add-report');
                          },
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        borderRadius: 12,
                    ),
                  );
                },
              ),
              ),
            ),

          // Simple Filter Button - زر الفلترة البسيط
          if (_isMapReady && _isInitialized)
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
    );
  }
}