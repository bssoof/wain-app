# Sprint 4 Closure Summary

## Scope
Sprint 4 ركز على:
- security hardening
- deploy sanity
- Android real-device verification
- إغلاق gaps الواضحة في callable functions وstorage/firestore access

## What Was Completed
1. تم تشديد `App Check` على الدوال الحساسة في `functions/src/index.ts`:
- `createClaimToken`
- `validateToken`
- `redeemToken`
- `backfillMerchantAnalytics`
- `redeemInviteCode`
- `promoteStory`
- `trackVenueEvent`
- `searchVenuesInBounds`

2. تم تشديد `firestore.rules`:
- قراءة `merchants` أصبحت محصورة بصاحب الـ `uid` نفسه

3. تم تحديث `storage.rules`:
- دعم مسارات:
  - `venues/{venueId}/photos/{fileName}`
  - `venues/{venueId}/stories/{fileName}`
- دعم فحص الملكية عبر:
  - `users/{uid}.merchant_venue_id`
  - أو `merchants/{uid}.venue_id`
- دعم:
  - صور حتى `5MB`
  - فيديو حتى `50MB`

4. تم إغلاق gap في `searchVenuesInBounds`:
- لم يعد `App Check` warning فقط
- أصبح enforced فعليًا

5. تم تحسين Merchant Story promotion status:
- يظهر سطر واضح تحت الستوري عند الترويج:
  - `مروج حتى ...`

## Related Commits
- `19f3a33` — `fix: tighten security rules and improve story promotion status`
- `83deda9` — `fix: require app check for venue bounds search`

## Deployment Status
تم بنجاح:
- deploy للـ storage rules
- deploy لمجموعة functions الحساسة
- deploy لـ `searchVenuesInBounds`

يجب فقط التأكد تشغيلًا أن `firestore.rules` المنشورة هي آخر نسخة محلية إذا لم يتم التحقق منها بشكل صريح بعد.

## Real-Device Validation
تمت تجربة Android في `profile mode` وتم الإبلاغ أن:
- discovery flows سليمة
- venue/menu flows سليمة
- merchant must-work flows سليمة
- security-tightened callables لم تكسر الاستخدام الأساسي

## iOS Status
دعم iOS:
- `Configured in code`
- `Not operationally verified`

السبب:
- لا توجد بيئة `macOS + Xcode` متاحة لتنفيذ `iOS smoke test`

انظر أيضًا:
- `docs/plan_review/ios_status_note.txt`

## Remaining Open Items
1. `iOS smoke test`
- يحتاج Mac + Xcode

2. release/pilot documentation
- إصدار ملخص جاهزية واضح قبل أي pilot أو release candidate

## Closure Decision
Sprint 4 يعتبر:
- **مغلقًا من جهة الكود**
- **مغلقًا من جهة Android التشغيلية**
- **مفتوحًا فقط من جهة iOS operational verification**

## Recommendation
لا تفتح features جديدة الآن.
المسار الصحيح من هنا:
- freeze feature work
- استقبال bugfixes صغيرة فقط
- أو pilot feedback من الاستخدام الحقيقي
