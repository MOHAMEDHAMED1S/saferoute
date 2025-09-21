// ML Models for Smart Insights

class DrivingAnalysis {
  final double safetyScore;
  final double fuelEfficiency;
  final double averageSpeed;
  final double totalDistance;
  final DateTime timestamp;
  
  DrivingAnalysis({
    required this.safetyScore,
    required this.fuelEfficiency,
    required this.averageSpeed,
    required this.totalDistance,
    required this.timestamp,
  });
}

class SmartRecommendation {
  final String id;
  final RecommendationType type;
  final RecommendationPriority priority;
  final String title;
  final String description;
  final String actionText;
  final double confidence;
  
  SmartRecommendation({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.actionText,
    required this.confidence,
  });
}

class RiskAssessment {
  final RiskLevel overallRisk;
  final List<Map<String, dynamic>> factors;
  final DateTime timestamp;
  
  RiskAssessment({
    required this.overallRisk,
    required this.factors,
    required this.timestamp,
  });
}

// Enums
enum RecommendationType { safety, efficiency, comfort, eco }
enum RecommendationPriority { low, medium, high, critical }
enum RiskLevel { low, medium, high, critical }