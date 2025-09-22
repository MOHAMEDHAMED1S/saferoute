import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/reports_provider.dart';
import '../../utils/map_utils.dart';
import '../../widgets/liquid_glass_widgets.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../models/report_model.dart';

class BasicMapScreen extends StatefulWidget {
  const BasicMapScreen({Key? key}) : super(key: key);

  @override
  State<BasicMapScreen> createState() => _BasicMapScreenState();
}

class _BasicMapScreenState extends State<BasicMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _loadReportsMarkers();
  }

  void _loadReportsMarkers() async {
    final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
    await reportsProvider.initialize();
    
    if (mounted) {
      setState(() {
        _markers = _createMarkersFromReports(reportsProvider.activeReports);
      });
    }
  }

  Set<Marker> _createMarkersFromReports(List<ReportModel> reports) {
    return reports.map((report) {
      return Marker(
        markerId: MarkerId(report.id),
        position: LatLng(report.location.lat, report.location.lng),
        infoWindow: InfoWindow(
          title: report.typeNameArabic,
          snippet: report.description,
        ),
        icon: _getMarkerIcon(report.type),
      );
    }).toSet();
  }

  BitmapDescriptor _getMarkerIcon(ReportType reportType) {
    // استخدام أيقونات مختلفة حسب نوع التقرير
    switch (reportType) {
      case ReportType.accident:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case ReportType.jam:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case ReportType.carBreakdown:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case ReportType.bump:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case ReportType.closedRoad:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    
    // تطبيق نمط الخريطة إذا كان متاحاً
    final mapStyle = MapUtils.getMapStyle();
    if (mapStyle != null) {
      try {
        await controller.setMapStyle(mapStyle);
      } catch (e) {
        debugPrint('فشل في تطبيق نمط الخريطة: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        _isMapReady = true;
      });
    }
  }

  void _animateToCurrentLocation() async {
    if (_mapController != null) {
      try {
        final cameraUpdate = MapUtils.safeCameraUpdate(MapUtils.defaultLocation);
        await MapUtils.animateCameraSafely(_mapController, cameraUpdate);
      } catch (e) {
        debugPrint('فشل في الانتقال للموقع الحالي: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'الخريطة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // الخريطة الأساسية
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: MapUtils.defaultLocation,
              zoom: MapUtils.defaultZoom,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            trafficEnabled: false,
            buildingsEnabled: true,
            indoorViewEnabled: false,
            mapType: MapType.normal,
            gestureRecognizers: const {},
            onTap: (LatLng position) {
              // يمكن إضافة وظائف عند النقر على الخريطة
            },
            liteModeEnabled: false,
            tiltGesturesEnabled: false, // تبسيط للخريطة العادية
            rotateGesturesEnabled: false, // تبسيط للخريطة العادية
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            minMaxZoomPreference: const MinMaxZoomPreference(8.0, 18.0),
          ),
          
          // معلومات الخريطة
          Positioned(
            top: 20,
            left: 20,
            child: LiquidGlassContainer(
              type: LiquidGlassType.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: LiquidGlassTheme.getIconColor('primary'),
                  ),
                  const SizedBox(width: 8),
                  Consumer<ReportsProvider>(
                    builder: (context, reportsProvider, child) {
                      return Text(
                        '${reportsProvider.reports.length} تقرير',
                        style: LiquidGlassTheme.subtitleTextStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // زر الموقع الحالي
      floatingActionButton: _isMapReady
          ? LiquidGlassButton(
              text: '',
              onPressed: _animateToCurrentLocation,
              type: LiquidGlassType.secondary,
              borderRadius: 28,
              padding: const EdgeInsets.all(16),
              icon: Icons.my_location,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}