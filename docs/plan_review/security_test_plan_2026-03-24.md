# Security Test Plan

## Goal
تنفيذ اختبار أمني عملي على التطبيق مع التركيز على:
- دخول التاجر وربط الحساب بالمحل
- صلاحيات التاجر بعد التفعيل
- تدفقات العرض `claim -> validate -> redeem`
- صلاحيات Firestore / Storage
- الدوال الحساسة المحمية بـ `App Check`

هذا الملف ليس pentest أكاديمي.  
هو checklist عملية مبنية على الكود الحالي في:
- `functions/src/index.ts`
- `firestore.rules`
- `storage.rules`
- `lib/features/merchant/presentation/screens/merchant_invite_screen.dart`
- `lib/features/merchant/presentation/providers/merchant_dashboard_providers.dart`
- `lib/features/merchant/presentation/screens/merchant_scan_screen.dart`
- `lib/features/offers/**`

---

## Important Rule Before Testing
نفّذ الاختبارات المدمرة أو التي فيها تعديل بيانات على:
- Firebase Emulator Suite
أو:
- مشروع staging منفصل

لا تختبر سيناريوهات تخريبية مباشرة على production إلا إذا كانت:
- controlled
- قابلة للعكس
- ومفهومة الأثر

---

## Priority Order
1. Merchant entry / invite takeover
2. Merchant authorization boundaries
3. Offer claim / redeem abuse
4. Storage ownership bypass
5. App Check enforcement regression
6. Guest vs authenticated data isolation
7. Rate limit / replay / reuse scenarios

---

## Preconditions / Test Data
جهّز قبل التنفيذ:

1. `merchant A`
- مربوط بـ `venue A`

2. `merchant B`
- مربوط بـ `venue B`

3. `venue A`
- فيها:
  - story واحدة على الأقل
  - offer amount
  - offer percent
  - offer `single_use_per_customer`

4. `venue B`
- مختلفة تمامًا عن `venue A`

5. invite codes
- invite صالح
- invite منتهي
- invite مستخدم

6. claims
- claim pending صالح
- claim pending منتهي
- claim redeemed

7. user accounts
- user authenticated A
- user authenticated B
- guest device id ثابت

8. time control
- لا تعتمد على الانتظار الفعلي لاختبارات `expires_at` أو `durationDays`
- الأفضل:
  - إنشاء بيانات اختبار منتهية أصلًا
  - أو backdated documents في emulator/staging
  - أو أي time-control ثابت غير flaky

---

## Test Metadata
سجّل لكل مجموعة اختبارات:
- `Severity`: `Critical / High / Medium`
- `Owner`: `Backend / Mobile / Rules / Infra`
- `Execution Mode`: `Manual / Emulator script / Rules unit test / Callable script`
- `Bug Classification`: `Security bug / Logic bug / Product decision / Hardening improvement`
- `Verification Method`: كيف نحكم أن الاختبار Pass فعلًا
- `Evidence Required`:
  - screenshot
  - app log
  - function log
  - Firestore document before/after
  - Storage object before/after

---

## Verification Method Rule
لا يعتبر الاختبار `Pass` إذا تحقق فقط:
- UI message
أو:
- log line
أو:
- function response

في الاختبارات الحساسة، الحد الأدنى هو:
1. Response/UI correct
2. State verification:
- Firestore document before/after
أو:
- Storage object before/after
3. Server evidence:
- function log
أو:
- emulator/rules output

إذا غاب واحد من هذه العناصر في اختبار حساس، تسجل النتيجة:
- `Incomplete verification`

---

## Cleanup / Reset Rules
بعد الاختبارات التي تغيّر بيانات:

1. احذف claims التجريبية إذا كانت بيئة staging/emulator
2. أعد reset لأي invite استُهلك لأغراض الاختبار فقط
3. أعد counters أو أعد seed للـ offers إذا كان الاختبار يعتمد على counts دقيقة
4. احذف ملفات test من:
- `venues/{venueId}/photos/*`
- `venues/{venueId}/stories/*`
5. دوّن أي data لا يمكن حذفها بسهولة في تقرير النتائج حتى لا تختلط على الجولة التالية

---

## A. Merchant Entry Security

## Why This Is High Risk
لأن `redeemInviteCode` هو الباب الذي يحول مستخدمًا عاديًا إلى تاجر فعلي، ويربطه بـ:
- `users/{uid}.merchant_venue_id`
- `users/{uid}.is_merchant`
- `merchants/{uid}`

أي خلل هنا يعني escalation of privilege مباشر.

## Files
- `functions/src/index.ts`
- `firestore.rules`
- `lib/features/merchant/presentation/providers/merchant_dashboard_providers.dart`

## Severity / Owner / Execution / Classification / Evidence
- `Severity`: `Critical`
- `Owner`: `Backend + Rules`
- `Execution Mode`: `Manual + Callable script`
- `Bug Classification`: `Security bug`
- `Verification Method`:
  - UI result + function log + `users/{uid}` before/after + `merchants/{uid}` before/after
- `Evidence Required`:
  - screenshot of UI result
  - function log
  - `users/{uid}` before/after
  - `merchants/{uid}` before/after
  - `merchant_invites/{inviteId}` before/after

## Test A1: Invalid Invite Code
### Steps
1. سجل دخول بحساب مستخدم عادي
2. افتح `Merchant Invite`
3. أدخل كود عشوائي مثل:
   - `WAIN-000000`
4. اضغط تحقق

### Expected
- لا يتفعّل الحساب كتاجر
- تظهر رسالة `invalid / not found`
- لا يتغير:
  - `users/{uid}.merchant_venue_id`
  - `users/{uid}.is_merchant`
- لا يتم إنشاء `merchants/{uid}`

## Test A2: Expired Invite Code
### Steps
1. أنشئ أو استخدم كود منتهي
2. نفّذ نفس تدفق التفعيل

### Expected
- فشل واضح
- لا توجد أي كتابة جزئية

## Test A3: Reuse Used Invite Code
### Steps
1. فعّل كود مرة أولى بحساب صالح
2. استخدم نفس الكود بحساب ثانٍ

### Expected
- المرة الثانية تفشل
- لا يحصل user2 على merchant link

## Test A4: Account Already Linked To Different Venue
### Steps
1. استخدم حساب تاجر مربوط بمحل A
2. أدخل كود صالح لمحل B

### Expected
- العملية تفشل
- الربط الحالي لا يتغير
- لا يحدث overwrite صامت

## Test A5: App Check Bypass On Invite
### Steps
1. جرّب استدعاء `redeemInviteCode` من client غير موثق أو بيئة بدون App Check
2. أو عطّل debug token مؤقتًا على بيئة الاختبار

### Expected
- `App Check verification failed`
- لا يحدث أي تعديل في Firestore

## Test A6: Rate Limit On Invite Retries
### Steps
1. بحساب واحد، جرّب عدة مرات بكود خاطئ بسرعة

### Expected
- بعد حد معين، تظهر `resource-exhausted / rate limited`
- لا توجد writes جانبية

## Section Cleanup
- reset أي invite اختباري استُهلك
- وثّق أو أعد baseline لأي user linking حصل أثناء الاختبار

---

## B. Merchant Authorization Boundaries

## Goal
التأكد أن التاجر لا يستطيع إدارة أو استرداد أو رفع محتوى لمحل ليس له.

## Files
- `functions/src/index.ts`
- `firestore.rules`
- `storage.rules`

## Severity / Owner / Execution / Classification / Evidence
- `Severity`: `Critical`
- `Owner`: `Backend + Rules + Storage`
- `Execution Mode`: `Callable script + Rules test + Manual`
- `Bug Classification`: `Security bug`
- `Verification Method`:
  - denied action + unchanged target venue/path/doc + log evidence
- `Evidence Required`:
  - function log
  - Firestore read/write result
  - screenshot or CLI output of permission error

## Test B1: Merchant Reads Only Own Merchant Doc
### Steps
1. سجّل كتاجر A
2. عبر Firestore console أو emulator client أو script، حاول قراءة:
   - `merchants/{merchantBUid}`

### Expected
- `permission-denied`

## Test B2: Merchant Cannot Redeem Claim For Another Venue
### Steps
1. أنشئ claim لمحل A
2. سجّل كتاجر محل B
3. امسح QR وحاول redeem

### Expected
- `permission-denied`
- لا تتغير حالة claim

## Test B3: Merchant Cannot Promote Story Of Another Venue
### Steps
1. كتاجر A، خذ `storyId` لمحل B
2. حاول استدعاء `promoteStory`

### Expected
- فشل
- لا يتم تعديل الستوري

## Test B4: Merchant Backfill Analytics Boundary
### Steps
1. كتاجر A، نفّذ `backfillMerchantAnalytics`
2. راقب أن التعديلات تخص venue A فقط

### Expected
- لا يوجد أي أثر على venue أخرى

## Section Cleanup
- أزل أي story/file/claim تجريبي استُخدم لهذا المسار
- راجع أن merchant A و merchant B عادا لحالة baseline

---

## C. Offer Claim / Redeem Abuse

## Why This Is High Risk
لأنها تمس:
- counting
- confirmed savings
- merchant validation
- إمكانية reuse أو replay

## Files
- `functions/src/index.ts`
- `lib/features/merchant/presentation/screens/merchant_scan_screen.dart`
- `lib/features/offers/data/repositories/offers_repository.dart`

## Severity / Owner / Execution / Classification / Evidence
- `Severity`: `Critical`
- `Owner`: `Backend + Mobile`
- `Execution Mode`: `Manual + Callable script`
- `Bug Classification`: `Security bug / Logic bug`
- `Verification Method`:
  - function response + claim/offer docs before/after + UI stats/claims
- `Evidence Required`:
  - claim document before/after
  - offer document before/after
  - user stats before/after
  - function log
  - screenshot of UI result

## Test C1: Claim Token Creation Without Auth
### Steps
1. نفّذ claim كضيف في الحالات المسموح بها
2. وحاول claim من بيئة غير موثقة أو بدون App Check

### Expected
- السلوك يتبع policy الحالية فقط
- لا bypass لـ App Check

## Test C1b: Guest Claim Without deviceId
### Steps
1. استدعِ `createClaimToken` بدون `deviceId`

### Expected
- `invalid-argument`
- لا يتم إنشاء claim

## Test C1c: Single Use Guest Reuse On Same Device
### Steps
1. كضيف على `deviceId` ثابت، أنشئ claim وكمّله حتى redeem لعرض `single_use_per_customer`
2. أعد `createClaimToken` لنفس العرض ونفس `deviceId`

### Expected
- يفشل بـ `offer_already_used`

## Test C2: Validate Token Replay
### Steps
1. أنشئ claim صالح
2. نفّذ `validateToken`
3. أعد نفس العملية عدة مرات

### Expected
- لا يحصل استهلاك مزيف
- التحقق لا يحوّل claim إلى redeemed

## Test C3: Redeem Same Token Twice
### Steps
1. استرد claim صالح مرة
2. أعد scan/redeem لنفس الـ QR

### Expected
- المرة الثانية تفشل
- لا تتضاعف الإحصائيات

## Test C3b: Redeem Expired Token
### Steps
1. أنشئ claim
2. انتظر انتهاء `expires_at`
3. حاول redeem

### Expected
- `Token expired`
- لا تتغير counters
- لا يتحول claim إلى `redeemed`

## Test C4: Percent Offer With Bill Amount
### Steps
1. أنشئ عرض نسبة
2. اطلب العرض كمستخدم مسجّل
3. التاجر يمسح QR
4. يدخل قيمة فاتورة
5. redeem

### Expected
- claim يتحول إلى `redeemed`
- `applied_bill_amount` محفوظ
- `applied_savings` محفوظ
- `User Stats`:
  - `used offers` يزيد
  - `confirmed savings` يزيد

## Test C5: Percent Offer Without Bill Amount
### Steps
1. كرر السيناريو لكن بدون إدخال الفاتورة

### Expected
- `used offers` يزيد
- `confirmed savings` لا يزيد لهذا claim

## Test C6: Cross-User Claim Leakage
### Steps
1. مستخدم A يطلب عرض
2. مستخدم B يفتح `My Claims` أو `User Stats`

### Expected
- لا يرى claims الخاصة بـ A
- لا يحصل خلط `device_id/user_id` للمستخدم المسجّل

## Test C7: Client Payload Tampering On createClaimToken
### Steps
1. استدعِ `createClaimToken`
2. مرر:
   - `offerId` صحيح
   - `venueId` يدويًا لكن لمحل مختلف

### Expected
- `invalid-argument` أو `venue_mismatch`
- لا يتم إنشاء claim

## Test C8: Client Payload Tampering On redeemToken
### Steps
1. استدعِ `redeemToken`
2. مرر:
   - `billAmount` سالب
   - `billAmount` صفر
   - `billAmount` نص غير رقمي
   - `billAmount` decimal غريب أو كبير جدًا
   - حقول إضافية لا يحتاجها السيرفر

### Expected
- القيم غير الصالحة تُرفض
- الحقول الإضافية لا تؤثر على المنطق

## Test C9: Cross-User Redeem With Borrowed QR
### Steps
1. المستخدم A ينشئ claim صالح
2. المستخدم B يحصل على QR/token الخاص بالمستخدم A
3. التاجر يمسح QR ويحاول redeem

### Expected
- إذا نجح redeem فقط لأن QR صالح، سجّل النتيجة كـ:
  - `Product decision / bearer-token risk`
- إذا كان المطلوب أمنيًا أن يكون QR مرتبطًا بهوية صاحب claim، فنجاح هذا السيناريو يعتبر:
  - `Security bug`

## Test C10: Offer Deactivation During Active Claim
### Steps
1. أنشئ claim صالح على عرض نشط
2. قبل redeem، أوقف العرض أو ألغِ تفعيله
3. حاول validate ثم redeem

### Expected
- لا يجب redeem claim على عرض لم يعد `available`
- إذا فشل validate/redeem بسبب حالة العرض، فهذا السلوك صحيح
- إذا تم redeem رغم أن العرض لم يعد متاحًا، فهذا `Logic bug`

## Policy Note: Guest Claim Visibility
الـ policy الحالية تسمح للضيف بإنشاء claim عبر `device_id`، لكن `offer_claims` نفسها ليست readable مباشرة عبر Firestore rules للضيف.

هذا يعني:
- guest claim creation = مسموحة حسب policy
- guest claim history direct Firestore read = غير مسموحة حاليًا

هذا **قرار منتجي/أمني** وليس بالضرورة bug.

## Risk Note: Guest Device Reset
التحكم الحالي للضيف يعتمد على `deviceId` محلي.

في التطبيق الحالي، `deviceId` يُخزن محليًا في `SharedPreferences`.
هذا يعني أن:
- `Clear App Data`
- أو إعادة تثبيت التطبيق
- أو التلاعب المحلي في الـ identifier

قد يؤدي إلى `deviceId` جديد، وبالتالي إعادة محاولة عروض `single_use_per_customer` للضيف.

هذا لا يعتبر bypass للخادم نفسه، لكنه:
- `Weak anti-abuse control`
- ويجب تسجيله كـ:
  - `Known risk`
  - أو `Product/security limitation`

## Test C1d: Guest Device Reset / Clear App Data
### Steps
1. كضيف، استخدم عرض `single_use_per_customer` حتى redeem
2. امسح بيانات التطبيق أو غيّر `deviceId` في بيئة الاختبار
3. أعد claim لنفس العرض

### Expected
- إذا نجح claim مرة ثانية:
  - سجّل النتيجة كـ `Known risk`
  - وليست surprise regression

## Section Cleanup
- احذف أو reset claims التجريبية
- أعد offers counters إذا اعتمد الاختبار على baseline واضح

---

## D. Firestore Rules Tests

## Goal
اختبار القواعد مباشرة لا فقط عبر الواجهة.

## Recommended
استخدم:
- Firebase Emulator Suite
- rules unit tests

## Collections To Attack
- `users`
- `merchants`
- `merchant_invites`
- `offer_claims`
- `venues`
- `stories`
- `reviews`

## Severity / Owner / Execution / Classification / Evidence
- `Severity`: `High`
- `Owner`: `Rules`
- `Execution Mode`: `Rules unit test + Emulator script`
- `Bug Classification`: `Security bug / Product decision`
- `Verification Method`:
  - rules/emulator denial + unchanged document state
- `Evidence Required`:
  - emulator rule test output
  - denied reads/writes screenshots or logs
  - before/after document state

## Test D1: User Profile Escalation
### Steps
1. بحساب مستخدم عادي، حاول تعديل:
   - `merchant_venue_id`
   - `is_merchant`

### Expected
- مرفوض

## Test D2: Direct Merchant Invite Read
### Steps
1. حاول قراءة `merchant_invites` من client

### Expected
- مرفوض

## Test D3: Offer Claims Access Rules
### Steps
1. المستخدم A يحاول قراءة claim يخص المستخدم B
2. guest يحاول قراءة claim مصمم لمستخدم مسجّل

### Expected
- مرفوض

## Test D3b: Offer Claims Query / List Enumeration
### Steps
1. بحساب مستخدم عادي، حاول تنفيذ query/list على `offer_claims`
2. لا تعتمد على document id محدد

### Expected
- query لا تسرب claims لمستخدمين آخرين
- إذا فشل query بالكامل فهذا مقبول
- إذا أعاد claims لا يملكها المستخدم فهذا `Security bug`

## Test D4: Venue Write Boundary
### Steps
1. مستخدم عادي أو تاجر venue أخرى يحاول تعديل venue لا يملكها

### Expected
- مرفوض

## Test D5: navigation_clicks Spam Boundary
### Steps
1. بدون auth، حاول create متكرر في `navigation_clicks`
2. اجعل `user_id == null`

### Expected
- إذا نجح، سجّلها كـ `Needs decision`
- لأن هذا السلوك permissive حاليًا وقد يفتح spam

### Decision Owner / SLA
- `Owner`: `Backend + Product`
- `Decision Required Before`: أي pilot مفتوح أو soft launch أوسع

## Test D6: Offer Stats Tampering
### Steps
1. كتاجر مالك للعرض، حاول تعديل:
   - `claims_count`
   - `redeemed_count`
   - `conversion_rate`
   - `last_redeemed_at`

### Expected
- مرفوض
- rule `touchesServerOfferFields` تمنع التلاعب

## Section Cleanup
- احفظ outputs قبل reset emulator أو staging state

---

## E. Storage Rules Tests

## Goal
منع رفع/حذف ملفات لمحل غير مملوك.

## Files
- `storage.rules`

## Severity / Owner / Execution / Classification / Evidence
- `Severity`: `High`
- `Owner`: `Storage + Rules`
- `Execution Mode`: `Manual + Emulator script`
- `Bug Classification`: `Security bug`
- `Verification Method`:
  - denied storage op + object before/after + path check
- `Evidence Required`:
  - storage error output
  - before/after file state
  - screenshot or CLI log

## Paths To Test
- `venues/{venueId}/photos/{fileName}`
- `venues/{venueId}/stories/{fileName}`

## Test E1: Upload Photo To Another Venue
### Steps
1. كتاجر A، حاول رفع إلى path خاص بـ venue B

### Expected
- `storage unauthorized`

## Test E2: Upload Story Media To Another Venue
### Steps
1. كتاجر A، حاول رفع صورة/فيديو إلى stories path لــ venue B

### Expected
- مرفوض

## Test E3: File Type And Size Boundaries
### Steps
1. ارفع ملف غير image/video
2. ارفع صورة أكبر من 5MB
3. ارفع فيديو أكبر من 50MB

### Expected
- مرفوض

## Test E3b: MIME Spoof With Renamed Extension
### Steps
1. جهّز ملف نصي أو غير صورة
2. غيّر اسمه إلى `.jpg` أو `.png`
3. حاول رفعه

### Expected
- القرار يعتمد على `contentType` وليس اسم الملف فقط
- إذا تم قبوله فقط لأن الاسم يبدو كصورة فهذه مشكلة

## Test E4: Delete Another Venue File
### Steps
1. كتاجر A، حاول حذف ملف photos أو stories لمحل B

### Expected
- `storage unauthorized`

## Test E5: Overwrite Existing Known Filename
### Steps
1. كتاجر A، جرّب overwrite لاسم ملف موجود في venue B

### Expected
- مرفوض

## Test E6: Update Existing File Boundary
### Steps
1. كتاجر A، حاول update على ملف قائم في venue B

### Expected
- مرفوض

## Test E7: Nested Path Spoof / Path Traversal Style Attempt
### Steps
1. كتاجر A، حاول إنشاء object name يحتوي segments مثل:
   - `../../../venueB/photos/hacked.jpg`
   - أو أي nested path يوحي بالخروج من tenant path
2. نفّذ الرفع إلى storage path تجريبي

### Expected
- لا يحصل أي bypass لملكية `venueId`
- إذا انتهى الملف داخل path غير مملوك أو تجاوز المسار المتوقع فهذه `Security bug`

## Note
في Cloud Storage هذا ليس OS path traversal حرفيًا، لكنه ما يزال اختبارًا مهمًا ضد:
- nested path spoof
- object key manipulation

## Section Cleanup
- احذف كل ملفات الاختبار من المسارات المسموحة
- وثّق أي object لم يُنظف

---

## F. App Check Enforcement Regression

## Goal
التأكد أن تشديد App Check لم يترك gaps، ولم يكسر flows الأساسية.

## Callables To Verify
- `createClaimToken`
- `validateToken`
- `redeemToken`
- `redeemInviteCode`
- `promoteStory`
- `trackVenueEvent`
- `backfillMerchantAnalytics`
- `searchVenuesInBounds`

## Severity / Owner / Execution / Classification / Evidence
- `Severity`: `High`
- `Owner`: `Backend + Infra`
- `Execution Mode`: `Manual + Callable script`
- `Bug Classification`: `Hardening improvement / Security bug`
- `Verification Method`:
  - callable behavior + no unintended writes + App Check evidence/logs
- `Evidence Required`:
  - app log
  - function log
  - Firebase App Check console evidence if needed

## Test F1: Valid App Instance
### Steps
1. شغّل التطبيق بإصدارك الحالي
2. جرّب كل flow من flows أعلاه

### Expected
- ينجح طبيعيًا

## Test F2: Invalid / Missing App Check
### Steps
1. اختبر من بيئة غير مهيأة أو بدون debug token في staging

### Expected
- يفشل الاستدعاء
- لا توجد writes جانبية

## Test F3: Replay Of Captured Legitimate Request
### Steps
1. التقط request شرعيًا من داخل التطبيق في بيئة اختبار
2. أعد إرسال نفس request أكثر من مرة

### Expected
- إذا كانت replay protection مفعلة على Firebase/App Check، يجب رفض replay
- وإذا لم تكن مفعلة، يجب أن تبقى:
  - auth
  - authorization
  - idempotency
  - transaction checks
كافية لمنع side effects الإضافية

## Replay Protection Note
تحقق صراحة هل high-risk callables تستخدم:
- Firebase App Check Replay Protection
أو:
- consumed App Check tokens

إذا لم تكن مفعلة، وثّق ذلك كطبقة غير مستخدمة حاليًا، ولا تفترض أن App Check وحده يمنع replay من عميل شرعي.

## Important Note
App Check طبقة إضافية فقط.  
حتى لو تم تعطيلها في بيئة ما، يجب أن تبقى:
- auth
- authorization
- ownership checks

كافية وحدها لمنع الوصول غير المصرح به.

## Section Cleanup
- أعد debug token أو App Check state إذا عُدّل للاختبار

---

## G. Input Validation Matrix

## Goal
التأكد أن الفشل ليس فقط authorization failure، بل أيضًا validation failure واضحة وصحيحة.

## Files / Functions
- `functions/src/index.ts`
  - `createClaimToken`
  - `validateToken`
  - `redeemToken`
  - `redeemInviteCode`
  - `promoteStory`

## Severity / Owner / Execution / Classification / Evidence
- `Severity`: `High`
- `Owner`: `Backend`
- `Execution Mode`: `Callable script + Manual`
- `Bug Classification`: `Security bug / Logic bug`
- `Verification Method`:
  - exact error code/message family + no writes + function log
- `Evidence Required`:
  - request payload
  - response error code
  - function log
  - document before/after

## Cases
- invite code format malformed
- QR/token malformed
- `billAmount` invalid
- `billAmount = NaN`
- `billAmount = Infinity`
- `billAmount = -Infinity`
- `billAmount > Number.MAX_SAFE_INTEGER`
- `billAmount` كسلسلة ضخمة جدًا (مثل 10MB نص)
- `storyId` malformed
- `venueId` malformed or mismatched
- `offerId` malformed
- `deviceId` missing or malformed
- `deviceId` كسلسلة ضخمة جدًا (مثل 10MB نص)
- `durationDays` خارج النطاق
- JSON إضافي يحاول `__proto__` أو حقول غير متوقعة

## Expected
- `invalid-argument` أو error code واضح
- لا توجد writes جزئية

---

## H. Concurrency / Replay Under Load

## Goal
كشف المشاكل التي لا تظهر في الاختبارات التسلسلية.

## Files / Functions
- `functions/src/index.ts`
  - `createClaimToken`
  - `validateToken`
  - `redeemToken`
  - `redeemInviteCode`

## Severity / Owner / Execution / Classification / Evidence
- `Severity`: `Critical`
- `Owner`: `Backend`
- `Execution Mode`: `Callable script + Parallel device/manual`
- `Bug Classification`: `Security bug / Logic bug`
- `Verification Method`:
  - parallel request result matrix + before/after docs + counters + timestamped logs
- `Evidence Required`:
  - function logs with timestamps
  - claim/offer documents before/after
  - counters before/after

## Recommended Tooling
لا تعتمد على التنفيذ اليدوي فقط في هذه المجموعة.

الأدوات المفضلة:
1. `custom Node script`
- باستخدام `Promise.all()` لاستدعاءات متوازية

2. `k6`
- لسيناريوهات load/retry المنظمة

3. `Artillery`
- إذا أردت replay/retry patterns أوسع

## Test H1: Redeem Same Token From Two Devices Simultaneously
### Steps
1. جهّز claim صالح
2. افتح جهازين للتاجر أو استدعاءين متوازيين
3. نفّذ redeem في نفس اللحظة تقريبًا

### Expected
- redeem واحد فقط ينجح
- الثاني يفشل
- `redeemed_count` يزيد مرة واحدة فقط
- claim تبقى بحالة نهائية واحدة فقط

## Test H2: Validate And Redeem Simultaneously
### Steps
1. جهاز A ينفّذ `validateToken`
2. جهاز B ينفّذ `redeemToken` في نفس النافذة الزمنية

### Expected
- لا يحدث corruption
- validation قد ترجع stale preview لكن بدون side effect
- redeem يحدد الحالة النهائية وحده

## Test H3: Repeated createClaimToken Under Retry
### Steps
1. لنفس `offerId` و`deviceId` و`userId`
2. أرسل الطلب مرتين بسرعة أو مع network retry

### Expected
- لا يتم إنشاء عدة pending claims غير لازمة
- إذا حصل أكثر من مستند، تسجل النتيجة كـ bug منطقي/أمني

## Test H4: Repeat Same Callable After Network Retry
### Steps
1. أعد إرسال نفس طلب:
   - `redeemInviteCode`
   - `redeemToken`
   - `validateToken`
2. مع payload نفسه

### Expected
- لا تحدث side effects إضافية
- إذا كان الطلب غير idempotent، يجب أن يفشل safely

## Pass Criteria
### H1
- exactly `1` successful redeem
- exactly `1` failed redeem
- `redeemed_count delta = 1`
- `claim.status = redeemed` بحالة نهائية واحدة فقط

### H2
- لا يوجد corruption
- الحالة النهائية للـ claim واحدة وواضحة
- لا يوجد counter delta غير متوقع

### H3
- لا تتكون عدة pending claims غير لازمة لنفس actor/window

### H4
- retry لا يضاعف side effects
- failure أو duplicate handling يكون safe ومفهوم

## Engineering Note
إذا فشل `H1` أو `H4` وظهر:
- double redeem
- أو counter duplication

فالحل المقبول هندسيًا هو:
- إبقاء كل checks + state transition + counter updates داخل `Firestore Transaction`
- وعدم الاعتماد على `read ثم write` المنفصل

مهم:
- `redeemToken` عندنا أصلًا يستخدم transaction
- لذلك فشل هذا الاختبار يعني bug في transaction guards أو حدود الـ state machine، لا غياب transaction بحد ذاته

## Section Cleanup
- احذف claims التجريبية واحفظ timestamped logs قبل reset البيئة

---

## I. Audit Logging And Traceability

## Goal
التأكد أن العمليات الحساسة قابلة للمراجعة لاحقًا.

## Files / Functions
- `functions/src/index.ts`
  - `redeemInviteCode`
  - `redeemToken`
  - `promoteStory`
  - `backfillMerchantAnalytics`

## Severity / Owner / Execution / Classification / Evidence
- `Severity`: `Medium`
- `Owner`: `Backend + Infra`
- `Execution Mode`: `Manual + Log review`
- `Bug Classification`: `Hardening improvement`
- `Verification Method`:
  - minimum fields موجودة في log/document trail
- `Evidence Required`:
  - function logs
  - any persisted audit document if present
  - before/after state

## Operations To Check
- merchant activation
- redeem
- promote story
- analytics backfill

## Minimum Log Fields
1. `redeemToken`
- `uid`
- `claimId`
- `offerId`
- `venueId`
- `timestamp`
- `result`

2. `redeemInviteCode`
- `uid`
- `inviteId` أو identifier كافٍ
- `venueId`
- `timestamp`
- `result`

3. `promoteStory`
- `uid`
- `storyId`
- `venueId`
- `durationDays`
- `timestamp`
- `result`

4. `backfillMerchantAnalytics`
- `uid`
- `venueId`
- `days`
- `timestamp`
- `result`

## Expected
- يوجد log أو document trail كافٍ لفهم:
  - من نفّذ العملية
  - متى
  - وعلى أي `venue/claim/story`

---

## J. Revocation / State Change Tests

## Goal
التأكد أن الصلاحيات لا تبقى فعالة بعد تغيّر الحالة.

## Files / Paths
- `firestore.rules`
- `storage.rules`
- `functions/src/index.ts`
- merchant-linked docs:
  - `users/{uid}`
  - `merchants/{uid}`

## Severity / Owner / Execution / Classification / Evidence
- `Severity`: `High`
- `Owner`: `Rules + Backend`
- `Execution Mode`: `Manual + Emulator script`
- `Bug Classification`: `Security bug / Product decision`
- `Verification Method`:
  - linkage docs before/after + denied action evidence + function log if callable involved
- `Evidence Required`:
  - before/after linkage docs
  - denied actions
  - function logs

## Tests
1. تاجر تم فك ربطه من venue:
- هل ما زال يرفع ملفات؟
- هل ما زال يروّج story؟
- هل ما زال يعمل redeem؟

2. venue أصبحت inactive أو غير متاحة:
- هل ما زالت offers أو story actions تعمل دون فحص؟

3. Merchant Scanner In-Flight Revocation
- افتح scanner أو جهّز redeem preview
- افصل ربط التاجر أو غيّر linkage
- حاول redeem بنفس الجلسة

### Expected
- الصلاحيات تتوقف فور فقدان الربط أو تغير الحالة التي يجب أن تمنع العملية

---

## K. User Stats Source Of Truth

`User Stats` في مسار العروض الحالي تعتمد على قراءة claims وتجميعها client-side، وليس على document server-side aggregated منفصل لهذا المسار.

لذلك في اختبارات:
- `used offers`
- `confirmed savings`

يجب توثيق:
- claim document before/after
- what the client rendered
- وعدم افتراض وجود backend stats updater منفصل

---

## L. Weak Spots To Watch Closely

## 1. Merchant Invite Flow
الأعلى حساسية بسبب privilege escalation.

## 2. Percent Offer Accounting
لأنه يجمع:
- redeem
- merchant input
- claim status
- customer stats

## 3. Guest vs Authenticated Claims
لأن عندك منطق `user_id` مقابل `device_id`
وهذا تاريخيًا كان نقطة حساسة.

## 4. Storage Cross-Service Ownership
لأن `storage.rules` تعتمد على Firestore reads.

## 5. Search Callable Abuse
`searchVenuesInBounds` endpoint عالي الاستخدام ويجب أن يبقى محميًا بـ App Check.

---

## M. Function Response Leakage

## Goal
التأكد أن الـ callables لا تعيد معلومات حساسة أو داخلية أكثر من اللازم.

## Scope
- `redeemInviteCode`
- `createClaimToken`
- `validateToken`
- `redeemToken`
- `promoteStory`
- `backfillMerchantAnalytics`
- `searchVenuesInBounds`

## Execution Mode
- `Callable script + UI observation`

## Verification Method
- راقب:
  - UI message
  - function response
  - logs

## Must Not Leak
- `venueId` غير لازم
- invite ownership details
- query internals
- stack traces خام
- أي identifier يسهل enumeration

## Expected
- الرسائل كافية للتعامل مع الخطأ
- لكنها لا تكشف بنية البيانات أو identifiers غير الضرورية

---

## N. Auth Token / Session State Tests

## Goal
التأكد أن الـ callable behavior صحيح مع auth/session غير الطبيعي.

## Scope
- expired Firebase ID token
- deleted Firebase Auth user
- disabled account
- stale session after role/linkage change

## Execution Mode
- `Callable script + staging/emulator auth manipulation`

## Verification Method
- response + no state change + logs

## Expected
- `unauthenticated` أو `permission-denied`
- لا توجد side effects

## Current Implementation Note
التطبيق الحالي لا يعتمد هنا على Firebase Custom Claims مثل:
- `request.auth.token.is_merchant`

بل يعتمد على:
- `users/{uid}.merchant_venue_id`
- `merchants/{uid}.venue_id`

ويقرأها server-side وقت الطلب.

لذلك خطر "stale custom claims for one hour" ليس هو الخطر الأساسي في البنية الحالية.

---

## O. Source Mapping

## Group To Source
- `A`:
  - `functions/src/index.ts` → `redeemInviteCode`
  - `firestore.rules` → `users`, `merchants`, `merchant_invites`
- `B`:
  - `functions/src/index.ts` → `validateToken`, `redeemToken`, `promoteStory`, `backfillMerchantAnalytics`
  - `storage.rules`
- `C`:
  - `functions/src/index.ts` → `createClaimToken`, `validateToken`, `redeemToken`
- `D`:
  - `firestore.rules`
- `E`:
  - `storage.rules`
- `F`:
  - `functions/src/index.ts`
  - `lib/main.dart`
- `G` / `H` / `I` / `M` / `N`:
  - `functions/src/index.ts`
- `J`:
  - `firestore.rules`
  - `storage.rules`
  - merchant linkage docs
- `K`:
  - `lib/features/profile/presentation/providers/user_benefit_insights_provider.dart`

---

## Test Execution Format
لكل test case، سجّل:
- التاريخ
- البيئة: emulator / staging / production-safe
- الحساب المستخدم
- نوع الجهاز
- الخطوات
- النتيجة الفعلية
- هل هي:
  - Pass
  - Fail
  - Needs decision

---

## Minimum Pass Criteria
لا تعتبر الاختبارات الأمنية ناجحة إذا لم يمر ما يلي:
1. لا يوجد privilege escalation عبر invite flow
2. لا يوجد merchant cross-venue access
3. لا يوجد double redeem أو replay فعلي
4. لا يوجد claim leakage بين المستخدمين
5. لا يوجد storage upload/delete خارج الملكية
6. App Check يمنع client غير الموثق من callable الحساسة

---

## Recommended Next Step
الخطوة الصحيحة بعد هذا الملف:
1. تنفيذ `Merchant Entry + Authorization` أولًا
2. ثم `Offer Claim / Redeem`
3. ثم `Firestore / Storage rules tests`
4. ثم توثيق النتائج في ملف:
   - `docs/plan_review/security_test_results_2026-03-24.md`
