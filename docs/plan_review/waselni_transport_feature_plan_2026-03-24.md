# Waselni Transport Feature Plan

## Status
هذه النسخة هي النسخة التنفيذية المعتمدة للـ MVP.
هي المرجع الواحد للقرار والتنفيذ، وليست ملف مراجعة أو ملاحظات متفرقة.

---

## Goal
إضافة ميزة `وصلني` داخل التطبيق بحيث يتمكن المستخدم، بعد الوصول إلى صفحة المكان، من رؤية خيارات نقل إلى المكان مع أسعار واضحة، ثم بدء handoff إلى شريك النقل.

المقصود هنا هو:
- `transport to venue`
- وليس `delivery of food/items`

---

## Final MVP Definition
الـ MVP المعتمد هو:
- `quote + handoff`

وهذا يعني:
1. التطبيق يجلب خيارات نقل من نقطة انطلاق المستخدم إلى المكان.
2. التطبيق يعرض أسعارًا تقديرية أو ثابتة بحسب المصدر.
3. عند اختيار المستخدم خيارًا، يبدأ handoff إلى الشريك.
4. لا يوجد في الـ MVP:
- dispatch داخلي كامل
- live driver tracking
- in-app payment
- booking lifecycle كامل داخل التطبيق

أي شيء من هذا ينتقل إلى `V2`.

---

## Why This Fits The Current App
المسار الحالي في التطبيق هو:
1. المستخدم يحدد المدينة أو الموقع والفلاتر.
2. التطبيق يقترح أماكن.
3. المستخدم يفتح `Venue Details`.
4. توجد مسارات تفاعل جاهزة مثل:
- `Call`
- `WhatsApp`
- `Navigate`

والبنية الحالية توفر أصلًا:
- مصدر موقع المستخدم:
  - `lib/core/providers/location_provider.dart`
- إحداثيات المكان:
  - `venue.lat`
  - `venue.lng`
- analytics/navigation infrastructure قائمة:
  - `lib/features/navigation/data/repositories/navigation_repository_impl.dart`

لكن `وصلني` يجب أن تكون feature مستقلة، ولا يجب أن تُبنى فوق `navigation_clicks`.

---

## Product Principles
1. `Venue-first`
- الميزة تظهر بعد دخول المستخدم إلى صفحة المكان.

2. `Origin-aware`
- التسعير يعتمد على origin واضح، وليس fallback صامت غير مفهوم.

3. `Provider-agnostic`
- لا نبني الكود على مزود واحد فقط.

4. `No fake certainty`
- إذا كان السعر تقديريًا، نعرضه بوضوح على أنه تقديري.

5. `Do not weaken current UX`
- لا نكسر مسارات:
  - `Call`
  - `WhatsApp`
  - `Navigate`

---

## Final UX Decision
## Entry Point
لن نضيف زرًا رابعًا في الشريط السفلي الحالي.

القرار المعتمد:
- يبقى الشريط السفلي كما هو:
  - `Call`
  - `WhatsApp`
  - `Navigate`
- وتُضاف ميزة `وصلني` كـ CTA card واضحة داخل `Venue Details` قرب أعلى الصفحة.

## Recommended Placement
أفضل مكان في الـ MVP:
- مباشرة بعد الـ hero summary أو قبل التبويبات الرئيسية
- كـ card مستقلة تحتوي:
  - عنوان `وصلني`
  - وصف قصير
  - origin الحالي
  - CTA: `عرض خيارات التوصيل`

هذا يحافظ على UX الحالي ولا يضغط الأزرار السفلية على الهاتف.

---

## User Flows
## Flow A: User With Real Location
1. المستخدم يدخل `Venue Details`.
2. يرى card `وصلني` ويضغط `عرض خيارات التوصيل`.
3. تظهر bottom sheet أو full-sheet تحتوي:
- `من`: موقعك الحالي
- `إلى`: اسم المكان
- loading quotes
4. تعرض الخيارات المتاحة.
5. يختار المستخدم خيارًا.
6. التطبيق:
- يسجل الحدث
- ينشئ handoff record
- ويفتح deep link أو وسيلة التواصل مع الشريك

## Flow B: User Without Real Location
إذا كان `userLocationProvider` يعمل على fallback city center أو لا توجد صلاحية موقع:
1. عند فتح `وصلني` يظهر banner واضح.
2. الرسالة:
- `موقعك الحالي غير متاح. الأسعار مبنية على مركز المدينة وقد تتغير.`
3. الخيارات المتاحة:
- `تفعيل الموقع`
- `المتابعة بالتقدير`
4. إذا تابع المستخدم:
- تعرض كل الأسعار كـ ranges أو estimates فقط
- مع badge `سعر تقديري`

## Flow C: No Quotes Available
إذا لا يوجد شريك متاح:
- نعرض:
  - `لا يوجد توصيل متاح حالياً`
- مع actions:
  - `ابدأ الملاحة بنفسك`
  - `اتصل بالمكان`

## Flow D: Return After Handoff
إذا عاد المستخدم إلى التطبيق بعد handoff:
- تبقى sheet قابلة للإغلاق أو إعادة الاستخدام
- نسجل العودة كـ analytics فقط
- لا نطلب منه تأكيد الحجز في الـ MVP

هذه الخطوة تؤجل إلى `V2` إذا صار لدينا booking state فعلي.

---

## Scope Boundaries
## Included In MVP
- quotes display
- managed pricing أو provider API integration
- handoff via deep link / WhatsApp / phone / provider URL
- analytics
- rate limiting
- quote logging
- feature flags

## Excluded From MVP
- trip status tracking
- driver assignment
- cancellation flow
- payment flow
- merchant-facing transport management
- webhook lifecycle integration
- disputes and settlement workflows داخل التطبيق

---

## Final Product Decisions
## Decision 1: Booking Model
المعتمد:
- `quotes + handoff only`

## Decision 2: Auth Model
المعتمد للـ MVP:
- `view quotes`: مسموح للضيف وللمستخدم المسجل
- `start handoff`: مسموح أيضًا للضيف وللمستخدم المسجل

الضبط الأمني يكون عبر:
- `App Check`
- `deviceId`
- rate limiting
- server-side validation

لا حاجة لفرض login في MVP طالما لا يوجد booking lifecycle داخلي أو payment.

## Decision 3: Distance Source
المعتمد:
- إذا provider API يعيد route distance/time، نستخدمه.
- إذا استخدمنا managed pricing، نستخدم Haversine server-side في الـ MVP.
- لا نعتمد على external route engine في النسخة الأولى.

## Decision 4: Quote Confidence
المعتمد:
- كل quote يجب أن تحمل أحد القيمتين:
  - `estimate`
  - `fixed`

## Decision 5: Quote Logging
المعتمد:
- `transport_quote_logs` ليست اختيارية.
- الحد الأدنى من logging إلزامي من أول يوم.

---

## Data Model
## Venue Fields
تضاف الحقول التالية فقط إلى `venues/{venueId}`:
- `transport_enabled: bool`
- `transport_partner_ids: string[]`
- `transport_notes_ar: string?`
- `transport_notes_en: string?`

## transport_partners/{partnerId}
الحقول المقترحة:
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
  - `whatsapp`
  - `phone`
  - `api_request`
- `min_eta_minutes`
- `max_eta_minutes`
- `is_active`

## transport_partner_rules/{ruleId}
هذا collection للتسعير المُدار داخليًا في الـ MVP.

الحقول:
- `partner_id`
- `city`
- `base_fare`
- `per_km_rate`
- `minimum_fare`
- `service_fee`
- `is_active`

ملاحظة:
- `surge_rules` خارج الـ MVP.

## transport_quote_logs/{logId}
هذا logging إلزامي في الـ MVP.

الحد الأدنى للحقول:
- `venue_id`
- `city`
- `origin_geohash`
- `quotes_count`
- `providers_queried`
- `providers_succeeded`
- `providers_failed`
- `selected_partner_id`
- `selected_price`
- `latency_ms`
- `user_authenticated`
- `created_at`

## transport_handoffs/{handoffId}
بدل `transport_requests` في الـ MVP، نعتمد collection اسمها `transport_handoffs` لأننا لا نبني booking lifecycle كامل.

الحقول:
- `user_id`
- `device_id`
- `venue_id`
- `partner_id`
- `origin`
- `destination`
- `selected_quote_id`
- `selected_price`
- `currency`
- `quote_confidence`
- `quote_source`
- `handoff_type`
  - `deep_link`
  - `whatsapp`
  - `phone`
  - `api`
- `request_channel`
  - `venue_details`
- `status`
  - `initiated`
  - `handed_off`
  - `failed`
  - `abandoned`
- `failure_reason`
- `created_at`
- `updated_at`

---

## Quote Object Contract
كل quote يجب أن ترجع بهذه الحقول المعيارية:
- `quote_id`
- `partner_id`
- `partner_name`
- `service_type`
- `estimated_price`
- `price_min`
- `price_max`
- `currency`
- `eta_minutes`
- `trip_minutes`
- `generated_at`
- `expires_at`
- `price_confidence`
  - `estimate`
  - `fixed`
- `quote_source`
  - `api`
  - `managed`
  - `cached`
- `handoff_type`
- `handoff_url`
- `pricing_version`

## Quote Expiry
المعتمد:
- كل quote يجب أن تحمل `expires_at`
- لا يسمح باستخدام quote منتهية
- إذا انتهت quote داخل الواجهة:
  - نظهر `انتهى هذا السعر. حدّث الأسعار.`
  - ونمنع handoff على quote منتهية

القيمة المقترحة للـ MVP:
- `TTL = 120s`

---

## Backend Architecture
## Client Module
إضافة feature مستقلة:
- `lib/features/transport/`

تقسيم مقترح:
- `lib/features/transport/data/`
- `lib/features/transport/domain/`
- `lib/features/transport/presentation/`

## Backend Module
التوصية:
- ملف مستقل:
  - `functions/src/transport.ts`
- ثم re-export من:
  - `functions/src/index.ts`

هذا أفضل من تضخيم `index.ts` أكثر.

---

## Required Callables
## 1. getTransportQuotes
المدخلات:
- `venueId`
- `originLat`
- `originLng`
- `city`
- `source`

المخرجات:
- `quotes[]`
- `originMode`
  - `real_location`
  - `city_fallback`
- `generatedAt`
- `expiresAt`

المسؤوليات:
- validate venue
- validate coordinates
- check `transport_enabled`
- determine active partners
- query provider adapters
- normalize quotes
- rank quotes
- write `transport_quote_logs`

## 2. createTransportHandoff
المدخلات:
- `venueId`
- `partnerId`
- `quoteId`
- `selectedQuote`
- `origin`
- `source`

المخرجات:
- `handoffId`
- `handoffType`
- `handoffUrl`

المسؤوليات:
- validate selected partner
- validate quote freshness
- verify quote server-side
- create `transport_handoffs`
- return safe handoff payload

## Not In MVP
- `cancelTransportRequest`
- `transportProviderWebhook`
- `getTransportStatus`

---

## Provider Adapter Design
كل provider يجب أن يطبق contract واحدة:
- `supports(city, venue, origin)`
- `getQuotes(origin, destination, context)`
- `buildHandoff(request)`
- `normalizeResult(raw)`

الهدف:
- API provider اليوم
- managed pricing غدًا
- شريك جديد لاحقًا

بدون إعادة كتابة الـ client أو الـ callable contract.

---

## Pricing Model
## MVP Rules
1. السعر لا يُحسب على الـ client.
2. أي verification نهائي يبقى server-side.
3. إذا كان المصدر managed pricing:
- `base_fare + (distance_km * per_km_rate) + service_fee`
4. إذا لا توجد real location:
- تعرض الأسعار كـ `range` أو `estimate` فقط
5. لا يوجد `surge_rules` في الـ MVP.

## Labels
- `سعر تقديري`
- `ابتداءً من`
- `من {min} إلى {max}`
- `قد يتغير عند التأكيد`

---

## Location Strategy
## Source Of Truth
نستخدم:
- `userLocationProvider`

## If Real Location Available
- تستخدم مباشرة في quote calculation.

## If Real Location Unavailable
- يستخدم city fallback الحالي.
- لكن يجب توضيح ذلك بصريًا.

## Final MVP Decision
لا يوجد map picker في الـ MVP.

البديل المعتمد:
- fallback واضح
- banner تحذيري
- أسعار بعلامة `سعر تقديري`
- CTA `تفعيل الموقع`

هذا يقلل التعقيد ويحافظ على صدق التجربة.

---

## CTA Visibility Rules
- إذا `transport_enabled == false`:
  - لا يظهر CTA `وصلني`

- إذا `transport_enabled == true` و`partners_available == false`:
  - يظهر CTA معطلًا مع نص `قريبًا`

- إذا `transport_enabled == true` و`partners_available == true`:
  - يظهر CTA فعالًا

- إذا المدينة أو origin خارج نطاق الشركاء:
  - يظهر CTA لكن عند الفتح تظهر حالة `غير مدعوم حاليًا`
  - ولا يبدأ handoff

---

## Waselni Sheet Design
المحتوى:
1. `من`
- موقعك الحالي أو `مركز المدينة (تقريبي)`

2. `إلى`
- اسم المكان

3. `Transport options`
- cards مرتبة

4. `Secondary action`
- `ابدأ الملاحة بنفسك`

## Quote Card Fields
- اسم الشريك
- نوع الخدمة
- السعر
- ETA
- مدة الرحلة
- badge:
  - `الأرخص`
  - `الأسرع`
  - `سعر تقديري`

## Required States
- loading skeleton
- no quotes
- no real location
- timeout
- offline
- partial provider failure
- quote expired

---

## Ranking Logic
الترتيب المعتمد:
1. cheapest
2. fastest
3. partner priority
4. quote freshness

ويُضاف tagging بصري:
- `الأرخص`
- `الأسرع`
- `موصى به`

---

## Timeout And Retry Strategy
## Provider Timeout
الحد الأقصى لكل provider في MVP:
- `5s`

## Aggregation Strategy
يجب استخدام:
- `Promise.allSettled`

حتى لا يفشل كل الطلب إذا provider واحد فشل.

## Retry Policy
في الـ server:
- لا retry غير محدود
- retry واحد داخلي فقط إذا كان الخطأ transient

في الـ client:
- زر `تحديث الأسعار`
- لا يوجد auto retry loop مزعج

---

## Caching Strategy
## Quote Cache
المعتمد:
- enabled
- `ttl = 120s`
- key تقريبي مثل:
  - `quotes:{venue_id}:{origin_geohash_6}`

## Cache Behavior
- `cache_hit`: return cached result إذا ما زالت صالحة
- `cache_miss`: fetch fresh
- إذا الكاش قريب من الانتهاء:
  - يمكن refresh بالخلفية لاحقًا، لكن ليس شرطًا في أول تنفيذ

## Storage Choice
لـ MVP:
- Firestore acceptable

Redis ليس مطلوبًا الآن.

---

## Analytics
لا تستخدم `navigation_clicks` لهذا المسار.

## Events
- `transport_quotes_opened`
- `transport_quotes_loaded`
- `transport_quotes_failed`
- `transport_quote_selected`
- `transport_handoff_started`
- `transport_handoff_failed`
- `transport_handoff_completed`
- `transport_handoff_abandoned`

## Required Dimensions
- `venue_id`
- `city`
- `source = venue_details`
- `partner_id`
- `service_type`
- `user_authenticated`
- `has_real_location`
- `quotes_count`
- `quote_source`
- `price_confidence`

---

## Security And Abuse Controls
## getTransportQuotes
- `App Check` required
- validate venue exists
- validate `transport_enabled == true`
- coordinate sanity checks
- distance sanity limit for MVP:
  - `<= 100km`
- rate limit by:
  - `uid`
  - or `deviceId`
- reject oversized payloads

## createTransportHandoff
- `App Check` required
- stronger rate limit
- no trust in client price
- validate quote freshness
- validate partner belongs to venue/city scope
- create record server-side only

## Firestore Rules
### `transport_handoffs`
- create: server only
- read: owner only
- update: server only

### `transport_partners`
- read: limited to safe public fields if needed
- write: admin/server only

### `transport_partner_rules`
- read/write: admin/server only

### `transport_quote_logs`
- create/write: server only
- read: admin/server only

## Required Security Tests
- quote spam
- origin tampering
- partner tampering
- stale quote reuse
- guest abuse via device reset
- inactive venue with transport enabled mismatch
- large payload abuse
- replay on handoff callable

---

## Secrets And Configuration
المعتمد:
- `Secret Manager only`

القواعد:
- لا أسرار في Git
- لا أسرار في `.env` committed
- لا اعتماد على `functions.config()`
- مفاتيح الشركاء وwebhooks وdistance services تبقى في secret manager فقط

أمثلة أسرار محتملة:
- `PARTNER_API_KEY_*`
- `DISTANCE_API_KEY`
- `TRANSPORT_WEBHOOK_SECRET`

---

## Feature Flags
الميزة يجب أن تكون خلف feature flags من أول يوم.

المستويات المقترحة:
- global flag:
  - `transport_enabled_global`
- city flag:
  - `transport_enabled_cities`
- partner flag:
  - `transport_partner_enabled:{partnerId}`

هذا ليس optional.

---

## Offline Handling
## MVP Minimum Behavior
- عند فتح `وصلني` بدون اتصال:
  - رسالة `يتطلب اتصال بالإنترنت`
  - وتبقى actions الحالية متاحة:
    - `Call`
    - `WhatsApp`
    - `Navigate`

- عند فقد الاتصال أثناء تحميل quotes:
  - error state + `إعادة المحاولة`

- عند فقد الاتصال بعد تحميل quotes:
  - يمكن عرض آخر quotes المحمّلة فقط إذا لم تنته صلاحيتها
  - وإلا نمنع handoff ونطلب refresh لاحقًا

---

## Observability
الحد الأدنى المطلوب قبل pilot:
- success rate for quote loading
- success rate for handoff start
- provider timeout rate
- average quote latency
- empty result rate
- top selected partner

ويجب تحديد alerts بسيطة على:
- quote failure spike
- provider outage
- latency spike

---

## Merchant And Admin Scope
## Merchant
في الـ MVP لا يوجد merchant self-management لهذه الميزة.

## Admin
نحتاج فقط:
- تفعيل/تعطيل transport على المكان
- ربط partners بالمكان أو المدينة
- ضبط pricing rules إذا كانت managed
- تعطيل partner أو منطقة

---

## Compliance
إذا كانت الميزة تتضمن مشاركة موقع أو handoff لشريك خارجي، يجب قبل pilot:
- تحديث privacy policy
- تحديث Data Safety على Android إذا لزم
- تحديث App Privacy على iOS إذا لزم

هذا blocker للـ pilot، وليس blocker للتطوير.

---

## Rollout Plan
## Phase 0: Discovery And Decision Gate
المدة: `3-5` أيام

المطلوب إغلاقه قبل الدخول في الكود:
- نوع الشريك الأول:
  - `API` أو `Managed`
- أول مدينة
- أول partner
- currency
- commission model المبدئي
- نصوص الـ handoff القانونية/التجارية إذا لزم

## Gate Criteria
لا نبدأ Phase 1 قبل حسم:
- [ ] Provider type
- [ ] First city
- [ ] First partner
- [ ] Currency
- [ ] Commission approach

## Phase 1: Backend Foundation
المدة: `5-7` أيام

المخرجات:
- schema
- `getTransportQuotes`
- `createTransportHandoff`
- provider adapter abstraction
- managed pricing fallback
- logging
- rate limiting
- feature flags

## Phase 2: Venue Details UX
المدة: `4-6` أيام

المخرجات:
- `وصلني` CTA card
- quotes sheet
- loading/empty/error states
- localization
- no-real-location UX

## Phase 2.5: Integration Testing
المدة: `2-3` أيام

المخرجات:
- end-to-end verification
- mock provider testing
- timeout/failure scenarios
- client/server integration fixes

## Phase 3: Handoff
المدة: `3-5` أيام

المخرجات:
- deep link / WhatsApp / phone handoff
- handoff records
- analytics wiring

## Phase 4: Hardening
المدة: `3-4` أيام

المخرجات:
- transport security test plan
- abuse tests
- replay/rate-limit tests
- provider failure tests
- quote expiry tests

## Phase 5: Pilot
المدة: `5-10` أيام

المخرجات:
- city-limited rollout
- one or two partners max
- quote accuracy review
- provider performance review
- support issue review

## Realistic Total
- `22-35` يوم عمل تقريبًا

---

## Acceptance Criteria For MVP
1. المستخدم يرى CTA `وصلني` داخل `Venue Details`
2. المستخدم يستطيع جلب quotes من موقعه أو من city fallback الواضح
3. الأسعار التقديرية معلمة بوضوح
4. quotes المنتهية لا تُستخدم
5. handoff يبدأ بنجاح عند اختيار quote صالحة
6. السعر لا يمكن tamper به من client
7. كل flow مسجل analytics بشكل مستقل
8. الميزة لا تكسر:
- `Call`
- `WhatsApp`
- `Navigate`

---

## Open Decisions Remaining
هذه ليست تناقضات في الخطة، بل قرارات business/ops يجب إغلاقها قبل Phase 1:
1. من هو الشريك الأول فعليًا؟
2. هل البداية `API` أم `Managed`؟
3. ما المدينة الأولى؟
4. ما نموذج العمولة قبل pilot؟
5. هل نحتاج wording/terms خاصة بالشريك؟

---

## Implementation Targets
## Client
- `lib/features/venue/presentation/screens/venue_details_screen.dart`
- `lib/features/transport/data/`
- `lib/features/transport/domain/`
- `lib/features/transport/presentation/`

## Backend
- `functions/src/transport.ts`
- `functions/src/index.ts`

## Rules
- `firestore.rules`

## Docs
- transport security plan
- API contract
- event dictionary
- rollout playbook

---

## Pre-Implementation Checklist
### Decisions
- [ ] Provider type decided
- [ ] First city selected
- [ ] First partner identified
- [ ] Currency confirmed
- [ ] Commission approach documented

### Technical
- [ ] Quote expiry contract approved
- [ ] Feature flags design approved
- [ ] Analytics events approved
- [ ] Rate limiting policy approved
- [ ] Secret Manager naming defined

### Documentation
- [ ] API contract drafted
- [ ] Data model reviewed
- [ ] Error codes list drafted
- [ ] Pilot scope documented

---

## Final Recommendation
النسخة الصحيحة للتنفيذ الآن هي:
- `Waselni = transport quotes + handoff from venue details`

ولا ننصح بتوسيعها في النسخة الأولى إلى booking platform كاملة.

هذا المسار:
- ينسجم مع التطبيق الحالي
- يحافظ على UX الحالي
- يضيف قيمة مباشرة بعد discovery
- ويبقي المخاطر التقنية والتشغيلية ضمن حدود واقعية
