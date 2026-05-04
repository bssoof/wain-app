# Waselni Transport Feature Plan

## Goal
إضافة ميزة `وصلني` داخل التطبيق بحيث يتمكن المستخدم، بعد اختيار الفلاتر والوصول إلى صفحة المكان، من رؤية خيارات توصيل/تكسي إلى المكان مع أسعار واضحة، ثم الانتقال إلى الحجز أو الطلب عبر شريك النقل.

الميزة المقصودة هنا هي:
- `transport to venue`
- وليست `delivery of food/items`

---

## Why This Feature Makes Sense In Current App Flow
المسار الحالي في التطبيق هو:
1. المستخدم يحدد المدينة أو الموقع والفلاتر
2. التطبيق يقترح أماكن
3. المستخدم يفتح `Venue Details`
4. في الأسفل توجد أزرار:
   - `Call`
   - `WhatsApp`
   - `Navigate`

هذا يعني أن أفضل نقطة إدخال لميزة `وصلني` هي:
- `lib/features/venue/presentation/screens/venue_details_screen.dart`

والبنية الحالية تساعدنا لأن عندنا أصلًا:
- مصدر موقع المستخدم:
  - `lib/core/providers/location_provider.dart`
- نقطة وصول للمكان:
  - `venue.lat`
  - `venue.lng`
- مسار analytics/navigation موجود:
  - `lib/features/navigation/data/repositories/navigation_repository_impl.dart`

لكن `وصلني` يجب أن تكون feature مستقلة، لا أن تُبنى فوق `navigation_clicks`.

---

## Product Definition
`وصلني` تعني:
- حساب أو جلب خيارات نقل من موقع المستخدم الحالي إلى المكان
- عرض:
  - نوع الخدمة
  - اسم الشريك أو السائق/الفئة
  - السعر المتوقع أو المؤكد
  - وقت الوصول التقريبي
  - وقت الرحلة التقريبي
- السماح للمستخدم أن:
  - يختار الخيار
  - يبدأ handoff إلى الشريك
  - أو يطلب الرحلة داخل النظام لاحقًا

---

## Recommended Scope
## MVP
النسخة الأولى يجب أن تكون:
- `estimate + handoff`

أي:
1. التطبيق يعرض خيارات النقل مع السعر المتوقع
2. عند اختيار المستخدم خيارًا، يتم:
   - handoff إلى شريك النقل
   - أو إرسال lead/request منظم

## Not Recommended For MVP
لا أنصح أن نبدأ مباشرة بـ:
- dispatch داخلي كامل
- live driver tracking
- in-app payment
- driver marketplace

هذه تنقل المشروع من feature transport إلى مشروع ride-hailing شبه كامل.

---

## Product Principles
1. `Venue-first`
- الميزة تظهر بعد دخول المستخدم إلى المكان

2. `Origin-aware`
- التسعير يعتمد على موقع بداية فعلي أو fallback واضح

3. `Provider-agnostic`
- لا نبني الكود على مزود واحد فقط

4. `No fake certainty`
- إذا السعر تقديري، نعرضه بوضوح كتقدير

5. `Do not weaken current UX`
- لا نكسر مسار:
  - `Call`
  - `WhatsApp`
  - `Navigate`

---

## UX Entry Points
## Primary Entry Point
داخل `Venue Details`.

## UI Recommendation
لا تضف زرًا رابعًا مساويًا للأزرار الثلاثة الحالية في الشريط السفلي، لأن هذا سيضغط الواجهة على الهاتف.

التوصية:
1. الشريط السفلي يصبح:
- `Call`
- `WhatsApp`
- `وصلني`

2. خيار `Navigate` ينتقل إلى داخل bottom sheet الخاصة بـ `وصلني` كخيار ثانوي:
- `ابدأ الملاحة بنفسك`
- `اختر تكسي`

## Optional Secondary Entry Point
لاحقًا يمكن إضافة badge أو CTA خفيف في:
- result cards
- map bottom sheet

لكن ليس في MVP.

---

## User Flow
## Flow A: User With Real Location
1. المستخدم يدخل `Venue Details`
2. يضغط `وصلني`
3. تظهر bottom sheet:
   - نقطة الانطلاق الحالية
   - المكان المقصود
   - loading quotes
4. التطبيق:
   - يسجل الحدث
   - وينفذ handoff أو request creation

## Flow B: User Without Real Location
إذا `userLocationProvider` يعمل على fallback city center أو لا يوجد location permission:
1. عند فتح `وصلني`
2. يظهر للمستخدم:
   - `حدد نقطة الانطلاق`
   - أو `استخدم مركز المدينة`
3. لا نحسب سعرًا على أنه مؤكد قبل حسم origin
4. يتم الطلب من المستخدم ب ادخال الموقع و التسجبل
## Flow C: No Quotes Available
إذا لا يوجد شريك متاح:
- نعرض:
  - `لا يوجد توصيل متاح الآن`
  - مع خيار:
    - `افتح الاتجاهات`
    - `اتصل بالمكان`

---

## Core Decisions
## Decision 1: Quote Source
عندنا 3 نماذج ممكنة:

1. `Provider API`
- التكسي أو الشركة لديها API للأسعار/الطلبات

2. `Aggregator`
- وسيط يجمع عروض أكثر من مزود

3. `Managed Local Pricing`
- لا يوجد API فعلي
- نخزن قواعد تسعير أو شركاء محليين داخل النظام

## Recommendation
ابنِ feature بواجهة موحدة:
- `TransportQuoteProvider`

حتى نقدر تشغيل:
- مزود API حقيقي
- أو fallback محلي مُدار داخليًا

هذا يعطي مرونة بدون إعادة كتابة الـ client.

## Decision 2: Booking Model
لـ MVP:
- `quote + handoff`

لـ V2:
- `quote + request + status`

## Decision 3: Auth Requirement
التوصية:
1. `view quotes`
- مسموح للضيف

2. `create transport request / booking intent`
- يفضل مستخدم مسجل
- أو guest مع:
  - `deviceId`
  - `App Check`
  - rate limiting

إذا أردت أبسط وأأمن MVP:
- اجعل الطلب الفعلي `auth-only`
- واترك مشاهدة الأسعار متاحة للجميع

---

## Data Model
## Venue Fields
أضف فقط ما يلزم:
- `transport_enabled: bool`
- `transport_partner_ids: string[]`
- `transport_notes_ar/en: string?`

ولا تخلط هذه البيانات مع حقول الـ navigation الحالية.

## New Collections
### `transport_partners/{partnerId}`
حقول مقترحة:
- `name`
- `status`
- `supported_cities`
- `service_modes`
- `quote_mode`
  - `api`
  - `managed`
- `currency`
- `contact_mode`
  - `deep_link`
  - `api_request`
  - `whatsapp`
  - `phone`
- `min_eta_minutes`
- `max_eta_minutes`
- `is_active`

### `transport_partner_rules/{ruleId}`
للتسعير المُدار داخليًا:
- `partner_id`
- `city`
- `base_fare`
- `per_km_rate`
- `minimum_fare`
- `surge_rules`
- `service_fee`
- `is_active`

### `transport_requests/{requestId}`
عند بدء handoff/request:
- `user_id`
- `device_id`
- `venue_id`
- `partner_id`
- `origin`
- `destination`
- `estimated_price`
- `currency`
- `status`
  - `initiated`
  - `handed_off`
  - `requested`
  - `accepted`
  - `completed`
  - `cancelled`
  - `failed`
- `created_at`
- `updated_at`
- `source`

### `transport_quote_logs/{quoteId}`
اختياري للتحليل فقط:
- `venue_id`
- `user_id`
- `device_id`
- `origin_hash`
- `provider_results_count`
- `selected_partner_id`
- `created_at`

لـ MVP يمكن تجنب تخزين كل quote، والاكتفاء بالـ analytics + request logs.

---

## Backend Architecture
## New Module
أنصح إضافة feature مستقلة:
- `lib/features/transport/`

وتوازيها خدمات backend:
- `functions/src/transport.ts`
أو داخل `functions/src/index.ts` مبدئيًا إذا أردت إبقاء الانتشار بسيطًا

## Recommended Callables
### `getTransportQuotes`
المدخلات:
- `venueId`
- `originLat`
- `originLng`
- `city`
- `source`

المخرجات:
- `quotes[]`
  - `partnerId`
  - `partnerName`
  - `serviceType`
  - `estimatedPrice`
  - `priceMin`
  - `priceMax`
  - `currency`
  - `etaMinutes`
  - `tripMinutes`
  - `isEstimate`
  - `handoffType`

المسؤوليات:
- validate venue
- validate location
- check `transport_enabled`
- call provider adapters
- normalize response
- rank options

### `createTransportRequest`
المدخلات:
- `venueId`
- `partnerId`
- `origin`
- `selectedQuote`
- `source`

المخرجات:
- `requestId`
- `handoffUrl` أو `requestStatus`

المسؤوليات:
- validate selected partner
- recalculate or verify quote integrity server-side
- create `transport_requests`
- return safe handoff payload

### `cancelTransportRequest`
ليست ضرورية في MVP إذا كان flow handoff-only.

### `transportProviderWebhook`
HTTP/admin-only future path إذا صار عندنا provider updates:
- accepted
- driver assigned
- completed

---

## Provider Adapter Design
## Interface
كل provider يجب أن يطبق نفس interface:
- `supports(city, venue, origin)`
- `getQuotes(origin, destination, context)`
- `buildHandoff(request)`
- `normalizeResult(raw)`

## Why This Matters
لأننا لا نعرف من الآن هل الشريك النهائي سيكون:
- API-based provider
- local taxi dispatcher
- managed pricing partner

إذا بنيت الكود مباشرة على provider واحد، ستقيد feature من أول يوم.

---

## Pricing Model
## MVP Pricing Rules
1. السعر يظهر كـ:
- `Estimated`
أو:
- `Starting from`

2. السعر لا يصبح `confirmed` إلا إذا provider يدعمه فعليًا.

3. إذا استخدمنا managed pricing:
الحساب يعتمد على:
- base fare
- distance km
- optional city/service fee
- optional time-of-day multiplier

## Important Constraint
لا تعتمد على client لحساب السعر النهائي.
الحساب أو verification يجب أن يبقى server-side.

---

## Location Strategy
## Origin Source Of Truth
استخدم نفس منطق التطبيق الحالي:
- `userLocationProvider`
- وإذا فشل:
  - selected city fallback

لكن في `وصلني` لا يكفي fallback الصامت دائمًا.

## Rule
إذا الموقع ليس `real location`:
- نعرض للمستخدم أن السعر مبني على:
  - مركز المدينة
أو:
  - نطلب منه تحديد origin يدويًا

هذا مهم حتى لا نعطي سعرًا مضللًا.

---

## Venue Details UI Plan
## Bottom Bar
النسخة المقترحة:
- `Call`
- `WhatsApp`
- `وصلني`

## Waselni Bottom Sheet
المحتوى:
1. `From`
- موقعك الحالي أو origin المختار

2. `To`
- اسم المكان + الحي/المدينة

3. `Transport options list`
- cards مرتبة حسب:
  - الأفضل سعرًا
  - الأسرع
  - الموصى به

4. `Secondary actions`
- `ابدأ الملاحة بنفسك`
- `تحديث الأسعار`

## Quote Card Fields
- اسم الشريك
- نوع الخدمة
- السعر
- ETA
- وقت الرحلة
- badge:
  - `الأرخص`
  - `الأسرع`
  - `سعر تقديري`

## Loading / Empty / Error States
يجب تصميم:
- loading skeleton
- no coverage
- no real location
- provider timeout
- partial results

---

## Ranking Logic
لا تعرض النتائج عشوائيًا.

الترتيب المقترح:
1. cheapest
2. fastest
3. partner priority
4. quote freshness

مع tagging بصري:
- `Best price`
- `Fastest`

---

## Analytics
لا تستخدم `navigation_clicks` لهذا المسار.

## New Events
- `transport_quotes_opened`
- `transport_quotes_loaded`
- `transport_quotes_failed`
- `transport_quote_selected`
- `transport_handoff_started`
- `transport_request_created`
- `transport_request_completed`
- `transport_request_cancelled`

## Required Dimensions
- `venue_id`
- `city`
- `source = venue_details`
- `partner_id`
- `service_type`
- `user_authenticated`
- `has_real_location`
- `quotes_count`

---

## Security And Abuse Controls
## For `getTransportQuotes`
- `App Check` required
- clamp coordinates to valid ranges
- validate venue exists and `transport_enabled == true`
- rate limit by:
  - `uid`
  - or `deviceId`
- reject oversized payloads

## For `createTransportRequest`
- stronger rate limit
- server-side quote verification
- no trust in price selected by client
- log request lifecycle

## Firestore Rules
`transport_requests`
- create: server only if possible
- read: owner only
- update: server/provider/admin only

`transport_partners`
- read: public only if data is safe
- write: admin/server only

## Security Testing To Add
- quote spam
- origin tampering
- partnerId tampering
- stale quote reuse
- guest abuse via device reset
- inactive venue with transport enabled mismatch

---

## Operational And Product Risks
1. `No provider API`
- الحل: managed pricing + handoff

2. `Estimated price mismatch`
- لازم wording واضح:
  - `سعر تقديري`

3. `Location quality poor`
- نحتاج fallback UI واضح

4. `Provider outage`
- partial results acceptable

5. `Commission disputes`
- transport analytics يجب أن تكون منفصلة عن `navigation_clicks`

6. `Support burden`
- إذا سمحت بطلب داخل التطبيق من أول يوم، ستدخل في:
  - cancellation
  - support
  - service disputes

لهذا handoff-first أنظف في البداية.

---

## Merchant/Admin Scope
## Merchant
في النسخة الأولى لا أوصي أن التاجر يدير transport بنفسه من لوحة التاجر.

## Admin
نحتاج admin configuration فقط:
- تفعيل transport على المكان
- ربط partners بالمكان أو المدينة
- ضبط pricing rules إذا كانت managed
- تعطيل شريك أو منطقة

---

## Rollout Plan
## Phase 0: Discovery And Provider Decision
المدة: `2-4` أيام

المخرجات:
- حسم:
  - API provider أم managed pricing
- حسم:
  - estimate-only أم request handoff
- جمع business rules:
  - commission
  - supported cities
  - service hours

## Phase 1: Backend Foundation
المدة: `3-5` أيام

المخرجات:
- schema
- `getTransportQuotes`
- adapter abstraction
- managed pricing fallback
- security/rate limiting

## Phase 2: Venue Details UX
المدة: `3-5` أيام

المخرجات:
- new `وصلني` CTA
- quotes sheet
- loading/error/empty states
- localization

## Phase 3: Request/Handoff Flow
المدة: `2-4` أيام

المخرجات:
- `createTransportRequest`
- handoff deep link
- request logs
- analytics

## Phase 4: Hardening
المدة: `2-3` أيام

المخرجات:
- security test plan for transport
- replay/rate-limit tests
- location tampering tests
- provider failure tests

## Phase 5: Pilot
المدة: `3-7` أيام

المخرجات:
- city-limited rollout
- one or two partners only
- quote accuracy review
- usage analytics review

---

## Acceptance Criteria For MVP
1. المستخدم يرى `وصلني` داخل `Venue Details`
2. يمكنه جلب أسعار من موقعه إلى المكان
3. إذا لم يوجد موقع حقيقي، يحصل على fallback واضح وغير مضلل
4. يمكنه اختيار خيار نقل وبدء handoff
5. كل flow مسجل analytics بشكل مستقل
6. لا يوجد price tampering من client
7. الميزة لا تكسر:
- call
- WhatsApp
- navigate

---

## Open Decisions That Must Be Closed Before Implementation
1. هل `وصلني`:
- quotes فقط
- أم quotes + booking request

2. هل الشريك:
- API-based
- أم local managed pricing

3. هل الضيف يستطيع طلب transport
أم:
- quotes فقط للضيف
- والطلب للمستخدم المسجل فقط

4. هل السعر:
- تقديري فقط
- أم مُلزم

5. هل هناك commission model مختلف عن `navigation_clicks`

---

## Recommended Technical Direction
التوصية العملية الآن:

1. ابدأ بـ `MVP = quote + handoff`
2. ابنِ feature مستقلة:
- `features/transport`
3. أضف CTA داخل:
- `VenueDetailsScreen`
4. لا تستخدم `navigation_clicks` كمسار بيانات للميزة
5. ابقِ pricing logic على السيرفر
6. اجعل provider integration قابلة للاستبدال

هذا المسار يعطيك:
- feature مفيدة بسرعة
- أقل مخاطرة تشغيلية
- وأساس صحيح للتوسع لاحقًا

---

## Suggested File/Module Targets
## Client
- `lib/features/venue/presentation/screens/venue_details_screen.dart`
- `lib/features/transport/data/`
- `lib/features/transport/domain/`
- `lib/features/transport/presentation/`

## Backend
- `functions/src/index.ts`
أو:
- `functions/src/transport.ts`

## Rules
- `firestore.rules`
إذا أضفت collections جديدة

## Docs
- security plan خاص بالـ transport بعد بدء التنفيذ

---

## Final Recommendation
إذا أردت تنفيذًا قويًا بدون تضخيم المشروع:

- لا تبدأ من `full taxi platform`
- ابدأ من:
  - `Waselni = transport estimates + handoff from venue details`

هذا ينسجم مع المنتج الحالي، ويضيف قيمة مباشرة بعد discovery، بدون إدخال التطبيق في تعقيد dispatch والدفع وتتبع السائق من النسخة الأولى.
