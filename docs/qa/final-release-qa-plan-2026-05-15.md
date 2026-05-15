# WAIN Final QA Plan قبل الإطلاق

تاريخ الخطة: 2026-05-15
المنطقة الزمنية المرجعية: Asia/Hebron
Baseline commit الحالي:

```text
6a8ba322
```

هذه الخطة هي مرجع QA النهائي قبل الإطلاق. الهدف الأساسي: كل شخص أو agent يختبر نفس النسخة، على نفس البيئة، وبنفس مسارات القبول، بدون اختلاف نسخ أو بيانات أو توقعات.

نطاق هذه الخطة حاليًا:

```text
Platform scope: Android فقط
```

إذا كان iOS داخل نطاق الإطلاق، يجب إنشاء خطة TestFlight موازية قبل اعتماد هذه الخطة كنهائية. لا يعتبر iOS مختبرًا ضمن هذه الجولة.

## 1. تثبيت النسخة المرجعية

لا يعتمد QA على "آخر كود عندي". يعتمد فقط على tag رسمي.

### شرط إلزامي: Working Tree نظيف

قبل إنشاء tag أو بناء APK:

```powershell
git status --short
```

يجب أن يكون الناتج فارغًا. إذا ظهرت ملفات محلية مثل:

```text
.firebase/hosting.cHVibGlj.cache
.vscode/settings.json
```

لا تبنِ APK قبل تنظيفها. اختر واحدًا:

```powershell
git stash push -m "local qa workspace files" -- .firebase/hosting.cHVibGlj.cache .vscode/settings.json
```

أو إذا كانت ملفات cache/إعدادات محلية غير مطلوبة:

```powershell
git restore -- .firebase/hosting.cHVibGlj.cache .vscode/settings.json
```

أي build من tree غير نظيف يعتبر invalid حتى لو كان الفرق في ملفات لا تؤثر على APK.

### إنشاء Git Tag محلي

```powershell
git tag -a qa-final-2026-05-15 6a8ba322 -m "Final QA baseline before launch"
git show --stat qa-final-2026-05-15
```

إذا لا تريد رفع أي شيء إلى GitHub، هذا tag يبقى محليًا فقط.

### قاعدة ممنوعة

أي tester لا يبني APK من جهازه. شخص واحد فقط يبني نسخة QA، ثم يوزع نفس الملف على الجميع.

## 2. بناء نسخة QA موحدة

يجب بناء نسختين:

```text
Profile APK:
  للتشخيص فقط عند الحاجة: logcat، أداء، debugging بواسطة QA Lead أو builder.

Release build:
  هو artifact الأساسي للاختبار البشري، ويجب أن يصل عبر Google Play Internal Testing
  في الجولة النهائية، لأنه الأقرب لسلوك الإنتاج وPlay Integrity.
```

على جهاز البناء الرئيسي:

```powershell
git checkout qa-final-2026-05-15
git rev-parse --short HEAD
git status --short

& "C:\src\flutter_windows_3.38.9-stable\flutter\bin\flutter.bat" clean
& "C:\src\flutter_windows_3.38.9-stable\flutter\bin\flutter.bat" pub get
& "C:\src\flutter_windows_3.38.9-stable\flutter\bin\flutter.bat" build apk --profile
& "C:\src\flutter_windows_3.38.9-stable\flutter\bin\flutter.bat" build apk --release

Get-FileHash "build\app\outputs\flutter-apk\app-profile.apk" -Algorithm SHA256
Get-FileHash "build\app\outputs\flutter-apk\app-release.apk" -Algorithm SHA256
```

سم اسم الملف بهذا الشكل:

```text
wain-qa-6a8ba322-profile.apk
wain-qa-6a8ba322-release.apk
```

وسجل:

```text
Build type:
Commit:
Tag:
APK SHA256:
Build time:
Builder name:
Flutter version:
Firebase project:
JDK version:
Android SDK / build-tools version:
```

أي جهاز QA لازم يثبت نفس release artifact ونفس الـ SHA256. لا يستخدم profile APK إلا إذا طلب QA Lead ذلك لتشخيص bug محدد.

### Build Register

لا تكرر metadata الطويلة داخل كل bug. أنشئ Build Register واحدًا للجولة:

```text
Build ID:
Commit:
Tag:
Patch tag:
APK/AAB SHA256:
Play Internal Testing version:
Flutter version:
JDK version:
Android SDK/build-tools:
Firebase project:
Builder:
Build time:
```

كل bug يشير إلى `Build ID` فقط، مع الجهاز والحساب والخطوات والأدلة.

### Builder ثابت

رغم تسجيل الإصدارات أعلاه، القاعدة العملية هي:

```text
نفس الشخص ونفس جهاز البناء يبني كل patch خلال الجولة.
```

لا تغيّر builder بين الأيام إلا إذا اضطررت. إذا تغيّر، سجّل السبب وأعد حساب SHA256 واعتبرها artifact جديدة.

### Smoke النهائي قبل الإطلاق

آخر Smoke قبل الإطلاق يجب أن يكون على release build من Google Play Internal Testing، وليس adb profile APK.

```text
Required final smoke artifact:
  Google Play Internal Testing build
```

السبب: Internal Testing يعطي سلوك أقرب للإنتاج، خصوصًا App Check Play Integrity وsigning/installer package.

## 3. بيئة QA

اعتمدنا مسار QA هجين لتجنب تأخير إعداد Firebase project منفصل كامل قبل الجولة:

```text
Functional QA:
  Firebase Emulator Suite
  Project: demo-wain-qa
  Services: Auth + Firestore + Functions + Storage حسب السيناريو

App Check + Play Integrity stage:
  Production Firebase project: wain-d2e28
  فقط لحسابات QA معلّمة بـ is_qa_test_user=true
  فقط للـ final smoke قبل أو أثناء Google Play Internal Testing
```

### Functional QA على Emulator Suite

هذه هي البيئة الافتراضية لكل سيناريوهات wallet / top-up / reversal / stories / admin review:

```text
firebase emulators:start --only auth,firestore,functions,storage
node scripts/qa-seed.mjs --project=demo-wain-qa --reset
node scripts/qa-verify-finance.mjs --project=demo-wain-qa --strict
```

أي functional bug يجب أن يذكر هل تم على emulator أو على production-like smoke.

### App Check + Play Integrity على Production Project

Play Integrity لا يُختبر بشكل موثوق على emulator. لذلك يتم اختبار App Check على production project فقط ضمن نافذة controlled:

```text
Required:
  - الحسابات عليها is_qa_test_user=true.
  - الحسابات مستثناة من analytics/reports المالية.
  - QA Lead يوافق على الحسابات والوقت قبل الاختبار.
  - لا تستخدم بيانات تجار حقيقية أو معاملات مالية حقيقية.
```

ممنوع اختبار wallet/top-up/reversal flows على production خارج هذه المرحلة.

### بيانات QA الثابتة

يجب تجهيز بيانات قابلة لإعادة الضبط:

```text
users:
  user_qa_01
  user_qa_02

merchants:
  merchant_qa_01 -> venue_qa_01
  merchant_qa_02 -> venue_qa_02

admins:
  admin_finance_01
  admin_finance_02
  admin_super_01

venues:
  venue_qa_01
  venue_qa_02

stories:
  3 stories لكل venue

wallet:
  merchant_wallets/venue_qa_01
  starting balance: 500 ILS
  debit entry 50 ILS story_promotion
  debit entry 99 ILS offer_pin
  debit entry 100 ILS story_promotion
  debit entry 250 ILS offer_pin
  debit entry 600 ILS story_promotion
```

### Seed Script إلزامي

يجب توفير أو تشغيل seed script قبل كل جولة:

```text
scripts/qa-seed.mjs
```

أمر التشغيل القياسي:

```powershell
node scripts/qa-seed.mjs --project=demo-wain-qa --reset
```

أمر التحقق المالي بعد seed:

```powershell
node scripts/qa-verify-finance.mjs --project=demo-wain-qa --venue=venue_qa_01,venue_qa_02 --strict
```

المخرجات المطلوبة من الـ seed:

```text
- 2 users عاديين.
- 2 merchants مربوطين بـ 2 venues.
- wallet لكل venue برصيد 500 ILS.
- 5 wallet entries قابلة للعكس بمبالغ 50, 99, 100, 250, 600.
- 3 stories منشورة لكل venue.
- عروض ومنيو أساسي لكل venue.
- 2 finance_admins.
- 1 super_admin.
- طباعة SEED_RUN_ID وكل uid/password/test ids في console وملف QA آمن.
```

أي اختبار يعتمد على بيانات غير موجودة في seed يعتبر invalid، وليس bug في التطبيق.

### Reset Policy

قبل كل جولة QA رئيسية:

```text
1. حذف أو أرشفة بيانات الاختبار القديمة.
2. إعادة seed للـ users / venues / stories / wallets.
3. تسجيل timestamp بداية الجولة.
4. منع استخدام نفس الحساب من أكثر من tester إلا في اختبارات concurrency.
5. تشغيل seed script وتسجيل seed run id.
```

## 4. تثبيت التطبيق على أجهزة QA

على كل هاتف:

```powershell
$adb = "C:\Users\a-z\AppData\Local\Android\Sdk\platform-tools\adb.exe"
& $adb shell pm clear com.wain.wain_app
& $adb install -r "PATH_TO\wain-qa-6a8ba322-profile.apk"
```

إذا ظهر:

```text
INSTALL_FAILED_UPDATE_INCOMPATIBLE
```

استخدم:

```powershell
& $adb shell pm uninstall --user 0 com.wain.wain_app
& $adb install "PATH_TO\wain-qa-6a8ba322-profile.apk"
```

## 5. أداة تتبع Bugs

اعتمدوا أداة واحدة فقط.

الاقتراح العملي إذا لا يوجد Jira/Linear:

```text
Notion table: WAIN Launch QA Bugs
```

### حقول إلزامية لكل Bug

```text
Bug ID:
Title:
Severity: P0 / P1 / P2 / P3
Owner:
Reporter:
Status: New / Triaged / In Progress / Ready for Retest / Closed / Won't Fix
SLA:
Build tag:
Commit:
APK SHA256:
Device:
Android version:
Account:
Role: user / merchant / admin
Environment: QA / production-like / emulator
Steps:
Expected:
Actual:
Screenshot or video:
Logs:
Retest result:
```

### Severity و SLA

```text
P0:
  يمنع الإطلاق.
  أمثلة: crash، wallet balance غلط، auth مكسور، security leak، data loss.
  أي ledger != balance، duplicate debit/credit، bypass للـ dual-control،
  write غير مصرّح إلى financial docs/proof files، أو غياب audit trail لقرار مالي
  يعتبر P0 حتى لو وُجد workaround.
  SLA: يبدأ الإصلاح فورًا. لا إطلاق مع P0 مفتوح.

P1:
  مسار أساسي مكسور.
  أمثلة: Google login لا يعمل، التاجر لا يستطيع الشحن، الأدمن لا يعتمد طلبات.
  SLA في جولة الإطلاق: triage خلال ساعتين، fix/mitigation في نفس يوم العمل إن أمكن.
  لا إطلاق مع P1 مفتوح.

P2:
  خلل مهم لكن له workaround.
  أمثلة: UI مكسور جزئيًا، tooltip clipped، حالة edge.
  P2 مالية تتعلق بعرض الرصيد أو entries تُعالج قبل الإطلاق.
  P2 غير مالية يمكن تأجيلها بقرار مكتوب من QA Lead وProduct.

P3:
  نصوص، تحسينات، polish.
  SLA: backlog بعد الإطلاق.
```

### Ownership

كل bug يجب أن يكون له owner واحد. لا يوجد bug بدون owner.

### Re-test و Patch Workflow

أي إصلاح bug يغيّر baseline. لا نكمل QA على tag قديم بعد إصلاح P0/P1.

السياسة:

```text
1. Developer يصلح bug في commit جديد.
2. QA Lead ينشئ patch tag جديد:
   qa-final-2026-05-15-p1
   qa-final-2026-05-15-p2
3. Builder يبني APK جديد ويحفظ SHA256 جديد.
4. كل testers يثبتون النسخة الجديدة.
5. يعاد اختبار:
   - bug الأصلي
   - smoke كامل
   - كل P0/P1 المرتبطة بنفس المنطقة
6. ticket ينتقل إلى Closed فقط بعد retest على آخر patch tag.
```

قالب التوثيق داخل bug:

```text
Fixed in commit:
Fixed in patch tag:
Retested by:
Retested at:
Retest result:
Regression scope:
```

## 6. الجدول الزمني للجولة

الجولة لا تبقى مفتوحة بلا نهاية. التقدير الواقعي:

```text
Day 0:
  clean baseline, tag, seed, build artifacts, distribute APK.

Day -1 readiness:
  verify QA Firebase project, seed script, App Check enforcement, and rules tests.

Day 1:
  Smoke test + فتح bugs الحرجة.

Day 2:
  Full regression حسب المسارات.

Day 3:
  Fix P0/P1 + patch build + retest.

Day 4-5:
  Buffer للـ rollback rehearsal، Internal Testing release smoke، وقرار Go/No-Go.
```

إذا احتجنا أكثر من patchين بسبب P0/P1 متكررة، نوقف الإطلاق ونرجع لمرحلة stabilization.

### أسئلة اعتماد قبل Day 0

لا يبدأ Day 0 قبل إجابة هذه الأسئلة:

```text
1. هل بيئة QA/Staging موجودة فعليًا لكل الخدمات؟
2. هل seed script الكامل موجود ومجرب؟
3. هل App Check enforcement مفعّل على Firestore, Functions, Storage؟
4. هل Firestore rules tests شغلت ونجحت؟
5. هل feature flags المالية موجودة فعليًا؟ إذا لا، هل وثقنا أن rollback سيكون build/deploy فقط؟
6. هل كل العمليات المالية تمر عبر Cloud Functions أو server-controlled APIs، وليس client writes مباشرة؟
7. هل يوجد requestId/idempotency primitive لكل مسار مالي: top-up, reversal request, first approval, second approval, promote story debit؟
8. أين يوجد audit trail المالي، وهل يحتوي actor, amount, requestId, oldStatus, newStatus, timestamp؟
9. كيف تُدار الأدوار الحساسة: custom claims أم Firestore docs أم مزيج؟
10. ما تعريف "نفس الجلسة" في story attribution؟
```

## 7. توزيع فريق QA

```text
QA Lead:
  يثبت baseline، يراقب نسخة APK، يفتح/يغلق bugs، يقرر go/no-go.

Tester A:
  مستخدم عادي: auth، search، suggestions، map، offers.

Tester B:
  stories، story-to-venue analytics، venue details.

Tester C:
  merchant: dashboard، stories، wallet، top-up، reversal request.

Tester D:
  admin web: topups، proof preview، merchant reversal review، second approval.

Tester E:
  edge cases: offline، permissions، logout/login، performance، small screens.
```

## 8. Smoke Test إلزامي

ينفذ قبل الجولة الكاملة. إذا فشل smoke، توقف الجولة.

```text
1. User email login.
2. User Google login.
3. Open suggestions screen.
4. Open story.
5. From story, open venue.
6. Open map and verify venues appear.
7. Merchant login.
8. Merchant dashboard loads.
9. Merchant wallet loads.
10. Merchant creates top-up request.
11. Admin sees top-up request.
12. Admin opens proof.
13. Admin approves top-up.
14. Merchant sees updated wallet.
15. Merchant requests reversal.
16. Admin sees merchant reversal request.
17. Admin approves direct reversal <= 100 ILS.
18. Merchant creates a new story.
19. The new story appears in the user-facing venue/story surfaces within 60s.
```

## 9. مسارات المستخدم العادي

| المسار | المتوقع |
| --- | --- |
| Email signup | إنشاء حساب أو رسالة واضحة عند الفشل |
| Email login | لا تظهر رسالة عامة إذا السبب معروف |
| Google login | يعمل على نسخة QA |
| Google logout ثم login بحساب آخر | يظهر اختيار الحساب أو لا يدخل تلقائيًا بالحساب القديم |
| الصفحة الرئيسية | لا يوجد crash، البيانات تظهر |
| الاقتراحات | البحث، الفلاتر، والستوريات في أماكنها الصحيحة |
| Scroll down/up في الاقتراحات | الفلاتر والستوريات تتحرك حسب المطلوب |
| فتح story viewer | النافبار لا يظهر |
| مشاهدة أكثر من ستوري | الانتقال طبيعي |
| الضغط من الستوري على الجهة | يفتح صفحة الجهة |
| فتح الخريطة | الأماكن تظهر |
| map filters | لا ترث فلاتر الاقتراحات بشكل خاطئ |
| فتح جهة | عروض، منيو، تقييمات، اتصال، واتساب، توجيه |
| الحصول على عرض | يسجل أو يعرض خطأ واضح |
| المفضلة | إضافة وإزالة صحيحة |
| جرّب لاحقًا | إضافة وإزالة صحيحة |
| profile/settings | اللغة، الإعدادات، logout تعمل |

## 10. مسارات التاجر

| المسار | المتوقع |
| --- | --- |
| Merchant login | لا تظهر رسالة "لا يوجد محل مربوط" إذا merchant doc صحيح |
| Dashboard | الرصيد، المشاهدات، دخول من الستوري، معدل التحويل |
| Stories screen | badge عدد المشاهدات يظهر للستوري |
| Promote story | لا يعلق بالتحميل |
| Wallet summary | الأرقام صحيحة |
| Wallet ledger | يحمل بدون "تعذر تحميل البيانات" |
| Top-up request | يرسل الطلب مع صورة الوصل |
| Reversal request | الزر يظهر فقط للعمليات القابلة |
| Reversal pending | badge قيد المراجعة |
| Reversal approved | badge تم التصحيح والرصيد يتعدل |
| Reversal rejected | badge مرفوض والسبب واضح |

## 11. مسارات Admin Web

| المسار | المتوقع |
| --- | --- |
| Login admin | دخول صحيح حسب الصلاحيات |
| Top-up queue | تظهر طلبات الشحن |
| Proof preview | صورة الوصل تفتح أو تظهر معاينة |
| Approve top-up | الرصيد يزيد والطلب يكتمل |
| Reject top-up | السبب محفوظ |
| Wallet ledger | العملية تظهر |
| Merchant reversal tab | طلبات التجار تظهر |
| Approve <= 100 ILS | تنفيذ مباشر |
| Approve > 100 ILS | ينتقل لموافقة ثانية |
| Same admin second approval | ممنوع |
| Different admin second approval | ينجح |
| Super admin path > 500 ILS | يتطلب super_admin |

## 12. Concurrency Scenarios

هذه المسارات لا تنفذ بحسابات مشتركة عشوائيًا. ينفذها QA Lead بتوقيت مضبوط.

| السيناريو | المتوقع |
| --- | --- |
| أدمنان يعتمدان نفس merchant reversal في نفس اللحظة | واحد ينجح، الثاني يرى `request_not_pending_review` |
| أدمن A يراجع طلب > 100 ILS ثم يحاول الموافقة الثانية | ممنوع بسبب dual-control |
| أدمن B يوافق ثانيًا بعد أدمن A | ينجح |
| تاجر يرسل reversal request بينما أدمن يبدأ `reverseWalletEntry` مباشر على نفس entry | لا يحدث double reversal |
| مستخدمان يضغطان Promote Story لنفس venue بنفس الوقت | ledger يبقى متسقًا ولا يصبح الرصيد سالبًا خطأ |
| تاجر لديه 50 ILS فقط يضغط Promote Story مرتين والتكلفة 50 ILS | عملية واحدة فقط تنجح، الثانية ترفض، الرصيد لا يصبح سالبًا |
| تاجر يضغط submit top-up مرتين بسرعة | لا ينشأ duplicate غير مقصود أو تظهر رسالة واضحة |
| إعادة نفس top-up request بعد timeout أو reconnect | لا ينشأ أثر مالي مكرر |
| approve نفس reversal request مرتين بنفس requestId | تنفيذ واحد فقط، الثانية ترفض أو ترجع نفس النتيجة الآمنة |
| second approval يُعاد بعد network retry | لا ينشأ reversal entry ثانية |
| promote story debit يُعاد بعد reconnect | debit واحد فقط أو رفض واضح بدون رصيد سالب |

### طريقة اختبار Double Tap

الاختبار اليدوي العادي قد لا يكشف المشكلة بسبب debounce. استخدم واحدة من الطرق التالية:

```text
1. Tester يضغط بإصبعين في نفس اللحظة على زر submit.
2. أو استخدم adb tap مرتين بفاصل قصير:
   adb shell input tap X Y
   timeout /t 0
   adb shell input tap X Y
3. أو اكتب script صغير يرسل tapين بفاصل 50ms إذا احتجت دقة أعلى.
```

سجل إحداثيات الزر في bug/ticket إذا وجدت مشكلة.

## 13. Story Analytics QA

| الخطوة | المتوقع |
| --- | --- |
| مستخدم يشاهد ستوري | `view_count` يزيد |
| يضغط زيارة الجهة من الستوري | event واحد `event_type=view`, `source=story_viewer`, `story_id=<id>` |
| يرجع ويضغط مرة ثانية بنفس الجلسة | لا يحسب كدخول ستوري جديد |
| يضغط من ستوري ثانية | event جديد بـ story_id مختلف |
| التاجر يفتح dashboard | "دخول من الستوري" يظهر بعد aggregation |
| معدل التحويل | `story_to_venue_views / story_views` |

## 14. Edge Cases

```text
- Offline ثم online.
- رفض صلاحية الموقع.
- قبول صلاحية الموقع.
- فتح التطبيق بعد force kill.
- logout ثم login بحساب مختلف.
- حساب غير تاجر يحاول فتح لوحة التاجر.
- تاجر بدون merchants/{uid}.venue_id.
- أدمن بدون capability يحاول الاعتماد.
- هاتف صغير.
- Android قديم وحديث.
- RTL Arabic كامل.
- ضغط سريع ومتكرر على buttons المالية.
- Duplicate top-up submit.
- Duplicate reversal request.
- Story viewer مع أكثر من ستوري.
- مستخدم له 0 ستوريات.
- تاجر له 0 wallet entries.
- تاجر له 100 wallet entries لاختبار pagination/scroll.
- ستوري بعنوان طويل جدًا.
- صورة upload كبيرة جدًا 10MB+.
- حدود منتصف الليل بين Asia/Hebron و Asia/Jerusalem.
- Font scaling 200%.
- TalkBack spot check للأزرار الأساسية.
- RTL arrows/icons direction.
- شبكة بطيئة Regular 3G أثناء top-up وpromote story.
- token/session expired: تعطيل/سحب صلاحية حساب merchant من Firebase Console ثم تنفيذ عملية مالية.
- background/foreground أثناء top-up submission.
- story expiry أثناء المشاهدة أو قبل الضغط على زيارة الجهة.
- emulator/rooted device مع App Check غير موثوق: يجب أن يفشل بشكل واضح أو يستخدم debug token موثق.
- top-up proof: الملف رُفع لكن الوثيقة لم تُنشأ.
- top-up proof: الوثيقة أُنشئت لكن الملف غير قابل للقراءة للأدمن.
- top-up proof: user/merchant غير مخول يحاول قراءة proof لطلب غيره.
- top-up proof: mime type غير صالح أو ملف كبير جدًا.
```

## 15. Performance و Stability

الأرقام التالية هي SLA للـ QA. لا تقبل "حسّيًا سريع/بطيء" بدون قياس تقريبي.

```text
- App cold start to first usable screen: <= 3s على هاتف متوسط.
- شاشة الاقتراحات TTI: <= 2s.
- Scroll في الاقتراحات: لا jank واضح خلال 30s scroll.
- فتح Story Viewer: <= 500ms بعد تحميل البيانات.
- فتح Venue Details: <= 2s.
- سجل المحفظة: <= 1s بعد فتح الشاشة.
- Merchant dashboard: <= 2s.
- Admin web finance pages: <= 2s بعد auth.
- Story analytics aggregation visibility: <= 1h.
- أول response بعد cold start لأي callable مالي حساس: <= 5s أو فعّل minimum instances.
- Firebase Functions error rate: لا يزيد عن baseline قبل QA.
- App Check failures: لا تمنع flows أساسية.
- Crashlytics: لا crash جديد متكرر.
```

### Cold Start Test

في Day 4، اترك callables المالية بدون استخدام ساعتين، ثم نفذ smoke مالي كامل:

```text
- createMerchantWalletReversalRequest
- reviewMerchantWalletReversalRequest
- approveWalletReversalRequest
- createTopUpRequest
- promote story callable/flow
```

إذا أول response يتجاوز 5 ثوانٍ بشكل متكرر، قيّم إضافة minimum instances للـ Functions الحساسة قبل الإطلاق.

### Crash Reporting Verification

قبل الإطلاق، نفذ crash test آمن في dev/staging فقط أو استخدم test crash إن وجد:

```text
Expected:
  Crashlytics يستقبل crash خلال دقائق، مع build/tag واضح.
```

إذا Crashlytics لا يستقبل، لا تعتبر الجولة observability-ready.

## 16. Security و Resilience Gates

هذه gates إلزامية قبل Go/No-Go لأنها تخص أمان البيانات المالية وليس UI فقط.

### Firestore Security Rules Negative Tests

يجب تشغيل tests موجودة أو تنفيذها يدويًا على Emulator/QA:

```text
- user_qa_01 يحاول قراءة merchant_wallets/{venueId} لجهة لا يملكها -> denied.
- user_qa_01 يحاول كتابة merchant_wallets أو entries مباشرة -> denied.
- merchant_qa_01 يحاول قراءة wallet_reversal_requests لتاجر آخر -> denied.
- merchant_qa_01 يحاول كتابة wallet_reversal_requests مباشرة -> denied.
- user أو merchant غير مخول يحاول قراءة proof files الخاصة بطلبات شحن غيره -> denied.
- user عادي يحاول قراءة admin-only queues/collections -> denied.
- admin بدون capability يحاول review/approve reversal -> denied.
- unauthenticated يحاول callable مالي -> denied.
```

المفضل تشغيل:

```powershell
cd functions
npm test -- test/rules/firestoreSecurityRules.test.js
```

إذا أي negative security test يفشل، فهو P0.

### Storage Proof Access Matrix

إثباتات الشحن يجب أن تختبر كـ Storage + Firestore + Admin access، وليس UI فقط:

| الحالة | المتوقع |
| --- | --- |
| صاحب الطلب يرفع proof صحيح | ينجح |
| أدمن مخول يفتح proof | ينجح |
| مستخدم آخر يفتح proof | denied |
| تاجر آخر يفتح proof | denied |
| proof doc موجود والملف مفقود | تظهر رسالة "تعذر الفتح" بدون crash |
| file uploaded وrequest doc فشل | لا يظهر طلب ناقص للأدمن، ويُسجل bug/cleanup |

### App Check Failure Behavior

تحقق من Firebase Console:

```text
App Check enforcement:
  Firestore: Enforced
  Functions: Enforced
  Storage: Enforced
```

ثم اختبر جهاز/Emulator غير موثوق بدون debug token:

```text
Expected:
  الطلبات الحساسة تفشل برسالة واضحة، ولا تمر بصمت.
```

إذا App Check في Monitoring فقط على service حساس، فهذا P0 قبل الإطلاق.

### Auth Token Expiry / Revocation

اختبار:

```text
1. افتح التطبيق كتاجر.
2. من Firebase Console عطّل الحساب أو اسحب الصلاحية.
3. حاول top-up أو promote story أو reversal request.
```

المتوقع:

```text
رسالة واضحة أو إعادة تسجيل دخول.
لا crash.
لا عملية مالية partial.
```

### Audit Trail Verification

كل عملية مالية يجب أن تترك أثرًا يمكن تتبعه:

```text
- Wallet entry.
- Wallet audit event أو admin log.
- Request document عند top-up/reversal.
- Admin decision fields عند approve/reject.
```

إذا الرصيد تغير بدون audit trail واضح، فهذا P0.

الحد الأدنى للحقول في أي audit/event مالي:

```text
actor_uid
actor_role أو auth_source
venue_id
request_id أو operation_id
entry_id إذا وجد
amount
currency
previous_status إذا وجد
new_status إذا وجد
timestamp
```

### Idempotency و Replay Gates

هذه البوابة P0 للعمليات المالية. المطلوب إثبات أن تكرار الطلب لا يكرر الأثر المالي.

| المسار | شرط القبول |
| --- | --- |
| top-up submit | نفس proof/amount/user لا ينتج طلبات مالية متناقضة عند retry |
| create reversal request | requestId/entryId يمنع طلبين active لنفس entry |
| first approval | تكرار approve لا يكرر mutation |
| second approval | تكرار approve لا ينشئ reversal entry ثانية |
| promote story debit | تكرار الطلب أو reconnect لا ينقص الرصيد مرتين |

إذا كان المسار يعتمد على UI debounce فقط، فهو غير كافٍ للإطلاق.

### Finance Invariants Verifier

قبل Go، شغّل verifier أو اكتب واحدًا:

```text
scripts/qa-verify-finance.mjs
```

المطلوب منه:

```text
- لكل wallet: opening balance + ledger deltas == current balance.
- لا توجد reversal approved بدون reversal_entry_id.
- لا توجد reversal_entry مكررة لنفس original entry.
- كل top-up approved له wallet entry واحدة.
- كل promote story debit له wallet entry واحدة وقصة/عملية مرتبطة.
- لا توجد wallet balance سالبة إلا إذا كان ذلك مسموحًا صراحةً في business rules.
```

يشغل بعد:

```text
- seed.
- smoke المالي.
- كل patch مالي.
- قبل Go decision.
```

فشل verifier = P0.

### Story Attribution Acceptance Contract

تعريف "نفس الجلسة" لهذه الجولة:

```text
نفس app process منذ فتح StoryViewerScreen وحتى إغلاقه أو kill/restart للتطبيق.
```

القبول:

```text
- الضغط الأول من story إلى venue يسجل source=story_viewer + story_id.
- الضغط الثاني على نفس story داخل نفس StoryViewerScreen session لا يسجل attribution جديد.
- إعادة تشغيل التطبيق أو فتح viewer جديد تعتبر session جديدة وقد تسجل attribution جديد.
- aggregation dashboard قد يتأخر حتى ساعة، لذلك raw event هو دليل أولي، والdashboard يُفحص مرة واحدة لكل patch.
```

## 17. معايير Go / No-Go

### Go

```text
- لا يوجد P0 أو P1 مفتوح.
- Smoke test كامل pass.
- آخر patch tag هو الذي اختُبر، وليس tag قديم.
- Release build من Google Play Internal Testing مر Smoke نهائي.
- QA environment/seed موثقان.
- Rollback rehearsal تم في staging.
- Security negative tests passed.
- App Check enforcement verified.
- Auth token expiry/revocation behavior واضح.
- Audit trail لكل عملية مالية متحقق.
- Idempotency/replay gates للعمليات المالية passed.
- Finance invariants verifier passed.
- Storage proof access matrix passed.
- Story attribution acceptance contract موثق ومختبر.
- Google login يعمل.
- App Check يعمل على نسخة QA: Firebase Console -> App Check -> Requests، خلال ساعتين من smoke يجب أن تكون Verified requests >= 95% لكل service مستخدم: Firestore, Functions, Storage.
- Wallet balance والledger متطابقان.
- Top-up flow يعمل.
- Reversal flow يعمل.
- Story analytics تظهر.
- Map يعرض أماكن.
- Admin web يعمل.
- flutter analyze نظيف.
- Functions logs بدون error rate غير طبيعي.
```

### No-Go

```text
- أي P0 مفتوح.
- أي P1 مفتوح بدون قرار رسمي.
- خلل wallet أو ledger.
- auth لا يعمل.
- App Check يمنع flows أساسية.
- admin approvals لا تعمل.
- crash متكرر.
- build من working tree غير نظيف.
- لم يتم retest بعد آخر patch.
- لم يمر release/internal testing smoke.
- Firestore rules negative test فشل.
- App Check service حساس ليس Enforced.
- عملية مالية بلا audit trail.
- replay/idempotency test ينتج duplicate debit/credit.
- finance verifier يفشل.
- proof file يمكن الوصول له من مستخدم غير مخول.
```

## 18. خطة Rollback

Rollback يجب أن يتمرن عليه في بيئة QA قبل الإطلاق. لا يكفي أن تكون الخطة مكتوبة.

### Rollback Rehearsal في QA

```text
1. شغّل functional smoke على Firebase Emulator Suite أو production-like QA window.
2. نفذ smoke مالي سريع.
3. ارجع Functions إلى آخر نسخة مستقرة.
4. ارجع Admin Web إلى آخر build مستقر.
5. تحقق أن التطبيق لا يزال يعمل.
6. سجل زمن rollback ومن نفذه.
```

قبل أي إطلاق مالي، خذ backup أو export مناسب للبيانات الحساسة حسب الإمكانية:

```text
- Firestore export أو backup policy مفعّلة.
- قائمة آخر deploy commits.
- آخر APK/AAB مستقر.
- رابط آخر Admin Web build مستقر.
```

### إذا فشل Flutter بعد الإطلاق

```text
1. إيقاف نشر النسخة الجديدة فورًا.
2. الرجوع إلى آخر APK/AAB مستقر.
3. إذا النشر عبر Play Console: roll back إلى previous release في track.
4. إذا adb/manual: توزيع APK السابق.
5. فتح bug P0/P1 وربطه بالنسخة الفاشلة.
```

### إذا فشلت Functions

```text
1. إعادة deploy لآخر commit مستقر للـ functions.
2. مراقبة callable error rate.
3. التأكد أن الطلبات المالية الموجودة لم تتغير بشكل خاطئ.
4. عدم حذف وثائق Firestore الجديدة إلا بعد تحليل.
```

### إذا فشلت Firestore Rules

```text
1. إعادة deploy لقواعد Firestore السابقة.
2. اختبار read/write للمستخدم والتاجر والأدمن.
3. اعتبارها P0 إذا منعت wallet/admin/auth flows.
```

### إذا فشلت Admin Web

```text
1. إعادة deploy لآخر build مستقر للـ hosting.
2. يمكن للتجار استخدام التطبيق، لكن approvals المالية قد تتوقف.
3. إذا approvals متوقفة، اعتبرها P1 أو P0 حسب المرحلة.
```

### معاملات مالية عالقة أو Partial Failure

إذا فشل callable مالي في المنتصف أو بقيت وثيقة عالقة:

```text
Scenario:
  wallet_reversal_requests/{id} بقيت pending_review أو pending_second_approval
  رغم أن الأدمن حاول الاعتماد.

Action:
  1. لا تعدل الرصيد يدويًا فورًا.
  2. افحص wallet entries و audit events.
  3. إذا لم تُنفذ reversal entry: يمكن إعادة المحاولة من Admin UI.
  4. إذا يوجد entry منفذة لكن request status لم يتحدث: QA Lead أو admin مسؤول يحدث status يدويًا بعد توثيق الدليل.
  5. افتح bug P0/P1 حسب الأثر.
```

قاعدة مهمة:

```text
أي تعديل يدوي على Firestore في بيانات مالية يجب أن يسجل:
  who, when, why, before, after, linked bug id.
```

### Runbook التعويض والمطابقة المالية

Rollback للكود لا يكفي وحده لمعالجة أثر مالي خاطئ. عند اكتشاف خطأ مالي في الإنتاج:

```text
1. أوقف المسار المتضرر:
   - disable feature flag إن وجد
   - أو rollback build/functions
   - أو إيقاف action من Admin UI مؤقتًا

2. جمّد المعالجة اليدوية المرتبطة:
   - لا تعتمد طلبات جديدة من نفس النوع حتى triage.

3. حدد المعاملات المتأثرة:
   - request_id
   - wallet entry ids
   - venue_id
   - user/merchant uid
   - amount/currency
   - timestamps

4. قرر آلية التعويض:
   - compensating ledger entry
   - reversal إداري
   - status correction فقط إذا لم يحدث أثر مالي

5. نفذ التعويض بموافقة شخصين:
   - finance owner
   - technical owner

6. شغّل qa-verify-finance.mjs أو verifier مكافئ.

7. وثق:
   - before/after balance
   - linked bug id
   - who approved
   - who executed
```

استخدم Firestore backup/PITR لأغراض forensic أو تعافي واسع من فساد/حذف، وليس كآلية يومية لإلغاء قيد مالي منفرد.

### إذا فشل Feature مالي فقط

#### Feature-Level Rollback Status

```text
غير متاح في هذا الإطلاق.
```

Remote Config feature flags غير مربوطة بالكود حاليًا. تم التحقق بتاريخ 2026-05-15:

```text
- لا توجد matches فعلية في lib/ أو functions/ أو admin_web_console/ لـ feature_merchant_reversal_enabled.
- لا توجد matches فعلية في lib/ أو functions/ أو admin_web_console/ لـ feature_story_attribution_enabled.
- لا توجد matches فعلية في lib/ أو functions/ أو admin_web_console/ لـ feature_promote_story_enabled.
- RemoteConfig SDK غير مستخدم في lib/.
```

#### Rollback الفعلي المتاح

```text
1. Functions:
   redeploy آخر commit مستقر عبر firebase deploy --only functions.

2. Firestore rules + indexes:
   redeploy آخر rules/indexes مستقرة.

3. Flutter:
   Google Play Console -> roll back إلى previous release في internal/production track.

4. Admin web:
   redeploy آخر hosting build مستقر.
```

#### Backlog لما بعد الإطلاق

```text
إضافة Remote Config flags لـ:
  - feature_merchant_reversal_enabled
  - feature_story_attribution_enabled
  - feature_promote_story_enabled

أولوية: post-v1.0.
```

### مبدأ عام

لا تعمل rollback عشوائي. كل rollback يجب أن يسجل:

```text
سبب rollback:
النسخة الفاشلة:
النسخة التي رجعنا لها:
وقت القرار:
من وافق:
البيانات المتأثرة:
```

## 19. ترتيب النشر بعد QA

```text
1. Firestore rules + indexes.
2. Functions.
3. Admin web.
4. Flutter Android build.
```

السبب: Flutter يعتمد على callables الجديدة. نشر Flutter قبل Functions قد يظهر أزرار تستدعي Functions غير موجودة.

## 20. مراقبة أول 24 ساعة

| Metric | Threshold |
| --- | --- |
| `trackVenueEvent` success rate | alert إذا أقل من 99% خلال ساعة |
| `createMerchantWalletReversalRequest` error rate | alert إذا أعلى من 1% خلال ساعة، باستثناء أخطاء duplicate/unauthorized الطبيعية |
| `reviewMerchantWalletReversalRequest` error rate | alert إذا أعلى من 0.5% خلال ساعة |
| `approveWalletReversalRequest` error rate | alert إذا أعلى من 0.5% خلال ساعة |
| App Check failures | alert إذا أعلى من 5% خلال ساعة لأي service |
| Google login failures | alert إذا زادت عن baseline أو ظهرت شكاوى متكررة |
| pending_review accumulation | alert إذا أكثر من 20 طلب أقدم من 24 ساعة |
| top-up pending accumulation | alert إذا أكثر من 20 طلب أقدم من 24 ساعة |
| Crashlytics | alert على أي issue جديد يؤثر على أكثر من 10 مستخدمين خلال ساعة |
| شكاوى نقص مشاهدات الصفحة | متوقعة بعد فصل story_to_venue، عالجها بالـ release note |

### مراقبة بشرية أثناء Bake وأول 24 ساعة

لا تعتمد على alerts فقط، لأن حجم العينة في Internal Testing قد لا يكفي لتفعيل كل alerts.

عيّن owner واضح لمراجعة dashboards/logs:

```text
Internal Testing bake:
  مراجعة كل 30 دقيقة.

أول 24 ساعة production:
  مراجعة كل 60 دقيقة على الأقل.
```

جهّز queries أو views مسبقًا لـ:

```text
- Functions errors.
- App Check invalid/outdated requests.
- Crashlytics new issues.
- wallet/reversal/top-up pending accumulation.
- audit events المالية خلال آخر ساعة.
```

## 21. Release Note للتجار

```text
تحديث الإحصائيات

أضفنا مقياسًا جديدًا: "دخول من الستوري" يعرض عدد المستخدمين
الذين زاروا صفحتك بعد ضغطهم على ستوري الترويج.

ملاحظة: رقم "مشاهدات الصفحة" أصبح يستثني الزيارات القادمة من
الستوري، لأنها تظهر الآن في رقم منفصل.

يُقاس "دخول من الستوري" منذ 14 مايو 2026.
```

## 22. نتيجة الجولة

في نهاية QA، يسجل QA Lead:

```text
QA tag:
Patch tag:
Build ID:
APK SHA256:
Release/Internal Testing build:
Environment:
Seed run id:
Total bugs:
P0 open:
P1 open:
P2 open:
P3 open:
Smoke result:
Full regression result:
Rollback rehearsal result:
Security negative tests result:
Idempotency/replay result:
Finance verifier result:
Audit trail verification result:
Go/No-Go decision:
Decision owner:
Decision timestamp:
```

## 23. Pre-Launch Bake

بعد قرار Go، لا ترفع مباشرة إلى production العام. نفذ bake قصير:

```text
1. ارفع release build إلى Google Play Internal Testing.
2. انتظر ساعتين على الأقل.
3. نفذ smoke مختصر على جهازين.
4. راقب Firebase metrics خلال الساعتين.
5. إذا بقيت المؤشرات ضمن الحدود، promote إلى production.
```

معايير نجاح الـ Bake:

```text
- Crashlytics: 0 crashes جديدة حرجة.
- App Check verified requests >= 95%.
- Functions error rate <= baseline.
- Google login يعمل على جهاز QA واحد على الأقل.
- Wallet/top-up/reversal smoke يمر.
```

إذا فشل bake:

```text
لا promote إلى production.
افتح bug P0/P1 حسب الأثر.
أنشئ patch tag جديد بعد الإصلاح.
أعد bake من البداية.
```
