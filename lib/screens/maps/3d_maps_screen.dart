import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/common/enhanced_ui_components.dart';
import '../../utils/responsive_utils.dart';

import 'dart:async';
import 'dart:math' as math;

class Maps3DScreen extends StatefulWidget {
  const Maps3DScreen({Key? key}) : super(key: key);

  @override
  State<Maps3DScreen> createState() => _Maps3DScreenState();
}

class _Maps3DScreenState extends State<Maps3DScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;
  
  bool _isLoading = false;
  bool _is3DEnabled = true;
  bool _showTraffic = true;
  bool _showBuildings = true;
  bool _showTerrain = false;
  double _mapZoom = 15.0;
  double _mapTilt = 45.0;
  double _mapBearing = 0.0;
  
  String _selectedMapType = 'satellite';

  
  final List<Map<String, dynamic>> _mapLayers = [
    {
      'id': 'traffic',
      'name': 'حركة المرور',
      'icon': Icons.traffic,
      'color': Colors.red,
      'enabled': true,
    },
    {
      'id': 'buildings',
      'name': 'المباني',
      'icon': Icons.business,
      'color': Colors.blue,
      'enabled': true,
    },
    {
      'id': 'terrain',
      'name': 'التضاريس',
      'icon': Icons.terrain,
      'color': Colors.green,
      'enabled': false,
    },
    {
      'id': 'weather',
      'name': 'الطقس',
      'icon': Icons.cloud,
      'color': Colors.lightBlue,
      'enabled': false,
    },
    {
      'id': 'safety',
      'name': 'نقاط الأمان',
      'icon': Icons.security,
      'color': Colors.orange,
      'enabled': false,
    },
  ];
  
  final List<Map<String, dynamic>> _mapTypes = [
    {
      'id': 'normal',
      'name': 'عادي',
      'icon': Icons.map,
    },
    {
      'id': 'satellite',
      'name': 'قمر صناعي',
      'icon': Icons.satellite_alt,
    },
    {
      'id': 'hybrid',
      'name': 'مختلط',
      'icon': Icons.layers,
    },
    {
      'id': 'terrain',
      'name': 'تضاريس',
      'icon': Icons.landscape,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMapData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _animationController.forward();
    _rotationController.repeat();
  }

  Future<void> _loadMapData() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate loading 3D map data
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحميل الخريطة ثلاثية الأبعاد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الخريطة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخرائط ثلاثية الأبعاد'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_is3DEnabled ? Icons.view_in_ar : Icons.map),
            onPressed: _toggle3DMode,
            tooltip: _is3DEnabled ? 'إيقاف الوضع ثلاثي الأبعاد' : 'تفعيل الوضع ثلاثي الأبعاد',
          ),
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showLayersPanel,
            tooltip: 'طبقات الخريطة',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showMapSettings,
            tooltip: 'إعدادات الخريطة',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ResponsiveBuilder(
          builder: (context, sizingInfo) {
            return Stack(
              children: [
                _buildMapView(),
                _buildMapControls(),
                _buildMapInfo(),
                if (_isLoading) _buildLoadingOverlay(),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'location',
            onPressed: _centerOnCurrentLocation,
            tooltip: 'موقعي الحالي',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'navigation',
            onPressed: _startNavigation,
            tooltip: 'بدء التنقل',
            child: const Icon(Icons.navigation),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade100,
            Colors.blue.shade300,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Simulated 3D Map View
          _build3DMapSimulation(),
          
          // Map Overlays
          if (_showTraffic) _buildTrafficOverlay(),
          if (_showBuildings) _buildBuildingsOverlay(),
          if (_showTerrain) _buildTerrainOverlay(),
        ],
      ),
    );
  }

  Widget _build3DMapSimulation() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_mapTilt * math.pi / 180)
            ..rotateY(_mapBearing * math.pi / 180)
            ..scale(_mapZoom / 15.0),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: Map3DPainter(
                is3DEnabled: _is3DEnabled,
                mapType: _selectedMapType,
                animationValue: _rotationAnimation.value,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrafficOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: TrafficOverlayPainter(),
      ),
    );
  }

  Widget _buildBuildingsOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: BuildingsOverlayPainter(
          is3DEnabled: _is3DEnabled,
        ),
      ),
    );
  }

  Widget _buildTerrainOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: TerrainOverlayPainter(),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      top: 100,
      child: Column(
        children: [
          _buildZoomControls(),
          const SizedBox(height: 16),
          _buildTiltControls(),
          const SizedBox(height: 16),
          _buildBearingControls(),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return GlassmorphicCard(
      child: Column(
        children: [
          IconButton(
            onPressed: _zoomIn,
            icon: const Icon(Icons.add),
            tooltip: 'تكبير',
          ),
          Container(
            width: 2,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: (_mapZoom - 10) / 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _zoomOut,
            icon: const Icon(Icons.remove),
            tooltip: 'تصغير',
          ),
        ],
      ),
    );
  }

  Widget _buildTiltControls() {
    return GlassmorphicCard(
      child: Column(
        children: [
          IconButton(
            onPressed: _increaseTilt,
            icon: const Icon(Icons.keyboard_arrow_up),
            tooltip: 'زيادة الميل',
          ),
          Transform.rotate(
            angle: _mapTilt * math.pi / 180,
            child: Icon(
              Icons.phone_android,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          IconButton(
            onPressed: _decreaseTilt,
            icon: const Icon(Icons.keyboard_arrow_down),
            tooltip: 'تقليل الميل',
          ),
        ],
      ),
    );
  }

  Widget _buildBearingControls() {
    return GlassmorphicCard(
      child: Column(
        children: [
          IconButton(
            onPressed: _rotateBearingLeft,
            icon: const Icon(Icons.rotate_left),
            tooltip: 'دوران يسار',
          ),
          Transform.rotate(
            angle: _mapBearing * math.pi / 180,
            child: Icon(
              Icons.navigation,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          IconButton(
            onPressed: _rotateBearingRight,
            icon: const Icon(Icons.rotate_right),
            tooltip: 'دوران يمين',
          ),
        ],
      ),
    );
  }

  Widget _buildMapInfo() {
    return Positioned(
      left: 16,
      bottom: 100,
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'معلومات الخريطة',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'التكبير: ${_mapZoom.toStringAsFixed(1)}x',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'الميل: ${_mapTilt.toStringAsFixed(0)}°',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'الاتجاه: ${_mapBearing.toStringAsFixed(0)}°',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'النوع: ${_getMapTypeName(_selectedMapType)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EnhancedLoadingIndicator(),
            SizedBox(height: 16),
            Text(
              'جاري تحميل الخريطة ثلاثية الأبعاد...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Control methods
  void _toggle3DMode() {
    setState(() {
      _is3DEnabled = !_is3DEnabled;
      if (!_is3DEnabled) {
        _mapTilt = 0;
        _mapBearing = 0;
      } else {
        _mapTilt = 45;
      }
    });
    
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _is3DEnabled ? 'تم تفعيل الوضع ثلاثي الأبعاد' : 'تم إيقاف الوضع ثلاثي الأبعاد',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _zoomIn() {
    setState(() {
      _mapZoom = math.min(_mapZoom + 1, 20);
    });
    HapticFeedback.lightImpact();
  }

  void _zoomOut() {
    setState(() {
      _mapZoom = math.max(_mapZoom - 1, 10);
    });
    HapticFeedback.lightImpact();
  }

  void _increaseTilt() {
    if (_is3DEnabled) {
      setState(() {
        _mapTilt = math.min(_mapTilt + 15, 60);
      });
      HapticFeedback.lightImpact();
    }
  }

  void _decreaseTilt() {
    setState(() {
      _mapTilt = math.max(_mapTilt - 15, 0);
    });
    HapticFeedback.lightImpact();
  }

  void _rotateBearingLeft() {
    setState(() {
      _mapBearing = (_mapBearing - 45) % 360;
    });
    HapticFeedback.lightImpact();
  }

  void _rotateBearingRight() {
    setState(() {
      _mapBearing = (_mapBearing + 45) % 360;
    });
    HapticFeedback.lightImpact();
  }

  void _centerOnCurrentLocation() {
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم التوسيط على الموقع الحالي'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _startNavigation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بدء التنقل'),
        content: const Text(
          'هل تريد بدء التنقل باستخدام الخريطة ثلاثية الأبعاد؟\n\n'
          'سيتم استخدام الذكاء الاصطناعي لتحديد أفضل طريق مع عرض ثلاثي الأبعاد للمباني والمعالم.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startNavigationMode();
            },
            child: const Text('بدء'),
          ),
        ],
      ),
    );
  }

  void _startNavigationMode() {
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم بدء وضع التنقل ثلاثي الأبعاد'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showLayersPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.layers,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'طبقات الخريطة',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _mapLayers.length,
                    itemBuilder: (context, index) {
                      final layer = _mapLayers[index];
                      return _buildLayerItem(layer);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLayerItem(Map<String, dynamic> layer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: layer['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  layer['icon'],
                  color: layer['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  layer['name'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: layer['enabled'],
                onChanged: (value) {
                  setState(() {
                    layer['enabled'] = value;
                    _updateLayerVisibility(layer['id'], value);
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateLayerVisibility(String layerId, bool enabled) {
    switch (layerId) {
      case 'traffic':
        _showTraffic = enabled;
        break;
      case 'buildings':
        _showBuildings = enabled;
        break;
      case 'terrain':
        _showTerrain = enabled;
        break;
    }
    
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled ? 'تم تفعيل طبقة ${_getLayerName(layerId)}' : 'تم إخفاء طبقة ${_getLayerName(layerId)}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMapSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات الخريطة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedMapType,
              decoration: const InputDecoration(labelText: 'نوع الخريطة'),
              items: _mapTypes.map((type) => 
                DropdownMenuItem<String>(
                  value: type['id'] as String,
                  child: Row(
                    children: [
                      Icon(type['icon'] as IconData, size: 20),
                      const SizedBox(width: 8),
                      Text(type['name'] as String),
                    ],
                  ),
                ),
              ).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMapType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('الوضع ثلاثي الأبعاد'),
              subtitle: const Text('تفعيل العرض ثلاثي الأبعاد للمباني'),
              value: _is3DEnabled,
              onChanged: (value) {
                setState(() {
                  _is3DEnabled = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              HapticFeedback.lightImpact();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getMapTypeName(String type) {
    final mapType = _mapTypes.firstWhere((t) => t['id'] == type);
    return mapType['name'];
  }

  String _getLayerName(String layerId) {
    final layer = _mapLayers.firstWhere((l) => l['id'] == layerId);
    return layer['name'];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
}

// Custom Painters for 3D Map Simulation
class Map3DPainter extends CustomPainter {
  final bool is3DEnabled;
  final String mapType;
  final double animationValue;

  Map3DPainter({
    required this.is3DEnabled,
    required this.mapType,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Draw base map
    _drawBaseMap(canvas, size, paint);
    
    // Draw roads
    _drawRoads(canvas, size, paint);
    
    // Draw landmarks
    if (is3DEnabled) {
      _draw3DLandmarks(canvas, size, paint);
    } else {
      _draw2DLandmarks(canvas, size, paint);
    }
  }

  void _drawBaseMap(Canvas canvas, Size size, Paint paint) {
    // Draw map background based on type
    switch (mapType) {
      case 'satellite':
        paint.color = Colors.green.shade200;
        break;
      case 'terrain':
        paint.color = Colors.brown.shade200;
        break;
      default:
        paint.color = Colors.grey.shade200;
    }
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw grid pattern
    paint.color = Colors.grey.shade300;
    paint.strokeWidth = 1;
    
    for (int i = 0; i < size.width; i += 50) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
    
    for (int i = 0; i < size.height; i += 50) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  void _drawRoads(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.grey.shade600;
    paint.strokeWidth = 8;
    paint.style = PaintingStyle.stroke;
    
    // Draw main roads
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.2,
      size.width,
      size.height * 0.4,
    );
    
    canvas.drawPath(path, paint);
    
    // Draw secondary roads
    paint.strokeWidth = 4;
    paint.color = Colors.grey.shade500;
    
    final path2 = Path();
    path2.moveTo(size.width * 0.2, 0);
    path2.lineTo(size.width * 0.2, size.height);
    
    canvas.drawPath(path2, paint);
  }

  void _draw3DLandmarks(Canvas canvas, Size size, Paint paint) {
    // Draw 3D buildings
    paint.style = PaintingStyle.fill;
    
    for (int i = 0; i < 5; i++) {
      final x = (i + 1) * size.width / 6;
      final y = size.height * 0.6;
      final height = 40.0 + (i * 20.0);
      
      // Building shadow
      paint.color = Colors.black.withValues(alpha: 0.3);
      canvas.drawRect(
        Rect.fromLTWH(x + 5.0, y + 5.0, 30.0, height),
        paint,
      );
      
      // Building
      paint.color = Colors.blue.shade300;
      canvas.drawRect(
        Rect.fromLTWH(x, y, 30.0, height),
        paint,
      );
      
      // Building top (3D effect)
      paint.color = Colors.blue.shade100;
      final topPath = Path();
      topPath.moveTo(x, y);
      topPath.lineTo(x + 30, y);
      topPath.lineTo(x + 35, y - 5);
      topPath.lineTo(x + 5, y - 5);
      topPath.close();
      
      canvas.drawPath(topPath, paint);
      
      // Building side (3D effect)
      paint.color = Colors.blue.shade200;
      final sidePath = Path();
      sidePath.moveTo(x + 30, y);
      sidePath.lineTo(x + 30, y + height);
      sidePath.lineTo(x + 35, y + height - 5);
      sidePath.lineTo(x + 35, y - 5);
      sidePath.close();
      
      canvas.drawPath(sidePath, paint);
    }
  }

  void _draw2DLandmarks(Canvas canvas, Size size, Paint paint) {
    // Draw 2D buildings
    paint.style = PaintingStyle.fill;
    paint.color = Colors.blue.shade300;
    
    for (int i = 0; i < 5; i++) {
      final x = (i + 1) * size.width / 6;
      final y = size.height * 0.6;
      final height = 40.0 + (i * 20.0);
      
      canvas.drawRect(
        Rect.fromLTWH(x, y, 30.0, height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TrafficOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    
    // Draw traffic flow indicators
    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.3 + i * 0.2);
      final colors = [Colors.green, Colors.orange, Colors.red];
      
      paint.color = colors[i].withValues(alpha: 0.7);
      
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BuildingsOverlayPainter extends CustomPainter {
  final bool is3DEnabled;

  BuildingsOverlayPainter({required this.is3DEnabled});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.purple.withValues(alpha: 0.3);
    
    // Highlight important buildings
    for (int i = 0; i < 3; i++) {
      final x = (i + 1) * size.width / 4;
      final y = size.height * 0.7;
      
      canvas.drawCircle(
        Offset(x, y),
        20,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TerrainOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Draw terrain elevation
    final gradient = LinearGradient(
      colors: [
        Colors.green.withValues(alpha: 0.3),
        Colors.brown.withValues(alpha: 0.3),
      ],
    );
    
    paint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    
    for (int i = 0; i <= size.width; i += 20) {
      final height = size.height * (0.6 + 0.2 * math.sin(i / 50));
      path.lineTo(i.toDouble(), height);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}