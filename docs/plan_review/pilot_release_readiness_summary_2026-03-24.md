# Pilot / Release Readiness Summary

## Current Position
المشروع الآن في وضع مناسب لـ:
- Android pilot
- bugfix-only stabilization

وليس في وضع مناسب حاليًا للادعاء بأن:
- iOS verified
- full multi-platform release confirmed

## What Is Ready
1. Discovery state
- city source-of-truth أوضح
- effective location fallback مربوط بالمدينة المختارة
- sync أفضل بين:
  - `Home`
  - `Results`
  - `Map`
  - `Profile`

2. Navigation and user flows
- back stack صار أوضح
- auth redirects أصلح
- venue details / venue menu flow ثبت

3. Merchant must-work flows
- menu publish/edit/toggle
- offers create/edit/toggle
- scan / redeem
- feedback ورسائل أخطاء أوضح

4. Offer redemption accounting
- percent offers تدعم إدخال قيمة الفاتورة عند التاجر
- التوفير المؤكد يمكن احتسابه عند توفر bill amount
- customer stats وclaims reading أصلحت للمستخدم المسجل

5. Security hardening
- App Check enforced على أهم callables
- storage ownership checks أوضح
- merchant reads في Firestore أشد

## What Was Verified
تم التحقق عمليًا على Android:
- discovery flows
- venue/menu flow
- merchant flows الأساسية
- claim / QR / redeem

## What Is Not Yet Verified
1. iOS smoke test
- غير منفذ بسبب عدم توفر Mac + Xcode

2. Full release-grade regression across every screen
- غير مطلوب الآن إذا الهدف pilot محدود

## Known Limits
1. iOS
- configured in code
- not operationally verified

2. `firebase-functions` SDK
- ما زال على إصدار أقدم
- ليس blocker لهذه المرحلة
- لكنه backlog تقني واضح

3. Guest claim history
- يحتاج قرار منتجي/أمني إذا أردت دعمه رسميًا

## Readiness Decision
### مناسب الآن لـ
- Android pilot
- controlled merchant rollout
- bugfix-only stabilization window

### غير مناسب الآن لـ
- إعلان iOS support as verified
- feature expansion قبل فترة مراقبة واستخدام حقيقي

## Recommended Operating Mode
اعتمد من الآن:
- `freeze on new features`
- `accept small bugfixes only`
- `collect real usage feedback`

## Immediate Next Steps
1. توثيق آخر known limitations في أي channel داخلي أو release note
2. تثبيت window قصيرة للـ pilot
3. تسجيل أي bugs تظهر أثناء الاستخدام الحقيقي
4. تأجيل أي feature جديدة حتى بعد أول دورة feedback
