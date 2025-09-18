أريدك أن تطور لي تطبيق موبايل باستخدام Flutter مع Firebase فقط (بدون أي Backend خارجي آخر مثل FastAPI).  
التطبيق هو "تطبيق للسلامة المرورية" يهدف إلى تقليل الحوادث عبر التوعية والإشعارات.  
المطلوب أن يعمل التطبيق على Android و iOS.

⚡ المتطلبات الرئيسية:
1. **تسجيل الدخول والتسجيل**:
   - تسجيل الدخول  بحساب Google عبر Firebase Authentication او Email and password.
   - حفظ بيانات المستخدم في Firestore (الاسم، رقم الهاتف/البريد، الموقع الحالي).

2. **مشاركة الموقع**:
   - المستخدم يعطي إذن مشاركة موقعه الحالي.
   - تخزين الموقع في Firestore مع تحديث لحظي عند الحركة.

3. **الإبلاغ عن المخاطر**:
   - زر "+" لإضافة بلاغ جديد على الخريطة.
   - عند الضغط يظهر قائمة بأنواع المخاطر:
     (حادث، ازدحام، سيارة معطلة، مطب، طريق مغلق).
   - يتم حفظ البلاغ في Firebase Firestore مع:
     (نوع البلاغ – الموقع – وقت البلاغ – معرف المبلّغ).

4. **عرض البلاغات على الخريطة**:
   - استخدام Google Maps SDK داخل التطبيق.
   - عرض جميع البلاغات في المنطقة مع أيقونات حسب نوع البلاغ.
   - عند اقتراب مستخدم من بلاغ (500 متر مثلاً) يظهر له إشعار صوتي وبصري:
     "يوجد حادث بعد 500 متر".

5. **التفاعل مع البلاغات**:
   - أي مستخدم يمكنه تأكيد صحة البلاغ (زر ✅).
   - أو الإبلاغ أنه خطأ (زر ❌).
   - النظام يعطي نقاط ثقة للمستخدمين حسب صحة بلاغاتهم.

6. **وضع القيادة**:
   - عند تفعيل وضع القيادة، يعرض التطبيق تنبيهات صوتية فقط لتقليل التشتت.

7. **صلاحية زمنية للبلاغات**:
   - كل بلاغ له مدة صلاحية (مثلاً: حادث = 2-4 ساعات، مطب = دائم).
   - يتم إزالة البلاغات المنتهية تلقائياً.

8. **اللوحة الإضافية**:
   - صفحة شخصية للمستخدم تحتوي:
     - عدد البلاغات التي أرسلها.
     - نقاط الثقة الخاصة به.
     - إمكانية تعديل البيانات.

⚙️ تقنيات مطلوبة:
- Flutter (Dart).
- Firebase Authentication (Google + Phone).
- Firebase Firestore (لتخزين المستخدمين والبلاغات).
- Firebase Cloud Messaging (للإشعارات).
- Google Maps SDK for Flutter.
- Firebase Storage (إذا احتجنا لرفع صور للبلاغ).

🎨 المطلوب:
- كود نظيف (Clean Code) مع استخدام Provider أو Riverpod لإدارة الحالة.
- تصميم بواجهة بسيطة وحديثة.
- تقسيم الكود إلى شاشات وWidgets منفصلة.
- استخدام أيقونات واضحة لأنواع المخاطر.


📂 Firestore Structure (مقترح)



1. 
users
 🧑‍🤝‍🧑


لكل مستخدم حساب خاص.
users (collection)
  └── userId (document)
        name: "Mohamed Hamed"
        email: "mohamed@email.com"
        phone: "+201234567890"
        photoUrl: "link_to_avatar"
        points: 120
        trustScore: 0.85        // نسبة ثقة المستخدم
        totalReports: 30        // عدد البلاغات اللي عملها
        createdAt: Timestamp
        lastLogin: Timestamp
        isDriverMode: true      // هل مفعّل وضع القيادة؟
        location: {
            lat: 30.123,
            lng: 31.456,
            updatedAt: Timestamp
        }



2. 
reports
 🚨


كل بلاغ مضاف يظهر هنا.
reports (collection)
  └── reportId (document)
        type: "accident"        // (accident, jam, car_breakdown, bump, closed_road)
        description: "حادث بسيط بين سيارتين"
        location: {
            lat: 30.123,
            lng: 31.456
        }
        createdAt: Timestamp
        expiresAt: Timestamp    // وقت انتهاء صلاحية البلاغ
        createdBy: "userId"
        status: "active"        // (active, expired, removed)
        confirmations: {
            trueVotes: 10,
            falseVotes: 2
        }
        confirmedBy: ["user1", "user2"]  // IDs المستخدمين اللي أكدوا
        deniedBy: ["user5"]              // IDs المستخدمين اللي نفوا



3. 
notifications
 🔔 (اختياري، لو عايز تخزن سجل التنبيهات)

notifications (collection)
  └── notificationId (document)
        userId: "userId"
        reportId: "reportId"
        title: "تحذير: حادث بعد 500 متر"
        body: "يرجى توخي الحذر"
        type: "accident_alert"
        isRead: false
        createdAt: Timestamp



4. 
settings
 ⚙️ (إعدادات النظام)

settings (collection)
  └── app (document)
        reportTypes: {
            accident: { expiryHours: 3 },
            jam: { expiryHours: 2 },
            car_breakdown: { expiryHours: 4 },
            bump: { expiryHours: 0 },   // دائم
            closed_road: { expiryHours: 12 }
        }
        driverModeDefaults: {
            alertsOnly: true
        }



5. (اختياري) 
leaderboard
 🏆


لو عايز تعمل ترتيب للمستخدمين حسب النقاط.
leaderboard (collection)
  └── month_2025_09 (document)
        topUsers: [
            { userId: "user1", points: 50 },
            { userId: "user2", points: 40 }
        ]



🔑 المميزات اللي بتغطيها البنية دي:


✅ المستخدمين مع بياناتهم + نقاط الثقة.
✅ البلاغات بأنواعها وصلاحيتها الزمنية.
✅ تأكيد أو نفي صحة البلاغات من باقي المستخدمين.
✅ نظام تنبيهات مرتبط بالبلاغات.
✅ إعدادات مرنة لصلاحيات البلاغ وأنواعها.
✅ دعم وضع القيادة (تنبيهات صوتية فقط).
✅ إمكانية عمل لوحة شرف (Leaderboard) لزيادة التفاعل.

