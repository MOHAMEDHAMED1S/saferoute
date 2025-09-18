import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  accidentAlert,
  jamAlert,
  carBreakdownAlert,
  bumpAlert,
  closedRoadAlert,
  reportConfirmed,
  reportDenied,
  pointsEarned,
}

class NotificationModel {
  final String id;
  final String userId;
  final String? reportId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    this.reportId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  // Convert from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return NotificationModel(
      id: doc.id,
      userId: data['userId'],
      reportId: data['reportId'],
      title: data['title'],
      body: data['body'],
      type: _stringToNotificationType(data['type']),
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      data: data['data'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'reportId': reportId,
      'title': title,
      'body': body,
      'type': _notificationTypeToString(type),
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'data': data,
    };
  }

  // Helper methods for enum conversion
  static NotificationType _stringToNotificationType(String type) {
    switch (type) {
      case 'accident_alert':
        return NotificationType.accidentAlert;
      case 'jam_alert':
        return NotificationType.jamAlert;
      case 'car_breakdown_alert':
        return NotificationType.carBreakdownAlert;
      case 'bump_alert':
        return NotificationType.bumpAlert;
      case 'closed_road_alert':
        return NotificationType.closedRoadAlert;
      case 'report_confirmed':
        return NotificationType.reportConfirmed;
      case 'report_denied':
        return NotificationType.reportDenied;
      case 'points_earned':
        return NotificationType.pointsEarned;
      default:
        return NotificationType.accidentAlert;
    }
  }

  static String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.accidentAlert:
        return 'accident_alert';
      case NotificationType.jamAlert:
        return 'jam_alert';
      case NotificationType.carBreakdownAlert:
        return 'car_breakdown_alert';
      case NotificationType.bumpAlert:
        return 'bump_alert';
      case NotificationType.closedRoadAlert:
        return 'closed_road_alert';
      case NotificationType.reportConfirmed:
        return 'report_confirmed';
      case NotificationType.reportDenied:
        return 'report_denied';
      case NotificationType.pointsEarned:
        return 'points_earned';
    }
  }

  // Get icon for notification type
  String get iconName {
    switch (type) {
      case NotificationType.accidentAlert:
        return '🚨';
      case NotificationType.jamAlert:
        return '🚗';
      case NotificationType.carBreakdownAlert:
        return '🔧';
      case NotificationType.bumpAlert:
        return '⚠️';
      case NotificationType.closedRoadAlert:
        return '🚧';
      case NotificationType.reportConfirmed:
        return '✅';
      case NotificationType.reportDenied:
        return '❌';
      case NotificationType.pointsEarned:
        return '🏆';
    }
  }

  // Check if notification is alert type
  bool get isAlert {
    return [
      NotificationType.accidentAlert,
      NotificationType.jamAlert,
      NotificationType.carBreakdownAlert,
      NotificationType.bumpAlert,
      NotificationType.closedRoadAlert,
    ].contains(type);
  }

  // Copy with method for updates
  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      reportId: reportId,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      data: data,
    );
  }

  // Factory method for creating alert notifications
  factory NotificationModel.createAlert({
    required String userId,
    required String reportId,
    required NotificationType type,
    required String hazardType,
    required int distanceInMeters,
  }) {
    String title = 'تحذير: $hazardType';
    String body = 'يوجد $hazardType بعد $distanceInMeters متر. يرجى توخي الحذر.';
    
    return NotificationModel(
      id: '', // Will be set by Firestore
      userId: userId,
      reportId: reportId,
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
      data: {
        'distance': distanceInMeters,
        'hazardType': hazardType,
      },
    );
  }

  // Factory method for creating confirmation notifications
  factory NotificationModel.createConfirmation({
    required String userId,
    required String reportId,
    required bool isConfirmed,
    required int pointsEarned,
  }) {
    String title = isConfirmed ? 'تم تأكيد بلاغك' : 'تم رفض بلاغك';
    String body = isConfirmed 
        ? 'تم تأكيد صحة بلاغك وحصلت على $pointsEarned نقطة'
        : 'تم الإبلاغ عن عدم صحة بلاغك';
    
    return NotificationModel(
      id: '', // Will be set by Firestore
      userId: userId,
      reportId: reportId,
      title: title,
      body: body,
      type: isConfirmed ? NotificationType.reportConfirmed : NotificationType.reportDenied,
      createdAt: DateTime.now(),
      data: {
        'pointsEarned': pointsEarned,
      },
    );
  }
}