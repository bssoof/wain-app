# Admin Web Console Hydration Fix - UI-036

Date: 2026-04-17
Status: Done
Scope: Hydration mismatch in filter select options

## المشكلة

ظهرت رسالة Runtime Error من Next.js:

`Text content does not match server-rendered HTML`

وكان المثال الظاهر داخل خيار من خيارات الفلتر:

- Server: `Phase7 venue_phase7_1775874615957`
- Client: `ستونز`

## السبب الجذري

كانت بعض مكونات الفلاتر تبني خيارات `select` عبر `localeCompare` أثناء التصيير الأولي. هذه المكونات تعمل على السيرفر أولًا ثم تعمل مرة ثانية في المتصفح أثناء hydration.

ترتيب النصوص المختلطة عربي/لاتيني عبر `localeCompare` يمكن أن يختلف بين Node.js والمتصفح، خصوصًا عند وجود أسماء fixture لاتينية بجانب أسماء عربية. النتيجة أن السيرفر يضع خيارًا في موضع معيّن، بينما العميل يضع خيارًا آخر في نفس الموضع، فيعتبر React أن HTML غير مطابق.

## الإصلاح

- إضافة مقارن نصوص ثابت لا يعتمد على `Intl` أو `localeCompare`.
- جعل النصوص العربية تظهر قبل النصوص اللاتينية بشكل deterministic.
- استخدام المقارن في المكونات التي تبني خيارات فلاتر أثناء SSR/hydration:
  - قائمة الجهات.
  - مركز الوسائط.
  - إدارة المراجعات.

## الملفات

- `wain_app/admin_web_console/lib/admin/stable-text-sort.ts`
- `wain_app/admin_web_console/lib/admin/stable-text-sort.test.ts`
- `wain_app/admin_web_console/components/venues/venue-directory-shell.tsx`
- `wain_app/admin_web_console/components/media/media-center-shell.tsx`
- `wain_app/admin_web_console/components/reviews/review-moderation-shell.tsx`

## التحقق

- `npx vitest run lib/admin/stable-text-sort.test.ts components/venues/venue-directory-shell.test.tsx components/media/media-center-shell.test.tsx components/reviews/review-moderation-shell.test.tsx`
  - النتيجة: 4 ملفات، 33 اختبارًا.
- `npx tsc --noEmit --pretty false`
  - مرّ بدون أخطاء.
- فحص `localeCompare` داخل `components` و`lib/admin`
  - لا توجد بقايا في المكونات التي قد تعمل أثناء hydration.
- `npm run build`
  - مرّ بعد إيقاف خادم التطوير لتجنب تعارض `.next`.
- إعادة تشغيل localhost على `3010`.
- HTTP:
  - `/admin/venues` رجع `200` بدون `Server Error`.
  - `/admin/media` رجع `200` بدون `Server Error`.
  - `/admin/content/reviews` رجع `200` بدون `Server Error`.
- تحقق متصفحي عبر Playwright:
  - `/admin/venues`: لا يوجد overlay، لا توجد console errors.
  - `/admin/media`: لا يوجد overlay، لا توجد console errors.
  - `/admin/content/reviews`: لا يوجد overlay، لا توجد console errors.

## النتيجة

تم حل سبب hydration mismatch بدون تغيير RBAC أو loaders أو عقود الأوامر. الإصلاح يقلل خطر تكرار نفس المشكلة في صفحات الفلاتر الأخرى التي تحتوي أسماء عربية ولاتينية مختلطة.
