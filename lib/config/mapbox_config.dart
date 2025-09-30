class MapboxConfig {
  static const String accessToken = 'pk.eyJ1IjoibW9oYW1lZDFzdCIsImEiOiJjbWc2ZzNma2QwZTdlMmtza2J2Y2FobzNwIn0.VnhahF0AkIeDAbo_2WETuw';
  
  // Default map style
  static const String defaultStyle = 'mapbox://styles/mapbox/streets-v12';
  
  // Alternative styles
  static const String satelliteStyle = 'mapbox://styles/mapbox/satellite-v9';
  static const String darkStyle = 'mapbox://styles/mapbox/dark-v11';
  static const String lightStyle = 'mapbox://styles/mapbox/light-v11';
  
  // Default camera settings
  static const double defaultZoom = 14.0;
  static const double minZoom = 1.0;
  static const double maxZoom = 20.0;
}