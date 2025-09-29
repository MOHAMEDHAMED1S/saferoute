import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import '../../providers/reports_provider.dart';
import '../../utils/map_utils.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../models/report_model.dart';
import '../../services/reports_firebase_service.dart';
import '../../services/location_service.dart';
import '../../widgets/common/bottom_navigation_widget.dart';

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
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isMapReady = false;
  Set<ReportType> _activeFilters = Set.from(ReportType.values);
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;
  int _currentBottomNavIndex = 1; // Set to 1 for "الخريطة" tab

  @override
  void initState() {
    super.initState();
    if (widget.showMarker && widget.initialLatitude != null && widget.initialLongitude != null) {
      _loadSpecificMarker();
    } else {
      _loadReportsMarkers();
    }
  }

  void _loadSpecificMarker() {
    // إنشاء علامة للموقع المحدد
    final marker = Marker(
      markerId: const MarkerId('specific_location'),
      position: LatLng(widget.initialLatitude!, widget.initialLongitude!),
      infoWindow: InfoWindow(
        title: widget.markerTitle ?? 'موقع البلاغ',
        snippet: widget.markerDescription ?? '',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    if (mounted) {
      setState(() {
        _markers = {marker};
      });
    }
  }

  void _loadReportsMarkers() async {
    // استخدام ReportsFirebaseService مباشرة للحصول على الإبلاغات
    final reportsService = ReportsFirebaseService();
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );

    // الحصول على الموقع الحالي
    final position = await locationService.getCurrentLocation();

    // الحصول على الإبلاغات القريبة من الموقع الحالي
    final reportsStream = reportsService.getReportsByLocation(
      position.latitude,
      position.longitude,
      10.0,
    );
    final reports = await reportsStream.first;

    if (mounted) {
      setState(() {
        _markers = _createMarkersFromReports(reports);
      });
    }
  }

  Set<Marker> _createMarkersFromReports(List<ReportModel> reports) {
    return reports.where((report) => _activeFilters.contains(report.type)).map((
      report,
    ) {
      return Marker(
        markerId: MarkerId(report.id),
        position: LatLng(report.location.lat, report.location.lng),
        infoWindow: InfoWindow(
          title: _getReportTypeNameArabic(report.type),
          snippet: report.description.length > 50
              ? '${report.description.substring(0, 50)}...'
              : report.description,
          onTap: () => _showReportDetails(report),
        ),
        icon: _getMarkerIcon(report.type),
        onTap: () {
          // تحريك الخريطة لمركز الإبلاغ
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(report.location.lat, report.location.lng),
              16.0,
            ),
          );
        },
      );
    }).toSet();
  }

  // دالة لعرض تفاصيل الإبلاغ في نافذة منبثقة
  void _showReportDetails(ReportModel report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              _getReportTypeIcon(report.type),
              color: _getReportTypeColor(report.type),
            ),
            const SizedBox(width: 8),
            Text(_getReportTypeNameArabic(report.type)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report.description, style: LiquidGlassTheme.bodyTextStyle),
              const SizedBox(height: 16),
              Text(
                'تم الإبلاغ في: ${_formatDate(report.createdAt)}',
                style: LiquidGlassTheme.bodyTextStyle.copyWith(
                  color: LiquidGlassTheme.getTextColor('secondary'),
                  fontSize: 12,
                ),
              ),
              if (report.imageUrls != null && report.imageUrls!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('الصور المرفقة:'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: report.imageUrls!.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showFullImage(report.imageUrls![index]),
                        child: Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(report.imageUrls![index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // دالة لعرض الصورة بالحجم الكامل
  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Image.network(imageUrl),
        ),
      ),
    );
  }

  // دالة لتنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  // دالة للحصول على اسم نوع الإبلاغ بالعربية
  String _getReportTypeNameArabic(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return 'حادث';
      case ReportType.jam:
        return 'ازدحام';
      case ReportType.carBreakdown:
        return 'عطل سيارة';
      case ReportType.bump:
        return 'مطب';
      case ReportType.closedRoad:
        return 'طريق مغلق';
      case ReportType.hazard:
        return 'خطر';
      case ReportType.police:
        return 'شرطة';
      case ReportType.traffic:
        return 'إشارة مرور';
      case ReportType.other:
        return 'أخرى';
    }
  }

  // دالة للحصول على أيقونة نوع الإبلاغ
  IconData _getReportTypeIcon(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return Icons.car_crash;
      case ReportType.jam:
        return Icons.traffic;
      case ReportType.carBreakdown:
        return Icons.car_repair;
      case ReportType.bump:
        return Icons.speed_sharp;
      case ReportType.closedRoad:
        return Icons.block;
      case ReportType.hazard:
        return Icons.warning;
      case ReportType.police:
        return Icons.local_police;
      case ReportType.traffic:
        return Icons.traffic;
      case ReportType.other:
        return Icons.help;
    }
  }

  // دالة للحصول على لون نوع الإبلاغ
  Color _getReportTypeColor(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return Colors.red;
      case ReportType.jam:
        return Colors.orange;
      case ReportType.carBreakdown:
        return Colors.yellow;
      case ReportType.bump:
        return Colors.blue;
      case ReportType.closedRoad:
        return Colors.purple;
      case ReportType.hazard:
        return Colors.deepPurple;
      case ReportType.police:
        return Colors.cyan;
      case ReportType.traffic:
        return Colors.green;
      case ReportType.other:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  BitmapDescriptor _getMarkerIcon(ReportType reportType) {
    // استخدام أيقونات مختلفة حسب نوع التقرير
    switch (reportType) {
      case ReportType.accident:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case ReportType.jam:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case ReportType.carBreakdown:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        );
      case ReportType.bump:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case ReportType.closedRoad:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueMagenta,
        );
      case ReportType.hazard:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
      case ReportType.police:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case ReportType.traffic:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case ReportType.other:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
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
        // استخدام Geolocator للحصول على الموقع الحالي
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        final cameraUpdate = CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.0,
        );

        await MapUtils.animateCameraSafely(_mapController, cameraUpdate);

        // إضافة علامة للموقع الحالي
        setState(() {
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: const InfoWindow(title: 'موقعك الحالي'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
          );
        });
      } catch (e) {
        debugPrint('فشل في الانتقال للموقع الحالي: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحديد الموقع الحالي: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // عرض مربع حوار التصفية
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية التقارير', textAlign: TextAlign.center),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ReportType.values.map((type) {
              final String typeName = _getReportTypeNameArabic(type);

              return CheckboxListTile(
                title: Text(typeName),
                value: _activeFilters.contains(type),
                activeColor: LiquidGlassTheme.getGradientByName(
                  'primary',
                ).colors.first,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _activeFilters.add(type);
                    } else {
                      _activeFilters.remove(type);
                    }
                  });
                  _refreshMarkers();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _activeFilters = Set.from(ReportType.values);
              });
              _refreshMarkers();
              Navigator.pop(context);
            },
            child: const Text('عرض الكل'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // تحديث العلامات على الخريطة
  void _refreshMarkers() {
    final reportsProvider = Provider.of<ReportsProvider>(
      context,
      listen: false,
    );
    setState(() {
      _markers = _createMarkersFromReports(reportsProvider.activeReports);
    });
  }

  // البحث عن موقع
  void _searchLocation(String query) async {
    // تنفيذ البحث عن الموقع
    if (query.isEmpty) return;

    try {
      // استخدام Google Places API للبحث
      final places = await PlacesAutocomplete.show(
        context: context,
        apiKey: 'AIzaSyBQrCVkbnaB8FQms55ZW5GUVGz52iXnOYw',
        mode: Mode.overlay,
        language: 'ar',
        types: [],
        strictbounds: false,
        components: [Component(Component.country, 'eg')],
        onError: (err) {
          debugPrint('خطأ في البحث: $err');
        },
      );

      if (places != null) {
        // الحصول على تفاصيل المكان المحدد
        final placeId = places.placeId;
        final details = await GoogleMapsPlaces(
          apiKey: 'AIzaSyBQrCVkbnaB8FQms55ZW5GUVGz52iXnOYw',
        ).getDetailsByPlaceId(placeId!);

        final lat = details.result.geometry!.location.lat;
        final lng = details.result.geometry!.location.lng;

        if (_mapController != null) {
          final cameraUpdate = CameraUpdate.newLatLngZoom(
            LatLng(lat, lng),
            15.0,
          );
          await MapUtils.animateCameraSafely(_mapController, cameraUpdate);
        }
      }
    } catch (e) {
      debugPrint('خطأ في البحث: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء البحث: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: LiquidGlassTheme.backgroundColor,
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن موقع...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.black),
                onSubmitted: _searchLocation,
                autofocus: true,
              )
            : const Text(
                'الخريطة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: _isSearchVisible
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearchVisible = false;
                    _searchController.clear();
                  });
                },
              )
            : null,
        actions: [
          // زر البحث
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.search_off : Icons.search,
              color: LiquidGlassTheme.getIconColor('primary'),
            ),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
              });
            },
            tooltip: 'بحث',
          ),
          // زر تصفية التقارير
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: LiquidGlassTheme.getIconColor('primary'),
            ),
            onPressed: _showFilterDialog,
            tooltip: 'تصفية التقارير',
          ),
        ],
      ),
      body: Stack(
        children: [
          // الخريطة الأساسية
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: (widget.initialLatitude != null && widget.initialLongitude != null)
                  ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
                  : MapUtils.defaultLocation,
              zoom: (widget.initialLatitude != null && widget.initialLongitude != null)
                  ? 16.0
                  : MapUtils.defaultZoom,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
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
                      final filteredCount = reportsProvider.reports
                          .where(
                            (report) => _activeFilters.contains(report.type),
                          )
                          .length;
                      return Text(
                        '$filteredCount تقرير',
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
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton(
                onPressed: _animateToCurrentLocation,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.my_location,
                  color: LiquidGlassTheme.getIconColor('primary'),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          if (index != _currentBottomNavIndex) {
            // Navigate based on the selected tab
            switch (index) {
              case 0: // الرئيسية
                Navigator.pushReplacementNamed(context, '/dashboard');
                break;
              case 1: // الخريطة
                // Already on map screen, do nothing
                break;
              case 2: // إبلاغ
                Navigator.pushNamed(context, '/report');
                break;
              case 3: // المجتمع
                Navigator.pushNamed(context, '/community');
                break;
              case 4: // الملف الشخصي
                Navigator.pushNamed(context, '/profile');
                break;
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
