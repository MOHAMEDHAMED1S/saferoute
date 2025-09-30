import 'report_model.dart';

class NearbyReport {
  final String id;
  final String title;
  final String description;
  final String distance; // formatted e.g., "250م" or "1.2كم"
  final String timeAgo; // e.g., "15 دقيقة"
  final int confirmations;
  final ReportType type;
  final double latitude;
  final double longitude;
  final String? relatedReportId; // Firestore document id if available

  NearbyReport({
    required this.id,
    required this.title,
    required this.description,
    required this.distance,
    required this.timeAgo,
    required this.confirmations,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.relatedReportId,
  });

  factory NearbyReport.fromJson(Map<String, dynamic> json) {
    return NearbyReport(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      distance: json['distance'] ?? '',
      timeAgo: json['timeAgo'] ?? '',
      confirmations: json['confirmations'] ?? 0,
      type: ReportType.values.firstWhere(
        (e) => e.toString() == 'ReportType.${json['type']}',
        orElse: () => ReportType.other,
      ),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      relatedReportId: json['relatedReportId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'distance': distance,
      'timeAgo': timeAgo,
      'confirmations': confirmations,
      'type': type.toString().split('.').last,
      'latitude': latitude,
      'longitude': longitude,
      'relatedReportId': relatedReportId,
    };
  }
}
