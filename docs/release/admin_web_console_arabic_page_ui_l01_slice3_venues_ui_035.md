# Admin Web Console Arabic Page UI - UI-035

Date: 2026-04-17
Status: Done
Scope: UI-L01 slice 3, verified venues and venue details wording pass

## الهدف

إكمال دفعة صفحات الجهات ضمن مسار التعريب المبسط صفحة بصفحة، مع الحفاظ على عقود الصلاحيات والتحميل والأوامر كما هي.

## السبب

كانت صفحات الجهات ما زالت تعرض مفردات تقنية أو داخلية مثل "دليل الجهات"، "مساحة العمل"، "تبويب"، "قيود محفظة"، "ميزانية المسح"، و"الجاهزية". هذه العبارات صحيحة تقنيًا لكنها غير مناسبة لمستخدم إداري يريد لغة عربية مباشرة وسهلة.

تم تسجيل هذه الدفعة باسم `UI-035` لأن السجل يحتوي إدخالًا سابقًا مكررًا باسم `UI-034`: واحد لإصلاح ARIA، وآخر قديم لإغلاق جزئي لمسار UI-L01. لم يتم حذف أو تعديل السجل القديم، وتمت إضافة هذا السجل لتثبيت التحقق الفعلي لهذه الدفعة.

## نطاق التغيير

- تبسيط صفحة قائمة الجهات:
  - `دليل الجهات` إلى `قائمة الجهات`.
  - `فتح مساحة العمل` إلى `فتح التفاصيل`.
  - `مساحة العمل` إلى `التفاصيل`.
  - `النطاقات المبتورة` إلى `مناطق لم تكتمل`.
  - `ميزانية المسح محدودة والنتائج الحالية جزئية` إلى رسالة أبسط عن جزئية البيانات.
- تبسيط صفحة تفاصيل الجهة:
  - `مساحة عمل الجهة` إلى `تفاصيل الجهة`.
  - `تبويب` و`تبويبات` إلى `قسم` و`أقسام`.
  - `قيود محفظة` إلى `عمليات محفظة`.
  - `الجاهزية` إلى `حالة النظام`.
  - `القيد` إلى `رقم العملية`.
- تبسيط نصوص القراءة فقط والبيانات القديمة.
- تحديث نصوص التحميل والخطأ لمسارات الجهات.
- تحديث الاختبارات لتثبيت المفردات الجديدة.

## الملفات

- `wain_app/admin_web_console/components/venues/venue-directory-shell.tsx`
- `wain_app/admin_web_console/components/venues/venue-directory-read-banner.tsx`
- `wain_app/admin_web_console/components/venue-workspace/venue-workspace-shell.tsx`
- `wain_app/admin_web_console/components/venue-workspace/venue-workspace-header.tsx`
- `wain_app/admin_web_console/components/venue-workspace/venue-workspace-read-banner.tsx`
- `wain_app/admin_web_console/app/(protected)/admin/venues/page.tsx`
- `wain_app/admin_web_console/app/(protected)/admin/venues/[venueId]/page.tsx`
- `wain_app/admin_web_console/app/(protected)/admin/venues/loading.tsx`
- `wain_app/admin_web_console/app/(protected)/admin/venues/[venueId]/loading.tsx`
- `wain_app/admin_web_console/app/(protected)/admin/venues/[venueId]/error.tsx`
- `wain_app/admin_web_console/components/venues/venue-directory-shell.test.tsx`
- `wain_app/admin_web_console/components/venues/venue-directory-route.test.tsx`
- `wain_app/admin_web_console/components/venue-workspace/venue-workspace-shell.test.tsx`

## التحقق

- فحص مفردات قديمة على ملفات الجهات ومساحة الجهة: لا توجد بقايا ظاهرة في ملفات `tsx` غير الاختبارية.
- Vitest مركز مرّ:
  - `components/venues/venue-directory-shell.test.tsx`
  - `components/venue-workspace/venue-workspace-shell.test.tsx`
  - `components/venues/venue-directory-route.test.tsx`
  - `components/venue-workspace/venue-workspace-route.test.tsx`
  - `components/shared/read-state-banner.test.tsx`
  - `lib/admin/admin-localization.test.ts`
  - النتيجة: 6 ملفات، 23 اختبارًا.
- `npx tsc --noEmit --pretty false` مرّ.
- `npm run build` مرّ بعد إيقاف خادم التطوير لتجنب تداخل `.next`.
- تم تشغيل localhost من جديد على المنفذ `3010`.
- تحقق HTTP:
  - `/admin/venues` رجع `200` بدون `Server Error`.
  - `/admin/venues/venue_route_1` رجع `200` بدون `Server Error`.
  - `/admin/dashboard` رجع `200` بدون `Server Error`.
- تحقق متصفح Playwright:
  - `/admin/venues` فتح بدون أخطاء console.
  - ظهرت المفردات الجديدة في الصفحة.

## النتيجة

دفعة الجهات أصبحت مثبتة كجزء من UI-L01 بلغة عربية أبسط وبدون تغيير في RBAC أو المسارات أو عقود الأوامر. الخطوة المنطقية التالية هي متابعة نفس أسلوب المراجعة على صفحة الوسائط لأنها ما زالت تحتوي أكبر كثافة من مفردات تشغيلية مرتبطة بالمعاينة والاستبدال وإجراءات الحوكمة.
