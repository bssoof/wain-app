# Admin Web Console Live Callable Placeholder Guard - UI-042

Date: 2026-04-17
Status: Done
Scope: Live callable transport guard for placeholder App Check tokens

## السبب

بعد إصلاح تصنيف App Check في `UI-041` بقيت تجربة المستخدم غير مثالية: الزر كان يرسل طلبًا إلى Cloud Functions الحية رغم أن `.env.local` يحتوي App Check token تجريبي/placeholder. النتيجة كانت رفضًا متوقعًا من الشبكة بدل منع الطلب مبكرًا برسالة محلية واضحة.

## الجذر التقني

`createFinanceCallableInvokerFromEnv` كان يعتبر النقل متصلًا بمجرد وجود `NEXT_PUBLIC_WAIN_*_FUNCTIONS_BASE_URL`. لذلك كانت أوامر المراجعات والمحتوى والوسائط والإعدادات قادرة على محاولة استدعاء live callables حتى لو كان App Check token مفقودًا أو placeholder.

## التغيير

- إضافة guard مشترك في `createFinanceCallableInvokerFromEnv`:
  - إذا كان URL حيًا على `cloudfunctions.net` ولا يوجد App Check token، يرجع النقل `not connected`.
  - إذا كان URL حيًا على `cloudfunctions.net` والتوكن placeholder مثل `local-dev-app-check`، يرجع النقل `not connected`.
  - إذا كان URL محليًا/emulator، يسمح بالتوكن التجريبي.
- إضافة ترجمة عربية دقيقة لسبب المنع:
  - `توكن أمان الطلب الحالي تجريبي، لذلك لا يمكن تنفيذ القرار على الخدمة الحية.`
  - `توكن أمان الطلب غير مضبوط، لذلك لا يمكن تنفيذ القرار على الخدمة الحية.`
- تحديث الاختبارات لتثبت:
  - business `failed-precondition` ما زال `409`.
  - App Check failure يصنف `403`.
  - live URL يرفض missing/placeholder App Check token.
  - emulator URL يسمح بالتوكن التجريبي.

## الملفات

- `wain_app/admin_web_console/lib/finance/finance-command-transport.ts`
- `wain_app/admin_web_console/lib/finance/finance-command-transport.test.ts`
- `wain_app/admin_web_console/lib/admin/admin-localization.ts`
- `wain_app/admin_web_console/lib/admin/admin-localization.test.ts`

## التحقق

- Vitest مركز:
  - `lib/finance/finance-command-transport.test.ts`
  - `lib/admin/admin-localization.test.ts`
  - `components/reviews/review-moderation-shell.test.tsx`
  - `lib/reviews/review-moderation-adapters.test.ts`
  - `lib/reviews/review-surface-affordances.test.ts`
  - النتيجة: 5 ملفات، 24 اختبارًا.
- `npx tsc --noEmit --pretty false`
  - مرّ بدون أخطاء.
- `npm run build`
  - مرّ بنجاح.
- localhost:
  - أعيد تشغيله على `3010`.
  - فحص متصفح بعد الضغط على `إخفاء` في `/admin/content/reviews`:
    - تظهر رسالة `توكن أمان الطلب الحالي تجريبي، لذلك لا يمكن تنفيذ القرار على الخدمة الحية.`
    - لا تظهر `تعذر التحقق من أمان الطلب الحالي.`
    - لا تظهر `تعارض`.
    - تظهر الحالة `غير متاح`.
    - لا توجد failed network requests.
    - لا توجد console errors أو page errors أو overlay.

## النتيجة

الواجهة الآن لا ترسل أوامر كتابة إلى Cloud Functions الحية عندما يكون App Check token محليًا/placeholder. هذا لا يجعل الأوامر تنجح؛ النجاح الفعلي يتطلب توكن App Check حي صالح أو تحويل البيئة إلى emulator محلي مضبوط.
