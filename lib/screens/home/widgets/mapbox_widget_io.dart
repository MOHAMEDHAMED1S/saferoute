import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../config/mapbox_config.dart';
import '../../../providers/reports_provider.dart';
import '../../../models/report_model.dart';

class MapboxWidget extends StatefulWidget {
  const MapboxWidget({Key? key}) : super(key: key);

  @override
  State<MapboxWidget> createState() => _MapboxWidgetState();
}

class _MapboxWidgetState extends State<MapboxWidget> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  geo.Position? _currentLocation;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Get current location
      await _getCurrentLocation();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'خطأ في تحميل الخريطة: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('خدمة الموقع غير مفعلة');
      }

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          throw Exception('تم رفض إذن الموقع');
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        throw Exception('تم رفض إذن الموقع نهائياً');
      }

      _currentLocation = await geo.Geolocator.getCurrentPosition();
    } catch (e) {
      throw Exception('فشل في الحصول على الموقع: ${e.toString()}');
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _setupMap();
  }

  Future<void> _setupMap() async {
    if (_mapboxMap == null) return;

    try {
      // Create point annotation manager
      _pointAnnotationManager = await _mapboxMap!.annotations.createPointAnnotationManager();
      
      // Move camera to current location
      if (_currentLocation != null) {
        await _moveCameraToLocation(_currentLocation!.latitude, _currentLocation!.longitude);
      }
      
      // Add report markers
      await _addReportMarkers();
    } catch (e) {
      debugPrint('خطأ في إعداد الخريطة: $e');
    }
  }

  Future<void> _moveCameraToLocation(double lat, double lng) async {
    if (_mapboxMap == null) return;
    
    final cameraOptions = CameraOptions(
      center: Point(coordinates: Position(lng, lat)),
      zoom: MapboxConfig.defaultZoom,
    );
    
    await _mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1000));
  }

  Future<void> _addReportMarkers() async {
    if (_pointAnnotationManager == null) return;

    final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
    final reports = reportsProvider.reports;

    List<PointAnnotationOptions> annotations = [];

    for (final report in reports) {
      final annotation = PointAnnotationOptions(
        geometry: Point(coordinates: Position(report.location.lng, report.location.lat)),
        iconImage: _getReportIcon(report.type),
        iconSize: 1.0,
        iconColor: _getReportColor(report.type).value,
      );
      annotations.add(annotation);
    }

    if (annotations.isNotEmpty) {
      await _pointAnnotationManager!.createMulti(annotations);
    }
  }

  String _getReportIcon(ReportType type) {
    // Using built-in Mapbox icons or simple shapes
    switch (type) {
      case ReportType.accident:
        return 'circle';
      case ReportType.jam:
        return 'square';
      case ReportType.carBreakdown:
        return 'triangle';
      case ReportType.bump:
        return 'diamond';
      case ReportType.closedRoad:
        return 'cross';
      case ReportType.hazard:
        return 'star';
      case ReportType.police:
        return 'shield';
      case ReportType.traffic:
        return 'hexagon';
      default:
        return 'circle';
    }
  }

  Color _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return Colors.red;
      case ReportType.jam:
        return Colors.orange;
      case ReportType.carBreakdown:
        return Colors.yellow;
      case ReportType.bump:
        return Colors.purple;
      case ReportType.closedRoad:
        return Colors.black;
      case ReportType.hazard:
        return Colors.pink;
      case ReportType.police:
        return Colors.blue;
      case ReportType.traffic:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _zoomIn() async {
    if (_mapboxMap == null) return;
    final currentCamera = await _mapboxMap!.getCameraState();
    await _mapboxMap!.setCamera(CameraOptions(zoom: (currentCamera.zoom + 1).clamp(0, 20)));
  }

  void _zoomOut() async {
    if (_mapboxMap == null) return;
    final currentCamera = await _mapboxMap!.getCameraState();
    await _mapboxMap!.setCamera(CameraOptions(zoom: (currentCamera.zoom - 1).clamp(0, 20)));
  }

  void _goToCurrentLocation() async {
    if (_currentLocation != null) {
      await _moveCameraToLocation(_currentLocation!.latitude, _currentLocation!.longitude);
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(_error, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = '';
                  _isLoading = true;
                });
                _initializeMap();
              },
              child: Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return Container(
      child: Stack(
        children: [
          // Mapbox Map
          MapWidget(
            key: ValueKey("mapWidget"),
            cameraOptions: CameraOptions(
              center: _currentLocation != null
                  ? Point(
                      coordinates: Position(
                        _currentLocation!.longitude,
                        _currentLocation!.latitude,
                      ),
                    )
                  : Point(coordinates: Position(39.8283, 21.4225)), // Mecca default
              zoom: MapboxConfig.defaultZoom,
            ),
            styleUri: MapboxConfig.defaultStyle,
            onMapCreated: _onMapCreated,
          ),
          
          // Map controls
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: _zoomIn,
                        icon: Icon(Icons.add, color: Colors.grey[700]),
                        tooltip: 'تكبير',
                      ),
                      Divider(height: 1, color: Colors.grey[300]),
                      IconButton(
                        onPressed: _zoomOut,
                        icon: Icon(Icons.remove, color: Colors.grey[700]),
                        tooltip: 'تصغير',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Current location button
          if (_currentLocation != null)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _goToCurrentLocation,
                  icon: Icon(Icons.my_location, color: Colors.blue),
                  tooltip: 'موقعي الحالي',
                ),
              ),
            ),
          
          // Reports count indicator
          Consumer<ReportsProvider>(
            builder: (context, reportsProvider, child) {
              if (reportsProvider.reports.isEmpty) return SizedBox.shrink();
              
              return Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.report_problem,
                        size: 16,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${reportsProvider.reports.length} بلاغ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pointAnnotationManager?.deleteAll();
    super.dispose();
  }
}