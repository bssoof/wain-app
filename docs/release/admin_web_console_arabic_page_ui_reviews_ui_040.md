# Admin Web Console Arabic Page UI - UI-040

Date: 2026-04-17
Status: Done
Scope: Reviews page wording pass

## الهدف

متابعة التعريب صفحة بصفحة على صفحة المراجعات بعد إغلاق العروض والقصص.

## السبب

صفحة المراجعات بقيت تعرض مفردات تشغيلية أو داخلية لا يحتاجها مستخدم الأدمن اليومي:

- `مغلفات طلبات`
- `حالات تشغيل`
- `مشغلو المحتوى`
- `عدد الصفوف`
- `الحداثة`
- `المرشحات المطبقة`
- `المعرّف`
- `تأكيد الإجراء`
- `سبب الإجراء`
- `تصعيد`

## التغيير

- تبسيط مقدمة الصفحة لتشرح القرار المتاح بوضوح: نشر، إخفاء، أو إرسال للمراجعة.
- تغيير ملخص الصفحة:
  - `المصدر` إلى `مصدر البيانات`.
  - `عدد الصفوف` إلى `عدد المراجعات`.
- تغيير ملاحظات القراءة:
  - `الحداثة` إلى `حالة البيانات`.
  - `المرشحات المطبقة` إلى `الخيارات الحالية`.
  - `الحد` إلى `العدد الأقصى`.
- تغيير البحث:
  - `البحث في المراجعات` إلى `بحث`.
  - placeholder أصبح `ابحث بنص المراجعة أو الكاتب أو الجهة أو رقم المراجعة`.
- تغيير حالة الفلتر من `معلّم` إلى `تحتاج مراجعة`.
- تغيير الجدول:
  - `الحالة` إلى `حالة المراجعة`.
  - `الإجراءات` إلى `الخيارات`.
  - صياغة رقم المراجعة أصبحت واضحة بدل وضعه بين أقواس.
  - `السبب` أصبح `سبب القرار`.
  - التقييم أصبح `من 5` بدل الصيغة الرقمية المختلطة.
- تغيير خلية القرار:
  - `تأكيد الإجراء` إلى `تأكيد القرار`.
  - `سبب الإجراء` إلى `سبب القرار`.
  - `ملاحظة اختيارية للمشغّل` إلى `ملاحظة اختيارية للفريق`.
  - `جارٍ الإرسال` إلى `جارٍ الحفظ`.
- تغيير تسمية `review_escalate` الظاهرة إلى `إرسال للمراجعة` بدون تغيير مفتاح الأمر أو عقد RBAC.
- تحديث شاشة التحميل إلى `جاري تحميل المراجعات`.

## الملفات

- `wain_app/admin_web_console/components/reviews/review-moderation-shell.tsx`
- `wain_app/admin_web_console/components/reviews/review-action-cell.tsx`
- `wain_app/admin_web_console/lib/reviews/review-surface-affordances.ts`
- `wain_app/admin_web_console/lib/admin/admin-localization.ts`
- `wain_app/admin_web_console/lib/navigation/admin-route-map.ts`
- `wain_app/admin_web_console/app/(protected)/admin/content/reviews/loading.tsx`
- `wain_app/admin_web_console/components/reviews/review-moderation-shell.test.tsx`
- `wain_app/admin_web_console/components/reviews/review-moderation-route.test.tsx`
- `wain_app/admin_web_console/lib/reviews/review-surface-affordances.test.ts`
- `wain_app/admin_web_console/lib/admin/admin-localization.test.ts`

## التحقق

- فحص نصوص قديمة على صفحة المراجعات:
  - لا توجد بقايا للمفردات القديمة المستهدفة داخل الواجهة نفسها.
  - بقيت عبارة `عدد الصفوف` فقط داخل اختبار يؤكد عدم ظهورها.
- Vitest مركز:
  - `components/reviews/review-moderation-shell.test.tsx`
  - `components/reviews/review-moderation-route.test.tsx`
  - `lib/reviews/review-surface-affordances.test.ts`
  - `lib/admin/admin-localization.test.ts`
  - النتيجة: 4 ملفات، 17 اختبارًا.
- `npx tsc --noEmit --pretty false`
  - مرّ بدون أخطاء.
- `npm run build`
  - مرّ بعد إيقاف خادم التطوير لتجنب تعارض `.next`.
- localhost:
  - أعيد تشغيله على `3010`.
  - `/admin/content/reviews` رجع `200` بدون `Server Error`.
  - `/admin/content/stories` رجع `200` بدون `Server Error`.
- فحص متصفح:
  - `/admin/content/reviews`: لا يوجد overlay، لا توجد console errors، وظهرت نصوص `عدد المراجعات` و`الخيارات الحالية`.
  - `/admin/content/stories`: لا يوجد overlay، لا توجد console errors.

## النتيجة

تم تبسيط صفحة المراجعات بدون تغيير RBAC أو loaders أو مفاتيح أوامر المراجعة أو payload contracts. بهذا تكتمل مجموعة المحتوى الأساسية: العروض، القصص، والمراجعات. الخطوة التالية المنطقية هي عمل smoke قصير لمجموعة المحتوى أو الانتقال إلى صفحة إعدادات التطبيق.
