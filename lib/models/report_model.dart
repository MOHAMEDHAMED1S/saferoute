import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ReportType {
  accident,
  jam,
  carBreakdown,
  bump,
  closedRoad,
  hazard,
  police,
  traffic,
  other,
}

extension ReportTypeExtension on ReportType {
  String get displayName {
    switch (this) {
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
      case ReportType.hazard:
        return 'خطر';
      case ReportType.police:
        return 'شرطة';
      case ReportType.traffic:
        return 'حركة مرور';
      case ReportType.other:
        return 'أخرى';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportType.accident:
        return Icons.car_crash;
      case ReportType.jam:
        return Icons.traffic;
      case ReportType.carBreakdown:
        return Icons.build;
      case ReportType.bump:
        return Icons.warning;
      case ReportType.closedRoad:
        return Icons.block;
      case ReportType.hazard:
        return Icons.warning;
      case ReportType.police:
        return Icons.local_police;
      case ReportType.traffic:
        return Icons.traffic;
      case ReportType.other:
        return Icons.assignment;
    }
  }
}

enum ReportStatus { active, expired, removed, pending, verified, rejected }

class ReportModel {
  final String id;
  final ReportType type;
  final String description;
  final ReportLocation location;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String createdBy;
  final ReportStatus status;
  final ReportConfirmations? confirmations;
  final List<String> confirmedBy;
  final List<String> deniedBy;
  final List<String>? imageUrls;
  final DateTime? updatedAt;

  ReportModel({
    required this.id,
    required this.type,
    required this.description,
    required this.location,
    required this.createdAt,
    this.expiresAt,
    required this.createdBy,
    this.status = ReportStatus.active,
    this.confirmations,
    this.confirmedBy = const [],
    this.deniedBy = const [],
    this.imageUrls,
    this.updatedAt,
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
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'],
      status: _stringToReportStatus(data['status']),
      confirmations: data['confirmations'] != null
          ? ReportConfirmations.fromMap(data['confirmations'])
          : null,
      confirmedBy: List<String>.from(data['verifiedBy'] ?? []),
      deniedBy: List<String>.from(data['rejectedBy'] ?? []),
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'type': _reportTypeToString(type),
      'description': description,
      'location': location.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'status': _reportStatusToString(status),
      'verifiedBy': confirmedBy,
      'rejectedBy': deniedBy,
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };

    // Add optional fields if they exist
    if (expiresAt != null) {
      data['expiresAt'] = Timestamp.fromDate(expiresAt!);
    }

    if (confirmations != null) {
      data['confirmations'] = confirmations!.toMap();
    }

    if (imageUrls != null && imageUrls!.isNotEmpty) {
      data['imageUrls'] = imageUrls;
    }

    return data;
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
      case 'hazard':
        return ReportType.hazard;
      case 'police':
        return ReportType.police;
      case 'traffic':
        return ReportType.traffic;
      case 'other':
        return ReportType.other;
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
      case ReportType.hazard:
        return 'hazard';
      case ReportType.police:
        return 'police';
      case ReportType.traffic:
        return 'traffic';
      case ReportType.other:
        return 'other';
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
      case 'pending':
        return ReportStatus.pending;
      case 'verified':
        return ReportStatus.verified;
      case 'rejected':
        return ReportStatus.rejected;
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
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.verified:
        return 'verified';
      case ReportStatus.rejected:
        return 'rejected';
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
      case ReportType.hazard:
        return 'خطر';
      case ReportType.police:
        return 'شرطة';
      case ReportType.traffic:
        return 'حركة مرور';
      case ReportType.other:
        return 'أخرى';
    }
  }

  // Check if report is expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  // Get trust score based on confirmations
  double get trustScore {
    final int trueVotes = confirmations?.trueVotes ?? 0;
    final int falseVotes = confirmations?.falseVotes ?? 0;
    final int total = trueVotes + falseVotes;
    if (total == 0) return 0.5;
    return trueVotes / total;
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

  ReportLocation({required this.lat, required this.lng});

  factory ReportLocation.fromMap(Map<String, dynamic> map) {
    return ReportLocation(
      lat: map['lat'].toDouble(),
      lng: map['lng'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'lat': lat, 'lng': lng};
  }
}

class ReportConfirmations {
  final int trueVotes;
  final int falseVotes;

  ReportConfirmations({this.trueVotes = 0, this.falseVotes = 0});

  factory ReportConfirmations.fromMap(Map<String, dynamic> map) {
    return ReportConfirmations(
      trueVotes: map['trueVotes'] ?? 0,
      falseVotes: map['falseVotes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'trueVotes': trueVotes, 'falseVotes': falseVotes};
  }

  ReportConfirmations copyWith({int? trueVotes, int? falseVotes}) {
    return ReportConfirmations(
      trueVotes: trueVotes ?? this.trueVotes,
      falseVotes: falseVotes ?? this.falseVotes,
    );
  }
}
