# الخطة الشاملة: لوحة أدمن ويب لتطبيق WAIN

## 1. الهدف

بناء **لوحة أدمن ويب مستقلة** تغطي التشغيل اليومي لتطبيق WAIN بدون الاعتماد على Firebase Console، مع إعطاء الأولوية للعمليات المالية والتشغيلية عالية الحساسية قبل التوسع إلى بقية وحدات النظام.

اللوحة يجب أن:

- تدير المحافظ، طلبات الشحن، العكس المالي، والجاهزية التشغيلية.
- تدير المحتوى المرتبط بالمحال: الصور، العروض، الستوري، المراجعات، والساعات والمنيو.
- توفر تقارير وطبقات قراءة واضحة للأدمن.
- تفرض الصلاحيات والحوكمة على مستوى الواجهة والـ backend والقواعد.
- تبقى كل العمليات الحساسة **server-side only** عبر Cloud Functions أو أوامر مكافئة.

## 2. ما هو داخل النطاق وما هو خارجه

### داخل النطاق

- Finance Ops
- Wallet Audit
- Reversals
- Top-up review
- Venue directory
- Venue workspace
- Media center
- Offers/Stories/Reviews moderation
- Admin analytics and readiness
- System config management
- Incident operations

### خارج النطاق في V1

- بناء لوحة BI معقدة أو dashboards تنفيذية ضخمة
- تعديل منطق المحفظة المالي الموجود
- بناء نظام دردشة أو inbox كامل داخل اللوحة
- دعم multi-currency
- replacement لأي flows موجودة في تطبيق التاجر إذا لم تكن إدارية بحتة
- export/PDF تنفيذي واسع للتقارير غير المالية خارج النطاق في V1، بينما export مالي محدود ومقيّد role-wise يدخل ضمن الوحدات التشغيلية فقط

## 3. القرار التقني

### القرار المعتمد

**React + Next.js** هو الخيار الافتراضي المعتمد للوحة الأدمن.

### سبب القرار

- مناسب أكثر للجداول الكبيرة، الفلاتر، الفرز، التصدير، وواجهات التشغيل اليومي.
- أكثر راحة في بناء admin workflows كثيفة القراءة والبحث.
- أقل مخاطرة من Flutter Web في شاشات مثل:
  - Wallet Audit
  - Top-Up Review Queue
  - Venue Directory
  - Audit Events

### استثناء مسموح

يمكن استخدام **Flutter Web** فقط إذا:

- الفريق Flutter-only
- وتم بناء prototype مثبت الأداء على:
  - جدول wallet audit يحتوي 1000+ صف
  - filters + pagination + sorting
  - بدون تدهور ملحوظ في الاستجابة

إذا لم يتحقق هذا الشرط، لا يبدأ التنفيذ بـ Flutter Web.

## 4. الافتراضات التشغيلية

- يوجد backend حالي مبني على Firebase:
  - Firestore
  - Storage
  - Auth
  - Cloud Functions
- نظام المحفظة الحالي مكتمل ويعمل في soft launch.
- الـ admin panel الجديدة ستبنى فوق البنية الحالية دون إعادة كتابة المنطق المالي.
- الفريق المستهدف للتنفيذ:
  - 1 frontend web engineer
  - 1 backend/Firebase engineer
  - 1 owner/ops reviewer جزئي

## 5. مبادئ التنفيذ الحاكمة

1. **المنع الافتراضي**
   - لا صلاحية لأي عملية إلا إذا تم التصريح بها صراحة.

2. **كل العمليات الحساسة عبر أوامر خادمية**
   - approve / reject
   - reversal
   - featured / promoted state changes
   - config publish
   - admin role changes

3. **الـ ledger يبقى append-only**
   - لا تعديل مباشر على historical entries.
   - أي تصحيح مالي عبر compensating entries فقط.

4. **الحوكمة قبل التوسع**
   - لا ننتقل من Finance Ops V1 إلى بقية الوحدات قبل إغلاق RBAC وidempotency وconfig governance.

5. **التشغيل اليومي أهم من كثرة الشاشات**
   - نبني أقل عدد من الوحدات التي تسمح للأدمن بالعمل بثقة.

## 6. RBAC ومصدر الحقيقة

### مصدر الحقيقة النهائي

- **Firebase Custom Claims** هي المصدر الأساسي.
- `admins/{uid}` يبقى fallback انتقاليًا فقط لتوافق الأنظمة الحالية عندما تكون الـ claim المطلوبة **غير موجودة أصلًا**.

### قاعدة الحسم عند التعارض

- إذا وُجدت الـ claim المطلوبة وكانت تسمح بالفعل، يعتمد القرار على الـ claim.
- إذا لم توجد الـ claim أصلًا، يمكن استخدام `admins/{uid}` كـ fallback انتقالي.
- إذا وُجدت claim وfallback doc مع تعارض صريح:
  - **Fail closed**
  - تُرفض العملية الحساسة
  - يُكتب audit event باسم `rbac_conflict_detected`
- لا يسمح بأي fallback يتجاوز claim صريحة مقيّدة أو ناقصة.

### الصلاحيات الأساسية

| الدور | الوحدات المسموحة |
| --- | --- |
| `super_admin` | كل شيء |
| `finance_admin` | top-ups, wallets, audit, reversals, finance reports, readiness |
| `content_admin` | venues, offers, stories, photos, reviews |
| `support_admin` | users, merchant linking, incidents, support case views, wallet visibility للقراءة فقط عند الحاجة التشغيلية الموثقة وبدون approve/reject/reversal/export مالي |
| `ops_viewer` | read-only dashboards, audit, readiness, reports |

### Policy Matrix مطلوبة

يجب إنشاء وثيقة منفصلة أو section ثابت يربط:

- role -> screens
- role -> commands
- role -> collections/read models
- role -> sensitive actions
- role -> escalation / approval authority

### Policy Matrix كآلية تنفيذ

لا تبقى Policy Matrix وثيقة وصفية فقط، بل تتحول إلى:

- مصدر واحد للمراجعة والتدقيق
- مرجع لاختبارات RBAC
- gate في CI يمنع دمج:
  - شاشة حساسة جديدة
  - callable حساس جديد
  - export مالي جديد
  بدون سطر سياسة واضح واختبار مطابق

### قواعد التنفيذ

- UI route guard فقط ليس كافيًا.
- كل callable حساس يجب أن يتحقق من الدور.
- Firestore Rules وStorage Rules يجب أن تدعم نفس السياسة.
- أي عملية لا يوجد لها سطر صريح في Policy Matrix تعتبر **ممنوعة افتراضيًا**.

## 7. الوحدات الرئيسية

### 7.1 Dashboard (MVP فقط)

يعرض بطاقات تشغيلية محدودة:

- pending top-up count
- aged pending top-ups
- reversals today
- low-balance merchants
- readiness WARN/FAIL
- expiring promotions / featured offers

**ممنوع** تحويله إلى لوحة ضخمة في V1.

### ميزانية الأداء للشاشات الثقيلة

يجب تثبيت Performance Budget من Phase 0 للشاشات التالية:

- `Wallet Audit`
- `Top-Up Review Queue`
- `Venue Directory`
- أي شاشة export أو filter كثيف

والحد الأدنى الذي يجب تعريفه:

- زمن الفتح الأولي
- زمن تطبيق filter
- زمن الانتقال بين الصفحات
- الحد الأعلى لحجم export قبل التجزئة أو المعالجة الخلفية

### 7.2 Top-Up Review Queue

- عرض كل `merchant_topup_requests` pending
- عرض proof image
- approve / reject
- admin note
- SLA indicator
- conflict-safe handling إذا تم تغيير الحالة من أدمن آخر

### 7.3 Wallet Audit

- قراءة ledger
- فلترة حسب:
  - venue
  - date range
  - type
  - feature key
  - reviewer
- ربط:
  - top-up request
  - linked entry
  - reversal
  - notification
- export CSV مالي محدود ومقيد على:
  - `finance_admin`
  - `super_admin`

### 7.4 Reversals Console

- read-only list للقيود القابلة للعكس
- reversal dialog
- reason enum + note optional
- إظهار row معكوسة بوضوح
- four-eyes approval عند تجاوز threshold

### 7.5 Venue Directory

- قائمة كل المحلات
- search by name / city / category
- readiness / wallet status / merchant link summary

### 7.6 Venue Workspace

Tabs مرحلية:

- wallet
- offers
- stories
- reviews
- photos
- hours
- menu
- analytics

**لن تُبنى كلها في أول release**.

### 7.7 Media Center

- proof images
- venue photos
- offer images
- story images
- replace / soft delete / quarantine / purge

### 7.8 Users & Merchant Linking

- user lookup
- merchant lookup
- venue link verification
- repair flows via server command only
- dry-run preview قبل التنفيذ

### 7.9 System Config

إدارة:

- `wallet_feature_pricing/default`
- low-balance defaults
- reminder windows
- feature flags التشغيلية

لكن عبر:

- Draft
- Review
- Publish
- Rollback snapshot

### 7.10 Operational Readiness

- عرض `verifyWalletOperationalReadiness`
- PASS / WARN / FAIL
- failureChecks
- warningChecks
- links مباشرة إلى runbooks

### 7.11 Incident Console / Runbooks

- incident classes
- kill switches
- owners
- quick links إلى rollback/runbook/checklists

## 8. الضوابط الحرجة

### 8.1 الأوامر المالية

كل أمر مالي إداري يجب أن يلتزم بـ:

- `command_id` إلزامي وموحد عبر كل القنوات
- transaction-safe state recheck
- fail on stale state
- audit event واضح
- conflict-safe UX

### عقد command موحد

كل أمر حساس يجب أن يحمل على الأقل:

- `command_id`
- `actor_uid`
- `actor_role`
- `action`
- `target_type`
- `target_id`
- `expected_state`
- `reason`
- `correlation_id`
- `submitted_at`

### سلوك replay وdouble-submit

- إعادة إرسال نفس `command_id`:
  - تعيد نفس النتيجة السابقة
  - لا تكرر التنفيذ
- `command_id` جديد على target تغيّرت حالته:
  - `409 conflict`
  - بدون أي partial write
- يطبق هذا على:
  - `approve_topup`
  - `reject_topup`
  - `reverse_wallet_entry`
  - `publish_config`

### تعريف `expected_state`

القاعدة العامة:

- `status` إلزامية دائمًا
- القيم الرقمية والحقول الثانوية تُضاف فقط عندما يكون تغيّرها مؤثرًا على صحة الأمر

التعريف الأولي لكل أمر:

| الأمر | الحد الأدنى في `expected_state` |
| --- | --- |
| `approve_topup` | `status = pending` + `decision_state = unreviewed` |
| `reject_topup` | `status = pending` + `decision_state = unreviewed` |
| `reverse_wallet_entry` | `entry_status = posted` + `reversal_state = not_reversed` + `entry_type = debit` |
| `publish_config` | `draft_status = reviewed` + `target_live_version = current_live_version` |

أي توسيع إضافي على `expected_state` يجب أن يبرر بتقليل مخاطر السباق، لا بزيادة التعقيد فقط.

### 8.2 الموافقة المزدوجة

مطلوبة لـ:

- بعض reversals
- أي config publish يمس pricing أو thresholds أو reminder windows

### مصفوفة الموافقة المزدوجة الأولية

| العملية | مستوى المخاطرة | الموافقة المطلوبة |
| --- | --- | --- |
| approve/reject top-up | قياسي | `finance_admin` واحد |
| reversal `<= 100 ILS` | منخفضة-متوسطة | `finance_admin` واحد + reason معياري |
| reversal `> 100 ILS` و`<= 500 ILS` | عالية | submit من `finance_admin` + approve من أدمن ثانٍ |
| reversal `> 500 ILS` | عالية جدًا | `super_admin` أو موافقة ثنائية أحدها `super_admin` |
| publish config مالي | عالية | reviewer + publisher مختلفان |

هذه المصفوفة **initial policy** ويجب تثبيتها نهائيًا في Phase 0 بعد اعتماد المالك التشغيلي.

### State machine أولية للموافقة المزدوجة

لحالات `reversal` التي تحتاج موافقة ثانية:

1. `drafted`
2. `pending_second_approval`
3. `approved_and_executed`
4. `rejected`
5. `expired`
6. `cancelled_by_requester`

### قواعد التشغيل

- عند رفع reversal فوق الحد المطلوب:
  - لا تنفذ ماليًا مباشرة
  - تُنقل إلى queue خاصة باسم `pending_second_approval`
- إشعار الأدمن الثاني في V1:
  - يظهر داخل queue مخصصة في اللوحة
  - ولا يعتمد على email كقناة أساسية في أول نسخة
- timeout policy الأولية:
  - `48 ساعة` ثم تتحول الحالة إلى `expired`
- cancellation policy:
  - الأدمن الذي أنشأ الطلب يستطيع الإلغاء ما دامت الحالة `pending_second_approval`
- أي انتقال حالة يكتب audit event مستقل

### 8.3 Config Governance

أي إعداد مالي أو تشغيلي حساس لا يكتب مباشرة إلى live doc.

المسار الصحيح:

1. Draft
2. Validation
3. Review
4. Publish
5. Audit old/new values
6. Rollback snapshot

### ضوابط النشر

- لا يوجد publish مباشر بدون pre-publish validation
- يجب إظهار impact preview قبل الاعتماد:
  - الحقول التي ستتغير
  - القيم القديمة والجديدة
  - أي thresholds أو prices متأثرة
- النشر يتم على مرحلتين:
  - `staged/canary publish` إذا كان ذلك مدعومًا في الإعداد المستهدف
  - ثم verification
  - ثم full publish
- أي فشل في verification بعد النشر يفعل rollback فوري إلى آخر snapshot صالحة

### 8.4 Media Lifecycle

السياسة المطلوبة:

1. soft delete
2. quarantine window
3. reference check
4. hard purge

ولا يسمح بحذف فوري مباشر لملف قد يكون referenced.

### قيد الحذف النهائي

- لا يسمح بـ `purge` إذا لم ينجح reference check
- نتيجة reference check تُحفظ في audit
- إذا كانت حالة `media_reference_index` غير صحية أو stale:
  - يسمح فقط `soft delete`
  - يمنع `purge`

### 8.5 Read Model Freshness

لكل read model يجب تعريف:

- source of truth
- update mode
- freshness target
- rebuild path
- health signal

### مراقبة صحة الـ read models

يجب أن توجد طبقة observability واضحة لـ:

- نجاح/فشل writer أو trigger
- `last_successful_build_at`
- عدد المحاولات الفاشلة
- زمن التأخر عن freshness target

وأي read model تتجاوز freshness target يجب أن:

- تُظهر badge `stale` أو `failed`
- تُرسل إشارة تشغيلية مناسبة إذا تجاوزت حدًا متفقًا عليه

### 8.6 عقود الشاشات

كل شاشة تشغيلية يجب أن تُعرّف صراحة:

- source of truth
- read model المستخدمة إن وجدت
- freshness target
- السلوك عند التأخر أو الفشل
- health indicator المعروض للأدمن

أمثلة إلزامية:

| الشاشة | المصدر | freshness target | السلوك عند التأخر |
| --- | --- | --- | --- |
| Top-Up Review Queue | `merchant_topup_requests` | near-real-time | banner تحذيري + منع bulk actions إذا كانت الصحة غير موثوقة |
| Wallet Audit | `merchant_wallets/{venueId}/entries` + `wallet_audit_events` | near-real-time | banner فقط مع استمرار القراءة |
| Dashboard Summary | `admin_dashboard_summary` | 1-5 min | badge `stale`, بدون تعطيل الشاشة |
| Venue Workspace Summary | venue read models | 1-5 min | badge صحة ظاهر على كل tab |
| Media Center | `media_reference_index` | near-real-time | منع `purge` عند stale/failed |

## 9. الـ read models المطلوبة

### الموجودة حاليًا

- `merchant_wallet_reports/{venueId}`
- `wallet_audit_events/{eventId}`

### المضافة إذا لزم

- `admin_dashboard_summary`
- `queue_sla_snapshots`
- `config_publish_history`
- `media_reference_index`

### الهدف من كل واحدة

| read model | الهدف | freshness target |
| --- | --- | --- |
| `merchant_wallet_reports` | wallet KPIs per venue | near-real-time |
| `wallet_audit_events` | linked admin trace | near-real-time |
| `admin_dashboard_summary` | dashboard counters | 1-5 min |
| `queue_sla_snapshots` | top-up and ops aging | 1-5 min |
| `config_publish_history` | config audit trail | immediate |
| `media_reference_index` | asset reference safety and delete eligibility | near-real-time |

### سياسة الصحة وإعادة البناء

لكل read model يجب توثيق:

- source of truth
- writer/updater
- rebuild command/path
- freshness target
- stale policy
- failure escalation owner
- required composite indexes إن وجدت

### عقود صحة إضافية

لكل read model يجب تحديد:

- هل يعتمد على trigger أم job مجدول
- ما هو الحد الذي يتحول بعده من `healthy` إلى `stale`
- ما هو الحد الذي يتحول بعده من `stale` إلى `failed`
- ما الإجراء التشغيلي عند الفشل:
  - banner فقط
  - تعطيل action حساس
  - escalation إلى owner

## 10. Audit Schema الموحد

كل event إداري يجب أن يلتزم بـ schema ثابت:

- `actor_uid`
- `actor_role`
- `action`
- `entity_type`
- `entity_id`
- `correlation_id`
- `reason`
- `before_summary` أو `before_hash`
- `after_summary` أو `after_hash`
- `timestamp`
- `correlation_status` عند الحاجة لربط سلسلة أوامر متعددة
- `source_surface` لتحديد ما إذا كان الأمر من web admin أو system automation

أمثلة actions:

- `topup_approved`
- `topup_rejected`
- `wallet_reversed`
- `config_draft_created`
- `config_published`
- `media_soft_deleted`
- `merchant_link_repaired`
- `rbac_conflict_detected`

### Audit retention وintegrity

يجب حسم السياسة التالية في Phase 0:

- مدة الاحتفاظ بسجلات التدقيق
- من يملك حق قراءتها
- من لا يملك حق تصديرها
- افتراضات سلامة السجل:
  - لا تعديل من UI
  - أي إعادة بناء أو معالجة لاحقة لا تلغي الأصل
- أي export أو قراءة موسعة لسجل التدقيق يجب أن تكون audited أيضًا

### Export Governance

أي export مالي أو تشغيلي حساس يجب أن يحدد:

- الأدوار المسموحة
- الأعمدة المسموحة
- ما إذا كان masking مطلوبًا
- الحد الأعلى لعدد الصفوف في export المباشر
- هل يحتاج background export بدلًا من inline export
- audit event مستقل لكل عملية export

## 11. Incident Model

### incident classes

- financial_integrity
- queue_backlog
- config_misconfiguration
- media_access_issue
- admin_auth_issue
- readiness_failure

### المطلوب لكل incident class

- owner
- backup owner
- first response SLA
- containment steps
- acknowledgment target
- mitigation target
- kill switch
- linked runbook

### قواعد المسؤولية التشغيلية

- لا يوجد incident class بدون owner مناوب واضح
- كل incident class يجب أن يحدد:
  - من يملك قرار الإيقاف
  - من يملك قرار الاستعادة
  - متى يتم التصعيد إلى `super_admin`

## 12. خطة التنفيذ المرحلية

### Phase Gates

لا يسمح بالانتقال من Phase إلى التالية إلا إذا:

- معايير القبول الحالية مكتملة
- لا توجد gaps حرجة مفتوحة في RBAC أو command model أو audit
- لا توجد read-models أساسية بحالة `failed`
- أي debt مقبول للمرحلة التالية موثق صراحة مع owner وموعد إغلاق

## Phase 0 - Governance Lock

### المخرجات

- Tech choice locked
- RBAC design locked
- Policy Matrix written
- financial command model locked
- config governance locked
- reversal dual-approval threshold locked
- read-model freshness table locked
- incident classes and owners locked
- deployment strategy locked
- session policy locked
- fallback removal criteria locked
- dual-approval state machine locked
- `expected_state` contracts locked per command
- current callable capability assessment completed
- required Firestore composite indexes identified
- performance budget locked للشاشات الثقيلة
- observability requirements locked للأوامر الحساسة وread models
- audit retention/integrity policy locked

### معايير القبول

- يوجد قرار تقني مكتوب ومعتمد
- يوجد Policy Matrix قابل للتنفيذ
- كل عمليات المال الحساسة لها command contract واضح
- تم حسم قاعدة التعارض بين claims وfallback doc
- تم حسم dual-approval matrix حسب نوع العملية
- تم حسم dual-approval state machine بما فيه queue وtimeout وcancellation
- تم حسم شكل `expected_state` لكل أمر حساس
- تم حسم config publish model بما فيه staged publish وrollback
- تم حسم عقود البيانات والصحة للشاشات الأساسية
- تم تحديد ما إذا كانت callables الحالية تحتاج refactor لدعم RBAC/idempotency/command model
- تم تحديد الـ composite indexes المطلوبة مسبقًا
- تم تحديد ميزانية الأداء للشاشات الثقيلة
- تم تحديد متطلبات observability للأوامر الحساسة وread models
- تم تحديد سياسة audit retention/integrity
- لا يبدأ أي كود قبل إغلاق هذه المرحلة

## Phase 1 - Foundation & RBAC Shell

### المخرجات

- admin auth shell
- role-aware routing
- layout
- base navigation
- permission helpers
- shared table/filter primitives
- session and claim-refresh handling

### معايير القبول

- غير الأدمن لا يدخل اللوحة
- route guards + backend checks متسقة
- شاشة protected واحدة تعمل end-to-end
- default deny مفعّل
- claims refresh وsession policy مطبقة على الأوامر الحساسة
- conflict UX محدد وواضح:
  - `409 conflict`
  - refresh state
  - retry decision only after explicit user action

## Phase 2 - Finance Ops V1

### المخرجات

- Top-Up Review Queue
- Wallet Audit
- Reversal Console
- Operational Readiness panel
- finance widgets الأساسية في الـ dashboard
- export CSV مالي محدود للـ ledger والـ top-up queue
- مؤشرات observability للأوامر المالية:
  - idempotency hits
  - `409 conflict`
  - denied actions
  - queue aging breaches

### معايير القبول

- approve/reject آمنة ضد التكرار
- reversal آمنة ومؤرشفة
- queue aging ظاهر
- readiness panel صحيحة
- كل أمر مالي يستخدم command model الجديد
- conflict handling واضح عند concurrent admin actions
- export المالي role-gated ولا يتاح لـ `ops_viewer` أو `support_admin`
- الإشارات التشغيلية الأساسية تظهر ويمكن مراقبتها بدون Firebase Console

## Phase 3 - Basic Venue Lookup + Workspace Core

### المخرجات

- venue directory
- venue search/filter
- workspace shell
- tabs:
  - wallet
  - offers
  - stories
  - reviews

### معايير القبول

- venue search يعرض النتائج ضمن زمن استجابة مقبول تشغيليًا
- tabs الأساسية تقرأ البيانات الصحيحة read-only فقط
- لا يوجد cross-venue action leakage
- wallet/offers/stories/reviews تعرض حالة الصحة والـ freshness بوضوح

## Phase 4 - Media Ops

### المخرجات

- proof viewer
- venue/offer/story image management
- soft delete workflow
- quarantine workflow
- reference check before purge

### معايير القبول

- لا يوجد hard delete مباشر من UI
- referenced assets لا تُحذف خطأً
- كل action إعلامي له audit
- `purge` ممنوع إذا كان `media_reference_index` غير صحي أو غير محدث

## Phase 5 - Content Ops

### المخرجات

- offers management
- stories management
- reviews moderation

### الفرق عن Phase 3

- `Phase 3`: قراءة سياقية داخل venue workspace
- `Phase 5`: أوامر إدارة وكتابة role-gated على المحتوى

### معايير القبول

- moderation reasons standardised
- actions role-gated
- protected derived fields لا تتعدل مباشرة من المتصفح

## Phase 6 - Analytics + Config

### المخرجات

- operational dashboard
- KPI widgets
- config draft/review/publish
- publish history

### معايير القبول

- dashboard خفيفة ووظيفية
- config validation صارمة
- publish/rollback audited

## Phase 7 - Hardening + Release

### المخرجات

- end-to-end tests
- concurrency coverage
- audit verification
- operator release checklist
- incident drill review

### معايير القبول

- لا duplicate processing
- no hidden direct writes
- no broken role escalation paths
- runbook قابل للاستخدام تحت الضغط

## 13. الأولوية الرسمية

لا يبدأ التنفيذ بـ:

- dashboard كبير
- media center كامل
- analytics متقدمة
- users linking repair flows

بل يبدأ فقط بـ:

1. Finance Ops V1
2. Readiness
3. Basic Venue Lookup

## 14. التقدير الزمني

على افتراض:

- 2 engineers
- sprint أسبوعين

| المرحلة | التقدير |
| --- | --- |
| Phase 0 | 3-5 أيام |
| Phase 1 | 1 sprint |
| Phase 2 | 1.5-2 sprint |
| Phase 3 | 1 sprint |
| Phase 4 | 1 sprint |
| Phase 5 | 1 sprint |
| Phase 6 | 1 sprint |
| Phase 7 | 1-1.5 sprint |

### إجمالي تقريبي

- **7 إلى 10 sprints**
- أو **14 إلى 20 أسبوعًا** حسب حجم الفريق وسرعة المراجعة التشغيلية والحاجة إلى hardening فعلي

### ملاحظة تقدير مهمة

- هذا التقدير يفترض أن جزءًا من callables الحالية يدعم RBAC أو idempotency بشكل جزئي
- إذا أظهر فحص Phase 0 أن:
  - `reviewMerchantTopUpRequest`
  - `reverseWalletEntry`
  - أو أوامر config الحالية
  تحتاج refactor أعمق من المتوقع، فإن الزيادة المرجحة ستكون داخل `Phase 2` أولًا

## 15. استراتيجية الاختبار

### backend

- callable tests
- rules tests
- config validation tests
- race condition/conflict tests
- idempotency tests
- RBAC conflict and claims/doc resolution tests
- observability signal coverage tests حيث يلزم

### web admin

- route guard tests
- permission rendering tests
- table/filter tests
- command dialog tests
- config workflow tests

### operational

- staging runbook
- incident rehearsal
- reversal threshold checks
- queue SLA smoke tests
- config publish canary/rollback rehearsal
- stale read model behavior checks
- performance budget checks للشاشات الثقيلة قبل الإطلاق

## 16. تعريف النجاح

تعتبر اللوحة ناجحة عندما:

- يستطيع الأدمن تشغيل Finance Ops يوميًا بدون Firebase Console
- الصلاحيات enforced على UI + backend + rules
- العمليات المالية الحساسة آمنة ضد التكرار والتسابق
- config cannot be broken from the panel
- audit trail كاملة وقابلة للبحث
- media deletion آمنة
- operators يملكون runbooks واضحة
- الدعم التشغيلي يعرف ownership وSLA وkill switches لكل incident class

## 17. القرار التنفيذي النهائي

- **نعم**: ابدأ بـ Admin Web V1
- **نعم**: ابدأ فقط بـ Finance Ops + Readiness + Basic Venue Lookup
- **لا**: لا تبنِ كل الوحدات دفعة واحدة
- **لا**: لا تبدأ التنفيذ قبل إغلاق Phase 0 الحوكمية

## 18. الخطوة التالية

الخطوة الصحيحة الآن ليست coding عشوائيًا، بل:

1. استخراج **Phase 0** كوثيقة تنفيذ مستقلة
2. حسم:
   - tech choice
   - RBAC source of truth
   - claims/doc conflict rule
   - command model
   - `expected_state` shape per command
   - dual-approval matrix
   - dual-approval state machine
   - config publish model
   - read-model freshness targets
   - session policy
   - export policy
   - composite indexes plan
   - callable refactor scope
   - deployment strategy
3. بعدها فقط يبدأ التنفيذ الفعلي

## 19. معايير أولية لإزالة fallback

الاتجاه المقترح في Phase 0:

- يُزال `admins/{uid}` fallback بعد:
  - sprint كامل من تشغيل claims بنجاح
  - التأكد أن كل admin uid يملك claim صحيحة
  - عدم وجود `rbac_conflict_detected` لمدة `7 أيام` متواصلة
  - اجتياز staging/ops verification بعد الإزالة في بيئة غير إنتاجية أولًا
