# Merchant Wallet Execution Plan

## Summary
- **Feature name**: `WAIN Credit` / `رصيد وين`
- **Scope**: نظام رصيد داخلي مغلق `closed-loop credit` للتاجر داخل WAIN فقط
- **Primary owner**: `venue` وليس `user`
- **First paid feature**: ترويج الستوري عبر callable `promoteStory`
- **Payment model**: تحويل بنكي يدوي + مراجعة أدمن + شحن رصيد داخلي
- **Storage model**: `wallet summary + immutable ledger`
- **Backend model**: `Cloud Functions + Firestore transactions`
- **Release strategy**: `backend-first`, ثم UI التاجر، ثم توسيع الاستخدام

## Product Decision
هذه الميزة ليست "محفظة بنكية" بالمعنى التنظيمي الكامل، بل هي `internal merchant credit system`.

هذا القرار مقصود لثلاثة أسباب:
- تجنب ربط البنوك وبوابات الدفع في مرحلة مبكرة.
- تقليل الاحتكاك مع التجار الذين لن يضعوا بطاقاتهم في تطبيق جديد.
- بناء بنية مالية داخلية قابلة للتوسعة لاحقًا إلى دفع إلكتروني رسمي.

## Goals
- تمكين التاجر من شحن رصيد داخلي واستخدامه في الميزات المدفوعة داخل التطبيق.
- منع الرصيد السالب أو الخصم المكرر أو التلاعب من الـ client.
- توفير سجل مالي واضح وشفاف لكل حركة.
- جعل أول تكامل مدفوع في المشروع هو `promoteStory`.
- إبقاء التصميم قابلًا للتوسعة لاحقًا لباقي الميزات المدفوعة.

## Non-Goals For V1
- لا `cash-out`.
- لا تحويل رصيد بين التجار.
- لا تحويل رصيد بين المستخدمين.
- لا دعم multi-currency في أول إصدار.
- لا بوابة دفع إلكترونية مباشرة.
- لا لوحة Admin كبيرة كشرط لإطلاق أول نسخة.

## Current Codebase Anchors
هذه الخطة مبنية على البنية الحالية للمشروع:
- التاجر مربوط حاليًا بالمحل عبر `users/{uid}.merchant_venue_id` و `merchants/{uid}.venue_id`.
- الترويج المدفوع الحالي موجود فعليًا في callable `promoteStory`.
- شاشة إدارة الستوري موجودة وتحتوي نقطة دخول واضحة لعملية الترويج.
- المشروع يستخدم `Firestore + Cloud Functions + Riverpod`.

ملفات الدمج الأساسية عند التنفيذ:
- `functions/src/index.ts`
- `firestore.rules`
- `lib/features/merchant/data/repositories/merchant_stories_repository.dart`
- `lib/features/merchant/presentation/screens/merchant_stories_screen.dart`
- `lib/features/merchant/presentation/providers/merchant_dashboard_providers.dart`
- ملفات جديدة داخل `lib/features/merchant` لطبقة المحفظة

## Core Product Rules
1. الرصيد يتبع `venueId` وليس `uid`.
2. كل خصم أو شحن يتم من الـ server فقط.
3. لا يوجد أي تعديل أو حذف على ledger entries بعد إنشائها.
4. أي تصحيح محاسبي يتم عبر entry جديدة من نوع `adjustment` أو `reversal`.
5. أي ميزة مدفوعة يجب أن تقرأ سعرها من مصدر server-side موحد.
6. لا يسمح بأي عملية تجعل الرصيد `available_balance < 0`.
7. كل عملية خصم أو شحن يجب أن تكون `idempotent`.

## Data Model

### 1. `merchant_wallets/{venueId}`
ملخص المحفظة الحالي. هذا المستند ليس المصدر المحاسبي النهائي، بل snapshot سريع للقراءة.

```ts
{
  venue_id: string,
  currency: "ILS",
  status: "active" | "suspended" | "closed",
  available_balance: number,
  low_balance_threshold: number,
  last_entry_at: Timestamp | null,
  last_top_up_at: Timestamp | null,
  created_at: Timestamp,
  updated_at: Timestamp
}
```

### 2. `merchant_wallets/{venueId}/entries/{entryId}`
الـ ledger الحقيقي. كل حركة مالية سطر مستقل غير قابل للتعديل.

```ts
{
  venue_id: string,
  type: "credit" | "debit" | "refund" | "adjustment" | "reversal",
  amount: number,
  currency: "ILS",
  balance_after: number,
  feature_key: string | null,
  reference_type: string | null,
  reference_id: string | null,
  idempotency_key: string,
  created_by_type: "system" | "merchant" | "admin",
  created_by_uid: string | null,
  note: string | null,
  metadata: map,
  created_at: Timestamp
}
```

### 3. `merchant_topup_requests/{requestId}`
طلبات شحن الرصيد المقدمة من التاجر.

```ts
{
  venue_id: string,
  requested_by_uid: string,
  amount: number,
  currency: "ILS",
  proof_image_url: string | null,
  transfer_reference: string | null,
  note: string | null,
  status: "pending" | "credited" | "rejected" | "cancelled",
  admin_note: string | null,
  reviewed_at: Timestamp | null,
  reviewed_by_uid: string | null,
  linked_entry_id: string | null,
  created_at: Timestamp,
  updated_at: Timestamp
}
```

### 4. `wallet_feature_pricing/default`
مرجع الأسعار المعتمد server-side.

```ts
{
  currency: "ILS",
  story_promote_1d: 3,
  story_promote_3d: 7,
  story_promote_7d: 14,
  updated_at: Timestamp,
  updated_by_uid: string | null
}
```

## Why Venue Wallet Instead Of User Wallet
- الميزات المدفوعة الحالية تخص المحل لا الشخص.
- قد يتغير المستخدم المرتبط بالمحل مستقبلًا، لكن الرصيد يجب أن يبقى للمحل.
- الربط التجاري الحالي في المشروع مبني حول `venue_id`.
- هذا يمنع تضارب الرصيد لو صار للحساب أكثر من مستخدم إداري لاحقًا.

## Ledger Rules
### Allowed Entry Types
- `credit`: شحن رصيد بعد تأكيد حوالة.
- `debit`: خصم مقابل ميزة مدفوعة.
- `refund`: إعادة مبلغ لخدمة لم تكتمل أو ألغيت.
- `adjustment`: تسوية يدوية من الأدمن.
- `reversal`: عكس محاسبي لحركة سابقة إذا حصل خطأ تشغيلي.

### Required Guarantees
- كل entry يجب أن تحتوي `balance_after`.
- كل entry يجب أن تحتوي `idempotency_key`.
- كل entry يجب أن تحتوي `created_by_type`.
- كل entry يجب أن ترتبط بمرجع واضح إذا كانت ناتجة عن feature أو top-up request.

## Top-Up Lifecycle
### User Flow
1. التاجر يفتح شاشة `رصيد وين`.
2. يختار `طلب شحن`.
3. يدخل المبلغ.
4. يرفع صورة الإيصال أو يضيف مرجع التحويل.
5. يرسل الطلب.
6. تظهر الحالة `قيد المراجعة`.

### Admin Flow
1. الأدمن يراجع الطلب والتحويل البنكي.
2. إذا ثبت التحويل:
   - يتم إنشاء `credit entry`.
   - يتم تحديث `merchant_wallets/{venueId}`.
   - يتم تحديث الطلب إلى `credited`.
3. إذا رُفض:
   - يتم تحديث الحالة إلى `rejected`.
   - يسجل السبب في `admin_note`.

### Lifecycle Decision
في `V1` لا نستخدم `approved -> completed`.
نستخدم فقط:
- `pending`
- `credited`
- `rejected`
- `cancelled`

هذا يقلل التعقيد ويجعل الحالة النهائية أوضح.

## Wallet Service Contract
كل العمليات تمر من خدمة server-side واحدة. لا يحق لأي شاشة أو repository أن تخصم من Firestore مباشرة.

### Required Functions
- `getWalletSummary(venueId)`
- `listWalletEntries(venueId, filters)`
- `createTopUpRequest(input)`
- `creditWallet(venueId, amount, context)`
- `debitWallet(venueId, amount, context)`
- `reviewTopUpRequest(requestId, decision, context)`
- `adjustWallet(venueId, amount, context)`

### Golden Rule
لا يوجد أي مكان في التطبيق يكتب مباشرة على:
- `merchant_wallets`
- `merchant_wallets/*/entries`

كل الكتابات تتم من Cloud Functions فقط.

## Callable / Backend Plan

### Merchant-Facing Callables
- `createMerchantTopUpRequest`
  - input: `amount`, `proofImageUrl?`, `transferReference?`, `note?`
  - auth required
  - derives `venueId` from merchant link
  - writes pending request

- `cancelMerchantTopUpRequest`
  - يسمح فقط بإلغاء الطلب إذا كان `pending`

- `promoteStory`
  - يبقى callable الحالي
  - لكن يتم توسيعه ليقرأ السعر ويخصم من المحفظة داخل transaction واحدة

### Admin-Only Callables
- `reviewMerchantTopUpRequest`
  - input: `requestId`, `decision`, `adminNote?`
  - إذا `decision=credit`:
    - validate request is pending
    - create credit ledger entry
    - update wallet summary
    - update request status to credited
  - إذا `decision=reject`:
    - update request status to rejected

- `adjustMerchantWallet`
  - لسيناريوهات استثنائية فقط
  - يكتب `adjustment entry`

## Pricing Strategy
في أول إصدار يكون السعر ثابتًا ومركزيًا:
- `story_promote_1d = 3 ILS`
- `story_promote_3d = 7 ILS`
- `story_promote_7d = 14 ILS`

التسعير لا يوضع داخل الـ client ولا hardcoded داخل أكثر من مكان.

## Story Promotion Paid Flow
هذا هو أول سيناريو مدفوع يجب دعمه end-to-end.

### Execution Flow
1. التاجر يختار مدة الترويج.
2. الـ client يعرض السعر المتوقع.
3. الـ client يستدعي `promoteStory`.
4. الـ backend ينفذ داخل transaction:
   - verify auth
   - verify merchant ownership
   - verify venue active
   - verify story belongs to venue
   - verify story not expired
   - resolve feature price
   - lock wallet doc
   - verify `available_balance >= price`
   - create `debit entry`
   - update wallet summary
   - update story promotion fields
   - write audit log
5. إذا الرصيد غير كاف:
   - لا يتم الترويج
   - يعاد خطأ `insufficient_wallet_balance`
6. الـ UI تعرض رسالة واضحة مع زر يذهب إلى شاشة المحفظة أو طلب الشحن.

### Required Error Codes
- `insufficient_wallet_balance`
- `wallet_not_found`
- `wallet_inactive`
- `story_expired`
- `venue_inactive`
- `permission-denied`

## Security Plan

### Firestore Rules
#### Merchant Reads
يسمح للتاجر المرتبط بالمحل بقراءة:
- `merchant_wallets/{venueId}`
- `merchant_wallets/{venueId}/entries/{entryId}`
- طلبات الشحن التابعة لنفس `venueId`

#### Merchant Writes
يسمح للتاجر فقط بـ:
- إنشاء `merchant_topup_requests`
- إلغاء طلب pending إذا تقرر دعم ذلك

#### Deny By Default
يمنع على الـ client:
- الكتابة على wallet summary
- الكتابة على ledger entries
- الموافقة أو الرفض أو التعديل المالي

### Auth Model
- كل callable للتاجر يحتاج `auth + app check`.
- كل callable للأدمن يحتاج `auth + admin role/custom claims`.

### Rate Limiting
- `createMerchantTopUpRequest`: حد يومي لتجنب spam.
- `reviewMerchantTopUpRequest`: محمي بدور الأدمن فقط.
- `promoteStory`: الاستمرار باستخدام النمط الحالي للحماية + audit log.

## Idempotency And Concurrency
هذه نقطة حرجة ويجب تنفيذها من أول يوم.

### Required Measures
- استخدام `Firestore transaction` لكل credit/debit.
- استخدام `idempotency_key` لكل عملية خصم أو شحن.
- في `promoteStory` يجب أن يكون المفتاح مرتبطًا بـ:
  - `storyId`
  - `durationDays`
  - `request attempt token` أو nonce منظم

### Why This Matters
بدون idempotency قد يحصل:
- ضغط الزر مرتين
- retry من الشبكة
- إعادة تنفيذ callable
- خصم مكرر على نفس العملية

## Merchant UI Plan

### 1. Wallet Summary Card
تضاف إلى لوحة التاجر وتعرض:
- الرصيد الحالي
- آخر حركة
- حالة الرصيد: `healthy`, `low`, `empty`
- زر `فتح الرصيد`

### 2. Wallet Screen
تعرض:
- الرصيد الحالي
- CTA لطلب شحن
- آخر الحركات
- رابط إلى السجل الكامل

### 3. Top-Up Request Screen
تعرض:
- إدخال المبلغ
- حقل مرجع التحويل
- رفع صورة الإيصال
- ملاحظة اختيارية
- نص واضح عن وقت المراجعة المتوقع

### 4. Transaction History Screen
تعرض:
- قائمة بكل `credit/debit/refund/adjustment`
- المبلغ
- الرصيد بعد الحركة
- الوقت
- الوصف

### 5. Top-Up Request History
تعرض:
- الطلبات السابقة
- الحالة
- ملاحظات الأدمن إن وجدت

### 6. Insufficient Balance State In Stories
داخل شاشة الستوري:
- عرض تكلفة الترويج قبل التأكيد
- إذا الرصيد غير كاف:
  - رسالة واضحة
  - CTA: `شحن الرصيد`

## Admin Operations Plan
في `V1` لا يشترط وجود Admin Panel كاملة.

### Recommended MVP
- مسار إداري داخلي محمي عبر callable أو script داخلي
- حسابات الأدمن فقط تملك:
  - review top-up requests
  - credit wallet
  - reject requests
  - manual adjustment

### Recommended SLA
- مراجعة الطلبات خلال أقل من `24 ساعة`
- يفضّل تشغيلية أولية خلال ساعات العمل نفسها

### Review Checklist
عند مراجعة طلب الشحن:
1. مطابقة المبلغ
2. مطابقة مرجع التحويل إن وجد
3. التحقق من الإيصال
4. التحقق من `venueId`
5. منع الشحن المكرر لنفس الطلب

## Notifications Plan
- عند إنشاء طلب شحن: إشعار للأدمن
- عند اعتماد الشحن: إشعار للتاجر مع المبلغ
- عند رفض الطلب: إشعار للتاجر مع السبب
- عند خصم ناجح: إشعار يوضح المبلغ والميزة
- عند انخفاض الرصيد عن `low_balance_threshold`: إشعار تذكيري

## Analytics And Audit
كل عملية مالية أو قرار إداري يجب أن ينتج `audit log`.

### Audit Events
- `createMerchantTopUpRequest`
- `reviewMerchantTopUpRequest`
- `adjustMerchantWallet`
- `promoteStory`

### Minimum Audit Fields
- `uid`
- `venueId`
- `requestId/referenceId`
- `amount`
- `result`
- `timestamp`

## Implementation Phases

### Phase 0: Foundations
**Goal**: تجهيز schema, rules, service contracts

#### Tasks
- إضافة collections الجديدة
- إضافة wallet types/constants
- إضافة pricing source
- تحديث Firestore rules
- إنشاء wallet service helper داخل functions

#### Acceptance
- لا client writes مباشرة على wallet data
- schema ثابت وواضح
- tests الأساسية للـ rules موجودة

### Phase 1: Top-Up Request Flow
**Goal**: تمكين التاجر من إرسال طلب شحن ومراجعته إداريًا

#### Tasks
- callable `createMerchantTopUpRequest`
- callable `reviewMerchantTopUpRequest`
- شاشة طلب شحن
- شاشة حالة الطلبات
- إشعارات approve/reject

#### Acceptance
- التاجر يستطيع إنشاء طلب
- الأدمن يستطيع اعتماد أو رفض الطلب
- اعتماد الطلب يولد credit ledger entry واحدة فقط

### Phase 2: Story Promotion Integration
**Goal**: ربط أول ميزة مدفوعة بالمحفظة

#### Tasks
- تعديل `promoteStory` ليخصم من المحفظة
- عرض تكلفة الترويج في UI
- معالجة insufficient balance
- تحديث dashboard invalidation بعد الخصم

#### Acceptance
- الترويج ينجح فقط إذا الرصيد كاف
- كل خصم يظهر في السجل
- لا double charge تحت retry/concurrency

### Phase 3: Wallet UX And Hardening
**Goal**: تحسين التجربة والاعتمادية

#### Tasks
- Wallet dashboard card
- transaction history screen
- low-balance banner
- admin adjustment flow
- reconciliation checks

#### Acceptance
- السجل واضح للتاجر
- الرصيد المُلخّص متطابق مع ledger
- حالات الفشل والرفض والرد واضحة

### Phase 4: Feature Expansion
**Goal**: إعادة استخدام نفس البنية لميزات أخرى

#### Candidates
- ترويج العروض
- تثبيت العروض
- boosting للظهور
- باقات مدفوعة

## Test Plan

### Emulator Tests
- create top-up request with valid merchant
- top-up request denied without auth
- top-up request denied without merchant link
- approve request creates exactly one credit entry
- reject request does not touch wallet balance
- approve same request twice does not double-credit
- debit with insufficient balance fails
- concurrent promoteStory requests do not overdraw wallet
- retry with same idempotency key does not duplicate debit
- refund writes correct balance_after
- suspended wallet blocks debit

### Firestore Rules Tests
- merchant can read own wallet
- merchant cannot read another venue wallet
- merchant cannot write wallet summary
- merchant cannot create ledger entries
- merchant can create own top-up request only
- non-admin cannot review requests

### Widget Tests
- wallet summary card renders balance
- insufficient balance state in stories screen
- top-up request form validation
- transaction list rendering
- low balance warning rendering

### Manual Tests
1. التاجر يقدم طلب شحن.
2. الأدمن يعتمد الطلب.
3. الرصيد يظهر محدثًا.
4. التاجر يروّج ستوري.
5. يتم الخصم مرة واحدة فقط.
6. الحركة تظهر في السجل.
7. عند نفاد الرصيد يظهر المسار الصحيح إلى الشحن.

## Risks And Mitigations

### Risk: Merchant Trust
- **Problem**: التاجر لا يثق بالشحن اليدوي.
- **Mitigation**: سجل حركات شفاف + حالات طلب واضحة + SLA واضح.

### Risk: Manual Ops Burden
- **Problem**: الشحن اليدوي يصبح عبئًا عند النمو.
- **Mitigation**: بناء ledger/service من البداية بشكل يسمح بإضافة بوابة دفع لاحقًا بدون إعادة تصميم.

### Risk: Double Charge
- **Problem**: ضغطات مكررة أو retries.
- **Mitigation**: transactions + idempotency keys + immutable ledger.

### Risk: Balance Drift
- **Problem**: summary لا يطابق ledger.
- **Mitigation**: reconciliation job أو check داخلي لاحقًا.

### Risk: Admin Abuse
- **Problem**: تعديل يدوي غير مضبوط.
- **Mitigation**: audit logs + adjustment reason + role restriction.

## Recommended Naming
- اسم المنتج: `رصيد وين`
- الاسم التقني: `merchant wallet`
- لا ينصح باستخدام كلمة "محفظة" وحدها في كل النصوص إذا كانت قد توحي بسحب وتحويل بنكي

## Done Criteria
- يوجد wallet per venue
- يوجد immutable ledger واضح
- يوجد top-up request flow كامل
- يوجد admin approval path
- `promoteStory` يخصم من الرصيد بأمان
- لا يوجد خصم مباشر من client
- جميع حالات insufficient balance تعمل
- الاختبارات الأساسية ناجحة
- السجل والرصيد ظاهرين بوضوح للتاجر

## Future Extensions
- ربط شحن تلقائي ببوابة دفع
- باقات شحن مع bonus credit
- تحويل من manual review إلى semi-automated reconciliation
- دعم أكثر من feature مدفوعة على نفس wallet service
- تقارير مالية للأدمن

## Final Recommendation
أفضل مسار للمشروع هو:
1. بناء `venue-based internal credit ledger`
2. تشغيله أولًا على `promoteStory`
3. إطلاقه مع review يدوي بسيط
4. التوسع بعد إثبات الاستقرار التشغيلي والمحاسبي

النجاح هنا لا يعتمد على شكل الواجهة بقدر ما يعتمد على صحة `ledger`, `transactions`, و `idempotency`.
