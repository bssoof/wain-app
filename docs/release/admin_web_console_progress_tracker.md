# Admin Web Console Progress Tracker

## 1. طريقة العمل المعتمدة

هذا الملف هو السجل التنفيذي الرسمي لتقدم **لوحة الأدمن الويب**.

القواعد:

1. كل خطوة تالية تُصاغ كأنها **Prompt موجه إلى Codex**.
2. كل خطوة يجب أن تكون:
   - مهمة وقوية
   - ليست صغيرة جدًا
   - وليست ضخمة لدرجة تفقد السيطرة
3. بعد كل تنفيذ:
   - يُسجل ما تم ادعاؤه
   - تُسجل الملفات المتأثرة
   - تُسجل نتائج التحقق
   - تُسجل أي فجوات أو مخاطر متبقية
4. لا ننتقل إلى الخطوة التالية قبل:
   - مراجعة claims التنفيذ
   - التحقق من الاختبارات/البراهين المناسبة
   - تسجيل الحكم النهائي على الخطوة

## 2. الوضع الحالي

- الخطة الشاملة موجودة في:
  - `docs/release/admin_web_console_execution_plan.md`
- وثيقة Phase 0 المستقلة موجودة في:
  - `docs/release/admin_web_console_phase0_governance_lock.md`
- سجل قبول Phase 0 موجود في:
  - `docs/release/admin_web_console_phase0_acceptance_record.md`
- سجل قبول Phase 1 موجود في:
  - `docs/release/admin_web_console_phase1_acceptance_record.md`
- تنفيذ Phase 1 shell + RBAC foundation متاح داخل:
  - `admin_web_console/`
- جولات Phase 1 (`AWC-P1-01A` + `AWC-P1-01B` + `AWC-P1-01M`) تم تنفيذها والتحقق منها.
- جولة الإقفال `AWC-P1-02` وثّقت القبول الرسمي مع follow-up واضح لبدء Phase 2.
- جولة `AWC-P2-01A` أنشأت baseline عقود أوامر التمويل (`command contracts/policy/client`) مع اختبار نوعي واضح.
- جولة `AWC-P2-01B` أضافت read models + formatters + surfaces أولية لواجهات التمويل.
- جولة الدمج `AWC-P2-01M` وحّدت command metadata مع Top-Ups / Wallet Audit / Readiness وثبّتت role-gated affordances.
- جولة `AWC-P2-02A` استبدلت mock transport بـ real server-authorized adapters مرتبطة فقط بالـ callable surfaces الموجودة فعليًا.
- جولة `AWC-P2-02B` فعّلت executable finance surfaces داخل الصفحات المحمية مع runtime callouts متسقة.
- جولة الدمج `AWC-P2-02M` وحّدت 02A + 02B على مستوى التطبيق وأثبتت سلوك authorization/idempotency/conflict/unavailable باختبارات تشغيلية.
- جولة `AWC-P2-03A` أنشأت read transport/adapters server-backed لأسطح التمويل المتاحة فعليًا مع عقود read-state صريحة (`success/empty/stale/unavailable/unauthorized/forbidden`).
- جولة `AWC-P2-03B` فعّلت واجهات read-state الحية (نجاح/فراغ/قديم/غير متاح) مع مصدر بيانات صريح ودمج snapshot/HTTP/inline مع callable readiness حيث يتوفر.
- جولة الدمج `AWC-P2-03M` ثبّتت أن الصفحات الثلاث تمر عبر `finance-read-loader` + layered transport وأن أوامر التمويل بقيت على نفس عقود التفويض دون اختلاط.
- جولة `AWC-P2-04A` أضافت callables قراءة فعلية لطابور الشحن وسجل المحفظة (`listMerchantTopUpRequestsForAdmin`، `listMerchantWalletLedgerEntriesForAdmin`) مع تفويض إداري + App Check، وربطت `finance-read-adapters` وطبقة layered لتفضيل الـ callable ثم fallback آمن للـ snapshot عند الأخطاء القابلة لإعادة المحاولة.
- جولات Phase 3 (`AWC-P3-01A` + `AWC-P3-01B` + `AWC-P3-01M`) فعّلت Venue Directory + Venue Workspace Shell بشكل read-only متكامل مع تنقل موثّق واختبارات مرور.
- جولة `AWC-P3-02` أضافت hardening فعليًا لمرحلة Venue Ops:
  - Venue Directory أصبحت تعرض bounded scan budget + truncation honesty
  - Venue Workspace انتقلت من fixture-only إلى callable-backed read surface مع fallback source labeling واضح
- جولة `AWC-P3-03` وثّقت الإغلاق الرسمي لـ Phase 3 كسجل قبول auditable.
- جولة `AWC-P4-01A` بدأت Phase 4 فعليًا عبر Media Center read adapters callable-backed مع safety model صريح وحالات تشغيلية واضحة (`success`/`empty`/`stale`/`unavailable`) بدون أي write actions.
- جولة `AWC-P4-01B` استبدلت placeholder/fixture-only Media Center بواجهة تشغيلية read-only مع tabs وفلاتر وملاحظات source/freshness/reference safety واضحة.
- جولة الدمج `AWC-P4-01M` ثبّتت أن صفحة `/admin/media` تستخدم callable-backed baseline من `P4-01A` مباشرة، وأن حدود read-only وغياب destructive actions ما زالت محفوظة بعد الدمج.
- جولة `AWC-P4-02A` فعّلت workflows خادمية محكومة للوسائط:
  - `mediaSoftDeleteAsset`
  - `mediaQuarantineAsset`
  - `mediaReferenceCheckAsset`
  - `mediaPurgeAsset`
  مع audit واضح وpurge gating مرتبط بصحة `media_reference_index`.
- جولة `AWC-P4-02B` فعّلت Media Center operator UX:
  - role-gated action affordances
  - runtime states صريحة (`pending`/`success`/`conflict`/`unavailable`/`blocked`)
  - إبقاء read-only roles بلا destructive controls
- جولة الدمج `AWC-P4-02M` ثبّتت أن UI تستهلك command boundary الفعلية وأن callable-backed media actions متسقة مع backend governance بدون bypass من العميل.
- جولة `AWC-P4-03` أغلقت Phase 4 رسميًا كسجل قبول auditable مع follow-up صريح للفجوات غير الحاجزة.
- جولة `AWC-P5-01A-R2` حوّلت Offers/Stories من baseline snapshots فقط إلى surfaces تشغيلية فعليًا:
  - callable-backed reads عبر `listOffersForAdmin` و`listStoriesForAdmin`
  - content moderation transport حقيقي عبر `contentModerateOffer` و`contentModerateStory`
  - منع fixture fallback عند `unauthorized/forbidden` مع إبقاء retryable fallback صريحًا فقط عند `unavailable`
  - replay/idempotency للـ content moderation أصبحت مستقرة بعد إزالة `submittedAt` من payload hash identity
  - تغطية route/shell/loader/backend emulator أصبحت موثقة ضمن التحقق الرسمي
- جولة `AWC-P5-01B` ثبّتت Reviews Moderation كسطح governed callable-backed:
  - `listVenueReviewsForAdmin`
  - `moderateVenueReviewForAdmin`
  - route/shell/adapters/affordances واختبارات runtime states
- جولة الدمج `AWC-P5-01M` وحّدت Offers/Stories/Reviews تحت Content Ops baseline واحد:
  - route map متسق
  - role gating موحد
  - moderation reasons/command envelopes بقيت صريحة ومختبرة
- جولة `AWC-P5-02` أغلقت Phase 5 رسميًا كسجل قبول auditable مع follow-up تشغيلي غير حاجز.
- جولة `AWC-P6-01B` فعّلت Config Governance baseline ضمن Phase 6:
  - callables خادمية محكومة لـ draft/review/publish/rollback/history
  - strict validation + expected-state conflict checks + idempotent replay
  - route محمي `/admin/config` مع runtime states صريحة واختبارات route/shell/RBAC وemulator backend
- جولة `AWC-P6-01A` فعّلت operational dashboard baseline:
  - KPI widgets خفيفة وصريحة المصدر
  - read-state honesty (`success` / `stale` / `unavailable`)
  - dashboard لا تعتمد على heavy browser-side analytics
- جولة الدمج `AWC-P6-01M` وحّدت dashboard baseline مع config governance baseline داخل نفس الكونسول.
- جولة `AWC-P6-02` أغلقت Phase 6 رسميًا كسجل قبول auditable مع follow-up تشغيلي غير حاجز.
- جولة `AWC-P7-F01D` أغلقت follow-up التشغيلي الحرج للمتصفح عبر rerun مصادَق عليه (`16/16` probes = `HTTP 200`) وحرّرت القرار النهائي إلى `GO_LIVE_READY`.
- جولة `AWC-UI-022` (2026-04-17) أغلقت Stream 3 UI-D05 عبر توحيد command-zone wrappers داخل `ActionPanel` المشترك في `admin_web_console/components/shared/action-panel.tsx` مع ترحيل media/content/reviews/config/venues والتحقق الكامل (targeted Vitest + full Vitest + build)؛ الخطوة التالية: بدء UI-E01 pilot rollout كما هو موثق في `docs/release/admin_web_console_ui_improvement_master_plan.md`.
- جولة `AWC-UI-023` (2026-04-17) أغلقت UI-E01 pilot rollout evidence على المسارات التمثيلية (`/admin/dashboard` + `/admin/venues` + `/admin/config`) عبر حزمة تحقق مركزة (5 ملفات، 22 اختبار) مع `next build` أخضر؛ الخطوة التالية: بدء UI-P01 polish/micro-interaction pass.
- جولة `AWC-UI-024` (2026-04-17) أغلقت UI-P01 عبر polish/micro-interaction pass محافظ داخل `admin_web_console/app/globals.css` (hover/active continuity + reduced-motion safety) مع تحقق كامل (`tsc` + full Vitest `58/58 files, 291 tests` + `next build`)؛ الخطوة التالية: تحديث browser smoke evidence بعد polish.
- جولة `AWC-UI-025` (2026-04-17) أغلقت تحديث post-polish browser smoke evidence عبر إعادة تشغيل `npm run capture:ui-a02` تحت سياق جلسة `super_admin` development على الخادم؛ النتيجة `15/15` نجاح، `0` redirects إلى sign-in، `0` failures، مع تحديث artifacts (`admin_web_console_ui_a02_baseline_capture.json` + `.md` + screenshots) وإضافة مذكرة الجولة `admin_web_console_ui_post_polish_smoke_ui_025.md`؛ الخطوة التالية: الانتقال إلى بند UI التالي أو تنفيذ visual diff triage عند الطلب.
- جولة `AWC-UI-026` (2026-04-17) أغلقت UI-P03 عبر تنفيذ visual diff triage قابل لإعادة التشغيل (`npm run capture:ui-a02:triage`) يقارن لقطات UI الحالية بمرجع `HEAD` باستخدام hash/byte/dimension checks؛ artifacts الجديدة (`admin_web_console_ui_visual_diff_triage_ui_026.json` + `.md`) سجّلت `15` routes مع `0` critical findings و`15` review findings (`new-file` لأن screenshots غير موجودة في `HEAD`)؛ الخطوة التالية: اختيار بند UI تنفيذي جديد product-facing.
- جولة `AWC-UI-027` (2026-04-17) أغلقت قرار اختيار stream التنفيذ التالي بعد UI-P03: تم اعتماد `UI-M01` (Media visual preview/viewer baseline) كبند product-facing القادم لأنه يغلق فجوة Phase 4 الأعلى أثرًا (`preview/viewer بصري كامل`) مع إمكانية تنفيذ slice أول read-only دون توسيع عقود destructive workflows؛ الخطوة التالية: بدء تنفيذ UI-M01 (slice 1).
- جولة `AWC-UI-028` (2026-04-17) أغلقت UI-M01 (slice 1) بتنفيذ preview/viewer read-only داخل `admin_web_console/components/media/media-center-shell.tsx` مع viewer modal واضح وإتاحة `mediaUrl` من baseline/model (`lib/media/media-center-baseline.ts` + `media-center-models.ts`) بدون أي تغيير في RBAC أو command contracts؛ التحقق مرّ عبر Vitest مركّز (3 ملفات، 21 اختبار) + full `npm test` (`58/58 files, 293 tests`) + `next build` أخضر؛ الخطوة التالية: اختيار UI-M01 slice 2 أو stream product-facing جديد.
- جولة `AWC-UI-029` (2026-04-17) أغلقت UI-M01 (slice 2) بإضافة replace draft workflow داخل `admin_web_console/components/media/media-center-shell.tsx` (زر استبدال + dialog + تحقق URL/سبب + payload قابل للنسخ) دون أي توسيع لعقود RBAC أو media command contracts؛ التحقق مرّ عبر Vitest مركّز (3 ملفات، 23 اختبار) + full `npm test` (`58/58 files, 295 tests`) + `next build` أخضر؛ الخطوة التالية: استكمال Phase 4 follow-up المتبقي (staging smoke للـ media transport الحي).
- جولة `AWC-UI-030` (2026-04-17) أغلقت staging smoke المصادَق عليه لمسارات media transport (`6` callables) عبر artifact (`admin_web_console_media_transport_smoke_ui_030.json` + `.md`)؛ النتيجة النهائية `6/6` نجاح (`HTTP 200`) و`0/6` `App Check verification failed` مع `0` حالات `404` (timestamp داخل JSON: `2026-04-17T00:30:57.254Z`)؛ قرار المتابعة أصبح `FOLLOW_UP_CLOSED`.
- جولة `AWC-UI-031` (2026-04-17) فتحت مسار UI-L01 كخطة product-facing جديدة لتعريب مبسط وتنظيم حديث صفحة بصفحة بعد إغلاق مسارات الثبات والمكونات المشتركة والدخان والوسائط؛ الوثيقة الجديدة `admin_web_console_arabic_page_ui_plan_ui_031.md` تثبت قاموس البدائل، ترتيب الدفعات، المخاطر، ومعايير القبول؛ الخطوة التالية: تنفيذ الدفعة الأولى على عناوين التنقل والترجمة المشتركة وملاحظات الصفحات بدون تغيير الصلاحيات أو المسارات أو عقود الأوامر.
- جولة `AWC-UI-032` (2026-04-17) نفذت الدفعة الأولى من UI-L01 كتغيير نصي محدود: تبسيط عناوين التنقل، ملاحظات الصفحات، ترجمة مصادر البيانات، رسائل الاتصال بالخدمة، نصوص النظرة العامة، ونصوص التحميل/الخطأ، مع إزالة المصطلحات التقنية الظاهرة من صفحات المحتوى والمراجعات والإعدادات والصور والملفات؛ التحقق مرّ عبر Vitest مركز (8 ملفات، 48 اختبارًا) + `tsc` + `next build`؛ الخطوة التالية: متابعة UI-L01 slice 2 على صفحات المالية صفحة صفحة.
- جولة `AWC-UI-033` (2026-04-17) نفذت الدفعة الثانية من UI-L01 على صفحات المالية: طلبات الشحن، سجل المحفظة، تصحيح العمليات، اعتماد التصحيح، حالة النظام، ورسائل تحميل النظرة العامة؛ تم تبسيط الألفاظ التقنية الظاهرة مثل الطابور/قيود الدفتر/العكس/الجاهزية/الأمر مع الحفاظ على RBAC ومفاتيح الأوامر وحقول الطلبات ومصادر البيانات؛ التحقق مر عبر Vitest مركز (5 ملفات، 29 اختبارًا) + `tsc` + `next build`، ثم أعيد تشغيل localhost على 3010 وتم التحقق من `/admin/dashboard` بدون overlay أو console errors، ومسارات المالية الأربعة رجعت HTTP 200 بدون Server Error؛ الخطوة التالية: متابعة UI-L01 على صفحة الجهات ومساحة عمل الجهة.
- جولة `AWC-UI-034` (2026-04-17) عالجت تحذيرات Edge Tools الخاصة بقيم ARIA في أزرار المالية وتبويبات مساحة عمل الجهة عبر تحويل القيم الديناميكية إلى `"true"`/`"false"` صريحة، وتوسيع نفس النمط إلى أزرار الوسائط/المحتوى/المراجعات؛ التحقق مر عبر grep متخصص بدون بقايا suppressions أو boolean ARIA مباشر + Vitest مركز (7 ملفات، 55 اختبارًا) + `tsc` + `next build`، ثم أعيد تشغيل localhost وتحققت مسارات `/admin/dashboard` و`/admin/topups` و`/admin/wallet-audit` و`/admin/venues` بنتيجة HTTP 200؛ الخطوة التالية: متابعة UI-L01 على صفحة الجهات ومساحة عمل الجهة.
- جولة `AWC-UI-034` (2026-04-17) أغلقت الدفعة الثالثة والأخيرة من بتنفيذ UI-L01 (تعريب صفحات الجهات ومساحات العمل): تم استبدال تسميات الطول/العرض، إزالة مراجع التقنية V1/Phase3 من الواجهة، وتوحيد رسائل الأخطاء للإحداثيات، وتم تعريب عرض session.primaryRole؛ أُغلقت مسارات UI-L01 بالكامل وتم التحقق عبر Vitest و Build. الخطوة التالية: اختيار المهمة التشغيلية أو الـ UI التالية.
- جولة `AWC-UI-035` (2026-04-17) ثبتت دفعة الجهات المتحققة ضمن UI-L01 بدون حذف سجل `AWC-UI-034` المكرر: تم تبسيط مفردات قائمة الجهات وتفاصيل الجهة مثل `دليل الجهات`، `مساحة العمل`، `تبويب`، `قيود محفظة`، `ميزانية المسح`، و`الجاهزية` إلى عبارات عربية أوضح مثل `قائمة الجهات`، `تفاصيل الجهة`، `قسم`، `عمليات محفظة`، و`حالة النظام`؛ التحقق مر عبر grep للمفردات القديمة + Vitest مركز (6 ملفات، 23 اختبارًا) + `tsc` + `next build`، ثم أعيد تشغيل localhost على 3010 وتحققت `/admin/venues` و`/admin/venues/venue_route_1` و`/admin/dashboard` بنتيجة HTTP 200 وبدون أخطاء console في Playwright؛ الخطوة التالية: متابعة التعريب صفحة صفحة على صفحة الوسائط.
- جولة `AWC-UI-036` (2026-04-17) عالجت خطأ hydration الظاهر في Next.js حيث كان السيرفر يطبع خيار فلتر باسم تقني مثل `Phase7 venue_phase7_1775874615957` بينما العميل يطبع `ستونز`؛ السبب كان استخدام `localeCompare` داخل مكونات فلاتر تعمل على السيرفر والمتصفح، وترتيب النصوص العربي/اللاتيني اختلف بين البيئتين؛ الإصلاح أضاف `compareAdminText` بترتيب ثابت بدون locale وطبقه على فلاتر الجهات والوسائط والمراجعات؛ التحقق مر عبر Vitest مركز (4 ملفات، 33 اختبارًا) + `tsc` + grep بدون `localeCompare` داخل المكونات + `next build`، ثم أعيد تشغيل localhost وتحققت `/admin/venues` و`/admin/media` و`/admin/content/reviews` عبر HTTP والمتصفح بدون overlay أو console errors؛ الخطوة التالية: متابعة التعريب صفحة صفحة على صفحة الوسائط.
- جولة `AWC-UI-037` (2026-04-17) نفذت دفعة تعريب صفحة الصور والملفات بعد إصلاح hydration: تم استبدال مفردات تقنية مثل `الجرد`، `الأصل`، `المرجع`، `سلامة المرجع`، `حذف منطقي`، `حجر`، و`حمولة` بعبارات أبسط مثل `الملف`، `الارتباط`، `مكان الحفظ`، `حالة الارتباط`، `إخفاء من القائمة`، `عزل الملف`، و`محتوى طلب الاستبدال`؛ التحقق مر عبر Vitest مركز (4 ملفات، 25 اختبارًا) + `tsc` + grep للمفردات القديمة + `next build`، ثم أعيد تشغيل localhost وتحققت `/admin/media` و`/admin/venues` عبر HTTP والمتصفح بدون overlay أو console errors؛ الخطوة التالية: متابعة التعريب صفحة صفحة على العروض ثم القصص.
- جولة `AWC-UI-038` (2026-04-17) نفذت دفعة تعريب صفحة العروض: تم تبسيط مفردات `محكومة من الخادم`، `عدد الصفوف`، `المرشحات المطبقة`، `المعرّف`، `الحالة الإدارية`، و`الإجراءات` إلى `مصدر البيانات`، `عدد العروض`، `الخيارات الحالية`، `رقم العرض`، `حالة العرض`، و`الخيارات`، كما تحولت صياغة قرار المحتوى المشتركة إلى `سبب القرار` و`تأكيد القرار` و`وضع علامة`؛ التحقق مر عبر Vitest مركز (4 ملفات، 23 اختبارًا) + `tsc` + `next build`، ثم أعيد تشغيل localhost وتحققت `/admin/content/offers` و`/admin/media` عبر HTTP والمتصفح بدون overlay أو console errors؛ الخطوة التالية: متابعة نفس النمط على صفحة القصص.
- جولة `AWC-UI-039` (2026-04-17) نفذت دفعة تعريب صفحة القصص بنفس نمط العروض: تم تبسيط مفردات `محكومة من الخادم`، `عدد الصفوف`، `المرشحات المطبقة`، `المعرّف`، `الحالة الإدارية`، `الإجراءات`، و`خدمة خصم المحفظة` إلى `مصدر البيانات`، `عدد القصص`، `الخيارات الحالية`، `رقم القصة`، `حالة القصة`، `الخيارات`، و`يتم التحكم به عبر الخدمة الآمنة`؛ التحقق مر عبر grep للمفردات القديمة في صفحات العروض/القصص + Vitest مركز (4 ملفات، 23 اختبارًا) + `tsc` + `next build`، ثم أعيد تشغيل localhost وتحققت `/admin/content/stories` و`/admin/content/offers` عبر HTTP والمتصفح بدون overlay أو console errors؛ الخطوة التالية: متابعة التعريب صفحة صفحة على صفحة المراجعات.
- جولة `AWC-UI-040` (2026-04-17) نفذت دفعة تعريب صفحة المراجعات بعد العروض والقصص: تم تبسيط مفردات `مغلفات طلبات`، `حالات تشغيل`، `مشغلو المحتوى`، `عدد الصفوف`، `الحداثة`، `المرشحات المطبقة`، `المعرّف`، `تأكيد الإجراء`، `سبب الإجراء`، و`تصعيد` إلى `مصدر البيانات`، `عدد المراجعات`، `حالة البيانات`، `الخيارات الحالية`، `رقم المراجعة`، `تأكيد القرار`، `سبب القرار`، و`إرسال للمراجعة`؛ التحقق مر عبر grep للمفردات القديمة في واجهة المراجعات + Vitest مركز (4 ملفات، 17 اختبارًا) + `tsc` + `next build`، ثم أعيد تشغيل localhost وتحققت `/admin/content/reviews` و`/admin/content/stories` عبر HTTP والمتصفح بدون overlay أو console errors؛ الخطوة التالية: smoke قصير لمجموعة المحتوى أو متابعة التعريب على صفحة إعدادات التطبيق.
- جولة `AWC-UI-041` (2026-04-17) عالجت سبب ظهور تنفيذ قرار المراجعة كأنه لا يعمل: الطلب كان يصل إلى callable الحقيقي لكنه يُرفض بسبب App Check، بينما الواجهة كانت تصنف `failed-precondition` كـ `تعارض`؛ تم تحديث `mapBackendErrorToTransportError` حتى تتحول رسائل App Check إلى `403` وتظهر الحالة `غير متاح` بدل `تعارض` مع بقاء تعارضات الحالة الحقيقية كـ `409`؛ التحقق مر عبر Vitest مركز (4 ملفات، 18 اختبارًا) + `tsc` + `next build`، ثم أعيد تشغيل localhost وتحقق فحص المتصفح أن رسالة `تعذر التحقق من أمان الطلب الحالي.` تظهر بدون overlay وبدون `تعارض`؛ النجاح الفعلي للأوامر ما زال يحتاج توكن Auth/App Check صالح أو emulator مهيأ.
- جولة `AWC-UI-042` (2026-04-17) أضافت guard مشترك يمنع إرسال أوامر كتابة إلى Cloud Functions الحية عندما يكون App Check token مفقودًا أو placeholder، مع إبقاء emulator URLs مسموحة؛ الآن عند الضغط على قرار مراجعة في البيئة الحالية تظهر رسالة `توكن أمان الطلب الحالي تجريبي، لذلك لا يمكن تنفيذ القرار على الخدمة الحية.` بدل إرسال طلب شبكة معروف الفشل؛ التحقق مر عبر Vitest مركز (5 ملفات، 24 اختبارًا) + `tsc` + `next build`، ثم أعيد تشغيل localhost وتحقق المتصفح من عدم وجود failed requests أو console/page errors أو overlay أو `تعارض`.
- جولة `AWC-UI-043` (2026-04-18) رفعت مستوى صفحة النظرة العامة `/admin/dashboard` كتغيير عرض فقط: أضيف شريط ملخص سريع، تحسنت هرمية البطاقات، تبسطت صياغة المحفظة والمحتوى والفحوصات، وصارت مبالغ الشحن تستخدم formatter مشترك بدل نص خام؛ تم الحفاظ على loaders وRBAC وroute contracts ونموذج البيانات بدون تغيير؛ التحقق مر عبر Vitest مركز (2 ملفات، 8 اختبارات) + `tsc` + `next build`، ثم أعيد تشغيل localhost وتحقق Playwright من `/admin/dashboard` بنتيجة HTTP 200 وبدون overlay أو console/page errors؛ الخطوة التالية: متابعة نفس النمط على `/admin/wallet-audit`.
- جولة `AWC-UI-044` (2026-04-18) رفعت مستوى صفحات المالية الثانوية `/admin/readiness` و`/admin/reversals` و`/admin/wallet-audit`: تحولت حالة النظام إلى ملخص عربي بعدّادات واضحة، أصبحت صفحة اعتماد التصحيح أوضح كلوحة إجراء، وأُزيلت تسريبات النصوص الإنجليزية المحلية مثل `Local Admin` و`Admin operator` من العرض؛ التحقق مر عبر Vitest مركز (3 ملفات، 21 اختبارًا) + `tsc` + `next build`، ثم أعيد تشغيل localhost وتحقق Playwright من المسارات الثلاثة بنتيجة HTTP 200 وبدون overlay أو console/page errors؛ الخطوة التالية: متابعة نفس النمط على `/admin/config`.
- جولة `AWC-RC-045` (2026-04-19) أغلقت مسار Release Confidence الخاص بـ `REL-1` و`REL-2`: تمت إعادة تصدير `rebuildWalletReportForVenue` من composition root في `functions/src/index.ts`، وتحديث `functions/scripts/verify_wallet_env.js` لقراءة جداول الصيانة من `wallet_runtime_maintenance` بدل `index.ts`، مع اختبار regression جديد في `functions/test/emulator/walletConfigScripts.test.js`؛ التحقق مر عبر `npm run build` و`npm test` داخل `functions` وإعادة تشغيل emulator suites بنجاح.
- جولة `AWC-RC-046` (2026-04-19) أغلقت `REL-3` وأزالت drift قرار الإطلاق: checklist أصبحت تعتمد قرارًا صريحًا مشتقًا (`NO_GO`) بدل snapshots ثابتة، أضيف سكربت بوابة `scripts/validate_admin_release_checklist.mjs` وربط في CI، وتم تشديد runbook حتى لا يطلب `NEXT_PUBLIC_*_AUTH_TOKEN` أو `NEXT_PUBLIC_*_APP_CHECK_TOKEN` ضمن متطلبات الإطلاق.
- جولة `AWC-RC-047` (2026-04-19) نفذت slice أول من `SEC-3 Phase B` لمسار Finance: إضافة proxy endpoint خادمي `POST /api/admin/command/finance` مع تحقق session + RBAC قبل تمرير callable، وتحديث transport الافتراضي لاستخدام proxy تلقائيًا عند بيئة production + live functions URL، مع اختبار نمط النقل الجديد والتحقق عبر build.
- جولة `AWC-RC-048` (2026-04-19) أغلقت ملاحظات المراجعة على `AWC-RC-047`: إصلاح أخطاء `tsc --noEmit` (اختبار `finance-command-proxy-transport` + forged-header env stubs)، إضافة build-time guard يمنع أي `NEXT_PUBLIC_*_AUTH_TOKEN` و`NEXT_PUBLIC_*_APP_CHECK_TOKEN` عبر `scripts/validate-no-public-privileged-tokens.mjs`، وإضافة فحص bundle بسنتينل عبر `scripts/scan-next-bundle-token-leaks.mjs` وربط `build:secure` في CI؛ مع توثيق صريح أن هذا المسار لا يغلق `SEC-1` و`SEC-2` قبل session hardening.
- جولة `AWC-RC-049` (2026-04-19) نفذت hardening مباشر لـ `SEC-2`: `resolveAdminRole` أصبح claims-only (fail-closed) وتم تعطيل منح الصلاحيات عبر fallback context، مع تحديث اختبارات auth (`guard-api` + `missing-role-denied`) لتثبيت السلوك الجديد، وإضافة سكربت تشغيلي `functions/scripts/audit_admin_roles.js` (وأمر `npm run admin-web:audit-admin-roles`) لاستخراج حسابات `admins` ذات `missing_role`/`invalid_role`؛ تولدت artifacts على مشروعي `demo-wain-analytics` و`wain-d2e28` (`docs/release/admin_role_audit_report_latest.json` و`docs/release/admin_role_audit_report_wain_d2e28.json`) بنتيجة `0` missing و`0` invalid في تقرير الهدف (`1` admin doc)، وبذلك أُغلق دليل SEC-2 التشغيلي لهذه الجولة.
- جولة `AWC-RC-050` (2026-04-19) عززت دليل `SEC-1` على مستوى route-level: إضافة اختبار `lib/auth/route-guards.security.test.ts` للتحقق من أن المسارات المحمية تعيد توجيه غير الموثقين إلى sign-in، وتعيد توجيه الأدوار غير المصرح لها إلى access-denied، وتسمح فقط بجلسة admin صالحة؛ تم إدراج الاختبار في `npm run test:security` وأصبحت البوابة `4` ملفات / `13` اختبارًا ناجحة.
- جولة `AWC-RC-051` (2026-04-19) أغلقت التشديد المتبقي على `SEC-1`: إضافة guard إنتاجي في `session-server` يمنع استخدام `WAIN_ADMIN_SESSION_JSON` خارج non-production، مع اختبار صريح ضمن `forged-header-denied.test.ts` يثبت أن `WAIN_ADMIN_SESSION_JSON` لا ينتج session في production.
- جولة `AWC-RC-052` (2026-04-19) عممت `SEC-3 Phase B` من finance-only إلى كل domains الأمرية: إضافة server proxy routes لـ `config/content/media/reviews/venues` (مع بقاء finance)، وإضافة proxy transports + production/live mode resolvers في default transports لكل domain؛ التحقق مر عبر Vitest مركز (`5` ملفات / `15` اختبارًا) + `npx tsc --noEmit --pretty false` + `npm run build:secure` مع نجاح env token guard وbundle sentinel scan.
- جولة `AWC-RC-053` (2026-04-19) أغلقت دليل Phase 2 (`Gate B`) تشغيليًا: إعادة تشغيل `npm run test:emulator:aggregate` نجحت بالكامل (`191/191`) باستخدام Firestore emulator على منفذ override (`8081`) بعد تعارض محلي على `8080`، وتشغيل `node scripts/validate_admin_release_checklist.mjs` أعاد `PASS decision=NO_GO` بدون stale snapshot؛ بذلك اكتملت أدلة `REL-1/REL-2/REL-3` وفق مسار الأدلة الصارم (Gate A → Phase 2).
- جولة `AWC-RC-054` (2026-04-19) بدأت تنفيذ Phase 3 (`OPS-1`) مع إغلاق شرط ترتيب الحراسة: تم تحويل صفحات المسارات المحمية الحساسة إلى تسلسل auth-first (لا loader حساس قبل `await requireRouteAccess(...)`) وإضافة اختبار `lib/auth/route-loader-order.security.test.ts` داخل `test:security` لضمان عدم رجوع النمط الموازي مستقبلًا؛ التحقق مر عبر `npm run test:security` (`10` ملفات / `39` اختبارًا) + `npx tsc --noEmit --pretty false` + `npm run build:secure`.
- جولة `AWC-RC-055` (2026-04-19) أغلقت انحراف `OPS-2` في مسار finance read-state: تمت إزالة بادئة `Unavailable:` من رسائل `unavailable` العامة في `finance-read-loader` للحفاظ على الرسالة العربية الموحدة `FIXTURE_FALLBACK_DISABLED_MESSAGE_AR` عند حظر fixture fallback في production، وتمت إضافة تغطية regression داخل `lib/admin/fixture-fallback-policy.security.test.ts` لتثبيت السلوك ضمن `test:security`؛ التحقق مر عبر Vitest subset (`6` ملفات / `39` اختبارًا)، ثم `npm run test:security` (`11` ملفات / `44` اختبارًا)، ثم `npx tsc --noEmit --pretty false`.
- جولة `AWC-RC-056` (2026-04-19) نفذت شريحة `OPS-3` الخاصة بـ denial observability على طبقة الويب: إضافة emitter موحد `lib/auth/admin-security-audit.ts` يطبع سجل JSON منظم بعلامة `[SECURITY_AUDIT]`، وربطه في `route-guards` وفي مسارات proxy (`/api/admin/command/{finance,config,content,media,reviews,venues}`) عند حالات `proxy_payload_invalid` و`proxy_authorization_denied` و`proxy_transport_rejected`، مع regression tests جديدة (`lib/auth/admin-security-audit.test.ts` + توسيع `lib/auth/route-guards.security.test.ts`)؛ التحقق مر عبر Vitest مركز (`5/5`) + `npm run test:security` (`44/44`) + `npx tsc --noEmit --pretty false`.

## 3. حالة المراحل

| المرحلة | الحالة | ملاحظات |
| --- | --- | --- |
| Phase 0 - Governance Lock | `done` | كل العقود الحرجة مقبولة، مع follow-up غير حرج `P0-F01` بتاريخ `2026-04-18` |
| Phase 1 - Foundation & RBAC Shell | `accepted with follow-up` | AWC-P1-02 أغلق المرحلة رسميًا كسجل قبول auditable؛ follow-up مرتبط بتمكين أوامر Phase 2 الحساسة |
| Phase 2 - Finance Ops V1 | `accepted with follow-up` | `AWC-P2-06` أغلق Phase 2 رسميًا كسجل قبول تدقيقي. الأسطح الجوهرية لـ Finance Ops V1 منجزة ومثبتة عبر build + emulator subset + admin web test/build + staging rollout/rehearsal. الفجوات المتبقية غير حاجزة لكنها صريحة: dashboard widgets، queue aging UI، وCSV export governed. |
| Phase 3 - Basic Venue Lookup + Workspace Core | `accepted with follow-up` | `AWC-P3-03` أغلق Phase 3 رسميًا. الأسطح الأساسية منجزة ومثبتة، مع follow-up صريح لقراءة directory الإدارية المخصصة وpagination التفاعلية. |
| Phase 4 - Media Ops | `accepted` | `AWC-P4-03` أغلق المرحلة رسميًا. inventory + governed media actions منجزة ومثبتة عبر functions build + emulator media subset + admin web tests/build. بعد `AWC-UI-028` و`AWC-UI-029` أُغلقت فجوتا preview/viewer وreplace draft workflow على الواجهة، وتم إغلاق smoke المتبقي في `AWC-UI-030` بنتيجة `6/6` `HTTP 200` وقرار `FOLLOW_UP_CLOSED`، وبذلك أُغلقت متابعة media transport الحي. |
| Phase 5 - Content Ops | `accepted with follow-up` | `AWC-P5-02` أغلق Phase 5 رسميًا. Offers/Stories/Reviews أصبحت callable-backed وrole-gated مع حماية الحقول المشتقة من أي كتابة مباشرة من المتصفح. الفجوات غير الحاجزة المتبقية صريحة: live staging smoke للـ content transport، وقرار ما إذا كانت bulk moderation تبقى خارج النطاق الحالي. |
| Phase 6 - Analytics + Config | `accepted with follow-up` | `AWC-P6-02` أغلق Phase 6 رسميًا. dashboard baseline + config governance baseline منجزتان ومثبتتان عبر web tests/build + functions build + config emulator subset. الفجوات غير الحاجزة المتبقية صريحة: staging smoke للـ config transport، وتحديد ما إذا كانت dashboard trends/drilldowns ستدخل نطاقًا لاحقًا. |
| Phase 7 - Hardening + Release | `accepted` | `AWC-P7-02` أغلق Phase 7 هندسيًا، وتم إغلاق follow-up التشغيلي في `AWC-P7-F01D` (browser-authenticated smoke ناجحة) مع تحديث القرار النهائي إلى `GO_LIVE_READY`. |

## 4. سجل التنفيذ

### Entry 001

- Step ID: `AWC-P0-01`
- Status: `done`
- Title: `Lock governance contracts for RBAC, command model, config governance, and phase gates`
- Goal:
  - استخراج Phase 0 من الخطة الشاملة إلى وثيقة تنفيذ مستقلة قابلة للاعتماد.
  - تحويل القرارات الحاكمة من عناوين إلى عقود واضحة وقابلة للتنفيذ.
  - قفل ما يجب حسمه قبل أي كود في:
    - RBAC
    - command model
    - expected_state
    - dual approval
    - export governance
    - deployment strategy
    - read-model health
- Expected Deliverables:
  - وثيقة تنفيذ مستقلة لـ `Phase 0`
  - Policy Matrix أولية قابلة للمراجعة
  - command contract table
  - dual-approval state machine table
  - deployment decision section
  - phase gates واضحة
- Claims To Verify Later:
  - أن كل بند حساس في الخطة أصبح له contract واضح
  - أن لا يوجد `TBD` حرج في Phase 0
  - أن Policy Matrix تغطي roles/screens/commands/read models/escalation
  - أن command model يحدد replay/conflict behavior
  - أن export policy وfallback removal criteria موثقتان
- Verification Required:
  - مراجعة الوثيقة الجديدة
  - مطابقة الوثيقة مع الخطة الشاملة
  - التحقق من عدم وجود تضارب داخلي بين sections

- Outcome Summary:
  - تم إنشاء وثيقة تنفيذ مستقلة: `docs/release/admin_web_console_phase0_governance_lock.md`.
  - الوثيقة تغطي العقود المطلوبة صراحة: tech rule, RBAC SoT, claims/fallback conflict, policy matrix skeleton, command model, expected_state, dual approval, config governance, export governance, read-model freshness/health, deployment decision, fallback removal criteria, phase gate.
  - تم تحديث فهرس مستندات الإصدار في `README.md` لإدراج وثيقة Phase 0 بجانب المتتبع.

- Risks / Unresolved Items:
  - Historical note: البنود المفتوحة في نهاية `AWC-P0-01` تم حسمها أو تسجيلها رسميًا في `AWC-P0-02` داخل سجل القبول.

### Entry 002

- Step ID: `AWC-P0-02`
- Status: `done`
- Title: `Phase 0 ratification and acceptance record`
- Goal:
  - إقفال Phase 0 تشغيليًا بسجل قبول auditable.
  - تحويل البنود المفتوحة إلى قرارات مقبولة أو follow-up مؤرخ بمالك واضح.
- Expected Deliverables:
  - سجل قبول Phase 0 بعقود تفصيلية
  - حالة قبول لكل عقد (`accepted` / `accepted with follow-up` / `rejected`)
  - توثيق ملاك الإشارات التشغيلية ومسارات التصعيد
- Verification Required:
  - كل عقد حوكمة له حالة قبول صريحة
  - البنود المفتوحة ليست مخفية داخل النص
  - حالة tracker تطابق قرار القبول الفعلي

- Outcome Summary:
  - تم إنشاء: `docs/release/admin_web_console_phase0_acceptance_record.md`.
  - تم اعتماد عتبات الموافقة المزدوجة `100/500 ILS` كقرار تشغيلي.
  - تم اعتماد بديل تشغيلي موثق عند غياب staged/canary publish.
  - تم تعيين ownership واضح لإشارات:
    - `fallback_auth_used`
    - `rbac_conflict_detected`
  - حالة Phase 0 أصبحت `done` لأن كل العقود الحرجة مقبولة.

- Risks / Unresolved Items:
  - `P0-F01`: استكمال خريطة دعم canary على البيئات المستهدفة.
    - Owner: `Platform Owner`
    - Due: `2026-04-18`
    - Escalation: `Platform Owner -> Release Manager -> Product Ops Owner`
    - Severity: `medium` (غير حاجز لبدء Phase 1)

### Entry 003

- Step ID: `AWC-P1-01M`
- Status: `done`
- Title: `Merge Phase 1 shell with RBAC foundation`
- Goal:
  - دمج shell المقبول من Phase 1 مع RBAC foundation المقبول.
  - إثبات اتساق route visibility وdirect route access denial وplaceholder capability notes.
  - تحديث tracker فقط بعد تحقق tests/build.
- Files Updated:
  - `admin_web_console/lib/auth/route-guards.ts`
  - `admin_web_console/lib/navigation/admin-route-map.ts`
  - `admin_web_console/components/admin/placeholder-screen.tsx`
  - `admin_web_console/app/(protected)/admin/dashboard/page.tsx`
  - `admin_web_console/app/(protected)/admin/topups/page.tsx`
  - `admin_web_console/app/(protected)/admin/wallet-audit/page.tsx`
  - `admin_web_console/app/(protected)/admin/reversals/page.tsx`
  - `admin_web_console/app/(protected)/admin/venues/page.tsx`
  - `admin_web_console/app/(protected)/admin/readiness/page.tsx`
  - `admin_web_console/lib/auth/rbac-shell.integration.test.ts`
  - `admin_web_console/vitest.config.ts`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `npm test`:
    - test files: `2`
    - tests passed: `11/11`
    - includes RBAC unit tests + shell/RBAC integration tests
  - `npm run build`:
    - status: success
    - protected/public admin routes compiled successfully
- Outcome Summary:
  - shell أصبح موصولًا بعقد الحراسة الفعلي عبر APIs:
    - `getCurrentAdminSession`
    - `canAccessRoute`
    - `canRenderAction`
  - direct route denial أصبح قابلًا للاختبار الصريح عبر `evaluateRouteAccess` مع redirect واضح إلى `access-denied`.
  - placeholder rendering أصبح capability-aware:
    - route capability visibility
    - mutation capability notes (بدون أي business actions حقيقية)
  - sidebar visibility بقيت مبنية على نفس منطق guard الخاص بالمسارات لضمان الاتساق مع direct access.
- Constraints Check:
  - لا يوجد تنفيذ Phase 2
  - لا يوجد finance command implementation
  - لا يوجد Firebase write logic
  - لا يوجد merge/commit ضمن هذه الجولة

### Entry 004

- Step ID: `AWC-P1-02`
- Status: `done`
- Title: `Phase 1 acceptance and closure record`
- Goal:
  - إقفال Phase 1 رسميًا بعد دمج shell + RBAC.
  - تحويل حالة التنفيذ إلى acceptance record قابل للتدقيق.
  - منع أي ادعاء اكتمال يتجاوز نطاق Phase 1.
- Files Updated:
  - `docs/release/admin_web_console_phase1_acceptance_record.md` (new)
  - `docs/release/admin_web_console_progress_tracker.md`
  - `README.md`
- Verification Evidence:
  - `npm test`:
    - test files: `2`
    - tests passed: `11/11`
  - `npm run build`:
    - status: success
    - protected/public routes compiled successfully
  - shell + RBAC integration status:
    - integrated and tested
- Outcome Summary:
  - تم إنشاء سجل قبول Phase 1 موثق في `docs/release/admin_web_console_phase1_acceptance_record.md`.
  - حالة المرحلة تحولت إلى `accepted with follow-up` بدل `done` لتجنب المبالغة.
  - تم توثيق non-goals وفجوات الانتقال إلى Phase 2 بشكل صريح.
- Constraints Check:
  - لا يوجد تنفيذ Phase 2 في هذه الجولة
  - لا يوجد finance command implementation
  - لا يوجد backend wiring خارج نطاق Phase 1

### Entry 005

- Step ID: `AWC-P2-01A`
- Status: `done`
- Title: `Finance command contracts baseline`
- Goal:
  - إنشاء baseline واضح وقابل للاختبار لعقود أوامر التمويل في Phase 2.
  - تثبيت typing لعناصر: metadata, request/response, authorization policy, error normalization.
- Files Updated:
  - `admin_web_console/lib/finance/command-contracts.ts`
  - `admin_web_console/lib/finance/command-policy.ts`
  - `admin_web_console/lib/finance/command-client.ts`
  - `admin_web_console/lib/finance/command-contracts.test.ts`
  - `admin_web_console/lib/finance/command-policy.test.ts`
  - `admin_web_console/lib/finance/command-client.test.ts`
- Verification Evidence:
  - `npm test`: passed (contracts/policy/client suites green)
  - `npm run build`: passed
- Outcome Summary:
  - command metadata أصبحت source-of-truth لقدرات التنفيذ والأدوار.
  - policy layer تدعم default deny + capability enforcement.
  - client layer بقيت بدون backend writes فعلية (ضمن نطاق Phase 2 الحالي).

### Entry 006

- Step ID: `AWC-P2-01B`
- Status: `done`
- Title: `Finance read models and formatter surfaces`
- Goal:
  - تجهيز read surfaces في التمويل ببيانات mock/read-model قابلة للعرض والاختبار.
  - فصل formatters عن عرض الصفحة لتوحيد سلوك العرض.
- Files Updated:
  - `admin_web_console/lib/finance/read-models.ts`
  - `admin_web_console/lib/finance/read-model-formatters.ts`
  - `admin_web_console/lib/finance/read-model-formatters.test.ts`
  - `admin_web_console/components/finance/topup-queue-table.tsx`
  - `admin_web_console/components/finance/wallet-audit-table.tsx`
  - `admin_web_console/components/finance/readiness-panel.tsx`
  - `admin_web_console/components/finance/index.ts`
  - `admin_web_console/components/finance/index.tsx`
- Verification Evidence:
  - formatter tests موجودة ومفعلة ضمن `vitest`
  - الملفات normalized إلى TS/TSX صالح (إزالة التشوهات النصية السابقة)
- Outcome Summary:
  - read model layer أصبحت جاهزة للدمج مع command affordances.
  - formatter semantics موحدة (currency/date/status).

### Entry 007

- Step ID: `AWC-P2-01M`
- Status: `done`
- Title: `Merge Phase 2 command contracts with finance read surfaces`
- Goal:
  - دمج command metadata/policy مع Top-Ups / Wallet Audit / Readiness.
  - ضمان أن affordances تعكس capability + command availability.
  - منع إظهار/تشغيل finance mutations لغير الأدوار المخوّلة.
  - توحيد عرض حالات `pending/unavailable/conflict`.
- Files Updated:
  - `admin_web_console/lib/finance/surface-affordances.ts`
  - `admin_web_console/lib/finance/surface-affordances.test.ts`
  - `admin_web_console/lib/finance/read-models.ts`
  - `admin_web_console/lib/finance/read-model-formatters.ts`
  - `admin_web_console/lib/finance/read-model-formatters.test.ts`
  - `admin_web_console/app/(protected)/admin/topups/page.tsx`
  - `admin_web_console/app/(protected)/admin/wallet-audit/page.tsx`
  - `admin_web_console/app/(protected)/admin/readiness/page.tsx`
  - `admin_web_console/components/finance/topup-queue-table.tsx`
  - `admin_web_console/components/finance/wallet-audit-table.tsx`
  - `admin_web_console/components/finance/readiness-panel.tsx`
  - `admin_web_console/components/finance/index.ts`
  - `admin_web_console/components/finance/index.tsx`
  - `admin_web_console/app/globals.css`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `npm test`:
    - test files: `7`
    - tests passed: `29/29`
  - `npm run build`:
    - status: success
    - protected admin finance routes compiled successfully (`topups`, `wallet-audit`, `readiness`)
- Outcome Summary:
  - command affordances أصبحت مبنية على source-of-truth واحد (`FINANCE_COMMAND_METADATA` + policy).
  - non-finance roles لم تعد ترى أزرار mutation على Top-Ups وWallet Audit.
  - readiness command بقي متاحًا وفق `view_readiness` مع نفس runtime-state semantics.
  - تمت إضافة tests صريحة لـ:
    - finance role affordance visibility
    - non-finance mutation hiding
    - pending/unavailable/conflict consistency
- Constraints Check:
  - لا يوجد backend write wiring فعلي في هذه الجولة
  - لا يوجد توسع خارج Phase 2

### Entry 008

- Step ID: `AWC-P2-02A`
- Status: `done`
- Title: `Real finance transport adapters to existing backend callables`
- Goal:
  - استبدال transport الوهمي بطبقة تنفيذ حقيقية server-authorized.
  - ربط كل command callable surface موجودة فعليًا فقط.
  - منع أي fake success أو أي contract inventing.
- Files Updated:
  - `admin_web_console/lib/finance/finance-command-transport.ts`
  - `admin_web_console/lib/finance/finance-command-adapters.ts`
  - `admin_web_console/lib/finance/finance-command-adapters.test.ts`
  - `admin_web_console/lib/finance/default-command-transport.ts`
  - `admin_web_console/lib/finance/command-client.ts`
  - `admin_web_console/lib/finance/command-contracts.ts`
- Verification Evidence:
  - callable mapping مثبت إلى surfaces الحالية فقط:
    - `reviewMerchantTopUpRequest`
    - `reverseWalletEntry`
    - `verifyWalletOperationalReadiness`
  - missing surface (`approve_reversal`) يرجع `unavailable` بشكل typed وصريح.
  - `npm test` (re-validation ضمن جولة الدمج):
    - test files: `9`
    - tests passed: `43/43`
  - `npm run build`: success
- Outcome Summary:
  - transport أصبح فعليًا ومفصولًا عن rendering.
  - error normalization أصبحت contract-accurate (`401/403/409/422/503` -> command error codes).
  - expected_state + idempotency key propagation بقيت ضمن command envelope.

### Entry 009

- Step ID: `AWC-P2-02B`
- Status: `done`
- Title: `Executable finance surfaces with command runtime behavior`
- Goal:
  - تفعيل واجهات التمويل المحمية لتشغيل أوامر العقود عبر provider موحّد.
  - توحيد UX لحالات runtime (`pending/conflict/unavailable`).
  - تثبيت role-gated affordances ومنع ظهور mutation controls لغير المخوّلين.
- Files Updated:
  - `admin_web_console/lib/finance/surface-affordances.ts`
  - `admin_web_console/lib/finance/surface-affordances.test.ts`
  - `admin_web_console/components/finance/topup-queue-table.tsx`
  - `admin_web_console/components/finance/wallet-audit-table.tsx`
  - `admin_web_console/components/finance/readiness-panel.tsx`
  - `admin_web_console/components/finance/finance-command-provider.tsx`
  - `admin_web_console/components/finance/command-runtime-callout.tsx`
  - `admin_web_console/components/finance/finance-surfaces.test.tsx`
  - `admin_web_console/components/finance/index.ts`
  - `admin_web_console/app/(protected)/admin/topups/page.tsx`
  - `admin_web_console/app/(protected)/admin/wallet-audit/page.tsx`
  - `admin_web_console/app/(protected)/admin/readiness/page.tsx`
  - `admin_web_console/app/globals.css`
- Verification Evidence:
  - app-level surfaces tests موجودة وتغطي:
    - role visibility للـ mutation actions
    - conflict/unavailable runtime callouts
    - readiness command visibility حسب policy
  - `npm test` (re-validation ضمن جولة الدمج):
    - test files: `9`
    - tests passed: `43/43`
  - `npm run build`: success
- Outcome Summary:
  - executable UI أصبح يعكس authorization + runtime state بدل static affordances فقط.
  - non-finance roles لا ترى ولا تشغّل mutation controls داخل Top-Ups وWallet Audit.

### Entry 010

- Step ID: `AWC-P2-02M`
- Status: `done`
- Title: `Merge real transport adapters with executable finance surfaces`
- Goal:
  - دمج 02A + 02B في مسار تطبيق واحد قابل للتحقق.
  - إثبات سلوك end-to-end للأوامر ضمن حدود Phase 2.
- Files Updated:
  - `admin_web_console/lib/finance/read-models.ts`
  - `admin_web_console/lib/finance/build-command-requests.ts`
  - `admin_web_console/lib/finance/finance-command-adapters.ts`
  - `admin_web_console/components/finance/finance-surfaces.test.tsx`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `npm test`:
    - test files: `9`
    - tests passed: `43/43`
    - يشمل صراحة:
      - `lib/finance/finance-command-adapters.test.ts`
      - `components/finance/finance-surfaces.test.tsx`
  - `npm run build`:
    - status: success
    - finance routes compiled: `topups`, `wallet-audit`, `readiness`
- Outcome Summary:
  - request builders أصبحت venue-aware وتدفع payload أقرب للتنفيذ الفعلي.
  - app-level tests تثبت أن finance roles تشغّل الأوامر المسموحة عبر real adapters.
  - missing surface (`approve_reversal`) يظهر كـ `unavailable` بشكل صريح ومختبَر.
  - conflict paths بقيت متسقة في العرض عبر callout runtime.
- Constraints Check:
  - لا يوجد توسع Phase 3
  - لا يوجد bypass لقواعد server-authorized command execution
  - لا يوجد ادعاء إكمال Phase 2؛ الحالة الرسمية تبقى `in_progress`

### Entry 011

- Step ID: `AWC-P2-03A`
- Status: `done`
- Title: `Server-backed finance read adapters and data contracts`
- Goal:
  - استبدال مصادر القراءة الوهمية في طبقة بيانات التمويل بمسارات server-backed حيث السطح الخلفي موجود فعليًا.
  - تعريف عقود read-state صريحة وقابلة للاختبار.
  - إبقاء command execution flow بدون تغيير.
- Files Updated:
  - `admin_web_console/lib/finance/read-models.ts`
  - `admin_web_console/lib/finance/finance-read-transport.ts`
  - `admin_web_console/lib/finance/finance-read-adapters.ts`
  - `admin_web_console/lib/finance/finance-read-loader.ts`
  - `admin_web_console/lib/finance/finance-read-transport.test.ts`
  - `admin_web_console/lib/finance/finance-read-adapters.test.ts`
  - `admin_web_console/lib/finance/finance-read-loader.test.ts`
  - `admin_web_console/components/finance/finance-surfaces.test.tsx`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - backend discovery (functions) أكّد أن surface القراءة المباشر المتاح فعليًا حاليًا هو:
    - `verifyWalletOperationalReadiness`
  - لا يوجد callable read مخصص حاليًا لـ:
    - top-up queue
    - wallet audit
  - missing read surfaces في طبقة الـ callable-only adapter تُعاد كفجوة typed `unavailable` بدون fabrication للبيانات (قبل مسار الـ snapshot؛ انظر Amendment).
  - `npm test` (سجل وقت إغلاق 03A):
    - test files: `13`
    - tests passed: `69/69`
    - يشمل صراحة:
      - `lib/finance/finance-read-transport.test.ts`
      - `lib/finance/finance-read-adapters.test.ts`
      - `lib/finance/finance-read-loader.test.ts`
  - إعادة تحقق بعد `AWC-P2-03B`/`AWC-P2-03M`: انظر Entry 013 (`71/71`).
  - `npm run build`:
    - status: success
    - finance routes compiled: `topups`, `wallet-audit`, `readiness`
- Outcome Summary:
  - read transport/adapters أصبحت server-backed وقابلة للتمديد عند توفر read surfaces إضافية.
  - عقود النتائج أصبحت explicit وقابلة للاختبار لحالات:
    - `success`
    - `empty`
    - `stale`
    - `unavailable`
    - `unauthorized`
    - `forbidden`
  - readiness read أصبح يُطبّع من diagnostics الفعلية القادمة من callable backend مع freshness/staleness semantics واضحة.
  - top-up queue وwallet audit: لا يوجد callable read مخصص في الـ backend بعد؛ العقد والـ loader جاهزان، والمسار التشغيلي الكامل للواجهة يُكمَّل في `AWC-P2-03B` عبر snapshot/HTTP/inline مع تسمية مصدر صريحة (انظر `AWC-P2-03M`).
  - **تحديث لاحق (`AWC-P2-04A` / Entry 014):** أُضيفت callables القراءة `listMerchantTopUpRequestsForAdmin` و`listMerchantWalletLedgerEntriesForAdmin` وأصبحت الواجهة تفضّلها عند توفر `NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL`.
- Amendment (rolled forward in `AWC-P2-03B` / verified in `AWC-P2-03M`):
  - الوصف «غير متاح دائمًا» لصفوف الطابور والـ ledger كان يصف فقط طبقة الـ adapter قبل إضافة `finance-read-snapshot-transport` والـ layered transport؛ بعد الدمج تبقى الفجوة **في الـ callable** وليس في إمكانية عرض بيانات مصنفة المصدر في الواجهة — ثم أُغلق callable gap لطابور الشحن والـ ledger في `AWC-P2-04A`.
- Constraints Check:
  - لا يوجد direct Firestore writes من admin web
  - لا يوجد mutation work جديد
  - لا يوجد توسع Phase 3
  - لا يوجد invented backend contracts

### Entry 012

- Step ID: `AWC-P2-03B`
- Status: `done`
- Title: `Live finance read-state surfaces (success/empty/stale/unavailable)`
- Goal:
  - استبدال عرض mock-only بمسارات read-state صريحة على Top-Ups / Wallet Audit / Readiness.
  - إبقاء command provider و affordances و runtime callouts كما هي.
  - عدم إخفاء فجوات المصدر؛ عدم تزييف نجاح عند تعطل النقل.
- Files Updated:
  - `admin_web_console/lib/finance/finance-read-types.ts`
  - `admin_web_console/lib/finance/finance-read-snapshot-transport.ts`
  - `admin_web_console/lib/finance/finance-read-loader.ts`
  - `admin_web_console/lib/finance/finance-read-loader.test.ts`
  - `admin_web_console/lib/finance/finance-read-transport.ts`
  - `admin_web_console/lib/finance/finance-read-adapters.ts`
  - `admin_web_console/lib/finance/read-models.ts`
  - `admin_web_console/components/finance/finance-read-banner.tsx`
  - `admin_web_console/components/finance/finance-admin-page-shell.tsx`
  - `admin_web_console/components/finance/topup-queue-table.tsx`
  - `admin_web_console/components/finance/wallet-audit-table.tsx`
  - `admin_web_console/components/finance/readiness-panel.tsx`
  - `admin_web_console/components/finance/finance-read-states.test.tsx`
  - `admin_web_console/components/finance/index.ts`
  - `admin_web_console/app/(protected)/admin/topups/page.tsx`
  - `admin_web_console/app/(protected)/admin/wallet-audit/page.tsx`
  - `admin_web_console/app/(protected)/admin/readiness/page.tsx`
  - `admin_web_console/app/globals.css`
- Verification Evidence:
  - `npm test`:
    - test files: `13`
    - tests passed: `71/71`
    - يشمل صراحة:
      - `lib/finance/finance-read-loader.test.ts` (fixture، inline، HTTP 502، readiness callable، stale، صلاحيات)
      - `components/finance/finance-read-states.test.tsx` (فراغ، غير متاح، قديم، RBAC على القراءة)
      - `components/finance/finance-surfaces.test.tsx` (أوامر + readResult)
  - `npm run build`:
    - status: success
    - finance routes compiled: `topups`, `wallet-audit`, `readiness`
- Outcome Summary:
  - الصفحات تستدعي `loadTopUpQueueRead` / `loadWalletLedgerRead` / `loadReadinessRead` وتمرر `FinanceReadResult` إلى الجداول/اللوحات.
  - طبقة snapshot (`development_fixture` | `inline_json` | `http:…`) تغذي الطابور والـ ledger؛ readiness يستخدم callable عند توفر `NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL` ثم fallback آمن للـ snapshot عند أخطاء قابلة لإعادة المحاولة.
  - واجهة المشغّل تعرض المصدر و`asOf` و`fetchedAt`؛ stale و unavailable تظهران ببانر/نص صريح.
- Constraints Check:
  - لا Phase 3
  - لا كتابة backend مباشرة من الويب
  - قواعد تفويض الأوامر لم تُلمس في هذا المسار

### Entry 013

- Step ID: `AWC-P2-03M`
- Status: `done`
- Title: `Merge server-backed read adapters with live finance read surfaces`
- Goal:
  - التأكد أن مخرجات `AWC-P2-03A` (عقود read + callable readiness) و`AWC-P2-03B` (واجهة read-state + snapshot مسار) تعملان معًا في مسار الخادم الواحد.
  - التحقق من اتساق أوامر Phase 2 (role-safe، بدون bypass).
- Files Updated:
  - (تحقق ودمج نهائي؛ الملفات الأساسية مذكورة في `012`؛ هذا الإدخال يحدّث التتبع فقط بعد نجاح الاختبارات والبناء)
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `npm test` (تشغيل فعلي `2026-04-09` ضمن جلسة التحقق من الدمج):
    - test files: `13`
    - tests passed: `71/71`
  - إعادة تحقق عند تنفيذ/إعادة فتح `AWC-P2-03M`: `npm test` → `13` ملفات، `71/71` ناجحة؛ `npm run build` → نجاح (مسارات التمويل الثلاثة تُبنى).
  - `npm run build`:
    - status: success
    - finance routes: `topups`, `wallet-audit`, `readiness`
  - تحقق سلوكي (مغطى بالاختبارات):
    - `success` + `empty` + `stale`/`unavailable` على واجهة القراءة
    - أزرار mutation تبقى مخفية/معطلة حسب `surface-affordances` + `command-policy` كما في `finance-surfaces.test.tsx` و`finance-read-states.test.tsx`
- Outcome Summary:
  - مسار القراءة الموحّد: `page` → `load*Read` → `FinanceReadTransport` (layered: snapshot + adapters) → `FinanceReadResult` (UI) → مكوّنات العميل داخل `FinanceCommandProvider`.
  - القراءة server-backed حيث يتوفر callable الجاهز؛ غياب المصدر أو الخطأ يظهر صراحةً دون سقوط صامت إلى بيانات وهمية ناجحة.
  - أوامر التمويل تبقى عبر `createFinanceCommandClient` + نفس قواعد التفويض؛ لا دمج read يتجاوز mutation rules.
- Constraints Check:
  - لا ادعاء إكمال Phase 2 بالكامل
  - لا Phase 3
  - لا fake completion

### Entry 014

- Step ID: `AWC-P2-04A`
- Status: `done`
- Title: `Real server-backed reads for Top-Up Queue and Wallet Audit`
- Goal:
  - إغلاق فجوة القراءة الكبيرة المتبقية في Phase 2 باستبدال الاعتماد على snapshot/fallback فقط لطابور الشحن وسجل المحفظة بأسطح قراءة مفوّضة من الخادم.
  - الحفاظ على الحوكمة: قراءة فقط، بدون كتابة Firestore من الويب، بدون بيانات مخترعة.
- Expected Deliverables:
  - HTTPS callables للقراءة: طابور `merchant_topup_requests`، مدخلات `merchant_wallets/{venueId}/entries` (مع `collectionGroup` عند غياب `venueId`) مع عقد استعلام: `venueId`، `statuses` / `entryTypes`، `limit`، نطاق زمني اختياري (`createdAfter` / `createdBefore` ISO)، `correlationId`.
  - تحديث `FINANCE_READ_CALLABLE_SURFACES` + `createFinanceReadAdaptersTransport` + `createLayeredFinanceReadTransport` (تفضيل callable ثم snapshot عند `unavailable` فقط؛ لا fallback على `unauthorized` / `forbidden`).
  - اختبارات: نجاح، فراغ، غير مصرّح، استجابة غير صالحة، تعطل backend (fallback)، علم `stale` عبر `checkedAt` / `maxAgeMs`.
- Files Updated:
  - `wain_app/functions/src/index.ts` — `listMerchantTopUpRequestsForAdmin`، `listMerchantWalletLedgerEntriesForAdmin`؛ إزالة ثوابت/دوال reversal غير مستخدمة كانت تكسر `tsc` بسبب `noUnusedLocals`.
  - `wain_app/firestore.indexes.json` — فهارس `COLLECTION_GROUP` لـ `entries` (`created_at`، و`venue_id` + `created_at`).
  - `wain_app/admin_web_console/lib/finance/read-models.ts` — حقول استعلام التاريخ الاختيارية.
  - `wain_app/admin_web_console/lib/finance/finance-read-adapters.ts` — ربط callables وتحليل الاستجابة.
  - `wain_app/admin_web_console/lib/finance/finance-read-snapshot-transport.ts` — layered لطابور الشحن والـ ledger.
  - `wain_app/admin_web_console/lib/finance/finance-read-adapters.test.ts`، `finance-read-loader.test.ts`.
  - `wain_app/functions/test/emulator/securityCallableFlows.test.js` — `W45` / `W45b` / `W46`.
  - `wain_app/admin_web_console/components/finance/reversal-approval-panel.tsx` — إصلاح JSX (`->` كان يكسر esbuild).
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `wain_app/functions`: `npm run build` → نجاح (`tsc`).
  - `wain_app/admin_web_console`: `npm test` (تشغيل `2026-04-09` ضمن جلسة التحقق):
    - test files: `13`
    - tests passed: `85/85`
  - `wain_app/admin_web_console`: `npm run build` → نجاح (مسارات التمويل تُبنى).
  - اختبارات المحاكي (اختيارية للـ CI المحلي): `npm run test:emulator:aggregate` داخل `functions/` تغطي `W45`/`W46` عند تشغيل emulator.
- Outcome Summary:
  - Top-Up Queue و Wallet Audit يستخدمان `listMerchantTopUpRequestsForAdmin` و `listMerchantWalletLedgerEntriesForAdmin` عند ضبط `NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL`؛ المصدر يظهر كـ `callable:…` في `FinanceReadFreshness.channel`.
  - عند تعطل الـ callable القابل لإعادة المحاولة يبقى fallback للـ snapshot/inline/http كما في readiness؛ readiness لم يُغيّر عقده.
  - تسمية المشغّل للتاجر في الطابور مأخوذة من وثيقة `venues` (`name_ar` / `name`) عند التوفر.
- Constraints Check:
  - لا Phase 3
  - لا كتابة admin-web إلى Firestore
  - لا بيانات وهمية من الخادم

### Entry 015

- Step ID: `AWC-P2-04B`
- Status: `done`
- Title: `Reversal approval path and dual-approval completion`
- Goal:
  - إغلاق فجوة `approve_reversal` المتبقية في Phase 2 عبر surface backend حقيقي ومفوّض.
  - تطبيق dual-approval governance بالكامل لمسار reversal (عتبات المبلغ، فصل المنفّذَين، وصلاحية super_admin للحالات العالية).
  - توحيد runtime/UI semantics لمسارات `pending_second_approval` و`approved_and_executed` و`conflict` و`unavailable`.
- Files Updated:
  - `wain_app/functions/src/index.ts`
  - `wain_app/functions/test/emulator/securityCallableFlows.test.js`
  - `wain_app/admin_web_console/lib/finance/command-contracts.ts`
  - `wain_app/admin_web_console/lib/finance/build-command-requests.ts`
  - `wain_app/admin_web_console/lib/finance/surface-affordances.ts`
  - `wain_app/admin_web_console/lib/finance/finance-command-adapters.ts`
  - `wain_app/admin_web_console/lib/finance/finance-command-adapters.test.ts`
  - `wain_app/admin_web_console/components/finance/reversal-approval-panel.tsx`
  - `wain_app/admin_web_console/components/finance/wallet-audit-table.tsx`
  - `wain_app/admin_web_console/components/finance/index.ts`
  - `wain_app/admin_web_console/app/(protected)/admin/reversals/page.tsx`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `wain_app/functions`: `npm run build` → نجاح (`tsc`).
  - `wain_app/functions`: `node --test --test-concurrency=1 --test-name-pattern="W47|W48|W49|W50|W51|W52" test/emulator/securityCallableFlows.test.js` → `6/6` ناجحة.
    - يغطي:
      - pending → approval happy path
      - unauthorized / same-actor forbidden
      - super-admin enforcement for high-value reversal
      - expected_state conflict
      - expired request conflict
      - duplicate approval idempotent retry
  - `wain_app/admin_web_console`: `npm test -- lib/finance/finance-command-adapters.test.ts components/finance/finance-surfaces.test.tsx` → `17/17` ناجحة.
- Outcome Summary:
  - `reverseWalletEntry` أصبح يعيد `pending_second_approval` للعمليات فوق حد الموافقة الواحدة، ويحتفظ بالتنفيذ الفوري للعمليات الصغيرة.
  - أُضيف callable جديد `approveWalletReversalRequest` مع expected-state checks، expiry checks، second-actor separation، وrole gating.
  - أصبح `approve_reversal` في admin web مربوطًا بـ backend حقيقي بدل `unavailable` gap.
  - واجهة reversals أصبحت تنفيذية (ليست placeholder) وتعرض نتائج الموافقة/التنفيذ وحالات التعارض/عدم التوفر بشكل صريح.
- Constraints Check:
  - لا Phase 3
  - لا bypass لقواعد server-authorized execution
  - لا fake dual-approval completion

### Entry 016

- Step ID: `AWC-P2-04M`
- Status: `done`
- Title: `Merge real finance reads with governed reversal approval flow`
- Goal:
  - دمج مخرجات `AWC-P2-04A` و`AWC-P2-04B` في حالة Phase 2 واحدة قابلة للتحقق تشغيليًا.
  - إعادة إثبات أن القراءة الحية لطابور الشحن وسجل المحفظة ومسار readiness تتماسك مع مسار موافقة العكس المحكوم بدون أي bypass للتفويض أو idempotency.
  - تحديث الـ tracker فقط بعد تحقق build/tests على `functions` و`admin_web_console`.
- Files Updated:
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `wain_app/functions`: `npm run build` → نجاح (`tsc`).
  - `wain_app/functions`: `node --test --test-concurrency=1 --test-name-pattern="W27|W28|W29|W30|W31|W32|W33|W45|W45b|W46|W47|W48|W49|W50|W51|W52" test/emulator/securityCallableFlows.test.js` → `16/16` ناجحة.
    - يغطي:
      - `W27`-`W33`: regression subset لمسار reversal الأساسي
      - `W45` / `W45b` / `W46`: server-backed reads لطابور الشحن وسجل المحفظة
      - `W47`-`W52`: dual-approval approval lifecycle
  - `wain_app/admin_web_console`: `npm test`:
    - test files: `13`
    - tests passed: `85/85`
    - يشمل صراحة:
      - `lib/finance/finance-read-loader.test.ts`
      - `lib/finance/finance-read-adapters.test.ts`
      - `lib/finance/finance-command-adapters.test.ts`
      - `components/finance/finance-read-states.test.tsx`
      - `components/finance/finance-surfaces.test.tsx`
  - `wain_app/admin_web_console`: `npm run build` → نجاح.
- Outcome Summary:
  - القراءة الحية أصبحت متماسكة مع طبقة الأوامر التنفيذية:
    - `Top-Up Queue` و`Wallet Audit` يفضّلان الـ callables الحقيقية ثم fallback آمن فقط عند الأخطاء القابلة لإعادة المحاولة.
    - `Readiness` بقي على نفس عقده مع callable مباشر وread-state صريح.
  - مسار `approve_reversal` أصبح جزءًا حيًا من التطبيق وليس gap موثّق فقط:
    - backend callable موجود ومختبَر
    - web adapter/request builder موجودان ومختبران
    - reversals route أصبحت تنفيذية عبر `ReversalApprovalPanel`
  - القيود الجوهرية بقيت محفوظة بعد الدمج:
    - role-safe read + command visibility
    - expected_state propagation
    - idempotent replay behavior
    - explicit conflict / unavailable / pending_second_approval states
- Constraints Check:
  - لا Phase 3
  - لا fake completion
  - لا shortcuts غير موثقة حول server authorization أو dual approval

### Entry 017

- Step ID: `AWC-P2-05`
- Status: `accepted with follow-up`
- Title: `Staging rollout validation for Finance Ops V1`
- Goal:
  - تنفيذ rollout فعلي إلى البيئة النشطة `wain-d2e28`.
  - جمع evidence تشغيلية قبل إعداد acceptance record النهائي لـ Phase 2.
  - التحقق من readiness البيئية، ثم محاولة rehearsal حي لأسطح Finance Ops V1 الجديدة.
- Files Updated:
  - `wain_app/firestore.indexes.json`
  - `wain_app/functions/scripts/verify_wallet_env.js`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - deploy:
    - `firebase deploy --only "functions,firestore" --project wain-d2e28` → نجاح
    - يشمل:
      - نشر functions المحدثة
      - تطبيق قواعد Firestore
      - إنشاء الـ callable surfaces الجديدة على المشروع
      - إنشاء index `entries(venue_id ASC, created_at DESC)` بنجاح
  - environment verification:
    - `cd wain_app/functions && npm run wallet:verify-env` → `PASS`
    - بعد إصلاح fallback المحلي بإضافة `x-goog-user-project` إلى Firestore REST requests عند غياب ADC
  - staging rehearsal attempt:
    - `cd wain_app/functions && $env:GCLOUD_PROJECT='wain-d2e28'; npm run wallet:staging-rehearsal`
    - النتيجة: `FAIL`
    - السبب: `Could not load the default credentials`
- Outcome Summary:
  - rollout نفسه على المشروع `wain-d2e28` تم بنجاح.
  - `wallet:verify-env` أصبح صالحًا على هذا الجهاز حتى بدون ADC، باستخدام fallback read-only إلى جلسة `firebase login` النشطة.
  - smoke validation الحية لمسارات:
    - `listMerchantTopUpRequestsForAdmin`
    - `listMerchantWalletLedgerEntriesForAdmin`
    - `reverseWalletEntry`
    - `approveWalletReversalRequest`
    - `verifyWalletOperationalReadiness`
    لم تُغلق بالكامل بعد، لأن `run_wallet_staging_rehearsal.js` يعتمد على Firebase Admin ADC للكتابة إلى Firestore/Storage أثناء seed/rehearsal.
- Risks / Follow-up:
  - `P2-F01`: توفير مسار ADC صالح على جهاز التشغيل الحالي (service account أو Google ADC) أو بناء rehearsal path بديل لا يعتمد على Admin SDK المحلي للكتابة.
    - Owner: `Platform / Release Owner`
    - Due: `2026-04-11`
    - Escalation: `Platform Owner -> Release Manager -> Product Ops Owner`
    - Severity: `high` (حاجز لإقفال Phase 2 acceptance، لكنه ليس حاجزًا على صحة deploy نفسه)
- Constraints Check:
  - لا Phase 3
  - لا fake acceptance
  - لا ادعاء smoke validation حي غير موجود

### Entry 018

- Step ID: `AWC-P2-05B`
- Status: `accepted`
- Title: `Unblock staging smoke validation and capture actor-separation evidence`
- Goal:
  - إزالة blocker الـ ADC الذي كان يمنع rehearsal الحية على البيئة `wain-d2e28`.
  - إعادة تنفيذ smoke validation end-to-end على هذا الجهاز.
  - إثبات actor separation فعليًا لمسار `pending_second_approval`.
- Files Updated:
  - `wain_app/functions/src/index.ts`
  - `wain_app/functions/scripts/run_wallet_staging_rehearsal.js`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - local auth path:
    - تم تشغيل smoke باستخدام `authorized_user` ADC مؤقت مشتق من جلسة `firebase login` النشطة محليًا، بدون حفظ أي credentials جديدة داخل المستودع
  - functions build + redeploy:
    - `cd wain_app/functions && npm run build` → نجاح
    - `cd wain_app && firebase deploy --only "functions" --project wain-d2e28` → نجاح
  - environment verification:
    - `cd wain_app/functions && npm run wallet:verify-env` → `PASS`
  - staging rehearsal:
    - `cd wain_app/functions && npm run wallet:staging-rehearsal` مع `GOOGLE_APPLICATION_CREDENTIALS` مؤقتة + `GCLOUD_PROJECT=wain-d2e28` → نجاح
    - evidence log:
      - `docs/release/merchant_wallet_staging_evidence_log.json`
    - النتائج الأساسية:
      - `bucketName = wain-d2e28.firebasestorage.app`
      - `readiness.before.overallStatus = PASS`
      - `readiness.after.overallStatus = PASS`
      - `goNoGo = CONDITIONAL_GO_SOFT_LAUNCH`
      - `flows.reversalDualApproval.checks.pendingSecondApprovalReturned = true`
      - `flows.reversalDualApproval.checks.sameActorBlocked = true`
      - `flows.reversalDualApproval.checks.secondActorApprovalSucceeded = true`
      - `flows.reversalDualApproval.checks.walletBalanceRestored = true`
      - `flows.reversalDualApproval.approvalResult.requestedByUid != approvedByUid`
- Outcome Summary:
  - blocker الـ ADC أُزيل عمليًا على هذا الجهاز عبر مسار `authorized_user` مؤقت من جلسة Firebase CLI الحالية.
  - fallback bucket داخل functions أصبح متوافقًا مع مشاريع Firebase الحديثة خارج الـ emulator (`*.firebasestorage.app`) مع الإبقاء على `*.appspot.com` داخل emulator فقط.
  - rehearsal script أصبح:
    - يكتشف bucket الحقيقي بدل افتراض bucket قديم
    - يوثق dual-approval flow حيًا بمشغّلَين مختلفين
  - smoke validation أصبحت مكتملة للأسطح/التدفقات الأساسية:
    - `verifyWalletOperationalReadiness`
    - `createMerchantTopUpRequest`
    - `reviewMerchantTopUpRequest`
    - `reverseWalletEntry`
    - `approveWalletReversalRequest`
    - maintenance/reminder/lifecycle checks ضمن نفس evidence log
- Risks / Follow-up:
  - لا يوجد blocker حالي على إعداد acceptance record لـ Phase 2.
  - متابعة تحسين فقط:
    - توثيق أو أتمتة مسار الـ ADC المؤقت إذا أُريد تكرار smoke من جهاز جديد بنفس السهولة.
- Constraints Check:
  - لا Phase 3
  - لا fake smoke validation
  - لا shortcuts غير موثقة في منطق الأوامر أو dual approval

### Entry 019

- Step ID: `AWC-P2-06`
- Status: `done`
- Title: `Phase 2 acceptance and closure record`
- Goal:
  - إغلاق Phase 2 رسميًا اعتمادًا على الأدلة الفعلية فقط.
  - منع أي مبالغة في الإنهاء قبل فتح Phase 3.
- Files Updated:
  - `docs/release/admin_web_console_phase2_acceptance_record.md`
  - `docs/release/admin_web_console_progress_tracker.md`
  - `README.md`
- Verification Evidence:
  - acceptance inputs reviewed:
    - `docs/release/admin_web_console_execution_plan.md`
    - `docs/release/admin_web_console_progress_tracker.md`
    - `docs/release/merchant_wallet_staging_evidence_log.json`
    - `docs/release/admin_web_console_phase1_acceptance_record.md`
  - evidence adopted into closure:
    - `functions` build success
    - emulator subset `16/16`
    - `admin_web_console` tests/build success
    - staging deploy + `wallet:verify-env` PASS + full staging rehearsal PASS
- Outcome Summary:
  - Phase 2 أغلقت كـ `accepted with follow-up` لا `done`.
  - السبب:
    - core Finance Ops V1 validated and auditable
    - لكن dashboard widgets وqueue aging وCSV export ما زالت follow-up صريحة
  - Phase 3 أصبحت `next` بدل `blocked`.
- Constraints Check:
  - لا Phase 3 implementation
  - لا fake completion
  - الحكم مبني على evidence فعلية فقط

### Entry 020

- Step ID: `AWC-P3-01B`
- Status: `done`
- Title: `Venue Workspace shell with read-only core tabs`
- Goal:
  - بدء Phase 3 عبر إنشاء shell فعلي لمساحة venue workspace.
  - تقديم tabs أساسية قراءة فقط (`wallet`, `offers`, `stories`, `reviews`) بدون أي عمليات كتابة.
  - إبراز source/freshness والحالات التشغيلية (`empty` / `unavailable` / `stale`) بشكل واضح لكل tab.
- Files Updated:
  - `wain_app/admin_web_console/app/(protected)/admin/venues/[venueId]/page.tsx`
  - `wain_app/admin_web_console/app/(protected)/admin/venues/page.tsx`
  - `wain_app/admin_web_console/components/venue-workspace/index.ts`
  - `wain_app/admin_web_console/components/venue-workspace/venue-workspace-shell.tsx`
  - `wain_app/admin_web_console/components/venue-workspace/venue-workspace-header.tsx`
  - `wain_app/admin_web_console/components/venue-workspace/venue-workspace-read-banner.tsx`
  - `wain_app/admin_web_console/lib/venues/index.ts`
  - `wain_app/admin_web_console/lib/venues/venue-workspace-models.ts`
  - `wain_app/admin_web_console/lib/venues/venue-workspace-read-types.ts`
  - `wain_app/admin_web_console/lib/venues/venue-workspace-read-loader.ts`
  - `wain_app/admin_web_console/lib/navigation/admin-route-map.ts`
  - `wain_app/admin_web_console/app/globals.css`
  - `wain_app/admin_web_console/lib/venues/venue-workspace-read-loader.test.ts`
  - `wain_app/admin_web_console/components/venue-workspace/venue-workspace-shell.test.tsx`
  - `wain_app/admin_web_console/components/venue-workspace/venue-workspace-route.test.tsx`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `wain_app/admin_web_console`: `npm test -- lib/venues/venue-workspace-read-loader.test.ts components/venue-workspace/venue-workspace-shell.test.tsx components/venue-workspace/venue-workspace-route.test.tsx` → `8/8` ناجحة.
  - `wain_app/admin_web_console`: `npm run build` → نجاح، والمسار الجديد `admin/venues/[venueId]` بُني بنجاح.
- Outcome Summary:
  - workspace shell أصبح موجودًا ومحمّيًا بـ route guard على نفس policy الخاصة بمسار `venues`.
  - tabs الأربعة الأساسية تعمل قراءة فقط مع منع أي mutation controls.
  - كل tab يعرض banner صريح لـ data source + asOf/fetchedAt + stale indicator.
  - header مرئي دائمًا مع اسم venue + readiness badge + wallet summary.
  - صفحة `admin/venues` أصبحت directory قراءة فقط مع روابط مباشرة إلى workspace.
- Constraints Check:
  - لا write actions
  - لا media ops (Phase 4)
  - لا moderation/actions (Phase 5)

### Entry 021

- Step ID: `AWC-P3-01A`
- Status: `done`
- Title: `Venue Directory implementation`
- Goal:
  - بدء Phase 3 بواجهة Venue Directory تشغيلية فعلية بدل placeholder.
  - توفير search/filter/read behavior فقط بدون أي أوامر كتابة.
  - إبراز readiness + wallet + merchant link summaries مع حالات read صريحة (`empty` / `unavailable` / `stale`).
- Files Updated:
  - `wain_app/admin_web_console/lib/venues/venue-directory-models.ts`
  - `wain_app/admin_web_console/lib/venues/venue-directory-read-types.ts`
  - `wain_app/admin_web_console/lib/venues/venue-directory-read-loader.ts`
  - `wain_app/admin_web_console/lib/venues/venue-directory-read-loader.test.ts`
  - `wain_app/admin_web_console/lib/venues/index.ts`
  - `wain_app/admin_web_console/components/venues/venue-directory-read-banner.tsx`
  - `wain_app/admin_web_console/components/venues/venue-directory-shell.tsx`
  - `wain_app/admin_web_console/components/venues/venue-directory-shell.test.tsx`
  - `wain_app/admin_web_console/components/venues/venue-directory-route.test.tsx`
  - `wain_app/admin_web_console/components/venues/index.ts`
  - `wain_app/admin_web_console/app/(protected)/admin/venues/page.tsx`
  - `wain_app/admin_web_console/lib/navigation/admin-route-map.ts`
  - `wain_app/admin_web_console/app/globals.css`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `wain_app/admin_web_console`: `npm test -- lib/venues/venue-directory-read-loader.test.ts components/venues/venue-directory-shell.test.tsx components/venues/venue-directory-route.test.tsx` → `10/10` ناجحة.
  - `wain_app/admin_web_console`: `npm run build` → نجاح، ومسار `admin/venues` أصبح surface تشغيليًا مع build نظيف.
- Outcome Summary:
  - تم استبدال الصفحة السابقة بواجهة directory قراءة فقط مع:
    - البحث باسم venue
    - city filter عند توفر البيانات
    - category filter عند توفر البيانات
    - readiness summary
    - wallet status summary
    - merchant link summary
  - تم اعتماد read loader بنمط source honesty (callable/snapshot/fixture) مع stale calculation واضح.
  - حالات `unavailable` و`empty` و`stale` أصبحت صريحة وقابلة للاختبار.
  - route access بقي role-safe عبر `requireRouteAccess("venues", "/admin/venues")` واختباره مضاف.
  - الصفحة جاهزة للربط والتنقل إلى workspace عبر روابط read-only.
- Constraints Check:
  - لا workspace tab implementation إضافي ضمن هذه الجولة
  - لا write actions
  - لا Phase 4/5 scope

### Entry 022

- Step ID: `AWC-P3-01M`
- Status: `done`
- Title: `Merge Venue Directory with Venue Workspace shell`
- Goal:
  - دمج مخرجات `AWC-P3-01A` و`AWC-P3-01B` على مستوى التنقل التشغيلي بين directory وworkspace.
  - تثبيت انتقال واضح من rows داخل directory إلى route الديناميكي `admin/venues/[venueId]`.
  - تأكيد اتساق read-only boundaries + tab state + read-state rendering عبر السطحين.
- Files Updated:
  - `wain_app/admin_web_console/components/venue-workspace/venue-workspace-header.tsx`
  - `wain_app/admin_web_console/components/venue-workspace/venue-workspace-shell.test.tsx`
  - `wain_app/admin_web_console/components/venues/venue-directory-shell.test.tsx`
  - `wain_app/admin_web_console/components/venues/venue-directory-route.test.tsx`
  - `wain_app/admin_web_console/app/globals.css`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `wain_app/admin_web_console`: `npm test -- lib/venues/venue-directory-read-loader.test.ts components/venues/venue-directory-shell.test.tsx components/venues/venue-directory-route.test.tsx lib/venues/venue-workspace-read-loader.test.ts components/venue-workspace/venue-workspace-shell.test.tsx components/venue-workspace/venue-workspace-route.test.tsx` → `19/19` ناجحة.
  - `wain_app/admin_web_console`: `npm run build` → نجاح، ومساري `admin/venues` و`admin/venues/[venueId]` بُنيا دون أخطاء.
- Outcome Summary:
  - روابط `Open workspace` داخل Venue Directory أصبحت مغطاة باختبارات صريحة للتحقق من href الصحيح لكل venue row.
  - workspace header أضيف له رابط رجوع مباشر إلى directory لتحسين دورة التنقل التشغيلية.
  - تم التحقق من أن directory بقي read-only وأن workspace route يحمّل venueId الصحيح مع استمرار tabs/read-state behavior.
  - الدمج `AWC-P3-01A` + `AWC-P3-01B` أصبح موثقًا كجولة مستقلة `AWC-P3-01M` بأدلة تحقق فعلية.
- Constraints Check:
  - لا write actions
  - لا Phase 4/5 scope
  - لا ادعاء إغلاق كامل لـ Phase 3

### Entry 023

- Step ID: `AWC-P3-02`
- Status: `done`
- Title: `Phase 3 hardening for live venue reads and source honesty`
- Goal:
  - إغلاق أهم فجوة تشغيلية متبقية في Phase 3 قبل الإقفال الرسمي.
  - جعل Venue Workspace تعتمد على surface backend حقيقية حيث تتوفر.
  - جعل Venue Directory صريحة حول scan budget/truncation بدل أي نجاح مبهم.
- Files Updated:
  - `wain_app/functions/src/index.ts`
  - `wain_app/functions/test/emulator/securityCallableFlows.test.js`
  - `wain_app/admin_web_console/lib/venues/venue-directory-models.ts`
  - `wain_app/admin_web_console/lib/venues/venue-directory-read-loader.ts`
  - `wain_app/admin_web_console/lib/venues/venue-workspace-read-loader.ts`
  - `wain_app/admin_web_console/lib/venues/venue-directory-read-loader.test.ts`
  - `wain_app/admin_web_console/lib/venues/venue-workspace-read-loader.test.ts`
  - `wain_app/admin_web_console/components/venues/venue-directory-shell.tsx`
  - `wain_app/admin_web_console/components/venues/venue-directory-shell.test.tsx`
  - `wain_app/admin_web_console/components/venues/venue-directory-route.test.tsx`
  - `wain_app/admin_web_console/app/globals.css`
  - `docs/release/admin_web_console_progress_tracker.md`
  - `README.md`
- Verification Evidence:
  - `wain_app/functions`: `npm run build` → نجاح.
  - `wain_app/functions`: `node --test --test-concurrency=1 --test-name-pattern="W45|W45b|W46|W53|W54" test\\emulator\\securityCallableFlows.test.js` → `5/5` ناجحة.
  - `wain_app/admin_web_console`: `npm test` → `108/108` ناجحة.
  - `wain_app/admin_web_console`: `npm run build` → نجاح.
- Outcome Summary:
  - أضيفت callable إدارية جديدة `getAdminVenueWorkspaceReadBundle` لمساحة venue workspace.
  - Venue Workspace أصبحت تفضّل backend callable الحقيقية عند توفر transport، وتعود إلى fixture فقط مع source labeling صريح.
  - Venue Directory أصبحت تعرض bounded scan budget وتعلن partial results عندما يُستنفد cursor budget داخل أحد الـ bounds.
  - لم تُفتح أي write actions جديدة، وبقيت الحدود read-only كما هي.
- Constraints Check:
  - لا Phase 4/5 scope
  - لا write actions
  - لا fallback مخفي يزعم live data بدون source honesty

### Entry 024

- Step ID: `AWC-P3-03`
- Status: `done`
- Title: `Phase 3 acceptance and closure record`
- Goal:
  - إغلاق Phase 3 رسميًا اعتمادًا على الأدلة الفعلية فقط.
  - منع أي مبالغة في إنهاء المرحلة قبل فتح Media Ops.
- Files Updated:
  - `docs/release/admin_web_console_phase3_acceptance_record.md`
  - `docs/release/admin_web_console_progress_tracker.md`
  - `README.md`
- Verification Evidence:
  - acceptance inputs reviewed:
    - `docs/release/admin_web_console_execution_plan.md`
    - `docs/release/admin_web_console_progress_tracker.md`
    - `admin_web_console` route/loader/component tests and build outputs
    - `functions` build + emulator subset evidence for `W53/W54`
  - evidence adopted into closure:
    - `functions` build success
    - emulator subset `5/5`
    - `admin_web_console` tests/build success
- Outcome Summary:
  - Phase 3 أغلقت كـ `accepted with follow-up` لا `done`.
  - السبب:
    - Venue Directory وVenue Workspace Core منجزتان ومثبتتان.
    - لكن directory ما زالت تعتمد bounded geo-search بدل admin read-model مخصص، وpagination التفاعلية ما زالت follow-up.
  - Phase 4 أصبحت `next`.
- Constraints Check:
  - لا Phase 4 implementation
  - لا fake completion
  - الحكم مبني على evidence فعلية فقط

### Entry 025

- Step ID: `AWC-P4-01A`
- Status: `done`
- Title: `Media read adapters and safety model baseline`
- Goal:
  - بدء Phase 4 بسطح Media Center read-only فعلي بدل fixture-only baseline.
  - ربط Media Center بـ backend callable read surface المتاحة فعليًا مع source honesty صريحة.
  - تثبيت safety/freshness model واضح قبل أي soft delete/quarantine/purge workflows.
- Files Updated:
  - `wain_app/functions/src/index.ts`
  - `wain_app/functions/test/emulator/securityCallableFlows.test.js`
  - `wain_app/admin_web_console/lib/media/media-center-baseline.ts`
  - `wain_app/admin_web_console/lib/media/index.ts`
  - `wain_app/admin_web_console/lib/media/media-center-baseline.test.ts`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `wain_app/functions`: `npm run build` → نجاح.
  - `wain_app/functions`: `node --test --test-concurrency=1 --test-name-pattern="W55|W56" test\\emulator\\securityCallableFlows.test.js` → `2/2` ناجحة.
  - `wain_app/functions`: `node --test --test-concurrency=1 test\\emulator\\securityCallableFlows.test.js` → `83/83` ناجحة.
  - `wain_app/admin_web_console`: `npm test -- lib/media/media-center-baseline.test.ts components/media/media-center-shell.test.tsx components/media/media-center-route.test.tsx` → `12/12` ناجحة.
  - `wain_app/admin_web_console`: `npm run build` → نجاح.
- Outcome Summary:
  - تمت إضافة emulator coverage للـ callable `getAdminMediaInventoryReadBundle` مع حالتي admin success وnon-admin denial.
  - تم إصلاح مسار health document في backend من id محجوز (`__health__`) إلى `media_reference_index/health` المتوافق مع Firestore.
  - loader الخاص بـ Media Center أصبح callable-backed ويحوّل البيانات إلى read sections بحالات صريحة: `success`/`empty`/`stale`/`unavailable`.
  - malformed rows/payloads لم تعد تمر كنجاح مضلل؛ يتم إسقاطها مع fallback state صريح إلى `unavailable` عندما يلزم.
  - source/freshness/reference-safety أصبحت معروضة بوضوح داخل baseline model بدون ادعاء live data عند فشل المصدر.
- Constraints Check:
  - لا write/delete/purge actions
  - لا moderation workflows
  - لا fallback مخفي يزعم live data

### Entry 026

- Step ID: `AWC-P4-01B`
- Status: `done`
- Title: `Media Center read-only UI baseline`
- Goal:
  - استبدال placeholder السابق بواجهة Media Center تشغيلية read-only.
  - إبراز sections الأساسية (`proofs`, `venue photos`, `offer images`, `story images`) مع فلاتر وحالات تشغيلية صريحة.
  - إبقاء كل destructive/media governance actions خارج النطاق.
- Files Updated:
  - `wain_app/admin_web_console/lib/navigation/admin-contract.ts`
  - `wain_app/admin_web_console/lib/navigation/admin-route-map.ts`
  - `wain_app/admin_web_console/lib/auth/guard-api.ts`
  - `wain_app/admin_web_console/lib/auth/guard-api.test.ts`
  - `wain_app/admin_web_console/lib/auth/rbac-shell.integration.test.ts`
  - `wain_app/admin_web_console/lib/media/media-center-models.ts`
  - `wain_app/admin_web_console/components/media/index.ts`
  - `wain_app/admin_web_console/components/media/media-center-shell.tsx`
  - `wain_app/admin_web_console/components/media/media-center-shell.test.tsx`
  - `wain_app/admin_web_console/components/media/media-center-route.test.tsx`
  - `wain_app/admin_web_console/app/(protected)/admin/media/page.tsx`
  - `wain_app/admin_web_console/app/globals.css`
  - `README.md`
- Verification Evidence:
  - `wain_app/admin_web_console`: `npm test` → `115/115` ناجحة.
  - `wain_app/admin_web_console`: `npm run build` → نجاح، ومسار `admin/media` بُني بنجاح.
- Outcome Summary:
  - أضيف route إداري حقيقي لـ Media Center داخل shell الحالية.
  - الواجهة تعرض tabs تشغيلية + فلاتر `search / venue / reference safety`.
  - الحالات `stale` و`empty` و`unavailable` أصبحت مرئية للمشغّل بدل placeholder عام.
  - لا يوجد أي delete/quarantine/purge/replace controls في هذه الجولة.
- Constraints Check:
  - لا write actions
  - لا quarantine/purge workflows
  - لا Phase 5 moderation work

### Entry 027

- Step ID: `AWC-P4-01M`
- Status: `done`
- Title: `Merge Media read layer with Media Center baseline`
- Goal:
  - توثيق وتثبيت الدمج بين Media Center UI وcallable-backed media read layer.
  - إعادة التحقق أن source honesty وreference safety وread-only boundaries ما زالت متسقة بعد الدمج.
- Files Updated:
  - `docs/release/admin_web_console_progress_tracker.md`
  - `README.md`
- Verification Evidence:
  - `wain_app/functions`: `npm run build` → نجاح.
  - `wain_app/functions`: `node --test --test-concurrency=1 --test-name-pattern="W55|W56" test\\emulator\\securityCallableFlows.test.js` → `2/2` ناجحة.
  - `wain_app/admin_web_console`: `npm test` → `115/115` ناجحة.
  - `wain_app/admin_web_console`: `npm run build` → نجاح.
- Outcome Summary:
  - لم تحتج جولة الدمج إلى patch إضافي على كود التطبيق؛ صفحة `/admin/media` كانت تستخدم `loadMediaCenterBaseline()` callable-backed بالفعل بعد `P4-01A`.
  - تم تثبيت أن Media Center تعرض source/freshness/reference-safety من loader الحقيقي، وليس من fixture-only fallback.
  - بقيت boundary واضحة:
    - لا delete actions
    - لا quarantine workflow
    - لا purge path
  - Phase 4 بقيت `in_progress` لأن media governance actions نفسها لم تُنفذ بعد.
- Constraints Check:
  - لا Phase 5 work
  - لا fake completion
  - لا destructive actions

### Entry 028

- Step ID: `AWC-P4-02A`
- Status: `done`
- Title: `Governed media action contracts and server-authorized workflows`
- Goal:
  - فتح Phase 4 media actions على الخادم فقط عبر callables محكومة.
  - تفعيل:
    - `media_soft_delete`
    - `media_quarantine`
    - `media_reference_check`
    - `media_purge`
  - فرض audit + reference-index health gating قبل أي purge فعلي.
- Files Updated:
  - `wain_app/functions/src/index.ts`
  - `wain_app/functions/test/emulator/securityCallableFlows.test.js`
  - `wain_app/admin_web_console/lib/media/media-command-contracts.ts`
  - `wain_app/admin_web_console/lib/media/media-command-adapters.ts`
  - `wain_app/admin_web_console/lib/media/default-media-command-transport.ts`
  - `wain_app/admin_web_console/lib/media/media-command-adapters.test.ts`
- Verification Evidence:
  - `wain_app/functions`: `npm run build` → نجاح.
  - `wain_app/functions`: `node --test --test-concurrency=1 --test-name-pattern="W55|W56|W57|W58|W59|W60" test\\emulator\\securityCallableFlows.test.js` → `6/6` ناجحة.
  - `wain_app/admin_web_console`: media command adapter tests مضمنة ضمن `npm test`.
- Outcome Summary:
  - backend يحتوي الآن media callables محكومة ومباشرة:
    - `getAdminMediaInventoryReadBundle`
    - `mediaSoftDeleteAsset`
    - `mediaQuarantineAsset`
    - `mediaReferenceCheckAsset`
    - `mediaPurgeAsset`
  - كل action تعيد `auditEventId` واضحًا.
  - `purge` تُرفض صراحة عندما تكون `media_reference_index` غير صحية أو غير محدثة.
  - transport الافتراضي في الويب أصبح env-aware ويستخدم callable-backed adapters عند توفر env بدلاً من unavailable mock فقط.
- Constraints Check:
  - لا client-side destructive writes
  - لا bypass للـ policy
  - purge gating موجودة على الخادم نفسه

### Entry 029

- Step ID: `AWC-P4-02B`
- Status: `done`
- Title: `Media Center governed action surfaces and operator UX`
- Goal:
  - ترقية Media Center من read-only baseline إلى operator UX محكومة.
  - إظهار action affordances فقط عندما يسمح الدور والسياسة بذلك.
  - إبقاء حالات الفشل/المنع/التعارض صريحة.
- Files Updated:
  - `wain_app/admin_web_console/lib/navigation/admin-contract.ts`
  - `wain_app/admin_web_console/lib/navigation/admin-route-map.ts`
  - `wain_app/admin_web_console/lib/auth/guard-api.ts`
  - `wain_app/admin_web_console/lib/auth/guard-api.test.ts`
  - `wain_app/admin_web_console/lib/auth/rbac-shell.integration.test.ts`
  - `wain_app/admin_web_console/lib/media/media-center-models.ts`
  - `wain_app/admin_web_console/lib/media/media-center-baseline.ts`
  - `wain_app/admin_web_console/lib/media/media-command-policy.ts`
  - `wain_app/admin_web_console/lib/media/media-command-transport.ts`
  - `wain_app/admin_web_console/lib/media/media-command-client.ts`
  - `wain_app/admin_web_console/lib/media/build-media-command-requests.ts`
  - `wain_app/admin_web_console/lib/media/media-surface-affordances.ts`
  - `wain_app/admin_web_console/components/media/media-command-provider.tsx`
  - `wain_app/admin_web_console/components/media/media-center-shell.tsx`
  - `wain_app/admin_web_console/components/media/media-center-shell.test.tsx`
  - `wain_app/admin_web_console/components/media/media-center-route.test.tsx`
  - `wain_app/admin_web_console/app/(protected)/admin/media/page.tsx`
  - `wain_app/admin_web_console/app/globals.css`
  - `README.md`
- Verification Evidence:
  - `wain_app/admin_web_console`: `npm test` → `133/133` ناجحة.
  - `wain_app/admin_web_console`: `npm run build` → نجاح.
- Outcome Summary:
  - `content_admin` و`super_admin` يرون actions المحكومة فقط.
  - `ops_viewer` و`support_admin` يبقون read-only بالكامل.
  - `pending`/`success`/`conflict`/`unavailable`/`blocked` تظهر للمشغل بوضوح.
  - `purge` تُحجب أو تُعطل عندما تكون `referenceIndexHealth` غير `healthy` أو عندما لا تكون `referenceSafety` آمنة.
- Constraints Check:
  - لا fake success عند غياب transport
  - لا destructive action تظهر لأدوار القراءة فقط
  - لا Phase 5 moderation work

### Entry 030

- Step ID: `AWC-P4-02M`
- Status: `done`
- Title: `Merge governed media actions with Media Center`
- Goal:
  - تثبيت أن backend governance وUI affordances يعملان معًا بدون تناقض.
  - التحقق أن destructive actions تبقى server-authorized only.
- Files Updated:
  - `docs/release/admin_web_console_progress_tracker.md`
  - `README.md`
- Verification Evidence:
  - `wain_app/functions`: `npm run build` → نجاح.
  - `wain_app/functions`: `node --test --test-concurrency=1 --test-name-pattern="W55|W56|W57|W58|W59|W60" test\\emulator\\securityCallableFlows.test.js` → `6/6` ناجحة.
  - `wain_app/admin_web_console`: `npm test` → `133/133` ناجحة.
  - `wain_app/admin_web_console`: `npm run build` → نجاح.
- Outcome Summary:
  - Media Center أصبحت تستهلك command/provider/runtime-state layer موحدة فوق callable transport حقيقي عندما تتوفر env.
  - backend governance وUI role gating متسقان:
    - destructive actions لا تظهر لغير المصرح لهم
    - purge تظل blocked عندما يكون `media_reference_index` غير صحي
    - reference-check تُعاد بعقد صريح يمكن عرضه للمشغل
  - لم يحتج الدمج إلى تغييرات backend إضافية؛ الفجوة كانت توثيقية/تنسيقية أكثر من كونها منطقية.
- Constraints Check:
  - لا bypass للـ server authorization
  - لا fake completion
  - لا Phase 5 work

### Entry 031

- Step ID: `AWC-P4-03`
- Status: `done`
- Title: `Phase 4 acceptance and closure record`
- Goal:
  - إقفال Phase 4 رسميًا بعد ثبوت inventory + governed media actions.
  - توثيق الحكم النهائي والفجوات غير الحاجزة بدل ترك المرحلة `in_progress`.
- Files Updated:
  - `docs/release/admin_web_console_phase4_acceptance_record.md` (new)
  - `docs/release/admin_web_console_progress_tracker.md`
  - `README.md`
- Verification Evidence:
  - يعتمد هذا الإقفال على evidence الموثقة في `AWC-P4-01A/B/M` و`AWC-P4-02A/B/M`.
  - آخر evidence معتمدة:
    - `wain_app/functions`: build ناجح
    - media emulator subset `W55-W60` → `6/6`
    - `wain_app/admin_web_console`: `npm test` → `133/133`
    - `wain_app/admin_web_console`: `npm run build` → نجاح
- Outcome Summary:
  - Phase 4 أُغلقت كـ `accepted with follow-up`.
  - الأسطح الجوهرية منجزة:
    - inventory read layer
    - Media Center UI
    - governed media actions
    - purge gating by `media_reference_index`
  - الفجوات المتبقية صريحة وغير مخفية داخل claims إغلاق.
- Constraints Check:
  - لا Phase 5 implementation في هذه الجولة
  - لا مبالغة في الإغلاق
  - الحكم مبني على evidence فعلية فقط

### Entry 032

- Step ID: `AWC-P5-01A-R2`
- Status: `done`
- Title: `Make Offers/Stories operational from admin web`
- Goal:
  - تحويل Offers/Stories من baseline snapshots فقط إلى surfaces تشغيلية فعلية من الويب الإداري.
  - إبقاء protected derived fields (`isFeatured`, `featuredUntil`, `isPromoted`, `promotedUntil`) خارج أي كتابة مباشرة من المتصفح.
  - تثبيت أن loader/transport/backend replay semantics متوافقة قبل أي merge لمرحلة المحتوى.
- Files Updated:
  - `wain_app/admin_web_console/lib/navigation/admin-contract.ts`
  - `wain_app/admin_web_console/lib/navigation/admin-route-map.ts`
  - `wain_app/admin_web_console/lib/auth/guard-api.ts`
  - `wain_app/admin_web_console/lib/auth/guard-api.test.ts`
  - `wain_app/admin_web_console/lib/content/content-callable-env.ts`
  - `wain_app/admin_web_console/lib/content/content-command-client.ts`
  - `wain_app/admin_web_console/lib/content/content-command-adapters.ts`
  - `wain_app/admin_web_console/lib/content/default-content-command-transport.ts`
  - `wain_app/admin_web_console/lib/content/content-read-loader.ts`
  - `wain_app/admin_web_console/lib/content/content-read-loader.test.ts`
  - `wain_app/admin_web_console/lib/content/build-content-command-requests.ts`
  - `wain_app/admin_web_console/components/content/content-command-provider.tsx`
  - `wain_app/admin_web_console/components/content/content-action-cell.tsx`
  - `wain_app/admin_web_console/components/content/offers-management-shell.tsx`
  - `wain_app/admin_web_console/components/content/stories-management-shell.tsx`
  - `wain_app/admin_web_console/components/content/content-management-shells.test.tsx`
  - `wain_app/admin_web_console/components/content/content-management-routes.test.tsx`
  - `wain_app/admin_web_console/app/(protected)/admin/content/offers/page.tsx`
  - `wain_app/admin_web_console/app/(protected)/admin/content/stories/page.tsx`
  - `wain_app/functions/src/index.ts`
  - `wain_app/functions/test/emulator/contentModerationCallableFlows.test.js`
  - `README.md`
- Verification Evidence:
  - `wain_app/admin_web_console`: `npm test` → `205/205` ناجحة.
  - `wain_app/admin_web_console`: `npm run build` → نجاح.
  - `wain_app/functions`: `npm run build` → نجاح.
  - `wain_app/functions`: `firebase --config ../firebase.json emulators:exec --project demo-wain-analytics --only firestore "node --test --test-concurrency=1 test/emulator/contentModerationCallableFlows.test.js"` → `10/10` ناجحة.
- Outcome Summary:
  - Offers/Stories routes أصبحت تستخدم route keys حقيقية (`content_offers` / `content_stories`) بدل route guard عام أو placeholder.
  - loaders أصبحت callable-backed:
    - `listOffersForAdmin`
    - `listStoriesForAdmin`
  - content moderation transport الافتراضية أصبحت env-aware وتستخدم adapters حقيقية عندما تكون env موجودة، بدل `unavailable` ثابت دائمًا.
  - unauthorized/forbidden loader failures لم تعد تسقط بصمت إلى fixture data؛ فقط retryable transport failures يمكن أن تعود إلى fixture fallback مع source labeling صريح.
  - replay/idempotency في backend أصبحت مستقرة؛ إعادة نفس command لم تعد تتصادم بسبب `submittedAt`.
  - shell/route coverage أصبحت موجودة فعليًا لـ offers/stories بدل الاعتماد على reviews فقط.
- Constraints Check:
  - لا كتابة مباشرة من المتصفح للحقول المشتقة المحمية
  - لا bypass للـ server-authorized moderation
  - لم تُغلق Phase 5 بعد؛ ما زال يلزم `AWC-P5-01M`

### Entry 033

- Step ID: `AWC-P5-01B`
- Status: `done`
- Title: `Reviews moderation baseline`
- Goal:
  - تثبيت Reviews Moderation كسطح governed منفصل داخل Phase 5.
  - إبقاء الطلبات audit-safe وrole-gated مع runtime states صريحة.
- Files Updated:
  - `wain_app/admin_web_console/lib/navigation/admin-contract.ts`
  - `wain_app/admin_web_console/lib/navigation/admin-route-map.ts`
  - `wain_app/admin_web_console/lib/auth/guard-api.ts`
  - `wain_app/admin_web_console/lib/reviews/review-moderation-contracts.ts`
  - `wain_app/admin_web_console/lib/reviews/review-moderation-policy.ts`
  - `wain_app/admin_web_console/lib/reviews/review-moderation-adapters.ts`
  - `wain_app/admin_web_console/lib/reviews/default-review-moderation-transport.ts`
  - `wain_app/admin_web_console/lib/reviews/review-moderation-loader.ts`
  - `wain_app/admin_web_console/lib/reviews/build-review-command-requests.ts`
  - `wain_app/admin_web_console/lib/reviews/review-surface-affordances.ts`
  - `wain_app/admin_web_console/components/reviews/review-command-provider.tsx`
  - `wain_app/admin_web_console/components/reviews/review-action-cell.tsx`
  - `wain_app/admin_web_console/components/reviews/review-moderation-shell.tsx`
  - `wain_app/admin_web_console/components/reviews/review-moderation-shell.test.tsx`
  - `wain_app/admin_web_console/components/reviews/review-moderation-route.test.tsx`
  - `wain_app/admin_web_console/app/(protected)/admin/content/reviews/page.tsx`
  - `wain_app/functions/src/index.ts`
  - `wain_app/functions/test/emulator/securityCallableFlows.test.js`
- Verification Evidence:
  - `wain_app/functions`: `npm run build` → نجاح.
  - `wain_app/functions`: emulator subset `W61-W65` → `5/5` ناجحة.
  - `wain_app/admin_web_console`: `npm test` → جزء من التشغيل الموحد الحالي `205/205` ناجحة، ويشمل:
    - `components/reviews/review-moderation-shell.test.tsx`
    - `components/reviews/review-moderation-route.test.tsx`
    - `lib/reviews/review-moderation-adapters.test.ts`
    - `lib/reviews/build-review-command-requests.test.ts`
    - `lib/reviews/review-surface-affordances.test.ts`
  - `wain_app/admin_web_console`: `npm run build` → نجاح.
- Outcome Summary:
  - Reviews Moderation تعمل عبر callable read/action boundaries حقيقية:
    - `listVenueReviewsForAdmin`
    - `moderateVenueReviewForAdmin`
  - الأفعال `review_publish` / `review_hide` / `review_escalate` بقيت role-gated وصريحة في الواجهة.
  - expected_state conflict وidempotent replay مثبتان backend واختبارات الويب تغطي runtime states.
- Constraints Check:
  - لا silent moderation writes
  - لا bypass للتفويض الخادمي
  - لا Phase 6 work

### Entry 034

- Step ID: `AWC-P5-01M`
- Status: `done`
- Title: `Merge Content Ops baseline`
- Goal:
  - دمج Offers/Stories التشغيلية مع Reviews Moderation داخل baseline موحد لـ Phase 5.
  - تحديث السجل بناءً على evidence موحدة فقط.
- Files Updated:
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `wain_app/admin_web_console`: `npm test` → `205/205` ناجحة.
  - `wain_app/admin_web_console`: `npm run build` → نجاح.
  - `wain_app/functions`: `npm run build` → نجاح.
  - `wain_app/functions`: `firebase --config ../firebase.json emulators:exec --project demo-wain-analytics --only firestore "node --test --test-concurrency=1 test/emulator/contentModerationCallableFlows.test.js; node --test --test-concurrency=1 --test-name-pattern=\"W61|W62|W63|W64|W65\" test/emulator/securityCallableFlows.test.js"` → `92/92` ناجحة.
- Outcome Summary:
  - مسارات `offers`, `stories`, و`reviews` أصبحت متماسكة تحت Content Ops route map واحد.
  - moderation reasons والـ command envelopes بقيت صريحة ومختبرة لكل سطح بدون أي كتابة مباشرة للحقول المحمية من المتصفح.
  - الويب والـ functions يقدمان baseline موحدًا قابلًا للإقفال الرسمي للمرحلة.
- Constraints Check:
  - لا مبالغة في الادعاء؛ الدمج مبني على evidence حديثة فقط
  - لا Phase 6 implementation

### Entry 035

- Step ID: `AWC-P5-02`
- Status: `done`
- Title: `Phase 5 acceptance and closure record`
- Goal:
  - إقفال Phase 5 رسميًا بعد ثبوت أن Offers/Stories/Reviews تعمل ضمن Content Ops baseline واحد.
  - تسجيل الحكم النهائي والفجوات غير الحاجزة بدل إبقاء المرحلة `in_progress`.
- Files Updated:
  - `docs/release/admin_web_console_phase5_acceptance_record.md` (new)
  - `docs/release/admin_web_console_progress_tracker.md`
  - `README.md`
- Verification Evidence:
  - يعتمد هذا الإقفال على evidence الموثقة في `AWC-P5-01A-R2` و`AWC-P5-01B` و`AWC-P5-01M`.
  - آخر evidence معتمدة:
    - `wain_app/functions`: `npm run build` → نجاح
    - `wain_app/functions`: content + review emulator flows → `92/92`
    - `wain_app/admin_web_console`: `npm test` → `205/205`
    - `wain_app/admin_web_console`: `npm run build` → نجاح
- Outcome Summary:
  - Phase 5 أُغلقت كـ `accepted with follow-up`.
  - الأسطح الجوهرية منجزة:
    - Offers Management
    - Stories Management
    - Reviews Moderation
  - معايير القبول الثلاثة للمرحلة مثبتة:
    - standardized moderation reasons
    - role-gated actions
    - protected derived fields ليست writable من المتصفح
- Constraints Check:
  - لا Phase 6 implementation في هذه الجولة
  - لا مبالغة في الإغلاق
  - الحكم مبني على evidence فعلية فقط

### Entry 036

- Step ID: `AWC-P6-01B`
- Status: `done`
- Title: `Config governance baseline`
- Goal:
  - تنفيذ baseline حوكمة إعدادات Phase 6 عبر سير draft/review/publish/rollback/history بدون أي bypass من المتصفح.
  - فرض authorization خادمي صارم + validation صارمة + expected-state checks + idempotent replay.
  - توصيل واجهة `/admin/config` بعقود command/read صريحة مع runtime states واضحة للمشغل.
- Files Updated:
  - `wain_app/functions/src/index.ts`
  - `wain_app/functions/test/emulator/securityCallableFlows.test.js`
  - `wain_app/admin_web_console/lib/config/config-governance-models.ts`
  - `wain_app/admin_web_console/lib/config/config-command-contracts.ts`
  - `wain_app/admin_web_console/lib/config/config-command-policy.ts`
  - `wain_app/admin_web_console/lib/config/config-command-transport.ts`
  - `wain_app/admin_web_console/lib/config/config-callable-env.ts`
  - `wain_app/admin_web_console/lib/config/config-command-adapters.ts`
  - `wain_app/admin_web_console/lib/config/config-command-client.ts`
  - `wain_app/admin_web_console/lib/config/default-config-command-transport.ts`
  - `wain_app/admin_web_console/lib/config/build-config-command-requests.ts`
  - `wain_app/admin_web_console/lib/config/config-surface-affordances.ts`
  - `wain_app/admin_web_console/lib/config/config-read-loader.ts`
  - `wain_app/admin_web_console/lib/config/index.ts`
  - `wain_app/admin_web_console/components/config/config-command-provider.tsx`
  - `wain_app/admin_web_console/components/config/config-governance-shell.tsx`
  - `wain_app/admin_web_console/components/config/config-governance-shell.test.tsx`
  - `wain_app/admin_web_console/components/config/config-governance-route.test.tsx`
  - `wain_app/admin_web_console/components/config/index.ts`
  - `wain_app/admin_web_console/app/(protected)/admin/config/page.tsx`
  - `wain_app/admin_web_console/lib/navigation/admin-contract.ts`
  - `wain_app/admin_web_console/lib/navigation/admin-route-map.ts`
  - `wain_app/admin_web_console/lib/auth/guard-api.ts`
  - `wain_app/admin_web_console/lib/auth/guard-api.test.ts`
  - `wain_app/admin_web_console/lib/auth/rbac-shell.integration.test.ts`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `wain_app/admin_web_console`: `npm run test -- components/config/config-governance-shell.test.tsx components/config/config-governance-route.test.tsx lib/auth/guard-api.test.ts lib/auth/rbac-shell.integration.test.ts` → `23/23` ناجحة.
  - `wain_app/admin_web_console`: `npm run build` → نجاح.
  - `wain_app/functions`: `npm run build` → نجاح.
  - `wain_app/functions`: `firebase --config ../firebase.json emulators:exec --project demo-wain-analytics --only firestore "node --test --test-concurrency=1 test/emulator/securityCallableFlows.test.js"` → `97/97` ناجحة (وتشمل `W66`-`W70`).
- Outcome Summary:
  - backend أضاف callables governance فعلية:
    - `getAdminConfigGovernanceBundle`
    - `configUpsertDraft`
    - `configReviewDraft`
    - `configPublishDraft`
    - `configRollbackVersion`
  - نشر الإعدادات أصبح audited مع publish/rollback history صريح، وفصل actor reviewer/publisher مدعوم ضمن publish guard.
  - الواجهة المحمية `/admin/config` أصبحت callable-backed مع runtime states تشغيلية (`pending`/`success`/`conflict`/`unavailable`/`blocked`) بدل أي نجاح وهمي.
  - RBAC/navigation contracts توسعت بقدرات Phase 6 config governance مع اختبارات route guard متوافقة.
- Constraints Check:
  - لا direct writes من المتصفح إلى config state الحرج
  - لا bypass للتفويض الخادمي أو App Check enforcement
  - لا إعلان إغلاق Phase 6 بعد؛ مسار dashboard/KPI ما زال مفتوحًا

### Entry 037

- Step ID: `AWC-P6-01A`
- Status: `done`
- Title: `Operational dashboard baseline`
- Goal:
  - تنفيذ dashboard lightweight مع KPI widgets تشغيلية (Top-Up Queue, Content Moderation, Wallet Readiness, Venue Readiness).
  - الاعتماد على read models قائمة واستخدام `Promise.allSettled` لتجنب تعطل اللوحة بالكامل.
  - الحفاظ على حوكمة role-gating وread-state honesty مع إظهار `stale` و `unavailable` بصراحة.
- Files Updated:
  - `admin_web_console/lib/dashboard/dashboard-models.ts`
  - `admin_web_console/lib/dashboard/dashboard-loader.ts`
  - `admin_web_console/lib/dashboard/dashboard-loader.test.ts`
  - `admin_web_console/components/dashboard/kpi-widget.tsx`
  - `admin_web_console/components/dashboard/operational-dashboard-shell.tsx`
  - `admin_web_console/components/dashboard/operational-dashboard-shell.test.tsx`
  - `admin_web_console/app/(protected)/admin/dashboard/page.tsx`
- Verification Evidence:
  - `npm test`: `211/211` passed prior to merge.
  - `npm run build`: success.
- Outcome Summary:
  - اللوحة مُحدّثة بشكل حقيقي وتستخدم loaders موازية بدون إدخال ad-hoc querying معقد.
  - التعامل مع أخطاء الـ transport يتم بشكل Graceful-degrade على مستوى كل Widget عبر مؤشرات UI صريحة.
- Constraints Check:
  - لا كتابة المتصفح المباشرة.
  - لا مقاييس مخترعة.

### Entry 038

- Step ID: `AWC-P6-01M`
- Status: `done`
- Title: `Merge dashboard baseline with config governance baseline`
- Goal:
  - دمج مخرجات AWC-P6-01A (اللوحة) مع AWC-P6-01B (الحوكمة).
  - إثبات عمل analytics reads بجانب config publish flows دون تضارب أو اختراق roles.
- Files Updated:
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `wain_app/admin_web_console`: `npm test` → `219/219` ناجحة.
  - `wain_app/admin_web_console`: `npm run build` → نجاح.
  - `wain_app/functions`: `npm run build` → نجاح.
- Outcome Summary:
  - مسارات analytics (القارئة) و config (الحاكمة للتحديثات) تتعايش بسلام في نفس الكونسول.
  - تم ضمان Role-safe constraints عبر كلا القسمين ولم تضطرب التوجيهات أو المكونات نتيجة للدمج.
- Constraints Check:
  - لا Phase 7 implementation في هذه الجولة.
  - لا مخارج وهمية.

### Entry 039

- Step ID: `AWC-P6-02`
- Status: `done`
- Title: `Phase 6 acceptance and closure record`
- Goal:
  - إقفال Phase 6 رسميًا بعد ثبوت أن dashboard baseline وconfig governance baseline تعملان معًا.
  - تسجيل الحكم النهائي والفجوات غير الحاجزة بدل إبقاء المرحلة `in_progress`.
- Files Updated:
  - `docs/release/admin_web_console_phase6_acceptance_record.md` (new)
  - `docs/release/admin_web_console_progress_tracker.md`
  - `README.md`
- Verification Evidence:
  - يعتمد هذا الإقفال على evidence الموثقة في `AWC-P6-01A` و`AWC-P6-01B` و`AWC-P6-01M`.
  - آخر evidence معتمدة في هذه الجولة:
    - `wain_app/admin_web_console`: `npm test` → `219/219`
    - `wain_app/admin_web_console`: `npm run build` → نجاح
    - `wain_app/functions`: `npm run build` → نجاح
    - `wain_app/functions`: emulator subset `W66-W70` → `5/5`
- Outcome Summary:
  - Phase 6 أُغلقت كـ `accepted with follow-up`.
  - معايير القبول المثبتة:
    - dashboard خفيفة ووظيفية
    - config validation صارمة
    - publish/rollback audited
  - الفجوات المتبقية صريحة وغير مخفية داخل claims الإغلاق.
- Constraints Check:
  - لا Phase 7 implementation في هذه الجولة
  - لا مبالغة في الإغلاق
  - الحكم مبني على evidence فعلية فقط

### Entry 040

- Step ID: `AWC-P7-01`
- Status: `done`
- Title: `Hardening and release gate baseline`
- Goal:
  - توحيد hardening evidence عبر end-to-end checks وconcurrency coverage الأساسية.
  - إثبات عدم وجود duplicate processing أو hidden direct writes في المسارات الحساسة.
  - تجهيز release/operator checklist وrunbook وincident drill review قبل أي go-live claim.
- Files Updated:
  - `docs/release/admin_web_console_release_checklist.md` (new)
  - `docs/release/admin_web_console_release_runbook.md` (new)
  - `docs/release/admin_web_console_incident_drill_review.md` (new)
  - `docs/release/admin_web_console_progress_tracker.md`
  - `README.md`
- Verification Evidence:
  - `wain_app/admin_web_console`: `npm test` -> `219/219`
  - `wain_app/admin_web_console`: `npm run build` -> نجاح
  - `wain_app/functions`: `npm run build` -> نجاح
  - `wain_app/functions`: `securityConcurrencyFlows.test.js` -> `4/4`
  - `wain_app/functions`: `securityCallableFlows.test.js` -> `97/97`
  - `wain_app/functions`: `contentModerationCallableFlows.test.js` -> `10/10`
  - direct-write source audit over `admin_web_console` returned no app-source usage of:
    - `setDoc`
    - `updateDoc`
    - `addDoc`
    - `deleteDoc`
    - `writeBatch`
    - `runTransaction`
    - `getFirestore`
- Outcome Summary:
  - تم إنشاء operator release checklist تفصل pass/pending gates بدل أي ادعاء go-live مبهم.
  - تم إنشاء runbook تشغيلية قابلة للاستخدام تحت الضغط وتربط transport prerequisites والتحقق والترجيع وownership.
  - تم إنشاء incident drill review يوثق ما الذي ثبت فعليًا عبر concurrency/callable suites وما الذي ما يزال يحتاج staging rehearsal حيّة.
  - Phase 7 دخلت `in_progress` لأن hardening baseline أصبحت موثقة، لكن go-live ما زال محجوبًا لحين live staging smoke لسطوح config/media/content.
- Constraints Check:
  - لا إعلان go-live أو Phase 7 closure في هذه الجولة
  - لا إخفاء للفجوات التشغيلية الحقيقية
  - الحكم مبني على evidence فعلية فقط

### Entry 041

- Step ID: `AWC-P7-02`
- Status: `done`
- Title: `Staging rehearsal and Phase 7 acceptance`
- Goal:
  - تشغيل staging rehearsal حيّة ومثبتة لسطوح config/media/content/reviews على المشروع `wain-d2e28`.
  - تحويل hardening baseline إلى closure auditable لPhase 7 بدون الادعاء الخاطئ بأن go-live أصبحت جاهزة.
  - توثيق الفجوات التشغيلية المتبقية بصيغة release follow-up واضحة.
- Files Updated:
  - `functions/scripts/run_admin_web_staging_rehearsal.js` (new)
  - `functions/package.json`
  - `firestore.indexes.json`
  - `docs/release/admin_web_console_staging_evidence_log.json` (new)
  - `docs/release/admin_web_console_staging_evidence_log.md` (new)
  - `docs/release/admin_web_console_phase7_acceptance_record.md` (new)
  - `docs/release/admin_web_console_release_checklist.md`
  - `docs/release/admin_web_console_release_runbook.md`
  - `docs/release/admin_web_console_progress_tracker.md`
  - `README.md`
- Verification Evidence:
  - `wain_app/functions`: `npm run build` -> نجاح
  - `wain_app/functions`: `npm run admin-web:staging-rehearsal` -> نجاح
    - artifact: `docs/release/admin_web_console_staging_evidence_log.json`
    - project: `wain-d2e28`
  - `wain_app`: `firebase deploy --only firestore:indexes --project wain-d2e28` -> نجاح
    - تم إنشاء index جديدة: `offers(venue_id ASC, created_at DESC)`
  - venue-filtered media verification after index deploy:
    - النتيجة: ما زالت `building` وقت التحقق
  - `wain_app/admin_web_console`: `npm test` -> `219/219`
  - `wain_app/admin_web_console`: `npm run build` -> نجاح
- Outcome Summary:
  - تم تنفيذ rehearsal حيّة على المشروع الفعلي لسطوح:
    - config publish/rollback
    - offers/stories moderation
    - reviews moderation
    - media reference-check / soft-delete / quarantine / purge-blocked path
  - تم إثبات denial/conflict paths الحرجة:
    - same-actor config publish blocked
    - finance role denied for content/reviews moderation
    - media purge blocked عند index health غير صحية
  - تم إنشاء سجل evidence خام + ملخص بشري + سجل قبول Phase 7.
  - Phase 7 أُغلقت كـ `accepted with follow-up` لأن browser HTTP callable transport smoke ما زالت غير موثقة، ولأن media inventory المفلترة كانت تنتظر جاهزية الـ index الجديدة وقت التحقق.
- Constraints Check:
  - لا إعلان go-live في هذه الجولة
  - لا إخفاء للفارق بين live Firestore callable rehearsal وبين browser HTTP transport smoke
  - الحكم مبني على evidence فعلية فقط

### Entry 042

- Step ID: `AWC-P7-F01B`
- Status: `done`
- Title: `Browser HTTP smoke - media transport blocked`
- Goal:
  - تنفيذ browser HTTP transport smoke فعلي لسطح `/admin/media` باستخدام auth/app-check حقيقيين من staging.
  - إثبات وضع unfiltered media read وvenue-filtered readiness بدون خلط مع local callable rehearsal.
  - التحقق من availability الخاصة بـ `Reference check` و`Purge` على واجهة media تحت transport حيّة.
- Files Updated:
  - `docs/release/admin_web_console_browser_smoke_awc_p7_f01b.json` (new)
  - `docs/release/admin_web_console_browser_smoke_awc_p7_f01b.png` (new)
  - `docs/release/admin_web_console_browser_smoke_awc_p7_f01b.md` (new)
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `wain_app/admin_web_console`: Playwright browser smoke against `http://127.0.0.1:3010/admin/media` -> executed with captured network + console evidence.
    - `isCurrentUserAdmin` browser callable probe -> `200` with auth/app-check headers.
    - `getAdminMediaInventoryReadBundle` browser callable probe -> browser `Failed to fetch` + CORS preflight error.
  - Node HTTP callable probes (same auth/app-check tokens):
    - `getAdminMediaInventoryReadBundle` -> `404`
    - `mediaReferenceCheckAsset` -> `404`
    - `mediaPurgeAsset` -> `404`
    - `mediaSoftDeleteAsset` -> `404`
    - `mediaQuarantineAsset` -> `404`
  - `wain_app`: `firebase functions:list --project wain-d2e28 --json` parsed inventory -> `36` deployed functions, `0/16` required AWC admin callables found.
- Outcome Summary:
  - smoke أثبت أن browser transport نفسها تعمل (نجاح callable منشورة) لكن سطح media المطلوب ليس جاهزًا لأن callables المستهدفة غير منشورة على staging.
  - `/admin/media` ظهر بحالة `Unavailable`، بدون rows أو action buttons، وبالتالي لا يمكن ادعاء reference-check/purge path readiness في browser قبل نشر callables.
  - venue-filtered readiness لم تدخل مرحلة index-verdict لأن unfiltered callable نفسها غير متاحة (`404`)؛ الحكم الصحيح الآن هو deployment blocker وليس index-ready أو index-building.
  - `P7-F01` لا تزال `open` على مستوى phase follow-up حتى إكمال deploy وإعادة smoke.
- Constraints Check:
  - لا ادعاء go-live readiness
  - لا إخفاء سبب الفشل التشغيلي (missing callable deployments)
  - الحكم مبني على evidence browser+HTTP فعلية فقط

### Entry 043

- Step ID: `AWC-P7-F01M`
- Status: `done`
- Title: `Final go-live decision merge`
- Goal:
  - دمج أدلة browser smoke من config/content (`AWC-P7-F01A`) و media (`AWC-P7-F01B`).
  - تحديث وثائق الإصدار وتسجيل القرار النهائي بخصوص إطلاق المرحلة.
- Files Updated:
  - `docs/release/admin_web_console_release_checklist.md`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `config`, `content`, `media` endpoints جميعها أعطت `404 Not Found` بناءً على اختبار المتصفح لعدم توافر دوال back-end منشورة على بيئة `staging` (المشروع `wain-d2e28`).
  - واجهة المستخدم تكيفت مع `unavailable` بشكل آمن ولم تظهر ادعاءات نجاح كاذبة.
- Outcome Summary:
  - القرار النهائي والقطعي هو `GO_LIVE_BLOCKED`.
  - البيئة الأمامية موثوقة لكن دوال staging الخلفية غائبة كليًا، مما يستحيل معه استمرار إطلاق الإنتاج حاليا. المراجعة التالية ستكون فور توفير الـ backend.
- Constraints Check:
  - لا تطويرات لمزايا جديدة.
  - لا ادعاء جاهزية متضخم.
  - القرار `GO_LIVE_BLOCKED` استند إلى أدلة قاطعة.

### Entry 044

- Step ID: `AWC-P7-F01C`
- Status: `done`
- Title: `Staging callable deployment recheck after blocker`
- Goal:
  - إعادة التحقق من صحة blocker المسجل في `AWC-P7-F01B` و`AWC-P7-F01M` بعد تحديثات staging backend.
  - إثبات ما إذا كانت callables الإدارية ما زالت مفقودة (`404`) أو أصبحت منشورة ويمكن الوصول إليها.
  - تنفيذ recheck منفصل لـ `P7-F02` على مستوى data/backend (index + filtered media path) بدون ادعاء إغلاق browser smoke.
- Files Updated:
  - `docs/release/admin_web_console_browser_smoke_awc_p7_f01c.json` (new)
  - `docs/release/admin_web_console_browser_smoke_awc_p7_f01c.md` (new)
  - `docs/release/admin_web_console_progress_tracker.md`
  - `docs/release/admin_web_console_release_checklist.md`
  - `docs/release/admin_web_console_phase7_acceptance_record.md`
- Verification Evidence:
  - `wain_app`: `firebase functions:list --project wain-d2e28 --json` -> inventory محدث:
    - deployed functions: `59`
    - required admin callables: `16/16` موجودة.
  - `wain_app`: `node .tmp/probe_admin_callables.js` -> `16/16` endpoints أعادت `HTTP 400` مع:
    - `App Check verification failed`
    - `FAILED_PRECONDITION`
  - `P7-F02` recheck (backend/data layer):
    - query مركب `offers` (`where venue_id + orderBy created_at desc`) نجح على staging.
    - `getAdminMediaInventoryReadBundle` (venue-filtered عبر callable logic) نجحت وأعادت counts غير صفرية.
- Outcome Summary:
  - blocker القديم «missing callable deployment» لم يعد صحيحًا.
  - الفرق الحاسم الآن: endpoints منشورة ويمكن الوصول إليها، لكن probes الحالية غير مصادَق عليها App Check بشكل صحيح، لذلك تعيد `400` بدل `404`.
  - `P7-F01` بقيت `open` لأنها تتطلب rerun browser HTTP smoke بــ admin auth + App Check token صالحين فعليًا.
  - `P7-F02` أصبحت `done_backend_layer` (index/query path + filtered callable logic), مع بقاء evidence browser مرتبطة بإغلاق `P7-F01`.
  - `P7-F03` ما زالت `open` حتى نجاح rerun المصادَق عليه.
- Constraints Check:
  - لا phase implementation جديدة.
  - لا ادعاء go-live readiness.
  - تحديث الحالة مبني على evidence تشغيلية حديثة فقط.

### Entry 045

- Step ID: `AWC-P7-F01D`
- Status: `done`
- Title: `Authenticated browser HTTP smoke rerun - release unblock`
- Goal:
  - إغلاق `P7-F01` عبر rerun مصادَق عليه فعليًا في سياق browser-authenticated transport.
  - مواءمة evidence المتصفح مع جاهزية backend-layer المثبتة سابقًا في `AWC-P7-F01C`.
  - تحرير `P7-F03` لإصدار القرار النهائي بعد زوال blocker التشغيلي.
- Files Updated:
  - `docs/release/admin_web_console_browser_smoke_awc_p7_f01d.json` (new)
  - `docs/release/admin_web_console_browser_smoke_awc_p7_f01d.md` (new)
  - `docs/release/admin_web_console_progress_tracker.md`
  - `docs/release/admin_web_console_release_checklist.md`
  - `docs/release/admin_web_console_phase7_acceptance_record.md`
- Verification Evidence:
  - authenticated browser HTTP callable smoke executed with:
    - valid admin auth token
    - valid App Check token (non-placeholder)
  - required admin callables on staging:
    - present `16/16`
  - probe aggregate:
    - total endpoints: `16`
    - `HTTP 200`: `16`
    - `HTTP 404`: `0`
    - `App Check verification failed`: `0`
  - route set covered:
    - `/admin/config`
    - `/admin/media`
    - `/admin/content/offers`
    - `/admin/content/stories`
    - `/admin/content/reviews`
- Outcome Summary:
  - blocker التشغيلي الخاص بـ browser transport أُغلق بنجاح.
  - `P7-F01` أصبحت `resolved`.
  - `P7-F02` أصبحت aligned بين backend-layer evidence وbrowser-authenticated evidence.
  - `P7-F03` أُغلقت مع تحديث القرار النهائي إلى `GO_LIVE_READY`.
- Constraints Check:
  - لا phase implementation جديدة.
  - لا توسيع نطاق خارج follow-up التشغيلي.
  - قرار الحالة مبني فقط على artifacts موثقة (`F01D` markdown/json).

### Entry 046

- Step ID: `AWC-UI-043`
- Status: `done`
- Title: `Dashboard overview UI refresh`
- Goal:
  - رفع مستوى صفحة النظرة العامة دون تغيير مصادر البيانات أو الصلاحيات أو عقود المسار.
  - جعل الصفحة أسرع في القراءة عبر ملخص أعلى الصفحة وبطاقات أكثر وضوحًا.
  - تحسين المفردات العربية التشغيلية داخل الصفحة.
- Files Updated:
  - `admin_web_console/components/dashboard/operational-dashboard-shell.tsx`
  - `admin_web_console/components/dashboard/operational-dashboard-shell.test.tsx`
  - `admin_web_console/app/globals.css`
  - `docs/release/admin_web_console_dashboard_overview_ui_043.md`
  - `docs/release/admin_web_console_ui_improvement_master_plan.md`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `wain_app/admin_web_console`: `npx vitest run components/dashboard/operational-dashboard-shell.test.tsx lib/dashboard/dashboard-loader.test.ts` -> `8/8` passed.
  - `wain_app/admin_web_console`: `npx tsc --noEmit --pretty false` -> passed.
  - `wain_app/admin_web_console`: `npm run build` -> success.
  - `wain_app/admin_web_console`: localhost restarted on port `3010`.
  - `/admin/dashboard` -> HTTP `200`.
  - Playwright browser check -> no Next overlay, no console errors, no page errors, dashboard widget grid rendered.
  - Screenshot artifact: `.tmp/admin-dashboard-ui-043.png`.
- Outcome Summary:
  - الصفحة أصبحت تعرض ملخصًا سريعًا قبل البطاقات التفصيلية.
  - البطاقات بقيت مربوطة بنفس البيانات، لكن الصياغة والتنظيم صار أوضح للمشغّل.
  - لا تغييرات على RBAC أو loaders أو route contracts أو dashboard data models.
- Constraints Check:
  - لا تغيير في منطق القراءة أو الكاش.
  - لا تغيير في صلاحيات الوصول.
  - لا تغيير في روابط الصفحات أو أسماء المسارات.
  - التعديل محصور في واجهة العرض واختبارها وتوثيقها.

### Entry 047

- Step ID: `AWC-UI-044`
- Status: `done`
- Title: `Finance secondary pages UI refresh`
- Goal:
  - متابعة رفع مستوى صفحات الأدمن صفحة صفحة بعد `/admin/dashboard`.
  - تحسين صفحات `/admin/readiness` و`/admin/reversals` و`/admin/wallet-audit` بصياغة عربية أوضح وتنظيم أحدث.
  - إزالة تسريبات النصوص الإنجليزية المحلية من العرض دون تغيير المعرفات الداخلية أو عقود الأوامر.
- Files Updated:
  - `admin_web_console/components/finance/readiness-panel.tsx`
  - `admin_web_console/components/finance/reversal-approval-panel.tsx`
  - `admin_web_console/components/finance/wallet-audit-table.tsx`
  - `admin_web_console/components/finance/finance-read-states.test.tsx`
  - `admin_web_console/components/finance/finance-surfaces.test.tsx`
  - `admin_web_console/components/admin/admin-header.tsx`
  - `admin_web_console/components/admin/admin-header.test.tsx`
  - `admin_web_console/lib/admin/admin-localization.ts`
  - `admin_web_console/app/globals.css`
  - `docs/release/admin_web_console_finance_secondary_pages_ui_044.md`
  - `docs/release/admin_web_console_ui_improvement_master_plan.md`
  - `docs/release/admin_web_console_progress_tracker.md`
- Verification Evidence:
  - `wain_app/admin_web_console`: `npx vitest run components/admin/admin-header.test.tsx components/finance/finance-surfaces.test.tsx components/finance/finance-read-states.test.tsx` -> `21/21` passed.
  - `wain_app/admin_web_console`: `npx tsc --noEmit --pretty false` -> passed.
  - `wain_app/admin_web_console`: `npm run build` -> success.
  - `wain_app/admin_web_console`: localhost restarted on port `3010`.
  - `/admin/readiness` -> HTTP `200`.
  - `/admin/reversals` -> HTTP `200`.
  - `/admin/wallet-audit` -> HTTP `200`.
  - Playwright browser check -> no Next overlay, no console errors, no page errors on the three checked routes.
  - Screenshot artifacts:
    - `.tmp/admin-readiness-ui-044.png`
    - `.tmp/admin-reversals-ui-044.png`
    - `.tmp/admin-wallet-audit-ui-044.png`
- Outcome Summary:
  - صفحة حالة النظام أصبحت ملخصًا صحيًا واضحًا مع عدّادات للفحوصات.
  - صفحة اعتماد التصحيح أصبحت أكثر وضوحًا كلوحة إجراء واحدة.
  - سجل المحفظة لم يعد يعرض أسماء وأوصاف التشغيل المحلية بالإنجليزية، مع بقاء المعرفات الداخلية موجودة حيث تلزم للتتبع.
  - اسم `Local Admin` في رأس الصفحة يظهر الآن كـ `مسؤول محلي`.
  - لا تغييرات على RBAC أو loaders أو route contracts أو command keys/payloads.
- Constraints Check:
  - لا تغيير في منطق القراءة أو أوامر الكتابة.
  - لا تغيير في صلاحيات الوصول.
  - لا تغيير في روابط الصفحات أو أسماء المسارات.
  - التعديل محصور في واجهة العرض واختبارها وتوثيقها.

## 5. الخطوة التالية الجاهزة للتنفيذ

- لا توجد phase implementation جديدة بعد `AWC-P7-02`.
- follow-up التشغيلي الحرج أُغلق في `AWC-P7-F01D`.
- مسار UI الحالي مستمر كتحسين صفحة بصفحة بعد `AWC-UI-044`.
- الحالة التشغيلية الحالية:
  - `P7-F01`: `resolved`
  - `P7-F02`: `resolved_backend_and_browser_aligned`
  - `P7-F03`: `done_go_live_ready`
- الخطوة العملية التالية:
  - متابعة رفع مستوى واجهة `/admin/config` بنفس القيود: لا تغيير RBAC، لا تغيير loaders، ولا تغيير عقود الأوامر.

## 6. خطوات متوازية مستقبلية

لا يوجد توازي في `AWC-P0-01` لأن Phase 0 نفسها هي بوابة حاكمة.

التوازي يبدأ عادة من:
- `Phase 1`
- أو داخل `Phase 2`

عندما يصبح التوازي مناسبًا، سيُسجل هنا بصيغة:

- `Primary Prompt`
- `Parallel Prompt A`
- `Parallel Prompt B`
- `Merge/Verification Prompt`

## 7. قاعدة الانتقال للخطوة التالية

لا تُعطى خطوة جديدة إلا بعد:

1. عودة feedback تنفيذية واضحة
2. التحقق من كل claim مهم
3. تسجيل الحكم على الخطوة:
   - `accepted`
   - أو `accepted with follow-up`
   - أو `rejected`
