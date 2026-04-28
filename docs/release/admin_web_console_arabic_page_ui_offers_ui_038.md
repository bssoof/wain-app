# Admin Web Console Arabic Page UI - UI-038

Date: 2026-04-17
Status: Done
Scope: Offers page wording pass

## الهدف

متابعة التعريب صفحة بصفحة على صفحة العروض بعد إغلاق إصلاح hydration وصفحة الصور والملفات.

## السبب

صفحة العروض كانت تحتوي مفردات إدارية/تقنية أقل وضوحًا للمستخدم اليومي، مثل:

- `محكومة من الخادم`
- `عدد الصفوف`
- `المرشحات المطبقة`
- `المعرّف`
- `الحالة الإدارية`
- `الإجراءات`
- `حذف/تعليم` في مسميات عامة مشتركة

## التغيير

- تبسيط مقدمة صفحة العروض لتشرح أن المستخدم يراجع العروض ويتخذ قرارًا حسب الصلاحية.
- تغيير ملخص الصفحة:
  - `المصدر` إلى `مصدر البيانات`.
  - `عدد الصفوف` إلى `عدد العروض`.
- تغيير ملاحظات القراءة:
  - `الحداثة` إلى `حالة البيانات`.
  - `المرشحات المطبقة` إلى `الخيارات الحالية`.
  - `الحد` إلى `العدد الأقصى`.
- تغيير الفلتر:
  - `البحث في العروض` إلى `بحث`.
  - placeholder أصبح `ابحث بعنوان العرض أو الجهة أو رقم العرض`.
- تغيير الجدول:
  - `الحالة الإدارية` إلى `حالة العرض`.
  - `الإجراءات` إلى `الخيارات`.
- تبسيط نص التمييز الآمن:
  - `تديره خدمة خصم المحفظة الآمنة` إلى `يتم التحكم به عبر الخدمة الآمنة`.
- تبسيط مكوّن قرار المحتوى المشترك:
  - `سبب الإجراء` إلى `سبب القرار`.
  - `تأكيد` إلى `تأكيد القرار`.
  - `جارٍ الإرسال` إلى `جارٍ الحفظ`.
  - `تعليم` إلى `وضع علامة`.
- تحديث تحميل صفحة العروض إلى `جاري تحميل العروض`.

## الملفات

- `wain_app/admin_web_console/components/content/offers-management-shell.tsx`
- `wain_app/admin_web_console/components/content/content-action-cell.tsx`
- `wain_app/admin_web_console/lib/content/content-surface-affordances.ts`
- `wain_app/admin_web_console/app/(protected)/admin/content/offers/loading.tsx`
- `wain_app/admin_web_console/lib/admin/admin-localization.ts`

## التحقق

- Vitest مركز:
  - `components/content/content-management-shells.test.tsx`
  - `components/content/content-management-routes.test.tsx`
  - `lib/content/content-surface-affordances.test.ts`
  - `lib/admin/admin-localization.test.ts`
  - النتيجة: 4 ملفات، 23 اختبارًا.
- `npx tsc --noEmit --pretty false`
  - مرّ بدون أخطاء.
- فحص نصوص قديمة على صفحة العروض:
  - صفحة العروض لم تعد تعرض مفردات مثل `عدد الصفوف`، `المرشحات`، `المعرّف`، `الحالة الإدارية`، و`الإجراءات`.
  - البقايا المتبقية موجودة في صفحة القصص، وهي الصفحة التالية المخططة.
- `npm run build`
  - مرّ بعد إيقاف خادم التطوير لتجنب تعارض `.next`.
- localhost:
  - أعيد تشغيله على `3010`.
  - `/admin/content/offers` رجع `200` بدون `Server Error`.
  - `/admin/media` رجع `200` بدون `Server Error`.
- فحص متصفح:
  - `/admin/content/offers`: لا يوجد overlay، لا توجد console errors، وظهرت نصوص `عدد العروض` و`الخيارات الحالية`.
  - `/admin/media`: لا يوجد overlay، لا توجد console errors.

## النتيجة

تم تبسيط صفحة العروض بدون تغيير RBAC أو loaders أو عقود أوامر المحتوى. الخطوة التالية المنطقية هي تطبيق نفس النمط على صفحة القصص لأنها تحتوي نسخة قريبة من مفردات العروض القديمة.
