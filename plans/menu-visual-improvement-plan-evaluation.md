# تقييم الخطة: Menu Visual Improvement Plan V2

رأيي العام: **خطة قوية وناضجة جداً**، تكشف عن تفكير منهجي ومراعاة لقيود حقيقية (Arabic-first, performance, accessibility, photo-poor venues). نسبة الجاهزية للتنفيذ ≈ 85%. تحتاج فقط شدّ في 3-4 نقاط قبل أن تصبح Ticket-ready بالكامل.

---

## ما يميّز الخطة (نقاط القوة)

| البُعد | الملاحظة |
| --- | --- |
| **الـ Scope discipline** | تعريف واضح لـ Non-goals (no Firestore changes, no cart) — يحمي Phase 1 من الانتفاخ. |
| **Audit دقيق** | تحديد الأصول الموجودة وغير المستخدمة (`isFeatured`, `MenuSection.icon`, `VenueFeaturedItemsRow`) قبل بناء أي شيء جديد — هذا يقلل العمل الفعلي بشكل كبير. |
| **احترام قرار سابق** | الإشارة إلى `docs/plan_review/venue_menu_redesign_plan.md` والالتزام بقاعدة "preview-first" يدل على انضباط معماري. |
| **Capability check واقعي** | عدم افتراض وجود Remote Config، والاعتماد على atomic release بدلاً منه — قرار صحيح هندسياً. |
| **Photo-poor first-class** | معاملة الـ no-photo state كحالة أساسية لا fallback — قرار تصميمي ذكي خصوصاً في السوق المحلي حيث تغطية الصور غير منتظمة. |
| **Priority Model (MoSCoW)** | Must/Should/Could/Won't واضحة وقابلة للقياس. |
| **Acceptance criteria لكل مكون** | كل component معه شروط قبول قابلة للاختبار — هذا نادر في خطط بهذا الحجم. |
| **KPI gate رقمي** | +10% item-open، -10% no-interaction، ≤5% regression in TTI — قابلة للقياس وغير متفائلة. |

---

## نقاط ضعف / فجوات يجب معالجتها

### 1. مشكلة "Baseline analytics" (خطر متوسط ⚠️)

الخطة تطلب KPI gate رقمي لكنها تعترف "If no baseline exists, the pilot should collect one". هذا تناقض عملي:

- **الواقع:** إذا لم يكن هناك baseline حالياً → الـ Pilot الأول لن يحقّق KPI gate أصلاً، سيقيس فقط.
- **التوصية:** اجعل **Ticket 7 (Measurement)** يسبق Ticket 1 جزئياً، أو على الأقل أضف "Phase 0: Baseline week" قبل أي تغيير UI — أسبوعان من analytics على الـ UI الحالي ثم ابدأ.

### 2. الـ Featured governance غير محسوم (خطر عالٍ ⚠️⚠️)

الخطة تذكر في Risks: *"Featured losing meaning if too many merchant items are marked featured"* — لكنها لا تحدد:

- ما الحد الأقصى لكل Venue؟ (مثلاً ≤ 20% من العناصر، أو cap صلب 8)
- من يعاقب الـ Venue التي تضع كل عناصرها featured؟
- هل هناك enforcement على مستوى الـ Firestore rules أو client-side فقط؟

**التوصية:** أضف Open Decision صريحاً: *"Define max featured items per venue and enforcement layer"*. بدون هذا، الـ Featured strip سيتحول إلى ضوضاء خلال أسابيع.

### 3. Currency localization تحت-محددة

البنود تذكر "₪ or شيكل for ILS" لكن:

- ماذا عن JOD أو USD لو ظهرت لاحقاً؟
- هل الرمز قبل الرقم أم بعده في RTL؟ (في العربية الموحدة: `15 ₪` لا `₪ 15`)
- هل تستخدم `intl.NumberFormat.currency` أم mapping يدوي؟

**التوصية:** أضف جدول صغير في Ticket 1 يحدد: locale → symbol → position → fallback.

### 4. "Above the fold" غير قابل للقياس

عبارة "first useful content visible above the fold on a normal phone" تتكرر 4 مرات لكنها ضبابية:

- ما هو "normal phone"؟ Pixel 6 (411x914)؟ iPhone 12 (390x844)؟
- ما هو "useful content"؟ أول item tile؟ أول section header؟

**التوصية:** اعتمد رقماً صريحاً مثل: *"On a 390×844 viewport, after data load, the first menu item tile must be at least 50% visible without scrolling."*

### 5. Golden tests + remote images

الخطة تقول "Use deterministic placeholder/image mocks where possible" لكن لا تحدد المكتبة (`network_image_mock`? `mocktail` + `Image.memory`?). بدون هذا، ستتأخر Tickets 1-2 بسبب flaky CI.

**التوصية:** اختر المكتبة في Ticket 0 وثبّتها قبل Ticket 1.

### 6. غياب RTL test explicit

رغم أن "Arabic-first" مذكورة كثيراً، Test Plan لا يحوي اختباراً صريحاً لـ `Directionality(textDirection: TextDirection.rtl)` لكل widget جديد. في الـ Featured strip الأفقي تحديداً، اتجاه التمرير في RTL يجب أن يكون من اليمين لليسار — وهذا مصدر bugs شهير في Flutter.

**التوصية:** أضف بند صريح: *"Each new widget must have at least one RTL widget test asserting layout and scroll direction."*

### 7. الـ Section Header progress badge

المكون D يذكر "Keep progress/count badge" لكن لا يوضح ما هو الـ progress (نسبة العناصر المتاحة؟ نسبة العناصر التي تم تصفحها؟). إذا كان غير واضح للمطور، سيُنفَّذ بشكل عشوائي.

---

## ملاحظات تكتيكية أصغر

- **Ticket 5** (extract details sheet) يجب أن يكون **Ticket 0.5**، أي قبل Ticket 1، لا في المنتصف. تحسين widget قبل استخراجه يخلق merge conflicts.
- **Ticket 3** يدمج Header + Category + Section icons في تذكرة واحدة — هذا كبير. اقسمه إلى 3a (Header) و 3b (Chips + icons).
- **Performance budget** يذكر "120-item menu" — جرّب على **300 items** أيضاً، فبعض المطاعم في فلسطين/الأردن لها قوائم ضخمة (شاورما + مشاوي + مشروبات + حلويات + إفطار...).
- **Manual QA checklist** ينقصه: *"Venue with mixed Arabic + English item names"* — حالة شائعة جداً ("Cappuccino كابتشينو").
- **Risk Register** ينقصه: *"Image caching memory pressure on low-end Android (1-2GB RAM)"* — مهم لجمهور محلي.

---

## ترتيب التنفيذ المقترح (تعديل بسيط)

| المرحلة | التذكرة |
| --- | --- |
| 0 | Product decisions + extract details sheet + golden infra + analytics baseline collection |
| 1 | Item Tile refresh + currency + RTL tests |
| 2 | Header + section icons mapping (without chips redesign) |
| 3 | Category chips redesign + sticky polish |
| 4 | Section header refresh |
| 5 | Featured row (preview-first, then compact strip) |
| 6 | Details sheet visual refresh |
| 7 | Legacy gallery + preview card |
| 8 | Analytics wiring + pilot |
| 9 | QA + golden + release |

السبب: تأجيل Featured row إلى ما بعد استقرار باقي الـ tiles يقلل rework إذا تغيّر تصميم البطاقة.

---

## القرار

**أوصي بالموافقة مع 3 شروط حاسمة قبل بدء Ticket 1:**

1. حسم **Featured governance** (الحد الأقصى + التطبيق) كـ Open Decision صريح.
2. تحديد **Baseline period** للـ analytics (أسبوع-أسبوعين على UI الحالي) قبل قياس أي KPI gate.
3. تثبيت **golden testing infra + RTL test convention** في Ticket 0.

بدون هذه الثلاثة، الخطة قابلة للتنفيذ لكنها ستُنتج جدلاً متأخراً (rework). معها، تصبح خطة execution-ready بمعنى الكلمة.
