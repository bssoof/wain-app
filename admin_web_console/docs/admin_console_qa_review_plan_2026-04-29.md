# Admin Web Console QA Review and Remediation Plan

تاريخ المراجعة: 2026-04-29

النطاق: `wain_app/admin_web_console` فقط.

الحالة العامة: لوحة الأدمن مبنية بشكل جيد من ناحية RBAC، server-side route guards، فصل server/client، ووضوح حالات القراءة `success/stale/unavailable`. نقاط الضعف الأساسية حالياً ليست في البنية الأمنية العامة، بل في سلامة بعض الأوامر الحساسة، تجربة الاستخدام داخل التبويبات، ودقة البحث/الفلاتر عند الاعتماد على slices محدودة من البيانات.

## التحقق الذي تم

- تم تشغيل `npm run build` بنجاح.
- تم تشغيل `npm test`.
- نتيجة `npm test`: نجح 381 اختباراً وفشل اختبار واحد بسبب timeout في `lib/finance/finance-read-snapshot-transport.test.ts`.
- تم تشغيل الاختبار الفاشل منفرداً ونجح، لذلك يصنف كـ flaky/parallelism risk وليس كسر وظيفي مؤكد.
- لم يتم تعديل أي كود أثناء هذه المراجعة.

## خريطة الصفحات والتبويبات

| المسار | الصفحة | النوع | ملاحظات QA سريعة |
|---|---|---|---|
| `/admin/dashboard` | نظرة عامة | Dashboard | جيدة كمركز تشغيل، تحتاج refresh/drill-down أوضح لكل widget. |
| `/admin/topups` | طلبات الشحن | Finance | واضحة ومحمية، لكن قرارات approve/reject تحتاج confirmation وسبب مخصص. |
| `/admin/wallet-audit` | سجل المحفظة | Finance | جيد، يحتاج filters أقوى حسب الجهة/النوع/الفترة. |
| `/admin/reversals` | طلبات عكس العمليات | Finance | أضعف صفحة؛ تعتمد على ID يدوي ولا تعرض queue للطلبات. |
| `/admin/readiness` | حالة النظام | Finance/Ops | جيدة، لكن أمر verify يحتاج مراجعة صلاحيات إن كان له side effects. |
| `/admin/venues` | الجهات | Content/Ops | غنية جداً، لكنها ثقيلة وتحتاج pagination/server-side search. |
| `/admin/venues/[venueId]` | Workspace الجهة | Tabs | تبويبات wallet/offers/stories/reviews read-only ولا تحفظ state بالرابط. |
| `/admin/media` | الصور والملفات | Tabs/Moderation | قوية في source honesty، لكن replace هو draft/manual وليس command فعلي. |
| `/admin/content/offers` | العروض | Moderation | جيدة، لكن البحث والفلاتر ضمن slice محدود. |
| `/admin/content/stories` | القصص | Moderation | جيدة، لكن نفس مشكلة slice/search والتبويب لا يحفظ الحالة. |
| `/admin/content/reviews` | المراجعات | Moderation | جيدة، لكن route يمرر `canModerate` ثابتاً ولا يستخدم affordances صريحة. |
| `/admin/config` | إعدادات التطبيق | Governance | الفكرة قوية، لكن workflow غير محكم UI-side والأرقام غير الصالحة تتحول إلى 0. |
| `/admin/sign-in` | تسجيل الدخول | Auth | مقبولة، تحتاج مراجعة UX للرسائل فقط. |

## نقاط القوة

- `requireAdminSession` و`requireRouteAccess` مستخدمة قبل تحميل البيانات الحساسة في صفحات الأدمن.
- `guard-api.ts` يحتوي RBAC matrix واضحة ومنفصلة عن UI.
- أغلب الصفحات تعرض حالات `unavailable` و`stale` بوضوح ولا تفبرك نجاحاً وهمياً.
- هناك tests واسعة للـ route guards، surface affordances، command transports، loaders، وUI components.
- `npm run build` يمر بنجاح ويشمل security guard لمنع public privileged tokens.
- مبدأ command proxy/server-side callable موجود، وهذا صحيح أمنياً.

## تحديث الخطة بعد التقييم الهندسي

تم اعتماد تعديلات المراجعة التالية قبل التنفيذ:

- رفع `AWC-QA-007` إلى P1 لأن أوامر الشحن المالية لا يجوز تنفيذها بزر مباشر بدون confirmation/idempotency.
- رفع `AWC-QA-010` إلى P1 مشروط إذا ثبت أن `verify_wallet_readiness` يكتب أو يستهلك عملاً تشغيلياً مكلفاً.
- خفض `AWC-QA-005` إلى P3 لأنه performance/UX وليس safety-critical.
- إضافة `AWC-QA-016` حتى `AWC-QA-020` لتغطية security headers، step-up auth، rate limiting، CSV/PII، وعقد optimistic/pessimistic UI.
- تثبيت استراتيجية البحث في Phase 2 على search tokens داخل Firestore كـ MVP، مع composite cursor ثابت.
- تعديل الجدول الزمني إلى 5-6 أسابيع بدلاً من تقدير مضغوط قد يضغط الاختبارات.

## Findings and Fix Plans

### AWC-QA-001 - P1 - زر Refresh في Reversals يعيد تنفيذ الاعتماد

الدليل:
- الملف: `components/finance/reversal-approval-panel.tsx`
- السطر: `onRefresh={() => void onApprove()}`

المشكلة:
- `CommandRuntimeCallout` يتلقى `onRefresh` لكنه مربوط بـ `onApprove`.
- إذا ضغط المستخدم "تحديث" بعد خطأ أو conflict قد يعيد تنفيذ أمر مالي حساس بدل تحديث القراءة.

الخطر:
- تكرار أمر approval.
- ارتباك للمستخدم بين retry وrefresh.
- اعتماد زائد على idempotency بدل منع الخطأ من الواجهة.

خطة الإصلاح:
1. استيراد `useRouter` داخل `ReversalApprovalPanel`.
2. ربط `onRefresh` بـ `router.refresh()`.
3. إبقاء `onRetry` فقط لإعادة تنفيذ `onApprove`.
4. إضافة test يثبت أن refresh لا يستدعي `runCommand`.

الملفات المقترحة:
- `components/finance/reversal-approval-panel.tsx`
- `components/finance/finance-surfaces.test.tsx` أو test مخصص للـ panel.

اختبارات القبول:
- عند الضغط على Retry يتم استدعاء command.
- عند الضغط على Refresh يتم استدعاء `router.refresh` فقط.
- `npm test components/finance/finance-surfaces.test.tsx`

Prompt تنفيذ:
```text
صلح ReversalApprovalPanel بحيث يكون onRefresh داخل CommandRuntimeCallout تحديثاً للصفحة فقط وليس إعادة تنفيذ approve. أضف test يثبت أن retry ينفذ الأمر وrefresh لا ينفذه، ثم شغل الاختبار المستهدف وnpm run build.
```

### AWC-QA-002 - P1 - Config publish غير محكوم بمرحلة Reviewed والأرقام غير الصالحة تتحول إلى 0

الدليل:
- الملف: `components/config/config-governance-shell.tsx`
- `toNumber()` يحول invalid إلى `0`.
- زر `publish_config` يعتمد فقط على `affordances.canPublish || publishState === "pending"` ولا يمنع النشر UI-side إذا `draftStatus !== "reviewed"`.

المشكلة:
- المستخدم يستطيع محاولة publish قبل review من الواجهة.
- أي قيمة فارغة/غير رقمية قد تتحول إلى 0 بصمت.

الخطر:
- إرسال أسعار خاطئة.
- اعتماد كامل على backend validation مع UX ضعيف.
- أخطاء تشغيلية في إعدادات الأسعار.

خطة الإصلاح:
1. إضافة validation local للأسعار كتحسين UX فقط:
   - كل سعر مطلوب.
   - أرقام صحيحة >= 0.
   - currency ضمن الخيارات المسموحة أو تعرض warning إن كانت legacy.
2. إضافة mirror validation server-side في callable/backend command:
   - رفض القيم السالبة أو غير finite.
   - رفض currency غير مدعوم إلا إذا كان legacy mode مصرحاً صراحة.
   - رفض `publish_config` إذا لم تكن المسودة في حالة `reviewed`.
   - رفض الأوامر بدون reason صالح.
3. إضافة validation للسبب:
   - لا يسمح بحفظ/مراجعة/نشر/استرجاع بدون reason واضح.
4. تعطيل publish إذا `draftStatus !== "reviewed"`.
5. تعطيل review إذا لا توجد draft محفوظة أو إذا draft already reviewed.
6. عرض أخطاء inline بجانب الحقول.
7. إضافة tests:
   - invalid number يمنع command.
   - backend/callable يرفض invalid payload حتى لو تم تجاوز الواجهة.
   - empty reason يمنع command.
   - publish disabled قبل reviewed.
   - publish enabled بعد review success.

الملفات المقترحة:
- `components/config/config-governance-shell.tsx`
- `components/config/config-governance-shell.test.tsx`

اختبارات القبول:
- لا يمكن نشر مسودة غير reviewed من الواجهة.
- لا تتحول القيم غير الصالحة إلى 0.
- تظهر رسالة خطأ عربية واضحة.
- `npm test components/config/config-governance-shell.test.tsx`

Prompt تنفيذ:
```text
شدّد ConfigGovernanceShell والـ config command backend: أضف client validation للأسعار والسبب كـ UX، وmirror validation server-side كـ security. امنع publish قبل reviewed ولا تحول input غير صالح إلى 0. أضف tests للواجهة ولرفض backend payload غير صالح، ثم شغل الاختبار المستهدف وnpm run build.
```

### AWC-QA-003 - P1 - البحث والفلاتر تعمل على slices محدودة فقط

الدليل:
- `lib/content/content-read-loader.ts`: fallback يقرأ `offers` limit 200 و`stories` limit 200.
- `lib/reviews/review-moderation-loader.ts`: fallback يقرأ `collectionGroup("reviews").limit(25)`.
- `lib/venues/venue-directory-read-loader.ts`: fallback يقرأ `venues.limit(limit)`.
- الفلاتر في UI تتم client-side على النتائج المحملة.

المشكلة:
- إذا كان العنصر خارج slice، البحث يعرض "لا توجد نتائج" رغم وجوده في Firestore.
- هذا يؤثر على العروض، القصص، المراجعات، الجهات، وربما media.

الخطر:
- قرارات إشراف خاطئة.
- عدم قدرة الأدمن على إيجاد عناصر موجودة.
- QA manual يعطي نتائج غير ثابتة حسب حجم البيانات.

خطة الإصلاح:
1. توحيد read-query contract:
   - `searchTerm`
   - `status`
   - `venueId`
   - `limit`
   - `cursor`
   - `sort`
   - `queryHash`
2. تمرير الفلاتر من URL query params بدلاً من state local فقط.
3. loader يقرأ من callable مع query params إن متاح.
4. اعتماد استراتيجية search MVP صريحة:
   - إضافة حقول search tokens مسبقة الفهرسة مثل `searchTokens` أو `normalizedNameTokens` حسب الكيان.
   - استخدام Firestore `array-contains`/token prefix للبحث الإداري الأساسي.
   - عدم استخدام Algolia/Typesense في MVP إلا إذا فشلت حدود Firestore فعلياً.
   - إذا بقيت صفحة تستخدم slice محلياً مؤقتاً، يجب عرض warning صريح: "البحث ضمن أول N نتيجة".
5. تثبيت عقد pagination/cursor:
   - الترتيب الافتراضي يجب أن يكون stable مثل `(updatedAt desc, docId desc)` أو `(createdAt desc, docId desc)` حسب الصفحة.
   - cursor يجب أن يحمل القيمتين وليس timestamp فقط.
   - cursor يجب أن يرتبط بـ `queryHash` حتى لا يستخدم مع فلاتر مختلفة.
   - اختبارات pagination يجب أن تثبت عدم تكرار أو اختفاء الصفوف عند تحديث `updatedAt` بين الصفحات.
6. fallback Firestore يدعم query بقدر الإمكان:
   - status filters عبر `where`.
   - pagination via composite cursor.
   - search عبر tokens أو يعرض warning إذا search محلي فقط.
7. UI يعرض عبارة واضحة:
   - "البحث ضمن أول N نتيجة" أو "بحث كامل من الخادم".
8. إضافة pagination controls.

الملفات المقترحة:
- `lib/content/content-read-loader.ts`
- `lib/reviews/review-moderation-loader.ts`
- `lib/venues/venue-directory-read-loader.ts`
- `components/content/offers-management-shell.tsx`
- `components/content/stories-management-shell.tsx`
- `components/reviews/review-moderation-shell.tsx`
- `components/venues/venue-directory-shell.tsx`
- route pages لقراءة `searchParams`.

اختبارات القبول:
- البحث بالـ query param ينعكس في loader.
- عند fallback محدود تظهر رسالة "partial/local-filtered".
- pagination next/prev تعمل ولا تكسر RBAC.
- tests لكل loader مع cursor/filter.
- cursor يستخدم `(sortValue, docId)` ويمنع duplicate/missing rows.
- search tokens ترجع نتيجة خارج أول slice محلي.

Prompts تنفيذ مقسمة:
```text
1. عرّف shared ReadQueryParams وReadPageCursor contract للـ admin loaders، مع queryHash وcomposite cursor `(sortValue, docId)`. أضف tests للـ encode/decode وتغيير الفلاتر.

2. طبّق العقد على reviews loader فقط: URL searchParams، Firestore/callable pagination، search tokens كـ MVP، وwarning إذا fallback محدود. أضف loader tests.

3. حدّث Reviews UI والroute لاستخدام URL-backed filters وpagination controls، مع رسائل "بحث كامل/جزئي". أضف UI tests للـ refresh/back/deep-link.

4. كرر النمط على offers loader وUI بدون تغيير سلوك moderation commands.

5. كرر النمط على stories loader وUI.

6. كرر النمط على venues directory loader وUI، وراقب bundle size.

7. أضف migration/backfill plan لحقول search tokens أو fallback آمن إذا لم تكن موجودة في البيانات الحالية.

8. شغل الاختبارات المستهدفة ثم npm run build.
```

### AWC-QA-004 - P2 - التبويبات الداخلية لا تحفظ حالتها بالرابط ولا تدعم keyboard navigation الكامل

الدليل:
- `components/venue-workspace/venue-workspace-shell.tsx` يستخدم `useState("wallet")`.
- `components/media/media-center-shell.tsx` يستخدم `useState(baseline.sections[0]?.key)`.
- لا توجد query params مثل `?tab=offers`.
- لا يوجد handling للأسهم يمين/يسار داخل `role=tablist`.

المشكلة:
- refresh أو back يعيد المستخدم إلى التبويب الافتراضي.
- مشاركة رابط لتبويب محدد غير ممكنة.
- accessibility ناقصة لمستخدمي الكيبورد.

الخطر:
- UX ضعيف للأدمن.
- صعوبة QA وإعادة إنتاج bugs.
- عدم اكتمال tab semantics.

خطة الإصلاح:
1. استخدام `useSearchParams` و`router.replace` لحفظ tab.
2. دعم `?tab=wallet|offers|stories|reviews`.
3. دعم media section query مثل `?section=proofs`.
4. إضافة keyboard navigation:
   - ArrowLeft/ArrowRight حسب RTL.
   - Home/End.
   - focus selected tab.
5. إضافة tests للتحديث والرابط والكيبورد.

الملفات المقترحة:
- `components/venue-workspace/venue-workspace-shell.tsx`
- `components/media/media-center-shell.tsx`
- tests الخاصة بهما.

اختبارات القبول:
- فتح `/admin/venues/x?tab=reviews` يبدأ على reviews.
- الضغط على tab يحدّث URL دون reload.
- back/forward يغير التبويب.
- keyboard navigation يعمل.

Prompt تنفيذ:
```text
اجعل تبويبات VenueWorkspace وMediaCenter URL-backed مع query params، وأضف keyboard navigation للـ tablist حسب RTL. أضف tests للـ initial tab، تحديث URL، back/forward، وأسهم الكيبورد.
```

### AWC-QA-005 - P3 - Warmup يسجل نجاحاً قبل نجاح الطلب

الدليل:
- `components/admin/admin-shell.tsx`
- `window.sessionStorage.setItem(storageKey, "1")` يحدث قبل `fetch("/api/admin/warmup")`.

المشكلة:
- إذا فشل warmup بسبب network أو 401 transient، لن يعاد في نفس الجلسة.

الخطر:
- فقدان فائدة prefetch/warmup.
- صعوبة قياس performance لأن warmup قد لا يعمل فعلاً.

خطة الإصلاح:
1. استخدم states:
   - `pending`
   - `done`
   - `failed`
2. لا تضع `done` إلا بعد `response.ok`.
3. استخدم `localStorage` مع timestamp وTTL قصير مثل 5 دقائق بدلاً من `sessionStorage` فقط، حتى لا يعاد warmup بلا داعٍ بين tabs.
4. في حالة failed اسمح بمحاولة لاحقة بعد cooldown قصير.
5. لا تجعل failure يؤثر على UI.
6. أضف test يحاكي fetch failure ثم retry.

الملفات المقترحة:
- `components/admin/admin-shell.tsx`
- `components/admin/admin-shell.test.tsx`

اختبارات القبول:
- warmup failure لا يضع done.
- warmup success يضع done.
- لا يتم spam للـ endpoint.

Prompt تنفيذ:
```text
عدّل AdminShell warmup ليحفظ done فقط بعد response.ok، واستخدم localStorage timestamp TTL لتقليل التكرار بين tabs، وأضف pending/failed مع retry cooldown. أضف tests لفشل fetch ثم نجاحه لاحقاً.
```

### AWC-QA-006 - P2 - ضجيج SECURITY_AUDIT أثناء next build

الدليل:
- `npm run build` نجح لكنه طبع عدة `SECURITY_AUDIT` بسبب routes محمية بدون session أثناء static generation.
- `app/(protected)/admin/layout.tsx` يستدعي `requireAdminSession()`.

المشكلة:
- build logs تظهر كأن هناك محاولات اختراق/unauthenticated access.
- CI يصبح noisy وقد يخفي مشاكل حقيقية.

الخطر:
- إرهاق مراقبة security logs.
- false positives في pipelines.

خطة الإصلاح:
1. لا تعيد تصنيف event نفسه بشكل عام حتى لا تخفي runtime attacks.
2. استخدم build context deterministic فقط مثل:
   - `process.env.NEXT_PHASE === "phase-production-build"`
3. أثناء build/prerender فقط، حوّل protected-route redirect logs إلى debug/non-security أو امنع static probing للمسارات المحمية.
4. runtime unauthenticated access يجب أن يبقى `SECURITY_AUDIT`.
5. أضف test يثبت أن runtime denial لا يزال يسجل audit.

الملفات المقترحة:
- `lib/auth/route-guards.ts`
- `lib/auth/admin-security-audit.ts`
- possibly route segment config.

اختبارات القبول:
- `npm run build` لا يطبع SECURITY_AUDIT runtime-like spam.
- security tests ما زالت تمر.

Prompt تنفيذ:
```text
قلل SECURITY_AUDIT noise أثناء next build باستخدام NEXT_PHASE === "phase-production-build" فقط، بدون إعادة تصنيف runtime events. صنف build/prerender redirects كـ non-security debug أو امنع static probing للمسارات المحمية، وأضف test يثبت أن runtime denial ما زال يسجل audit.
```

### AWC-QA-007 - P1 - Topups approve/reject بدون confirmation أو سبب مخصص

الدليل:
- `components/finance/topup-queue-table.tsx` ينفذ approve/reject مباشرة.
- `buildRejectTopUpRequest` يستخدم reason افتراضي.

المشكلة:
- القرار المالي يتم بزر مباشر.
- لا يوجد سبب reject واضح من المستخدم.

الخطر:
- أخطاء بشرية.
- audit trail ضعيف.
- double-submit أو network retry قد يعيد إرسال القرار بدون idempotency صريح.

خطة الإصلاح:
1. إضافة confirmation dialog لكل approve/reject.
2. للرفض: reason required.
3. للاعتماد: reason اختياري لكن يعرض summary المبلغ والجهة.
4. توليد `clientRequestId = uuid()` عند فتح confirmation dialog.
5. تمرير `clientRequestId` مع command payload.
6. backend/proxy يضمن idempotency بناءً على `(commandType, clientRequestId, actorUid)`.
7. منع double submit من الواجهة، لكن لا تعتمد عليه كضمان وحيد.
8. إضافة tests.

الملفات المقترحة:
- `components/finance/topup-queue-table.tsx`
- shared confirmation component إن وجد أو component محلي بسيط.
- tests finance surfaces.

اختبارات القبول:
- approve لا ينفذ قبل confirmation.
- reject لا ينفذ بدون سبب.
- reason يصل للrequest.
- نفس `clientRequestId` لا ينتج قرارين عند retry.

Prompt تنفيذ:
```text
أضف confirmation flow لقرارات TopUpQueueTable. اجعل reject يحتاج سبباً واعرض summary قبل approve. ولّد clientRequestId عند فتح dialog ومرره للcommand، وطبّق idempotency في backend/proxy حتى لا يكرر retry القرار. أضف tests تثبت عدم تنفيذ الأمر قبل التأكيد وأن reason/clientRequestId يمران في payload.
```

### AWC-QA-008 - P2 - Reversals page لا تعرض queue

الدليل:
- `components/finance/reversal-approval-panel.tsx` يطلب إدخال `reversalRequestId` يدوياً.
- لا توجد قراءة لقائمة pending reversals في route.

المشكلة:
- الأدمن لا يعرف الطلبات المنتظرة من الصفحة نفسها.

الخطر:
- اعتماد طلب خاطئ.
- workflow يدوي زائد.
- إذا فتح أدمنان نفس queue، قد يحاولان اعتماد نفس الطلب في نفس الوقت بدون lock واضح.

خطة الإصلاح:
1. إضافة loader لطلبات التصحيح المنتظرة.
2. عرض table بالطلبات:
   - request id
   - original entry
   - venue/user
   - amount
   - expiresAt
   - requestedBy
3. زر approve من الصف.
4. إضافة optimistic locking:
   - كل row يحمل `version` أو `updatedAt`.
   - command يرسل `expectedVersion`.
   - callable يرفض `version mismatch` ويطلب refresh.
5. إبقاء manual ID كـ advanced fallback.
6. إضافة RBAC/tests للـ queue والـ lock conflict.

الملفات المقترحة:
- `lib/finance/finance-read-loader.ts`
- `lib/finance/finance-read-snapshot-transport.ts`
- `components/finance/reversal-approval-panel.tsx`
- `app/(protected)/admin/reversals/page.tsx`

اختبارات القبول:
- الصفحة تعرض pending reversals.
- approve من row يرسل id الصحيح.
- empty/unavailable states واضحة.
- إذا تغيرت النسخة قبل الاعتماد، يعرض conflict ولا يعتمد الطلب.

Prompt تنفيذ:
```text
حوّل صفحة Reversals من إدخال يدوي فقط إلى queue review. أضف loader لقائمة pending reversal requests، table مع approve per row، ومرر expectedVersion للcommand حتى يرفض backend version mismatch. احتفظ manual ID كخيار fallback، وغطِّ empty/unavailable/RBAC/conflict tests.
```

### AWC-QA-009 - P2 - Media replace يظهر كإجراء لكنه ينتج draft/manual copy فقط

الدليل:
- `components/media/media-center-shell.tsx` يحتوي `MediaReplaceDialog`.
- البحث عن `media_replace_draft` يظهر أنه draft payload وليس command فعلي في `lib/media`.

المشكلة:
- الزر "استبدال الملف" قد يوحي بتنفيذ استبدال فعلي.

الخطر:
- توقعات خاطئة للمستخدم.
- خطوات يدوية غير موثقة.

خطة الإصلاح:
1. إما تحويل replace إلى command حقيقي عبر proxy/callable.
2. أو إعادة تسمية الواجهة إلى "إنشاء طلب استبدال يدوي".
3. عرض حالة واضحة: "لن يتم الحفظ في النظام".
4. إضافة copy-to-clipboard reliable + fallback.

الملفات المقترحة:
- `components/media/media-center-shell.tsx`
- `lib/media/media-command-contracts.ts` إذا تحول إلى command.
- `app/api/admin/command/media` إذا أصبح proxy command.

اختبارات القبول:
- المستخدم يعرف إن كان الإجراء فعلياً أو draft.
- لا توجد رسالة نجاح توهم بتغيير backend.

Prompt تنفيذ:
```text
راجع Media Replace UX. إما حوّله إلى command حقيقي عبر media command proxy، أو أعد تسميته كطلب استبدال يدوي مع copy payload واضح ولا تعرض نجاحاً يوحي بتغيير backend.
```

### AWC-QA-010 - P1 إذا كان mutation / P2 إذا كان read-only - Readiness verify متاح لأدوار القراءة

الدليل:
- `FINANCE_COMMAND_METADATA.verify_wallet_readiness.allowedRoles` تشمل `ops_viewer`, `support_admin`, `content_admin`.
- required capability هو `view_readiness`.

المشكلة:
- إذا كان verify يكتب diagnostics أو يشغل backend work، فهذا ليس read-only.
- معيار القرار: أي callable يكتب في Firestore أو يستهلك عملاً تشغيلياً واضحاً `> 100ms` يجب اعتباره mutation/operation وليس read.

الخطر:
- أدوار قراءة تنفذ عمليات تشغيلية.
- تضارب مع مبدأ least privilege.

خطة الإصلاح:
1. تحقق من callable backend: هل `verify_wallet_readiness` write أو read فقط؟
2. إذا write/expensive حسب معيار `write` أو `> 100ms`: أضف capability جديدة `run_readiness_check`.
3. اسمح بها فقط لـ `super_admin` و`finance_admin`.
4. إذا read-only فعلاً: غير label إلى "تحديث القراءة" ووضح أنه آمن.
5. وثق القرار داخل test أو comment قريب من command metadata حتى لا يتغير التصنيف لاحقاً بلا مراجعة.

الملفات المقترحة:
- `lib/finance/command-contracts.ts`
- `lib/auth/guard-api.ts`
- `components/finance/readiness-panel.tsx`
- functions callable إن لزم.

اختبارات القبول:
- ops_viewer لا يرى زر تشغيل فحص إذا كان الأمر mutation.
- finance_admin يراه.
- security tests محدثة.

Prompt تنفيذ:
```text
راجع verify_wallet_readiness: إذا كان يكتب في Firestore أو يستهلك أكثر من 100ms كعمل تشغيلي، اعتبره mutation وأضف capability run_readiness_check واقصره على finance_admin/super_admin. إذا كان read-only فعلاً، وثق ذلك وغير label. حدث UI/tests/security matrix.
```

### AWC-QA-011 - P2 - صفحة الجهات ثقيلة

الدليل:
- `npm run build` يوضح `/admin/venues` بحجم `161 kB First Load JS`.
- `components/venues/venue-directory-shell.tsx` كبير وفيه create/edit/actions/filtering.

المشكلة:
- صفحة الجهات تحمل الكثير من UI دفعة واحدة.

الخطر:
- TTI أبطأ.
- تجربة ضعيفة على أجهزة أقل قوة.

خطة الإصلاح:
1. Lazy-load create/edit dialogs.
2. فصل action cell إلى component مستقل loaded عند الحاجة.
3. نقل filtering/search إلى server-side تدريجياً.
4. إضافة route-level performance budget.

الملفات المقترحة:
- `components/venues/venue-directory-shell.tsx`
- `components/venues/venue-create-dialog.tsx`
- `components/venues/venue-edit-dialog.tsx`

اختبارات القبول:
- build size ينخفض.
- create/edit لا يكسران tests.
- `/admin/venues` يحافظ على نفس السلوك.

Prompt تنفيذ:
```text
خفف bundle صفحة /admin/venues عبر lazy loading للـ create/edit dialogs وفصل action cell. لا تغير السلوك. قارن build output قبل/بعد وأبق tests الخاصة بالvenues ناجحة.
```

### AWC-QA-012 - P2 - Reviews route يمرر canModerate كقيمة ثابتة

الدليل:
- `app/(protected)/admin/content/reviews/page.tsx`
- `<ReviewModerationShell snapshot={snapshot} canModerate />`

المشكلة:
- حالياً route guard يمنع غير content/super، لذلك ليس exploit مباشر.
- لكنه نمط غير متسق مع offers/stories التي تحسب affordances.

الخطر:
- لو تغيرت صلاحيات route لاحقاً سيظهر UI actions بدون تحقق page-level واضح.

خطة الإصلاح:
1. استخدام `computeReviewAffordances(session)`.
2. تمرير `canModerate = canReviewPublish || canReviewHide || canReviewEscalate`.
3. إضافة route test.

الملفات المقترحة:
- `app/(protected)/admin/content/reviews/page.tsx`
- `lib/reviews/review-surface-affordances.ts`
- `components/reviews/review-moderation-route.test.tsx`

اختبارات القبول:
- content_admin يرى actions.
- role بدون moderation لا يرى actions إذا تغير route لاحقاً.

Prompt تنفيذ:
```text
اجعل صفحة reviews تستخدم computeReviewAffordances بدل canModerate ثابت. أضف route test يثبت أن canModerate مبني من session capabilities.
```

### AWC-QA-013 - P3 - Accessibility: dialogs لا تظهر focus trap واضح

الدليل:
- dialogs متعددة في media/venues تستخدم `role="dialog"` و`aria-modal`.
- لم يظهر focus trap أو Escape handling موحد من القراءة.

المشكلة:
- keyboard users قد يخرجون من dialog أو لا يعود focus لمصدر الفتح.

الخطر:
- ضعف accessibility.
- QA keyboard يفشل في flows مهمة.

خطة الإصلاح:
1. إنشاء shared `ModalDialog` بسيط.
2. يدعم:
   - focus initial
   - trap Tab
   - Escape close
   - return focus to opener
3. استخدامه في create/edit/media preview/replace.
4. tests keyboard.

الملفات المقترحة:
- `components/shared/modal-dialog.tsx`
- `components/media/media-center-shell.tsx`
- `components/venues/venue-create-dialog.tsx`
- `components/venues/venue-edit-dialog.tsx`

اختبارات القبول:
- Tab يبقى داخل dialog.
- Escape يغلق.
- focus يعود للزر.

Prompt تنفيذ:
```text
أضف shared ModalDialog مع focus trap وEscape وreturn focus، ثم طبقه تدريجياً على media dialogs وvenue create/edit. أضف keyboard accessibility tests.
```

### AWC-QA-014 - P3 - Filters لا تحفظ state بين الرجوع والتنقل

الدليل:
- أغلب filters في UI state local (`useState`).

المشكلة:
- عند back/refresh تضيع الفلاتر.
- QA لا يستطيع مشاركة رابط لحالة معينة.

الخطر:
- تجربة تشغيل ضعيفة.
- صعوبة التحقيق في bugs.

خطة الإصلاح:
1. نقل filters المهمة إلى URL query params.
2. استخدام debounce للبحث.
3. حفظ pagination/tab/filter معاً.

الملفات المقترحة:
- `components/shared/filter-toolbar.tsx`
- صفحات content/reviews/venues/media.

اختبارات القبول:
- refresh يحافظ على filter.
- رابط مباشر يفتح نفس النتائج.

Prompt تنفيذ:
```text
اجعل الفلاتر المهمة URL-backed في pages الرئيسية، مع debounce للبحث، وغطِّ refresh/back/deep-link tests.
```

### AWC-QA-015 - P3 - Logging performance داخل loaders قد يسبب noise

الدليل:
- عدة loaders تطبع `[PERF]` عبر `console.log`.

المشكلة:
- مفيد أثناء التطوير، لكنه noisy في tests/build/production logs.

الخطر:
- صعوبة قراءة CI logs.
- تضيع security/runtime warnings المهمة.

خطة الإصلاح:
1. إنشاء logger مركزي يحترم env مثل `WAIN_ADMIN_PERF_LOGS=1`.
2. تعطيل logs افتراضياً في test/build.
3. إبقاء إمكانية التفعيل عند التشخيص.

الملفات المقترحة:
- `lib/admin/admin-logger.ts`
- loaders في finance/content/media/venues/dashboard.

اختبارات القبول:
- tests لا تطبع PERF افتراضياً.
- عند env flag تطبع.

Prompt تنفيذ:
```text
استبدل console.log PERF في admin loaders بـ admin logger محكوم بـ env flag. اجعل logs معطلة افتراضياً في tests/build وقابلة للتفعيل عند التشخيص.
```

### AWC-QA-016 - P2 - CSP وsecurity headers غير موثقة كعقد حماية

الدليل:
- يجب مراجعة `next.config.*` وroute headers للتأكد من وجود سياسة headers صريحة للوحة الأدمن.

المشكلة:
- لوحة الأدمن تتعامل مع أوامر مالية ومحتوى حساس.
- بدون CSP وframe protections واضحة، أي XSS أو clickjacking يصبح أثره أعلى.

الخطر:
- سرقة جلسة أدمن أو تنفيذ أوامر privileged عبر injected script.
- embedding للوحة داخل iframe خارجي إذا لم توجد `frame-ancestors`/`X-Frame-Options`.

خطة الإصلاح:
1. إضافة أو توثيق headers في `next.config.*`:
   - `Content-Security-Policy` مبدئياً: `default-src 'self'`.
   - `frame-ancestors 'none'` أو `X-Frame-Options: DENY`.
   - `Strict-Transport-Security` في production فقط.
   - `Referrer-Policy`.
   - `Permissions-Policy`.
2. السماح فقط بالمصادر المطلوبة فعلياً:
   - Firebase/Auth/Functions/Storage endpoints.
   - image/media domains الموثقة.
3. إضافة tests تفحص headers الناتجة.
4. إن كان CSP الكامل سيكسر inline scripts/styles في Next، ابدأ بـ report-only ثم شدده تدريجياً.

اختبارات القبول:
- `next.config` يعيد headers للمسارات `/admin/:path*`.
- iframe embedding مرفوض.
- لا توجد external script origins غير مبررة.

Prompt تنفيذ:
```text
راجع وأضف security headers للـ admin console في next.config: CSP، frame-ancestors/X-Frame-Options، HSTS production-only، Referrer-Policy، Permissions-Policy. اجعل السماحات محصورة بمصادر Firebase/media المطلوبة، وأضف tests للheaders.
```

### AWC-QA-017 - P1 - الأوامر الحساسة تحتاج re-auth أو step-up auth

الدليل:
- أوامر مثل reversal approval، topup approve/reject، config publish/rollback هي أوامر عالية الأثر.
- session verification cache مفيد للأداء لكنه لا يكفي وحده كضمان حديث للإجراءات الحساسة.

المشكلة:
- جلسة قديمة أو جهاز مفتوح يمكن أن ينفذ أمر مالي/حوكمي بدون إعادة تحقق حديثة.

الخطر:
- compromised/stale admin session تنفذ أوامر مالية أو تنشر إعدادات حساسة.

خطة الإصلاح:
1. تعريف قائمة `SENSITIVE_ADMIN_COMMANDS`:
   - `approve_topup`
   - `reject_topup`
   - `approve_reversal`
   - `reverse_wallet_entry`
   - `publish_config`
   - `rollback_config`
2. إضافة شرط `lastReauthAt` أو session freshness:
   - مثال: re-auth مطلوب إذا آخر تحقق أقدم من 10-15 دقيقة.
3. الواجهة تعرض step-up dialog قبل تنفيذ الأمر.
4. backend/proxy يرفض الأمر إذا لم تصل freshness claim/reauth proof صالحة.
5. TOTP أو WebAuthn يمكن أن يكون مرحلة لاحقة، لكن العقد يجب أن يدعمها.

اختبارات القبول:
- sensitive command بجلسة قديمة يعرض re-auth ولا يرسل command.
- backend يرفض payload بدون freshness proof حتى لو تم تجاوز الواجهة.
- command غير حساس لا يطلب step-up.

Prompt تنفيذ:
```text
أضف step-up auth للأوامر الحساسة في admin console. عرّف SENSITIVE_ADMIN_COMMANDS، واطلب re-auth إذا lastReauthAt أقدم من 10-15 دقيقة، واجعل backend/proxy يرفض الأمر بدون freshness proof. غطِّ topup/reversal/config tests.
```

قرار PR 17.1:
- آلية الـ MVP هي re-enter password عبر Firebase re-auth، وليست MFA.
- مدة step-up token هي 15 دقيقة.
- أول نطاق تنفيذ هو finance mutations فقط:
  - `approve_topup`
  - `reject_topup`
  - `reverse_wallet_entry`
  - `approve_reversal`
- `verify_wallet_readiness` لا يدخل في PR 17.1 إلى أن يحسم AWC-QA-010 هل هو read-only أو mutation.
- `config` ينتقل إلى PR لاحق بعد ثبات نمط finance.

حدود هذا الحل:
- إذا كانت كلمة مرور الأدمن compromised، فالـ password step-up compromised أيضاً.
- هذا mitigation للمرحلة الأولى وليس بديلاً عن TOTP/WebAuthn.
- يحتاج AWC-QA-016 لاحقاً لتشديد CSP وتقليل phishing/script-injection risk.
- الـ token يجب أن يكون HTTP-only cookie، `SameSite=Strict`، وTTL قصير.
- production signing key يجب أن يأتي من Secret Manager وليس env مباشر.

### AWC-QA-018 - P1 - Mutations تحتاج rate limiting لكل مستخدم وأمر

الدليل:
- command proxy يسمح بتنفيذ أوامر privileged متعددة حسب الدور.
- لا توجد إشارة واضحة لعقد rate limit على mutations.

المشكلة:
- أدمن compromised أو automation خاطئ يمكنه إرسال عدد كبير من reject/approve خلال دقيقة.

الخطر:
- ضرر مالي وتشغيلي سريع قبل اكتشاف الاختراق.
- audit log يصبح noisy بعد وقوع الضرر وليس حاجزاً قبله.

خطة الإصلاح:
1. إضافة rate limit على مستوى backend/proxy حسب:
   - `actorUid`
   - `commandType`
   - optional target مثل `venueId`
2. استخدام token bucket أو Firestore transactional counter قصير TTL.
3. thresholds أولية:
   - أوامر مالية: منخفضة ومحافظة.
   - أوامر moderation: أعلى لكن محدودة.
4. عند الرفض، أرجع typed error واضح `rate_limited`.
5. سجل audit event منفصل للـ rate limit hit.

اختبارات القبول:
- تجاوز الحد يرجع `rate_limited`.
- rate limit لا يكسر user آخر أو command آخر.
- audit يسجل محاولات التجاوز.

Prompt تنفيذ:
```text
أضف rate limiting للـ admin mutation commands في backend/proxy حسب actorUid وcommandType. استخدم counter/TTL أو token bucket، وأرجع typed rate_limited error مع audit event. أضف tests لأوامر finance والمراجعة.
```

### AWC-QA-019 - P2 - CSV export يحتاج PII/data governance

الدليل:
- صفحة Topups تذكر export، ولم يتم توثيق الحقول المصدرة أو صلاحياتها.

المشكلة:
- CSV قد يحتوي IDs، أرقام هاتف، أسماء، أو بيانات مالية قابلة للمشاركة خارج النظام.

الخطر:
- تسريب PII أو بيانات مالية.
- مخالفة مبدأ least-data export.

خطة الإصلاح:
1. جرد الحقول المصدرة في Topups وWallet Audit وأي export آخر.
2. تصنيف الحقول:
   - public operational
   - internal
   - PII
   - financial sensitive
3. إخفاء أو mask الحقول الحساسة حسب الدور.
4. إضافة audit event لكل export.
5. إضافة warning واضح قبل export إذا يحتوي بيانات حساسة.

اختبارات القبول:
- role بدون صلاحية مالية كاملة لا يصدر PII.
- export يسجل audit event.
- CSV لا يحتوي حقول غير موثقة.

Prompt تنفيذ:
```text
راجع CSV exports في admin console. وثق الحقول، صنف PII/financial sensitive، طبّق masking حسب الدور، وأضف audit event لكل export مع tests تثبت أن الأدوار المحدودة لا تصدر PII.
```

### AWC-QA-020 - P2 - عقد optimistic/pessimistic UI غير موحد بعد commands

الدليل:
- صفحات finance/content تستخدم أنماطاً مختلفة بعد تنفيذ commands: refresh، local state، أو banners.

المشكلة:
- بدون عقد واضح، قد تختفي row قبل تأكيد server أو تبقى بعد نجاح command.
- عند فشل rollback قد يرى المستخدم حالة خاطئة.

الخطر:
- قرارات مالية أو moderation بناءً على UI غير متزامن.
- صعوبة QA لأن السلوك يختلف بين الصفحات.

خطة الإصلاح:
1. تحديد سياسة صريحة:
   - finance commands: pessimistic UI، لا تغير row إلا بعد server success ثم refresh.
   - content moderation: يمكن optimistic فقط إذا يوجد rollback واضح ورسالة conflict.
2. توحيد command result handling:
   - `success`
   - `conflict`
   - `rate_limited`
   - `forbidden`
   - `unavailable`
3. إضافة tests لكل نمط.
4. توثيق policy في ملف قريب من command runtime components.

اختبارات القبول:
- finance row لا تختفي قبل server confirm.
- conflict يعرض refresh/action واضح.
- optimistic rollback يعمل إذا تم استخدامه في content.

Prompt تنفيذ:
```text
عرّف policy موحدة لسلوك UI بعد admin commands: finance pessimistic فقط، content optimistic فقط مع rollback واضح. وحّد result handling للحالات success/conflict/rate_limited/forbidden/unavailable وأضف tests للصفحات المالية والمحتوى.
```

## مراجعة مفصلة حسب الصفحة

### Shell and Navigation

الملفات:
- `components/admin/admin-shell.tsx`
- `components/admin/admin-sidebar.tsx`
- `components/admin/admin-header.tsx`
- `lib/navigation/admin-route-map.ts`

التقييم:
- الـ sidebar مبني من route map وRBAC، وهذا جيد.
- grouping واضح: المالية، المحتوى، النظام.
- hover-intent prefetch جيد للأداء.

التحسينات:
- warmup retry كما في AWC-QA-005.
- استخدام `localStorage` مع TTL للـ warmup بدل نجاح وهمي داخل tab واحد.
- إضافة حالة collapsed/expanded محفوظة للمستخدم.
- تحسين mobile layout إذا sidebar يأخذ مساحة كبيرة.
- إضافة labels للأيقونات إذا أضيفت لاحقاً.

### Dashboard

الملفات:
- `app/(protected)/admin/dashboard/page.tsx`
- `components/dashboard/operational-dashboard-shell.tsx`
- `lib/dashboard/dashboard-loader.ts`

التقييم:
- يعرض ملخصاً جيداً ويدعم stale state.
- `Promise.all` في loader جيد.

التحسينات:
- زر refresh لكل widget.
- links مباشرة عندما تكون counts > 0.
- إضافة "آخر تحديث لكل مصدر" بدلاً من generatedAt العام فقط.
- لو widget unavailable، أظهر action مقترح.

### Topups

الملفات:
- `app/(protected)/admin/topups/page.tsx`
- `components/finance/topup-queue-table.tsx`

التقييم:
- table واضحة.
- export موجود.
- RBAC action affordances جيدة.

التحسينات:
- confirmation modal.
- `clientRequestId` وidempotency لكل approve/reject.
- reject reason required.
- server-side pagination.
- filter حسب الحالة/الجهة/المبلغ.
- audit note واضح.
- مراجعة CSV export للـ PII والحقول المالية.

### Wallet Audit

الملفات:
- `app/(protected)/admin/wallet-audit/page.tsx`
- `components/finance/wallet-audit-table.tsx`

التقييم:
- summary جيد.
- reversal affordance يظهر فقط على debit.

التحسينات:
- filters للفترة والجهة والنوع.
- deep link entry id.
- confirmation قبل reverse.
- توضيح pending_second_approval في table وليس فقط outcome.

### Reversals

الملفات:
- `app/(protected)/admin/reversals/page.tsx`
- `components/finance/reversal-approval-panel.tsx`

التقييم:
- موجود كأمر يدوي فقط.

التحسينات الحرجة:
- إصلاح `onRefresh`.
- إضافة queue.
- validation للـ ID.
- عرض expiry/required second approver.

### Readiness

الملفات:
- `app/(protected)/admin/readiness/page.tsx`
- `components/finance/readiness-panel.tsx`

التقييم:
- summary ممتاز.
- checks مع actions جيدة.

التحسينات:
- راجع صلاحية verify.
- استخدم معيار `write` أو `> 100ms` لتحديد هل verify يحتاج `run_readiness_check`.
- اعرض وقت تشغيل آخر check بوضوح.
- اجعل failure action أكثر تحديداً حسب check.

### Venues Directory

الملفات:
- `app/(protected)/admin/venues/page.tsx`
- `components/venues/venue-directory-shell.tsx`
- `components/venues/venue-create-dialog.tsx`
- `components/venues/venue-edit-dialog.tsx`

التقييم:
- من أغنى صفحات النظام.
- create/edit/status actions موجودة.

التحسينات:
- تقليل bundle.
- server-side search/pagination.
- confirmation status changes.
- validation أقوى للـ coordinates والروابط في UI بجانب backend.
- عرض "partial results" بشكل أكثر بروزاً.

### Venue Workspace Tabs

التبويبات:
- wallet
- offers
- stories
- reviews

التقييم:
- read-only مناسب كبداية.
- read banners لكل tab ممتازة.

التحسينات:
- URL-backed tabs.
- روابط للصفحات المختصة:
  - offer moderation
  - story moderation
  - review moderation
  - wallet audit filtered by venue
- keyboard navigation.
- summary صغير لكل tab حتى قبل فتحه.

### Media Center Tabs

الأقسام:
- proofs
- offer images
- story media
- venue photos

التقييم:
- يعرض source/freshness/reference safety بشكل جيد.
- action sidebar جيد.

التحسينات:
- replace command أو توضيح أنه manual draft.
- URL-backed section.
- preview dialog focus trap.
- server-side media filtering عند البيانات الكبيرة.

### Offers Moderation

الملفات:
- `app/(protected)/admin/content/offers/page.tsx`
- `components/content/offers-management-shell.tsx`
- `components/content/content-action-cell.tsx`

التقييم:
- moderation actions جيدة.
- confirmation panel قبل التنفيذ موجود.

التحسينات:
- server-side filters.
- preserve filter in URL.
- عرض تفاصيل offer أكثر قبل approve/reject.
- السبب الافتراضي حسب نوع action.

### Stories Moderation

الملفات:
- `app/(protected)/admin/content/stories/page.tsx`
- `components/content/stories-management-shell.tsx`

التقييم:
- مشابه للعروض وجيد.

التحسينات:
- لا تكتف باقتطاع أول 50 حرفاً؛ أضف preview/expand.
- server-side filters.
- deep link للحالة.

### Reviews Moderation

الملفات:
- `app/(protected)/admin/content/reviews/page.tsx`
- `components/reviews/review-moderation-shell.tsx`
- `components/reviews/review-action-cell.tsx`

التقييم:
- UI واضح ويدعم البحث والفلاتر.

التحسينات:
- استخدم `computeReviewAffordances`.
- رفع limit أو server-side pagination.
- عرض context أكثر للمراجعة: rating, author, venue, moderation history.

### Config Governance

الملفات:
- `app/(protected)/admin/config/page.tsx`
- `components/config/config-governance-shell.tsx`
- `lib/config/*`

التقييم:
- workflow مقسم إلى خطوات.
- history table موجود.

التحسينات الحرجة:
- validation للأرقام والسبب.
- mirror validation server-side قبل قبول أي command.
- publish disabled قبل reviewed.
- rollback يحتاج confirmation قوي.
- publish/rollback يحتاجان step-up auth إذا كانت الجلسة قديمة.
- إظهار diff بين live/draft قبل النشر.

## خطة تنفيذ مقترحة

### Phase 1 - Safety fixes

الهدف: منع أي أمر حساس من سوء تنفيذ أو UX مضلل.

المدة الواقعية: 5-7 أيام.

المهام:
1. AWC-QA-001: إصلاح Reversal refresh.
2. AWC-QA-002: Config client/server validation وpublish gate.
3. AWC-QA-007: Topup confirmation/reason/idempotency.
4. AWC-QA-008: Reversal queue مع optimistic locking.
5. AWC-QA-010: Readiness capability إذا ثبت أنه mutation/expensive.
6. AWC-QA-017: Step-up auth للأوامر الحساسة.
7. AWC-QA-018: Rate limiting للـ mutation commands.
8. AWC-QA-012: Review affordances بدل canModerate ثابت.

التحقق:
- `npm test components/finance/finance-surfaces.test.tsx`
- `npm test components/config/config-governance-shell.test.tsx`
- `npm test components/reviews/review-moderation-route.test.tsx`
- command proxy/backend tests للـ idempotency وstep-up وrate limiting.
- `npm run build`

### Phase 2 - Data correctness and search

الهدف: منع false negatives في البحث والفلاتر.

المدة الواقعية: 10-14 يوم.

المهام:
1. shared `ReadQueryParams` و`ReadPageCursor` contract.
2. Firestore search tokens كاستراتيجية MVP للبحث.
3. composite cursor ثابت `(sortValue, docId)` مع `queryHash`.
4. reviews loader/UI أولاً.
5. offers loader/UI.
6. stories loader/UI.
7. venues pagination/search.
8. migration/backfill plan للـ search tokens.
9. إظهار partial/local filtering warnings لأي fallback مؤقت.

التحقق:
- loader tests لكل query/cursor.
- UI tests للـ URL-backed filters.
- tests لعدم duplicate/missing rows عند تغير timestamps.
- manual QA على dataset كبير.

### Phase 3 - Tabs and UX continuity

الهدف: تحسين الرجوع والتحديث ومشاركة الروابط.

المدة الواقعية: 5-7 أيام.

المهام:
1. URL-backed tabs في venue workspace.
2. URL-backed sections في media.
3. keyboard navigation للـ tablists.
4. حفظ filters في URL.
5. AWC-QA-019: مراجعة CSV export والـ PII.
6. AWC-QA-020: توحيد optimistic/pessimistic UI بعد commands.

التحقق:
- tests للـ back/forward.
- keyboard tests.
- CSV export governance tests.
- command UI state tests.

### Phase 4 - Accessibility and dialogs

الهدف: رفع جودة الواجهات الحرجة.

المدة الواقعية: 4-5 أيام.

المهام:
1. shared ModalDialog.
2. focus trap.
3. Escape handling.
4. return focus.
5. تطبيقه على media/venues/config confirmations.
6. AWC-QA-016: CSP/security headers إذا لم تنجز في Phase 1.

التحقق:
- Testing Library keyboard tests.
- manual keyboard-only QA.
- header/security tests.

### Phase 5 - Performance and observability

الهدف: تقليل bundle/log noise وتحسين سرعة الأدمن.

المدة الواقعية: 4-5 أيام.

المهام:
1. Lazy load venues dialogs.
2. admin logger للـ PERF logs.
3. warmup success semantics.
4. build-time audit noise reduction.
5. route size budget.

التحقق:
- `npm run build` ومقارنة route sizes.
- `npm test`
- logs نظيفة.

### Timeline واقعي

| المرحلة | التقدير |
|---|---:|
| Phase 1 - Safety | 5-7 أيام |
| Phase 2 - Search/Pagination | 10-14 يوم |
| Phase 3 - Tabs/UX/Data governance | 5-7 أيام |
| Phase 4 - Accessibility/Security headers | 4-5 أيام |
| Phase 5 - Performance/Observability | 4-5 أيام |
| المجموع الواقعي | 5-6 أسابيع |

## QA Checklist بعد كل Phase

- تسجيل دخول super_admin.
- تسجيل دخول finance_admin.
- تسجيل دخول content_admin.
- تسجيل دخول support_admin أو ops_viewer.
- التأكد من sidebar routes حسب الدور.
- فتح كل route مباشرة من URL والتأكد من guard.
- اختبار empty state.
- اختبار unavailable state إذا أمكن عبر mock/env.
- اختبار stale banner.
- اختبار command success.
- اختبار command conflict.
- اختبار forbidden command.
- اختبار idempotency لنفس `clientRequestId`.
- اختبار rate limit لأوامر mutation.
- اختبار step-up auth عند جلسة قديمة.
- اختبار refresh/back/deep link.
- اختبار keyboard-only للتبويبات والdialogs.
- اختبار CSV export حسب الدور وعدم تسريب PII.
- اختبار security headers للمسارات الإدارية.
- تشغيل `npm test`.
- تشغيل `npm run build`.

## Done Criteria للمراجعة القادمة

- لا توجد P1 مفتوحة.
- `npm test` يمر بدون flaky timeout أو يتم عزل/تصحيح الاختبار.
- `npm run build` يمر بدون security audit noise غير ضروري.
- كل command مالي حساس لديه confirmation أو سبب واضح.
- كل command مالي حساس لديه `clientRequestId` وidempotency backend.
- كل command حساس يطبق step-up auth عند session قديمة.
- كل mutation command لديه rate limit موثق ومختبر.
- validation الحساسة موجودة في الواجهة والbackend معاً.
- كل tab مهم URL-backed.
- كل filter رئيسي URL-backed أو عليه تحذير أنه local/partial.
- search/pagination تستخدم composite cursor ثابت أو توثق fallback مؤقت.
- CSV exports مصنفة ومقيدة حسب الدور.
- security headers مفعلة أو يوجد CSP report-only plan واضح.
- لا يوجد UI يوحي بنجاح backend عند عدم تنفيذ command فعلي.
