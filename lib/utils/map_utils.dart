import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapUtils {
  // Default map configuration
  static const LatLng defaultLocation = LatLng(30.0444, 31.2357); // Cairo, Egypt
  static const double defaultZoom = 12.0;
  static const double minZoom = 8.0;
  static const double maxZoom = 20.0;

  // Map style for better performance
  static String? getMapStyle() {
    if (kIsWeb) {
      // Simplified style for web
      return null;
    }
    
    // Custom style for mobile platforms
    return '''
    [
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "transit",
        "elementType": "labels",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      }
    ]
    ''';
  }

  // Platform-specific map options
  static Map<String, dynamic> getMapOptions() {
    return {
      'myLocationEnabled': true,
      'myLocationButtonEnabled': false,
      'zoomControlsEnabled': !kIsWeb,
      'mapToolbarEnabled': false,
      'compassEnabled': !kIsWeb, // Disable compass on web for better performance
      'trafficEnabled': false,
      'buildingsEnabled': true, // Enable buildings for better Android performance
      'indoorViewEnabled': false,
      'liteModeEnabled': false, // Disable lite mode for Android compatibility
      'tiltGesturesEnabled': true, // Enable tilt for Android
      'rotateGesturesEnabled': true, // Enable rotation for Android
      'scrollGesturesEnabled': true,
      'zoomGesturesEnabled': true,
      'minMaxZoomPreference': MinMaxZoomPreference(minZoom, maxZoom),
    };
  }

  // Camera update with bounds checking
  static CameraUpdate safeCameraUpdate(LatLng target, {double? zoom}) {
    final safeZoom = zoom?.clamp(minZoom, maxZoom) ?? defaultZoom;
    return CameraUpdate.newLatLngZoom(target, safeZoom);
  }

  // Animate camera with error handling
  static Future<void> animateCameraSafely(
    GoogleMapController? controller,
    CameraUpdate cameraUpdate,
  ) async {
    if (controller == null) return;
    
    try {
      await controller.animateCamera(cameraUpdate);
    } catch (e) {
      // Fallback to move camera if animation fails
      try {
        await controller.moveCamera(cameraUpdate);
      } catch (e) {
        // Ignore if both fail
        if (kDebugMode) {
          print('Camera update failed: $e');
        }
      }
    }
  }

  // Calculate distance between two points
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters
    final double lat1Rad = point1.latitude * (3.14159265359 / 180);
    final double lat2Rad = point2.latitude * (3.14159265359 / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    final double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Check if location is within Egypt bounds (approximate)
  static bool isLocationInEgypt(LatLng location) {
    const double minLat = 22.0;
    const double maxLat = 31.7;
    const double minLng = 25.0;
    const double maxLng = 35.0;

    return location.latitude >= minLat &&
           location.latitude <= maxLat &&
           location.longitude >= minLng &&
           location.longitude <= maxLng;
  }
}