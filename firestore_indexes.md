# فهارس Firestore المطلوبة

## فهرس البلاغات (Reports)
يجب إنشاء فهرس مركب للاستعلام عن بلاغات المستخدم:

**Collection:** `reports`
**Fields:**
- `createdBy` (Ascending)
- `createdAt` (Descending)
- `__name__` (Descending)

**رابط الإنشاء:**
```
https://console.firebase.google.com/v1/r/project/saferoute-11/firestore/indexes?create_composite=Ckxwcm9qZWN0cy9zYWZlcm91dGUtMTEvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3JlcG9ydHMvaW5kZXhlcy9fEAEaDQoJY3JlYXRlZEJ5EAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg
```

## فهرس المكافآت (Rewards)
يجب إنشاء فهرس مركب للاستعلام عن المكافآت المتاحة:

**Collection:** `rewards`
**Fields:**
- `isActive` (Ascending)
- `requiredPoints` (Ascending)
- `__name__` (Ascending)

**رابط الإنشاء:**
```
https://console.firebase.google.com/v1/r/project/saferoute-11/firestore/indexes?create_composite=Ckxwcm9qZWN0cy9zYWZlcm91dGUtMTEvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3Jld2FyZHMvaW5kZXhlcy9fEAEaDAoIaXNBY3RpdmUQARoSCg5yZXF1aXJlZFBvaW50cxABGgwKCF9fbmFtZV9fEAE
```

## فهرس مكافآت المستخدم (User Rewards)
يجب إنشاء فهرس مركب للاستعلام عن مكافآت المستخدم:

**Collection:** `userRewards`
**Fields:**
- `userId` (Ascending)
- `redeemedDate` (Descending)
- `__name__` (Descending)

**رابط الإنشاء:**
```
https://console.firebase.google.com/v1/r/project/saferoute-11/firestore/indexes?create_composite=ClBwcm9qZWN0cy9zYWZlcm91dGUtMTEvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3VzZXJSZXdhcmRzL2luZGV4ZXMvXxABGgoKBnVzZXJJZBABGhAKDHJlZGVlbWVkRGF0ZRACGgwKCF9fbmFtZV9fEAI
```

## خطوات الإنشاء:

1. انقر على كل رابط من الروابط أعلاه
2. سيتم فتح Firebase Console
3. انقر على "Create Index"
4. انتظر حتى يكتمل إنشاء الفهرس (قد يستغرق بضع دقائق)
5. كرر العملية لكل فهرس

## ملاحظة:
بعد إنشاء جميع الفهارس، ستحتاج إلى إعادة تشغيل التطبيق لتعمل الاستعلامات بشكل صحيح.