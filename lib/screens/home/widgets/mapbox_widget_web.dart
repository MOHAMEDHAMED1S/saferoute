import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import '../../../models/report_model.dart';
import '../../../config/mapbox_config.dart';
import '../../../providers/reports_provider.dart';
import '../../../providers/dashboard_provider.dart';

class MapboxWidget extends StatefulWidget {
  const MapboxWidget({super.key});

  @override
  State<MapboxWidget> createState() => _MapboxWidgetState();
}

class _MapboxWidgetState extends State<MapboxWidget> {
  late html.DivElement _mapElement;
  String _viewType = 'mapbox-map-${DateTime.now().millisecondsSinceEpoch}';
  js.JsObject? _map;
  bool _isMapInitialized = false;
  List<ReportModel> _currentReports = [];
  final List<js.JsObject> _markers = [];
  bool _userLocationFound = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    // Create the map container element
    _mapElement = html.DivElement()
      ..id = 'mapbox-map-${DateTime.now().millisecondsSinceEpoch}'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.borderRadius = '12px';

    // Register the view factory
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        // Initialize Mapbox map when the element is ready
        _initMapboxGL();
        return _mapElement;
      },
    );
  }

  void _initMapboxGL() {
    // Wait for the element to be attached to DOM
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_isDisposed) return;
      
      try {
        // Check if Mapbox GL JS is loaded
        if (js.context['mapboxgl'] == null) {
          if (kDebugMode) {
            print('Mapbox GL JS not loaded. Please check if the script is included in index.html');
          }
          return;
        }

        // Set Mapbox access token
        js.context['mapboxgl']['accessToken'] = MapboxConfig.accessToken;

        // Create map instance with optimized settings for faster loading
        final mapOptions = js.JsObject.jsify({
          'container': _mapElement.id,
          'style': MapboxConfig.defaultStyle,
          'center': [39.8283, 21.3891], // Default to Mecca coordinates
          'zoom': 12,
          'attributionControl': false,
          'logoPosition': 'bottom-left',
          'preserveDrawingBuffer': true,
          'antialias': false, // Disable antialiasing for better performance
          'optimizeForTerrain': true,
        });

        _map = js.JsObject(js.context['mapboxgl']['Map'], [mapOptions]);

        // Add navigation controls
        final navControl = js.JsObject(js.context['mapboxgl']['NavigationControl']);
        _map!.callMethod('addControl', [navControl, 'top-right']);

        // Add geolocate control with auto-trigger
        final geolocateControl = js.JsObject(js.context['mapboxgl']['GeolocateControl'], [
          js.JsObject.jsify({
            'positionOptions': {
              'enableHighAccuracy': true,
              'timeout': 10000,
              'maximumAge': 60000
            },
            'trackUserLocation': true,
            'showUserHeading': true,
            'showAccuracyCircle': true
          })
        ]);
        _map!.callMethod('addControl', [geolocateControl, 'top-right']);

        // Add map load event listener with proper JS interop
        _map!.callMethod('on', ['load', js.allowInterop((js.JsObject event) {
          if (_isDisposed) return;
          if (kDebugMode) {
            print('Mapbox map loaded successfully');
          }
          if (mounted) {
            setState(() {
              _isMapInitialized = true;
            });
          }
          
          // Automatically trigger geolocation
          _getUserLocation();
          
          // Load reports after map is ready with shorter delay
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && !_isDisposed) {
          _loadReports();
            }
          });
        })]);

        // Add geolocate events with proper error handling
        geolocateControl.callMethod('on', ['geolocate', js.allowInterop((js.JsObject position) {
          if (_isDisposed) return;
          try {
            final coords = position['coords'];
              final lat = coords['latitude'];
              final lng = coords['longitude'];
            if (lat != null && lng != null) {
              if (kDebugMode) {
                print('User location found: $lat, $lng');
              }
              if (mounted) {
                setState(() {
                  _userLocationFound = true;
                });
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error processing geolocate event: $e');
            }
          }
        })]);

        geolocateControl.callMethod('on', ['error', js.allowInterop((js.JsObject error) {
          if (_isDisposed) return;
          if (kDebugMode) {
            print('Geolocation error: ${error['message'] ?? error.toString()}');
          }
        })]);

        // Add click event listener with proper JS interop
        _map!.callMethod('on', ['click', js.allowInterop((js.JsObject event) {
          if (_isDisposed) return;
          if (kDebugMode) {
            print('Map clicked at: ${event['lngLat']}');
          }
        })]);

      } catch (e) {
        if (kDebugMode) {
          print('Error initializing Mapbox: $e');
        }
      }
    });
  }

  void _getUserLocation() {
    if (_isDisposed) return;
    
    try {
      // Use HTML5 Geolocation API to get user location
      final geolocation = html.window.navigator.geolocation;
        geolocation.getCurrentPosition().then((html.Geoposition position) {
          if (_isDisposed || !mounted) return;
          
          final lat = position.coords?.latitude;
          final lng = position.coords?.longitude;
          
          if (lat != null && lng != null && _map != null) {
            // Center map on user location
            _map!.callMethod('flyTo', [
              js.JsObject.jsify({
                'center': [lng, lat],
                'zoom': 15,
                'duration': 2000
              })
            ]);
            
            if (mounted) {
              setState(() {
                _userLocationFound = true;
              });
            }
            
            if (kDebugMode) {
              print('User location: $lat, $lng');
            }
          }
        }).catchError((error) {
          if (kDebugMode) {
            print('Geolocation error: $error');
          }
        });
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user location: $e');
      }
    }
  }

  void _loadReports() {
    if (!_isMapInitialized || _map == null || _isDisposed) return;

    try {
      if (!mounted) return;
      
      final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
      
      if (kDebugMode) {
        print('Loading reports - Current reports count: ${reportsProvider.reports.length}');
        print('Nearby reports count: ${reportsProvider.nearbyReports.length}');
      }
      
      // If reports are already loaded, update map immediately
      if (reportsProvider.reports.isNotEmpty) {
        if (kDebugMode) {
          print('Reports already loaded, updating map immediately');
        }
        _updateReportsOnMap();
      } else if (!reportsProvider.isLoading) {
        // Initialize reports provider asynchronously without blocking UI
        if (kDebugMode) {
          print('Initializing reports provider...');
        }
        reportsProvider.initialize().then((_) {
          if (mounted && !_isDisposed) {
            if (kDebugMode) {
              print('Reports provider initialized. Reports count: ${reportsProvider.reports.length}');
            }
            _updateReportsOnMap();
          }
        }).catchError((error) {
          if (kDebugMode) {
            print('Error initializing reports provider: $error');
          }
        });
      }

      // Listen to reports changes
      reportsProvider.addListener(_updateReportsOnMap);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading reports: $e');
      }
    }
  }

  void _updateReportsOnMap() {
    if (!_isMapInitialized || _map == null || _isDisposed || !mounted) return;

    try {
      final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
      
      // Get reports - prioritize nearby reports if available
      List<ReportModel> reports = [];
      if (reportsProvider.nearbyReports.isNotEmpty) {
        reports = reportsProvider.nearbyReports;
        if (kDebugMode) {
          print('Using nearby reports: ${reports.length}');
        }
      } else if (reportsProvider.reports.isNotEmpty) {
        // Filter for active reports only
        reports = reportsProvider.reports
            .where((report) => report.status == ReportStatus.active)
            .toList();
        if (kDebugMode) {
          print('Using all active reports: ${reports.length}');
        }
      } else {
        // Try to get reports from dashboard provider as fallback
        try {
          final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
          if (dashboardProvider.nearbyReports.isNotEmpty) {
            // Convert NearbyReport to ReportModel for display
            reports = dashboardProvider.nearbyReports.map((nearbyReport) {
              return ReportModel(
                id: nearbyReport.id,
                type: nearbyReport.type,
                description: nearbyReport.description,
                location: ReportLocation(
                  lat: nearbyReport.latitude,
                  lng: nearbyReport.longitude,
                ),
                createdBy: 'unknown',
                createdAt: DateTime.now(),
                expiresAt: DateTime.now().add(Duration(hours: 2)),
                status: ReportStatus.active,
                confirmations: ReportConfirmations(
                  trueVotes: nearbyReport.confirmations,
                  falseVotes: 0,
                ),
                confirmedBy: [],
                deniedBy: [],
              );
            }).toList();
            if (kDebugMode) {
              print('Using dashboard reports: ${reports.length}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error getting dashboard reports: $e');
          }
        }
      }

      // Clear existing markers
      _clearReportMarkers();

      // Add new markers
      for (final report in reports) {
        _addReportMarker(report);
      }

      _currentReports = reports;
      if (mounted) {
        setState(() {});
      }
      
      if (kDebugMode) {
        print('Updated ${reports.length} reports on map');
        for (var report in reports) {
          print('Report: ${report.type.displayName} at ${report.location.lat}, ${report.location.lng}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating reports on map: $e');
      }
    }
  }

  void _clearReportMarkers() {
    // Remove all existing markers
    for (final marker in _markers) {
      try {
        marker.callMethod('remove');
      } catch (e) {
        if (kDebugMode) {
          print('Error removing marker: $e');
        }
      }
    }
    _markers.clear();
  }

  void _addReportMarker(ReportModel report) {
    if (_isDisposed) return;
    
    try {
      // Create marker element with professional design
      final markerElement = html.DivElement()
        ..className = 'report-marker'
        ..style.width = '48px'
        ..style.height = '48px'
        ..style.borderRadius = '50%'
        ..style.border = '3px solid white'
        ..style.cursor = 'pointer'
        ..style.display = 'flex'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..style.backgroundColor = _getReportColor(report.type)
        ..style.boxShadow = '0 4px 12px rgba(0,0,0,0.3), 0 0 0 2px ${_getReportColor(report.type)}30'
        ..style.transition = 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)'
        ..style.position = 'relative';
      markerElement.appendHtml(_getReportIconSVG(report.type), treeSanitizer: html.NodeTreeSanitizer.trusted);

      // Add pulse animation
      final pulseElement = html.DivElement()
        ..style.position = 'absolute'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.borderRadius = '50%'
        ..style.backgroundColor = _getReportColor(report.type)
        ..style.opacity = '0.3'
        ..style.animation = 'pulse 2s infinite'
        ..style.pointerEvents = 'none';
      
      markerElement.append(pulseElement);

      // Add hover effects
      markerElement.onMouseEnter.listen((_) {
        if (!_isDisposed) {
          markerElement.style.transform = 'scale(1.15)';
          markerElement.style.boxShadow = '0 8px 20px rgba(0,0,0,0.4), 0 0 0 4px ${_getReportColor(report.type)}50';
        }
      });

      markerElement.onMouseLeave.listen((_) {
        if (!_isDisposed) {
          markerElement.style.transform = 'scale(1.0)';
          markerElement.style.boxShadow = '0 4px 12px rgba(0,0,0,0.3), 0 0 0 2px ${_getReportColor(report.type)}30';
        }
      });

      // Create marker
      final marker = js.JsObject(js.context['mapboxgl']['Marker'], [
        js.JsObject.jsify({'element': markerElement})
      ]);

      // Set marker position
      marker.callMethod('setLngLat', [
        js.JsArray.from([report.location.lng, report.location.lat])
      ]);

      // Add marker to map
      marker.callMethod('addTo', [_map]);

      // Store marker reference
      _markers.add(marker);

      // Add click event for popup with proper event handling
      markerElement.onClick.listen((_) {
        if (!_isDisposed) {
          _showReportPopup(report);
        }
      });

      if (kDebugMode) {
        print('Added marker for report: ${report.type.displayName} at ${report.location.lat}, ${report.location.lng}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error adding report marker: $e');
      }
    }
  }

  String _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return '#DC2626'; // Professional Red - حوادث
      case ReportType.jam:
        return '#EA580C'; // Professional Orange - ازدحام
      case ReportType.carBreakdown:
        return '#D97706'; // Professional Amber - عطل
      case ReportType.bump:
        return '#7C3AED'; // Professional Purple - مطب
      case ReportType.closedRoad:
        return '#B91C1C'; // Professional Dark Red - طريق مغلق
      case ReportType.hazard:
        return '#C2410C'; // Professional Orange-Red - خطر
      case ReportType.police:
        return '#2563EB'; // Professional Blue - شرطة
      case ReportType.traffic:
        return '#EA580C'; // Professional Orange - مرور
      case ReportType.other:
        return '#6B7280'; // Professional Gray - أخرى
    }
  }


  String _getReportIconSVG(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return '''
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M12 2L13.09 8.26L22 9L13.09 9.74L12 16L10.91 9.74L2 9L10.91 8.26L12 2Z" fill="white"/>
            <path d="M8 12L10 14L16 8" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        ''';
      case ReportType.jam:
        return '''
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect x="3" y="8" width="18" height="8" rx="2" fill="white"/>
            <circle cx="7" cy="12" r="1.5" fill="#333"/>
            <circle cx="17" cy="12" r="1.5" fill="#333"/>
            <path d="M6 8V6C6 4.5 7.5 3 9 3H15C16.5 3 18 4.5 18 6V8" stroke="white" stroke-width="2"/>
          </svg>
        ''';
      case ReportType.carBreakdown:
        return '''
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M14.5 4H9.5L8 6H4C2.9 6 2 6.9 2 8V16C2 17.1 2.9 18 4 18H5C5.6 18 6 17.6 6 17V16H18V17C18 17.6 18.4 18 19 18H20C21.1 18 22 17.1 22 16V8C22 6.9 21.1 6 20 6H16L14.5 4Z" fill="white"/>
            <circle cx="6.5" cy="13.5" r="1.5" fill="#333"/>
            <circle cx="17.5" cy="13.5" r="1.5" fill="#333"/>
          </svg>
        ''';
      case ReportType.bump:
        return '''
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M3 12H21M3 12L7 8M3 12L7 16M21 12L17 8M21 12L17 16" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M6 9H8V15H6V9Z" fill="white"/>
            <path d="M16 9H18V15H16V9Z" fill="white"/>
          </svg>
        ''';
      case ReportType.closedRoad:
        return '''
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect x="3" y="6" width="18" height="12" rx="2" fill="white"/>
            <path d="M8 6V4C8 2.9 8.9 2 10 2H14C15.1 2 16 2.9 16 4V6" stroke="white" stroke-width="2"/>
            <path d="M9 10H15M9 14H15" stroke="#333" stroke-width="2" stroke-linecap="round"/>
          </svg>
        ''';
      case ReportType.hazard:
        return '''
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M12 2L2 20H22L12 2Z" fill="white"/>
            <path d="M12 8V12M12 16H12.01" stroke="#333" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        ''';
      case ReportType.police:
        return '''
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <circle cx="12" cy="8" r="4" fill="white"/>
            <path d="M8 21V19C8 17.9 8.9 17 10 17H14C15.1 17 16 17.9 16 19V21" stroke="white" stroke-width="2"/>
            <path d="M10 8H14" stroke="#333" stroke-width="2" stroke-linecap="round"/>
          </svg>
        ''';
      case ReportType.traffic:
        return '''
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect x="9" y="2" width="6" height="20" rx="3" fill="white"/>
            <circle cx="12" cy="6" r="2" fill="#E53E3E"/>
            <circle cx="12" cy="12" r="2" fill="#F6AD55"/>
            <circle cx="12" cy="18" r="2" fill="#4CAF50"/>
          </svg>
        ''';
      case ReportType.other:
        return '''
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M21 10C21 17 12 23 12 23S3 17 3 10C3 7.6 4.6 5.6 7 5.6C8.7 5.6 10.1 6.5 12 8.1C13.9 6.5 15.3 5.6 17 5.6C19.4 5.6 21 7.6 21 10Z" fill="white"/>
            <path d="M12 13C13.1 13 14 12.1 14 11C14 9.9 13.1 9 12 9C10.9 9 10 9.9 10 11C10 12.1 10.9 13 12 13Z" fill="#333"/>
          </svg>
        ''';
    }
  }


  void _showReportPopup(ReportModel report) {
    if (_isDisposed) return;
    
    try {
      // Create professional popup content
      final popupContent = '''
        <div style="
          padding: 0; 
          min-width: 360px; 
          max-width: 420px;
          font-family: 'Inter', 'Cairo', -apple-system, BlinkMacSystemFont, sans-serif; 
          direction: rtl;
          background: #ffffff;
          border-radius: 16px;
          box-shadow: 0 20px 40px rgba(0,0,0,0.1), 0 0 0 1px rgba(0,0,0,0.05);
          overflow: hidden;
        ">
          <!-- Header with gradient -->
          <div style="
            background: linear-gradient(135deg, ${_getReportColor(report.type)}, ${_getReportColor(report.type)}dd);
            padding: 20px;
            color: white;
            position: relative;
          ">
            <div style="
              display: flex; 
              align-items: center; 
              gap: 12px;
            ">
              <div style="
                width: 48px; 
                height: 48px; 
                border-radius: 12px; 
                background: rgba(255,255,255,0.2);
                backdrop-filter: blur(10px);
                display: flex; 
                align-items: center; 
                justify-content: center;
                box-shadow: 0 4px 12px rgba(0,0,0,0.2);
              ">
                ${_getReportIconSVG(report.type)}
              </div>
              <div style="flex: 1;">
                <h3 style="
                  margin: 0; 
                  font-size: 18px;
                  font-weight: 700;
                  letter-spacing: -0.5px;
                ">
                  ${report.type.displayName}
          </h3>
                <p style="
                  margin: 4px 0 0 0; 
                  font-size: 13px; 
                  opacity: 0.9;
                  font-weight: 500;
                ">
                  ${_formatDate(report.createdAt)}
                </p>
              </div>
            </div>
          </div>

          <!-- Content -->
          <div style="padding: 20px;">
            <!-- Description -->
            <div style="margin-bottom: 20px;">
              <h4 style="
                margin: 0 0 8px 0; 
                font-size: 14px; 
                color: #374151;
                font-weight: 600;
                letter-spacing: -0.2px;
              ">الوصف</h4>
              <div style="
                background: #f8fafc;
                padding: 12px 16px;
                border-radius: 8px;
                border-right: 4px solid ${_getReportColor(report.type)};
                font-size: 14px; 
                color: #4b5563;
                line-height: 1.6;
              ">${report.description}</div>
            </div>

            <!-- Status Cards -->
            <div style="
              display: grid; 
              grid-template-columns: 1fr 1fr; 
              gap: 12px; 
              margin-bottom: 20px;
            ">
              <div style="
                background: ${report.status == ReportStatus.active ? '#f0fdf4' : '#fef2f2'};
                border: 1px solid ${report.status == ReportStatus.active ? '#bbf7d0' : '#fecaca'};
                padding: 12px;
                border-radius: 8px;
                text-align: center;
              ">
                <div style="
                  font-size: 11px; 
                  color: ${report.status == ReportStatus.active ? '#166534' : '#991b1b'};
                  font-weight: 600;
                  text-transform: uppercase;
                  letter-spacing: 0.5px;
                ">الحالة</div>
                <div style="
                  font-size: 13px; 
                  color: ${report.status == ReportStatus.active ? '#166534' : '#991b1b'};
                  margin-top: 4px;
                  font-weight: 600;
                ">${report.status == ReportStatus.active ? 'نشط' : 'منتهي الصلاحية'}</div>
              </div>
              
              <div style="
                background: #eff6ff;
                border: 1px solid #bfdbfe;
                padding: 12px;
                border-radius: 8px;
                text-align: center;
              ">
                <div style="
                  font-size: 11px; 
                  color: #1e40af;
                  font-weight: 600;
                  text-transform: uppercase;
                  letter-spacing: 0.5px;
                ">المدة المتبقية</div>
                <div style="
                  font-size: 13px; 
                  color: #1e40af;
                  margin-top: 4px;
                  font-weight: 600;
                ">${report.expiresAt != null ? _formatDate(report.expiresAt!) : 'غير محدد'}</div>
              </div>
            </div>

            <!-- Voting Stats -->
            <div style="
              display: flex; 
              gap: 12px; 
              margin-bottom: 20px;
            ">
              <div style="
                flex: 1;
                background: linear-gradient(135deg, #10b981, #059669);
                color: white; 
                padding: 12px 16px; 
                border-radius: 8px; 
                display: flex; 
                align-items: center; 
                gap: 8px;
                box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
              ">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                  <path d="M9 12L11 14L15 10M21 12C21 16.9706 16.9706 21 12 21C7.02944 21 3 16.9706 3 12C3 7.02944 7.02944 3 12 3C16.9706 3 21 7.02944 21 12Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                <div>
                  <div style="font-size: 16px; font-weight: 700;">${report.confirmations?.trueVotes ?? 0}</div>
                  <div style="font-size: 11px; opacity: 0.9;">تأكيد</div>
                </div>
              </div>
              <div style="
                flex: 1;
                background: linear-gradient(135deg, #ef4444, #dc2626);
                color: white; 
                padding: 12px 16px; 
                border-radius: 8px; 
                display: flex; 
                align-items: center; 
                gap: 8px;
                box-shadow: 0 4px 12px rgba(239, 68, 68, 0.3);
              ">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                  <path d="M6 18L18 6M6 6L18 18" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                <div>
                  <div style="font-size: 16px; font-weight: 700;">${report.confirmations?.falseVotes ?? 0}</div>
                  <div style="font-size: 11px; opacity: 0.9;">رفض</div>
                </div>
              </div>
            </div>

            <!-- Location Info -->
            <div style="
              background: #f8fafc;
              border: 1px solid #e2e8f0;
              padding: 12px 16px;
              border-radius: 8px;
              margin-bottom: 20px;
            ">
              <div style="
                font-size: 11px; 
                color: #64748b;
                font-weight: 600;
                text-transform: uppercase;
                letter-spacing: 0.5px;
                margin-bottom: 4px;
              ">الموقع</div>
              <div style="
                font-size: 13px; 
                color: #334155;
                font-weight: 500;
                font-family: 'Monaco', 'Menlo', monospace;
              ">${report.location.lat.toStringAsFixed(6)}, ${report.location.lng.toStringAsFixed(6)}</div>
            </div>

            <!-- Action Buttons -->
            <div style="
              display: flex; 
              gap: 12px;
            ">
              <button style="
                flex: 1;
                background: linear-gradient(135deg, ${_getReportColor(report.type)}, ${_getReportColor(report.type)}dd);
                color: white;
                border: none;
                padding: 12px 16px;
                border-radius: 8px;
                font-size: 13px;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.2s ease;
                box-shadow: 0 2px 8px ${_getReportColor(report.type)}40;
              " onmouseover="this.style.transform='translateY(-1px)'; this.style.boxShadow='0 4px 12px ${_getReportColor(report.type)}60'" onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='0 2px 8px ${_getReportColor(report.type)}40'">
                عرض التفاصيل
              </button>
              <button style="
                flex: 1;
                background: #6b7280;
                color: white;
                border: none;
                padding: 12px 16px;
                border-radius: 8px;
                font-size: 13px;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.2s ease;
                box-shadow: 0 2px 8px rgba(107, 114, 128, 0.3);
              " onmouseover="this.style.transform='translateY(-1px)'; this.style.boxShadow='0 4px 12px rgba(107, 114, 128, 0.4)'" onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='0 2px 8px rgba(107, 114, 128, 0.3)'">
                مشاركة
              </button>
            </div>
          </div>
        </div>
      ''';

      // Create popup with enhanced styling
      final popup = js.JsObject(js.context['mapboxgl']['Popup'], [
        js.JsObject.jsify({
          'closeOnClick': false,
          'closeButton': true,
          'maxWidth': '400px',
          'className': 'custom-popup',
        })
      ]);

      popup.callMethod('setLngLat', [
        js.JsArray.from([report.location.lng, report.location.lat])
      ]);
      popup.callMethod('setHTML', [popupContent]);
      popup.callMethod('addTo', [_map]);

      // Add custom CSS for popup
      _addCustomPopupCSS();

    } catch (e) {
      if (kDebugMode) {
        print('Error showing report popup: $e');
      }
    }
  }

  void _addCustomPopupCSS() {
    try {
      final style = html.StyleElement()
        ..text = '''
          @keyframes pulse {
            0% { transform: scale(1); opacity: 0.3; }
            50% { transform: scale(1.1); opacity: 0.1; }
            100% { transform: scale(1); opacity: 0.3; }
          }
          
          @keyframes fadeInUp {
            from {
              opacity: 0;
              transform: translateY(20px);
            }
            to {
              opacity: 1;
              transform: translateY(0);
            }
          }
          
          .mapboxgl-popup-content {
            padding: 0 !important;
            border-radius: 16px !important;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1), 0 0 0 1px rgba(0,0,0,0.05) !important;
            animation: fadeInUp 0.3s ease-out !important;
            overflow: hidden !important;
          }
          
          .mapboxgl-popup-tip {
            border-top-color: #ffffff !important;
            filter: drop-shadow(0 -2px 4px rgba(0,0,0,0.1)) !important;
          }
          
          .mapboxgl-popup-close-button {
            background: rgba(0,0,0,0.1) !important;
            color: #64748b !important;
            border-radius: 50% !important;
            width: 28px !important;
            height: 28px !important;
            font-size: 16px !important;
            line-height: 28px !important;
            transition: all 0.2s ease !important;
            backdrop-filter: blur(10px) !important;
          }
          
          .mapboxgl-popup-close-button:hover {
            background: rgba(0,0,0,0.2) !important;
            color: #1f2937 !important;
            transform: scale(1.1) !important;
          }
          
          .report-marker {
            animation: fadeInUp 0.4s ease-out;
          }
          
          .report-marker:hover {
            z-index: 1000 !important;
          }
        ''';
      
      if (!html.document.head!.children.any((element) => element is html.StyleElement && element.text!.contains('mapboxgl-popup-content'))) {
        html.document.head!.append(style);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding custom CSS: $e');
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    try {
      if (mounted) {
        final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
        reportsProvider.removeListener(_updateReportsOnMap);
      }
      _clearReportMarkers();
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing MapboxWidget: $e');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const SizedBox.shrink();
    }
    
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, child) {
        return Stack(
          children: [
            // Map container
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: HtmlElementView(
                  viewType: _viewType,
                ),
              ),
            ),
            // Loading indicator
            if (reportsProvider.isLoading || !_isMapInitialized)
              Positioned(
                top: 8,
                right: 8,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          !_isMapInitialized 
                              ? 'جاري تحميل الخريطة...' 
                              : 'جاري تحميل البلاغات...',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Location status
            if (_isMapInitialized && !_userLocationFound)
              Positioned(
                top: 8,
                left: 8,
                child: Card(
                  color: Colors.orange.shade100,
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_searching, color: Colors.orange, size: 12),
                        const SizedBox(width: 6),
                        const Text(
                          'جاري تحديد الموقع...',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Error message
            if (reportsProvider.errorMessage != null)
              Positioned(
                top: 8,
                right: 8,
                child: Card(
                  color: Colors.red.shade100,
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          reportsProvider.errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Reports count and status
            if (_isMapInitialized)
              Positioned(
                bottom: 8,
                right: 8,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'البلاغات: ${_currentReports.length}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        if (reportsProvider.nearbyReports.isNotEmpty)
                          Text(
                            'قريبة: ${reportsProvider.nearbyReports.length}',
                            style: TextStyle(fontSize: 8, color: Colors.green.shade700),
                          ),
                        if (_userLocationFound)
                          Text(
                            'تم تحديد الموقع ✓',
                            style: TextStyle(fontSize: 8, color: Colors.green.shade700),
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
}