# Sprint 0 Baseline Report

Date: `2026-03-23`

## Executive Summary
تم بدء `Sprint 0` من خطة التثبيت.  
النتيجة الأولية: المشروع ليس في وضع "ابدأ إصلاحات عمياء" الآن، بل يحتاج أولًا تثبيت baseline واضح لأن الـ worktree الحالي نفسه يحتوي تعديلات واسعة وغير ملتزمة على نفس المسارات الحرجة.

أهم 4 نتائج:
1. الـ worktree الحالي **dirty** بشكل كبير ويمس:
   - routing
   - auth
   - discovery
   - merchant
   - venue
   - l10n
   - tests
   - functions
2. `iOS` ما زال **غير مهيأ** على مستوى Firebase.
3. `service-account-key.json` **غير متتبع** في git وموجود في `.gitignore`، لكن هناك سكربتات محلية تعتمد عليه.
4. قواعد Firestore تبدو مبدئيًا ذات اتجاه صحيح (`deny-by-default` في مناطق حساسة)، لكن هناك نقاط مراجعة عملية قبل اعتبارها "مغلقة".

---

## Baseline Status

### Git Status
- الفرع الحالي: `main`
- الحالة: `dirty worktree`
- توجد تعديلات/إضافات واسعة على:
  - `lib/**`
  - `functions/**`
  - `test/**`
  - `firestore.rules`
  - `firestore.indexes.json`
  - `docs/**`

### Impact
هذا يعني أن أي تعديل مباشر الآن في الملفات المشتركة قد يختلط مع شغل سابق غير ملتزم، خصوصًا في:
- `lib/core/routing/app_router.dart`
- `lib/features/discovery/**`
- `lib/features/merchant/**`
- `lib/features/venue/**`
- `lib/l10n/**`

---

## iOS Decision Baseline

### Finding
في `lib/firebase_options.dart`:
- `TargetPlatform.android` مهيأ
- `TargetPlatform.web` مهيأ
- `TargetPlatform.iOS` يرمي `UnsupportedError`

### Conclusion
الوضع الحالي ليس "iOS جاهز جزئيًا"، بل:
- مشروع iOS موجود
- لكن Firebase iOS غير مهيأ

### Decision Needed
واحد من الخيارين:
1. `Android/Web only for this cycle`
2. `Add Firebase iOS config in Sprint 0/1`

---

## Secrets Audit Baseline

### service-account-key.json

### Findings
1. الملف `service-account-key.json` **غير متتبع** حاليًا في git.
2. الملف موجود داخل `.gitignore`.
3. توجد استخدامات صريحة له في سكربتات محلية:
   - `scripts/create_invite.js`
   - `functions/scripts/cleanup_menu_import_noise.js`
   - `functions/scripts/cleanup_menu_versions_retention.js`
   - `functions/scripts/migrate_legacy_menu_to_versioned.js`

### Conclusion
- هذا جيد جزئيًا لأنه غير متتبع.
- لكنه ما زال dependency محليًا لعمليات إدارية.
- إذًا الخطر هنا ليس "تسرّب مباشر عبر git" حاليًا، بل:
  - غموض في workflow
  - احتمال استخدام غير منضبط محليًا
  - اعتماد يدوي غير موثق كفاية

### Required Follow-up
1. توثيق استخدامه بدقة
2. التأكد أنه لا يدخل في runtime العادي
3. حصر كل السكربتات التي تحتاجه مقابل السكربتات التي تعمل بدونه

---

## Firestore Rules Quick Audit

### Positive Signals
1. `merchants`:
   - client create/update/delete = `false`
2. `merchant_invites`:
   - no client access
3. `offer_claims`:
   - client write = `false`
4. `visits`:
   - client read/write = `false`
5. `venue_analytics` و`venue_analytics_daily`:
   - read-only لمالك المكان
6. `venue_events`:
   - blocked for clients

### Review Points
1. `navigation_clicks`
- القاعدة الحالية تسمح بالإنشاء إذا:
  - المستخدم مسجل دخول
  - أو `user_id == null`
- هذا قد يكون مقصودًا لدعم guest analytics، لكنه يحتاج مراجعة واعية حتى لا يتحول إلى نقطة spam/noise.

2. `reviews`
- يوجد منطق جيد للفصل بين:
  - تعديل المستخدم لمراجعته
  - تعديل التاجر فقط لحقول الرد
- يحتاج فقط verification سريع على أن الحقول الحساسة لا يمكن التلاعب بها عبر حالات edge.

3. `venues/menu_versions`
- القراءة public فقط للإصدار `active`
- والكتابة للمالك
- هذا اتجاه صحيح.

### Conclusion
قواعد Firestore ليست مكسورة ظاهريًا، لكن لا تعتبر مغلقة بعد.  
هي تحتاج `targeted audit` لا `full rewrite`.

---

## Storage Rules Quick Audit

### Finding
في `storage.rules`:
- upload/update/delete لصور المكان تعتمد على:
  - `request.auth != null`
  - `isValidImage()`
  - `isVenueOwner(venueId)`

### Review Point
`isVenueOwner(venueId)` تعتمد فقط على:
- `users/{uid}.merchant_venue_id`

بينما أجزاء من Firestore logic تستخدم أحيانًا:
- `merchants/{uid}.venue_id`
- أو fallback بين users/merchants

### Conclusion
هذا ليس ثغرة مؤكدة، لكنه **inconsistency محتمل** بين:
- ownership check في Firestore
- ownership check في Storage

وهذا يستحق مراجعة مبكرة.

---

## Functions Quick Audit

### Positive Signals
في `functions/src/index.ts`:
1. `claimOffer`:
   - يتحقق من offer state
   - يمنع claim مكرر/منتهي/مستخدم
   - يستخدم transaction للتحديثات الحرجة
2. `verifyToken`:
   - يتحقق من أن التاجر يملك نفس venue
3. `redeemToken`:
   - يتحقق من merchant ownership
   - يتحقق من claim state
   - يستخدم transaction
4. `redeemInviteCode`:
   - فيه rate limiting bucket
   - يتحقق من invite state
   - يربط المستخدم بالمكان داخل transaction

### Review Points
1. هذه functions تبدو أفضل من جهة الأمن من كثير من أجزاء الـ UI.
2. لا يوجد red flag واضح فوري هنا مثل:
   - missing auth check
   - missing venue ownership check
3. لكن يلزم review focused لاحق على:
   - idempotency
   - abuse surfaces
   - failure logging

---

## CI Baseline

### Current CI
في `.github/workflows/ci.yml`:
1. `flutter pub get`
2. `flutter analyze --no-pub`
3. `flutter test test/core/mojibake_guard_test.dart --no-pub`
4. `flutter test --no-pub`

### Conclusion
هذا baseline جيد، لكنه لا يزال:
- gate عام
- وليس gate مخصصًا للتدفقات الحرجة أو smoke checks

---

## Immediate Risks
1. العمل فوق worktree dirty جدًا سيزيد احتمال الخلط بين التثبيت الجديد وشغل سابق غير ملتزم.
2. iOS status غير محسوم، وهذا يربك scope الإطلاق.
3. secrets workflow غير موثق كفاية.
4. ownership checks بين Firestore وStorage ليست موحدة تمامًا.

---

## Recommended First Fix Order
1. تثبيت قرار iOS:
   - داخل scope الآن أو خارجه مؤقتًا
2. توثيق/تنظيف workflow الخاص بـ `service-account-key.json`
3. مراجعة ownership consistency بين:
   - `firestore.rules`
   - `storage.rules`
4. بعد ذلك فقط:
   - بدء `Sprint 1: Discovery State`

---

## Not Ready Yet
لا أنصح الآن بفتح:
- Merchant hardening
- redesign إضافي
- features جديدة

قبل حسم:
1. iOS decision
2. secrets baseline
3. rules/storage ownership review
4. worktree strategy

---

## Sprint 0 Status
- Baseline collected: `Done`
- iOS decision: `Pending`
- Secrets audit: `In progress`
- Rules/functions quick audit: `Done`
- First executable fix: `Pending decision`
