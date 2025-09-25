import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferoute/models/rewards_model.dart';
import 'package:saferoute/models/report_model.dart';

class RewardsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // نقاط للأنشطة المختلفة
  static const int POINTS_PER_REPORT = 10;
  static const int POINTS_PER_CONFIRMED_REPORT = 15;
  static const int POINTS_PER_CHAT_MESSAGE = 2;
  static const int POINTS_PER_DAILY_LOGIN = 5;

  // الحصول على نقاط المستخدم
  Future<PointsModel> getUserPoints(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('userPoints')
          .doc(userId)
          .get();

      if (doc.exists) {
        return PointsModel.fromFirestore(doc);
      } else {
        // إنشاء سجل جديد إذا لم يكن موجودًا
        PointsModel newPoints = PointsModel(
          points: 0,
          userId: userId,
          lastUpdated: DateTime.now(),
        );
        await _firestore
            .collection('userPoints')
            .doc(userId)
            .set(newPoints.toMap());
        return newPoints;
      }
    } catch (e) {
      print('Error getting user points: $e');
      return PointsModel(
        points: 0,
        userId: userId,
        lastUpdated: DateTime.now(),
      );
    }
  }

  // إضافة نقاط للمستخدم
  Future<void> addPoints(String userId, int pointsToAdd, String reason) async {
    try {
      // الحصول على نقاط المستخدم الحالية
      PointsModel currentPoints = await getUserPoints(userId);
      
      // تحديث النقاط
      await _firestore.collection('userPoints').doc(userId).set({
        'points': currentPoints.points + pointsToAdd,
        'userId': userId,
        'lastUpdated': Timestamp.now(),
      });

      // تسجيل معاملة النقاط
      await _firestore.collection('pointsTransactions').add({
        'userId': userId,
        'points': pointsToAdd,
        'reason': reason,
        'timestamp': Timestamp.now(),
        'type': 'credit'
      });
    } catch (e) {
      print('Error adding points: $e');
      throw e;
    }
  }

  // إضافة نقاط عند إنشاء بلاغ جديد
  Future<void> addPointsForNewReport(String userId, ReportModel report) async {
    await addPoints(userId, POINTS_PER_REPORT, 'إنشاء بلاغ جديد');
  }

  // إضافة نقاط عند تأكيد بلاغ
  Future<void> addPointsForConfirmedReport(String userId) async {
    await addPoints(userId, POINTS_PER_CONFIRMED_REPORT, 'تأكيد بلاغ');
  }

  // إضافة نقاط عند إرسال رسالة في الدردشة
  Future<void> addPointsForChatMessage(String userId) async {
    await addPoints(userId, POINTS_PER_CHAT_MESSAGE, 'المشاركة في الدردشة');
  }

  // إضافة نقاط لتسجيل الدخول اليومي
  Future<void> addPointsForDailyLogin(String userId) async {
    try {
      PointsModel currentPoints = await getUserPoints(userId);
      
      // التحقق مما إذا كان آخر تحديث كان اليوم
      DateTime lastUpdated = currentPoints.lastUpdated;
      DateTime now = DateTime.now();
      
      // إذا كان آخر تحديث ليس اليوم، أضف نقاط تسجيل الدخول
      if (lastUpdated.day != now.day || 
          lastUpdated.month != now.month || 
          lastUpdated.year != now.year) {
        await addPoints(userId, POINTS_PER_DAILY_LOGIN, 'تسجيل الدخول اليومي');
      }
    } catch (e) {
      print('Error adding daily login points: $e');
    }
  }

  // خصم نقاط من المستخدم (عند استبدال مكافأة)
  Future<bool> deductPoints(String userId, int pointsToDeduct, String reason) async {
    try {
      // الحصول على نقاط المستخدم الحالية
      PointsModel currentPoints = await getUserPoints(userId);
      
      // التحقق من وجود نقاط كافية
      if (currentPoints.points < pointsToDeduct) {
        return false; // نقاط غير كافية
      }
      
      // خصم النقاط
      await _firestore.collection('userPoints').doc(userId).set({
        'points': currentPoints.points - pointsToDeduct,
        'userId': userId,
        'lastUpdated': Timestamp.now(),
      });

      // تسجيل معاملة النقاط
      await _firestore.collection('pointsTransactions').add({
        'userId': userId,
        'points': -pointsToDeduct,
        'reason': reason,
        'timestamp': Timestamp.now(),
        'type': 'debit'
      });
      
      return true; // تم الخصم بنجاح
    } catch (e) {
      print('Error deducting points: $e');
      return false;
    }
  }

  // الحصول على قائمة المكافآت المتاحة
  Future<List<RewardModel>> getAvailableRewards() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('rewards')
          .where('isActive', isEqualTo: true)
          .orderBy('requiredPoints')
          .get();
      
      return snapshot.docs
          .map((doc) => RewardModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting rewards: $e');
      return [];
    }
  }

  // استبدال نقاط بمكافأة
  Future<UserRewardModel?> redeemReward(String userId, String rewardId) async {
    try {
      // الحصول على المكافأة
      DocumentSnapshot rewardDoc = await _firestore
          .collection('rewards')
          .doc(rewardId)
          .get();
      
      if (!rewardDoc.exists) {
        return null;
      }
      
      RewardModel reward = RewardModel.fromFirestore(rewardDoc);
      
      // التحقق من أن المكافأة نشطة
      if (!reward.isActive) {
        return null;
      }
      
      // خصم النقاط
      bool deducted = await deductPoints(
        userId, 
        reward.requiredPoints, 
        'استبدال مكافأة: ${reward.brandName}'
      );
      
      if (!deducted) {
        return null; // فشل في خصم النقاط
      }
      
      // إنشاء مكافأة للمستخدم
      UserRewardModel userReward = UserRewardModel(
        id: '', // سيتم تعيينه بواسطة Firestore
        userId: userId,
        rewardId: rewardId,
        discountCode: reward.discountCode,
        redeemedDate: DateTime.now(),
        expiryDate: reward.expiryDate,
      );
      
      // حفظ المكافأة في Firestore
      DocumentReference docRef = await _firestore
          .collection('userRewards')
          .add(userReward.toMap());
      
      // إعادة المكافأة مع معرف جديد
      return UserRewardModel(
        id: docRef.id,
        userId: userReward.userId,
        rewardId: userReward.rewardId,
        discountCode: userReward.discountCode,
        redeemedDate: userReward.redeemedDate,
        expiryDate: userReward.expiryDate,
      );
    } catch (e) {
      print('Error redeeming reward: $e');
      return null;
    }
  }

  // الحصول على مكافآت المستخدم
  Future<List<UserRewardModel>> getUserRewards(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('userRewards')
          .where('userId', isEqualTo: userId)
          .orderBy('redeemedDate', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => UserRewardModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user rewards: $e');
      return [];
    }
  }
}