import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportType {
  accident,
  jam,
  carBreakdown,
  bump,
  closedRoad,
}

enum ReportStatus {
  active,
  expired,
  removed,
}

class ReportModel {
  final String id;
  final ReportType type;
  final String description;
  final ReportLocation location;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String createdBy;
  final ReportStatus status;
  final ReportConfirmations confirmations;
  final List<String> confirmedBy;
  final List<String> deniedBy;

  ReportModel({
    required this.id,
    required this.type,
    required this.description,
    required this.location,
    required this.createdAt,
    required this.expiresAt,
    required this.createdBy,
    this.status = ReportStatus.active,
    required this.confirmations,
    this.confirmedBy = const [],
    this.deniedBy = const [],
  });

  // Convert from Firestore document
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return ReportModel(
      id: doc.id,
      type: _stringToReportType(data['type']),
      description: data['description'] ?? '',
      location: ReportLocation.fromMap(data['location']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
      status: _stringToReportStatus(data['status']),
      confirmations: ReportConfirmations.fromMap(data['confirmations']),
      confirmedBy: List<String>.from(data['confirmedBy'] ?? []),
      deniedBy: List<String>.from(data['deniedBy'] ?? []),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'type': _reportTypeToString(type),
      'description': description,
      'location': location.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdBy': createdBy,
      'status': _reportStatusToString(status),
      'confirmations': confirmations.toMap(),
      'confirmedBy': confirmedBy,
      'deniedBy': deniedBy,
    };
  }

  // Helper methods for enum conversion
  static ReportType _stringToReportType(String type) {
    switch (type) {
      case 'accident':
        return ReportType.accident;
      case 'jam':
        return ReportType.jam;
      case 'car_breakdown':
        return ReportType.carBreakdown;
      case 'bump':
        return ReportType.bump;
      case 'closed_road':
        return ReportType.closedRoad;
      default:
        return ReportType.accident;
    }
  }

  static String _reportTypeToString(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return 'accident';
      case ReportType.jam:
        return 'jam';
      case ReportType.carBreakdown:
        return 'car_breakdown';
      case ReportType.bump:
        return 'bump';
      case ReportType.closedRoad:
        return 'closed_road';
    }
  }

  static ReportStatus _stringToReportStatus(String status) {
    switch (status) {
      case 'active':
        return ReportStatus.active;
      case 'expired':
        return ReportStatus.expired;
      case 'removed':
        return ReportStatus.removed;
      default:
        return ReportStatus.active;
    }
  }

  static String _reportStatusToString(ReportStatus status) {
    switch (status) {
      case ReportStatus.active:
        return 'active';
      case ReportStatus.expired:
        return 'expired';
      case ReportStatus.removed:
        return 'removed';
    }
  }

  // Get Arabic name for report type
  String get typeNameArabic {
    switch (type) {
      case ReportType.accident:
        return 'حادث';
      case ReportType.jam:
        return 'ازدحام';
      case ReportType.carBreakdown:
        return 'سيارة معطلة';
      case ReportType.bump:
        return 'مطب';
      case ReportType.closedRoad:
        return 'طريق مغلق';
    }
  }

  // Check if report is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Get trust score based on confirmations
  double get trustScore {
    int total = confirmations.trueVotes + confirmations.falseVotes;
    if (total == 0) return 0.5;
    return confirmations.trueVotes / total;
  }

  // Copy with method for updates
  ReportModel copyWith({
    ReportStatus? status,
    ReportConfirmations? confirmations,
    List<String>? confirmedBy,
    List<String>? deniedBy,
  }) {
    return ReportModel(
      id: id,
      type: type,
      description: description,
      location: location,
      createdAt: createdAt,
      expiresAt: expiresAt,
      createdBy: createdBy,
      status: status ?? this.status,
      confirmations: confirmations ?? this.confirmations,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      deniedBy: deniedBy ?? this.deniedBy,
    );
  }
}

class ReportLocation {
  final double lat;
  final double lng;

  ReportLocation({
    required this.lat,
    required this.lng,
  });

  factory ReportLocation.fromMap(Map<String, dynamic> map) {
    return ReportLocation(
      lat: map['lat'].toDouble(),
      lng: map['lng'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}

class ReportConfirmations {
  final int trueVotes;
  final int falseVotes;

  ReportConfirmations({
    this.trueVotes = 0,
    this.falseVotes = 0,
  });

  factory ReportConfirmations.fromMap(Map<String, dynamic> map) {
    return ReportConfirmations(
      trueVotes: map['trueVotes'] ?? 0,
      falseVotes: map['falseVotes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trueVotes': trueVotes,
      'falseVotes': falseVotes,
    };
  }

  ReportConfirmations copyWith({
    int? trueVotes,
    int? falseVotes,
  }) {
    return ReportConfirmations(
      trueVotes: trueVotes ?? this.trueVotes,
      falseVotes: falseVotes ?? this.falseVotes,
    );
  }
}