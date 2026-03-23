# خطة تنفيذ نهائية: نقل المنيو إلى شاشة مستقلة

## Summary
نقل المنيو من داخل `VenueDetailsScreen` إلى شاشة مستقلة `VenueMenuScreen`، مع إبقاء صفحة المطعم كـ overview أخف وأوضح.

هذه الخطة تعتمد القرارات التالية بشكل نهائي:
- `Offers` تبقى في صفحة المطعم
- `Featured items` تصبح ضمن preview في صفحة المطعم
- صفحة المطعم تعرض `preview + CTA`
- `Claim offer logic` تبقى callback كما هي
- التنفيذ يكون: **فصل معماري أولاً، ثم polish بصري**
- `TabController` في صفحة المطعم يصبح `length: 2`

---

## الهدف
1. إزالة تعقيد المنيو من صفحة المطعم.
2. جعل صفحة المطعم أخف وأوضح.
3. إنشاء شاشة منيو مستقلة أسهل في التصفح والصيانة.
4. إنهاء مشاكل تداخل المنيو مع الهيدر والتمرير داخل صفحة المطعم.
5. إبقاء المنيو نفسه قابلًا للتطوير لاحقًا بشكل مستقل.

---

## النطاق

### داخل النطاق
- `lib/core/routing/app_router.dart`
- `lib/features/venue/presentation/screens/venue_details_screen.dart`
- `lib/features/venue/presentation/screens/venue_menu_screen.dart` (جديد)
- `lib/features/venue/presentation/widgets/venue_menu_tab.dart`
- `lib/features/venue/presentation/widgets/venue_menu_preview_section.dart` (جديد)
- `lib/features/venue/presentation/widgets/venue_menu_section.dart` عند الحاجة المحدودة

### خارج النطاق
- backend
- repositories
- OCR
- merchant menu
- offers business logic
- reviews/details content نفسه

---

## القرار المعماري

### صفحة المطعم `VenueDetailsScreen`
تصبح شاشة Overview فقط، وتحتوي على:
- الهيدر
- summary strip
- stories
- offers
- menu preview
- tabs:
  - `التفاصيل`
  - `الآراء`

### شاشة المنيو `VenueMenuScreen`
تصبح شاشة مستقلة وتحتوي على:
- AppBar واضح
- اسم المطعم
- منيو كامل:
  - search
  - chips
  - sections
  - expand/collapse
  - item details sheet

---

## القرارات النهائية

### 1. Offers section
- تبقى في `VenueDetailsScreen`
- لا تنتقل إلى `VenueMenuScreen`

### 2. Featured items
- تنتقل لتكون جزءًا من `menu preview` داخل صفحة المطعم
- لا تظهر أعلى شاشة المنيو المستقلة

### 3. Preview في صفحة المطعم
- نعتمد `preview items + CTA`
- وليس CTA فقط

### 4. Claim offer logic
- تبقى callback كما هي
- لا يُنقل منطق claim إلى شاشة المنيو

### 5. ترتيب التنفيذ
- المرحلة الأولى: فصل معماري
- المرحلة الثانية: visual polish داخل شاشة المنيو الجديدة
- لا نخلط الاثنين

### 6. TabController
- يصبح `length: 2`
- `المنيو` يخرج من التبويبات بالكامل
- لا نسمح بتبويب يفتح route جديدة

---

## Implementation Plan

## Phase 1: Routing
### الملف
- `lib/core/routing/app_router.dart`

### التغييرات
- إضافة route جديد:
  - `/venue/:id/menu`
- بناء route إلى:
  - `VenueMenuScreen(venueId: id)`

### النتيجة
- المنيو يصبح شاشة مستقلة قابلة للفتح عبر `context.push`

---

## Phase 2: إنشاء شاشة المنيو المستقلة
### الملف
- `lib/features/venue/presentation/screens/venue_menu_screen.dart`

### التغييرات
- إنشاء `Scaffold`
- `AppBar` بسيط:
  - back
  - اسم المطعم
- body يعتمد على `venueByIdProvider(venueId)`
- حالات:
  - loading
  - error
  - empty venue
  - data
- عند وجود venue:
  - عرض `VenueMenuTab`

### ملاحظة
- `VenueMenuScreen` لا تعرض:
  - offers
  - stories
  - reviews
  - social/meta blocks

---

## Phase 3: تبسيط VenueMenuTab للشاشة المستقلة
### الملف
- `lib/features/venue/presentation/widgets/venue_menu_tab.dart`

### التغييرات
- تحويل `VenueMenuTab` ليكون menu-focused
- إزالة أو جعل هذه العناصر اختيارية:
  - `VenueOffersSection`
  - `VenueFeaturedItemsRow`
- إضافة flags إذا لزم:
  - `showOffersSection = false`
  - `showFeaturedItems = false`
- أو الأفضل:
  - إزالة هذه العناصر من `VenueMenuTab` نهائيًا إذا أصبحت مسؤولية preview فقط

### القرار المفضل
- `VenueMenuTab` للشاشة المستقلة يجب أن يعرض:
  - header
  - search
  - chips
  - sections
  - bottom sheet
- بدون offers
- بدون featured row

---

## Phase 4: إنشاء Menu Preview داخل صفحة المطعم
### الملف
- `lib/features/venue/presentation/widgets/venue_menu_preview_section.dart`

### التغييرات
- widget جديد يعرض:
  - عنوان `المنيو`
  - عدد الأصناف
  - 3 إلى 5 أصناف فقط
  - featured items إذا وجدت
  - زر واضح:
    - `عرض المنيو الكامل`
- يعتمد على نفس menu providers الحالية
- لا يحتوي:
  - search
  - chips
  - section expand/collapse
  - heavy scroll logic

### الهدف
- إبقاء صفحة المطعم informative
- بدون إدخال full menu complexity داخلها

---

## Phase 5: تعديل VenueDetailsScreen
### الملف
- `lib/features/venue/presentation/screens/venue_details_screen.dart`

### التغييرات
- إزالة `VenueMenuTab` من `TabBarView`
- جعل التبويبات:
  - `التفاصيل`
  - `الآراء`
- إضافة `VenueMenuPreviewSection` في مكان مناسب داخل الصفحة
- زر `عرض المنيو الكامل` يفتح:
  - `context.push('/venue/${venue.id}/menu')`

### النتيجة
- صفحة المطعم تصبح أخف
- الـ tabs تصبح منطقية
- المنيو لم يعد مرتبطًا بمشاكل الهيدر والتمرير في نفس الشاشة

---

## Phase 6: UX polish بعد الفصل
### الملفات
- `lib/features/venue/presentation/screens/venue_menu_screen.dart`
- `lib/features/venue/presentation/widgets/venue_menu_tab.dart`
- `lib/features/venue/presentation/widgets/venue_menu_section.dart`

### التغييرات
- بعد استقرار الفصل المعماري:
  - polish بصري للمنيو داخل الشاشة الجديدة
  - spacing
  - search block
  - section chips
  - item rows
  - preview rhythm

### السبب
- بعد الفصل، أي polish سيكون أوضح وأقل خطورة

---

## تفاصيل UX النهائية

## صفحة المطعم
### تحتوي على
- hero/header
- summary strip
- offers
- stories
- menu preview
- details tab
- reviews tab

### لا تحتوي على
- full menu
- chips
- full search
- full category scrolling

## شاشة المنيو
### تحتوي على
- app bar
- menu title / venue name
- search
- category chips
- sections
- items
- item details sheet

### لا تحتوي على
- offers section
- featured row كعنصر مستقل أعلى الشاشة
- tabs أخرى

---

## Public API / Contract Changes

### جديد
- `VenueMenuScreen`
- `VenueMenuPreviewSection`

### تغييرات
- `VenueDetailsScreen`:
  - `TabController(length: 2)` بدل 3
- `VenueMenuTab`:
  - قد يصبح أنظف بعد إزالة المنطق غير الخاص بالمنيو
  - أو يحصل على flags اختيارية لو أردنا migration تدريجي

---

## Acceptance Criteria
تعتبر الخطة ناجحة إذا تحقق التالي:

1. صفحة المطعم لم تعد تعرض المنيو الكامل داخلها.
2. يوجد `Menu Preview + CTA` واضح داخل صفحة المطعم.
3. الضغط على `عرض المنيو الكامل` يفتح شاشة جديدة.
4. الرجوع من شاشة المنيو يرجع طبيعي إلى صفحة المطعم.
5. صفحة المطعم تصبح أخف بصريًا وأسهل في التصفح.
6. شاشة المنيو تعرض full menu بشكل مستقل وواضح.
7. لا regression في:
   - search
   - chips
   - section navigation
   - item details sheet
8. الأداء في صفحة المطعم يتحسن مقارنة بالحالة الحالية.

---

## Test Cases

1. فتح صفحة مطعم ثم الضغط على `عرض المنيو الكامل`
2. back من شاشة المنيو إلى صفحة المطعم
3. venue فيها منيو كبير
4. venue بدون منيو structured
5. venue فيها featured items
6. venue فيها offers
7. menu search يعمل داخل الشاشة الجديدة
8. chips تعمل داخل الشاشة الجديدة
9. item details sheet تعمل داخل الشاشة الجديدة
10. tabs في صفحة المطعم أصبحت فقط:
   - التفاصيل
   - الآراء

---

## Risks
1. إذا أبقينا عناصر من المنيو الكامل داخل صفحة المطعم، سنرجع نفس المشكلة.
2. إذا أبقينا `TabController` بطول 3 مع tab يفتح شاشة، سنخلق UX مربك.
3. إذا لم نفصل `VenueMenuTab` من responsibilities غير المنيو، سننقل التعقيد فقط إلى شاشة ثانية.

---

## Rollout Order
1. `app_router.dart`
2. `venue_menu_screen.dart`
3. `venue_menu_preview_section.dart`
4. `venue_details_screen.dart`
5. `venue_menu_tab.dart`
6. `flutter analyze`
7. تجربة على الهاتف
8. بعد ثبات المعمارية: visual polish pass

---

## Explicit Non-Goals
هذه الخطة لا تشمل:
- تحسين OCR
- تعديل backend
- إعادة تصميم offers نفسها
- إعادة تصميم reviews/details
- merchant menu changes

---

## Ready-to-Implement Decision
هذه الخطة جاهزة للتنفيذ بدون أسئلة مفتوحة.
