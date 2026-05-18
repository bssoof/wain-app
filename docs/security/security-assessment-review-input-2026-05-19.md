# WAIN Security Assessment Review Input

Date: 2026-05-19

Use this file to paste external or manual review notes for the WAIN security assessment plan.

Source plan:

- `docs/security/full-application-security-assessment-plan-2026-05-19.md`

## Review Source

Reviewer:

Review date:

Review type:

- [ ] Internal engineering review
- [ ] Security/AppSec review
- [ ] Compliance/governance review
- [ ] External consultant review
- [ ] Other:

## Raw Review Notes

Paste the full review here.

```text

```

## Key Decisions To Extract

Use this section after pasting the review.

| Decision / Recommendation | Accept / Reject / Needs Verification | Reason | Owner | Target file or artifact |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## Candidate Findings

Only add items here as candidates until they have evidence from code, tests, runtime behavior, or configuration.

| Candidate ID | Title | Proposed severity | Evidence needed | Verification status |
| --- | --- | --- | --- | --- |
|  |  |  |  | Needs verification |

## Plan Changes Requested

| Section | Requested change | Priority | Status |
| --- | --- | --- | --- |
|  |  |  | Not started |

## Follow-up Commands Or Evidence Needed

```powershell

```

## Final Triage Summary

To be filled after review triage:

- Accepted changes:
- Rejected changes:
- Findings promoted to confirmed:
- Findings closed as false positive:
- Required commits:
<aside>
🛡️

**WAIN — Defensive Application Security Assessment Report**

تاريخ: 2026-05-19  •  المنفّذ: AppSec Engineer (Notion AI)  •  المالك: basil khateeb  •  معايير: OWASP ASVS/MASVS/Top 10 + NIST SSDF/CSF + ISO 27001 Annex A

</aside>

<aside>
📌

**ملخص بطاقة الحالة (Status Banner)**

- **قرار الإصدار المبدئي:** ⛔ **No-Go مشروط (Conditional Go)** — يصبح Go بعد إغلاق Findings الـP0/P1 وإجراء Tabletop Drill واحدة.
- **عدد Findings الكلي:** 15 (P0=3 • P1=5 • P2=4 • P3=3)
- **المراجعة التالية:** بعد إكمال أسبوع W3-4 من Remediation Roadmap.
- **القاعدة الصارمة:** لا أكواد استغلال (Exploit Code) ولا خطوات هجوم فعلي — كشف وتحليل ومعالجة فقط.
</aside>

### معلومات التطبيق (App Profile)

| البند | القيمة |
| --- | --- |
| **نوع التطبيق** | Mobile Android — Flutter APK |
| **Stack التقني** | Flutter (Dart) + Firebase Auth + Firestore + Cloud Storage + Cloud Functions (Node/TS) + Admin Web Console (Next.js) |
| **البيئة** | مرشّح إنتاج (Production Candidate) |
| **حجم المستخدمين** | 1,000 – 50,000 |
| **البيانات الحساسة** | محافظ مالية + سجلات Ledger + صور إثبات تعبئة + PII (اسم/هاتف/إيميل/موقع) + بيانات أعمال للتجار |
| **Compliance رسمي** | لا يوجد حالياً (التزام طوعي بـOWASP/NIST/ISO كمرجع) |
| **تصنيف الخطورة** | P0 Critical / P1 High / P2 Medium / P3 Low — مع CVSS 3.1 Base Score |

### ✔️ شريط التحقق السريع (Quick Verification Strip)

- [ ]  Threat Model مكتمل ومُصادَق عليه
- [ ]  كل P0/P1 Findings مُغلقة
- [ ]  Checklist للمحاور الـ12 موقّعة
- [ ]  Remediation Roadmap مُعتمدة
- [ ]  Incident Response Drill واحدة على الأقل مُسجّلة
- [ ]  APK Production candidate خالٍ من Emulator config و Debug flags

---

# 🧠 1. THREAT MODEL مختصر

## 1.1 الأصول المعرضة للخطر (Assets)

| فئة الأصل | الأصول الرئيسية | الحساسية |
| --- | --- | --- |
| **مالية (Financial)** | أرصدة المحافظ، قيود Ledger، طلبات Top-up، طلبات Reversal، Audit Events | 🔴 حرجة |
| **هوية (Identity)** | حسابات Firebase Auth، Custom Claims، Session Tokens، Refresh Tokens | 🔴 حرجة |
| **PII** | اسم/هاتف/إيميل/موقع المستخدم، صور البروفايل | 🟠 عالية |
| **أصول تجار (Merchant)** | ملكية الـ Venue، Offers، Stories، Menu، تحليلات ومبيعات | 🟠 عالية |
| **ملفات حساسة** | صور إثبات التعبئة (Top-up Proofs) — حساسة مالياً | 🔴 حرجة |
| **بنية تحتية** | Cloud Functions، Service Accounts، Firestore Rules، Storage Rules، CI/CD secrets | 🔴 حرجة |
| **الإصدار (Release)** | APK الإنتاج، Play Signing Keys، dart-defines، Upload Keys | 🔴 حرجة |

## 1.2 المهاجمون المحتملون (Threat Actors)

- 🎭 9 نماذج مهاجمين موثّقة
    1. **مهاجم خارجي مجهول** — يحاول الوصول لـFirestore/Storage بدون مصادقة.
    2. **مستخدم عادي مصدّق (Authenticated User)** — يحاول قراءة/كتابة بيانات مستخدم آخر.
    3. **تاجر A ضد تاجر B (Cross-Tenant)** — أخطر سيناريو تجاري عبر Tenant Isolation.
    4. **Finance Admin يطمح لـSuper Admin** — Privilege Escalation داخلي.
    5. **عميل مُعدَّل (Modified Client)** — Flutter APK مُعاد بناؤه يتجاوز فحوصات UI.
    6. **Replay/Double-Submit Attacker** — يستهدف Top-up و Reversal.
    7. **مهاجم يملك APK** — يجري Reverse Engineering ويبحث عن Endpoints/أسرار.
    8. **Insider / Internal Misuse** — موظف بصلاحيات Firebase/GCP Console.
    9. **مهاجم Admin Web** — XSS/CSRF/Header Forgery على Admin Console.

## 1.3 أخطر سيناريوهات الهجوم (Top Attack Scenarios)

| # | السيناريو | الأصل المستهدف | الأثر |
| --- | --- | --- | --- |
| S1 | تزوير Audit Event أو تخطّيه لمعاملة مالية حقيقية | Ledger Integrity | 🔴 كارثي |
| S2 | Double Top-up Approval (نفس Request مرتين) | رصيد محفظة التاجر | 🟠 عالي مالياً |
| S3 | كتابة مباشرة لـLedger من العميل (تجاوز Functions) | Ledger Integrity | 🔴 كارثي |
| S4 | Finance Admin يوقّع نهائياً بدون Super Admin | Two-Person Rule | 🟠 عالٍ |
| S5 | Cross-Tenant Read: تاجر يقرأ Wallet/Proofs لتاجر آخر | سرية تجارية + PII | 🟠 عالٍ |
| S6 | تسريب مفتاح Service Account من Repo أو APK | كل الـbackend | 🔴 كارثي |
| S7 | Replay لـCallable Function برقم Idempotency معاد | ازدواج معاملة مالية | 🟠 عالٍ |
| S8 | Storage upload لمسار تاجر آخر أو إعادة كتابة Story | تشويش/تشويه | 🟡 متوسط-عالٍ |
| S9 | تسريب Token/PII في Logcat الإصدار | خصوصية مستخدم | 🟠 عالٍ |
| S10 | App Check معطّل أو يُعتمد عليه وحده دون Rules | تجاوز كامل | 🟠 عالٍ |

---

# ✅ 2. نقاط القوة في الخطة

<aside>
💪

الخطة تظهر **نضجاً هندسياً ملحوظاً** في عدة محاور — يُوثَّق ما هو مغطى لمنع تراجعه (regression).

</aside>

- **Release Gate صريح** — يحجب الإصدار على P0/P1، تجاوز Rules، تسريب أسرار، Emulator config في APK الإنتاج.
- **Safety Rules مُحكَمة** — تمنع الاختبارات الهدّامة على الإنتاج بدون إذن مكتوب وخطة Rollback.
- **Governance Addendum** — يحوي SLA لكل خطورة، وقواعد Risk Acceptance بانتهاء صلاحية ≤ 90 يوماً.
- **Control Traceability Matrix** — يربط كل اختبار بـWAIN Control + OWASP/NIST/ISO.
- **CI/CD Gates ملزمة** — Secrets / Flutter / Functions / Rules / Admin Web / Dependency Audit / APK Inspection.
- **Negative Testing Matrix شامل** — Firestore (14 حالة) + Storage (8 حالات).
- **Financial Abuse Tests (FIN-001 … FIN-012)** — تغطي Double Submit، Replay، Tampering، Drift.
- **Verifiers مؤتمتة** — `qa-verify-finance` و `qa-verify-audit-trail` مع شرط `fail=0 warn=0`.
- **Mobile Hardening Baseline** — يطلب قرارات صريحة (Obfuscation، Pinning، Root Detection، Screenshot Prevention).
- **Incident Response Drills** — مذكورة (Tabletop/Emulator drill قبل الإطلاق).
- **Evidence Discipline** — قوية: Hashes، before/after، logcat، function logs، screenshots، verdict.
- **Phase 0 (Freeze Target)** — يضمن أن كل الاختبارات تستهدف نفس Commit/Tag.

---

# ❌ 3. الثغرات والنواقص (Gaps)

<aside>
⚠️

أُدرج هنا 15 فجوة منهجية (G1 … G15) سيتم تحويل كل واحدة إلى Finding في قاعدة بيانات Findings، مع CVSS وRemediation وSLA.

</aside>

### G1 — تغطية MASVS Android غير صريحة

الخطة تذكر `MASVS-STORAGE/RESILIENCE` فقط، دون **MASVS-CRYPTO / MASVS-NETWORK / MASVS-PLATFORM / MASVS-CODE**. فجوة توافق مع OWASP MASVS L1/L2.

### G2 — غياب نمذجة تهديدات رسمية (STRIDE / LINDDUN)

الخطة تذكر "Threat Model" عموماً دون منهجية رسمية للأمان (STRIDE) أو الخصوصية (LINDDUN).

### G3 — App Check: قرار النشر غامض

"App Check enforced where required" — دون تحديد بالضبط أي callable/resource إلزامية وأيها Audit-only، ولا خطة Rollout (Enforce vs Unenforced).

### G4 — Play Integrity API غير مذكور

لتطبيق Android يتعامل بمال، الاعتماد على App Check وحده دون Play Integrity (Device + App Integrity) فجوة معروفة.

### G5 — Rate Limiting و Anti-Abuse غير مفصّل

ذكر عام لـ"rate limiting" دون آلية محددة (Cloud Armor / Functions limiter / Firestore counters).

### G6 — Backup & Restore Drill غير مُختبَر

يوجد Recovery Runbook، لكن لا يوجد اشتراط **Restore فعلي من Firestore Backups** قبل الإطلاق.

### G7 — Privacy by Design غير ممنهج رغم وجود PII

رغم عدم وجود Compliance رسمي، وجود PII (هاتف/موقع) و 50K مستخدم محتمل يستدعي: Retention Policy + Right-to-Delete + DSAR Workflow.

### G8 — Mobile Crash / Tamper Telemetry غير محدد

هل Crashlytics مدمج؟ هل يُفلتر PII تلقائياً؟ غير موثق.

### G9 — Insecure Deep Links على Android

ذكر "Deep links cannot open privileged screens" دون اشتراط **App Links Verification** (`autoVerify=true` + Digital Asset Links) ضد Intent Hijacking.

### G10 — WebView Security

إذا وُجدت شاشة `webview_flutter` (شروط/خصوصية/مساعدة)، لا يوجد فحص JS Bridge أو `setJavaScriptEnabled` أو File Access.

### G11 — Logging Sink Security: Firebase Logs Retention

Log Routing/Redaction/Retention على مستوى GCP Project غير معرّف، وقد تحوي Cloud Logs بيانات PII.

### G12 — Threat Intel للمكتبات

Dependency Audit يكتشف CVE معروف فقط؛ لا يوجد بند يفرض **مراقبة GitHub Advisory / Snyk** للحزم الحرجة.

### G13 — Penetration Test مستقل خارجي

غياب تام لذكر **Pen Test طرف ثالث** قبل الإصدار — Best Practice لتطبيق مالي حتى بدون إلزام تنظيمي.

### G14 — DPIA (Data Protection Impact Assessment)

حتى بدون GDPR رسمي، محافظ + موقع + 50K مستخدم يستحق DPIA خفيف.

### G15 — Bug Bounty / Responsible Disclosure

لا يوجد ذكر لقناة `security.txt` ولا سياسة Responsible Disclosure لما بعد الإطلاق.

---

# 🔴 4. الأولويات الحرجة (Critical Priorities)

<aside>
📋

كل Finding مُسجَّل كصفحة كاملة في **Findings DB** (أسفل هذه الصفحة) بصيغة الإطار المطلوب. هنا ملخص بصري للـP0 و P1 فقط.

</aside>

### 🔴 WAIN-F-001 — احتمال غياب فرض App Check + Play Integrity على Callables المالية

| **المشكلة** | قرار App Check غامض في الخطة، يفتح الباب لاستدعاء callable من عميل مزوّر/معاد بناؤه |
| --- | --- |
| **الخطورة** | 🔴 P0 Critical |
| **CVSS 3.1** | **8.6** (AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:L) |
| **السبب الجذري** | غياب اشتراط Enforce صريح + عدم تكامل Play Integrity في server-side |
| **التأثير** | تجاوز Functions مباشرة → معاملات مالية مزيفة + احتيال على Top-up/Reversal |
| **التوصية** | App Check Enforce لكل callable مالي + Play Integrity verification داخل Function (Device + App + Token Payload) |
| **الأولوية الزمنية** | ⏱️ فوري — قبل أي إصدار |

### 🔴 WAIN-F-002 — احتمال وجود `service-account-key.json` في الـRepo

| **المشكلة** | ملف Service Account Key مذكور في Phase 2 لكن لم تُثبَت إزالته/إبطاله |
| --- | --- |
| **الخطورة** | 🔴 P0 Critical |
| **CVSS 3.1** | **9.8** (AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H) |
| **السبب الجذري** | إدارة مفاتيح غير ناضجة — اعتماد على Service Account Keys بدلاً من Workload Identity |
| **التأثير** | استيلاء كامل على Firebase Project + Firestore + Storage + Functions |
| **التوصية** | تأكيد الحذف من Repo و Git history + إبطال من GCP IAM + Rotate + الانتقال إلى Workload Identity Federation |
| **الأولوية الزمنية** | ⏱️ فوري — قبل أي إصدار |

### 🔴 WAIN-F-003 — نقص إثبات Two-Person Rule على Reversal

| **المشكلة** | اعتماد التوقيع النهائي على Custom Claims وحدها (قد تكون stale) |
| --- | --- |
| **الخطورة** | 🔴 P0 Critical |
| **CVSS 3.1** | **8.1** (AV:N/AC:H/PR:H/UI:N/S:U/C:H/I:H/A:N) |
| **السبب الجذري** | غياب التحقق المزدوج من Firestore source-of-truth + غياب توقيع رقمي مستقل من Super Admin |
| **التأثير** | Finance Admin يتجاوز Super Admin → خسارة مالية محتملة |
| **التوصية** | Function تتحقق من Claims + Firestore role doc + توقيع منفصل من Super Admin مسجّل في نفس transaction + Audit Event |
| **الأولوية الزمنية** | ⏱️ فوري |

### 🟠 ملخص P1 / High (التفاصيل في Findings DB)

- **WAIN-F-004** — احتمال تسريب Tokens/PII في logcat الإصدار — CVSS **7.5** — أسبوع.
- **WAIN-F-005** — Idempotency Key قد لا يُفرض server-side — CVSS **7.4** — أسبوع.
- **WAIN-F-006** — App Links / Deep Links بدون `autoVerify` — CVSS **7.1** — أسبوع.
- **WAIN-F-007** — Storage Rules: ضوابط Content-Type/Size غير مؤكدة — CVSS **6.8** — أسبوع.
- **WAIN-F-008** — Cleartext Traffic exception غير محصور بـbuildType — CVSS **7.0** — أسبوع.

### 🟡 ملخص P2 / Medium

- **WAIN-F-009** — غياب Rate Limit صريح على Top-up create — CVSS 5.3.
- **WAIN-F-010** — Screenshot Prevention قرار غير موثق — CVSS 4.8.
- **WAIN-F-011** — Crashlytics قد يلتقط PII دون redact — CVSS 5.5.
- **WAIN-F-012** — Dart Obfuscation + split-debug-info غير ملزم في CI — CVSS 4.4.

### 🔵 ملخص P3 / Low

- **WAIN-F-013** — غياب `security.txt` / Responsible Disclosure.
- **WAIN-F-014** — غياب DPIA خفيف رغم وجود PII + Location.
- **WAIN-F-015** — Backup restore drill غير موثق.

---

# ✔️ 5. Checklist للمحاور الـ12

<aside>
📊

القائمة الكاملة في **Checklist DB** أسفل هذه الصفحة — تقييم رباعي: ✅ مغطى / ⚠️ جزئي / ❌ غائب / ➡️ يحتاج تحقق.

</aside>

| # | المحور | الحالة المبدئية | السبب المختصر |
| --- | --- | --- | --- |
| 1 | Source Code Review | ✅ مغطى | Phase 3/6/8 + `rg` greps موثقة |
| 2 | APIs Security (Callables) | ⚠️ جزئي | App Check Enforcement غامض |
| 3 | Application Security (Flutter) | ⚠️ جزئي | MASVS غير مكتمل |
| 4 | UI/UX Security | ➡️ يحتاج تحقق | Screenshot/Tap-jacking/Clipboard غير صريح |
| 5 | Database & Access Control (Firestore) | ✅ مغطى | Phase 4 + 14 حالة negative |
| 6 | Authentication & Sessions | ⚠️ جزئي | Token Rotation / Revocation غير مفصّل |
| 7 | Encryption & Data Protection | ➡️ يحتاج تحقق | لا تصنيف بيانات صريح |
| 8 | Error Handling & Logs | ⚠️ جزئي | CI gate تلقائي غير ملزم |
| 9 | File Upload/Download Security | ⚠️ جزئي | content-type/size enforcement غير مثبت |
| 10 | Configuration & Environment | ✅ مغطى | Phase 0 + APK inspection شامل |
| 11 | Dependencies & Third-party Libraries | ✅ مغطى | Phase 9 + SBOM + audit في CI |
| 12 | OWASP Top 10 Coverage | ⚠️ جزئي | A06/A08/A09 يحتاج توثيق صريح |

---

# ❓ 6. أسئلة لازم تُجاب قبل بدء الفحص

## 🛠️ تقنية (Technical)

1. هل App Check مُفعَّل **Enforce** على كل callable مالي، أم بعضها Unenforced؟
2. هل Play Integrity API مُكامَل في Functions verification path؟
3. ما حالة Dart Obfuscation + `--split-debug-info` في APK المرشّح للإنتاج؟
4. هل `cleartextTrafficPermitted` مفصول بين debug/release في `AndroidManifest`؟
5. هل في WebView أي شاشة؟ ما إعدادات JS / File access / JS Bridge؟
6. هل Crashlytics مُكامَل؟ ما قواعد PII redaction؟
7. هل Idempotency Key مفروض كـDoc ID في Firestore transaction؟
8. هل Deep Links تستخدم `android:autoVerify="true"` + `assetlinks.json`؟
9. هل `network_security_config.xml` يحظر cleartext في release؟
10. هل Functions تتحقق من Claims **+** Firestore source-of-truth لكل عملية مالية؟

## 🏛️ تنظيمية (Organizational)

1. من هو Security Lead المعتمد لتوقيع P0/P1؟
2. هل Two-Person Rule موثق رسمياً لـReversal/Super Admin؟
3. ما عملية Risk Acceptance — من يوقّع، أين تُسجّل، ومتى تنتهي؟
4. هل هناك Incident Response on-call rotation موثّقة؟
5. هل تم اختبار Tabletop / Emulator drill واحدة على الأقل؟
6. هل توجد سياسة Responsible Disclosure (حتى لو غير ملزم)؟
7. من يملك Play Console + Firebase Console؟ هل MFA مُفعَّل على الجميع؟

## 📊 بيانات (Data)

1. تصنيف البيانات: ما Public / Internal / Confidential / Restricted؟
2. سياسة Retention لكل: PII / Top-up Proofs / Audit Events / Logs؟
3. هل يوجد DSAR Workflow (Export / Delete)؟
4. هل بيانات الموقع (Location) تُخزَّن دائمة أم Session-only؟
5. هل يوجد تشفير حقول حساسة على Application Layer (إضافة لتشفير Firebase الافتراضي)؟
6. خطة معالجة بيانات QA Users قبل الإطلاق للإنتاج؟

## 🏗️ بنية تحتية (Infrastructure)

1. هل يوجد Service Account Key مُولّد؟ متى آخر دوران (Rotation)؟
2. Workload Identity Federation مفعّل أم Service Account Keys تقليدية؟
3. ما GCP IAM Roles للمطورين / QA / Admin؟ هل Least Privilege؟
4. Firebase Backups: دوري؟ متى آخر Restore Drill؟
5. CI/CD: من يملك secrets في GitHub Actions / Cloud Build؟
6. Play Signing: Play App Signing مُفعَّل أم Upload Key محلي؟
7. Monitoring & Alerting: من يستقبل alerts لـFunction errors المالية؟
8. Cloud Logging Retention: كم يوم؟ هل PII مُنقّى؟

---

# 🛠️ 7. خطة المعالجة (Remediation Roadmap)

<aside>
🗺️

الـRoadmap الكاملة مُسجّلة في **Remediation Roadmap DB** أسفل هذه الصفحة، مع ربط Two-way مع Findings DB.

</aside>

| الأسبوع | المهمة | المسؤول | Linked Findings |
| --- | --- | --- | --- |
| **W1-2 (Critical Fix)** | تأكيد إبطال + تدوير Service Account؛ نقل لـWorkload Identity | DevSecOps + Infra | WAIN-F-002 |
| W1-2 | فرض App Check Enforce + Play Integrity verification | Backend | WAIN-F-001 |
| W1-2 | تعزيز Two-Person Rule في Reversal Function + Audit | Backend | WAIN-F-003 |
| **W3-4 (High Fix)** | فرض Idempotency Key كـDoc ID + transaction guard | Backend | WAIN-F-005 |
| W3-4 | `autoVerify` على Deep Links + assetlinks.json | Mobile | WAIN-F-006 |
| W3-4 | تشديد Storage Rules: content-type + size + ownership | Rules | WAIN-F-007 |
| W3-4 | فصل `network_security_config.xml` debug/release | Mobile | WAIN-F-008 |
| W3-4 | CI grep gate لمنع `print` / `debugPrint` في release | DevSecOps | WAIN-F-004 |
| **W5-6 (Medium Fix)** | Rate Limiter على Top-up create | Backend | WAIN-F-009 |
| W5-6 | تفعيل `FLAG_SECURE` على شاشات Wallet/Proof | Mobile | WAIN-F-010 |
| W5-6 | Crashlytics PII redaction rules | Mobile | WAIN-F-011 |
| W5-6 | إلزام Obfuscation + split-debug-info في CI release job | DevSecOps | WAIN-F-012 |
| **W7-8 (Low + Hardening)** | نشر `security.txt`  • Responsible Disclosure page | Security Lead | WAIN-F-013 |
| W7-8 | DPIA خفيف + توثيق Retention Policy | Security Lead + Product | WAIN-F-014 |
| W7-8 | Backup Restore Drill على staging | Infra/SRE | WAIN-F-015 |

---

# 📏 8. مقاييس النجاح (Success Metrics / KPIs)

| KPI | الهدف | كيف يُقاس | تكرار |
| --- | --- | --- | --- |
| **Open P0/P1 Findings** | 0 | استعلام Findings DB | يومي |
| Mean Time to Triage (P0) | ≤ 24 ساعة | timestamp(New→Triaged) | شهري |
| Mean Time to Fix (P0) | ≤ 72 ساعة | timestamp(Triaged→Ready for Retest) | شهري |
| Mean Time to Fix (P1) | ≤ 7 أيام | نفس الحساب | شهري |
| Critical Dependency CVE backlog | 0 unaccepted | `npm audit`  • `flutter pub outdated` | أسبوعي |
| Firestore/Storage negative tests pass rate | 100% | CI gate | كل PR |
| Finance Verifier `fail=0 warn=0` | 100% | `qa-verify-finance` | كل PR |
| Audit Trail Verifier `fail=0 warn=0` | 100% | `qa-verify-audit-trail` | كل PR |
| APK Production Config violations | 0 | grep-gate في CI | كل release |
| Secrets in repo/build/logs | 0 | gitleaks / trufflehog | كل push |
| Control Traceability Mapping | ≥ 95% | manual audit | per release |
| Drill MTTD / MTTR | MTTD < 1h • MTTR < 4h | tabletop drill | ربع سنوي |
| Incident Drills Completed | ≥ 1 قبل الإصدار | drill log | لكل major release |
| % Findings مع CVSS + OWASP/NIST/ISO mapping | 100% | Findings DB audit | شهري |
| % APK builds مع Obfuscation + split-debug | 100% release builds | CI job log | كل release |

---

# 📄 9. الملخص التنفيذي (Executive Summary)

<aside>
📄

**WAIN — Executive Security Summary (2026-05-19)**

تطبيق **WAIN** (Flutter Android، مرشّح إنتاج، 1K–50K مستخدم، يتعامل مع محافظ مالية + إثباتات تعبئة + بيانات شخصية + بيانات أعمال للتجار) يمتلك خطة أمنية **ناضجة هندسياً** تغطي بشكل متين: قواعد إصدار صارمة (Release Gates)، Governance Addendum مع SLA و Risk Acceptance، Control Traceability Matrix، CI/CD Gates ملزمة، اختبارات Firestore/Storage السلبية الشاملة، والتحقق من السلامة المالية عبر Verifiers مؤتمتة (`qa-verify-finance` و `qa-verify-audit-trail`).

يكشف هذا التقييم الدفاعي عن **3 ثغرات P0 Critical** (تأكيد إبطال مفتاح Service Account، فرض App Check + Play Integrity على Callables المالية، تعزيز Two-Person Rule في Reversal)، و**5 ثغرات P1 High** متعلقة بـ Idempotency Enforcement، App Links Verification، Storage Content-Type/Size، Cleartext Traffic Scope، وتسريب logs، يجب إغلاقها جميعاً قبل أي قرار إطلاق إنتاج.

**التوصية النهائية:** ⛔ **No-Go مشروط (Conditional Go)** — يصبح Go بعد:

1. إنجاز Roadmap الأسبوعَين W1-2 و W3-4 بالكامل.
2. إجراء Tabletop Drill واحدة موثقة (compromised token / unauthorized wallet mutation).
3. تنفيذ Backup Restore Drill ناجح على staging.
4. توقيع Security Lead + Backend Owner + Mobile Owner + Rules Owner + DevSecOps Owner.

مع التزام طوعي بـ **OWASP MASVS L1 / ASVS V4 / Top 10 (2021)** و **NIST SSDF + CSF** و **ISO 27001 Annex A** كمراجع رغم عدم وجود Compliance رسمي مُلزم في هذه المرحلة.

</aside>

---

# 📚 قواعد البيانات المرتبطة (Linked Databases)

ستُنشأ ثلاث قواعد بيانات أسفل هذه الصفحة:

1. 🐛 **Findings DB** — كل ثغرة كصفحة كاملة بالـ CVSS و OWASP/NIST/ISO mapping.
2. 🛠️ **Remediation Roadmap DB** — مرتبطة Two-way بـFindings DB.
3. ✔️ **Checklist DB** — للمحاور الـ12 مع تقييم رباعي وربط بـFindings.

---

# ✍️ Signed-Off Section

| الدور | الاسم | التوقيع | التاريخ |
| --- | --- | --- | --- |
| Security Lead |  |  |  |
| Backend Owner |  |  |  |
| Mobile Owner |  |  |  |
| Rules Owner |  |  |  |
| Admin Web Owner |  |  |  |
| DevSecOps Owner |  |  |  |
| Infra / SRE Owner |  |  |  |

<aside>
⚠️

**قواعد صارمة طُبِّقت في كامل التقرير:**

- ✅ لا توجد أكواد استغلال (Exploit Code).
- ✅ لا توجد خطوات هجوم فعلي قابلة للتنفيذ.
- ✅ التركيز على الكشف، التحليل الدفاعي، والمعالجة فقط.
- ✅ الأسلوب رسمي مناسب للتوثيق ومشاركة الفريق.
- ✅ مصطلحات تقنية + شرح عربي مُبسَّط.
</aside>

[🐛 WAIN — Findings DB](https://www.notion.so/f4040283feff4d22987b01e928fae7ad?pvs=21)

[✔️ WAIN — Checklist DB (12 محور)](https://www.notion.so/2a338a5096d844da85dfa193168a6c4d?pvs=21)

[🛠️ WAIN — Remediation Roadmap DB](https://www.notion.so/06797dba5f4d491283a434aaeb567140?pvs=21)



## الملخص

Deep Links بدون autoVerify تفتح باب لـIntent Hijacking على Android.

## التحقق الدفاعي

- `rg -n "android:autoVerify|intent-filter" android/app/src/main/AndroidManifest.xml`
- فحص جلب assetlinks.json (HTTPS GET) ومطابقة بصمة التوقيع.
- adb shell `pm get-app-links com.wain.wain_app`.

## خطة الإصلاح

1. حصر deep links على https فقط.
2. تفعيل autoVerify.
3. نشر assetlinks.json.
4. Route Guard داخل التطبيق لرفض فتح shells حساسة دون مصادقة.

## خطة التحقق

- adb verify status = `verified`.
- Manual: tampering app A لا يلتقط روابط [wain.app](http://wain.app).

## الأثر

يسد فجوة G9 و G10 جزئياً.


## الملخص

Storage Rules تتطلب فحوص contentType + size + ownership صريحة.

## التحقق الدفاعي

- ST-007 و ST-008 في Phase 5.
- emulator: محاولة رفع application/octet-stream → تُرفض.

## خطة الإصلاح

1. تحديث storage.rules بفحوص صريحة.
2. إضافة emulator tests لـST-007 و ST-008.
3. إلزام image MIME validation على عميل + server.
4. وضع quota لـstorage per merchant.

## خطة التحقق

- ST-001 حتى ST-008 تمر بـfail=0.
- حجم storage لكل merchant tenant غير تجاوز.

## الأثر

يعالج S8 (Storage cross-path).


## الملخص

Flutter بحاجة إلى cleartext لـemulator (10.0.2.2)، ولكن يجب حصره بال buildType debug فقط.

## التحقق الدفاعي

- `apkanalyzer manifest print app-release.apk | grep -i cleartextTraffic`
- `unzip -p app-release.apk AndroidManifest.xml | strings | grep -i cleartext`
- فحص network_security_config.xml في release.

## خطة الإصلاح

1. فصل release/debug manifest config.
2. CI gate yfail على وجود cleartextTrafficPermitted=true في release.
3. توثيق السياسة في `docs/security/transport-policy.md`.

## خطة التحقق

- Phase 10 inspection تثبت `usesCleartextTraffic=false` في release.

## الأثر

يعزز transport security ويسد فجوة MASVS-NETWORK.


## الملخص

Rate Limiting غائب على أفعال ليست مالية مباشرة لكنها تستهلك موارد بحدود غير مرصودة.

## التحقق الدفاعي

- Cloud Monitoring داشبورد لـfunction invocations per minute.
- Firestore counter يتوضح إذا تجاوز 50 طلب في 5 دقائق.

## خطة الإصلاح

1. إضافة rate limit middleware.
2. سياسة backoff + 429 response واضحة للعميل.
3. logging لجميع الـblocked attempts.

## خطة التحقق

- التجربة على emulator بإرسال 30 طلب في 10 ثواني و رصد rate-limit response.

## الأثر

يسد G5.

## الملخص

FLAG_SECURE فحص دفاعي بسيط يمنع screenshot/screen recording على شاشات حساسة.

## التحقق الدفاعي

- Manual: محاولة screenshot على شاشة Wallet → يجب أن تظهر سوداء.

## خطة الإصلاح

1. تحديد قائمة routes حساسة.
2. wrapper widget `SecureScreen` يفعل FLAG_SECURE في initState ويعطله في dispose.
3. توثيق القرار في Mobile Hardening Decision Log.

## خطة التحقق

- adb screencap تعطي إطاراً أسود على الشاشات الحساسة.

## الأثر

يدعم Mobile Hardening Baseline.

https://www.notion.so/WAIN-F-001-6488b8cba885467f9efe0a8b3906c050?source=copy_link


## الملخص

الخطة تذكر `service-account-key.json` في Phase 2 وتتطلب التحقق أنه ليس مفتاحاً إنتاجياً حقيقياً. حتى لو كان فحص emulator-only، وجود الملف جزء من secret hygiene رديئة.

## التحقق الدفاعي (Detection)

- `gitleaks detect --no-banner --redact`
- `trufflehog filesystem --no-update .`
- فحص GitHub Actions secrets / Cloud Build secrets.
- ربط alert على GCP IAM Recommender.

## خطة الإصلاح (تفصيل)

1. **التحقق من نوع المفتاح:** فتح الملف وفحص `project_id` + `client_email`.
2. **الحذف والتاريخ:** `git rm` + tool لتنظيف history (BFG أو git-filter-repo).
3. **الإبطال:** GCP Console → IAM → حذف المفتاح حتى لو كان تجريبياً.
4. **البديل الآمن:** WIF + GitHub Actions OIDC.
5. **تدوين السياسة:** "لا تُخزّن service account keys في Repo أبداً".

## خطة التحقق

- gitleaks/trufflehog yield zero findings.
- IAM key list خالٍ من مفتاح الحساب المعني.
- CI uses WIF without long-lived keys.

## الأثر على سيناريوهات التهديد

يعالج S6 (تسريب SA key) تماماً، ويقلل سطح S8 (Insider misuse).

## الملخص

للعمليات المالية العكسية (Reversal) يجب إثبات Two-Person Rule ترانزاكشنياً لمنع تجاوز Finance Admin لـSuper Admin.

## التحقق الدفاعي

- مراجعة الـ Reversal callable للتأكد من `runTransaction` + double role check.
- استعلام Audit Events لتجربة الرجوع والتحقق من وجود حقلي `approver_finance` + `approver_super_admin`.
- `qa-verify-finance` و `qa-verify-audit-trail` تغطي حالة FIN-007.

## خطة الإصلاح

1. تعديل `finalApproveReversal` callable: `runTransaction` داخلها فحص Firestore role docs لـactor + super_admin signer.
2. Schema Audit Event يشمل `actor_finance_uid`، `actor_super_admin_uid`، `timestamps`.
3. رفض أي request انتهت صلاحيته أو تغير status.
4. توثيق العملية في `docs/finance/two-person-rule.md`.

## خطة التحقق

- تشغيل FIN-004، FIN-005، FIN-007 في Phase 7 (Financial Abuse).
- إثبات فشل Finance Admin وحده في التوقيع النهائي.

## الأثر على السيناريوهات

يعالج S4 (Finance bypass) و S1 (Audit Event مفقود).



## الملخص

logs في Flutter سهلة الالتقاط؛ CI Gate صارم أجدى من المراجعة اليدوية.

## التحقق الدفاعي

- `rg -n "debugPrint\(|print\(" lib`
- logcat smoke على release APK بعد تلغيم سيناريوهات auth + wallet + top-up.
- grep على keywords: `idToken|refreshToken|Bearer|otp|password|secret|wallet|proof`.

## خطة الإصلاح

1. `WainLogger.info/warn/error` مع PII redaction rules متصلة بـregex denylist.
2. CI gate `security:flutter:no-print` يفشل PR عند وجود `debugPrint`/`print` خارج `lib/dev_tools/` فقط.
3. `kReleaseMode` guard داخل logger يغلق الإخراج تماماً.

## خطة التحقق

- إعادة Phase 10 logcat run — لا تظهر PII/tokens.
- CI badge تعرض grep-gate أخضر.

## الأثر على السيناريوهات

يعالج S9 (تسريب logcat).

## الملخص

Idempotency لإفعال مالية ليس تحسيناً تجريبياً بل شرط سلامة.

## التحقق الدفاعي

- FIN-001، FIN-002، FIN-005، FIN-006 في خطة الفحص الحالية.
- `qa-verify-finance --strict` يرصد duplicate credits.

## خطة الإصلاح المفصلة

1. تحديث schema لـ`createTopUpRequest`، `approveTopUp`، `createReversal` — إجبار `client_request_id`.
2. Firestore Rules: رفض أي write بدون idempotency key.
3. Doc-ID-based dedupe.
4. إضافة metric/alert لـ"duplicate request blocked".

## خطة التحقق

- تشغيل FIN-001 حتى FIN-008 في emulator وإثبات `duplicate_blocked` audit events.

## الأثر

يعالج S2 (Double Approval) و S7 (Replay).
# WAIN-F-001

CVSS 3.1: 8٫6
CVSS Vector: CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:L
Evidence Path: docs/security/evidence/2026-05-19/WAIN-F-001/
Impact: تجاوز Functions مباشرة من عميل مزوّر أو معاد بناؤه → احتيال على Top-up/Reversal، إنشاء معاملات مالية غير مصرّحة، وتجاوز سلسلة الثقة من العميل إلى Backend.
OWASP / NIST / ISO Ref: ISO 27001 A.13, NIST CSF, OWASP ASVS V4, OWASP MASVS-PLATFORM, OWASP MASVS-RESILIENCE, OWASP Top 10 A04
Owner: Backend
Remediation: تفعيل App Check Enforce على كل callable مالي (وليس Unenforced) + تكامل Play Integrity Server Verification داخل Function (Device + App + Token Payload) + فحص nonce مربوط بالطلب + خطة Rollout موثقة من Unenforced → Enforce.
Root Cause: غياب اشتراط App Check Enforce صريح على كل callable مالي، وعدم تكامل Play Integrity API في server-side verification path.
Severity: P0 Critical
Status: New
الأولوية الزمنية: فوري
العنوان / Summary: غياب فرض صريح لـApp Check + Play Integrity على Callables المالية
المحور: APIs Security, Application Security, Authentication & Sessions

## الملخص

App Check وحده غير كافٍ لتطبيق مالي؛ Play Integrity يفحص سلامة الجهاز (Device Integrity)، سلامة التطبيق (App Integrity)، وصحة الترخيص من Play Store.

## التحقق الدفاعي (Detection)

- فحص firebase.json و Functions code للتأكد من `enforceAppCheck: true`.
- استعراض Firebase Console → App Check → APIs → حالة كل service (Cloud Functions خصوصاً).
- فحص السجلات (Cloud Logging) لرصد طلبات بدون App Check Token.

## خطة الإصلاح

1. تفعيل App Check Enforce على كل callable مالي (`createTopUpRequest`، `approveTopUp`، `createReversal`، إلخ).
2. دمج Play Integrity API — verifying integrity verdicts server-side.
3. رفض الطلبات التي تحمل verdicts ضعيفة (MEETS_BASIC_INTEGRITY فقط للعمليات غير الحرجة، MEETS_STRONG للمالية).
4. توثيق السلوك عند فشل App Check (Fail Closed للمالية).

## خطة التحقق (Verification Plan)

- Retest بـ Functions emulator + عميل معدل لإثبات رفض الطلب عند غياب App Check Token.
- تجربة Play Integrity مع حساب QA حقيقي.

## الأثر على سيناريوهات التهديد

- يعالج S1 (تزوير Audit)، S3 (تجاوز Functions)، S5 (Cross-Tenant)، S10 (App Check وحده).

# WAIN-F-002

CVSS 3.1: 9٫8
CVSS Vector: CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H
Evidence Path: docs/security/evidence/2026-05-19/WAIN-F-002/
Impact: تسريب مفتاح واحد = استيلاء كامل على Firebase Project + Firestore + Storage + Functions بصلاحيات Admin SDK تتجاوز كل Rules.
OWASP / NIST / ISO Ref: ISO 27001 A.8, ISO 27001 A.9, NIST SSDF, OWASP ASVS V10, OWASP ASVS V2, OWASP Top 10 A02, OWASP Top 10 A05
Owner: DevSecOps
Remediation: 1) تأكيد حذف الملف من working tree. 2) تنظيف Git history (git filter-repo). 3) إبطال المفتاح من GCP IAM → Service Accounts → Keys → Delete. 4) Rotate أي credentials مشتقة. 5) الانتقال إلى Workload Identity Federation لـ CI/CD.
Root Cause: إدارة مفاتيح غير ناضجة — اعتماد على Service Account Keys بدلاً من Workload Identity Federation أو Platform-Managed Credentials.
Severity: P0 Critical
Status: New
الأولوية الزمنية: فوري
العنوان / Summary: احتمال وجود Service Account Key في الـRepo دون إثبات إبطال
المحور: Configuration & Environment, Encryption & Data Protection, Source Code Review

## الملخص

الخطة تذكر `service-account-key.json` في Phase 2 وتتطلب التحقق أنه ليس مفتاحاً إنتاجياً حقيقياً. حتى لو كان فحص emulator-only، وجود الملف جزء من secret hygiene رديئة.

## التحقق الدفاعي (Detection)

- `gitleaks detect --no-banner --redact`
- `trufflehog filesystem --no-update .`
- فحص GitHub Actions secrets / Cloud Build secrets.
- ربط alert على GCP IAM Recommender.

## خطة الإصلاح (تفصيل)

1. **التحقق من نوع المفتاح:** فتح الملف وفحص `project_id` + `client_email`.
2. **الحذف والتاريخ:** `git rm` + tool لتنظيف history (BFG أو git-filter-repo).
3. **الإبطال:** GCP Console → IAM → حذف المفتاح حتى لو كان تجريبياً.
4. **البديل الآمن:** WIF + GitHub Actions OIDC.
5. **تدوين السياسة:** "لا تُخزّن service account keys في Repo أبداً".

## خطة التحقق

- gitleaks/trufflehog yield zero findings.
- IAM key list خالٍ من مفتاح الحساب المعني.
- CI uses WIF without long-lived keys.

## الأثر على سيناريوهات التهديد

يعالج S6 (تسريب SA key) تماماً، ويقلل سطح S8 (Insider misuse).

# WAIN-F-003

CVSS 3.1: 8٫1
CVSS Vector: CVSS:3.1/AV:N/AC:H/PR:H/UI:N/S:U/C:H/I:H/A:N
Evidence Path: docs/security/evidence/2026-05-19/WAIN-F-003/
Impact: Finance Admin بصلاحيات قديمة أو مسروقة يوقّع نهائياً على Reversal بدون Super Admin → خسائر مالية غير قابلة للإرجاع وفقدان ثقة التجار.
OWASP / NIST / ISO Ref: ISO 27001 A.12, ISO 27001 A.9, NIST CSF, OWASP ASVS V10, OWASP ASVS V4, OWASP ASVS V5, OWASP Top 10 A01
Owner: Backend
Remediation: Function للتوقيع النهائي تفحص: (1) Claims حديثة، (2) Firestore role doc match، (3) توقيع Super Admin ملفوف في transaction واحدة، (4) Audit event واحد بتفاصيل الموقّعين الاثنين، (5) فحص expiry لـRequest رفض عند تغيّر status.
Root Cause: التحقق من دور Finance/Super Admin عبر Custom Claims فقط (قد تكون stale)، دون تحقق مزدوج من Firestore source-of-truth، ودون توقيع رقمي مستقل من Super Admin داخل نفس Firestore transaction.
Severity: P0 Critical
Status: New
الأولوية الزمنية: فوري
العنوان / Summary: Two-Person Rule لـReversal غير مُثبَت ترانزاكشنياً
المحور: APIs Security, Authentication & Sessions, Database & Access Control

## الملخص

للعمليات المالية العكسية (Reversal) يجب إثبات Two-Person Rule ترانزاكشنياً لمنع تجاوز Finance Admin لـSuper Admin.

## التحقق الدفاعي

- مراجعة الـ Reversal callable للتأكد من `runTransaction` + double role check.
- استعلام Audit Events لتجربة الرجوع والتحقق من وجود حقلي `approver_finance` + `approver_super_admin`.
- `qa-verify-finance` و `qa-verify-audit-trail` تغطي حالة FIN-007.

## خطة الإصلاح

1. تعديل `finalApproveReversal` callable: `runTransaction` داخلها فحص Firestore role docs لـactor + super_admin signer.
2. Schema Audit Event يشمل `actor_finance_uid`، `actor_super_admin_uid`، `timestamps`.
3. رفض أي request انتهت صلاحيته أو تغير status.
4. توثيق العملية في `docs/finance/two-person-rule.md`.

## خطة التحقق

- تشغيل FIN-004، FIN-005، FIN-007 في Phase 7 (Financial Abuse).
- إثبات فشل Finance Admin وحده في التوقيع النهائي.

## الأثر على السيناريوهات

يعالج S4 (Finance bypass) و S1 (Audit Event مفقود).

# WAIN-F-004

CVSS 3.1: 7٫5
CVSS Vector: CVSS:3.1/AV:L/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N
Evidence Path: docs/security/evidence/2026-05-19/WAIN-F-004/
Impact: استخراج idTokens، refreshTokens، phone، email، و wallet proofs من logcat على أجهزة غير محروسة (USB debugging) أو عبر تطبيقات تملك READ_LOGS على إصدارات Android أقدم.
OWASP / NIST / ISO Ref: ISO 27001 A.12, NIST SSDF, OWASP ASVS V7, OWASP MASVS-CODE, OWASP MASVS-STORAGE, OWASP Top 10 A09
Owner: Mobile
Remediation: 1) CI grep gate يفشل release عند وجود debugPrint/print في lib/. 2) dart-defines تحقن logger no-op في release. 3) Wrapper WainLogger مع redaction rules لـPII. 4) flutter build apk --release --obfuscate --split-debug-info=.... 5) logcat smoke test في Phase 10.
Root Cause: غياب CI gate ملزم لمنع print()/debugPrint()/logger في release builds، وغياب PII Redaction Layer مركزية.
Severity: P1 High
Status: New
الأولوية الزمنية: أسبوع
العنوان / Summary: احتمال تسريب Tokens/PII في logcat بإصدار الإنتاج
المحور: Application Security, Encryption & Data Protection, Error Handling & Logs

## الملخص

logs في Flutter سهلة الالتقاط؛ CI Gate صارم أجدى من المراجعة اليدوية.

## التحقق الدفاعي

- `rg -n "debugPrint\(|print\(" lib`
- logcat smoke على release APK بعد تلغيم سيناريوهات auth + wallet + top-up.
- grep على keywords: `idToken|refreshToken|Bearer|otp|password|secret|wallet|proof`.

## خطة الإصلاح

1. `WainLogger.info/warn/error` مع PII redaction rules متصلة بـregex denylist.
2. CI gate `security:flutter:no-print` يفشل PR عند وجود `debugPrint`/`print` خارج `lib/dev_tools/` فقط.
3. `kReleaseMode` guard داخل logger يغلق الإخراج تماماً.

## خطة التحقق

- إعادة Phase 10 logcat run — لا تظهر PII/tokens.
- CI badge تعرض grep-gate أخضر.

## الأثر على السيناريوهات

يعالج S9 (تسريب logcat).

# WAIN-F-005

CVSS 3.1: 7٫4
CVSS Vector: CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:H/A:L
Evidence Path: docs/security/evidence/2026-05-19/WAIN-F-005/
Impact: Double Submit / Replay يؤدي إلى ازدواج Top-up Credit أو Reversal Debit → خسائر مالية وتلاعب Drift في Ledger.
OWASP / NIST / ISO Ref: ISO 27001 A.14, NIST CSF, OWASP ASVS V4, OWASP ASVS V5, OWASP Top 10 A04
Owner: Backend
Remediation: 1) جعل client_request_id حقلاً إلزامياً في الـcallable schema. 2) استخدامه كـDoc ID في top_up_requests/{client_request_id} مع create فقط (يفشل إذا موجود). 3) transaction guard داخل الـ callable. 4) TTL 24-48 ساعة لـidempotency keys.
Root Cause: Idempotency مذكور في الخطة كـ"strategy" دون إلزام سكيمي (مثل استخدام client_request_id كـDoc ID + transaction guard).
Severity: P1 High
Status: New
الأولوية الزمنية: أسبوع
العنوان / Summary: إلزامية Idempotency Key على المعاملات المالية غير مؤكدة server-side
المحور: APIs Security, Database & Access Control

## الملخص

Idempotency لإفعال مالية ليس تحسيناً تجريبياً بل شرط سلامة.

## التحقق الدفاعي

- FIN-001، FIN-002، FIN-005، FIN-006 في خطة الفحص الحالية.
- `qa-verify-finance --strict` يرصد duplicate credits.

## خطة الإصلاح المفصلة

1. تحديث schema لـ`createTopUpRequest`، `approveTopUp`، `createReversal` — إجبار `client_request_id`.
2. Firestore Rules: رفض أي write بدون idempotency key.
3. Doc-ID-based dedupe.
4. إضافة metric/alert لـ"duplicate request blocked".

## خطة التحقق

- تشغيل FIN-001 حتى FIN-008 في emulator وإثبات `duplicate_blocked` audit events.

## الأثر

يعالج S2 (Double Approval) و S7 (Replay).

# WAIN-F-006

CVSS 3.1: 7٫1
CVSS Vector: CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:L/A:N
Evidence Path: docs/security/evidence/2026-05-19/WAIN-F-006/
Impact: Intent Hijacking: تطبيق خبيث يسجل نفس scheme ويلتقط روابط الدفع/التجار/Top-up، أو تصيد phishing عبر deep link يعيد توجيه المستخدم.
OWASP / NIST / ISO Ref: ISO 27001 A.13, ISO 27001 A.14, OWASP MASVS-AUTH, OWASP MASVS-PLATFORM, OWASP Top 10 A01, OWASP Top 10 A07
Owner: Mobile
Remediation: 1) تجميع deep links تحت https scheme حصراً. 2) android:autoVerify="true". 3) نشر /.well-known/assetlinks.json ببصمة SHA-256 لـRelease Signing. 4) رفض فتح الروابط دون مصادقة + role check.
Root Cause: غياب اشتراط android:autoVerify="true" على intent-filters + غياب assetlinks.json مستضافة على الـHTTPS domain.
Severity: P1 High
Status: New
الأولوية الزمنية: أسبوع
العنوان / Summary: App Links / Deep Links غير محمية بـ autoVerify + Digital Asset Links
المحور: Application Security, Authentication & Sessions, UI/UX Security

## الملخص

Deep Links بدون autoVerify تفتح باب لـIntent Hijacking على Android.

## التحقق الدفاعي

- `rg -n "android:autoVerify|intent-filter" android/app/src/main/AndroidManifest.xml`
- فحص جلب assetlinks.json (HTTPS GET) ومطابقة بصمة التوقيع.
- adb shell `pm get-app-links com.wain.wain_app`.

## خطة الإصلاح

1. حصر deep links على https فقط.
2. تفعيل autoVerify.
3. نشر assetlinks.json.
4. Route Guard داخل التطبيق لرفض فتح shells حساسة دون مصادقة.

## خطة التحقق

- adb verify status = `verified`.
- Manual: tampering app A لا يلتقط روابط [wain.app](http://wain.app).

## الأثر

يسد فجوة G9 و G10 جزئياً.

# WAIN-F-007

CVSS 3.1: 6٫8
CVSS Vector: CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:H/A:L
Evidence Path: docs/security/evidence/2026-05-19/WAIN-F-007/
Impact: تحميل ملفات خبيثة (executables، HTML لـXSS عبر download)، إغراق Storage quota، استغلال بوابة Upload لتخزين بيانات بريدية (Spam Storage).
OWASP / NIST / ISO Ref: ISO 27001 A.13, OWASP ASVS V4, OWASP MASVS-STORAGE, OWASP Top 10 A01, OWASP Top 10 A04
Owner: Rules
Remediation: Storage Rules: request.resource.contentType.matches("image/(jpeg|png|webp)") + request.resource.size < 5 * 1024 * 1024 + request.auth.uid == venueOwnerUid(venueId) + request.auth.token.role == "merchant".
Root Cause: غياب إثبات مفصّل في Storage Rules لـ: contentType allow-list (image/jpeg, image/png, application/pdf)، size cap (مثل 5MB)، ownership path matching (/merchants/{uid}/...).
Severity: P1 High
Status: New
الأولوية الزمنية: أسبوع
العنوان / Summary: Storage Rules: ضوابط content-type و size غير مؤكدة
المحور: Database & Access Control, File Upload/Download Security

## الملخص

Storage Rules تتطلب فحوص contentType + size + ownership صريحة.

## التحقق الدفاعي

- ST-007 و ST-008 في Phase 5.
- emulator: محاولة رفع application/octet-stream → تُرفض.

## خطة الإصلاح

1. تحديث storage.rules بفحوص صريحة.
2. إضافة emulator tests لـST-007 و ST-008.
3. إلزام image MIME validation على عميل + server.
4. وضع quota لـstorage per merchant.

## خطة التحقق

- ST-001 حتى ST-008 تمر بـfail=0.
- حجم storage لكل merchant tenant غير تجاوز.

## الأثر

يعالج S8 (Storage cross-path).

# WAIN-F-008

CVSS 3.1: 7
CVSS Vector: CVSS:3.1/AV:A/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N
Evidence Path: docs/security/evidence/2026-05-19/WAIN-F-008/
Impact: MITM على شبكات Wi-Fi غير آمنة → التقاط idTokens أو بيانات Top-up Proof إذا تم إرسالها عبر endpoint cleartext.
Owner: Mobile
Remediation: 1) network_security_config_release.xml يحظر cleartext تماماً. 2) network_security_config_debug.xml يسمح فقط لـ 10.0.2.2/127.0.0.1. 3) Gradle buildTypes manifestPlaceholders تختار الملف المناسب. 4) rg CI gate يرفض cleartext keys في release manifest.
Root Cause: في Flutter + Firebase emulator workflow، usesCleartextTraffic أو network_security_config.xml قد يتسرب إلى release APK دون فصل buildType.
Severity: P1 High
Status: New
الأولوية الزمنية: أسبوع
العنوان / Summary: Cleartext Traffic exception غير محصور بين debug/release
المحور: Application Security, Configuration & Environment, Encryption & Data Protection

## الملخص

Flutter بحاجة إلى cleartext لـemulator (10.0.2.2)، ولكن يجب حصره بال buildType debug فقط.

## التحقق الدفاعي

- `apkanalyzer manifest print app-release.apk | grep -i cleartextTraffic`
- `unzip -p app-release.apk AndroidManifest.xml | strings | grep -i cleartext`
- فحص network_security_config.xml في release.

## خطة الإصلاح

1. فصل release/debug manifest config.
2. CI gate yfail على وجود cleartextTrafficPermitted=true في release.
3. توثيق السياسة في `docs/security/transport-policy.md`.

## خطة التحقق

- Phase 10 inspection تثبت `usesCleartextTraffic=false` في release.

## الأثر

يعزز transport security ويسد فجوة MASVS-NETWORK.

# WAIN-F-009

CVSS 3.1: 5٫3
CVSS Vector: CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:L
Evidence Path: docs/security/evidence/2026-05-19/WAIN-F-009/
Impact: أتمتة إنشاء طلبات Top-up ترهق finance admin queue، تسبب noise في Audit Events، وتتيح brute-force على endpoints غير المالية.
Owner: Backend
Remediation: 1) Firestore counter merchants/{uid}/rate_state/topup يرصد window 1 دقيقة/10 طلبات. 2) Cloud Functions middleware. 3) Cloud Armor / reCAPTCHA Enterprise لـadmin web. 4) Alert عند تجاوز threshold.
Root Cause: الخطة تذكر "rate limiting" عموماً دون آلية محددة (Cloud Armor / Cloud Functions limiter / Firestore-based counters).
Severity: P2 Medium
Status: New
الأولوية الزمنية: 30 يوم
العنوان / Summary: غياب Rate Limit صريح على Top-up create و callables حساسة
المحور: APIs Security, Application Security

## الملخص

Rate Limiting غائب على أفعال ليست مالية مباشرة لكنها تستهلك موارد بحدود غير مرصودة.

## التحقق الدفاعي

- Cloud Monitoring داشبورد لـfunction invocations per minute.
- Firestore counter يتوضح إذا تجاوز 50 طلب في 5 دقائق.

## خطة الإصلاح

1. إضافة rate limit middleware.
2. سياسة backoff + 429 response واضحة للعميل.
3. logging لجميع الـblocked attempts.

## خطة التحقق

- التجربة على emulator بإرسال 30 طلب في 10 ثواني و رصد rate-limit response.

## الأثر

يسد G5.

# WAIN-F-010

CVSS 3.1: 4٫8
CVSS Vector: CVSS:3.1/AV:P/AC:L/PR:L/UI:R/S:U/C:H/I:N/A:N
Evidence Path: docs/security/evidence/2026-05-19/WAIN-F-010/
Impact: Screenshot/Screen recording تلتقط أرصدة و QR codes و PII — تعرض تلقائي عبر Google Photos backup أو تطبيقات third-party.
OWASP / NIST / ISO Ref: ISO 27001 A.13, OWASP MASVS-PLATFORM, OWASP MASVS-STORAGE
Owner: Mobile
Remediation: 1) SystemChrome.setSecureFlag() (Flutter package: flutter_windowmanager أو platform channel). 2) تفعيل FLAG_SECURE على routes: Wallet Detail، Top-up Proof View، QR Payment، Admin Sensitive. 3) تعطيله في release فقط (debug فيه حرية للـQA).
Root Cause: غياب WindowManager.LayoutParams.FLAG_SECURE على الشاشات التي تعرض أرصدة، QR للـpayment، أو إثباتات top-up.
Severity: P2 Medium
Status: New
الأولوية الزمنية: 30 يوم
العنوان / Summary: غياب FLAG_SECURE على شاشات Wallet/Top-up Proof
المحور: Application Security, UI/UX Security

## الملخص

FLAG_SECURE فحص دفاعي بسيط يمنع screenshot/screen recording على شاشات حساسة.

## التحقق الدفاعي

- Manual: محاولة screenshot على شاشة Wallet → يجب أن تظهر سوداء.

## خطة الإصلاح

1. تحديد قائمة routes حساسة.
2. wrapper widget `SecureScreen` يفعل FLAG_SECURE في initState ويعطله في dispose.
3. توثيق القرار في Mobile Hardening Decision Log.

## خطة التحقق

- adb screencap تعطي إطاراً أسود على الشاشات الحساسة.

## الأثر

يدعم Mobile Hardening Baseline.