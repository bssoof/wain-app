# Admin Web Console Arabic Page UI - UI-039

Date: 2026-04-17
Status: Done
Scope: Stories page wording pass

## الهدف

متابعة التعريب صفحة بصفحة على صفحة القصص بعد إغلاق صفحة العروض.

## السبب

صفحة القصص كانت تحمل نفس المفردات القديمة التي أُزيلت من صفحة العروض:

- `محكومة من الخادم`
- `عدد الصفوف`
- `المرشحات المطبقة`
- `المعرّف`
- `الحالة الإدارية`
- `الإجراءات`
- `سطح الإدارة`
- `خدمة خصم المحفظة`

## التغيير

- تبسيط مقدمة الصفحة لتشرح مراجعة القصص واتخاذ قرار واضح حسب الصلاحية.
- تغيير ملخص الصفحة:
  - `المصدر` إلى `مصدر البيانات`.
  - `عدد الصفوف` إلى `عدد القصص`.
- تغيير ملاحظات القراءة:
  - `الحداثة` إلى `حالة البيانات`.
  - `المرشحات المطبقة` إلى `الخيارات الحالية`.
  - `الحد` إلى `العدد الأقصى`.
- تغيير البحث:
  - `البحث في القصص` إلى `بحث`.
  - placeholder أصبح `ابحث بنص القصة أو الجهة أو رقم القصة`.
- تغيير الجدول:
  - `الحالة الإدارية` إلى `حالة القصة`.
  - `الإجراءات` إلى `الخيارات`.
- تبسيط نص الترويج:
  - `تديره خدمة خصم المحفظة الآمنة` إلى `يتم التحكم به عبر الخدمة الآمنة`.
- تحديث شاشة التحميل إلى `جاري تحميل القصص`.
- تحديث اختبار route mock ليتبع عناوين navigation العربية الأبسط.

## الملفات

- `wain_app/admin_web_console/components/content/stories-management-shell.tsx`
- `wain_app/admin_web_console/app/(protected)/admin/content/stories/loading.tsx`
- `wain_app/admin_web_console/components/content/content-management-routes.test.tsx`

## التحقق

- فحص نصوص قديمة على صفحات المحتوى:
  - لا توجد بقايا للمفردات القديمة المستهدفة في صفحات العروض والقصص ومكوّناتها.
- Vitest مركز:
  - `components/content/content-management-shells.test.tsx`
  - `components/content/content-management-routes.test.tsx`
  - `lib/content/content-surface-affordances.test.ts`
  - `lib/admin/admin-localization.test.ts`
  - النتيجة: 4 ملفات، 23 اختبارًا.
- `npx tsc --noEmit --pretty false`
  - مرّ بدون أخطاء.
- `npm run build`
  - مرّ بعد إيقاف خادم التطوير لتجنب تعارض `.next`.
- localhost:
  - أعيد تشغيله على `3010`.
  - `/admin/content/stories` رجع `200` بدون `Server Error`.
  - `/admin/content/offers` رجع `200` بدون `Server Error`.
- فحص متصفح:
  - `/admin/content/stories`: لا يوجد overlay، لا توجد console errors، وظهرت نصوص `عدد القصص` و`الخيارات الحالية`.
  - `/admin/content/offers`: لا يوجد overlay، لا توجد console errors.

## النتيجة

تم تبسيط صفحة القصص بدون تغيير RBAC أو loaders أو عقود أوامر المحتوى. الخطوة التالية المنطقية هي صفحة المراجعات لأنها آخر صفحة في مجموعة المحتوى وتحتوي مفردات تشغيلية حول النشر والإخفاء والتصعيد.
