import '../models/report_model.dart';
import '../models/user_statistics_model.dart';

class UserStatisticsService {
  /// حساب إحصائيات المستخدم من قائمة البلاغات
  UserStatistics calculateUserStatistics(List<ReportModel> reports) {
    if (reports.isEmpty) {
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

    int totalReports = reports.length;
    int confirmedReports = 0;
    int rejectedReports = 0;
    int activeReports = 0;
    int expiredReports = 0;

    Map<String, int> reportsByType = {};
    Map<String, int> reportsByStatus = {};

    for (var report in reports) {
      // حساب الحالات
      switch (report.status) {
        case ReportStatus.active:
          activeReports++;
          break;
        case ReportStatus.expired:
          expiredReports++;
          break;
        case ReportStatus.verified:
          confirmedReports++;
          break;
        case ReportStatus.rejected:
          rejectedReports++;
          break;
        case ReportStatus.pending:
        case ReportStatus.removed:
          // لا نحسب هذه الحالات في الإحصائيات الأساسية
          break;
      }

      // التحقق من التأكيدات إذا كانت متوفرة
      if (report.confirmations != null) {
        if (report.confirmations!.trueVotes > report.confirmations!.falseVotes) {
          confirmedReports++;
        } else if (report.confirmations!.falseVotes > report.confirmations!.trueVotes) {
          rejectedReports++;
        }
      }

      // حساب البلاغات حسب النوع
      String typeKey = _getReportTypeDisplayName(report.type);
      reportsByType[typeKey] = (reportsByType[typeKey] ?? 0) + 1;

      // حساب البلاغات حسب الحالة
      String statusKey = _getReportStatusDisplayName(report.status);
      reportsByStatus[statusKey] = (reportsByStatus[statusKey] ?? 0) + 1;
    }

    // حساب معدل التأكيد
    double confirmationRate = 0.0;
    int totalVotedReports = confirmedReports + rejectedReports;
    if (totalVotedReports > 0) {
      confirmationRate = (confirmedReports / totalVotedReports) * 100;
    }

    return UserStatistics(
      totalReports: totalReports,
      confirmedReports: confirmedReports,
      rejectedReports: rejectedReports,
      activeReports: activeReports,
      expiredReports: expiredReports,
      confirmationRate: confirmationRate,
      reportsByType: reportsByType,
      reportsByStatus: reportsByStatus,
    );
  }

  /// الحصول على اسم نوع البلاغ للعرض
  String _getReportTypeDisplayName(ReportType type) {
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

  /// الحصول على اسم حالة البلاغ للعرض
  String _getReportStatusDisplayName(ReportStatus status) {
    switch (status) {
      case ReportStatus.active:
        return 'نشط';
      case ReportStatus.expired:
        return 'منتهي الصلاحية';
      case ReportStatus.verified:
        return 'مؤكد';
      case ReportStatus.rejected:
        return 'مرفوض';
      case ReportStatus.pending:
        return 'في الانتظار';
      case ReportStatus.removed:
        return 'محذوف';
    }
  }

  /// حساب نقاط المستخدم بناءً على الإحصائيات
  int calculateUserPoints(UserStatistics statistics) {
    int points = 0;
    
    // نقاط للبلاغات المؤكدة
    points += statistics.confirmedReports * 10;
    
    // نقاط للبلاغات النشطة
    points += statistics.activeReports * 5;
    
    // نقاط إضافية للدقة العالية
    if (statistics.confirmationRate >= 80) {
      points += 50;
    } else if (statistics.confirmationRate >= 60) {
      points += 25;
    }
    
    // نقاط للمشاركة النشطة
    if (statistics.totalReports >= 50) {
      points += 100;
    } else if (statistics.totalReports >= 20) {
      points += 50;
    } else if (statistics.totalReports >= 10) {
      points += 25;
    }
    
    return points;
  }

  /// تحديد مستوى المستخدم بناءً على النقاط
  String getUserLevel(int points) {
    if (points >= 500) {
      return 'خبير';
    } else if (points >= 300) {
      return 'متقدم';
    } else if (points >= 150) {
      return 'متوسط';
    } else if (points >= 50) {
      return 'مبتدئ';
    } else {
      return 'جديد';
    }
  }

  /// الحصول على لون مستوى المستخدم
  String getUserLevelColor(String level) {
    switch (level) {
      case 'خبير':
        return '#FFD700'; // ذهبي
      case 'متقدم':
        return '#C0C0C0'; // فضي
      case 'متوسط':
        return '#CD7F32'; // برونزي
      case 'مبتدئ':
        return '#4CAF50'; // أخضر
      case 'جديد':
      default:
        return '#9E9E9E'; // رمادي
    }
  }
}