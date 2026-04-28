# Admin Web Console Arabic Page UI - UI-037

Date: 2026-04-17
Status: Done
Scope: Media page wording pass after hydration fix

## الهدف

متابعة مسار التعريب صفحة بصفحة على صفحة الصور والملفات بعد تثبيت خطأ hydration في `UI-036`.

## السبب

صفحة الصور والملفات كانت تحتوي مفردات تشغيلية وتقنية صعبة للمستخدم الإداري، مثل:

- `الجرد`
- `الأصل`
- `المرجع`
- `سلامة المرجع`
- `حذف منطقي`
- `حجر`
- `حمولة`
- `وسيط`

هذه المفردات دقيقة تقنيًا لكنها غير مريحة لمستخدم يريد قرارات واضحة وسريعة.

## التغيير

- تبسيط مقدمة الصفحة لتشرح أن الصفحة تعرض صور وملفات الجهات وتوضح التعديلات حسب الصلاحية.
- تغيير ملخص الاستخدام:
  - `المصدر النشط` إلى `مصدر البيانات`.
  - `قناة الإجراءات` إلى `طريقة الاستخدام`.
  - `واجهة محكومة` إلى `تعديل حسب الصلاحية`.
- تغيير مفردات الفلاتر والجدول:
  - `سلامة المرجع` إلى `حالة الارتباط`.
  - `الأصل` إلى `الملف`.
  - `المرجع` إلى `الارتباط`.
  - `المصدر` إلى `مكان الحفظ`.
  - `الإجراءات` إلى `الخيارات`.
- تبسيط أزرار الأوامر:
  - `حذف منطقي` إلى `إخفاء من القائمة`.
  - `حجر` إلى `عزل الملف`.
  - `فحص المرجع` إلى `فحص الارتباط`.
- تبسيط نافذة المعاينة وطلب الاستبدال:
  - `معاينة الوسيط` إلى `معاينة الملف`.
  - `استبدال الأصل` إلى `استبدال الملف`.
  - `حمولة مسودة الاستبدال` إلى `محتوى طلب الاستبدال`.
- تبسيط رسائل مصدر البيانات وحالة الارتباط في loader.

## الملفات

- `wain_app/admin_web_console/components/media/media-center-shell.tsx`
- `wain_app/admin_web_console/components/media/media-command-provider.tsx`
- `wain_app/admin_web_console/lib/media/media-center-baseline.ts`
- `wain_app/admin_web_console/lib/media/media-surface-affordances.ts`
- `wain_app/admin_web_console/components/media/media-center-shell.test.tsx`
- `wain_app/admin_web_console/lib/media/media-center-baseline.test.ts`

## التحقق

- Vitest مركز:
  - `components/media/media-center-shell.test.tsx`
  - `components/media/media-center-route.test.tsx`
  - `lib/media/media-center-baseline.test.ts`
  - `lib/admin/stable-text-sort.test.ts`
  - النتيجة: 4 ملفات، 25 اختبارًا.
- `npx tsc --noEmit --pretty false`
  - مرّ بدون أخطاء.
- فحص نصوص قديمة في ملفات الوسائط المستهدفة:
  - لا توجد بقايا للمفردات القديمة مثل `حذف منطقي`، `حجر`، `فحص المرجع`، `فهرس المراجع`، `حمولة`، `وسيط`، `الأصل`، `الجرد`.
- `npm run build`
  - مرّ بعد إيقاف خادم التطوير لتجنب تعارض `.next`.
- localhost:
  - أعيد تشغيله على `3010`.
  - `/admin/media` رجع `200` بدون `Server Error`.
  - `/admin/venues` رجع `200` بدون `Server Error`.
- فحص متصفح:
  - `/admin/media`: لا يوجد overlay، لا توجد console errors، وظهرت نصوص `طريقة الاستخدام` و`حالة الارتباط`.
  - `/admin/venues`: لا يوجد overlay، لا توجد console errors.

## النتيجة

تم تبسيط صفحة الصور والملفات بدون تغيير RBAC أو loaders أو عقود أوامر الوسائط. الخطوة التالية المنطقية هي متابعة نفس الأسلوب على صفحات المحتوى: العروض ثم القصص.
