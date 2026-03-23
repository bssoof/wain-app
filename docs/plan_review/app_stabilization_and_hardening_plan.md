# خطة تثبيت وتقوية التطبيق

## Summary
هذه الخطة مخصصة لتثبيت المنتج الحالي قبل فتح أي جبهة features جديدة.  
الهدف ليس إعادة بناء التطبيق، بل تحويله من codebase غني بالميزات إلى منتج أكثر تماسكا، أوضح في state والتنقل، وأقوى في التدفقات الحرجة على الهاتف.

الخطة مبنية على الكود الحالي في المشروع، خصوصا في المسارات التالية:
- `lib/core/routing/app_router.dart`
- `lib/core/providers/location_provider.dart`
- `lib/features/profile/presentation/providers/settings_providers.dart`
- `lib/features/discovery/presentation/widgets/filter_bottom_sheet.dart`
- `lib/features/discovery/presentation/screens/home_screen.dart`
- `lib/features/discovery/presentation/screens/results_screen.dart`
- `lib/features/map/presentation/screens/map_screen.dart`
- `lib/features/venue/presentation/screens/venue_details_screen.dart`
- `lib/features/venue/presentation/screens/venue_menu_screen.dart`
- `lib/features/offers/presentation/screens/offer_details_screen.dart`
- `lib/features/offers/presentation/screens/my_claims_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_dashboard_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_menu_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_scan_screen.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `lib/core/errors/app_exceptions.dart`
- `lib/core/widgets/app_error_widget.dart`
- `lib/firebase_options.dart`
- `firestore.rules`
- `storage.rules`
- `functions/src/**`
- `.github/workflows/ci.yml`

---

## الهدف الرئيسي
1. توحيد state الاكتشاف بحيث تصبح المدينة والموقع والفلاتر واللغة/الثيم متسقة بين كل الشاشات.
2. تثبيت أهم تدفقات المستخدم على جهاز فعلي، خصوصا:
   - `results -> venue details -> venue menu`
   - `offer claim -> QR -> merchant scan/redeem`
3. تثبيت أهم تدفقات التاجر:
   - dashboard
   - menu
   - offers
   - photos
   - stories
   - hours
4. إغلاق الثغرات التشغيلية الواضحة:
   - iOS Firebase gap
   - secrets/rules/function hardening
   - CI/testing gates
5. تعريف Launch Gates واضحة قبل أي features جديدة.

---

## النطاق

### داخل النطاق
- state management للاكتشاف والإعدادات
- التنقل والـ back stack sanity
- صفحات results/map/venue/offers/menu
- auth flows
- claim/redeem flows
- merchant operational flows
- security rules/functions
- CI + tests + profiling + release gates

### خارج النطاق
- إعادة تصميم شامل للتطبيق كله
- OCR relaunch
- admin panel جديد
- offline-first architecture كاملة
- payments / bookings
- إعادة كتابة backend أو تغيير stack

---

## المشاكل الحالية التي تستهدفها الخطة
1. الـ state الحرج موزع على أكثر من موضع:
   - location
   - city
   - search/filter state
   - language/theme/settings
2. التطبيق غني بالميزات، لكن هذا يرفع خطر عدم الاتساق بين الشاشات.
3. بعض المسارات المهمة تبدو قوية من الكود، لكنها تحتاج hardening فعلي على الجهاز وليس فقط `flutter analyze`.
4. iOS ما زال غير محسوم لأن `TargetPlatform.iOS` غير مهيأ في:
   - `lib/firebase_options.dart`
5. هناك مسارات حساسة أمنيًا وتشغيليًا:
   - `firestore.rules`
   - `storage.rules`
   - `functions/src/**`
   - `service-account-key.json`

---

## المبادئ التنفيذية
1. نصلح source-of-truth أولاً، لا UI polish أولاً.
2. نثبت flow حرِج واحد كاملًا قبل الانتقال للذي بعده.
3. أي ميزة لا تملك acceptance criteria لا تعتبر منجزة.
4. لا نضيف features جديدة أثناء هذه الخطة.
5. لا نثق بالنجاح على Windows أو Web كبديل عن جهاز Android فعلي.
6. نلتزم بـ WIP limit صارم:
   - لا يُفتح أكثر من مسار تنفيذي رئيسي واحد داخل كل sprint.
   - لا يبدأ sprint جديد قبل إغلاق acceptance criteria الخاصة بالسابق.
7. Launch Readiness Gates هي المرجع التنفيذي النهائي، وليست قسمًا توثيقيًا ثانويًا.

---

## قواعد التنفيذ المرحلي
1. `Sprint 0`:
   - baseline
   - iOS decision
   - secrets audit
   - quick security audit
2. `Sprint 1`:
   - Discovery state فقط
3. `Sprint 2`:
   - Navigation + user critical flows فقط
4. `Sprint 3`:
   - Merchant must-work flows فقط
5. `Sprint 4`:
   - CI/performance/final launch gates

### ممنوعات التنفيذ
- لا يُفتح `Sprint 3` قبل إغلاق قبول `Sprint 2` فعليًا.
- لا يُفتح redesign أو polish واسع أثناء تثبيت state والتنقل.
- لا يُرحّل `service-account-key` وrules review إلى آخر الخطة.

---

## المسار A: توحيد Discovery State

## الهدف
جعل state الاكتشاف متسقة وفورية الانعكاس بين:
- `Home`
- `Results`
- `Map`
- `FilterBottomSheet`
- أي state تعتمد على المدينة/الموقع/الفلاتر

## الملفات المستهدفة
- `lib/core/providers/location_provider.dart`
- `lib/features/profile/presentation/providers/settings_providers.dart`
- `lib/features/discovery/presentation/widgets/filter_bottom_sheet.dart`
- `lib/features/discovery/presentation/screens/home_screen.dart`
- `lib/features/discovery/presentation/screens/results_screen.dart`
- `lib/features/map/presentation/screens/map_screen.dart`
- أي provider متعلق بـ search/results/filter state

## التنفيذ
1. تعريف source of truth صريح لـ:
   - current city
   - effective location
   - budget range
   - sort mode
   - cuisine filters
2. توحيد العلاقة بين:
   - `settingsProvider.city`
   - `userLocationProvider`
   - `searchProvider`
3. منع تكرار نفس القرار في أكثر من widget state محلي إذا كان يجب أن يكون global.
4. تحديد precedence rule واضحة:
   - الموقع الحقيقي إذا متاح
   - fallback city/location إذا غير متاح
   - override يدوي من المستخدم إذا كان مطلوبًا
5. جعل `FilterBottomSheet` يقرأ من provider موحد ويكتب إليه مباشرة بطريقة متسقة.
6. ربط أي تغيير في المدينة/الفلاتر بتحديث واضح على:
   - results
   - map markers/list
   - nearby/discovery sections

## فحوصات القبول
1. تغيير المدينة من settings أو نقطة التحكم ينعكس على النتائج والخريطة.
2. تغيير الفلاتر من `FilterBottomSheet` ينعكس فورا على results/map.
3. الرجوع والدخول للشاشات لا يعيد state بشكل مفاجئ.
4. لا يوجد duplication واضح لقرار الفلاتر/المدينة بين أكثر من state محلية.

---

## المسار B: Back Stack وNavigation Hardening

## الهدف
جعل التنقل مفهومًا ومتوقعًا في كل المسارات الأساسية.

## الملفات المستهدفة
- `lib/core/routing/app_router.dart`
- `lib/features/discovery/presentation/screens/home_screen.dart`
- `lib/features/map/presentation/screens/map_screen.dart`
- `lib/features/discovery/presentation/screens/results_screen.dart`
- `lib/features/venue/presentation/screens/venue_details_screen.dart`
- `lib/features/venue/presentation/screens/venue_menu_screen.dart`
- `lib/features/offers/presentation/screens/offer_details_screen.dart`
- `lib/features/offers/presentation/screens/my_claims_screen.dart`
- أي شاشة تستخدم `context.go` أو fallback navigation

## التنفيذ
1. route audit كامل:
   - من أين تأتي كل شاشة
   - هل يجب أن تُفتح عبر `push` أم `go`
2. تثبيت قاعدة:
   - screens الفرعية = `push`
   - التنقل الجذري فقط = `go`
3. مراجعة back behavior في:
   - venue details
   - venue menu
   - offer details
   - my claims
   - merchant screens
4. التأكد أن "اضغط مرة ثانية للخروج" يبقى فقط على الشاشة الجذرية المعتمدة.
5. فحص deep-link/readability في route names والـ path parameters.

## فحوصات القبول
1. back stack طبيعي من كل شاشة فرعية.
2. لا يوجد tab أو CTA يعمل route behavior مربك.
3. العودة من `venue menu` ترجع إلى `venue details`.
4. العودة من `offer details` و`my claims` و`profile-linked screens` لا تكسر history.

---

## المسار C: User Critical Flows Hardening

## الهدف
تثبيت أهم flows التي تحدد ثقة المستخدم العادي في التطبيق.

## التدفقات المستهدفة
1. `onboarding -> home/question flow -> results -> venue details -> venue menu`
2. `offer details -> claim -> QR -> merchant redeem`
3. `favorites / try list / saved offers`
4. `login/signup/OTP/guest`

## الملفات المستهدفة
- `lib/features/discovery/presentation/screens/results_screen.dart`
- `lib/features/map/presentation/screens/map_screen.dart`
- `lib/features/venue/presentation/screens/venue_details_screen.dart`
- `lib/features/venue/presentation/screens/venue_menu_screen.dart`
- `lib/features/offers/presentation/screens/offer_details_screen.dart`
- `lib/features/offers/presentation/screens/my_claims_screen.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- شاشات auth
- أي providers للعروض، الحفظ، الـ claims

## التنفيذ
1. flow audit لكل شاشة:
   - loading
   - empty
   - error
   - success
2. توحيد الرسائل والسلوك في حالات:
   - no internet
   - expired claim
   - already used
   - limit exceeded
3. مراجعة coupling بين venue details وvenue menu بعد الفصل المعماري الأخير.
4. التأكد أن favorite/try list/saved offers لا تتضارب بين guest/user.
5. مراجعة auth upgrade path:
   - guest -> logged in
   - email/Google/OTP

## فحوصات القبول
1. flow `results -> venue details -> venue menu` يعمل بلا تعثر بصري أو تنقلي.
2. flow العرض كامل من claim إلى redeem مثبت على جهاز فعلي.
3. auth flow لا يترك حالات معلقة أو رسائل غامضة.
4. القوائم المحفوظة لا تفقد state عند التنقل أو بعد login transition.

---

## المسار D: Merchant Operational Hardening

## الهدف
تثبيت الجانب التشغيلي للتاجر بحيث يصبح موثوقًا، لا مجرد موجود.

## الملفات المستهدفة
- `lib/features/merchant/presentation/screens/merchant_dashboard_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_menu_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_offers_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_photos_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_reviews_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_stories_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_hours_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_scan_screen.dart`
- أي repositories/providers مرتبطة بها

## التنفيذ
1. تصنيف عمليات التاجر إلى:
   - `must work now`
   - `can degrade`
2. `must work now`:
   - claim scan/redeem
   - menu publish
   - add/edit/delete item/category
   - offers create/edit/toggle
3. `can degrade`:
   - stories
   - photos polish
   - dashboard niceties
   - أي تحسينات غير حرجة على تجربة الإدارة
4. مراجعة الأخطاء التجارية:
   - venue not linked
   - publish validation errors
   - upload failures
   - dashboard refresh/backfill errors
5. التأكد أن كل عملية لها success/error feedback واضح ومترجم.

## فحوصات القبول
1. يمكن للتاجر تنفيذ `must work now` workflow كامل لمحل واحد:
   - menu publish
   - offer create/edit/toggle
   - scan/redeem
2. لا توجد screens تاجر "موجودة شكليًا" لكنها تفشل في happy path الحرج.
3. `can degrade` لا تمنع pilot أو soft launch إذا كانت الملاحظات عليها غير حرجة.
4. الأخطاء مفهومة وتسمح بالتعافي.

---

## المسار E: iOS Decision And Platform Baseline

## الهدف
إغلاق ملف iOS كقرار هندسي واضح بدل بقائه منطقة ضبابية.

## الملفات المستهدفة
- `lib/firebase_options.dart`
- `ios/**`
- Firebase project configuration

## القرار المطلوب
واحد فقط من الخيارين:
1. **دعم iOS في هذه الدورة**
   - إعداد Firebase iOS كامل
   - تشغيل التطبيق فعليًا
   - اختبار auth + push + core flows
2. **تجميد iOS مؤقتًا**
   - توثيق رسمي أن Android/Web فقط في هذه المرحلة
   - إزالة أي إيحاء خاطئ بأن iOS جاهز

## التنفيذ إذا تم اختيار الدعم
1. إضافة Firebase iOS config
2. تحديث `DefaultFirebaseOptions`
3. تشغيل build/checks على iOS
4. اختبار critical flows

## فحوصات القبول
1. لا يبقى `TargetPlatform.iOS` throw بلا قرار.
2. توجد وثيقة واضحة عن وضع iOS الحالي.

---

## المسار F: Security And Secrets Hardening

## الهدف
تقليل المخاطر الأمنية الواضحة قبل أي توسع جديد.

## الملفات المستهدفة
- `firestore.rules`
- `storage.rules`
- `functions/src/**`
- `scripts/**`
- `service-account-key.json`
- أي ملفات env أو مفاتيح تشغيل

## التنفيذ
1. `Sprint 0 quick audit` إلزامي:
   - التحقق من أن `service-account-key.json` ليس جزءًا من التشغيل اليومي العادي
   - التحقق من `.gitignore`
   - التحقق من أماكن استخدام المفتاح في `scripts/**` و`functions/scripts/**`
2. rules audit:
   - من يقرأ ماذا
   - من يكتب ماذا
   - merchant ownership checks
   - claim/redeem protection
3. functions audit:
   - input validation
   - auth enforcement
   - rate limiting
   - idempotency للأجزاء الحساسة
4. secrets audit:
   - منع بقاء مفاتيح حساسة غير لازمة في repo أو مسارات تشغيل عشوائية
5. مراجعة scripts المحلية التي تستخدم `service-account-key.json`.
6. توثيق secure local workflow للفريق.

## فحوصات القبول
1. كل flow حساس له rule/function check صريح.
2. لا توجد سكربتات تشغيل حساسة غير موثقة.
3. ملفات المفاتيح الحساسة تعامل كـ local-only، وليست جزءًا من التشغيل العادي.

---

## المسار G: Error Handling And Empty States

## الهدف
توحيد مستوى الجودة في التجربة عند الفشل، لا فقط عند النجاح.

## الملفات المستهدفة
- `lib/core/errors/app_exceptions.dart`
- `lib/core/widgets/app_error_widget.dart`
- صفحات results/map/venue/offers/merchant

## التنفيذ
1. حصر أنماط الأخطاء الشائعة:
   - no internet
   - permission denied
   - not found
   - unavailable
   - invalid state
2. توحيد ترجمة وعرض هذه الحالات.
3. منع الرسائل الخام أو التقنية من الظهور للمستخدم النهائي.
4. مراجعة empty states:
   - favorites
   - try list
   - saved offers
   - notifications
   - results

## فحوصات القبول
1. لا توجد رسالة exception خام تظهر للمستخدم.
2. empty/error/loading states موحدة في الإيقاع البصري والمعنى.

---

## المسار H: Testing And CI Gates

## الهدف
تحويل الجودة من "شغل يدوي" إلى Launch Gates قابلة للقياس.

## الملفات المستهدفة
- `.github/workflows/ci.yml`
- `test/**`
- أي scripts تشغيل للتأكد من analyze/test/gen-l10n

## التنفيذ
1. تعريف minimum CI gate:
   - `flutter analyze`
   - `flutter test`
   - `flutter gen-l10n` عند الحاجة
2. إضافة/تقوية tests على:
   - discovery state sync
   - navigation sanity
   - venue/menu critical widgets
   - offer/redeem logic where possible
3. تعريف smoke test checklist يدوي على الجهاز.
4. توثيق ما هو مطلوب قبل كل merge مهم.

## فحوصات القبول
1. CI يمنع regressions الأساسية.
2. يوجد smoke checklist قصيرة ومعتمدة.
3. أي تغيير في state/navigation/venue/offers يمر عبر gate واضح.

---

## المسار I: Performance Gate On Real Device

## الهدف
إغلاق النقاش حول الأداء بالأرقام على Android فعلي.

## السيناريوهات الإلزامية
1. venue ثقيل:
   - صور
   - قصص
   - عروض
   - تقييمات
   - منيو كبير
2. map search + moving + filters
3. offer claim + QR
4. merchant menu editing

## القياس
- `flutter run --profile`
- DevTools:
  - frame chart
  - raster jank
  - memory spikes

## معايير القبول
1. venue الثقيلة تبقى قابلة للاستخدام مع scroll بلا jank واضح يقطع القراءة أو التمرير.
2. لا يوجد memory spike يؤدي إلى kill أو reload أو تدهور واضح في الجلسة.
3. `claim -> QR -> redeem` يتم بلا stalls محسوسة للمستخدم.
4. `map -> results -> venue -> menu` يبقى usable على جهاز Android فعلي في `profile mode`.
5. القياس يعتمد على checklist موحدة، لا على انطباع حر غير موثق.

---

## Launch Readiness Gates

## الهدف
تعريف متى نقول إن النسخة جاهزة للدفع، ومتى لا.
هذا القسم هو **المرجع التنفيذي الرسمي** قبل أي:
- soft launch
- merchant pilot
- release candidate

## لا تعتبر النسخة جاهزة إذا
1. discovery state غير موحد.
2. claim/redeem flow غير مثبت على الهاتف.
3. merchant menu/scan/offers غير موثوق.
4. iOS داخل scope لكن ما زال غير مهيأ.
5. rules/functions فيها gaps واضحة.
6. CI لا يغطي analyze/test على الأقل.

## تعتبر النسخة قابلة للدفع عندما
1. state الحرج موحد.
2. critical user flows مثبتة.
3. critical merchant flows مثبتة.
4. security rules/functions audited.
5. CI gates تمر.
6. release note + known limitations موثقة.

---

## الترتيب التنفيذي المقترح

## Sprint 0: Baseline And Decision Gates
### الهدف
تثبيت baseline قبل أي تعديل كبير.

### التنفيذ
1. توثيق الوضع الحالي.
2. حسم قرار iOS.
3. `service-account-key` audit.
4. quick audit على:
   - `firestore.rules`
   - `storage.rules`
   - `functions` الحساسة
5. جمع smoke checklist.
6. baseline performance على Android.

### المخرجات
- baseline report
- iOS decision
- secrets audit result
- critical flows checklist

### Required Real-Device Test Before Closing Sprint 0
1. شغّل التطبيق على Android فعلي.
2. افتح `Home`.
3. افتح `Map`.
4. افتح `Profile`.
5. افتح `Venue Details`.
6. تأكد أن التطبيق يفتح ويغلق هذه الشاشات بدون crash.
7. سجّل ملاحظات baseline فقط:
   - startup
   - navigation
   - obvious lag
   - obvious broken UI
8. إذا iOS داخل scope:
   - شغّل build على Mac/Xcode
   - وسجّل هل Firebase init ينجح أم لا

---

## Sprint 1: Discovery State Unification
### الهدف
توحيد location/city/filter/settings state.

### المخرجات
- source-of-truth واضح
- sync ثابت بين Home/Results/Map/Filter

### Required Real-Device Test Before Closing Sprint 1
1. افتح `Profile`.
2. غيّر المدينة.
3. ارجع إلى `Home`.
4. افتح `Results`.
5. افتح `Map`.
6. افتح `Nearby`.
7. تأكد أن كل الشاشات تستخدم نفس المدينة.
8. أطفئ صلاحية الموقع.
9. افتح `Map` مجددًا.
10. تأكد أن fallback center صار على المدينة المختارة.
11. افتح `Question Flow -> Results`.
12. تأكد أن `Results` تحافظ على city الحالية.
13. افتح `FilterBottomSheet`.
14. غيّر الفلاتر.
15. تأكد أن `Results` و`Map` يعكسان نفس state.

---

## Sprint 2: Navigation And User Flows
### الهدف
تثبيت back stack والـ user critical flows.

### المخرجات
- route audit fixes
- venue/menu/offers/auth hardening

### Required Real-Device Test Before Closing Sprint 2
1. افتح `Profile` كضيف.
2. اضغط `تسجيل الدخول`.
3. أكمل login أو signup أو OTP.
4. تأكد أنك ترجع إلى `Profile`.
5. افتح `User Stats` كضيف.
6. اضغط `تسجيل الدخول`.
7. أكمل auth.
8. تأكد أنك ترجع إلى `Stats`.
9. افتح `Results -> Venue Details -> Venue Menu`.
10. اضغط back من `Venue Menu`.
11. تأكد أنك ترجع إلى `Venue Details`.
12. افتح `Saved Offers` و`My Claims` مباشرة.
13. اضغط back.
14. تأكد أن fallback route صحيح.
15. افتح مكان بدون مراجعات وأنت ضيف.
16. اضغط CTA الخاص بالمراجعات.
17. تأكد أنه يفتح login مع redirect للمكان نفسه.

---

## Sprint 3: Merchant Hardening
### الهدف
تثبيت العمليات اليومية الحرجة للتاجر.

### المخرجات
- merchant `must work now` paths مستقرة
- أخطاء أوضح

### Required Real-Device Test Before Closing Sprint 3
1. افتح `Merchant Dashboard`.
2. افتح `Edit Venue`.
3. عدّل واحفظ.
4. افتح `Hours`.
5. عدّل واحفظ.
6. افتح `Menu`.
7. أضف عنصرًا جديدًا في `Menu` ثم احفظه وتأكد من ظهور success feedback.
8. عدّل عنصرًا موجودًا ثم احفظه وتأكد من ظهور success feedback.
9. غيّر `availability` لعنصر موجود ثم تأكد أن التغيير يتم بدون فشل صامت.
10. انشر `draft` وتأكد من ظهور feedback واضح عند النجاح أو الفشل.
11. افتح `Offers`.
11. أنشئ offer جديدًا بقيمة خصم صحيحة.
12. جرّب إنشاء offer بقيمة فارغة أو نسبة أكبر من 100 وتأكد من منع الحفظ برسالة واضحة.
13. عدّل offer متوقف وتأكد أن التعديل لا يعيد تفعيله تلقائيًا.
14. امسح تاريخ البداية أو النهاية في offer موجود ثم احفظ، وتأكد أن التغيير يُحترم فعليًا.
15. فعّل/عطّل offer من القائمة الرئيسية وتأكد من ظهور feedback واضح.
16. احذف offer وتأكد من ظهور feedback واضح.
17. افتح `Photos`.
18. ارفع صورة واحذف صورة.
19. افتح `Reviews`.
20. أضف ردًا ثم احذفه.
21. افتح `Scan`.
22. امسح QR صالح.
23. نفّذ redeem ناجح وتأكد أن sheet يُغلق بعد النجاح.
24. جرّب redeem فاشل أو token غير صالح وتأكد أن الخطأ يظهر بوضوح وأن التدفق لا ينكسر.
25. تأكد أن كل `must work now` flows تنتهي بـ success/error feedback واضح وقابل للتعافي.

---

## Sprint 4: Security + CI + Performance Gate
### الهدف
إغلاق الجوانب التشغيلية قبل أي توسع.

### المخرجات
- rules/functions review
- CI gates أوضح
- Android performance report

### Required Real-Device Test Before Closing Sprint 4
1. شغّل التطبيق على Android في `profile mode`.
2. اختبر:
   - `Map`
   - `Results`
   - `Venue Details`
   - `Venue Menu`
   - `Offer claim -> QR`
   - `Merchant scan/redeem`
3. راقب:
   - frame drops
   - raster jank
   - memory spikes
4. أعد نفس التجربة على venue ثقيل.
5. إذا iOS داخل scope:
   - نفّذ smoke test مكافئ على iPhone
6. لا يغلق Sprint 4 بدون:
   - `flutter analyze`
   - `flutter test`
   - manual device pass
   - performance notes موثقة

---

## اختبار القبول الشامل
1. المستخدم يغير المدينة/الفلاتر ويرى انعكاسًا متسقًا بين الشاشات.
2. نتائج -> مكان -> منيو تعمل بسلاسة.
3. عرض -> مطالبة -> QR -> استرداد تعمل بالكامل.
4. التاجر يدير المنيو والعروض والساعات وscan دون تعثر جوهري.
5. لا توجد رسائل خام أو states مكسورة.
6. الوضع المنصاتي واضح: iOS مدعوم أو مؤجل بقرار صريح.
7. CI + tests تمنع regressions الأساسية.

---

## Checklist التشغيل قبل الإطلاق
1. هل `Sprint 0` أغلق فعليًا بما فيه قرار iOS وsecrets audit؟
2. هل `Discovery State` موحد بين Home/Results/Map/Filter؟
3. هل `Navigation + back stack` مثبتان على الهاتف؟
4. هل `claim -> QR -> redeem` يعمل end-to-end؟
5. هل merchant `must work now` flows مثبتة؟
6. هل rules/functions الحساسة راجعت؟
7. هل `flutter analyze` و`flutter test` وCI pass؟
8. هل performance checklist على Android pass؟
9. هل known limitations موثقة بوضوح؟

---

## Detailed Manual Validation Checklist

### 1. Discovery State
1. افتح `Profile` وغير المدينة.
2. ارجع إلى `Home`.
3. افتح `Results`.
4. تأكد أن النتائج تغيرت حسب المدينة الجديدة، وليس حسب آخر city قديمة محفوظة.
5. افتح `Map`.
6. إذا صلاحية الموقع مغلقة:
   - تأكد أن مركز الخريطة fallback صار على المدينة المختارة، وليس رام الله دائمًا.
7. افتح `Nearby`.
8. تأكد أن العناصر المعروضة هناك من نفس المدينة المختارة.
9. افتح `Question Flow`.
10. أكمل الاختيارات ثم افتح `Results`.
11. تأكد أن `Results` ما زالت تستخدم المدينة الحالية المختارة.
12. غيّر الفلاتر من `FilterBottomSheet`.
13. تأكد أن `Results` و`Map` يعكسان الفلاتر نفسها بدون reset مفاجئ.

### 2. Auth Redirect And Back Stack
1. افتح `Profile` كضيف.
2. اضغط `تسجيل الدخول`.
3. أكمل login/email أو guest أو OTP.
4. تأكد أن الرجوع النهائي بعد النجاح يعيدك إلى `Profile` وليس `Home` عشوائيًا.
5. افتح `User Stats` كضيف.
6. اضغط `تسجيل الدخول`.
7. أكمل auth.
8. تأكد أن العودة النهائية تذهب إلى `/stats`.
9. افتح `Login` مباشرة كرابط:
   - `/login`
10. اضغط زر الإغلاق.
11. تأكد أنه يرجع إلى `/home` إذا لم يوجد stack.
12. افتح `Signup` مباشرة كرابط:
   - `/signup`
13. اضغط زر الإغلاق أو رابط `سجّل دخول`.
14. تأكد أنه يرجع إلى `/login` إذا لم يوجد stack.
15. افتح `OTP` ضمن flow الهاتف.
16. اضغط `تغيير الرقم`.
17. تأكد أنه يرجع إلى شاشة login/phone entry، وليس pop إلى فراغ.

### 3. Venue Flow
1. افتح `Results`.
2. ادخل إلى `Venue Details`.
3. اضغط `عرض المنيو الكامل`.
4. تأكد أن `VenueMenuScreen` تُفتح كـ route مستقلة.
5. اضغط back من شاشة المنيو.
6. تأكد أنك ترجع إلى `Venue Details`.
7. افتح `Venue Details` مباشرة من الخريطة.
8. اضغط back.
9. تأكد أن العودة منطقية:
   - إلى الشاشة السابقة إذا فيه stack
   - أو fallback معقول إذا فُتحت مباشرة.

### 4. Reviews Flow
1. افتح مكان لا يحتوي مراجعات وأنت ضيف.
2. تأكد أن empty state لا يفتح form مباشرة.
3. اضغط CTA.
4. يجب أن يفتح login مع:
   - `redirectTo=/venue/:id`
5. أكمل تسجيل الدخول.
6. تأكد أنك ترجع لنفس صفحة المكان.
7. افتح review form كمستخدم مسجل.
8. أرسل مراجعة.
9. تأكد أن المراجعة تظهر بعد الإرسال وأن الـ counts تتحدث.

### 5. Offers And Claims Flow
1. افتح `Offer Details`.
2. اضغط claim على offer صالحة.
3. تأكد أن شاشة QR تفتح بدون stall.
4. اترك التايمر ينتهي أو جرّب offer منتهية.
5. تأكد أن النصوص تتغير إلى expired state بشكل واضح.
6. افتح `My Claims`.
7. اضغط على claim pending.
8. تأكد أنها تفتح `Offer Details` الصحيحة.
9. افتح `Saved Offers`.
10. اضغط back.
11. تأكد أن العودة إلى `Profile` تعمل حتى لو الشاشة فُتحت مباشرة.

### 6. Merchant Must-Work Flow
1. افتح `Merchant Dashboard`.
2. ادخل إلى `Edit Venue`.
3. احفظ تعديلًا بسيطًا.
4. تأكد من success feedback والرجوع الصحيح.
5. افتح `Hours`.
6. عدّل ساعات العمل واحفظ.
7. تأكد من success feedback والرجوع الصحيح.
8. افتح `Photos`.
9. جرّب رفع صورة.
10. تأكد أن الصورة تظهر وأن الرجوع لا يكسر stack.
11. افتح `Reviews`.
12. أضف ردًا ثم احذفه.
13. تأكد من feedback والrefresh.
14. افتح `Scan`.
15. امسح QR صالح.
16. أكمل `redeem`.
17. تأكد أن النتيجة النهائية واضحة وأن إعادة المسح تعمل.

### 7. iOS Baseline
1. افتح المشروع على Mac/Xcode.
2. شغّل `pod install` إذا لزم.
3. شغّل build/run على iPhone Simulator أو جهاز حقيقي.
4. تحقق من:
   - Firebase init
   - login
   - Google Sign-In URL scheme
   - Venue flow
   - Claim flow
5. إذا فشل أي جزء:
   - يسجل كـ blocker صريح، وليس ملاحظة جانبية.

### 8. Regression Smoke After Current Batch
1. `flutter analyze`
2. `flutter test`
3. افتح `Home -> Question Flow -> Results`
4. افتح `Map`
5. افتح `Profile`
6. افتح `Venue Details -> Venue Menu`
7. افتح `Offer Details`
8. افتح `My Claims`
9. افتح `Saved Offers`
10. افتح `Merchant Dashboard`
11. تأكد أنه لا يوجد:
   - crashes
   - back dead-ends
   - incorrect fallback routes
   - raw exception text

---

## المخاطر
1. محاولة تحسين كل شيء دفعة واحدة ستفشل.
2. فتح features جديدة أثناء هذه الخطة سيكسر التركيز.
3. تجاهل rules/functions أخطر من أي مشكلة UI حالية.
4. الاعتماد على النجاح في Web/Windows بدل Android سيعطي baseline مضلل.

---

## Explicit Non-Goals
- features جديدة
- OCR stabilization
- redesign شامل لكل الواجهة
- admin panel
- bookings/payments
- migration معمارية واسعة خارج الحاجة

---

## القرار النهائي
العمل التالي المنطقي على المشروع ليس feature جديدة، بل **مرحلة تثبيت شاملة**.  
إذا نُفذت هذه الخطة، يصبح المشروع في وضع أقوى بكثير لاتخاذ قرار:
- soft launch
- merchant pilot
- أو توسع ميزات لاحق بثقة أعلى
