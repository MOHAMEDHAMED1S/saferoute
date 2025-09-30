class UserStatistics {
  final int totalReports;
  final int confirmedReports;
  final int rejectedReports;
  final int activeReports;
  final int expiredReports;
  final double confirmationRate;
  final Map<String, int> reportsByType;
  final Map<String, int> reportsByStatus;

  UserStatistics({
    required this.totalReports,
    required this.confirmedReports,
    required this.rejectedReports,
    required this.activeReports,
    required this.expiredReports,
    required this.confirmationRate,
    required this.reportsByType,
    required this.reportsByStatus,
  });

  factory UserStatistics.empty() {
    return UserStatistics(
      totalReports: 0,
      confirmedReports: 0,
      rejectedReports: 0,
      activeReports: 0,
      expiredReports: 0,
      confirmationRate: 0.0,
      reportsByType: {},
      reportsByStatus: {},
    );
  }

  UserStatistics copyWith({
    int? totalReports,
    int? confirmedReports,
    int? rejectedReports,
    int? activeReports,
    int? expiredReports,
    double? confirmationRate,
    Map<String, int>? reportsByType,
    Map<String, int>? reportsByStatus,
  }) {
    return UserStatistics(
      totalReports: totalReports ?? this.totalReports,
      confirmedReports: confirmedReports ?? this.confirmedReports,
      rejectedReports: rejectedReports ?? this.rejectedReports,
      activeReports: activeReports ?? this.activeReports,
      expiredReports: expiredReports ?? this.expiredReports,
      confirmationRate: confirmationRate ?? this.confirmationRate,
      reportsByType: reportsByType ?? this.reportsByType,
      reportsByStatus: reportsByStatus ?? this.reportsByStatus,
    );
  }

  @override
  String toString() {
    return 'UserStatistics(totalReports: $totalReports, confirmedReports: $confirmedReports, rejectedReports: $rejectedReports, activeReports: $activeReports, expiredReports: $expiredReports, confirmationRate: $confirmationRate)';
  }
}