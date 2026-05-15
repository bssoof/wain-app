# Financial Incident Recovery Runbook

تاريخ الإنشاء: 2026-05-15  
النطاق: WAIN wallet / top-up / reversal / promoted story / offer pin  
Owner: QA Lead + Finance Owner + Technical Owner

هذا الـ runbook يتعامل مع أثر مالي وقع فعليًا. الهدف هو **compensation and reconciliation**، وليس الاعتماد على rollback وحده.

Rollback للكود أو Functions أو Firestore rules موثق في [خطة QA النهائية](./final-release-qa-plan-2026-05-15.md). هذا الملف يجيب عن سؤال مختلف: إذا تغيرت بيانات مالية في production بشكل خاطئ، كيف نوقف النزيف ونصحح ledger بدون حذف التاريخ؟

## 1. متى يُفعّل

فعّل هذا الـ runbook عند أي حالة من التالية:

- Wallet entry بمبلغ خاطئ أو `type` خاطئ.
- Duplicate credit/debit رغم وجود idempotency protections.
- Top-up أصبح `credited` بدون wallet credit entry.
- Reversal أصبح `approved_and_executed` بدون reversal entry، أو توجد reversal entry بدون request مكتمل.
- Audit event مفقود لعملية مالية فعلية.
- `available_balance` لا يطابق آخر `balance_after` في ledger.
- أي شكوى تاجر عن رصيد غير صحيح بعد عملية مالية.

## 2. أول 5 دقائق: Triage

1. افتح incident ticket واحد، ولا تعالج عبر محادثات متناثرة.
2. حدّد scope مبدئي:
   - venue واحد
   - عدة venues
   - كل النظام
3. اجمع identifiers:
   - `venueId`
   - `requestId`
   - `entryId`
   - `uid`
   - timestamp تقريبي
4. شغّل verifiers في وضع read-only:

```powershell
node scripts/qa-verify-finance.mjs --project=wain-d2e28 --venue=<venueId> --allow-live --strict
node scripts/qa-verify-audit-trail.mjs --project=wain-d2e28 --venue=<venueId> --allow-live --strict
```

5. احفظ output في:

```text
incidents/<YYYYMMDD-HHmm>-<short-title>/
```

إذا الـ issue واسع أو غير مفهوم خلال 5 دقائق، صعّده كـ P0.

## 3. أول 15 دقيقة: Containment

لا تبدأ بتعديل ledger قبل احتواء المسار المتضرر.

إذا الخطأ في callable محددة:

```text
1. قيّم هل الخطأ widespread أم venue-specific.
2. إذا widespread:
   - deploy hotfix يجعل callable يرجع unavailable مؤقتًا.
   - أو redeploy آخر Functions commit مستقر.
3. إذا venue-specific:
   - ضع wallet status للـ venue كـ frozen/suspended إذا الكود يدعم ذلك.
   - أوقف المعالجة اليدوية لهذا venue حتى انتهاء التشخيص.
```

قواعد إلزامية:

- لا تحذف أي wallet entry.
- لا تعدّل `amount` في entry موجود.
- لا تعدّل `balance_after` في entry موجود.
- لا تعدّل audit event موجود.
- لا تستخدم PITR كحل أولي لحالة مالية منفردة.

## 4. Diagnosis

ابنِ timeline قبل التعويض.

اجمع:

```text
merchant_wallets/<venueId>
merchant_wallets/<venueId>/entries ordered by created_at
wallet_audit_events where venue_id == <venueId>
merchant_topup_requests where venue_id == <venueId>
wallet_reversal_requests where venue_id == <venueId>
related functions logs around incident time
```

سجّل في incident ticket:

```text
first_bad_timestamp:
affected_request_ids:
affected_entry_ids:
actor_uid:
actor_role:
function/callable:
expected_state:
actual_state:
```

بعد ذلك صنّف الخطأ حسب Section 5.

## 5. Compensation Procedures

كل compensation يحتاج موافقة شخصين:

```text
Finance Owner:
Technical Owner:
```

إذا كان المبلغ كبيرًا أو يؤثر على عدة تجار، أضف approval من Product/Founder.

### 5.1 Erroneous Credit

الحالة: المحفظة استلمت رصيدًا لا تستحقه.

الإجراء:

```text
1. لا تحذف credit entry.
2. أضف entry تعويضي بعكس الأثر:
   type: debit أو reversal حسب نموذج النظام المعتمد
   amount: نفس مبلغ credit الخاطئ
   reference_type: compensation
   reference_id: incident_<id>
   note: سبب واضح
   metadata.compensates_entry_id: <badEntryId>
   metadata.incident_id: <incidentId>
3. أضف wallet_audit_events event:
   category: compensation_reversal
   event_type: erroneous_credit_compensated
```

بعد الإضافة، شغّل verifiers.

### 5.2 Erroneous Debit

الحالة: المحفظة خُصمت دون استحقاق.

الإجراء:

```text
1. لا تعدّل debit entry الأصلي.
2. أضف credit entry:
   type: credit
   amount: نفس مبلغ الخصم الخاطئ
   reference_type: compensation
   reference_id: incident_<id>
   note: تعويض خصم خاطئ
   metadata.compensates_entry_id: <badEntryId>
   metadata.incident_id: <incidentId>
3. أضف wallet_audit_events event:
   category: compensation_reversal
   event_type: erroneous_debit_compensated
```

### 5.3 Duplicate Entry

الحالة: نفس العملية أثّرت مرتين على ledger.

الإجراء:

```text
1. حدّد entry الصحيح والـ duplicate entry.
2. لا تحذف الـ duplicate.
3. أضف entry تعويضي يعكس أثر الـ duplicate فقط.
4. علّم الـ duplicate عبر metadata فقط إذا كان ذلك لا يكسر الكود:
   metadata.is_duplicate = true
   metadata.duplicate_incident_id = <incidentId>
5. افتح bug منفصل للتحقيق في idempotency_key أو requestId.
```

### 5.4 Top-up Credited Without Ledger Entry

الحالة: `merchant_topup_requests/{id}.status == credited` لكن لا يوجد `linked_entry_id` صالح أو entry غير موجود.

الإجراء:

```text
1. تحقق من proof وقرار الأدمن.
2. إذا القرار صحيح:
   - أنشئ credit entry مطابق للطلب.
   - حدّث linked_entry_id في top-up request.
   - أضف audit event يوضح recovery=true.
3. إذا القرار غير صحيح:
   - لا تضف credit.
   - صحح status إلى rejected أو needs_review حسب الحالة.
   - أضف audit event recovery.
```

### 5.5 Reversal State Mismatch

الحالة: request منفّذ بدون reversal entry، أو reversal entry موجودة بدون request status صحيح.

الإجراء:

```text
1. إذا لا يوجد reversal entry:
   - أعد المحاولة من Admin UI إذا request ما زال صالحًا.
   - أو نفّذ compensation entry بعد موافقة شخصين.
2. إذا توجد reversal entry لكن status لم يتحدث:
   - لا تضف entry ثانية.
   - صحح status فقط بعد إثبات entry id.
3. أضف audit event recovery=true.
```

### 5.6 Missing Audit Event

الحالة: العملية المالية صحيحة في ledger لكن audit trail ناقص.

الإجراء:

```text
1. أضف audit event جديد ولا تعدّل event قديم.
2. استخدم created_at = وقت العملية الأصلية إذا معروف.
3. أضف:
   recovered_at: now
   recovery: true
   recovery_reason: <reason>
   incident_id: <incidentId>
```

### 5.7 available_balance Drift

الحالة: `merchant_wallets/{venueId}.available_balance` لا يطابق آخر `balance_after`.

الإجراء:

```text
1. احسب ledger chain من البداية.
2. تحقق يدويًا من كل entry حول أول mismatch.
3. إذا كل entries صحيحة:
   - حدّث available_balance فقط إلى آخر balance_after.
   - أضف audit event:
     category: balance_recovery
     event_type: available_balance_reconciled
4. إذا entries غير صحيحة:
   - لا تحدّث available_balance وحده.
   - عالج entry الخطأ بإجراء compensation مناسب.
```

## 6. Verification بعد التعويض

بعد أي تعديل:

```powershell
node scripts/qa-verify-finance.mjs --project=wain-d2e28 --venue=<venueId> --allow-live --strict
node scripts/qa-verify-audit-trail.mjs --project=wain-d2e28 --venue=<venueId> --allow-live --strict
```

النتيجة المطلوبة:

```text
fail=0
warn=0 أو warnings مفسّرة في incident ticket
```

إذا بقي أي failure:

```text
STOP.
لا تنفذ compensation ثاني عشوائي.
ارجع إلى Diagnosis وأعد بناء timeline.
```

## 7. Communication

### رسالة للتاجر

```text
مرحبًا،

رصدنا خللًا في عملية مالية أثّرت على رصيد محفظتك في وين.
تم إيقاف المسار المتأثر مؤقتًا ومراجعة سجل العمليات.

قمنا بتصحيح الرصيد عبر قيد تعويضي واضح في سجل المحفظة، دون حذف أي عملية سابقة، حتى يبقى السجل شفافًا وقابلًا للمراجعة.

الرصيد الحالي بعد التصحيح: <amount> ILS
رقم مرجع التصحيح: <incident_id>

نعتذر عن الإرباك، وسنشارك أي تفاصيل إضافية تحتاجها.
```

### رسالة داخلية للفريق

```text
Incident: <incident_id>
Severity: P0/P1
Affected venues:
Affected requests:
Affected entries:
Containment:
Current status:
Owner:
Next update:
```

## 8. Post-Incident

خلال 48 ساعة:

```text
1. اكتب postmortem في incidents/<incidentId>/postmortem.md.
2. وثّق root cause.
3. وثّق corrective action.
4. وثّق preventive action.
5. إذا verifier لم يلتقط المشكلة مبكرًا، أضف check جديد.
6. إذا rollback كان بطيئًا، حدّث خطة rollback.
```

## 9. ممنوعات

```text
ممنوع حذف wallet entry.
ممنوع تعديل amount في wallet entry موجود.
ممنوع تعديل balance_after في wallet entry موجود.
ممنوع تعديل audit event موجود.
ممنوع استخدام PITR كحل أولي لقيد مالي منفرد.
ممنوع تنفيذ compensation بدون موافقة Finance Owner و Technical Owner.
ممنوع إغلاق incident قبل مرور qa-verify-finance و qa-verify-audit-trail.
```

## 10. Templates

### Incident Report

```text
incident_id:
opened_at:
opened_by:
severity:
status:

summary:

affected_venues:
affected_users:
affected_requests:
affected_entries:

first_bad_timestamp:
detection_source:
containment_action:

financial_impact:
before_balance:
after_balance:
compensation_entries:

verification:
qa-verify-finance result:
qa-verify-audit-trail result:

approvals:
finance_owner:
technical_owner:
product/founder if needed:

root_cause:
corrective_action:
preventive_action:
```

### Audit Recovery Payload

```json
{
  "category": "balance_recovery",
  "event_type": "available_balance_reconciled",
  "venue_id": "<venueId>",
  "incident_id": "<incidentId>",
  "recovery": true,
  "recovery_reason": "<reason>",
  "actor_uid": "<adminUid>",
  "before_balance": 0,
  "after_balance": 0,
  "created_at": "<original-action-timestamp-if-known>",
  "recovered_at": "<now>",
  "updated_at": "<now>"
}
```

### Compensation Entry Metadata

```json
{
  "incident_id": "<incidentId>",
  "compensates_entry_id": "<badEntryId>",
  "compensation_reason": "<reason>",
  "approved_by_finance": "<uid>",
  "approved_by_technical": "<uid>"
}
```
