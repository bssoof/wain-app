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

---

## Sprint 1: Discovery State Unification
### الهدف
توحيد location/city/filter/settings state.

### المخرجات
- source-of-truth واضح
- sync ثابت بين Home/Results/Map/Filter

---

## Sprint 2: Navigation And User Flows
### الهدف
تثبيت back stack والـ user critical flows.

### المخرجات
- route audit fixes
- venue/menu/offers/auth hardening

---

## Sprint 3: Merchant Hardening
### الهدف
تثبيت العمليات اليومية الحرجة للتاجر.

### المخرجات
- merchant `must work now` paths مستقرة
- أخطاء أوضح

---

## Sprint 4: Security + CI + Performance Gate
### الهدف
إغلاق الجوانب التشغيلية قبل أي توسع.

### المخرجات
- rules/functions review
- CI gates أوضح
- Android performance report

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
