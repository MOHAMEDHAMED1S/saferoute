import 'dart:math' as math;

// AR Navigation Models
class ARNavigationData {
  final String id;
  final ARInstruction instruction;
  final ARLandmark? landmark;
  final AROverlay overlay;
  final double distance;
  final double bearing;
  final DateTime timestamp;
  final ARVisibility visibility;
  
  const ARNavigationData({
    required this.id,
    required this.instruction,
    this.landmark,
    required this.overlay,
    required this.distance,
    required this.bearing,
    required this.timestamp,
    required this.visibility,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'instruction': instruction.toJson(),
    'landmark': landmark?.toJson(),
    'overlay': overlay.toJson(),
    'distance': distance,
    'bearing': bearing,
    'timestamp': timestamp.toIso8601String(),
    'visibility': visibility.toJson(),
  };
  
  factory ARNavigationData.fromJson(Map<String, dynamic> json) => ARNavigationData(
    id: json['id'],
    instruction: ARInstruction.fromJson(json['instruction']),
    landmark: json['landmark'] != null ? ARLandmark.fromJson(json['landmark']) : null,
    overlay: AROverlay.fromJson(json['overlay']),
    distance: json['distance'].toDouble(),
    bearing: json['bearing'].toDouble(),
    timestamp: DateTime.parse(json['timestamp']),
    visibility: ARVisibility.fromJson(json['visibility']),
  );
}

class ARInstruction {
  final String id;
  final ARInstructionType type;
  final String text;
  final String arabicText;
  final ARDirection direction;
  final double distance;
  final String? streetName;
  final ARPriority priority;
  final ARAnimation animation;
  
  const ARInstruction({
    required this.id,
    required this.type,
    required this.text,
    required this.arabicText,
    required this.direction,
    required this.distance,
    this.streetName,
    required this.priority,
    required this.animation,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'text': text,
    'arabicText': arabicText,
    'direction': direction.name,
    'distance': distance,
    'streetName': streetName,
    'priority': priority.name,
    'animation': animation.toJson(),
  };
  
  factory ARInstruction.fromJson(Map<String, dynamic> json) => ARInstruction(
    id: json['id'],
    type: ARInstructionType.values.byName(json['type']),
    text: json['text'],
    arabicText: json['arabicText'],
    direction: ARDirection.values.byName(json['direction']),
    distance: json['distance'].toDouble(),
    streetName: json['streetName'],
    priority: ARPriority.values.byName(json['priority']),
    animation: ARAnimation.fromJson(json['animation']),
  );
  
  String get distanceText {
    if (distance < 100) {
      return '${distance.toInt()} متر';
    } else if (distance < 1000) {
      return '${(distance / 100).round() * 100} متر';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} كم';
    }
  }
  
  String get directionIcon {
    switch (direction) {
      case ARDirection.straight:
        return '↑';
      case ARDirection.left:
        return '←';
      case ARDirection.right:
        return '→';
      case ARDirection.slightLeft:
        return '↖';
      case ARDirection.slightRight:
        return '↗';
      case ARDirection.sharpLeft:
        return '↙';
      case ARDirection.sharpRight:
        return '↘';
      case ARDirection.uTurn:
        return '↩';
      case ARDirection.roundabout:
        return '⭕';
      case ARDirection.exit:
        return '🚪';
    }
  }
}

class ARLandmark {
  final String id;
  final String name;
  final String arabicName;
  final ARLandmarkType type;
  final ARPosition position;
  final double distance;
  final double bearing;
  final ARVisibility visibility;
  final String? imageUrl;
  final String? description;
  final double confidence;
  
  const ARLandmark({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.type,
    required this.position,
    required this.distance,
    required this.bearing,
    required this.visibility,
    this.imageUrl,
    this.description,
    required this.confidence,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'arabicName': arabicName,
    'type': type.name,
    'position': position.toJson(),
    'distance': distance,
    'bearing': bearing,
    'visibility': visibility.toJson(),
    'imageUrl': imageUrl,
    'description': description,
    'confidence': confidence,
  };
  
  factory ARLandmark.fromJson(Map<String, dynamic> json) => ARLandmark(
    id: json['id'],
    name: json['name'],
    arabicName: json['arabicName'],
    type: ARLandmarkType.values.byName(json['type']),
    position: ARPosition.fromJson(json['position']),
    distance: json['distance'].toDouble(),
    bearing: json['bearing'].toDouble(),
    visibility: ARVisibility.fromJson(json['visibility']),
    imageUrl: json['imageUrl'],
    description: json['description'],
    confidence: json['confidence'].toDouble(),
  );
  
  String get typeIcon {
    switch (type) {
      case ARLandmarkType.building:
        return '🏢';
      case ARLandmarkType.monument:
        return '🏛️';
      case ARLandmarkType.bridge:
        return '🌉';
      case ARLandmarkType.gasStation:
        return '⛽';
      case ARLandmarkType.restaurant:
        return '🍽️';
      case ARLandmarkType.hospital:
        return '🏥';
      case ARLandmarkType.school:
        return '🏫';
      case ARLandmarkType.mosque:
        return '🕌';
      case ARLandmarkType.park:
        return '🌳';
      case ARLandmarkType.mall:
        return '🏬';
      case ARLandmarkType.traffic:
        return '🚦';
      case ARLandmarkType.roundabout:
        return '⭕';
    }
  }
}

class AROverlay {
  final String id;
  final AROverlayType type;
  final ARPosition position;
  final ARSize size;
  final ARColor color;
  final double opacity;
  final ARAnimation animation;
  final bool isVisible;
  final String? text;
  final String? iconPath;
  final double rotation;
  final double scale;
  
  const AROverlay({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    required this.color,
    required this.opacity,
    required this.animation,
    required this.isVisible,
    this.text,
    this.iconPath,
    required this.rotation,
    required this.scale,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'position': position.toJson(),
    'size': size.toJson(),
    'color': color.toJson(),
    'opacity': opacity,
    'animation': animation.toJson(),
    'isVisible': isVisible,
    'text': text,
    'iconPath': iconPath,
    'rotation': rotation,
    'scale': scale,
  };
  
  factory AROverlay.fromJson(Map<String, dynamic> json) => AROverlay(
    id: json['id'],
    type: AROverlayType.values.byName(json['type']),
    position: ARPosition.fromJson(json['position']),
    size: ARSize.fromJson(json['size']),
    color: ARColor.fromJson(json['color']),
    opacity: json['opacity'].toDouble(),
    animation: ARAnimation.fromJson(json['animation']),
    isVisible: json['isVisible'],
    text: json['text'],
    iconPath: json['iconPath'],
    rotation: json['rotation'].toDouble(),
    scale: json['scale'].toDouble(),
  );
}

class ARPosition {
  final double x;
  final double y;
  final double z;
  final double latitude;
  final double longitude;
  final double altitude;
  
  const ARPosition({
    required this.x,
    required this.y,
    required this.z,
    required this.latitude,
    required this.longitude,
    required this.altitude,
  });
  
  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'z': z,
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
  };
  
  factory ARPosition.fromJson(Map<String, dynamic> json) => ARPosition(
    x: json['x'].toDouble(),
    y: json['y'].toDouble(),
    z: json['z'].toDouble(),
    latitude: json['latitude'].toDouble(),
    longitude: json['longitude'].toDouble(),
    altitude: json['altitude'].toDouble(),
  );
  
  double distanceTo(ARPosition other) {
    const double earthRadius = 6371000; // meters
    
    double lat1Rad = latitude * math.pi / 180;
    double lat2Rad = other.latitude * math.pi / 180;
    double deltaLatRad = (other.latitude - latitude) * math.pi / 180;
    double deltaLonRad = (other.longitude - longitude) * math.pi / 180;
    
    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double bearingTo(ARPosition other) {
    double lat1Rad = latitude * math.pi / 180;
    double lat2Rad = other.latitude * math.pi / 180;
    double deltaLonRad = (other.longitude - longitude) * math.pi / 180;
    
    double y = math.sin(deltaLonRad) * math.cos(lat2Rad);
    double x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLonRad);
    
    double bearing = math.atan2(y, x);
    
    return (bearing * 180 / math.pi + 360) % 360;
  }
}

class ARSize {
  final double width;
  final double height;
  final double depth;
  
  const ARSize({
    required this.width,
    required this.height,
    required this.depth,
  });
  
  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'depth': depth,
  };
  
  factory ARSize.fromJson(Map<String, dynamic> json) => ARSize(
    width: json['width'].toDouble(),
    height: json['height'].toDouble(),
    depth: json['depth'].toDouble(),
  );
}

class ARColor {
  final int red;
  final int green;
  final int blue;
  final double alpha;
  
  const ARColor({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });
  
  Map<String, dynamic> toJson() => {
    'red': red,
    'green': green,
    'blue': blue,
    'alpha': alpha,
  };
  
  factory ARColor.fromJson(Map<String, dynamic> json) => ARColor(
    red: json['red'],
    green: json['green'],
    blue: json['blue'],
    alpha: json['alpha'].toDouble(),
  );
  
  int get value => (alpha * 255).round() << 24 | red << 16 | green << 8 | blue;
}

class ARAnimation {
  final ARAnimationType type;
  final double duration;
  final ARAnimationCurve curve;
  final bool repeat;
  final bool reverse;
  final double delay;
  
  const ARAnimation({
    required this.type,
    required this.duration,
    required this.curve,
    required this.repeat,
    required this.reverse,
    required this.delay,
  });
  
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'duration': duration,
    'curve': curve.name,
    'repeat': repeat,
    'reverse': reverse,
    'delay': delay,
  };
  
  factory ARAnimation.fromJson(Map<String, dynamic> json) => ARAnimation(
    type: ARAnimationType.values.byName(json['type']),
    duration: json['duration'].toDouble(),
    curve: ARAnimationCurve.values.byName(json['curve']),
    repeat: json['repeat'],
    reverse: json['reverse'],
    delay: json['delay'].toDouble(),
  );
}

class ARVisibility {
  final bool isVisible;
  final double distance;
  final double minDistance;
  final double maxDistance;
  final double opacity;
  final ARVisibilityCondition condition;
  
  const ARVisibility({
    required this.isVisible,
    required this.distance,
    required this.minDistance,
    required this.maxDistance,
    required this.opacity,
    required this.condition,
  });
  
  Map<String, dynamic> toJson() => {
    'isVisible': isVisible,
    'distance': distance,
    'minDistance': minDistance,
    'maxDistance': maxDistance,
    'opacity': opacity,
    'condition': condition.name,
  };
  
  factory ARVisibility.fromJson(Map<String, dynamic> json) => ARVisibility(
    isVisible: json['isVisible'],
    distance: json['distance'].toDouble(),
    minDistance: json['minDistance'].toDouble(),
    maxDistance: json['maxDistance'].toDouble(),
    opacity: json['opacity'].toDouble(),
    condition: ARVisibilityCondition.values.byName(json['condition']),
  );
  
  bool shouldShow(double currentDistance) {
    if (!isVisible) return false;
    if (currentDistance < minDistance || currentDistance > maxDistance) return false;
    
    switch (condition) {
      case ARVisibilityCondition.always:
        return true;
      case ARVisibilityCondition.nearOnly:
        return currentDistance <= 100;
      case ARVisibilityCondition.farOnly:
        return currentDistance > 100;
      case ARVisibilityCondition.dayOnly:
        final hour = DateTime.now().hour;
        return hour >= 6 && hour < 18;
      case ARVisibilityCondition.nightOnly:
        final hour = DateTime.now().hour;
        return hour < 6 || hour >= 18;
      case ARVisibilityCondition.goodWeather:
        // TODO: Implement weather condition check
        return true; // For now, always return true
      case ARVisibilityCondition.navigating:
        // TODO: Implement navigation state check
        return true; // For now, always return true
    }
  }
}

class ARCalibration {
  final double compassOffset;
  final double tiltOffset;
  final double scaleOffset;
  final DateTime lastCalibration;
  final bool isCalibrated;
  final double accuracy;
  
  const ARCalibration({
    required this.compassOffset,
    required this.tiltOffset,
    required this.scaleOffset,
    required this.lastCalibration,
    required this.isCalibrated,
    required this.accuracy,
  });
  
  Map<String, dynamic> toJson() => {
    'compassOffset': compassOffset,
    'tiltOffset': tiltOffset,
    'scaleOffset': scaleOffset,
    'lastCalibration': lastCalibration.toIso8601String(),
    'isCalibrated': isCalibrated,
    'accuracy': accuracy,
  };
  
  factory ARCalibration.fromJson(Map<String, dynamic> json) => ARCalibration(
    compassOffset: json['compassOffset'].toDouble(),
    tiltOffset: json['tiltOffset'].toDouble(),
    scaleOffset: json['scaleOffset'].toDouble(),
    lastCalibration: DateTime.parse(json['lastCalibration']),
    isCalibrated: json['isCalibrated'],
    accuracy: json['accuracy'].toDouble(),
  );
  
  bool get needsRecalibration {
    final timeSinceCalibration = DateTime.now().difference(lastCalibration);
    return !isCalibrated || 
           timeSinceCalibration.inHours > 24 || 
           accuracy < 0.8;
  }
}

// Enums
enum ARInstructionType {
  turn,
  continue_,
  merge,
  exit,
  roundabout,
  destination,
  waypoint,
  warning,
}

enum ARDirection {
  straight,
  left,
  right,
  slightLeft,
  slightRight,
  sharpLeft,
  sharpRight,
  uTurn,
  roundabout,
  exit,
}

enum ARLandmarkType {
  building,
  monument,
  bridge,
  gasStation,
  restaurant,
  hospital,
  school,
  mosque,
  park,
  mall,
  traffic,
  roundabout,
}

enum AROverlayType {
  arrow,
  text,
  icon,
  line,
  circle,
  rectangle,
  path,
  landmark,
  instruction,
  warning,
}

enum ARPriority {
  low,
  medium,
  high,
  critical,
}

enum ARAnimationType {
  none,
  fade,
  scale,
  rotate,
  translate,
  pulse,
  bounce,
  shake,
}

enum ARAnimationCurve {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  bounceIn,
  bounceOut,
  elasticIn,
  elasticOut,
}

enum ARVisibilityCondition {
  always,
  nearOnly,
  farOnly,
  dayOnly,
  nightOnly,
  goodWeather,
  navigating,
}

// Helper Extensions
extension ARInstructionTypeExtension on ARInstructionType {
  String get arabicName {
    switch (this) {
      case ARInstructionType.turn:
        return 'انعطف';
      case ARInstructionType.continue_:
        return 'تابع';
      case ARInstructionType.merge:
        return 'اندمج';
      case ARInstructionType.exit:
        return 'اخرج';
      case ARInstructionType.roundabout:
        return 'دوار';
      case ARInstructionType.destination:
        return 'الوجهة';
      case ARInstructionType.waypoint:
        return 'نقطة مرور';
      case ARInstructionType.warning:
        return 'تحذير';
    }
  }
}

extension ARLandmarkTypeExtension on ARLandmarkType {
  String get arabicName {
    switch (this) {
      case ARLandmarkType.building:
        return 'مبنى';
      case ARLandmarkType.monument:
        return 'نصب تذكاري';
      case ARLandmarkType.bridge:
        return 'جسر';
      case ARLandmarkType.gasStation:
        return 'محطة وقود';
      case ARLandmarkType.restaurant:
        return 'مطعم';
      case ARLandmarkType.hospital:
        return 'مستشفى';
      case ARLandmarkType.school:
        return 'مدرسة';
      case ARLandmarkType.mosque:
        return 'مسجد';
      case ARLandmarkType.park:
        return 'حديقة';
      case ARLandmarkType.mall:
        return 'مول';
      case ARLandmarkType.traffic:
        return 'إشارة مرور';
      case ARLandmarkType.roundabout:
        return 'دوار';
    }
  }
}