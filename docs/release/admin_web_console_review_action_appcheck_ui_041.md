# Admin Web Console Review Action App Check Fix - UI-041

Date: 2026-04-17
Status: Done
Scope: Review action failure state clarity

## السبب

عند محاولة تنفيذ قرار مراجعة من `/admin/content/reviews` في البيئة المحلية، كان الطلب يصل إلى callable الحقيقي ثم يُرفض من backend بسبب فشل App Check:

- الرسالة الظاهرة: `تعذر التحقق من أمان الطلب الحالي.`
- الشارة كانت تظهر: `تعارض`

هذا كان مضللًا. السبب ليس تعارض حالة مراجعة، بل رفض أمني بسبب App Check أو توكن غير صالح/غير قابل للتحقق في البيئة الحالية.

## السبب التقني

Cloud Functions ترجع `failed-precondition` عند غياب App Check:

- `functions/src/shared/app-check.ts`
- الرسالة: `App Check verification failed`

طبقة admin web كانت تحول كل `failed-precondition` إلى `409 conflict`. هذا صحيح لحالات business conflict مثل `expected_state`، لكنه غير صحيح لرسائل App Check.

## التغيير

- تحديث `mapBackendErrorToTransportError` لتمييز رسائل App Check وتحويلها إلى `403` بدل `409`.
- إبقاء `failed-precondition` الأخرى مثل `reversal_request_expired` كـ `409`.
- إضافة اختبار يثبت أن App Check لا يظهر كتعارض.
- إضافة اختبار في صفحة المراجعات يثبت أن رسالة App Check تظهر مع حالة `غير متاح`.

## الملفات

- `wain_app/admin_web_console/lib/finance/finance-command-transport.ts`
- `wain_app/admin_web_console/lib/finance/finance-command-transport.test.ts`
- `wain_app/admin_web_console/components/reviews/review-moderation-shell.test.tsx`

## التحقق

- Vitest مركز:
  - `lib/finance/finance-command-transport.test.ts`
  - `components/reviews/review-moderation-shell.test.tsx`
  - `lib/reviews/review-moderation-adapters.test.ts`
  - `lib/reviews/review-surface-affordances.test.ts`
  - النتيجة: 4 ملفات، 18 اختبارًا.
- `npx tsc --noEmit --pretty false`
  - مرّ بدون أخطاء.
- `npm run build`
  - مرّ بنجاح.
- localhost:
  - أعيد تشغيله على `3010`.
  - `/admin/content/reviews` رجع `200`.
- فحص متصفح بعد الضغط على `إخفاء`:
  - ظهرت رسالة `تعذر التحقق من أمان الطلب الحالي.`
  - لم تظهر `تعارض`.
  - ظهرت الحالة `غير متاح`.
  - لا يوجد Next overlay أو page errors.

## ملاحظة مهمة

هذا الإصلاح لا يتجاوز App Check ولا يجعل القرار ينجح بدون توكن صالح. هو يصحح تفسير الفشل في الواجهة فقط. لكي تنجح أوامر المراجعات فعليًا على callable الحقيقي، يجب توفير Auth/App Check tokens صالحة أو تشغيل بيئة emulator مهيأة بنفس شروط الأمان.
