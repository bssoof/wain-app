# Merchant Master Execution Plan

## Summary
- **Surface**: لوحة التاجر داخل تطبيق WAIN الحالي فقط.
- **Model**: `single-venue merchant` فقط في هذا المسار.
- **Sprint length**: `1 week`.
- **Realistic duration**: `10-14 sprints`.
- **First usable release**: نهاية `P1`.
- **Guiding principle**: `improve without demolition`.

## Current State
- لوحة التاجر الحالية تتكون من `10 screens` ومسارات `/merchant/*` متعددة.
- merchant feature تملك `data/` و`presentation/` فقط؛ لا توجد طبقة `domain/` فعلية داخلها الآن.
- dashboard الحالية كبيرة جدًا وتحتوي orchestration وCloud Functions calls مباشرة من الـ widget.
- `merchantNotifications` ما زالت خارج تجمع merchant routes ويجب ضمّها داخل `ShellRoute`.
- توجد fallbacks إلى `/merchant/invite` داخل عدة شاشات تشغيلية؛ تُسجّل cleanup لاحق ولا تُزال في `P0a`.
- `dashboard null-venue handling` يبقى كما هو كـ `defense in depth`.
- زر `Scan` في Profile يبقى ظاهرًا الآن ويُسجّل `P1 polish`.

## Phase Plan

### P0a — Access Guard
- **Duration**: `1 sprint`
- **Goal**: إغلاق الوصول غير المحمي لكل مسارات `/merchant/*`.
- **Implementation**
- إنشاء `MerchantRouteAccess`: `unauthenticated`, `needsInvite`, `ready(venueId)`, `brokenVenueLink`.
- إنشاء `merchantRouteAccessProvider` ويجب أن `watch authStateProvider` مباشرة؛ لا يعتمد على `merchantVenueIdProvider`.
- إضافة `GoRouterRefreshStream` أو `ChangeNotifier` مكافئ مبني على `authStateChanges()` واستخدامه في `refreshListenable`.
- إبقاء `GoRouter redirect` للـ auth فقط: أي `/merchant/*` بدون auth يذهب إلى `/login?redirectTo=<original route>`.
- نقل كل merchant routes، بما فيها `/merchant/notifications`، إلى `ShellRoute` pathless واحدة.
- داخل `ShellRoute`, تطبيق `MerchantAccessGate` واحدة فقط.
- سلوك الـ gate:
- `needsInvite`: يسمح فقط بـ `/merchant/invite`.
- `ready`: يمنع فتح invite ويرسل إلى dashboard.
- `brokenVenueLink`: يعرض access issue state موحدة بدون redirect صامت.
- تحديث `MerchantInviteScreen` بعد redeem ناجح ليعمل:
- `ref.invalidate(merchantRouteAccessProvider)`
- `ref.invalidate(merchantVenueIdProvider)`
- ثم `context.go('/merchant/dashboard')`
- **Acceptance**
- كل `/merchant/*` محروس.
- login/otp يعيدان المستخدم للمسار الأصلي.
- invite success يحدّث الـ guard فورًا.
- broken venue link لا يسبب crash.

### P0b-I — Typed Merchant Foundation
- **Duration**: `1 sprint`
- **Goal**: تثبيت الأساس typed/repository قبل الدخول في refactor dashboard الثقيل.
- **Implementation**
- إضافة بنية `domain + application + data + presentation` داخل merchant feature.
- إنشاء الأنواع الأساسية:
- `MerchantWorkspace`
- `MerchantDashboardPayload`
- `MerchantKpi`
- `MerchantActionItem`
- `MerchantAlert`
- `MerchantContentHealth`
- `MerchantAnalyticsSummary`
- `MerchantAnalyticsDailyPoint`
- قراءة `venue_analytics.updated_at` صراحة داخل النوع الجديد لأن قاعدة stale rule جاهزة من الـ backend.
- إنشاء repositories واضحة لأسطح:
- `merchant_dashboard_repository`
- `merchant_offers_repository`
- `merchant_notifications_repository`
- `merchant_scan_repository`
- نقل كل Firestore writes الخاصة بالعروض من UI إلى repository.
- استخراج `OfferFormSheet` من شاشة العروض إلى مكوّن/ملف مستقل؛ هذا prerequisite صريح لـ lifecycle في `P2`.
- إيقاف fake dismiss في notifications: إزالة swipe delete behavior مؤقتًا أو تحويله إلى disabled state بدل حذف بصري كاذب.
- **Acceptance**
- لا Firestore writes مباشرة من `MerchantOffersScreen`.
- `OfferFormSheet` مفصولة عن الشاشة الرئيسية.
- `venue_analytics.updated_at` متاحة typed داخل merchant domain/application.
- no fake dismiss behavior في notifications.

### P0b-II — Dashboard Decomposition And Refresh Semantics
- **Duration**: `1-2 sprints`
- **Goal**: تفكيك dashboard الثقيلة وتثبيت semantics واضحة للتحديث.
- **Implementation**
- استخراج orchestration من dashboard إلى controller/use-case layer.
- إزالة Cloud Function calls المباشرة من dashboard widget.
- هدف الحجم: dashboard screen render-centric وبحجم لا يتجاوز تقريبًا `700` سطر.
- تحويل pull-to-refresh إلى `read refresh` فقط.
- تحويل backfill/callables إلى actions منفصلة وواضحة في UI.
- إصلاح post-redeem invalidation للمصادر المتأثرة: `offers`, `analytics`, `notifications`, `dashboard payload`.
- تنفيذ cleanup للـ dead invite fallback code في الشاشات التشغيلية، مع إبقاء dashboard null-venue handling كما هو.
- **Milestone rule**
- إذا `P0b-I` استهلك sprint كامل، يتم اعتبار `P0b-II` milestone مستقل وقد يحتاج sprint ثالث؛ هذه إشارة مبكرة وليست failure.
- **Acceptance**
- لا Cloud Function calls مباشرة من dashboard widget.
- refresh semantics واضحة ومنفصلة عن backfill.
- post-redeem updates تظهر بدون stale UI واضح.
- fallback cleanup تم في الشاشات المستهدفة.

### P1 — Decision Hub
- **Duration**: `2 sprints`
- **Goal**: تحويل dashboard إلى surface قرار حقيقية.
- **Implementation**
- بناء Merchant Shell فوق المسارات الحالية مع header ثابت وquick nav وaction feed.
- البدء بـ `Action Feed` أولًا ثم health strip ثم بقية shell chrome.
- **Loading strategy**
- Stage 1: `workspace access`, `venue summary`, `analytics summary`, `unread count`, `action feed skeleton`
- Stage 2: `daily analytics 14d`, `unanswered reviews limit 5`, `offers limit 10`, `story freshness lightweight read`
- Stage 3: full lists only inside child screens
- **Performance budget**
- skeleton خلال `<300ms`
- first meaningful content خلال `<1.2s warm` و`<2.5s cold`
- لا يزيد الحمل الأولي عن `5` reads/listeners قبل first meaningful paint و`8` بعد deferred loads
- **Action Feed rules**
- priority: `critical > important > suggested`
- sorting: `age desc` ثم `business impact desc`
- display: `top 5`
- max `2 suggested`
- `critical`: no active menu, missing hours, stale analytics `>24h`, broken venue link
- `important`: unanswered reviews `>24h`, no active offers, offer ends within `48h`
- `suggested`: photos `<5`, no story in `7d`, profile incomplete
- **Acceptance**
- dashboard تعطي: ما الذي تغير، ما الذي يحتاج تدخلًا، وما هو next best action.
- action feed مرتبة وقابلة للاختبار.
- فوق الطية لا تحمل full lists.
- stale analytics تعتمد على `updated_at` الحقيقي من backend.

### P2 — Growth Ops
- **Duration**: `2-3 sprints`
- **Goal**: تثبيت حلقة الربح اليومية.
- **Implementation**
- إضافة `status` additive للعروض: `draft | active | paused | archived`
- القراءة تفضّل `status` ثم fallback إلى `is_active` خلال release انتقالية
- ربط lifecycle كامل للعروض عبر repository + typed models
- استكمال refactor شاشة العروض بعد فصل `OfferFormSheet` حتى تصبح lifecycle-ready
- ضمان اتساق: `scan -> redeem -> counters -> notifications -> dashboard`
- deep links للإشعارات تصبح دقيقة ومقصودة
- **Acceptance**
- لا drift بين counters في العرض والداشبورد
- التاجر يرى lifecycle واضحًا للعروض
- deep links تفتح السطح الصحيح

### P3 — Content Ops
- **Duration**: `2-3 sprints`
- **Goal**: تحويل surfaces المحتوى إلى content health system.
- **Implementation**
- تعريف thresholds ثابتة:
- `menu freshness`: healthy `<=14d`, warning `15-30d`, critical `>30d` أو no active menu
- `photo coverage`: healthy `>=5`, warning `3-4`, critical `<3`
- `story cadence`: healthy active now أو `<=7d`, warning `8-14d`, critical `>14d`
- `hours confidence`: healthy إذا `is_24h` أو ساعات كاملة + timezone، warning partial، critical none
- `profile completeness`: required = `name`, `category`, `city`, `phone`, `description`, `1+ photo`
- إظهار هذه المؤشرات في dashboard مع CTA مباشر
- **Acceptance**
- كل مؤشر له threshold واضح
- كل warning/critical له CTA مباشر
- الشاشات الفرعية تستعمل shared states نفسها

### P4 — Platform Hardening
- **Duration**: `1-2 sprints`
- **Goal**: نقل طبقة القرار إلى read model server-side.
- **Implementation**
- إضافة doc جديد additive: `merchant_workspace/{venueId}`
- يحتوي: `generated_at`, `summary`, `health`, `top_actions`, `freshness`
- **Generation strategy chosen by default**
- event-driven generation on relevant writes:
- offer create/update/delete/redeem
- review create/reply update
- story create/delete/promote
- venue info/hours/menu publish updates
- plus nightly reconciliation scheduled job لإصلاح أي drift
- client يقرأ `merchant_workspace` أولًا
- إذا غاب، يستخدم fallback client derivation لمدة release واحدة فقط
- تحديث rules للسماح بالقراءة للتاجر المرتبط فقط
- بعد release مستقر واحد، إزالة fallback
- **Acceptance**
- dashboard الرئيسية تعتمد على server read model
- nightly reconciliation موجودة
- لا breaking changes على العقود القديمة

## Public Interfaces / Types
- أنواع جديدة:
- `MerchantRouteAccess`
- `MerchantWorkspace`
- `MerchantDashboardPayload`
- `MerchantKpi`
- `MerchantActionItem`
- `MerchantActionPriority`
- `MerchantContentHealth`
- `MerchantAnalyticsSummary`
- `MerchantAnalyticsDailyPoint`
- عقد offers الجديد:
- `status` additive مع fallback إلى `is_active`
- عقد read model النهائي:
- `merchant_workspace/{venueId}` read-only additive

## Test Plan
- **Unit**
- route access decisions
- stale/freshness rules using `updated_at`
- action ranking
- content health thresholds
- offer status mapping
- **Widget**
- access gate
- login redirect return
- dashboard shell
- action feed ordering
- notifications behavior after swipe removal
- **Integration/Emulator**
- `invite -> dashboard`
- `offer claim -> scan -> redeem -> counters + notification`
- `review reply -> action clear`
- `refresh without backfill`
- **Manual**
- deep link إلى merchant routes
- login ثم return
- invite redeem
- scan/redeem من حساب merchant فعلي
- dashboard first paint + stale indicators

## Execution Checklist
- تنفيذ `P0a` أولًا وإغلاقه بالكامل.
- تنفيذ `P0b-I` قبل أي قرار UI كبير على dashboard.
- إذا استهلك `P0b-I` sprint كامل، يتم رسميًا توسيع `P0b` إلى 3 sprints.
- تنفيذ `P0b-II` قبل `P1`.
- عدم بدء `P2` قبل فصل `OfferFormSheet`.
- تسجيل `Profile scan visibility` كبند `P1 polish`.
- تسجيل dead invite fallback cleanup ضمن `P0b-II`.
- إبقاء dashboard null-venue handling كما هو حتى نهاية `P0b-II`.

## Assumptions
- baseline مبني على مهندس واحد.
- لا offline support خاص بالتاجر في هذا المسار.
- لا multi-branch ولا staff roles في هذا التنفيذ.
- `merchant_workspace` generation تعتمد event triggers + nightly reconciliation كقرار افتراضي معتمد، وليس open question.
