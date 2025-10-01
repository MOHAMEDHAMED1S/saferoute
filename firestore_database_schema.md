# مخطط قاعدة بيانات Firestore - تطبيق SafeRoute

## نظرة عامة
يستخدم تطبيق SafeRoute قاعدة بيانات Firestore لتخزين وإدارة جميع البيانات. هذا المستند يوثق الهيكل الكامل لقاعدة البيانات والمجموعات المستخدمة.

## المجموعات الرئيسية (Collections)

### 1. مجموعة المستخدمين (users)
**المسار:** `users/{userId}`

**الحقول:**
- `id` (String): معرف المستخدم الفريد
- `name` (String): اسم المستخدم
- `email` (String): البريد الإلكتروني
- `phone` (String?): رقم الهاتف (اختياري)
- `photoUrl` (String?): رابط صورة المستخدم (اختياري)
- `points` (int): نقاط المستخدم
- `trustScore` (double): درجة الثقة
- `totalReports` (int): إجمالي التقارير المرسلة
- `createdAt` (Timestamp): تاريخ إنشاء الحساب
- `lastLogin` (Timestamp): آخر تسجيل دخول
- `isDriverMode` (bool): حالة وضع القيادة
- `isOnline` (bool): حالة الاتصال الفوري
- `lastSeen` (Timestamp): آخر ظهور
- `location` (Map): موقع المستخدم
  - `latitude` (double): خط العرض
  - `longitude` (double): خط الطول
  - `timestamp` (Timestamp): وقت تحديث الموقع
  - `accuracy` (double?): دقة الموقع
  - `speed` (double?): السرعة الحالية
- `settings` (Map): إعدادات المستخدم
  - `notifications` (bool): تفعيل الإشعارات
  - `darkMode` (bool): الوضع المظلم
  - `language` (String): اللغة
  - `realTimeUpdates` (bool): التحديثات الفورية
  - `locationSharing` (bool): مشاركة الموقع الفوري
- `fcmTokens` (Array): رموز FCM للإشعارات

### 2. مجموعة التقارير (reports)
**المسار:** `reports/{reportId}`

**الحقول:**
- `id` (String): معرف التقرير الفريد
- `type` (String): نوع التقرير (حادث، ازدحام، طريق مغلق، إلخ)
- `description` (String): وصف التقرير
- `location` (Map): موقع التقرير
  - `latitude` (double): خط العرض
  - `longitude` (double): خط الطول
  - `address` (String?): العنوان
  - `city` (String?): المدينة
  - `country` (String?): البلد
- `createdAt` (Timestamp): تاريخ إنشاء التقرير
- `createdBy` (String): معرف المستخدم الذي أنشأ التقرير
- `status` (String): حالة التقرير (pending, confirmed, denied, resolved)
- `confirmations` (int): عدد التأكيدات
- `confirmedBy` (Array): قائمة معرفات المستخدمين الذين أكدوا
- `deniedBy` (Array): قائمة معرفات المستخدمين الذين رفضوا
- `imageUrls` (Array): روابط الصور المرفقة

**أنواع التقارير المدعومة:**
- `accident`: حادث
- `traffic`: ازدحام مروري
- `roadClosed`: طريق مغلق
- `construction`: أعمال إنشاءات
- `police`: نقطة شرطة
- `hazard`: خطر على الطريق
- `weather`: حالة طقس سيئة

### 3. مجموعة الحوادث (incidents)
**المسار:** `incidents/{incidentId}`

**الحقول:**
- `id` (String): معرف الحادث الفريد
- `userId` (String): معرف المستخدم المبلغ
- `incidentType` (String): نوع الحادث
- `timestamp` (Timestamp): وقت الحادث
- `latitude` (double): خط العرض
- `longitude` (double): خط الطول
- `description` (String): وصف الحادث
- `imageUrl` (String?): رابط صورة الحادث
- `confirmations` (int): عدد التأكيدات
- `isActive` (bool): حالة نشاط الحادث

### 4. مجموعة الإشعارات (notifications)
**المسار:** `notifications/{notificationId}`

**الحقول:**
- `id` (String): معرف الإشعار الفريد
- `userId` (String): معرف المستخدم المستقبل
- `reportId` (String?): معرف التقرير المرتبط (اختياري)
- `title` (String): عنوان الإشعار
- `body` (String): محتوى الإشعار
- `type` (String): نوع الإشعار
- `isRead` (bool): حالة القراءة
- `createdAt` (Timestamp): تاريخ الإنشاء
- `data` (Map?): بيانات إضافية

**أنواع الإشعارات:**
- `report_confirmed`: تأكيد تقرير
- `report_denied`: رفض تقرير
- `new_report_nearby`: تقرير جديد قريب
- `points_earned`: نقاط مكتسبة
- `level_up`: ترقية مستوى

### 5. مجموعة المجتمع (community)
**المسار:** `community/{postId}`

**الحقول:**
- `id` (String): معرف المنشور الفريد
- `userId` (String): معرف المستخدم الناشر
- `userName` (String): اسم المستخدم الناشر
- `title` (String): عنوان المنشور
- `content` (String): محتوى المنشور
- `category` (String): فئة المنشور
- `imageUrls` (Array): روابط الصور المرفقة
- `createdAt` (Timestamp): تاريخ الإنشاء
- `updatedAt` (Timestamp): تاريخ آخر تحديث
- `likes` (int): عدد الإعجابات
- `comments` (int): عدد التعليقات
- `tags` (Array): العلامات
- `location` (Map?): الموقع (اختياري)

### 6. مجموعة دردشة المجتمع (community_chat)
**المسار:** `community_chat/{messageId}`

**الحقول:**
- `id` (String): معرف الرسالة الفريد
- `userId` (String): معرف المرسل
- `userName` (String): اسم المرسل
- `message` (String): محتوى الرسالة
- `timestamp` (Timestamp): وقت الإرسال
- `type` (String): نوع الرسالة (text, image, location)
- `imageUrl` (String?): رابط الصورة (للرسائل المصورة)
- `location` (Map?): بيانات الموقع (لرسائل الموقع)
- `deletedAt` (Timestamp?): وقت الحذف (للرسائل المحذوفة)

### 7. مجموعة القيادة (driving)
**المسار:** `driving/{userId}`

**الحقول:**
- `preferences` (Map): تفضيلات القيادة
  - `safetyMode` (String): وضع الأمان
  - `distanceUnit` (String): وحدة المسافة
  - `voiceAlerts` (bool): التنبيهات الصوتية
  - `autoReport` (bool): التقارير التلقائية
- `statistics` (Map): إحصائيات القيادة
  - `totalDrives` (int): إجمالي الرحلات
  - `totalDistance` (double): إجمالي المسافة
  - `totalDrivingTime` (int): إجمالي وقت القيادة
  - `averageSpeed` (double): متوسط السرعة
  - `maxSpeed` (double): أقصى سرعة
  - `safetyScore` (double): درجة الأمان
- `currentDrive` (Map): الرحلة الحالية
  - `status` (String): حالة الرحلة
- `createdAt` (Timestamp): تاريخ الإنشاء
- `updatedAt` (Timestamp): تاريخ آخر تحديث

### 8. مجموعة الطقس (weather)
**المسار:** `weather/{locationId}`

**الحقول:**
- `location` (String): اسم الموقع
- `temperature` (double): درجة الحرارة
- `condition` (String): حالة الطقس
- `humidity` (int): الرطوبة
- `windSpeed` (double): سرعة الرياح
- `visibility` (double): مدى الرؤية
- `lastUpdated` (Timestamp): آخر تحديث

### 9. مجموعة المكافآت (rewards)
**المسار:** `rewards/{rewardId}`

**الحقول:**
- `id` (String): معرف المكافأة
- `title` (String): عنوان المكافأة
- `description` (String): وصف المكافأة
- `requiredPoints` (int): النقاط المطلوبة
- `isActive` (bool): حالة النشاط
- `imageUrl` (String?): رابط صورة المكافأة
- `createdAt` (Timestamp): تاريخ الإنشاء

### 10. مجموعة مكافآت المستخدم (userRewards)
**المسار:** `userRewards/{userRewardId}`

**الحقول:**
- `userId` (String): معرف المستخدم
- `rewardId` (String): معرف المكافأة
- `redeemedDate` (Timestamp): تاريخ الاستبدال
- `status` (String): حالة المكافأة

### 11. مجموعة الإعدادات (settings)
**المسار:** `settings/{settingId}`

**الحقول:**
- `key` (String): مفتاح الإعداد
- `value` (dynamic): قيمة الإعداد
- `type` (String): نوع البيانات
- `updatedAt` (Timestamp): تاريخ آخر تحديث

### 12. مجموعة التحليلات (analytics)
**المسار:** `analytics/{analyticsId}`

**الحقول:**
- `eventType` (String): نوع الحدث
- `userId` (String?): معرف المستخدم (اختياري)
- `data` (Map): بيانات الحدث
- `timestamp` (Timestamp): وقت الحدث

### 13. مجموعة الأمان (security)
**المسار:** `security/{securityId}`

**الحقول:**
- `userId` (String): معرف المستخدم
- `eventType` (String): نوع حدث الأمان
- `details` (Map): تفاصيل الحدث
- `timestamp` (Timestamp): وقت الحدث
- `ipAddress` (String?): عنوان IP
- `deviceInfo` (Map?): معلومات الجهاز

### 14. مجموعة المسارات (routes)
**المسار:** `routes/{routeId}`

**الحقول:**
- `userId` (String): معرف المستخدم
- `startLocation` (Map): نقطة البداية
- `endLocation` (Map): نقطة النهاية
- `waypoints` (Array): النقاط الوسطية
- `distance` (double): المسافة
- `duration` (int): المدة المتوقعة
- `createdAt` (Timestamp): تاريخ الإنشاء

## الفهارس المطلوبة (Indexes)

### فهرس التقارير
- **Collection:** `reports`
- **Fields:** `createdBy` (Ascending), `createdAt` (Descending), `__name__` (Descending)

### فهرس المكافآت
- **Collection:** `rewards`
- **Fields:** `isActive` (Ascending), `requiredPoints` (Ascending), `__name__` (Ascending)

### فهرس مكافآت المستخدم
- **Collection:** `userRewards`
- **Fields:** `userId` (Ascending), `redeemedDate` (Descending), `__name__` (Descending)

## قواعد الأمان (Security Rules)

### قواعد عامة:
- المستخدمون يمكنهم قراءة وكتابة بياناتهم الخاصة فقط
- التقارير يمكن قراءتها من قبل جميع المستخدمين المصادق عليهم
- الإشعارات خاصة بكل مستخدم
- بيانات المجتمع قابلة للقراءة من قبل جميع المستخدمين

### مثال على قواعد الأمان:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // قواعد المستخدمين
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // قواعد التقارير
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == resource.data.createdBy;
      allow update: if request.auth != null;
    }
    
    // قواعد الإشعارات
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

## ملاحظات مهمة

1. **التخزين المؤقت**: يتم تفعيل التخزين المؤقت لتحسين الأداء في حالة عدم الاتصال
2. **الفهرسة**: يجب إنشاء الفهارس المطلوبة لضمان أداء الاستعلامات
3. **الأمان**: يتم تطبيق قواعد أمان صارمة لحماية بيانات المستخدمين
4. **التحديثات الفورية**: يتم استخدام Firestore Snapshots للتحديثات الفورية
5. **معالجة الأخطاء**: يتم التعامل مع أخطاء الشبكة وانقطاع الاتصال بشكل مناسب

## إحصائيات قاعدة البيانات

- **عدد المجموعات الرئيسية**: 14 مجموعة
- **عدد الفهارس المطلوبة**: 3 فهارس مركبة
- **أنواع البيانات المدعومة**: String, int, double, bool, Timestamp, Array, Map
- **ميزات خاصة**: التحديثات الفورية، التخزين المؤقت، قواعد الأمان المتقدمة

---
