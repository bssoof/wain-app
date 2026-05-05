# UI A02 Baseline Findings (Authenticated)

**Date:** 2026-05-05
**Capture base URL:** http://127.0.0.1:3010 (local dev)
**Session:** WAIN_ADMIN_SESSION_JSON injected (super_admin)
**Routes captured:** 15
**Viewport:** 1728 x 1117 (desktop)
**Screenshot dir:** docs/release/ui_a02_baseline_screenshots/
**Review method:** Manual vision review of all 15 PNG screenshots by Codex

## Methodology

Each route has a triage block:
- **P0** — visual issues blocking core admin work or creating serious decision risk
- **P1** — issues hurting scan-ability, hierarchy, or repeated daily workflows
- **P2** — polish items with lower operational impact
- **Action items** — concrete fixes mapped to the UI refresh master plan phases

Categories considered while reviewing:
- Visual hierarchy and what stands out first
- Density and wasted space
- Semantic color and contrast
- Typography, alignment, and RTL rhythm
- Iconography gaps and text-only controls
- Loading, empty, error, stale, and unavailable states
- Action affordances and decision confidence
- Information architecture inside repeated tables and cards

---

## `/admin` — Admin root (redirect target check)

**Master priority:** P2
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/01_admin_index.png`
**Capture status:** HTTP 200 | shot: `01_admin_index.png`

### Visual issues

**P0:**
- [ ] لا توجد مشكلة P0 ظاهرة في اللقطة.

**P1:**
- [ ] منطقة المحتوى الرئيسية فارغة بالكامل بعد الـ header، ولا تعرض حالة واضحة مثل redirect target أو empty state؛ هذا يجعل `/admin` يبدو كصفحة مكسورة رغم أن الـ sidebar ظاهر.
- [ ] لا يوجد breadcrumb أو PageHeader داخل المحتوى يوضح أين وصل المستخدم بعد دخول `/admin`.

**P2:**
- [ ] الـ sidebar يعتمد على النص فقط بدون أيقونات، ما يجعل مسح الأقسام أبطأ.
- [ ] زر تسجيل الخروج في أعلى المحتوى بعيد بصريا عن معلومات المستخدم ولا يظهر كجزء من user menu.

### Action items (mapped to master plan phases)

- [ ] **Phase 1:** إضافة EmptyState مشترك لـ `/admin` يوضح أن هذه صفحة توجيه أو نقطة دخول عامة.
- [ ] **Phase 2:** توحيد الـ shell بإضافة breadcrumb وuser menu وأيقونات للـ sidebar.

---

## `/admin/sign-in` — Sign-in page

**Master priority:** P2
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/02_sign_in.png`
**Capture status:** HTTP 200 | shot: `02_sign_in.png`

### Visual issues

**P0:**
- [ ] لا توجد مشكلة P0 ظاهرة في اللقطة.

**P1:**
- [ ] صفحة تسجيل الدخول خالية من أي إشارة للبيئة أو المنتج غير عنوان النص، فلا يظهر بوضوح هل الدخول محلي أو staging أو live.
- [ ] لا توجد مساحة ظاهرة لرسائل الخطأ أو التحذير بجانب الحقول؛ عند فشل الدخول غالبا ستظهر الرسائل كإضافة مفاجئة قد تغير ارتفاع البطاقة.

**P2:**
- [ ] البطاقة في منتصف شاشة واسعة جدا مع فراغ كبير حولها؛ التصميم نظيف لكنه لا يحمل هوية بصرية واضحة للوحة WAIN.
- [ ] رابط "عرض حالة رفض الوصول" يظهر كوصلة نصية صغيرة في أسفل البطاقة، وقد يبدو كعنصر ثانوي غير مهم.

### Action items (mapped to master plan phases)

- [ ] **Phase 1:** إضافة Alert/InlineError pattern لرسائل تسجيل الدخول بدون layout shift.
- [ ] **Phase 2:** إضافة environment badge خفيف في auth/shell surfaces.
- [ ] **Phase 10:** التحقق من تمركز البطاقة وحجم الحقول على 360px و390px.

---

## `/admin/access-denied` — Access denied page

**Master priority:** P2
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/03_access_denied.png`
**Capture status:** HTTP 200 | shot: `03_access_denied.png`

### Visual issues

**P0:**
- [ ] لا توجد مشكلة P0 ظاهرة في اللقطة.

**P1:**
- [ ] بطاقة رفض الوصول لا تحتوي على أيقونة أو لون دلالي واضح للخطر/المنع، لذلك لا تختلف بصريا كثيرا عن صفحة معلومات عادية.
- [ ] "المسار المطلوب: نظرة عامة" يظهر كنص ثانوي صغير ولا يوضح للمستخدم ما الإذن المطلوب أو ما الخطوة التالية غير تسجيل الدخول.

**P2:**
- [ ] المساحة الكبيرة حول البطاقة تجعل الصفحة هادئة جدا لكنها قليلة المعلومات بالنسبة لحالة صلاحيات.
- [ ] رابط العودة إلى تسجيل الدخول يمكن أن يكون زر CTA أوضح.

### Action items (mapped to master plan phases)

- [ ] **Phase 1:** بناء ErrorState/AccessDenied state بأيقونة دلالية ونص سبب أوضح.
- [ ] **Phase 2:** إضافة رابط رجوع آمن إلى الصفحة السابقة أو dashboard عند توفر session.

---

## `/admin/dashboard` — Operational dashboard

**Master priority:** P0
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/04_dashboard.png`
**Capture status:** HTTP 200 | shot: `04_dashboard.png`

### Visual issues

**P0:**
- [ ] لا توجد مشكلة P0 ظاهرة في اللقطة؛ الصفحة تعمل وتعرض مؤشرات تشغيلية أساسية.

**P1:**
- [ ] شريط المؤشرات العلوي يعرض أربع قيم في صندوق طويل واحد بدون أيقونات أو تسميات قوية؛ الأرقام المهمة لا تقود العين بسرعة للقرار التالي.
- [ ] بطاقة "محتوى ينتظر المراجعة" تحتوي صندوق "أحدث العروض" ضيق داخل البطاقة، والنصوص التقنية الطويلة مثل معرف العرض تضغط القراءة وتكسر الإيقاع.
- [ ] بطاقة "طلبات الشحن" تعرض empty state نصي فقط داخل مساحة كبيرة، بدون أيقونة أو CTA لفتح السجل أو تغيير الفلتر.
- [ ] بطاقات dashboard الأربع ليست متوازنة في الارتفاع والمحتوى؛ بعض البطاقات غنية بالأرقام وبعضها شبه فارغ، ما يضعف scan-ability.

**P2:**
- [ ] معلومات "المصدر" و"آخر تحديث" مكررة أسفل عدة بطاقات وتضيف ضجيجا بصريا.
- [ ] الـ badges مثل "محدث" و"لا بيانات" صغيرة ولا تساعد وحدها على فهم الحالة.
- [ ] الـ sidebar النشط واضح بإطار، لكنه ما زال نصيا بالكامل بدون icons.

### Action items (mapped to master plan phases)

- [ ] **Phase 4:** تحويل شريط المؤشرات إلى KPI widgets بأيقونات وحالات واضحة وأولوية قرار.
- [ ] **Phase 4:** إضافة QuickActions واضحة من dashboard إلى الشحن والمراجعات والجهات وحالة النظام.
- [ ] **Phase 1:** إضافة EmptyState مشترك للبطاقات الفارغة مع CTA اختياري.
- [ ] **Phase 11:** إضافة telemetry privacy-safe لنقرات KPI والـ quick actions.

---

## `/admin/topups` — Top-up queue

**Master priority:** P0
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/05_topups.png`
**Capture status:** HTTP 200 | shot: `05_topups.png`

### Visual issues

**P0:**
- [ ] لا توجد مشكلة P0 ظاهرة في اللقطة؛ حالة عدم وجود طلبات واضحة نصيا.

**P1:**
- [ ] empty state داخل "طلبات الشحن التي تنتظر القرار" نصي فقط ولا يوضح إن كان السبب عدم وجود بيانات، فلتر، أو انتهاء قائمة العمل.
- [ ] لا توجد CommandBar فوق قائمة الشحن توضح الإجراءات المتاحة مثل refresh أو عرض الأرشيف أو تغيير النطاق الزمني.
- [ ] شريط مصدر البيانات منفصل في بطاقة رفيعة فوق المحتوى ويأخذ مساحة دون أن يساعد على اتخاذ القرار.

**P2:**
- [ ] يوجد فراغ عمودي كبير بين عنوان الصفحة وصندوق الحالة، ما يجعل الصفحة تبدو أخف من بقية صفحات finance.
- [ ] لا توجد أيقونة أو لون نجاح خفيف في empty state لتأكيد أن الوضع طبيعي.

### Action items (mapped to master plan phases)

- [ ] **Phase 5:** إضافة EmptyState خاص بطلبات الشحن يميز بين "لا توجد طلبات" و"فلتر لا يطابق".
- [ ] **Phase 1:** بناء CommandBar مشترك يعرض refresh/range/actions أعلى كل queue.
- [ ] **Phase 3:** تجهيز DataTable skeleton/empty rows لظهور الطلبات لاحقا بنفس المساحة.

---

## `/admin/wallet-audit` — Wallet audit

**Master priority:** P1
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/06_wallet_audit.png`
**Capture status:** HTTP 200 | shot: `06_wallet_audit.png`

### Visual issues

**P0:**
- [ ] لا توجد مشكلة P0 ظاهرة، لكن قراءة الجدول الحالي مرهقة لصفحة مالية يومية.

**P1:**
- [ ] جدول سجل المحفظة كثيف جدا؛ معرفات العمليات الطويلة بخط عريض تهيمن على الصفوف وتدفع المعلومات المالية المهمة إلى الخلف.
- [ ] عمود "تصحيح العملية" يكرر رسالة طويلة في كل صف، ما يزيد ارتفاع الصفوف دون قيمة قرارية جديدة.
- [ ] لا يوجد sticky header أو density toggle ظاهر، والجدول طويل بما يكفي ليصعب تتبع الأعمدة أثناء التمرير.
- [ ] ملخص الأرقام أعلى الجدول مسطح بصريا ولا يبرز المخاطر مثل إجمالي الخصم أو آخر عملية.

**P2:**
- [ ] أزرار/شرائح النوع مثل "إضافة" صغيرة ومتكررة وتحتاج لون semantic أكثر وضوحا.
- [ ] العملة تظهر بجانب الأرقام بشكل ضيق وقد تبدو ملتصقة بالقيمة.

### Action items (mapped to master plan phases)

- [ ] **Phase 3:** تحسين DataTable بدعم sticky header وdensity compact/comfortable.
- [ ] **Phase 5:** تحويل wallet audit إلى compact audit view يبرز المبلغ، النوع، المرجع، والحالة قبل المعرفات الطويلة.
- [ ] **Phase 3:** اختصار رسائل "لا يوجد إجراء تصحيح" إلى badge أو tooltip بدلا من جملة مكررة.

---

## `/admin/reversals` — Reversals

**Master priority:** P1
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/07_reversals.png`
**Capture status:** HTTP 200 | shot: `07_reversals.png`

### Visual issues

**P0:**
- [ ] إجراء مالي حساس "اعتماد التصحيح" يظهر كحقل رقم طلب وزر مباشر فقط، بدون مراجعة تفاصيل العملية أو خطوة تأكيد مرئية؛ هذا يرفع خطر اعتماد طلب خاطئ.

**P1:**
- [ ] نموذج الاعتماد موزع أفقيا داخل بطاقة كبيرة، لكن مسار القرار غير واضح: ما الذي سيحدث بعد إدخال الرقم؟ وما هي البيانات التي ستظهر قبل الاعتماد؟
- [ ] شرائح الحالة والصلاحية في بداية البطاقة قليلة الأثر ولا تعطي hierarchy كافيا للإجراء الحساس.
- [ ] لا تظهر رسائل validation أو مثال تفصيلي لمعرف طلب حقيقي، فقط placeholder عام.

**P2:**
- [ ] badge "جاهز" منفصل أعلى يسار البطاقة وبعيد عن الزر، لذلك لا يدعم القرار في لحظة التنفيذ.
- [ ] البطاقة واسعة جدا مقارنة بعدد الحقول، ما يجعل الصفحة تبدو فارغة.

### Action items (mapped to master plan phases)

- [ ] **Phase 5:** تحويل reversals إلى wizard قصير: إدخال الطلب، عرض تفاصيل العملية، ثم تأكيد الاعتماد.
- [ ] **Phase 1:** استخدام ConfirmDialog موحد لكل عملية مالية حساسة.
- [ ] **Phase 5:** إضافة validation inline ورسائل خطأ بجانب حقل رقم طلب التصحيح.

---

## `/admin/readiness` — Readiness/health

**Master priority:** P1
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/08_readiness.png`
**Capture status:** HTTP 200 | shot: `08_readiness.png`

### Visual issues

**P0:**
- [ ] لا توجد مشكلة P0 ظاهرة؛ الصفحة تعرض حالة النظام والفحوصات الأساسية.

**P1:**
- [ ] ملخص حالة المحفظة لا يستخدم hierarchy قوي للحالة العامة؛ badge "الحالة العامة: جاهز" صغير في طرف البطاقة بينما النتيجة الأهم تستحق مركزا بصريا أعلى.
- [ ] زر "تحديث حالة النظام" عريض جدا وموجود داخل مساحة كبيرة، لكنه لا يوضح هل هو إجراء آمن أو متى يلزم تشغيله.
- [ ] قائمة الفحوصات تظهر كصفوف كبيرة متباعدة، ولا يوجد ترتيب بصري واضح حسب الخطورة لأن كل شيء يبدو سليما بنفس الوزن.

**P2:**
- [ ] تكرار timestamps ومصدر البيانات يضيف ضجيجا هادئا في صفحة يفترض أن تكون health dashboard مختصرة.
- [ ] أزرار "عرض تقارير الجهات" و"مراجعة أرصدة الجهات" تبدو ثانوية جدا رغم أنها خطوات متابعة.

### Action items (mapped to master plan phases)

- [ ] **Phase 5:** إعادة ترتيب readiness إلى health cards حسب الخطورة مع CTA واضح لكل فحص.
- [ ] **Phase 1:** إضافة HealthState component بأيقونات نجاح/تحذير/خطر.
- [ ] **Phase 9:** إضافة row-update خفيف عند تحديث الفحوصات بدون layout shift.

---

## `/admin/venues` — Venues directory

**Master priority:** P0
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/09_venues_directory.png`
**Capture status:** HTTP 200 | shot: `09_venues_directory.png`

### Visual issues

**P0:**
- [ ] لا توجد مشكلة P0 واحدة تمنع العمل، لكن الجدول الحالي شديد الكثافة لصفحة P0 يومية.

**P1:**
- [ ] جدول الجهات يعرض معلومات كثيرة في صفوف عالية: badges للحالة، التصنيفات، المحفظة، رابط التاجر، وأزرار متعددة؛ صعب مسح الجهات التي تحتاج تدخل سريع.
- [ ] لا توجد status legend قريبة تشرح معنى "جاهز"، "فشل"، "تحذير"، "ظاهر"، "مخفي"، "نشط"، "منتهي" رغم كثرة الشرائح.
- [ ] منطقة الإجراءات في كل صف مكررة وثقيلة: dropdown، زر "تعديل الملف"، badge "غير معروف"، ورابط "فتح التفاصيل"؛ الأهم لا يبرز.
- [ ] الفلاتر موجودة، لكن لا توجد active filter chips أو clear all، ولا يظهر أي بحث محفوظ للسيناريوهات اليومية.
- [ ] لا توجد أي صور/معاينة للجهة، فيصعب تمييز الجهات بصريا داخل قائمة طويلة.

**P2:**
- [ ] summary cards أعلى الجدول مفيدة لكنها مسطحة ولا تبرز الجهات الفاشلة أو التحذيرات.
- [ ] بعض أسماء الجهات والمعرفات الإنجليزية الطويلة تخلق تفاوتا بصريا داخل عمود الجهة.

### Action items (mapped to master plan phases)

- [ ] **Phase 6:** إعادة تصميم action cell بحيث يظهر الإجراء الأساسي فقط والباقي داخل menu.
- [ ] **Phase 3:** تحسين DataTable بدعم sticky header، density، وربما pinned action column.
- [ ] **Phase 6:** إضافة status legend وصورة/thumbnail عند توفرها.
- [ ] **Phase 3:** إضافة active filter chips وclear all في FilterToolbar.

---

## `/admin/venues/[venue]` — Venue workspace

**Master priority:** P1
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/10_venues_workspace.png`
**Capture status:** HTTP 200 | shot: `10_venues_workspace.png`

### Visual issues

**P0:**
- [ ] لا توجد مشكلة P0 ظاهرة؛ workspace يعرض معلومات الجهة والمحفظة.

**P1:**
- [ ] بطاقة رأس الجهة كبيرة جدا وفيها فراغ واسع؛ رابط "العودة إلى الجهات" معزول في الطرف الأيسر ومعلومات الجهة في الطرف الأيمن، فتضعف وحدة الـ header.
- [ ] اسم الجهة يظهر بالإنجليزية "Venue wan_01" مع نص "Core checks are healthy..." داخل واجهة عربية، ما يكسر الاتساق اللغوي في مساحة مركزية.
- [ ] التبويبات صغيرة ومنفصلة بصريا عن المحتوى، ولا تحتوي badges توضح عدد عناصر المحفظة/العروض/القصص/المراجعات.
- [ ] لا توجد صورة أو media preview للجهة في header رغم أن workspace مكان طبيعي لتمييز الجهة.

**P2:**
- [ ] جدول المحفظة في الأسفل بسيط جدا ويبدو منفصلا عن سياق الجهة.
- [ ] استخدام الشرائح للحالة والمحفظة جيد، لكنه يحتاج ترتيب أقرب لاسم الجهة.

### Action items (mapped to master plan phases)

- [ ] **Phase 6:** بناء VenueHeader غني يجمع الاسم، الحالة، الرصيد، الرجوع، والصورة في block واحد.
- [ ] **Phase 6:** إضافة tabs واضحة مع badges ومحتوى نشط مرتبط بصريا.
- [ ] **Phase 1:** توحيد اللغة داخل المكونات المشتركة أو وضع سياسة fallback للنصوص الإنجليزية.

---

## `/admin/media` — Media library

**Master priority:** P1
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/11_media.png`
**Capture status:** HTTP 200 | shot: `11_media.png`

### Visual issues

**P0:**
- [ ] هدف الصفحة هو مراجعة الصور والملفات، لكن كل الصفوف الظاهرة تعرض "لا توجد معاينة مباشرة لهذا الملف" ولا توجد thumbnails؛ هذا يضعف القدرة على مراجعة media بصريا من الصفحة نفسها.

**P1:**
- [ ] التحذير الأصفر أعلى الصفحة عريض جدا ويظهر قبل العنوان، فيصبح أول ما يراه المستخدم رغم أن النص يقول إن المشكلة لا تؤثر على العمل.
- [ ] لوحة الخيارات اليسرى داخل الجدول تستهلك مساحة كبيرة وتكرر حالة عنصر واحد، بينما قائمة الملفات الأساسية أضيق.
- [ ] التبويبات/الشرائح "صور الإثبات، صور الجهات..." تبدو كأزرار pill لكنها لا تعرض أعدادا واضحة لكل قسم، ووسم "بيانات قديمة" منفصل عنها.
- [ ] الفلاتر والبحث لا تعرض active chips ولا تمييز لحالة الارتباط المختارة.

**P2:**
- [ ] النصوص التقنية الطويلة لأسماء الملفات والمعرفات تهيمن على الصفوف.
- [ ] زر "إخفاء" في التحذير يبدو كزر مستقل لكنه لا يوضح هل يخفي التحذير مؤقتا أم دائما.

### Action items (mapped to master plan phases)

- [ ] **Phase 7:** إضافة preview grid أو preview column بصور مصغرة وحالة fallback واضحة عند غياب الملف.
- [ ] **Phase 7:** تحويل إجراءات media إلى أيقونات واضحة: عرض، استبدال، عزل، إخفاء.
- [ ] **Phase 3:** تحسين الفلاتر بإظهار active chips وحالة الارتباط الحالية.
- [ ] **Phase 1:** توحيد AlertBanner بحيث لا يهيمن على الصفحة عندما يكون warning غير حرج.

---

## `/admin/content/offers` — Content offers moderation

**Master priority:** P1
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/12_content_offers.png`
**Capture status:** HTTP 200 | shot: `12_content_offers.png`

### Visual issues

**P0:**
- [ ] لا توجد مشكلة P0 ظاهرة، لكن قرار مراجعة العروض يحتاج سياق أغنى مما تعرضه الصفوف الحالية.

**P1:**
- [ ] التحذير الأصفر أعلى الصفحة يهيمن على أول الشاشة ويؤخر الوصول إلى queue المراجعة.
- [ ] الجدول يعرض عنوان العرض والجهة والحالة، لكنه لا يعرض ملخص العرض، التاريخ، السعر/الخصم، أو معاينة تساعد على قبول/رفض مستنير.
- [ ] منطقة الخيارات في كل صف تعرض dropdown ثم زر "اعتماد" حتى للصفوف المعتمدة بالفعل، ما يضيف أفعال تبدو قابلة للتنفيذ رغم أن الرسالة تقول "العرض بالحالة المطلوبة بالفعل".
- [ ] لا توجد أزرار قرار أساسية ثابتة أو flow واضح يطلب سبب القرار عند الرفض/الإيقاف.

**P2:**
- [ ] الأعمدة واسعة جدا وبعض الصفوف فيها فراغ أبيض كبير بين العنوان والخيارات.
- [ ] الحالة "قيد المراجعة" تظهر كـ badge واضح، لكن لا يوجد ترتيب يرفعها أعلى من المعتمدة.

### Action items (mapped to master plan phases)

- [ ] **Phase 7:** إعادة تصميم offers queue لتعرض ملخص العرض والجهة والحالة والقرار الأساسي في صف واحد.
- [ ] **Phase 7:** إظهار primary decision buttons فقط عند الحاجة، وإخفاء الأفعال غير القابلة للتطبيق.
- [ ] **Phase 1:** إضافة ConfirmDialog/Reason field للقرارات الحساسة أو الرفض.
- [ ] **Phase 3:** إضافة sorting/filter preset للعناصر قيد المراجعة.

---

## `/admin/content/stories` — Content stories moderation

**Master priority:** P1
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/13_content_stories.png`
**Capture status:** HTTP 200 | shot: `13_content_stories.png`

### Visual issues

**P0:**
- [ ] صفحة مراجعة القصص لا تعرض نص القصة أو صورة/preview للقصة في الصفوف الظاهرة؛ القرارات المتاحة تعتمد على معرفات تقنية فقط، وهذا لا يكفي لاتخاذ قرار moderation موثوق.

**P1:**
- [ ] عمود الخيارات ضخم ويتكرر داخله أربع بطاقات أفعال لكل قصة: اعتماد، رفض، وضع علامة، إيقاف؛ هذا يستهلك ارتفاعا كبيرا ويجعل الصف الواحد يبدو كلوحة كاملة.
- [ ] التحذير الأصفر أعلى الصفحة يسبق العنوان ويزيد المسافة إلى قائمة القصص.
- [ ] حالة القصة والحقول "نشط" و"مروج" ظاهرة، لكن لا يوجد عرض بصري للأولوية أو سبب المراجعة.
- [ ] البحث والفلتر موجودان، لكن لا توجد chips للحالة الحالية أو quick filters مثل "قيد المراجعة" و"مبلغ عنه".

**P2:**
- [ ] النصوص الإنجليزية للمعرفات طويلة وتغطي مساحة أكبر من اسم الجهة أو الحالة.
- [ ] أزرار "جاهز" بجانب كل فعل تضيف تكرارا بصريا أكثر مما تضيف معلومات.

### Action items (mapped to master plan phases)

- [ ] **Phase 7:** تحويل stories queue إلى layout يعرض preview/النص/الوسائط قبل أزرار القرار.
- [ ] **Phase 7:** تجميع أفعال القصة في decision bar واحد بدل أربع بطاقات متكررة.
- [ ] **Phase 3:** إضافة filter chips وrow density مناسب للصفوف الطويلة.
- [ ] **Phase 1:** توحيد status/pending badges حتى لا تتكرر "جاهز" بجانب كل زر.

---

## `/admin/content/reviews` — Content reviews moderation

**Master priority:** P0
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/14_content_reviews.png`
**Capture status:** HTTP 200 | shot: `14_content_reviews.png`

### Visual issues

**P0:**
- [ ] كل المراجعات الظاهرة تعرض "لا يوجد نص مختصر لهذه المراجعة" ولا يظهر نص المراجعة الكامل؛ هذا يمنع اتخاذ قرار مراجعة محتوى مبني على السياق.

**P1:**
- [ ] قرارات "نشر/إخفاء/إرسال للمراجعة" تظهر داخل dropdown وزر منفصل لكل صف، لكنها لا تعرض سبب القرار أو preview للسياق.
- [ ] الأعمدة تترك مساحات كبيرة، بينما النص الأهم غير موجود؛ نتيجة ذلك أن الجدول يبدو واسعا لكنه قليل القيمة.
- [ ] فلتر الحالة والجهة لا يعرض active chips أو quick filters للصفوف التي تحتاج قرارا فعلا.
- [ ] التحذير الأصفر أعلى الصفحة يزاحم عنوان المراجعات رغم أنه ليس خاصا بالمراجعات فقط.

**P2:**
- [ ] أرقام التقييم تظهر كنص "5 من 5" بدون visualization صغير يسهل المسح.
- [ ] أسماء جهات مثل "test فانيلا" ومعرفات review الطويلة تخلق تباينا لغويا وبصريا.

### Action items (mapped to master plan phases)

- [ ] **Phase 7:** عرض نص المراجعة أو excerpt واضح داخل الصف، مع fallback يشرح سبب عدم توفر النص.
- [ ] **Phase 7:** بناء review decision pattern موحد يحتوي الحالة، السبب، والأزرار الأساسية.
- [ ] **Phase 3:** إضافة quick filters وactive chips للجهة والحالة.
- [ ] **Phase 1:** إضافة RatingDisplay compact بدلا من نص التقييم فقط.

---

## `/admin/config` — Config governance

**Master priority:** P0
**Screenshot:** `docs/release/ui_a02_baseline_screenshots/15_config.png`
**Capture status:** HTTP 200 | shot: `15_config.png`

### Visual issues

**P0:**
- [ ] الصفحة تعرض إعدادات أسعار ونشر واسترجاع، لكن لا يوجد diff واضح بين المسودة والنسخة المنشورة قبل أزرار "نشر" و"استرجاع"؛ هذا يخلق خطر قرار في إعدادات حساسة.

**P1:**
- [ ] workflow موجود كنص "خريطة العمل" ثم ثلاث بطاقات خطوات، لكنه ليس stepper بصري؛ لا يظهر بوضوح أين المستخدم الآن: تعديل، مراجعة، نشر، أو استرجاع.
- [ ] نموذج الأسعار واسع وموزع على حقول كثيرة، لكن زر "حفظ المسودة" أسفل يسار البطاقة بعيد عن بداية التدفق في RTL.
- [ ] قسم "المراجعة والنشر" يعرض حقول سبب وملاحظة وتأكيد، لكن أزرار "اعتماد المراجعة" و"نشر" في صفين منفصلين دون خطر بصري كاف.
- [ ] التحذير الأصفر أعلى الصفحة يضيف ضوضاء في صفحة حساسة كان الأفضل أن تعرض تحذيرات النشر نفسها قرب الإجراء.

**P2:**
- [ ] سجل النشر طويل ومفيد، لكنه يأتي أسفل الصفحة دون تلخيص أحدث نشر/استرجاع في أعلى governance workflow.
- [ ] بعض قيم السبب والمنفذ باللغة الإنجليزية مثل `smoke test` و`phase7_restore_baseline` تحتاج عرضا compact أو wrapping أو tooltip.

### Action items (mapped to master plan phases)

- [ ] **Phase 8:** إضافة diff preview واضح بين draft/live قبل publish أو rollback.
- [ ] **Phase 8:** تحويل الصفحة إلى stepper بصري: تعديل المسودة، مراجعة، نشر، استرجاع.
- [ ] **Phase 1:** استخدام ConfirmDialog بخطر دلالي للـ publish والـ rollback.
- [ ] **Phase 8:** تلخيص أحدث نشر/استرجاع أعلى الصفحة قبل سجل النشر الكامل.

---

## Cross-cutting observations

- **Sidebar:** يعمل بشكل ثابت ويظهر active route، لكنه نصي بالكامل، داكن وثقيل، ولا يحتوي أيقونات أو compact/collapsed mode. هذا تكرر في كل صفحات الأدمن.
- **Header:** يعرض عنوان عام، اسم المستخدم، وزر خروج فقط. لا يوجد breadcrumb، بحث سريع، environment badge، أو user menu واضح.
- **Page structure:** معظم الصفحات تبدأ بعنوان كبير ووصف ثم شريط مصدر بيانات ثم بطاقة محتوى. النمط متسق لكنه يستهلك مساحة رأسية كثيرة قبل العمل الفعلي.
- **DataTable:** الجداول في wallet, venues, media, offers, stories, reviews كثيفة وتعتمد على نصوص ومعرفات طويلة. لا تظهر sticky headers أو row density أو pinned action columns.
- **FilterToolbar:** الفلاتر موجودة في عدة صفحات، لكن لا توجد active filter chips أو clear all أو presets للسيناريوهات اليومية.
- **StatusBadge:** الشرائح اللونية مفيدة، لكنها كثيرة ومتكررة في بعض الجداول، وأحيانا تشرح حالات متعددة دون legend قريب.
- **Empty states:** صفحات مثل topups وبعض بطاقات dashboard تعرض empty text فقط، بدون أيقونة، CTA، أو تمييز بين no data وfiltered out وstale data.
- **Action affordances:** الإجراءات الحساسة في reversals وconfig تحتاج confirm/diff/stepper أوضح. إجراءات content moderation تتكرر كأزرار نصية كثيرة دون decision flow مركزي.
- **Iconography gaps:** لا توجد أيقونات واضحة في navigation، empty states، table actions، alerts، أو أزرار القرار؛ هذا يجعل الواجهة أبطأ في المسح.
- **Warnings:** التحذير الأصفر الخاص بمدير الأسرار يظهر عريضا أعلى media/content/config ويهيمن على الصفحة رغم أنه يقول إن العمل غير متأثر.
- **Language consistency:** بعض الصفحات تعرض نصوصا إنجليزية داخل واجهة عربية، خاصة venue workspace ومعرفات تقنية طويلة في content/config.

## Recommendations for master plan adjustment

- **Phase 1 priority:** ابدأ بمكونات `PageHeader`, `CommandBar`, `EmptyState`, `ConfirmDialog`, `AlertBanner`, وsemantic tokens قبل أي redesign خاص بالصفحات.
- **Phase 2 priority:** تحسين الـ shell مبكرا مهم لأنه يظهر في كل لقطة: أيقونات sidebar، breadcrumb، environment badge، user menu، وتهيئة compact/mobile drawer.
- **Phase 3 priority:** ارفع DataTable وFilterToolbar قبل الدخول في الصفحات الثقيلة؛ venues/content/media/wallet كلها تحتاج نفس الأساس.
- **Phase 4 priority:** dashboard يحتاج QuickActions وKPI hierarchy، لكن لا يحتاج إعادة رسم كاملة قبل إنهاء foundation والجداول.
- **Phase 5 priority:** ضع reversals قبل بقية finance pages لأن لقطة reversals تكشف خطر UX في إجراء مالي حساس.
- **Phase 7 priority:** راجع content reviews/stories قبل offers؛ reviews/stories تفتقد نص/preview المحتوى، وهذا أعلى أثرا من تحسين عرض العروض.
- **Phase 8 priority:** Config governance يجب أن يحصل على diff/confirm مبكرا بسبب حساسية النشر والاسترجاع.
- **Re-prioritize phases:** نعم بشكل طفيف: بعد Phase 1 و2، نفذ slice مشترك للجداول والفلاتر ثم slice أمان للإجراءات الحساسة في reversals/config/content decisions قبل التلميع والحركة.
