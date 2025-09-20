import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/report_model.dart';
import '../../../utils/map_utils.dart';

class MapWidget extends StatefulWidget {
  final Function(GoogleMapController) onMapCreated;
  final Position? currentPosition;
  final Set<Marker> markers;
  final Function(ReportModel)? onMarkerTapped;

  const MapWidget({
    Key? key,
    required this.onMapCreated,
    this.currentPosition,
    this.markers = const {},
    this.onMarkerTapped,
  }) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _controller;
  bool _isMapReady = false;

  void _onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    
    // Apply map style if available
    final mapStyle = MapUtils.getMapStyle();
    if (mapStyle != null) {
      try {
        await controller.setMapStyle(mapStyle);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to set map style: $e');
        }
      }
    }
    
    setState(() {
      _isMapReady = true;
    });
    widget.onMapCreated(controller);
    
    // Update camera position if current position is available
    if (widget.currentPosition != null) {
      final target = LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );
      final cameraUpdate = MapUtils.safeCameraUpdate(target);
      await MapUtils.animateCameraSafely(_controller, cameraUpdate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
           target: widget.currentPosition != null
               ? LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude)
               : MapUtils.defaultLocation,
           zoom: MapUtils.defaultZoom,
         ),
        markers: widget.markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: MapUtils.getMapOptions()['zoomControlsEnabled'],
         mapToolbarEnabled: MapUtils.getMapOptions()['mapToolbarEnabled'],
         compassEnabled: MapUtils.getMapOptions()['compassEnabled'],
         trafficEnabled: MapUtils.getMapOptions()['trafficEnabled'],
         buildingsEnabled: MapUtils.getMapOptions()['buildingsEnabled'],
         indoorViewEnabled: MapUtils.getMapOptions()['indoorViewEnabled'],
         mapType: MapType.normal,
         gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
         onTap: (LatLng position) {
           // Handle map tap if needed
         },
         // Platform-specific optimizations
         liteModeEnabled: MapUtils.getMapOptions()['liteModeEnabled'],
         tiltGesturesEnabled: MapUtils.getMapOptions()['tiltGesturesEnabled'],
         rotateGesturesEnabled: MapUtils.getMapOptions()['rotateGesturesEnabled'],
         scrollGesturesEnabled: MapUtils.getMapOptions()['scrollGesturesEnabled'],
         zoomGesturesEnabled: MapUtils.getMapOptions()['zoomGesturesEnabled'],
         minMaxZoomPreference: MapUtils.getMapOptions()['minMaxZoomPreference'],
      ),
    );
  }

  @override
  void dispose() {
    // Only dispose controller if map is ready to avoid Google Maps Flutter Web error
    if (_isMapReady && _controller != null) {
      _controller!.dispose();
    }
    super.dispose();
  }
}