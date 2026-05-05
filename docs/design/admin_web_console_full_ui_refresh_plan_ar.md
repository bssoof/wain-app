# خطة تحسين واجهة لوحة الأدمن - Web Admin Console

آخر تحديث: 2026-05-05  
النطاق: `admin_web_console` داخل مشروع WAIN  
الحالة: خطة تنفيذ مقترحة بعد مراجعة أولية للكود الحالي

## 1. الهدف

تحويل لوحة الأدمن الحالية إلى تجربة تشغيل احترافية، عربية بالكامل، سريعة المسح، واضحة في القرارات، وفيها حركة خفيفة تساعد المستخدم بدون تشتيت.

الخطة لا تستهدف تغيير صلاحيات الأدمن أو عقود البيانات أو أوامر Firebase. التركيز الأساسي هو:

- تحسين الشكل العام والهوية البصرية.
- تحسين التنقل وسرعة الوصول.
- توحيد الجداول والفلاتر والإجراءات.
- إضافة أيقونات وحركة UI خفيفة.
- تقوية تجربة الموبايل والتابلت.
- رفع وضوح الحالات: تحميل، فارغ، خطأ، غير متاح، قيد التنفيذ، نجاح.
- تجهيز tokens للـ dark mode من البداية حتى لو لم يتم إطلاقه في أول نسخة.
- إبقاء نظام التخطيط LTR-aware تحسبا لأي واجهة أدمن إنجليزية لاحقا.

## 2. ما تمت مراجعته

تمت مراجعة الملفات والمسارات التالية لبناء الخطة على الواقع الحالي وليس على تصور عام:

- `admin_web_console/package.json`
- `admin_web_console/app/globals.css`
- `admin_web_console/components/admin/admin-shell.tsx`
- `admin_web_console/components/admin/admin-sidebar.tsx`
- `admin_web_console/components/admin/admin-header.tsx`
- `admin_web_console/lib/navigation/admin-route-map.ts`
- `admin_web_console/components/shared/data-table.tsx`
- `admin_web_console/components/shared/filter-toolbar.tsx`
- `admin_web_console/components/shared/status-badge.tsx`
- `admin_web_console/components/shared/action-panel.tsx`
- `admin_web_console/components/dashboard/operational-dashboard-shell.tsx`
- `admin_web_console/components/finance/topup-queue-table.tsx`
- `admin_web_console/components/venues/venue-directory-shell.tsx`
- `admin_web_console/components/config/config-governance-shell.tsx`
- `docs/release/admin_web_console_ui_improvement_master_plan.md`
- `docs/release/admin_web_console_ui_a02_baseline_capture.md`
- `docs/release/ui_a02_baseline_screenshots`

## 3. ملخص الحالة الحالية

نقاط قوة موجودة:

- مشروع الأدمن مستقل داخل `admin_web_console` ويستخدم Next.js 14.
- الواجهة عربية وRTL من الأساس.
- توجد مسارات واضحة: dashboard, finance, venues, media, content, config.
- يوجد تصميم مركزي عبر `globals.css` مع tokens للألوان والمسافات والحركة.
- توجد مكونات مشتركة مهمة: `DataTable`, `FilterToolbar`, `StatusBadge`, `ActionPanel`.
- يوجد توثيق سابق وخطة master طويلة في `docs/release/admin_web_console_ui_improvement_master_plan.md`.
- يوجد baseline screenshots لكل المسارات الأساسية وعددها 15، وكلها كانت HTTP 200 وقت الالتقاط.
- يوجد اهتمام سابق بالحالات الآمنة: loading, error, unavailable, stale, read-only.

الفجوات التي تحتاج تحسين:

- الواجهة ما زالت تعتمد كثيرا على نصوص داخل الأزرار والروابط، بدون نظام أيقونات واضح.
- `package.json` لا يحتوي حاليا على مكتبة أيقونات مثل `lucide-react` ولا مكتبة حركة مثل `framer-motion`.
- الـ sidebar جيد وظيفيا، لكنه ثقيل بصريا، بدون أيقونات، وبدون نمط desktop compact/collapsed.
- على الشاشات الصغيرة يتحول الـ sidebar إلى شريط علوي طويل، والأفضل تحويله إلى drawer واضح.
- الـ header بسيط جدا: عنوان، اسم المستخدم، زر خروج. يحتاج بحث سريع، breadcrumb، حالة البيئة، وأفعال عامة.
- `globals.css` كبير جدا ويجمع أنماط كل الصفحات، وهذا يصعب تطوير الشكل بدون تأثيرات جانبية.
- الجداول تعمل كـ display table فقط، وتحتاج sticky header، toolbar أعلى الجدول، active filter chips، bulk actions، وحالات empty أجمل.
- الحركة الحالية موجودة كـ transitions بسيطة، لكن لا توجد لغة motion متكاملة للصفحات، المودالات، التوست، والسكلتون.
- بعض الصفحات تستخدم layout شبيه ببعضه لكن بدون PageHeader وCommandBar موحدين.
- صفحات الإجراءات الحساسة مثل topups وconfig تحتاج hierarchy أوضح للقرار، التأكيد، والخطوة التالية.
- لا يوجد dark mode contract واضح داخل tokens الحالية.
- الخطة الحالية عربية بالكامل، لكن يجب تجهيز logical spacing/alignment حتى لا يصبح دعم الإنجليزية لاحقا refactor كبير.
- لا توجد ميزانية أداء رقمية للتغييرات الجديدة مثل bundle size وLCP.
- لا يوجد telemetry واضح لمعرفة أي أجزاء الأدمن يستخدمها الفريق فعلا.

## 4. اتجاه التصميم المقترح

الاتجاه المناسب للوحة الأدمن هو operational SaaS dashboard:

- كثافة معلومات منظمة، بدون hero أو مظهر تسويقي.
- خلفية هادئة، أسطح بيضاء، حدود خفيفة، وتباين واضح.
- ألوان دلالية محدودة: أزرق للأفعال الأساسية، أخضر للنجاح، كهرماني للتحذير، أحمر للخطر، ورمادي للحالات المحايدة.
- تقليل الاعتماد على الأزرق الداكن في كامل الشاشة حتى لا تبدو الواجهة one-note.
- جعل البطاقات والجداول أخف، مع radius أقرب إلى 8px في المكونات الجديدة.
- استخدام أيقونات واضحة داخل التنقل والأزرار، مع tooltips للأيقونات التي قد لا تكون مفهومة وحدها.
- العربية تكون لغة واجهة يومية بسيطة، مع إبقاء المصطلحات التقنية فقط عند الحاجة.

## 5. مبادئ التنفيذ

- عدم تغيير RBAC أو route guards أو command payloads.
- عدم تغيير loaders أو data contracts إلا إذا احتاجت واجهة معينة حقلا جديدا ويكون ذلك بقرار منفصل.
- تنفيذ التحسينات على slices صغيرة وقابلة للاختبار.
- كل slice يجب أن يمر على الأقل بـ TypeScript وVitest المستهدف.
- أي تغيير layout كبير يجب التحقق منه بصور Playwright على desktop وmobile.
- الحركة يجب أن تحترم `prefers-reduced-motion`.
- استخدام CSS motion كخيار أول، وإضافة مكتبة حركة فقط إذا ظهر احتياج حقيقي.
- كل token جديد يجب أن يملك معنى semantic لا اسم لون مباشر، حتى يدعم light/dark لاحقا.
- استخدام logical CSS properties مثل `inline-start`, `inline-end`, `margin-inline`, `padding-inline` بدل ربط التصميم بالـ RTL فقط.
- أي مكتبة جديدة يجب أن تمر على performance budget قبل اعتمادها.

## 6. الخطة التنفيذية

### المرحلة 0: تحديث baseline وتحليل بصري

الهدف: تثبيت نقطة انطلاق قبل أي تغيير جديد.

المهام:

- تشغيل أو تحديث capture للمسارات الموجودة في `docs/release/ui_a02_baseline_screenshots`.
- مراجعة كل لقطة وتسجيل مشاكل واضحة: ازدحام، تداخل، أزرار غير واضحة، مسافات، ضعف hierarchy.
- بناء checklist لكل مسار.
- تحديد صفحات P0:
  - `/admin/dashboard`
  - `/admin/topups`
  - `/admin/venues`
  - `/admin/content/reviews`
  - `/admin/config`

المخرجات:

- ملف triage مختصر للصور الحالية.
- قائمة أولويات P0/P1/P2.

### المرحلة 1: Design System و UI Foundation

الهدف: بناء لغة واجهة قابلة لإعادة الاستخدام بدل تعديل كل صفحة بشكل منفصل.

الملفات المتوقعة:

- `admin_web_console/app/globals.css`
- `admin_web_console/components/shared/*`
- ملفات جديدة مقترحة داخل `admin_web_console/components/shared/ui/*`

المهام:

- إضافة `lucide-react` لاستخدام أيقونات موحدة في:
  - sidebar
  - header actions
  - table actions
  - empty states
  - alerts
- إنشاء مكونات مشتركة:
  - `PageHeader`
  - `CommandBar`
  - `IconButton`
  - `Tooltip`
  - `SegmentedControl`
  - `EmptyState`
  - `SkeletonBlock`
  - `ConfirmDialog`
  - `ToastViewport`
- تحسين tokens:
  - `--radius-card: 8px`
  - `--sidebar-width-expanded`
  - `--sidebar-width-compact`
  - `--header-height`
  - `--motion-enter`
  - `--motion-exit`
  - `--surface-raised`
  - `--surface-hover`
- إضافة dark mode token contract بدون تفعيل الإطلاق مباشرة:
  - `--color-bg`
  - `--color-surface`
  - `--color-surface-muted`
  - `--color-text`
  - `--color-text-muted`
  - `--color-border`
  - `--color-primary`
  - `--color-success`
  - `--color-warning`
  - `--color-danger`
- تجهيز mode selector لاحقا عبر `data-theme="light"` و`data-theme="dark"` أو `html.dark`.
- مراجعة كل token قديم مثل `--bg`, `--surface`, `--line` وربطه تدريجيا بأسماء semantic الجديدة.
- تثبيت LTR-aware foundation:
  - كل spacing واتجاهات border تستخدم logical properties.
  - كل أيقونة اتجاهية مثل الأسهم يجب أن تراعي RTL/LTR.
  - عدم افتراض `text-align: right` داخل المكونات المشتركة إلا عبر container direction.
- تقسيم الأنماط الطويلة تدريجيا إلى sections واضحة أو ملفات CSS module عند الحاجة.

معايير القبول:

- كل زر أيقوني له `aria-label`.
- كل Tooltip يعمل hover وfocus.
- لا توجد حركة عندما يفعّل المستخدم reduced motion.
- لا تتغير عقود البيانات أو الصلاحيات.
- يمكن تبديل tokens نظريا إلى dark بدون إعادة تسمية كل CSS variables.
- لا يوجد CSS جديد يعتمد على `left/right` إلا عند الحاجة التقنية وبقرار موثق.

### المرحلة 2: Shell و Navigation

الهدف: جعل لوحة الأدمن تشعر كنظام واحد واضح.

الملفات المتوقعة:

- `admin_web_console/components/admin/admin-shell.tsx`
- `admin_web_console/components/admin/admin-sidebar.tsx`
- `admin_web_console/components/admin/admin-header.tsx`
- `admin_web_console/lib/navigation/admin-route-map.ts`
- `admin_web_console/app/globals.css`

المهام:

- إضافة أيقونة لكل route في `ADMIN_ROUTE_MAP`.
- تحويل sidebar إلى:
  - expanded desktop mode
  - compact desktop mode
  - mobile drawer
- إضافة زر collapse/expand واضح.
- إظهار active route بشكل أقوى: icon, left/right accent, background.
- إضافة breadcrumb داخل header أو PageHeader.
- إضافة global quick search للانتقال السريع بين صفحات الأدمن.
- إضافة environment badge مثل: Local, Emulator, Live.
- تحسين user menu بدلا من زر خروج منفرد.

الحركة:

- sidebar width animation لمدة 180ms.
- mobile drawer slide-in.
- active route indicator ينتقل بسلاسة.

معايير القبول:

- navigation يعمل بالكيبورد.
- mobile drawer لا يسبب scroll مزدوج.
- لا تتداخل القائمة مع المحتوى على 360px width.

### المرحلة 3: الجداول والفلاتر

الهدف: جعل صفحات العمل اليومية أسرع في القراءة واتخاذ القرار.

الملفات المتوقعة:

- `admin_web_console/components/shared/data-table.tsx`
- `admin_web_console/components/shared/filter-toolbar.tsx`
- الصفحات التي تستخدم الجداول: finance, venues, media, content, config.

المهام:

- توسيع `DataTable` لدعم:
  - sticky header
  - row density: comfortable / compact
  - row hover واضح
  - empty row state
  - loading skeleton rows
  - optional row selection
  - bulk action bar
- تحسين `FilterToolbar`:
  - active filter chips
  - clear all
  - saved common filters لاحقا
  - search input بأيقونة بحث
- تحويل action cells من نصوص كثيرة إلى icon + label عند الحاجة.
- جعل أعمدة الإجراءات ثابتة عند scroll أفقي إذا أمكن.

الحركة:

- filter chip enter/exit.
- table row fade/translate خفيف عند تغير الفلاتر.
- skeleton shimmer بسيط.

معايير القبول:

- لا يتغير sorting أو filtering behavior إلا بشكل مقصود.
- الجدول لا يكسر layout على mobile، ويظل scroll أفقي واضح.
- أزرار الصف لا تتغير أبعادها أثناء pending/success/error.

### المرحلة 4: Dashboard

الهدف: تحويل dashboard إلى شاشة تشغيل يومية تقود الأدمن إلى القرار التالي.

الملفات المتوقعة:

- `admin_web_console/components/dashboard/operational-dashboard-shell.tsx`
- `admin_web_console/components/dashboard/kpi-widget.tsx`
- `admin_web_console/app/(protected)/admin/dashboard/page.tsx`

المهام:

- إضافة top operations strip أوضح:
  - طلبات تحتاج قرار
  - محتوى ينتظر مراجعة
  - مشاكل المحفظة
  - جهات تحتاج متابعة
- إضافة trend mini visuals إن كانت البيانات موجودة.
- إضافة quick actions:
  - فتح طلبات الشحن
  - فتح مراجعات المحتوى
  - فتح حالة النظام
  - فتح الجهات
- تحسين cards لتصبح أكثر scan-friendly.
- إضافة empty states لكل widget عندما لا توجد بيانات.

الحركة:

- KPI cards تظهر stagger بسيط.
- state changes تظهر بدون layout shift.

معايير القبول:

- أول شاشة تعطي قرارا واضحا خلال 5 ثوان.
- لا توجد بطاقة تحتاج قراءة طويلة لفهم الحالة.

### المرحلة 5: Finance Pages

النطاق:

- `/admin/topups`
- `/admin/wallet-audit`
- `/admin/reversals`
- `/admin/readiness`

المهام:

- `topups`:
  - command bar أعلى الجدول.
  - approve/reject بأيقونات واضحة.
  - confirmation dialog موحد.
  - إبراز الطلبات عالية القيمة أو القديمة.
- `wallet-audit`:
  - فلترة أوضح حسب النوع والحالة والتاريخ.
  - timeline أو compact audit view اختياري.
- `reversals`:
  - تحويل النموذج إلى wizard قصير: بيانات العملية، السبب، التأكيد.
  - validation ورسائل أخطاء بجانب الحقول.
- `readiness`:
  - health cards واضحة.
  - ترتيب المشاكل حسب الخطورة.
  - CTA واضح للخطوة التالية.

الحركة:

- pending action state داخل الزر.
- confirm dialog scale/fade.
- toast عند النجاح أو الخطأ.

### المرحلة 6: Venues و Venue Workspace

النطاق:

- `/admin/venues`
- `/admin/venues/[venueId]`

المهام:

- تحسين summary cards في قائمة الجهات.
- إضافة status legend بسيط.
- تحسين action cell:
  - أهم إجراء يظهر كزر مباشر.
  - باقي الإجراءات داخل menu.
- تحسين create/edit dialogs:
  - tabs أو sections: معلومات أساسية، تواصل، صور، ساعات، موقع.
  - sticky footer للحفظ والإلغاء.
- في workspace:
  - header غني بمعلومات الجهة وحالتها.
  - tabs واضحة مع badges.
  - صورة أو media preview عندما تكون متاحة.

الحركة:

- tab transition خفيف.
- dialog step transitions.
- upload progress واضح.

### المرحلة 7: Media و Content Moderation

النطاق:

- `/admin/media`
- `/admin/content/offers`
- `/admin/content/stories`
- `/admin/content/reviews`

المهام:

- media:
  - preview grid أو preview column أوضح.
  - actions بأيقونات: عرض، استبدال، عزل، إخفاء.
  - modal preview بحجم مناسب.
- offers/stories/reviews:
  - review queue layout أوضح.
  - primary decision buttons ثابتة.
  - سبب القرار كجزء واضح من flow.
  - badges للحالة، الخطورة، المصدر.
- توحيد `review action` و`content action` visual pattern.

الحركة:

- content item decision feedback.
- preview modal fade.
- toast بعد القرار.

### المرحلة 8: Config Governance

النطاق:

- `/admin/config`

المهام:

- تحويل الصفحة إلى workflow بصري:
  - تعديل المسودة
  - مراجعة
  - نشر
  - استرجاع
- جعل الخطوة الحالية بارزة.
- تجميع حقول الأسعار بشكل grid واضح.
- إضافة diff preview بين draft وlive إن كانت البيانات متاحة.
- إضافة خطر بصري أوضح قبل publish/rollback.

الحركة:

- stepper progress animation خفيف.
- confirm dialog للـ publish والـ rollback.

### المرحلة 9: Animation System

الهدف: حركة هادئة ومتناسقة في كل اللوحة.

القواعد:

- مدة الحركة الأساسية 120ms إلى 220ms.
- لا توجد حركات طويلة أو bouncing.
- الحركة لا تغير layout بشكل مفاجئ.
- كل الحركة تحت `prefers-reduced-motion`.

أنماط الحركة المطلوبة:

- `fade-in-up` لدخول الصفحة.
- `panel-enter` للبطاقات.
- `drawer-slide` للـ sidebar mobile.
- `dialog-enter` للمودالات.
- `toast-enter` للتنبيهات.
- `row-update` لتحديث صفوف الجداول.
- `skeleton-shimmer` للتحميل.

اقتراح تقني:

- ابدأ بـ CSS classes داخل `globals.css`.
- لا تضف `framer-motion` إلا إذا أصبح لدينا transitions معقدة بين route states أو shared layout.

### المرحلة 10: Responsive و Accessibility

المهام:

- اختبار widths:
  - 360px
  - 390px
  - 768px
  - 1024px
  - 1440px
- التأكد من:
  - عدم تداخل النصوص.
  - عدم خروج الأزرار من الحاويات.
  - hit target لا يقل عن 44px للموبايل.
  - focus visible لكل control.
  - كل icon-only button يملك label.
  - كل dialog يملك title وfocus management.
  - كل toast يملك role مناسب.

معايير القبول:

- لا توجد console errors في Playwright.
- لا يوجد Next overlay.
- لا توجد عناصر متداخلة في screenshots.

### المرحلة 11: Performance و Telemetry

الهدف: منع التحسين البصري من إبطاء لوحة الأدمن، وإضافة قياس يساعدنا نفهم الاستخدام الحقيقي.

المهام:

- تثبيت performance budget قبل إضافة أي مكتبة UI جديدة.
- قياس حجم bundle الحالي قبل إضافة `lucide-react` أو أي مكتبة حركة.
- تسجيل أثر كل dependency جديدة على:
  - JavaScript bundle size
  - route load time
  - build output warnings
- إضافة telemetry خفيف للأحداث الإدارية غير الحساسة:
  - clicks على KPI widgets في dashboard.
  - clicks على quick actions.
  - فتح/إغلاق sidebar أو drawer.
  - استخدام filters في الجداول.
  - command intent للعمليات الحساسة بدون تسجيل payload أو بيانات شخصية.
  - dwell time تقريبي على dashboard والصفحات الرئيسية.
- ربط telemetry باحترام الخصوصية:
  - لا تسجيل لأسماء المستخدمين.
  - لا تسجيل لمبالغ أو IDs حساسة داخل event payload.
  - استخدام route key وaction key فقط عندما يكفي.

ميزانية الأداء المقترحة:

- LCP على صفحات الأدمن الأساسية: `<= 2.5s` على baseline local/staging المتفق عليه.
- TBT أو blocking time بعد التحميل: لا يزيد عن baseline الحالي بأكثر من `50ms`.
- Client JS bundle: لا يزيد عن الحجم الحالي بأكثر من `60 KB gzip` لكل slice رئيسي.
- Route transition blank-screen incidents: `0`.
- Console errors أثناء Playwright smoke: `0`.

معايير القبول:

- أي إضافة dependency جديدة توثق سببها وحجمها التقريبي.
- إذا تخطى slice الميزانية، يتم توثيق السبب أو تقسيمه.
- telemetry لا يرسل بيانات مالية أو معرفات شخصية خام.

## 7. ترتيب التنفيذ المقترح

1. تحديث baseline screenshots وتسجيل مشاكل UI الحالية.
2. تثبيت token contract للـ light/dark وRTL/LTR قبل بناء المكونات.
3. قياس bundle الحالي وتثبيت performance budget.
4. إضافة icon system ومكونات `IconButton`, `Tooltip`, `PageHeader`, `CommandBar`.
5. تحسين shell: sidebar, header, search, mobile drawer.
6. تحسين `DataTable` و`FilterToolbar`.
7. إعادة تصميم Dashboard مع telemetry للأحداث غير الحساسة.
8. تحسين Finance pages.
9. تحسين Venues وWorkspace.
10. تحسين Media وContent Moderation.
11. تحسين Config Governance.
12. تمرير responsive وaccessibility وperformance وvisual smoke.

## 8. ملفات متوقعة للتعديل

ملفات مشتركة:

- `admin_web_console/package.json`
- `admin_web_console/package-lock.json`
- `admin_web_console/app/globals.css`
- `admin_web_console/components/shared/data-table.tsx`
- `admin_web_console/components/shared/filter-toolbar.tsx`
- `admin_web_console/components/shared/status-badge.tsx`
- `admin_web_console/components/shared/action-panel.tsx`
- `admin_web_console/lib/admin/*` عند إضافة telemetry أو theme helpers

ملفات جديدة مقترحة:

- `admin_web_console/components/shared/ui/icon-button.tsx`
- `admin_web_console/components/shared/ui/tooltip.tsx`
- `admin_web_console/components/shared/ui/page-header.tsx`
- `admin_web_console/components/shared/ui/command-bar.tsx`
- `admin_web_console/components/shared/ui/empty-state.tsx`
- `admin_web_console/components/shared/ui/skeleton.tsx`
- `admin_web_console/components/shared/ui/confirm-dialog.tsx`
- `admin_web_console/components/shared/ui/toast.tsx`
- `admin_web_console/components/shared/ui/theme-toggle.tsx` عند اعتماد dark mode في الواجهة
- `admin_web_console/lib/admin/admin-telemetry.ts`

ملفات shell:

- `admin_web_console/components/admin/admin-shell.tsx`
- `admin_web_console/components/admin/admin-sidebar.tsx`
- `admin_web_console/components/admin/admin-header.tsx`
- `admin_web_console/lib/navigation/admin-route-map.ts`

صفحات ومكونات module:

- `admin_web_console/components/dashboard/*`
- `admin_web_console/components/finance/*`
- `admin_web_console/components/venues/*`
- `admin_web_console/components/venue-workspace/*`
- `admin_web_console/components/media/*`
- `admin_web_console/components/content/*`
- `admin_web_console/components/reviews/*`
- `admin_web_console/components/config/*`

## 9. الاختبارات والتحقق

أوامر التحقق الأساسية من داخل `admin_web_console`:

```bash
npm run test
npx tsc --noEmit --pretty false
npm run build
```

تحقق الأداء:

```bash
npm run build
```

بعد كل dependency جديدة:

- مراجعة build output وحجم bundle.
- مقارنة الحجم مع baseline قبل التغيير.
- توثيق أي زيادة تتجاوز `60 KB gzip`.

تحقق بصري:

```bash
npm run capture:ui-a02
```

اختبارات مستهدفة حسب المرحلة:

- shell:
  - `components/admin/admin-shell.test.tsx`
  - `components/admin/admin-sidebar` عند إضافة/تحديث اختبار
  - `lib/navigation/admin-route-map.test.ts`
- shared:
  - `components/shared/data-table.test.tsx`
  - `components/shared/filter-toolbar.test.tsx`
  - tests جديدة لمكونات `ui`
- dashboard:
  - `components/dashboard/operational-dashboard-shell.test.tsx`
- finance:
  - `components/finance/finance-surfaces.test.tsx`
  - `components/finance/topup-confirmation-dialog.test.tsx`
- venues:
  - `components/venues/venue-directory-shell.test.tsx`
  - `components/venue-workspace/venue-workspace-shell.test.tsx`
- content/reviews/config:
  - الاختبارات الموجودة في كل module مع إضافة coverage للحالات الجديدة.

## 10. Definition of Done

تعتبر خطة التحسين مكتملة عندما:

- كل المسارات الأساسية تظهر بتصميم موحد ومحدث.
- sidebar وheader يعملان بشكل ممتاز على desktop وmobile.
- كل الجداول تستخدم نمط DataTable المحسن أو قرار موثق لعدم استخدامه.
- كل صفحة فيها loading, empty, error, unavailable states واضحة.
- الأزرار الحساسة لها confirm واضح ورسائل نتيجة واضحة.
- الحركة موجودة وخفيفة ومحترمة لـ reduced motion.
- token contract يدعم dark mode بدون refactor واسع.
- المكونات المشتركة تستخدم logical properties وتظل LTR-aware.
- performance budget محفوظ أو أي تجاوز موثق ومقبول.
- telemetry الأساسي موجود للأحداث غير الحساسة في dashboard والتنقل والفلاتر.
- Playwright screenshots لا تظهر تداخل أو layout break.
- `npm run test`, `npx tsc --noEmit --pretty false`, و`npm run build` تمر بنجاح.

## 11. ملاحظات مهمة قبل التنفيذ

- يوجد ملف master سابق في `docs/release/admin_web_console_ui_improvement_master_plan.md`. هذه الخطة الجديدة لا تلغيه، بل تلخص مسار UI refresh القادم بشكل عربي وتنفيذي.
- يفضل عند بدء التنفيذ إضافة entry في ملف release log أو إنشاء tracking doc لكل slice.
- يجب الحفاظ على التشغيل الحالي، خاصة أن لوحة الأدمن مرتبطة بصلاحيات وعمليات مالية ومحتوى حساس.
- عند إضافة أي مكتبة جديدة مثل `lucide-react` يجب تشغيل build واختبار bundle/security scan الموجود في scripts.
- dark mode ليس مطلوبا كإطلاق كامل في أول slice، لكن tokens يجب أن تكون جاهزة له من البداية.
- telemetry يجب أن يبقى privacy-safe ولا يسجل payloads حساسة أو بيانات مالية/شخصية خام.
