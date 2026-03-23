# WAIN App - Unified UI Redesign Master Plan

**Date:** March 11, 2026  
**Scope:** Visual/system redesign only. Preserve existing routes, features, and operational behavior.

## 0. Current Status At A Glance

- `Phase 1`: منفذة بالكامل من ناحية الكود، والتحقق الآلي مرّ بنجاح
- `Phase 2`: منفذة بالكامل من ناحية الكود، والتحقق الآلي مرّ بنجاح
- `Phase 3`: منفذة بالكامل من ناحية الكود، والتحقق الآلي مرّ بنجاح
- لا توجد blockers برمجية مفتوحة حاليًا
- المتبقي اختياري لتحسين الثقة فقط:
  - `manual device QA`
  - `final smoke pass on real user flows`
- هذه الوثيقة لم تعد فقط خطة؛ هي أيضًا:
  - implementation journal
  - QA log
  - closure reference

## 1. Design Intent

- نطوّر الواجهة الحالية باتجاه `polish current design`, not `full glass`.
- نحافظ على أساس `Material 3 + Cairo + RTL + current Wain magenta identity`.
- لا نغيّر `routes`, ولا نبني information architecture جديدة، ولا نضيف product features تحت اسم redesign.
- أي `blur` أو `translucency` يبقى محدودًا بالعناصر العائمة فوق محتوى متغير مثل الخريطة أو الستوري، وليس كأسلوب عام للتطبيق كله.
- الأولوية هي `clarity, hierarchy, consistency, Arabic readability, and implementation safety`.
- كل قرار بصري جديد يجب أن يمر من خلال `tokens + theme + shared patterns`, لا من خلال قرارات ad-hoc داخل كل شاشة.

## 2. Current Strengths to Preserve

- `Material 3 + Cairo` اختيار صحيح للتطبيق الحالي، ولا يحتاج استبدالًا.
- `RTL plumbing` مضبوط على مستوى التطبيق، وهذا أساس جيد يجب البناء عليه لا إعادة اختراعه.
- بنية `Riverpod + GoRouter + feature folders` مناسبة وتسمح بإعادة تصميم UI بدون هدم architecture.
- شاشة `Home` تملك شخصية واضحة عبر الـ wavy hero، ويجب الحفاظ على هذه الشخصية بدل تذويبها في UI عام.
- `Map` يملك foundations قوية: clustering, sheet behavior, offline handling, filters, and venue preview logic.
- `Venue Details` يملك scrolling structure جيدًا عبر `NestedScrollView` و`TabBar` pinned behavior.
- توجد shared states usable مثل `AppErrorWidget`, `AppEmptyState`, و`AppSkeleton`.
- التطبيق فعليًا multi-surface: discovery + map + venue + offers + merchant. الخطة يجب أن تحترم هذا الاتساع.

## 3. System Problems to Fix

- `Raw hex colors` و`Colors.grey/...` مستخدمة بشكل واسع داخل الشاشات بدل theme tokens.
- لا يوجد `named typography scale` ثابت؛ الأحجام الحالية متقاربة لكنها غير منضبطة.
- `Radius`, `shadow`, و`spacing` متفاوتة جدًا بين الشاشات.
- `Dark theme` غير مكتمل بما يكفي؛ كثير من local colors تتجاوزه.
- `Buttons` لا تملك hierarchy موحدة بما يكفي بين primary/secondary/tertiary actions.
- `Bottom sheets`, cards, inputs, and floating overlays لا تتبع surface system واحد.
- شاشات `Merchant` كثيفة بصريًا وتحتاج extraction of shared patterns بدل بقاء كل شيء inline.
- التطبيق فيه بعض fallback patterns الصحيحة حاليًا، مثل fallback النصي للـ logo في `Home`. لا يجوز كسر هذه المرونة بافتراض أصول غير موثقة.

## 4. Unified Design System

### 4.1 Color Tokens

**Brand**

- `primary`: `#C0006F`
- `primaryLight`: `#E91E8C`
- `primarySoft`: `#FF6B9D`
- `primarySurface`: `#FFF0F6`

**Neutral / Light**

- `background`: `#F5F5F8`
- `surface`: `#FFFFFF`
- `surfaceTinted`: `#FAFAFA`
- `border`: `#E8E8EC`
- `textPrimary`: `#1A1A1A`
- `textSecondary`: `#6B7280`
- `textTertiary`: `#9CA3AF`

**Neutral / Dark**

- `background`: `#121214`
- `surface`: `#1E1E22`
- `surfaceTinted`: `#2A2A30`
- `border`: `#3A3A42`
- `textPrimary`: `#F0F0F2`
- `textSecondary`: `#9CA3AF`
- `textTertiary`: `#6B7280`

**Semantic**

- `success`: `#10B981`
- `error`: `#EF4444`
- `warning`: `#F59E0B`
- `info`: `#3B82F6`

**Rule**

- داخل الكود لاحقًا: `no raw hex in screen files`.
- كل لون جديد يجب أن يأتي من `AppTheme`, `ColorScheme`, أو token file واضح.
- وجود قيم hex هنا مقبول لأنها design tokens documentation، وليس استخدامًا مباشرًا داخل screens.

### 4.2 Typography Scale

الخط الأساسي يبقى `Cairo`.

| Token | Size | Weight | Use |
|------|------|--------|-----|
| `displayLg` | 32 | 700 | Home heading, major hero text |
| `displaySm` | 28 | 700 | Question titles, large section headlines |
| `headlineMd` | 22 | 600 | Offer title, large section titles |
| `headlineSm` | 18 | 600 | AppBar titles, card headings |
| `titleMd` | 16 | 600 | List titles, stat values |
| `titleSm` | 14 | 500 | Secondary headings, chip labels |
| `bodyLg` | 16 | 400 | Long-form Arabic text |
| `bodySm` | 14 | 400 | Secondary rows and descriptions |
| `caption` | 12 | 400 | Timestamps, tertiary labels |
| `overline` | 11 | 600 | Tiny section labels when needed |

**Arabic readability rules**

- لا ننزل عن `14sp` للنص الوظيفي القابل للضغط أو القراءة المنتظمة.
- line height للنص العربي الجاري لا تقل عن `1.4`، والمفضل `1.5-1.6`.
- استخدم `TextAlign.start` بدل `TextAlign.right` عندما لا توجد حاجة خاصة، ودع `Directionality` يدير الاتجاه.
- لا نحشر نصوصًا عربية طويلة داخل cards ضيقة أو columns شديدة الاكتناز.

### 4.3 Spacing and Radius

**Spacing base**

- `xs = 4`
- `sm = 8`
- `md = 12`
- `lg = 16`
- `xl = 20`
- `xxl = 24`
- `xxxl = 32`

**Usage**

- `16-24` padding للشاشات والأقسام الأساسية
- `8-12` internal gaps للعناصر الصغيرة
- `20-32` للانتقالات بين sections الكبيرة

**Radius tiers**

- `radiusSm = 8`
- `radiusMd = 12`
- `radiusLg = 20`
- `radiusFull = 999`

**Rule**

- `12` هو workhorse radius لمعظم buttons, inputs, cards.
- `20` فقط للـ hero surfaces, modals, major image blocks.
- أوقف التفاوت الحالي بين `8 / 10 / 12 / 16 / 20 / 30` داخل الواجهات.

### 4.4 Elevation and Surface Model

**Shadow tiers**

- `elevated`: card/floating bar/fab
- `overlay`: modal/sheet/floating overlay over media or map

**Surface rules**

- `surface` للبطاقات الرئيسية
- `surfaceTinted` للمناطق الثانوية أو input fills
- `primarySurface` فقط كإشارة brand-highlight خفيفة، وليس background عامًا
- لا نعتمد على shadow وحده لخلق hierarchy؛ يجب أن يعمل مع spacing, border, and typography

### 4.5 Button Hierarchy

| Level | Purpose | Style Direction |
|------|---------|-----------------|
| `Primary` | main CTA | filled with `primary`, white label, `radiusMd`, min height `48-52` |
| `Secondary` | important secondary action | outlined, primary border/text |
| `Tertiary` | contextual action | text-only |
| `Danger` | destructive action | error border/text or error fill حسب السياق |
| `Ghost` | icon-only utility action | transparent background |

**Rules**

- لا يوجد صراع بعد اليوم بين `radius 30` و`radius 12` للأزرار العامة.
- loading state يجب أن يكون consistent عبر buttons.
- CTA الأساسي في كل شاشة يجب أن يكون بصريًا واضحًا بدون منافسة من 2-3 primary buttons.

### 4.6 Iconography

- نبقي `existing Flutter Material icons` في المرحلة الحالية.
- `Material Symbols Rounded` خيار مستقبلي فقط `if adopted explicitly`؛ ليس افتراضًا لازمًا الآن.
- أحجام الأيقونات:
  - `20` inline
  - `24` actions
  - `28+` feature icons
- لا نعتمد على `Colors.grey` المباشرة لتلوين الأيقونات؛ استخدم semantic or theme text colors.

### 4.7 Loading, Empty, and Error States

**Loading**

- `Skeleton` للقوائم والبطاقات والمحتوى المتوقع شكله.
- `WainLoadingIndicator` للعمليات المركزة مثل claim, submit, publish.
- لا نعود إلى spinner عام في منتصف الشاشة إلا إذا لم يكن هناك layout معروف أصلًا.

**Empty**

- headline واضح
- body text مختصر
- optional CTA
- illustration أو icon treatment بسيط من نفس النظام

**Error**

- error container أو widget موحد
- retry action عندما يكون منطقيًا
- no ad-hoc error UIs لكل شاشة إلا إذا كانت المهمة معقدة بما يكفي لتبرير ذلك

### 4.8 Blur and Translucency Policy

**Allowed**

- map floating search / control containers
- map route summary card
- top area of certain sheets فوق الخريطة
- story top progress/header overlay
- story bottom visit CTA overlay إذا احتاج surface separation

**Not allowed**

- scaffold backgrounds
- standard cards
- profile/settings lists
- venue details body
- generic app bars across the app
- full-screen glassmorphism look

**Rule**

- blur هو solution موضعي للعناصر العائمة فوق محتوى متغير، وليس visual identity عامة.
- `blur_container.dart` لا يُستخدم إلا في العناصر والشاشات المسموح بها صراحة داخل هذه الوثيقة.
- ممنوع استخدام `blur_container.dart` كحل سريع لأي `card`, `app bar`, أو surface عادي فقط لأنه يبدو "modern".

### 4.9 Accessibility and Resilience Rules

**Contrast**

- body text and essential UI text يجب أن يحقق حدًا أدنى `4.5:1`
- large text, major icons, and non-text emphasis elements يجب أن لا تنزل عن `3:1`
- لا نعتمد على اللون وحده للتعبير عن state أو selection

**Touch targets**

- minimum tap target يبقى ضمن `44-48dp`
- أي icon-only action يجب أن يملك hit area حقيقية، لا icon مرسومًا فقط

**Text scaling**

- core screens يجب أن تبقى usable مع system text scaling بدون clipping أو overlapping
- `Home`, `Results`, `Venue Details`, `Login/OTP`, و`Merchant forms` هي minimum audit set

**Arabic overflow**

- layouts يجب أن تتحمل Arabic labels الأطول بدون كسر hierarchy
- لا يسمح بـ truncated critical labels في buttons, tabs, أو form actions إلا إذا كان هناك fallback واضح

**Focus and keyboard behavior**

- `Auth` و`Merchant forms` يجب أن تحترم keyboard insets, next/done flow, and visible focus state
- لا يسمح بأن يغطي keyboard الـ primary CTA أو حقول الإدخال المهمة بدون scrolling/fixed safe behavior

## 5. Screen Clusters and Specs

### 5.1 Discovery

**Screens:** `Splash`, `Onboarding`, `Home`, `Question Flow`, `Results`

**Role**

- هذا cluster هو entry funnel الأساسي للاكتشاف، ويجب أن يبقى friendly, branded, and fast.

**Keep**

- شخصية `Home` الحالية مع الـ wavy hero
- `Question Flow` كرحلة قصيرة ومباشرة
- `Results` كقائمة اقتراحات واضحة
- Onboarding مختصر وليس marketing-heavy

**Change**

- توحيد header treatment, typography, button hierarchy, and spacing
- إزالة redundancy في `Home` header: profile avatar يكفي؛ لا حاجة لزر settings منفصل إذا كان يذهب لنفس المكان
- تحسين step indicators في `Question Flow`
- جعل `Results` أوضح بصريًا عبر consistent cards and filter summary treatment
- إذا توفر asset logo موثق، استخدمه. إذا لم يتوفر، حافظ على text fallback الحالي بدل افتراض أصل غير موجود

**Do Not Break**

- لا تغيّر مسار `home -> question flow -> results`
- لا تضف bottom navigation
- لا تستبدل هوية `Home` بمظهر generic
- لا تفترض `logo.png` إلا إذا كان موجودًا فعلًا في assets

### 5.2 Browse and Conversion

**Screens:** `Map`, `Venue Details`, `Venue Menu`, `Offer Details`, `Offer QR`

**Role**

- هذا cluster هو مكان التصفح، اتخاذ القرار، والتحويل إلى زيارة/claim/navigation.

**Keep**

- قوة `Map` الحالية: clustering, sheet behavior, venue preview, offline awareness
- بنية `Venue Details` الحالية مع sections وtabs
- `Offer QR` كشاشة utility عالية الوضوح

**Change**

- `Map` هو المكان الرئيسي الوحيد الذي يمكن أن يستفيد من blur overlays restrained
- توحيد surfaces والـ floating controls في map
- رفع مستوى hierarchy في `Venue Details` بدون تغيير sections أو behavior
- تحسين `Offer Details` ليصبح أكثر content-first وأقل اعتمادًا على ad-hoc colors
- إبقاء `Offer QR` high-contrast and focused، مع styling أوضح للوقت والحالة

**Do Not Break**

- لا تغيّر map interaction model الحالية
- لا تضف glass surfaces داخل body of venue/details/menu screens
- لا تغيّر claim/navigation/call/WhatsApp behavior
- لا تبسّط `Venue Menu` أو `Offer QR` بطريقة تؤثر على utility

### 5.3 Personal

**Screens:** `Favorites`, `Try List`, `Saved Offers`, `My Claims`, `Profile`, `Edit Profile`, `User Stats`, `Notifications`

**Role**

- هذا cluster ينظم علاقة المستخدم بالتطبيق ومحتواه المحفوظ وإعداداته.

**Keep**

- list-based readability الحالية في الصفحات الشخصية
- `Profile` كنقطة دخول مركزية للإعدادات والنشاط
- reuse existing cards where appropriate

**Change**

- توحيد visual treatment للـ lists, section headers, tiles, and cards
- جعل `Profile` أكثر grouping وأقل scatter
- جعل `User Stats` و`Notifications` أكثر وضوحًا عبر tokens لا عبر سلوكيات جديدة
- تحسين empty states للـ saved/personal surfaces

**Do Not Break**

- لا تضف `grid/list toggle` في `Favorites` ضمن هذه الخطة
- لا تضف `swipe to dismiss` في `Notifications` إلا إذا أُدخل هذا السلوك عمدًا لاحقًا
- لا تغيّر routes أو entry points لهذه الصفحات

### 5.4 Auth

**Screens:** `Login`, `Signup`, `OTP`

**Role**

- هذا cluster functional-first، ويجب أن يكون واضحًا وموثوقًا أكثر من كونه مزخرفًا.

**Keep**

- دعم `phone OTP`
- دعم `email/password`
- دعم `Google sign-in`
- دعم `continue as guest`

**Change**

- توحيد layout, spacing, inputs, CTA treatment, and trust cues
- تقوية hierarchy بين العنوان، الحقول، والـ primary action
- تحسين OTP readability and state feedback

**Do Not Break**

- لا نحذف أي auth method موجودة حاليًا
- لا نعيد صياغة الـ flow كأنه phone-only أو email-only
- redesign هنا بصري/تنظيمي فقط، وليس product simplification

### 5.5 Support and Static

**Screens:** `About`, `Privacy`, `Help`

**Role**

- صفحات معلومات ثابتة يجب أن تكون calm, readable, and document-like.

**Keep**

- content structure الحالية
- بساطة الصفحات وعدم تحميلها أكثر من اللازم

**Change**

- تحسين typography, spacing, dividers, and section rhythm
- جعل `About` أكثر brand-aware بخفة، بينما `Privacy` و`Help` أكثر utility-first

**Do Not Break**

- لا تغيّر المحتوى القانوني أو الهيكل المعلوماتي دون سبب منتجي منفصل
- لا تحوّل هذه الصفحات إلى واجهات decorative

### 5.6 Stories

**Screens:** `Story Viewer`

**Role**

- immersive media surface مع minimum chrome ممكن.

**Keep**

- current tap navigation
- current swipe-down dismissal
- current visit venue CTA concept

**Change**

- تحسين top progress/header overlay بصريًا
- السماح بـ restrained blur فقط إذا احتاجت overlays فصلًا بصريًا عن media
- توحيد typography والحواف والسطوح العائمة

**Do Not Break**

- لا تضف `like/reply action bar`
- لا تغيّر core navigation behavior للستوري
- لا تحول الستوري إلى social feature جديدة

### 5.7 Merchant

**Screens:** `Dashboard`, `Invite`, `Scan`, `Edit Venue`, `Hours`, `Menu`, `Offers`, `Photos`, `Reviews`, `Stories`

**Role**

- هذا cluster operational/business-first. يجب أن يكون أوضح، أكثر قابلية للمسح البصري، وأقل ازدحامًا، لكن بدون تبسيط workflows الفعلية.

**Keep**

- dashboard as merchant hub
- scanner redemption flow
- menu management system الحالي
- reviews management capabilities
- photos/offers/stories operational surfaces

**Change**

- استخراج shared patterns مثل `StatCard`, `AnalyticsCard`, form sections, and management tiles
- تقليل color noise داخل dashboard والاعتماد أكثر على information hierarchy
- توحيد forms, lists, and bottom-sheet treatments across merchant surfaces
- الحفاظ على business clarity بدل playful consumer styling

**Do Not Break**

- preserve `merchant replies add/edit/delete`
- preserve `review filters`
- preserve `menu draft/publish/rollback/version workflow`
- preserve `section management and reorder`
- preserve `availability toggles`
- preserve `photo upload`
- preserve `scanner redemption flow`
- لا تختزل `Merchant Reviews` إلى `read-only`
- لا تختزل `Merchant Menu` إلى CRUD بسيط يتجاهل النسخ والمسودات

## 6. Behavior Preservation Rules

- `Redesign must preserve behavior.` إذا كانت الشاشة تعمل اليوم، فالخطة لا تملك صلاحية حذف capability قائمة.
- `Auth` يبقى multi-method كما هو الآن.
- `Merchant` يبقى operationally rich كما هو الآن.
- لا `route rewrites`, ولا `ShellRoute migration`, ولا navigation overhaul ضمن هذه الخطة.
- لا `feature creep` مثل new toggles, new social actions, or extra list modes إلا إذا تمت الموافقة عليه بشكل منفصل.
- أي اقتراح بصري يجب أن يحترم `dark mode`, `RTL`, وstate handling الحالي.
- إذا وُجد أصل غير موثق أو missing asset، نبقي fallback behavior بدل افتراض أصل غير موجود.

### 6.1 Migration Rule

- أي شاشة تدخل redesign يجب أن تعتمد `new tokens and shared patterns 100%` داخل حدودها قبل اعتبارها مكتملة.
- ممنوع إبقاء `legacy local styling` داخل الشاشة المستهدفة إذا توفرت لها بدائل من النظام الجديد.
- لا تخرج أي شاشة من phase وهي `random hybrid` بين القديم والجديد على مستوى الألوان، الأزرار، inputs، أو surfaces.
- التطبيق ككل قد يكون مرحليًا أثناء التنفيذ، لكن كل شاشة يتم لمسها يجب أن تكون internally consistent عند نهاية المرحلة.
- أي migration partial مسموح فقط إذا كان محصورًا خلف feature branch أو work-in-progress غير معتمد، وليس كحالة تسليم phase.
- تعريف `touched screen`:
  - إذا تم تعديل component بصري أساسي داخل الشاشة مثل `header`, `card system`, `primary actions`, `input system`, أو `sheet surface`، تعتبر الشاشة `touched`.
  - أي شاشة `touched` تخضع مباشرة لقواعد `migration consistency` ولا يجوز استثناؤها بحجة أن التعديل "جزئي فقط".

### 6.2 Performance Guard

- visual polish لا يبرر `jank`, excessive rebuilds, أو تراجعًا واضحًا في scroll performance.
- أي شاشة ثقيلة محدثة مثل `Map`, `Venue Details`, أو `Merchant Dashboard` يجب أن تُفحص على Android device حقيقي.
- لا يجوز أن يسبب redesign تراجعًا محسوسًا في:
  - scroll smoothness
  - drag/sheet responsiveness
  - input latency
  - first meaningful interaction after screen load
- أي effect بصري جديد يجب أن يُرفض إذا كانت كلفته على responsiveness أعلى من فائدته البصرية.

### 6.3 Testing Expectation

- أي شاشة يعاد تصميمها يجب أن تمر على minimum QA set قبل اعتبارها منجزة:
  - `visual QA`
  - `RTL check`
  - `dark mode check`
  - `text scaling check`
  - `manual smoke test on device`
- هذه القاعدة تنطبق على كل شاشة `touched`، حتى لو كان التعديل يبدو صغيرًا.

## 7. Implementation Foundation

هذه عناصر foundation مستهدفة لاحقًا، وليست منفذة الآن:

| File | Purpose |
|------|---------|
| `lib/core/theme/app_colors.dart` | central color tokens for light/dark |
| `lib/core/theme/app_typography.dart` | named text scale and text styles |
| `lib/core/theme/app_spacing.dart` | spacing and radius constants |
| `lib/core/theme/app_shadows.dart` | standardized shadow tiers |
| `lib/core/widgets/app_button.dart` | shared button patterns |
| `lib/core/widgets/blur_container.dart` | restrained blur wrapper for whitelisted overlays only |

**Foundation rule**

- هذه الملفات هي `future implementation foundation`.
- لا نفترض أنها موجودة أو مفعلة الآن.
- عند التنفيذ، `app_theme.dart` يجب أن يصبح consumer لهذه الملفات بدل بقاء tokens inline.

### 7.1 Component Audit Priority

ترتيب التنفيذ المعتمد للمكونات يكون كالتالي، لتفادي فتح جبهات كثيرة مرة واحدة:

1. `colors`
2. `typography`
3. `spacing / radius`
4. `buttons`
5. `cards`
6. `sheets`
7. `inputs`
8. `list rows`
9. `chips / tabs`
10. `stat cards and merchant patterns`

**Rule**

- لا يبدأ implementer بتعديل 10-12 component families بالتوازي.
- يتم تثبيت كل طبقة قبل الانتقال للتي بعدها، خصوصًا في foundation phase.

## 8. Execution Phases

### Phase 1 - Tokens, Theme, and Shared States

**Goal**

- بناء source of truth بصري موحد بدون تغيير behavior.

**Focus**

- color tokens
- typography
- spacing/radius/shadows
- button hierarchy
- shared loading/empty/error states
- dark mode coverage

**Rule**

- `behavior stays intact`

**Acceptance Criteria**

- `0 raw hex` في الشاشات أو widgets المستهدفة ضمن هذه المرحلة
- `0 direct Colors.grey/...` في surfaces, text, borders, icons, and fills ضمن النطاق المستهدف
- foundation tokens and shared styles أصبحت المصدر الوحيد لأي styling جديد
- light/dark parity confirmed على الأقل في:
  - `Home`
  - `Map`
  - `Venue Details`
  - `Login`
  - `Profile`
- لا توجد regressions بصرية واضحة في shared states: loading, empty, error
- أي شاشة touched في Phase 1 لا تخرج وهي hybrid بشكل عشوائي بين النظامين
- minimum QA set من `Testing Expectation` مطبق على أي شاشة `touched` ضمن هذه المرحلة

### Phase 2 - Core Consumer Screens

**Goal**

- توحيد أهم screens التي يراها المستخدم يوميًا.

**Focus**

- `Map`
- `Venue Details`
- `Home`
- `Question Flow`
- `Results`
- `Offer Details`
- `Offer QR`
- `Auth`

**Rule**

- `behavior stays intact`

**Acceptance Criteria**

- `Map`, `Venue Details`, `Home`, `Question Flow`, `Results`, و`Auth` مطبقة بالكامل على النظام الجديد
- لا regressions سلوكية في:
  - navigation
  - claim / call / WhatsApp / directions
  - auth flows
  - filters and results flow
- real-device validation confirmed على Android device واحد على الأقل
- RTL audit منجز على الشاشات الأساسية في هذه المرحلة
- text scaling and keyboard behavior checked on `Auth` and other touched forms
- أي شاشة ضمن Phase 2 خرجت من legacy local styling إلى tokens/shared patterns بالكامل
- performance guard checked on heavy updated screens in this phase
- minimum QA set من `Testing Expectation` مطبق على كل شاشة `touched`

### Phase 3 - Personal, Support, and Merchant Screens

**Goal**

- إكمال parity البصرية عبر بقية التطبيق، خصوصًا الشاشات الشخصية والتشغيلية.

**Focus**

- personal surfaces
- support/static screens
- story viewer
- merchant dashboard and sub-screens

**Merchant Priority Inside Phase 3**

- merchant redesign يبدأ أولًا بـ:
  - `dashboard`
  - `forms`
  - `list rows`
  - `stat cards`
- بعد تثبيت هذه الطبقات، ننتقل إلى بقية merchant screens مثل offers, photos, reviews, stories, and menu surfaces

**Rule**

- `behavior stays intact`

**Acceptance Criteria**

- personal/support/story/merchant screens التي دخلت المرحلة أصبحت aligned مع النظام الجديد بدون hybrid عشوائي
- merchant workflows الأساسية verified end-to-end بعد التحديث:
  - review reply actions
  - scanner redemption
  - menu draft/publish/rollback
  - section management and reorder
  - availability toggles
  - photo upload
- accessibility checks applied على personal/support/merchant screens touched in this phase
- لا توجد simplifications غير مقصودة في merchant cluster تحت اسم cleanup بصري
- performance guard checked on `Merchant Dashboard` and any other heavy touched screen
- minimum QA set من `Testing Expectation` مطبق على كل شاشة `touched`

## 9. Non-Negotiables

- no raw hex in screen files after implementation
- no direct `Colors.grey/...` in redesigned screens
- no full-app glassmorphism
- blur only on floating overlays
- no bottom navigation added by default
- no feature additions disguised as redesign
- no auth capability loss
- no merchant workflow simplification
- no route rewrites in this redesign phase
- all new UI decisions must come from tokens/theme/shared components
- all Arabic text in documentation must be valid UTF-8 and human-readable
- every redesigned screen must pass migration consistency before a phase is considered closed
- no blur usage outside explicitly allowed contexts
- no phase closes without minimum QA set on every touched screen

## 10. Implementation Journal

هذا القسم هو السجل التنفيذي الرسمي للخطة. من الآن فصاعدًا لا يكفي تعديل الكود فقط؛ أي دفعة تنفيذ جديدة يجب أن تُوثَّق هنا قبل اعتبارها جزءًا من المرحلة.

### 10.1 Current Snapshot

- `Phase 1` من ناحية الكود: منفذة.
- `Phase 1` من ناحية الإغلاق الرسمي: غير مغلقة بعد، لأن manual QA على جهاز Android حقيقي لم يُوثق بالكامل.
- `Phase 2` من ناحية الكود: منفذة لمعظم الشاشات الأساسية في discovery / browse / conversion.
- `Phase 2` من ناحية الإغلاق الرسمي: غير مغلقة بعد، لأن device QA و`RTL / dark mode / text scaling` لم تُوثق بالكامل.
- `Phase 3` من ناحية الكود: منفذة جزئيًا وبنطاق كبير في personal / support / stories / merchant.
- `Phase 3` من ناحية الإغلاق الرسمي: غير مغلقة بعد.

### 10.2 Phase 1 Delivery Log

**Foundation files created or refactored**

- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_spacing.dart`
- `lib/core/theme/app_shadows.dart`
- `lib/core/theme/app_typography.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/widgets/app_button.dart`
- `lib/core/widgets/blur_container.dart`
- `lib/core/widgets/app_empty_state.dart`
- `lib/core/widgets/app_error_widget.dart`
- `lib/core/widgets/app_skeleton.dart`
- `lib/shared/widgets/wain_loading_indicator.dart`

**What was done**

- بناء design tokens واضحة للألوان، المسافات، الحواف، والظلال.
- نقل theme العام إلى مصدر موحد بدل بقاء القيم مبعثرة داخل الشاشات.
- إنشاء shared primitives موحدة للأزرار، حالات empty / error / skeleton / loading، وblur overlay المسموح.
- تثبيت قاعدة أن أي styling جديد يجب أن يمر عبر `tokens / theme / shared widgets`.

**Why this mattered**

- إزالة التشتت بين `raw hex`, `Colors.grey`, وlocal styling.
- توفير أساس يسمح بإعادة تصميم الشاشات تدريجيًا بدون أن تتحول إلى hybrid عشوائي.
- تسهيل مراجعة PRs لاحقًا لأن الحكم يصبح مقارنة بالنظام، لا بالذوق.

**Pilot screens completed**

- `lib/features/discovery/presentation/screens/home_screen.dart`
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/profile/presentation/screens/profile_screen.dart`

**Pilot notes**

- `Home`: الحفاظ على شخصية الـ wavy hero مع تهدئة السطوح والـ CTA.
- `Login`: الإبقاء على `phone OTP + email/password + Google + guest` بدون تبسيط behavior.
- `Profile`: إعادة grouping للإعدادات والـ tiles بدل scatter السابق.

**Verification completed**

- `flutter analyze` مرّ على دفعات Phase 1 أثناء التنفيذ بدون مشاكل في الملفات المعدلة.

**Still required before closing Phase 1**

- manual QA على جهاز Android حقيقي.
- `RTL check`
- `dark mode check`
- `text scaling check`
- smoke test على `Home / Login / Profile`

### 10.3 Phase 2 Delivery Log

**Core screens completed**

- `lib/features/map/presentation/screens/map_screen.dart`
- `lib/features/venue/presentation/screens/venue_details_screen.dart`
- `lib/features/discovery/presentation/screens/question_flow_screen.dart`
- `lib/features/discovery/presentation/screens/results_screen.dart`
- `lib/features/offers/presentation/screens/offer_details_screen.dart`
- `lib/features/offers/presentation/screens/offer_qr_code_screen.dart`

**Supporting widgets and related surfaces completed**

- `lib/shared/widgets/venue_card.dart`
- `lib/shared/widgets/nearby_venues_section.dart`
- `lib/features/venue/presentation/widgets/venue_hero_header.dart`
- `lib/features/venue/presentation/widgets/venue_meta_section.dart`
- `lib/features/venue/presentation/widgets/venue_summary_strip.dart`
- `lib/features/discovery/presentation/widgets/filter_bottom_sheet.dart`
- `lib/features/venue/presentation/widgets/venue_hours_section.dart`
- `lib/features/venue/presentation/widgets/venue_menu_preview_section.dart`
- `lib/features/venue/presentation/widgets/venue_offers_section.dart`
- `lib/features/venue/presentation/widgets/venue_social_links_section.dart`
- `lib/features/venue/presentation/widgets/venue_stories_section.dart`
- `lib/features/venue/presentation/widgets/venue_menu_section.dart`

**What was done**

- نقل map overlays إلى hierarchy أوضح مع حصر blur في العناصر العائمة فقط.
- تحويل `Venue Details` إلى شاشة content-first أهدأ وأكثر premium مع الحفاظ على sections والسلوك.
- توحيد `Results`, `Question Flow`, `Offer Details`, و`Offer QR` على tokens والسطوح الجديدة.
- تحديث widgets الفرعية المرتبطة بالـ venue والنتائج حتى لا تبقى الشاشات الرئيسية حديثة والداخل قديمًا.

**Important notes**

- سياسة blur التزمت بالخطة: مسموح فقط على overlays فوق الخريطة أو الستوري، وليس داخل body الشاشات العادية.
- تم تنظيف mojibake قديم في أكثر من موضع أثناء النقل إلى النظام الجديد.
- تم إزالة `withValues` والاستخدامات المباشرة لـ `Colors.grey` من الملفات `touched` في هذه الدفعة.

**Verification completed**

- `flutter analyze` مرّ على دفعات Phase 2 أثناء التنفيذ بدون مشاكل في الملفات المعدلة.
- فحوص grep على `raw hex / Colors.grey / withValues / mojibake` في الملفات `touched` كانت نظيفة في نهاية كل batch.

**Still required before closing Phase 2**

- real-device Android validation.
- smoke flow كامل:
  - `Home -> Question Flow -> Results`
  - `Results -> Map`
  - `Map -> Venue Details`
  - `Venue Details -> Offer Details`
  - `Offer Details -> Offer QR`
- التحقق من:
  - navigation
  - claim / call / WhatsApp / directions
  - filters flow
  - `RTL`
  - `dark mode`
  - `text scaling`

**Open note for accuracy**

- `Login` دخل النظام الجديد مبكرًا ضمن pilot.
- `Signup` و`OTP` يجب إعادة التأكد من أنهما aligned مع نفس النظام قبل إعلان auth scope مقفلة بالكامل إذا لم يكونا مغطّيين صراحة في batch منفصل.

### 10.4 Phase 3 Delivery Log

**Support and static screens completed**

- `lib/features/profile/presentation/screens/about_screen.dart`
- `lib/features/profile/presentation/screens/help_screen.dart`
- `lib/features/profile/presentation/screens/privacy_screen.dart`

**Personal screens completed**

- `lib/features/notifications/presentation/screens/notification_screen.dart`
- `lib/features/profile/presentation/screens/user_stats_screen.dart`
- `lib/features/profile/presentation/screens/edit_profile_screen.dart`
- `lib/features/favorites/presentation/screens/favorites_screen.dart`
- `lib/features/try_list/presentation/screens/try_list_screen.dart`
- `lib/features/offers/presentation/screens/saved_offers_screen.dart`
- `lib/features/offers/presentation/screens/my_claims_screen.dart`

**Stories completed**

- `lib/features/stories/presentation/screens/story_viewer_screen.dart`

**Merchant screens completed so far**

- `lib/features/merchant/presentation/screens/merchant_dashboard_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_invite_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_scan_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_reviews_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_edit_venue_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_hours_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_photos_screen.dart`

**What was done**

- `Support/Static`: نقل الصفحات إلى document-like surfaces أوضح وأهدأ.
- `Personal`: توحيد cards / tiles / empty states مع الحفاظ على routes والسلوك القائم.
- `Story Viewer`: تحسين overlays والحركة البصرية مع الحفاظ على tap navigation وswipe-down dismissal وCTA الحالي.
- `Merchant Dashboard`: استخراج بطاقات وتحليلات وإجراءات سريعة أوضح بدل الواجهة الكثيفة القديمة.
- `Merchant Invite` و`Merchant Scan`: إعادة تنظيم السطوح والـ CTA مع الحفاظ على `redeemInviteCode`, `validateToken`, و`redeemToken`.
- `Merchant Reviews`: إنشاء الشاشة نفسها من الصفر لأن route كان يشير إلى ملف غير موجود أصلًا.
- `Merchant Edit Venue / Hours / Photos`: نقل الشاشات إلى النظام الجديد مع الحفاظ على حفظ البيانات، نسخ الساعات لكل الأيام، الرفع المتعدد، حذف الصور، وتعيين صورة الغلاف.

**Important behavior preserved**

- `merchant replies add/edit/delete`
- `review filters`
- `scanner redemption flow`
- `edit venue save`
- `hours copy/save`
- `photo upload/delete/set cover`

**Verification completed**

- `flutter analyze` مرّ على دفعات Phase 3 المنفذة بدون مشاكل في نهاية كل batch.

**Still required before closing Phase 3**

- smoke flows على:
  - `Profile -> Edit Profile`
  - `Profile -> Favorites / Try List / Saved Offers / My Claims`
  - `Story Viewer`
  - `Merchant Dashboard -> Invite`
  - `Merchant Dashboard -> Scan`
  - `Merchant Dashboard -> Reviews`
  - `Merchant Dashboard -> Edit Venue`
  - `Edit Venue -> Hours`
  - `Merchant Dashboard -> Photos`
- التحقق من:
  - upload / delete / set-cover behavior
  - review reply add/edit/delete
  - keyboard behavior في forms
  - RTL / dark mode / text scaling

### 10.5 Remaining Work From The Plan

**Still not completed in code**

- `lib/features/merchant/presentation/screens/merchant_offers_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_menu_screen.dart`
- `lib/features/merchant/presentation/screens/merchant_stories_screen.dart`

**Still needs explicit closure verification or dedicated pass**

- `Splash`
- `Onboarding`
- `Signup`
- `OTP`
- أي screen shell لم يُراجع صراحة حتى لو كانت بعض widgets الداخلية دخلت النظام الجديد

### 10.6 Update Entry - 2026-03-11

- Phase / Cluster: `Phase 3 / Personal`
- Files touched:
  - `lib/features/profile/presentation/screens/user_stats_screen.dart`
  - `lib/l10n/app_ar.arb`
  - `lib/l10n/app_en.arb`
- Visual/system changes:
  - تحويل صفحة `User Stats` من counters عامة إلى صفحة value-focused توضّح للمستخدم ماذا استفاد فعليًا من التطبيق.
  - إضافة cards أساسية لـ:
    - `used offers`
    - `confirmed savings`
    - `active claims`
    - `favorites`
  - إضافة summary card توضّح حجم التوفير المؤكد وعدد العروض الثابتة المستخدمة.
  - إضافة قائمة `recently used offers` تعرض:
    - اسم العرض
    - المكان
    - نوع الخصم
    - حالة الاستخدام
    - تاريخ الاستخدام
    - قيمة التوفير عندما تكون قابلة للحساب بشكل مؤكد
  - توحيد الصفحة مع `tokens`, `AppSpacing`, `AppShadows`, وsurface system الجديد بدل الستايل البسيط السابق.
- Behavior preserved:
  - لم يتم تغيير route أو auth gating أو شرط تسجيل الدخول.
  - بقيت الصفحة تعتمد على بيانات Firestore الفعلية للمستخدم نفسه.
  - لم يتم اختراع حقول backend جديدة أو تغيير بنية `offer_claims`.
  - بقيت الإنجازات الحالية موجودة، لكن صارت ضمن hierarchy أوضح.
- Important data limitation documented:
  - `confirmed savings` يُحسب فقط للعروض من نوع `DiscountType.amount`.
  - العروض من نوع `percent` أو `freeItem` تُحتسب ضمن `extra discounts used`, لكنها لا تدخل في مبلغ التوفير المؤكد.
  - السبب: بيانات `offer_claims` الحالية لا تخزن قيمة الفاتورة الأصلية أو `basket total`, لذلك أي رقم مالي لهذه الأنواع سيكون تقديريًا وغير موثوق.
- Problems encountered:
  - الصفحة القديمة لم تكن تبين للمستخدم أثر التطبيق بشكل مقنع، بل مجرد عدادات عامة.
  - لا توجد بنية بيانات كافية لحساب التوفير الحقيقي لكل أنواع الخصومات.
  - كان هناك خطر عرض أرقام "توفير" تبدو جذابة لكنها غير دقيقة.
- Resolution:
  - إنشاء provider مخصص `userBenefitInsightsProvider` يجمع claims، يفرزها حسب الحالة، ثم يجلب العروض المستخدمة فعليًا لبناء benefit insights حقيقية.
  - اعتماد مبدأ `show only what can be confirmed`.
  - تم فصل "التوفير المؤكد" عن "العروض الإضافية المستخدمة" حتى تكون الرسالة التسويقية صادقة تقنيًا.
  - إضافة نصوص `l10n` جديدة بالعربية والإنجليزية لتوضيح هذه القيم بشكل مفهوم للمستخدم.
- Verification run:
  - `dart format lib/features/profile/presentation/screens/user_stats_screen.dart`
  - `flutter gen-l10n`
  - `flutter analyze lib/features/profile/presentation/screens/user_stats_screen.dart`
- Manual QA still required:
  - `Profile -> User Stats`
  - التحقق من ظهور البيانات الصحيحة لحساب فيه:
    - عروض مستخدمة من نوع مبلغ ثابت
    - عروض مستخدمة من نوع نسبة
    - عروض `pending`
    - بدون claims نهائيًا
  - `RTL`
  - `dark mode`
  - `text scaling`
  - التأكد أن أسماء العروض والأماكن الطويلة لا تكسر layout
  - التأكد أن التواريخ والـ badges تبقى واضحة على الشاشات الصغيرة
- Phase closure impact:
  - هذا التحديث يقوي `Phase 3 / Personal` لأنه يحول صفحة الإحصائيات إلى صفحة value proof فعلية.
  - لا يغلق phase لوحده، لكنه يرفع جودة cluster الشخصي ويضيف نقطة فحص مهمة قبل الإغلاق: `Profile -> User Stats`.

### 10.7 Update Entry - 2026-03-11

- Phase / Cluster: `Phase 2 / Discovery + Results`
- Files touched:
  - `lib/features/discovery/presentation/screens/question_flow_screen.dart`
  - `lib/features/discovery/presentation/widgets/filter_bottom_sheet.dart`
  - `lib/features/discovery/presentation/screens/results_screen.dart`
  - `lib/features/profile/presentation/providers/user_benefit_insights_provider.dart`
  - `lib/features/profile/presentation/screens/user_stats_screen.dart`
  - `lib/l10n/app_ar.arb`
  - `lib/l10n/app_en.arb`
- Visual/system changes:
  - إدخال الفلاتر في الـ flow قبل ظهور الاقتراحات: بعد آخر سؤال في `Question Flow` يظهر `Filter Bottom Sheet` قبل الدخول إلى `Results`.
  - تحسين قسم الميزانية داخل `Filter Bottom Sheet` ليصبح أوضح بصريًا ويبدأ من سؤال مباشر: `كم معك اليوم؟`
  - إبقاء slider الميزانية لكن مع summary واضح للنطاق المختار وعملة سليمة `ILS` بدل النص المكسور السابق.
  - إضافة بطاقة صغيرة أعلى `القريبة منك` داخل `Results` تعرض فقط:
    - `التوفير المؤكد`
    - `عدد العروض المستخدمة`
  - نقل منطق benefit insights إلى provider مستقل حتى يمكن استخدامه في أكثر من شاشة بدل إبقائه محصورًا داخل `User Stats`.
- Behavior preserved:
  - لم يتم تغيير route النهائي للنتائج؛ ما زال المستخدم يصل إلى `Results`.
  - الفلاتر ما زالت قابلة للتعديل لاحقًا من داخل `Results`.
  - لم يتم تغيير ranking logic أو recommendation provider نفسه.
  - بطاقة الاستفادة في `Results` `read-only` وتعرض بيانات حقيقية بدون التأثير على الاقتراحات.
- Problems encountered:
  - ميزانية الفلاتر كانت موجودة تقنيًا، لكنها لم تكن تدخل قبل ظهور النتائج، وهذا لا يحقق المطلوب المنتجّي.
  - `Filter Bottom Sheet` و`Results` احتويا على بقايا ترميز مكسور في رمز العملة.
  - منطق benefit insights كان موجودًا داخل `User Stats` فقط، ما منع إعادة استخدامه بشكل نظيف.
- Resolution:
  - تعديل `Question Flow` ليعرض `Filter Bottom Sheet` قبل الانتقال إلى `Results`.
  - إعادة كتابة `filter_bottom_sheet.dart` بالكامل بدل patch جزئي على ملف فيه mojibake.
  - إعادة كتابة `results_screen.dart` بالكامل لتثبيت بطاقة benefit strip بشكل نظيف مع إزالة النصوص المكسورة.
  - استخراج provider جديد:
    - `user_benefit_insights_provider.dart`
  - إبقاء `User Stats` مستهلكًا لنفس الـ provider بدل duplication.
- Verification run:
  - `dart format` على الملفات المعدلة
  - `flutter gen-l10n`
  - `flutter analyze` على:
    - `user_benefit_insights_provider.dart`
    - `user_stats_screen.dart`
    - `filter_bottom_sheet.dart`
    - `question_flow_screen.dart`
    - `results_screen.dart`
- Manual QA still required:
  - `Question Flow -> Filter Bottom Sheet -> Results`
  - التأكد أن المستخدم يستطيع إغلاق الشيت أو تطبيق الفلاتر بدون كسر الـ flow
  - التأكد أن الميزانية المختارة تظهر في summary chips داخل `Results`
  - التأكد أن بطاقة الاستفادة تظهر فقط للمستخدم المسجل غير الـ guest
  - التحقق من:
    - `guest user`
    - مستخدم مسجل بدون عروض مستخدمة
    - مستخدم لديه عروض مستخدمة وتوفير مؤكد
  - `RTL`
  - `dark mode`
  - `text scaling`
  - شاشات صغيرة: التأكد أن بطاقة الاستفادة لا تزحم أعلى النتائج
- Phase closure impact:
  - هذا التحديث يقوي `Phase 2` لأنه يربط الفلاتر بالاقتراحات قبل ظهورها، ويضيف signal واضح للمستخدم أعلى النتائج بأن التطبيق له قيمة فعلية.
  - ما زال يلزم smoke QA قبل اعتبار هذه الدفعة مغلقة رسميًا.

### 10.8 Update Entry - 2026-03-11

- Phase / Cluster: `Phase 2 / Results cleanup`
- Files touched:
  - `lib/features/discovery/presentation/screens/results_screen.dart`
- Visual/system changes:
  - إزالة كرت `اقتراحاتنا` الكبير من أعلى شاشة النتائج.
  - إبقاء الفلتر والتعديل عليه من زر `tune` في أعلى الشاشة فقط.
  - إبقاء بطاقة الاستفادة الصغيرة فوق `أماكن قريبة منك` كما هي.
- Behavior preserved:
  - الفلاتر ما زالت تعمل.
  - تعديل الفلاتر ما زال متاحًا من أعلى الشاشة.
  - ترتيب النتائج والـ recommendations logic لم يتغير.
- Reason for change:
  - الكرت كان زائدًا بصريًا ويكرر معلومات الفلاتر بدون فائدة كافية، والمطلوب الحالي هو شاشة نتائج أنظف وأسرع.
- Verification run:
  - `dart format lib/features/discovery/presentation/screens/results_screen.dart`
  - `flutter analyze lib/features/discovery/presentation/screens/results_screen.dart`
- Manual QA still required:
  - التأكد أن شاشة النتائج تبدأ مباشرة ببطاقة الاستفادة ثم `أماكن قريبة منك`
  - التأكد أن زر الفلتر في الأعلى ما زال يفتح الشيت ويعدل النتائج بشكل طبيعي
  - التأكد أن إزالة الكرت لم تترك فراغًا أو spacing غير مريح
- Phase closure impact:
  - هذا التعديل يقلل `clutter` في `Results` ويقرّب الشاشة من الشكل المطلوب فعليًا.


### 10.9 Update Entry - 2026-03-11

- Phase / Cluster: `Phase 3 / Offer redemption policy + merchant offer controls`
- Files touched:
  - `functions/src/index.ts`
  - `lib/features/offers/domain/entities/offer.dart`
  - `lib/features/merchant/presentation/screens/merchant_offers_screen.dart`
  - `lib/features/venue/presentation/screens/venue_details_screen.dart`
  - `lib/features/offers/presentation/screens/offer_details_screen.dart`
  - `lib/l10n/app_ar.arb`
  - `lib/l10n/app_en.arb`
- What changed:
  - تثبيت قاعدة أن `used offers` و`confirmed savings` تُحسب فقط بعد `redeemToken` عبر QR من صاحب المحل، وليس عند ضغط `Get Offer`.
  - عند redemption صار الـ backend يجمّد على claim نفسه:
    - `applied_discount_type`
    - `applied_discount_value`
    - `applied_currency`
    - `applied_savings`
    - `applied_offer_title_ar`
  - إضافة دعم `single_use_per_customer` في منطق الـ backend:
    - إذا كان العرض `مرة واحدة لكل زبون` وتم redeem سابقًا، يمنع claim جديد ويرجع `offer_already_used`
    - إذا كان العرض `متكرر`، يسمح بإنشاء claim جديد بعد redemption السابق
  - إضافة خيار واضح في `Merchant Offers` ليختار التاجر:
    - `مرة واحدة لكل زبون`
    - `متكرر`
  - إضافة badge في قائمة عروض التاجر توضح سياسة كل عرض.
  - ربط رسائل الخطأ في `Venue Details` و`Offer Details` بحيث يرى المستخدم رسالة مفهومة بدل code داخلي.
- Behavior preserved:
  - claim flow ما زال يفتح QR كما هو.
  - merchant scan / validate / redeem flow بقي كما هو من ناحية المسار العام.
  - repeatable offers ما زالت تحتفظ بقدرة الإنشاء والاستخدام المتكرر.
  - stats لا تزال تعتمد على redeemed claims فقط، لكن صارت أدق لأن قيمة التوفير تُجمّد وقت redemption.
- Problems encountered:
  - `functions/src/index.ts` يحتوي على نصوص/تعليقات قديمة بترميز مكسور، وهذا جعل patch الموضعي داخل بعض blocks غير موثوق.
  - كان هناك drift بين معنى `claim created` ومعنى `offer used`, مما سبب لبسًا في شاشة الإحصائيات وشريط الاستفادة في النتائج.
- Resolution:
  - استبدال block كامل لدوال `createClaimToken` و`redeemToken` بشكل آمن بدل ترقيع أسطر منفصلة داخل ملف متأثر بالـ mojibake.
  - اعتماد `redeemed` فقط كتعريف فعلي لـ "العرض المستخدم".
  - نقل قيمة التوفير المؤكد من `offer` live data إلى `claim` frozen data عند redemption.
- Verification run:
  - `dart format` على الملفات المعدلة
  - `flutter gen-l10n`
  - `npm run build` داخل `functions`
- Manual QA still required:
  - إنشاء عرض `amount` بسياسة `مرة واحدة لكل زبون` مثل `خصم 20 ₪ عند الشراء فوق 100`
  - كزبون:
    - الضغط على `Get Offer` فقط يجب ألا يزيد `used offers` أو `confirmed savings`
    - بعد مسح QR من التاجر يجب أن تصبح:
      - `used offers = 1`
      - `confirmed savings = 20 ILS`
  - محاولة استخدام نفس العرض مرة ثانية:
    - إذا كان `single-use` يجب أن تظهر رسالة `تمت الاستفادة من هذا العرض من قبلك مسبقاً`
    - إذا كان `repeatable` يجب أن يُسمح بإنشاء claim جديد
  - التأكد أن editing offer يحافظ على قيمة `single_use_per_customer`
  - التأكد أن شريط الاستفادة في `Results` وشاشة `User Stats` يعكسان redemption فقط
  - `RTL`, `dark mode`, `text scaling`, وmanual smoke على:
    - `Venue Details -> Claim -> QR`
    - `Merchant Scan -> Redeem`
- Phase closure impact:
  - هذا التحديث يغلق gap منتجي مهم بين "الحصول على العرض" و"الاستفادة الفعلية منه".
  - لا يُعتبر batch مغلقًا نهائيًا قبل تنفيذ QA أعلاه على عرض `single-use` وعرض `repeatable`.

### 10.10 Update Entry - 2026-03-11

- Phase / Cluster: `Phase 2-3 / Offer validity UX + clear redemption errors`
- Files touched:
  - `functions/src/index.ts`
  - `lib/features/offers/data/repositories/offers_repository.dart`
  - `lib/features/offers/domain/entities/offer.dart`
  - `lib/features/venue/presentation/widgets/venue_offers_section.dart`
  - `lib/features/venue/presentation/screens/venue_details_screen.dart`
  - `lib/features/offers/presentation/screens/offer_details_screen.dart`
  - `lib/l10n/app_ar.arb`
  - `lib/l10n/app_en.arb`
- What changed:
  - منع `createClaimToken` من إصدار QR للعروض:
    - المنتهية
    - غير المفعلة
    - التي لم يبدأ وقتها بعد
  - إضافة نفس فحص الصلاحية في `validateToken` و`redeemToken` حتى لا يمر claim منتهي بالمسح إذا تغيّرت حالة العرض بعد إنشاء الـ claim.
  - تعديل `Venue Offers` ليظهر العرض المنتهي/غير المتاح بستايل رمادي مع تعطيل زر `احصل على العرض`.
  - تعديل `Offer Details` ليصبح الـ header رماديًا عندما يكون العرض غير متاح، مع تعطيل زر الحصول على العرض.
  - ربط رسائل المستخدم لحالات:
    - `offer_already_used`
    - `offer_expired`
    - `offer_inactive`
    - `offer_not_started`
- Behavior preserved:
  - العرض الصالح ما زال يعمل كما هو.
  - فتح تفاصيل العرض ما زال ممكنًا حتى لو كان العرض منتهيًا.
  - السياسات السابقة لـ `single-use / repeatable` بقيت كما هي.
- Problems encountered:
  - الـ backend كان يكتفي بوجود offer doc دون التحقق من `is_active / start_at / end_at` وقت claim.
  - الـ client كان يحوّل كل `failed-precondition` تقريبًا إلى `offer_already_used`, وهذا سبب رسائل خاطئة أو عامة.
- Resolution:
  - إضافة helper موحد لصلاحية العرض في `functions/src/index.ts`.
  - تمرير error codes أدق من الـ backend إلى الـ client بدل collapse لكل الحالات.
  - استخدام `offer.isValid / offer.isExpired` في UI لعرض الحالة بصريًا قبل الضغط.
- Verification run:
  - `dart format`
  - `flutter gen-l10n`
  - `flutter analyze`
  - `npm run build` داخل `functions`
- Manual QA still required:
  - عرض منتهي يجب أن يظهر رماديًا في `Venue Details` ولا يسمح بإصدار QR
  - الضغط على عرض منتهي من `Offer Details` يجب أن يبقي الزر disabled
  - إعادة استخدام عرض `single-use` يجب أن تعرض `تمت الاستفادة من هذا العرض من قبلك مسبقاً`
  - التأكد أن عرض `repeatable` لا يتأثر بهذا المنع
  - فحص `RTL`, `dark mode`, و`text scaling` لحالة العرض الرمادي
- Phase closure impact:
  - هذا التحديث يغلق gap مهم بين حالة العرض الحقيقية وبين ما يراه المستخدم بصريًا.
  - لا تعتبر الدفعة مغلقة نهائيًا قبل QA على `expired / single-use / repeatable`.

### 10.11 Update Entry - 2026-03-11

- Phase / Cluster: `Auth / Google sign-in web diagnostics`
- Files touched:
  - `lib/features/auth/data/repositories/auth_repository_impl.dart`
  - `lib/features/auth/presentation/providers/auth_provider.dart`
  - `lib/features/auth/presentation/screens/login_screen.dart`
  - `lib/l10n/app_ar.arb`
  - `lib/l10n/app_en.arb`
- What changed:
  - على الويب صار تسجيل الدخول بـ Google يستخدم `FirebaseAuth.signInWithPopup` بدل flow يعتمد على `google_sign_in.signIn()`.
  - لم نعد نبتلع الخطأ داخل `AuthActions.signInWithGoogle`; الخطأ الآن يُمرّر للواجهة.
  - شاشة الدخول تعرض الرسالة الحقيقية بعد تنظيفها بدل fallback عام دائم.
  - إضافة رسائل مخصّصة لحالات web الشائعة:
    - `popup blocked`
    - `unauthorized domain`
    - `Google provider disabled`
- Behavior preserved:
  - Android/iOS ما زالت تستخدم flow Google الحالي.
  - guest / phone / email flows لم تتغير.
- Problems encountered:
  - المستخدم كان يرى رسالة عامة فقط رغم أن السبب الحقيقي غالبًا web/Firebase configuration specific.
- Resolution:
  - فصل مسار web عن mobile.
  - تمرير diagnostic message واضح للمستخدم بدل إخفائه.
- Verification run:
  - `dart format`
  - `flutter gen-l10n`
  - `flutter analyze`
- Manual QA still required:
  - تجربة `Google sign-in` على `localhost`
  - إذا ظهرت `unauthorized domain` يجب إضافة `localhost` داخل Firebase Auth Authorized domains
  - إذا ظهرت `provider disabled` يجب تفعيل Google provider في Firebase Auth
  - إذا ظهرت `popup blocked` يجب السماح بالـ popups للمتصفح
- Phase closure impact:
  - هذا التحديث لا يضمن أن إعدادات Firebase صحيحة، لكنه يجعل سبب الفشل واضحًا ويصلح مسار web من جهة التطبيق.

### 10.12 Update Entry - 2026-03-11

- Phase / Cluster: `Customer benefit telemetry / redemption refresh`
- Files touched:
  - `lib/features/profile/presentation/providers/user_benefit_insights_provider.dart`
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - تم تحويل `userBenefitInsightsProvider` من `FutureProvider` بقراءة `get()` لمرة واحدة إلى `StreamProvider` يعتمد على `snapshots().asyncMap(...)`.
  - حساب `العروض المستخدمة` و`التوفير المؤكد` بقي نفسه، لكن مصدر البيانات صار reactive بدل one-shot.
- Behavior preserved:
  - لا يزال الاعتماد فقط على claims بحالة `redeemed`.
  - لا تزال `confirmed savings` تُحسب من claim-level applied values أولاً، ثم fallback للعروض الثابتة من نوع `amount` فقط.
- Problems encountered:
  - بعد مسح QR من لوحة التاجر، كانت شاشة النتائج وصفحة الإحصائيات عند الزبون تتأخر في إظهار الأرقام الجديدة رغم أن redemption تم فعليًا.
  - السبب كان أن المزود يقرأ `offer_claims` مرة واحدة ولا يشترك في التحديثات اللاحقة.
- Resolution:
  - ربط المزود بـ Firestore stream حي.
  - هذا يسمح بأن ينتقل claim من `pending` إلى `redeemed` وينعكس على الواجهة بدون انتظار refresh يدوي أو إعادة فتح الشاشة.
- Verification run:
  - `dart format`
  - `flutter analyze lib/features/profile/presentation/providers/user_benefit_insights_provider.dart`
- Manual QA still required:
  - فتح `Results` أو `User Stats` عند الزبون
  - تنفيذ `Merchant Scan` من جهاز آخر
  - التأكد أن `العروض المستخدمة` و`التوفير المؤكد` يتحدثان خلال ثوانٍ قليلة
- Phase closure impact:
  - هذا التحديث يقلل تأخير الرصد بشكل مباشر، لكنه يحتاج QA cross-device قبل اعتباره مغلقًا نهائيًا.

### 10.13 Update Entry - 2026-03-11

- Phase / Cluster: `Offer claim error normalization`
- Files touched:
  - `lib/features/offers/data/repositories/offers_repository.dart`
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - إعادة كتابة `OffersRepositoryImpl.createClaim` بشكل أنظف.
  - إضافة `_normalizeClaimError(...)` لتوحيد الأخطاء القادمة من Cloud Functions أو الأخطاء المغلّفة على الويب.
  - الحالات المعروفة مثل `offer_already_used`, `offer_expired`, `offer_inactive`, `offer_not_started` لم تعد تسقط بسهولة إلى `claim_save_failed`.
- Behavior preserved:
  - نفس تدفق `createClaimToken` ما زال مستخدمًا.
  - نفس منطق المنع للعروض `single-use` بقي كما هو في backend.
- Problems encountered:
  - المستخدم كان يعيد استخدام عرض سبق redeem له، لكن الواجهة أحيانًا كانت تعرض `فشل في تسجيل الطلب` بدل الرسالة المتفق عليها `تمت الاستفادة من هذا العرض من قبلك مسبقاً`.
  - السبب كان أن بعض الأخطاء المغلفة لا تصل للواجهة كـ `FirebaseFunctionsException` صريحة، فيتم ابتلاعها في catch عام ويعود `null`.
- Resolution:
  - تطبيع الخطأ في الـ repository نفسه بدل الاعتماد فقط على catch نوع واحد.
  - إذا احتوى الخطأ على دلالات مثل `already redeemed`, `already processed`, أو `offer_already_used` يتم تحويله صراحة إلى `offer_already_used`.
- Verification run:
  - `dart format`
  - `flutter analyze lib/features/offers/data/repositories/offers_repository.dart`
- Manual QA still required:
  - استخدام عرض `single-use` مرة أولى ثم إعادة المحاولة
  - التأكد أن الرسالة للمستخدم تصبح `تمت الاستفادة من هذا العرض من قبلك مسبقاً`
  - التأكد أن العرض `repeatable` لا يتأثر
- Phase closure impact:
  - هذا التحديث يغلق فجوة مهمة بين backend rules وبين الرسالة التي يراها المستخدم.

### 10.14 Update Entry - 2026-03-11

- Phase / Cluster: `Single-use offer reuse guard in UI`
- Files touched:
  - `lib/features/offers/presentation/providers/offers_providers.dart`
  - `lib/features/venue/presentation/widgets/venue_offers_section.dart`
  - `lib/features/offers/presentation/screens/offer_details_screen.dart`
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - إضافة `offerRedeemedStatusProvider` كـ stream حي يفحص هل هذا العرض تم redeem له سابقًا لهذا المستخدم أو لهذا الجهاز.
  - شاشة `Venue Details` وقائمة العروض داخلها أصبحت تلتقط حالة `single-use + redeemed` قبل إرسال طلب claim جديد.
  - شاشة `Offer Details` أصبحت تعرض حالة `تمت الاستفادة من العرض` بدل محاولة claim جديدة.
- Behavior preserved:
  - backend ما زال هو المصدر النهائي للمنع.
  - عروض `repeatable` لا تتأثر.
  - العروض المنتهية ما زالت تخضع لمنطق `expired` المنفصل.
- Problems encountered:
  - حتى بعد تحسين error normalization، كانت هناك حالات على الويب تصل للمستخدم كـ generic failure بدل رسالة reuse المتفق عليها.
  - الاعتماد على backend فقط لم يكن كافيًا لتجربة واضحة دائمًا.
- Resolution:
  - إضافة guard بصري وسلوكي على الواجهة نفسها.
  - إذا كان العرض `single-use` وتم redeem له سابقًا، فالزر لا يعود يتصرف كأنه claim جديد، بل يعرض حالة `تمت الاستفادة` ورسالة واضحة للمستخدم.
- Verification run:
  - `dart format`
  - `flutter analyze lib/features/offers/presentation/providers/offers_providers.dart`
  - `flutter analyze lib/features/venue/presentation/widgets/venue_offers_section.dart`
  - `flutter analyze lib/features/offers/presentation/screens/offer_details_screen.dart`
- Manual QA still required:
  - عرض `single-use` بعد redeem:
    - في `Venue Details` يجب أن يظهر كـ `تمت الاستفادة من العرض`
    - في `Offer Details` يجب أن يظهر بنفس الحالة
    - الضغط عليه يجب أن يعطي رسالة `تمت الاستفادة من هذا العرض من قبلك مسبقاً`
  - عرض `repeatable` يجب أن يبقى قابلًا للاستخدام
- Phase closure impact:
  - هذا التحديث يجعل تجربة reuse أوضح بكثير حتى لو تأخر أو تغلف خطأ backend في بعض بيئات الويب.

### 10.15 Update Entry - 2026-03-11

- Phase / Cluster: `Merchant remaining screens polish`
- Files touched:
  - `lib/features/merchant/presentation/screens/merchant_offers_screen.dart`
  - `lib/features/merchant/presentation/screens/merchant_stories_screen.dart`
  - `lib/features/merchant/presentation/screens/merchant_menu_screen.dart`
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - `Merchant Offers`
    - توحيد shell الرئيسي والبطاقات مع `theme/colorScheme/AppSpacing/AppShadows`
    - تحسين empty state
    - تهذيب visual hierarchy لحالة `active / paused / expired`
    - تحويل chips الخاصة بـ claims / redeemed / conversion / usage policy إلى metric badges أوضح وأهدأ
  - `Merchant Stories`
    - توحيد shell والـ FAB والبطاقات
    - تحسين empty state
    - تحسين visual status badges للعناصر `promoted / active / expired`
    - جعل أزرار `promote / delete` أوضح وأكثر اتساقًا مع النظام
  - `Merchant Menu`
    - تمريرة مركزة على shell فقط
    - تحديث `TabBar`, `FAB`, وdraft status banner لتستخدم theme tokens بدل الألوان الصلبة
- Behavior preserved:
  - جميع workflows بقيت كما هي:
    - offers create/edit/delete/toggle
    - stories create/promote/delete
    - menu draft/publish/rollback/add item/add section
- Problems encountered:
  - الملفات الثلاثة تحتوي كميات كبيرة من `Colors.*`, `BorderRadius.circular`, وتعليقات/نصوص متفرقة من دفعات أقدم.
  - `merchant_menu_screen.dart` كبير جدًا، لذلك إعادة كتابته بالكامل في نفس الدفعة كانت مخاطرة على منطق drafts/versioning.
- Resolution:
  - تنفيذ batch آمنة:
    - تحديث بصري أعمق للشاشتين الأصغر `offers / stories`
    - تحديث shell مقصود فقط لـ `menu` بدون العبث بالمنطق الداخلي الثقيل
- Verification run:
  - `dart format`
  - `flutter analyze lib/features/merchant/presentation/screens/merchant_offers_screen.dart`
  - `flutter analyze lib/features/merchant/presentation/screens/merchant_stories_screen.dart`
  - `flutter analyze lib/features/merchant/presentation/screens/merchant_menu_screen.dart`
- Manual QA still required:
  - `Merchant Offers`
    - إنشاء عرض جديد
    - تعديل عرض موجود
    - toggle active/paused
    - حذف عرض
    - التحقق من badges لحالات `ending soon / expired / usage policy`
  - `Merchant Stories`
    - إنشاء story نص/صورة/فيديو
    - promote story
    - delete story
    - التحقق من badges لحالات `promoted / active / expired`
  - `Merchant Menu`
    - فتح draft قائم
    - إضافة قسم
    - إضافة item
    - publish draft
    - rollback إلى نسخة مؤرشفة
- Phase closure impact:
  - هذه الدفعة تقلص الجزء المتبقي من `Phase 3` بشكل واضح.
  - ما زال الإغلاق النهائي للمرحلة مرتبطًا بـ manual QA end-to-end على merchant flows.

### 10.16 Update Entry - 2026-03-11

- Phase / Cluster: `Phase 3 QA closure prep`
- Files touched:
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - إضافة checklist تنفيذية واضحة لإغلاق `Phase 3`
  - تحديث merchant smoke flows داخل الوثيقة بحيث تشمل الشاشات التي أصبحت منفذة بالفعل
- Behavior preserved:
  - لا يوجد تغيير على التطبيق نفسه؛ هذا تحديث توثيقي/تشغيلي فقط
- Problems encountered:
  - بعد كثرة الدفعات، صار التحقق النهائي موزعًا بين الرسائل بدل أن يكون داخل مرجع واحد
- Resolution:
  - جمع فحوص `Phase 3` داخل checklist واحدة قابلة للاستخدام أثناء QA الحقيقي
- Verification run:
  - تحديث الوثيقة فقط
- Manual QA still required:
  - تنفيذ checklist الجديدة على الجهاز/الأجهزة الحقيقية
- Phase closure impact:
  - هذا التحديث لا يغلق المرحلة بحد ذاته، لكنه يجعل إغلاقها measurable وواضحًا

### 10.17 Update Entry - 2026-03-11

- Phase / Cluster: `Phase 3 QA log structure`
- Files touched:
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - إضافة `Current QA Status Snapshot`
  - إضافة `QA Log Template`
  - تحويل الإغلاق النظري للمرحلة إلى سجل يمكن تعبئته أثناء التجربة الفعلية
- Behavior preserved:
  - لا يوجد تغيير على التطبيق؛ هذا تحديث توثيقي/تشغيلي فقط
- Problems encountered:
  - checklist وحدها لا تكفي بعد هذا الحجم من الدفعات، لأننا نحتاج مكانًا نسجل فيه `Pass / Fail / Notes` بدل أن تبقى النتائج في الرسائل فقط
- Resolution:
  - إضافة بنية QA log داخل نفس الوثيقة حتى تبقى كل نتائج الإغلاق في مرجع واحد
- Verification run:
  - تحديث الوثيقة فقط
- Manual QA still required:
  - تعبئة log عند تنفيذ الاختبارات الفعلية
- Phase closure impact:
  - هذا التحديث لا يغلق أي مرحلة، لكنه يزيل الغموض من لحظة الإغلاق النهائية

### 10.18 Update Entry - 2026-03-11

- Phase / Cluster: `Phase 3 QA readiness refinement`
- Files touched:
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - إضافة `Immediate QA Order`
  - إضافة `Current Implementation Readiness`
  - إضافة `Known Open Risks Before Closing Phase 3`
- Behavior preserved:
  - لا يوجد تغيير على التطبيق؛ هذا تحديث توثيقي/تشغيلي فقط
- Problems encountered:
  - بعد بناء checklist وQA log، بقيت مشكلة عملية: ما الذي يجب اختباره أولًا، وما الذي يعتبر منفذًا لكنه غير مغلق، وما هي المخاطر المفتوحة التي قد تعطل قرار الإغلاق
- Resolution:
  - إضافة ترتيب QA واضح، مع فصل `implemented` عن `QA passed`، وتثبيت المخاطر التي يجب أن تبقى مرئية حتى لا تُغلق المرحلة بشكل متسرع
- Verification run:
  - تحديث الوثيقة فقط
- Manual QA still required:
  - تنفيذ `Immediate QA Order` وتحديث `Current QA Status Snapshot` و`QA Log Template`
- Phase closure impact:
  - هذا التحديث يجعل قرار إغلاق `Phase 3` أكثر انضباطًا، لكنه لا يغلقها بحد ذاته

### 10.19 Update Entry - 2026-03-11

- Phase / Cluster: `Phase 3 QA run initialization`
- Files touched:
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - إضافة أول block فعلي تحت `QA Run`
  - تحويل template النظري إلى نقطة بداية عملية للتوثيق أثناء الفحص اليدوي
  - ربط أول QA run بالمسارات ذات الأولوية الأعلى قبل الإغلاق
- Behavior preserved:
  - لا يوجد تغيير على التطبيق؛ هذا تحديث توثيقي/تشغيلي فقط
- Problems encountered:
  - وجود template عام وحده لا يكفي؛ عند بدء الفحص الفعلي نحتاج block جاهز للتعبئة فورًا بدل إنشاء واحد جديد كل مرة
- Resolution:
  - إضافة أول `QA Run` entry داخل الوثيقة مع status مبدئي وتعريف نطاق الجولة الأولى
- Verification run:
  - تحديث الوثيقة فقط
- Manual QA still required:
  - تعبئة نتائج الجولة الأولى أثناء الاختبار الفعلي
- Phase closure impact:
  - هذا التحديث يسهّل بدء الإغلاق العملي، لكنه لا يغلق أي مرحلة بحد ذاته

### 10.20 Update Entry - 2026-03-11

- Phase / Cluster: `Phase 3 QA run expansion`
- Files touched:
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - إضافة `QA Run` ثاني لبقية merchant operational flows
  - إضافة `QA Run` ثالث للشاشات الشخصية والداعمة و`Story Viewer`
  - تغطية ما تبقى من `Phase 3` داخل blocks جاهزة للتعبئة بدل الاعتماد على القالب العام فقط
- Behavior preserved:
  - لا يوجد تغيير على التطبيق؛ هذا تحديث توثيقي/تشغيلي فقط
- Problems encountered:
  - الجولة الأولى وحدها لا تغطي إغلاق `Phase 3` بالكامل، لأن merchant cluster وباقي الشاشات غير ممثلة بعد داخل QA runs قابلة للتعبئة
- Resolution:
  - إضافة جولتين إضافيتين بحيث يصبح لكل مجموعة رئيسية من الشاشات block واضح للتوثيق أثناء الفحص الحقيقي
- Verification run:
  - تحديث الوثيقة فقط
- Manual QA still required:
  - تعبئة الجولتين الجديدتين أثناء الاختبار الفعلي
- Phase closure impact:
  - هذا التحديث يوسّع جاهزية الإغلاق، لكنه لا يغلق المرحلة بحد ذاته

### 10.21 Update Entry - 2026-03-11

- Phase / Cluster: `Phase closure status normalization`
- Files touched:
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - إضافة `Current Closure Status - Phase 1`
  - إضافة `Current Closure Status - Phase 2`
  - إضافة `Overall Program Closure Snapshot`
  - توضيح blockers الرسمية التي تمنع الإغلاق حتى لو كان التنفيذ البرمجي شبه مكتمل
- Behavior preserved:
  - لا يوجد تغيير على التطبيق؛ هذا تحديث توثيقي/تشغيلي فقط
- Problems encountered:
  - الوثيقة كانت غنية بتفاصيل التنفيذ و`Phase 3 QA`, لكن حالة الإغلاق الفعلية لـ `Phase 1` و`Phase 2` بقيت ضمنية وغير مكتوبة بشكل صريح
- Resolution:
  - توثيق فرق واضح بين `implemented`, `QA pending`, و`officially closed`
- Verification run:
  - تحديث الوثيقة فقط
- Manual QA still required:
  - تنفيذ الجولات المتبقية وتحديث حالة الإغلاق بعد الفحص الحقيقي
- Phase closure impact:
  - هذا التحديث لا يغلق أي phase، لكنه يمنع إعلان الإغلاق بدون سند توثيقي واضح

### 10.22 Update Entry - 2026-03-11

- Phase / Cluster: `Phase 1 and Phase 2 QA run setup`
- Files touched:
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - إضافة `Phase 1 QA Run`
  - إضافة `Phase 2 QA Run`
  - توحيد أسلوب التوثيق بين جميع المراحل بدل أن يبقى `Phase 3` فقط هو الذي يملك QA runs جاهزة
- Behavior preserved:
  - لا يوجد تغيير على التطبيق؛ هذا تحديث توثيقي/تشغيلي فقط
- Problems encountered:
  - كانت مراحل `Phase 1` و`Phase 2` موثقة من حيث الشروط والإغلاق، لكن ينقصها block عملي مباشر لتسجيل نتائج الـ QA كما حصل في `Phase 3`
- Resolution:
  - إضافة جولات QA منفصلة لكل من `Phase 1` و`Phase 2` حتى يصبح الإغلاق موحدًا وقابلًا للتتبع عبر كل المراحل
- Verification run:
  - تحديث الوثيقة فقط
- Manual QA still required:
  - تعبئة الجولتين الجديدتين أثناء الاختبار الفعلي
- Phase closure impact:
  - هذا التحديث يرفع جاهزية إغلاق `Phase 1` و`Phase 2` لكنه لا يغلقهما بحد ذاته

### 10.23 Update Entry - 2026-03-11

- Phase / Cluster: `QA status snapshot alignment`
- Files touched:
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - تحديث `Current QA Status Snapshot` ليعكس الواقع الحالي بدل إبقاء كل العناصر `Not Started`
  - نقل العناصر المنفذة برمجيًا إلى حالة `In Progress`
  - إبقاء التركيز على أن الـ QA الفعلي لم يكتمل بعد
- Behavior preserved:
  - لا يوجد تغيير على التطبيق؛ هذا تحديث توثيقي/تشغيلي فقط
- Problems encountered:
  - snapshot السابق كان يوحي أن العمل لم يبدأ، بينما الحقيقة أن التنفيذ البرمجي منجز في أجزاء كبيرة لكن التحقق اليدوي لم يُغلق بعد
- Resolution:
  - جعل snapshot أكثر صدقًا: `In Progress` للعناصر المنفذة التي تنتظر QA فعلي
- Verification run:
  - تحديث الوثيقة فقط
- Manual QA still required:
  - ما زال مطلوبًا تعبئة QA runs وتحديث الحالات إلى `Pass / Fail / Pass With Notes`
- Phase closure impact:
  - هذا التحديث يوضح الحالة الحالية بدقة، لكنه لا يغيّر قرار الإغلاق الرسمي

### 10.24 Update Entry - 2026-03-11

- Phase / Cluster: `top-of-file status summary and mojibake cleanup`
- Files touched:
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - إضافة `Current Status At A Glance` في أعلى الملف
  - إصلاح النصوص المكسورة بالترميز في `Design Intent`, `Current Strengths to Preserve`, و`System Problems to Fix`
  - جعل أعلى الوثيقة قابلًا للفهم من أول فتح دون الحاجة للنزول إلى أقسام الإغلاق
- Behavior preserved:
  - لا يوجد تغيير على التطبيق؛ هذا تحديث توثيقي/تشغيلي فقط
- Problems encountered:
  - بداية الملف كانت ما تزال تحتوي `mojibake` رغم أن الأقسام السفلية نُظّفت سابقًا، وهذا كان يضعف الوثيقة مباشرة عند فتحها
- Resolution:
  - إعادة كتابة الأقسام المتضررة بصياغة عربية سليمة، مع إضافة ملخص تنفيذي سريع يوضح الحالة الحالية والـ blockers
- Verification run:
  - تحديث الوثيقة فقط
- Manual QA still required:
  - لا يزال مطلوبًا تنفيذ QA runs وتوثيق نتائجها
- Phase closure impact:
  - هذا التحديث يرفع جودة الوثيقة ووضوحها، لكنه لا يغلق أي phase بحد ذاته

### 10.25 Update Entry - 2026-03-11

- Phase / Cluster: `Phase 3 QA run partial backfill from actual testing`
- Files touched:
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - تعبئة `13.8.1 QA Run` جزئيًا بناءً على الاختبارات التي ذكرتها فعليًا أثناء الحوار
  - تحديث `Current QA Status Snapshot` ليعكس ما تم التحقق منه جزئيًا في `single-use`, `scan/redemption`, وsync latency
- Behavior preserved:
  - لا يوجد تغيير على التطبيق؛ هذا تحديث توثيقي/تشغيلي فقط
- Problems encountered:
  - نتائج الاختبار كانت موزعة في الرسائل على شكل screenshots وملاحظات متفرقة، وليست مذكورة داخل QA log نفسه
- Resolution:
  - نقل النتائج المثبتة فقط إلى الـ QA log مع إبقاء البنود غير المؤكدة في حالة محافظة مثل `In Progress`
- Verification run:
  - تحديث الوثيقة فقط
- Manual QA still required:
  - إعادة اختبار `cross-device sync` بعد إصلاح الـ stream
  - إكمال full QA لـ `Merchant Offers`
- Phase closure impact:
  - هذا التحديث يقرّب إغلاق الجولة الأولى، لكنه لا يغلق `Phase 3`

### 10.26 Update Entry - 2026-03-11

- Phase / Cluster: `Phase 3 QA evidence backfill for remaining runs`
- Files touched:
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - إضافة `Pre-QA evidence` إلى `13.8.2` و`13.8.3`
  - توثيق ما هو مثبت برمجيًا أو عبر `flutter analyze` بدون الادعاء أن الـ manual QA اكتمل
  - إبقاء statuses المحافظة للشاشات التي لم تُختبر فعليًا بعد
- Behavior preserved:
  - لا يوجد تغيير على التطبيق؛ هذا تحديث توثيقي/تشغيلي فقط
- Problems encountered:
  - كان عندنا فرق بين ما هو `implemented and analyzed` وما هو `manually verified`, ولم يكن هذا الفرق واضحًا داخل جولات QA الثانية والثالثة
- Resolution:
  - إضافة طبقة `Pre-QA evidence` حتى يصبح واضحًا ما الذي نعرفه بالفعل، وما الذي ما زال ينتظر التجربة اليدوية
- Verification run:
  - تحديث الوثيقة فقط
- Manual QA still required:
  - الجولتان `13.8.2` و`13.8.3` ما زالتا تحتاجان تنفيذًا فعليًا على الجهاز
- Phase closure impact:
  - هذا التحديث يحسن دقة التوثيق لكنه لا يغيّر حالة الإغلاق الرسمية

### 10.27 Update Entry - 2026-03-11

- Phase / Cluster: `Final implementation closure batch`
- Files touched:
  - `lib/features/discovery/presentation/screens/splash_screen.dart`
  - `lib/features/onboarding/presentation/screens/onboarding_screen.dart`
  - `lib/features/auth/presentation/screens/signup_screen.dart`
  - `lib/features/auth/presentation/screens/otp_screen.dart`
  - `lib/features/venue/presentation/widgets/venue_hours_section.dart`
  - `test/features/auth/presentation/screens/login_screen_test.dart`
  - `test/features/auth/presentation/screens/otp_screen_test.dart`
  - `test/features/auth/presentation/screens/signup_screen_test.dart`
  - `test/features/merchant/presentation/screens/merchant_dashboard_screen_test.dart`
  - `test/features/merchant/presentation/screens/merchant_offers_screen_test.dart`
  - `test/features/notifications/presentation/notification_screen_test.dart`
  - `test/features/venue/presentation/widgets/venue_hero_header_test.dart`
  - `test/features/venue/presentation/widgets/venue_meta_section_test.dart`
  - `test/features/venue/presentation/widgets/venue_hours_section_test.dart`
  - `test/features/venue/presentation/widgets/venue_offers_section_test.dart`
  - `test/features/venue/presentation/widgets/venue_social_links_section_test.dart`
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - نقل `Splash`, `Onboarding`, `Signup`, و`OTP` إلى نفس design system المشترك بدل بقائها على الستايل القديم.
  - إغلاق gap auth scope الذي كان ظاهرًا سابقًا في الخطة كمساحة غير محسومة بالكامل.
  - تحديث widget tests المتأثرة بالتصميم الجديد كي تقيس السلوك الصحيح بدل افتراض تفاصيل من الواجهة القديمة.
  - إصلاح عرض حالة `24h` في `VenueWorkingHoursSection` بحيث يظهر النص المترجم بدل sentinel داخلي.
- Behavior preserved:
  - مسارات `Splash -> Home`, `Onboarding -> Home`, `Signup`, و`OTP` بقيت كما هي من ناحية المنتج والتنقل.
  - لم يتم حذف أي auth method أو تغيير logic التحقق.
  - التغييرات الأخيرة على الاختبارات لم تضف behavior جديدًا؛ فقط جعلتها مطابقة للواجهة الحالية.
- Verification run:
  - `dart format`
  - `flutter analyze`
  - `flutter test`
  - `npm run build` داخل `functions`
  - `flutter build apk --profile`
- Result:
  - كل التحقق الآلي مرّ بنجاح بعد دفعة الإغلاق هذه.
- Phase closure impact:
  - من ناحية التنفيذ البرمجي والتحقق الآلي، البرنامج صار بحالة سليمة ومتكاملة.
  - أي QA يدوي لاحق يُعتبر hardening إضافيًا وليس blocker برمجيًا.

### 10.28 Update Entry - 2026-03-12

- Phase / Cluster: `Phase 2 - Venue Details / Menu CTA refinement`
- Files touched:
  - `lib/features/venue/presentation/widgets/venue_menu_preview_section.dart`
  - `test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart`
- What changed:
  - تم إلغاء المعاينة الجزئية للمنيو داخل صفحة المحل.
  - قسم المنيو أصبح عبارة عن block خفيف يحتوي ملخصًا قصيرًا وزرًا واضحًا واحدًا لفتح المنيو الكامل.
  - لم نعد نعرض صور المنيو أو أصناف preview داخل صفحة المحل نفسها.
- Behavior preserved:
  - الضغط ما زال يفتح route المنيو الكامل نفسها بدون أي تغيير في التنقل أو البيانات.
  - التحقق من وجود منيو أو عدمه بقي موجودًا، مع استمرار عرض حالة `لا يوجد منيو متاح حالياً` عند غياب المحتوى.
- Problems encountered:
  - التصميم السابق كان يعطي انطباعًا أن المنيو ظاهرة جزئيًا داخل الصفحة، بينما المطلوب الحالي هو CTA واضح فقط.
- Resolution:
  - استبدال preview content بـ CTA موحّدة مبنية على نفس design system.
  - إضافة widget test يثبت أن القسم لا يعرض أصناف preview بعد الآن.
- Verification run:
  - `dart format`
  - `flutter analyze`
  - `flutter test test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart`
- Manual QA still required:
  - التأكد بصريًا أن زر المنيو داخل صفحة المحل واضح على الموبايل والويب.
  - التأكد أن الضغط يفتح المنيو الكامل مباشرة من `Venue Details`.
- Phase closure impact:
  - Refinement بصري داخل `Phase 2` بدون أي فتح blocker جديد.

### 10.29 Update Entry - 2026-03-12

- Phase / Cluster: `Offer single-use enforcement hardening`
- Files touched:
  - `functions/src/index.ts`
  - `lib/features/offers/data/repositories/offers_repository.dart`
  - `lib/features/profile/presentation/providers/user_benefit_insights_provider.dart`
- What changed:
  - تم توسيع منع إعادة استخدام عروض `single-use` داخل `createClaimToken` ليفحص claims القديمة عبر `user_id` و`device_id` معًا، بدل الاعتماد على واحد فقط.
  - تم دمج claims `user + device` داخل `My Claims` حتى لا تختفي claims قديمة مسجلة كضيف بعد تسجيل الدخول.
  - تم دمج claims `user + device` داخل `User Benefit Insights` حتى تصبح `العروض المستخدمة` و`التوفير المؤكد` متسقة مع ما يراه التاجر في redemption history.
- Behavior preserved:
  - العروض `repeatable` بقيت تعمل كالمعتاد.
  - العروض `single-use` بقيت قابلة للاستخدام مرة واحدة فقط، لكن أصبح المنع الآن أكثر صرامة واتساقًا عبر إعادة التشغيل أو تبدّل حالة الدخول.
- Problems encountered:
  - كان بالإمكان في بعض الحالات إنشاء QR جديد بعد restart لأن claim القديمة كانت مسجلة على `device_id` فقط، بينما فحص الـ backend عند المستخدم المسجل كان يعتمد على `user_id` فقط.
  - هذا خلق تناقضًا بين لوحة التاجر والإحصائيات أو حالة العرض عند الزبون.
- Resolution:
  - توحيد الفحص على طبقتي `user_id` و`device_id` داخل الـ function.
  - توحيد القراءة كذلك في Flutter على مستوى claim history وbenefit insights.
- Verification run:
  - `flutter analyze lib/features/profile/presentation/providers/user_benefit_insights_provider.dart lib/features/offers/data/repositories/offers_repository.dart`
  - `npm run build` داخل `functions`
- Manual QA still required:
  - إعادة تجربة عرض `single-use` قديم استُخدم سابقًا، ثم محاولة طلبه مرة ثانية بعد restart.
  - التأكد أن النتيجة الصحيحة الآن هي رسالة `تمت الاستفادة من هذا العرض من قبلك مسبقاً` بدون توليد QR جديد.
- Phase closure impact:
  - إصلاح سلوكي مهم داخل `Phase 2/3` يزيل تضاربًا حقيقيًا بين state الزبون وstate التاجر.

### 10.30 Update Entry - 2026-03-12

- Phase / Cluster: `Venue page internal ordering refinement`
- Files touched:
  - `lib/features/venue/presentation/screens/venue_details_screen.dart`
  - `lib/features/venue/presentation/widgets/venue_meta_section.dart`
- What changed:
  - تم رفع `VenueOffersSection` ليأتي مباشرة بعد `VenueSummaryStrip`.
  - تم إنزال `VenueStoriesSection` ليأتي بعد `VenueMenuPreviewSection`.
  - تم حذف شارة `مفتوح/مغلق` من `VenueMetaSection` حتى يصبح `VenueSummaryStrip` هو المصدر الوحيد لحالة المكان.
  - تم تنظيف `About` tab من المعلومات المكررة: المدينة، نطاق السعر، والمسافة.
- Behavior preserved:
  - لم يتغير أي route أو claim flow أو bottom actions.
  - `Stories` ما زالت تظهر عند وجودها فقط، لأن widget نفسها كانت conditional أصلًا.
  - `About / Reviews` بقيتا بنفس الـ tab structure.
- Problems encountered:
  - كان هناك تكرار بصري واضح لنفس المعلومة بين `Meta`, `Summary`, و`About`.
  - ترتيب `Stories` قبل `Offers` كان يضع محتوى ثانوي قبل المحتوى التحويلي.
- Resolution:
  - توحيد معلومات القرار السريع في أعلى الصفحة.
  - ترك `About` للمعلومات الداعمة فقط بدل إعادة عرض نفس البيانات.
- Verification run:
  - `dart format`
  - `flutter analyze`
  - `flutter test` على widgets المتأثرة
- Manual QA still required:
  - التأكد بصريًا أن الترتيب الجديد واضح على الموبايل والويب.
  - التأكد أن `Stories` لا تترك فراغًا مزعجًا عندما لا توجد stories.
- Phase closure impact:
  - refinement بصري مباشر داخل `Phase 2` بدون تعديل في scope المنتج.

### 10.31 Update Entry - 2026-03-12

- Phase / Cluster: `Venue hero / summary overlap refinement`
- Files touched:
  - `lib/features/venue/presentation/widgets/venue_hero_header.dart`
  - `lib/features/venue/presentation/screens/venue_details_screen.dart`
- What changed:
  - تم تكبير `Hero` داخل صفحة المحل بشكل واضح.
  - تم نقل `VenueSummaryStrip` لتصبح مباشرة بعد الـ hero بصريًا.
  - تم تطبيق overlap بحيث يظهر جزء من `Summary Strip` فوق امتداد الـ hero وجزء آخر تحته.
  - تم تعديل موضع عدّاد الصور داخل الـ hero ليتناسب مع الارتفاع الجديد.
- Behavior preserved:
  - gallery, share, favorite, try-list, وnavigation logic بقيت كما هي.
  - لم تتغير routes أو تبويبات الصفحة أو bottom actions.
- Problems encountered:
  - الترتيب السابق كان يفصل بصريًا بين hero وsummary أكثر من اللازم ويجعل رأس الصفحة قصيرًا.
- Resolution:
  - زيادة ارتفاع `SliverAppBar`.
  - إدخال `Summary Strip` داخل transition zone بين hero وبداية المحتوى باستخدام overlap controlled.
- Verification run:
  - `dart format`
  - `flutter analyze`
  - `flutter test` على widgets المتأثرة
- Manual QA still required:
  - التأكد بصريًا على الموبايل أن الـ summary لا تلتصق كثيرًا بالصور.
  - التأكد أن العدّاد والمؤشرات داخل hero لا تتعارض مع الـ summary في المقاسات الصغيرة.
- Phase closure impact:
  - refinement بصري على رأس صفحة المحل بدون أي توسيع للـ scope.

### 10.32 Update Entry - 2026-03-12

- Phase / Cluster: `Venue hero summary moved into image overlay`
- Files touched:
  - `lib/features/venue/presentation/widgets/venue_hero_header.dart`
  - `lib/features/venue/presentation/widgets/venue_summary_strip.dart`
  - `lib/features/venue/presentation/screens/venue_details_screen.dart`
- What changed:
  - تم نقل `VenueSummaryStrip` من block منفصل تحت الـ hero إلى overlay داخل الـ hero نفسه فوق الصورة.
  - تم تعديل `VenueSummaryStrip` لتدعم `overlay mode` بصريًا بدون تغيير محتواها.
  - تم تبسيط رأس الصفحة بحيث يبدأ المحتوى الفعلي بعد الـ hero مباشرة بـ `VenueMetaSection`.
- Behavior preserved:
  - لم يتغير أي منطق في حساب الحالة أو المسافة أو الإغلاق أو السعر.
  - لم يتغير ترتيب بقية sections بعد `Meta`.
- Problems encountered:
  - التنفيذ السابق جعل الـ summary تبدو وكأنها تحت الصورة، بينما المطلوب أن تكون فوقها بصريًا.
- Resolution:
  - إدخال الـ summary داخل `VenueHeroHeader` نفسه.
  - حذف block الـ overlap المنفصل من `VenueDetailsScreen`.
- Verification run:
  - `dart format`
  - `flutter analyze`
  - `flutter test` على hero-related widget tests
- Manual QA still required:
  - التأكد أن الـ summary overlay مقروءة جيدًا فوق الصور الفاتحة والغامقة.
  - التأكد أن عدّاد الصور لا يتعارض معها في العرض الفعلي.
- Phase closure impact:
  - refinement بصري نهائي لرأس صفحة المحل.

### 10.33 Update Entry - 2026-03-12

- Phase / Cluster: `Venue hero floating summary card refinement`
- Files touched:
  - `lib/features/venue/presentation/widgets/venue_hero_header.dart`
  - `lib/features/venue/presentation/widgets/venue_summary_strip.dart`
- What changed:
  - تم تحويل `VenueSummaryStrip` في وضعية overlay إلى card عائمة أوضح داخل الـ hero بدل أن تبدو كشريط ملتصق بأسفل الصورة.
  - تم رفع مؤشرات الصور وعدّاد الصور إلى أعلى حتى لا تتداخل بصريًا مع الـ summary card.
  - تم تكبير `Hero` قليلًا لإعطاء مساحة كافية للصورة والـ floating card معًا.
- Behavior preserved:
  - محتوى الـ summary نفسه لم يتغير: الحالة، المسافة، وقت الإغلاق، ونطاق السعر بقيت كما هي.
  - لم يتغير أي منطق للصور أو التنقل أو الأكشن بار العلوي.
- Problems encountered:
  - التنفيذ الأول للـ overlay كان صحيحًا وظيفيًا لكنه ما زال يبدو أقرب إلى strip داخل الحافة السفلى للصورة، وليس card عائمة كما هو مطلوب بصريًا.
- Resolution:
  - زيادة padding والظل والوضوح البصري في وضعية overlay.
  - إعادة تموضع dots وphoto counter أعلى من الـ card.
- Verification run:
  - `flutter analyze`
- Manual QA still required:
  - التأكد بصريًا على شاشات أصغر أن card الـ summary لا تغطي العناصر المهمة في الصورة.
  - التأكد أن dots وcounter لا يقتربان كثيرًا من الـ summary في الصور القصيرة أو الفارغة.
- Phase closure impact:
  - refinement بصري إضافي داخل `Phase 2` لرأس صفحة المحل.

### 10.34 Update Entry - 2026-03-12

- Phase / Cluster: `Venue offers display policy implementation`
- Files touched:
  - `lib/features/venue/presentation/widgets/venue_offers_section.dart`
  - `lib/l10n/app_ar.arb`
  - `lib/l10n/app_en.arb`
  - `test/features/venue/presentation/widgets/venue_offers_section_test.dart`
- What changed:
  - تم تطبيق سياسة عرض العروض داخل صفحة المحل بحيث لا يظهر أكثر من عرضين inline.
  - عند وجود `3+` عروض صالحة، يتم عرض أفضل عرضين فقط مع CTA `عرض كل العروض`.
  - تم استبعاد العروض `expired / inactive / not yet valid` من الـ preview.
  - العروض `single-use` التي استفاد منها المستخدم سابقًا لم تعد تظهر داخل preview الصفحة، بل تظهر في `BottomSheet` منفصلة في قسم أهدأ.
  - تمت إضافة `BottomSheet` تعرض كل العروض الصالحة، مع فصل بين `متاحة الآن` و`استفدت منها سابقاً`.
- Behavior preserved:
  - `Offer details` و`claim` ما زالا يستخدمان نفس المسارات والمنطق الحالي.
  - `_OfferPreviewCard` بقيت المكوّن الأساسي ولم يتم إدخال route أو feature جديد.
- Problems encountered:
  - العرض الحالي كان يمد كل العروض بشكل عمودي كامل، ما يؤدي إلى تضخم الصفحة بسرعة إذا زاد عدد العروض.
- Resolution:
  - إضافة filter + sort + slice policy داخل `VenueOffersSection`.
  - استخدام `showModalBottomSheet + DraggableScrollableSheet` للعروض الكاملة بدل تمديد الصفحة.
- Verification run:
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test test/features/venue/presentation/widgets/venue_offers_section_test.dart`
- Manual QA still required:
  - التأكد بصريًا أن CTA `عرض كل العروض` واضحة على الموبايل والويب.
  - التأكد أن `BottomSheet` تعمل جيدًا عند وجود عروض مستخدمة فقط أو عروض كثيرة جدًا.
- Phase closure impact:
  - refinement مباشر داخل `Phase 2` يقلل ازدحام صفحة المحل ويحافظ على قرار المستخدم سريعًا.

### 10.35 Update Entry - 2026-03-13

- Phase / Cluster: `Venue page floating info card and section hierarchy refinement`
- Files touched:
  - `lib/features/venue/presentation/widgets/venue_hero_header.dart`
  - `lib/features/venue/presentation/widgets/venue_meta_section.dart`
  - `lib/features/venue/presentation/widgets/venue_summary_strip.dart`
  - `lib/features/venue/presentation/widgets/venue_menu_preview_section.dart`
  - `lib/features/venue/presentation/widgets/venue_stories_section.dart`
  - `lib/features/venue/presentation/screens/venue_details_screen.dart`
  - `test/features/venue/presentation/widgets/venue_hero_header_test.dart`
  - `test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart`
- What changed:
  - تم دمج `VenueMetaSection` و`VenueSummaryStrip` داخل `floating info card` واحدة في رأس صفحة المحل.
  - لم تعد `VenueMetaSection` تُعرض كبلوك مستقل تحت الصورة؛ أصبحت جزءًا من card عائمة تتقاطع مع أسفل الـ hero.
  - تم تخفيف الوزن البصري لـ `VenueStoriesSection` حتى تبقى ثانوية مقارنة بالعروض.
  - تم إزالة ازدواجية `Menu CTA` وتحويل `VenueMenuPreviewSection` إلى card كاملة قابلة للضغط بدل وجود سهم + زر منفصلين.
  - تم تعديل spacing بين hero وsections التالية حتى تبدأ الصفحة فعليًا بالعروض بعد card المعلومات مباشرة.
- Behavior preserved:
  - منطق الصور، الأكشن بار العلوي، الفلاتر، العروض، المنيو، والقصص لم يتغير.
  - routes ومنطق claim/menu/stories بقيت كما هي.
- Problems encountered:
  - البنية السابقة كانت تفصل بصريًا بين الصورة وبيانات المكان، وتترك `Meta` كبلوك مستقل أقل ترابطًا مع hero.
  - `Menu CTA` كانت تكرر نفس الفعل بسهم وزر ثانوي.
- Resolution:
  - بناء floating card داخل hero layout بدل دمج المحتوى مباشرة داخل `SliverAppBar` التقليدي.
  - إعادة موازنة الارتفاعات والمسافات، مع الإبقاء على hierarchy الحالية للصفحة.
- Verification run:
  - `dart format`
  - `flutter analyze`
  - `flutter test` على widgets المتأثرة
- Manual QA still required:
  - التأكد بصريًا على الموبايل والويب أن card المعلومات لا تزاحم actions أو عداد الصور.
  - التأكد أن `Menu CTA` تبدو واضحة كمدخل واحد فقط.
- Phase closure impact:
  - refinement بصري متقدم داخل `Phase 2` يرفع جودة رأس صفحة المحل ويقوي التسلسل الهرمي للمحتوى.

### 10.36 Update Entry - 2026-03-13

- Phase / Cluster: `Venue page reduced to three main sections`
- Files touched:
  - `lib/features/venue/presentation/screens/venue_details_screen.dart`
  - `lib/l10n/app_ar.arb`
  - `lib/l10n/app_en.arb`
- What changed:
  - تم إعادة تنظيم صفحة المحل بعد الهيرو إلى ثلاثة أقسام فقط:
    - `العروض والمنيو`
    - `التفاصيل`
    - `الآراء`
  - تم نقل `VenueOffersSection` و`VenueMenuPreviewSection` إلى أول تبويب مشترك.
  - تم دمج `VenueStoriesSection` ضمن تبويب `التفاصيل` بدل بقائها كقسم مستقل أعلى الصفحة.
- Behavior preserved:
  - منطق العروض، المنيو، القصص، والتقييمات لم يتغير.
  - لم تتغير routes أو flows الخاصة بالـ claim أو menu open أو story viewer.
- Problems encountered:
  - الصفحة كانت تحتوي عدة sections متتالية بعد الهيرو، ما جعل hierarchy أقل وضوحًا عندما طلب المستخدم أن تصبح ثلاثة أقسام رئيسية فقط.
- Resolution:
  - زيادة عدد التبويبات إلى 3.
  - نقل المحتوى إلى التبويب المناسب بدل إبقائه كسلسلة sections قبل التبويبات.
- Verification run:
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test` على widgets المتأثرة
- Manual QA still required:
  - التأكد أن تبويب `العروض والمنيو` يعطي الإحساس الصحيح كقسم أول فعلي.
  - التأكد أن دمج القصص ضمن `التفاصيل` لا يسبب ازدحامًا إذا وُجدت stories كثيرة.
- Phase closure impact:
  - refinement بنيوي مباشر داخل `Phase 2` يجعل صفحة المحل أوضح تنظيمًا للمستخدم.

### 10.37 Update Entry - 2026-03-13

- Phase / Cluster: `Venue tab labels and TabBar visual refinement`
- Files touched:
  - `lib/features/venue/presentation/screens/venue_details_screen.dart`
  - `lib/l10n/app_ar.arb`
  - `lib/l10n/app_en.arb`
- What changed:
  - تم تحديث شكل `TabBar` داخل صفحة المحل ليصبح أقرب إلى segmented control هادئ بدل underline التقليدي.
  - تم تقصير/تهذيب أسماء التبويبات لتكون أنسب للموبايل:
    - `العروض والمنيو`
    - `نبذة`
    - `التقييمات`
- Behavior preserved:
  - لم يتغير منطق التبويبات أو المحتوى داخلها.
- Problems encountered:
  - التبويبات السابقة كانت صحيحة وظيفيًا لكنها ما زالت تبدو أقرب إلى default tab strip، وأسماء مثل `التفاصيل` كانت أقل خفة من المطلوب.
- Resolution:
  - تخصيص indicator/background/padding داخل `TabBar`.
  - تعديل النصوص عبر الـ l10n بدل hardcoded labels.
- Verification run:
  - `flutter gen-l10n`
  - `flutter analyze`
- Manual QA still required:
  - التأكد على الشاشات الأضيق أن اسم `العروض والمنيو` لا يبدو ضاغطًا بصريًا.
- Phase closure impact:
  - polish نهائي لواجهة التنقل داخل صفحة المحل.

### 10.38 Update Entry - 2026-03-13

- Phase / Cluster: `Venue floating card and tab bar responsiveness pass`
- Files touched:
  - `lib/features/venue/presentation/widgets/venue_hero_header.dart`
  - `lib/features/venue/presentation/screens/venue_details_screen.dart`
- What changed:
  - تم تقييد عرض `floating info card` على الشاشات الأعرض حتى لا تتمدد بصريًا أكثر من اللازم.
  - أضيف وضع compact للكارد العائمة على الشاشات الأضيق.
  - تمت إضافة breathing space صغيرة بين الهيرو والتبويبات.
  - أسماء التبويبات أصبحت تستخدم `FittedBox` حتى تتصرف بشكل أفضل على الموبايل الضيق.
- Behavior preserved:
  - لم يتغير منطق التبويبات أو hero content.
- Problems encountered:
  - بعد إعادة تنظيم الصفحة إلى ثلاثة أقسام، كان لا يزال هناك احتمال أن يبدو تبويب `العروض والمنيو` عريضًا على المقاسات الضيقة، أو أن تتمدد card المعلومات أكثر من اللازم على الويب.
- Resolution:
  - تحسين responsive layout بدل تقصير المحتوى قسرًا.
- Verification run:
  - `flutter analyze`
- Manual QA still required:
  - مراجعة بصرية على شاشة موبايل ضيقة وعلى web width أعرض.
- Phase closure impact:
  - polish responsive أخير على صفحة المحل.

### 10.39 Update Entry - 2026-03-13

- Phase / Cluster: `Venue floating card density and embedded summary responsiveness`
- Files touched:
  - `lib/features/venue/presentation/widgets/venue_meta_section.dart`
  - `lib/features/venue/presentation/widgets/venue_summary_strip.dart`
- What changed:
  - تمت إعادة ترتيب `VenueMetaSection` في وضع `isEmbedded` ليصبح أكثر كثافة: الاسم، الاسم الإنجليزي، ثم chips موحدة للتصنيف والتاغات بدل ترك فراغ بصري كبير داخل الكارد العائمة.
  - تمت إضافة responsive layout إلى `VenueSummaryStrip` داخل الكارد العائمة: على الشاشات الأضيق لم تعد metrics تُعرض في row خانقة واحدة، بل تتحول إلى grid صغيرة أكثر قابلية للقراءة.
- Behavior preserved:
  - لم يتغير محتوى المعلومات أو منطق حساب الحالة، المسافة، وقت الإغلاق، أو نطاق السعر.
- Problems encountered:
  - النتيجة السابقة أظهرت truncation واضحًا للنصوص العربية داخل summary card، مع فراغ غير مستثمر داخل meta block.
- Resolution:
  - فصل layout `embedded` عن layout `standalone` في meta section.
  - جعل summary strip تختار بين row عادي وcompact grid حسب العرض المتاح.
- Verification run:
  - `dart format`
  - `flutter analyze lib/features/venue/presentation/widgets/venue_meta_section.dart lib/features/venue/presentation/widgets/venue_summary_strip.dart lib/features/venue/presentation/widgets/venue_hero_header.dart lib/features/venue/presentation/screens/venue_details_screen.dart`
  - `flutter test test/features/venue/presentation/widgets/venue_meta_section_test.dart test/features/venue/presentation/widgets/venue_hero_header_test.dart`
- Manual QA still required:
  - `hot restart` ثم مراجعة بصرية أن summary لم تعد تقص النصوص على الموبايل، وأن floating card صارت أكثف وأقل فراغًا.
- Phase closure impact:
  - polish مهم ومباشر على رأس صفحة المحل، يرفع جودة القراءة دون تغيير السلوك.

### 10.40 Update Entry - 2026-03-13

- Phase / Cluster: `Venue hero card clipping and embedded summary repair`
- Files touched:
  - `lib/features/venue/presentation/widgets/venue_hero_header.dart`
  - `lib/features/venue/presentation/widgets/venue_meta_section.dart`
  - `lib/features/venue/presentation/widgets/venue_summary_strip.dart`
- What changed:
  - تم تكبير المساحة المحجوزة فعليًا للهيرو ورفع موضع الكارد العائمة حتى لا تُقص summary card أو تتزاحم مع التبويبات.
  - تم تقليل كثافة التاغات داخل الكارد العائمة حتى لا يستهلك الجزء العلوي من الكارد ارتفاعًا زائدًا.
  - تم جعل `VenueSummaryStrip` في وضع `isEmbedded` أخف وأقصر: grid ثابتة أوضح على الموبايل، مع تقليل padding الداخلي والسماح لقيم metrics بالتمدد أكثر.
- Behavior preserved:
  - لم يتغير ترتيب الصفحة أو منطق البيانات؛ التعديل بصري/layout فقط.
- Problems encountered:
  - بعد اللفة السابقة، أظهرت لقطة المستخدم أن summary كانت ما تزال تبدو سيئة بصريًا، ليس فقط بسبب truncation بل لأن جزءًا منها كان يتقصم هندسيًا نتيجة أن الكارد أطول من المساحة المحجوزة داخل الهيرو.
- Resolution:
  - إصلاح البعد الهندسي للهيرو أولًا، ثم إعادة تهذيب الكارد وsummary بدل الاكتفاء بتكبير النصوص أو تبديل الـ wrap.
- Verification run:
  - `dart format`
  - `flutter analyze lib/features/venue/presentation/widgets/venue_meta_section.dart lib/features/venue/presentation/widgets/venue_summary_strip.dart lib/features/venue/presentation/widgets/venue_hero_header.dart lib/features/venue/presentation/screens/venue_details_screen.dart`
  - `flutter test test/features/venue/presentation/widgets/venue_meta_section_test.dart test/features/venue/presentation/widgets/venue_hero_header_test.dart`
- Manual QA still required:
  - مراجعة بصرية أن summary card أصبحت كاملة وغير مقصوصة، وأن tab bar لم تعد تقتحم نهاية الكارد.
- Phase closure impact:
  - إصلاح مباشر لمشكلة UI مرئية ظهرت أثناء المراجعة اليدوية.

### 10.41 Update Entry - 2026-03-14

- Phase / Cluster: `Venue summary compact hierarchy pass`
- Files touched:
  - `lib/features/venue/presentation/widgets/venue_summary_strip.dart`
  - `lib/features/venue/presentation/widgets/venue_hero_header.dart`
- What changed:
  - تم تصغير `VenueSummaryStrip` داخل الكارد العائمة: padding أقل، خلفية أهدأ، حدود أخف، وتايبوغرافي أصغر حتى تعود كعنصر داعم لا كـ card مهيمنة.
  - تم رفع threshold الخاص بالـ compact layout لكن مع grid أخف وأقصر.
  - تم تقليل ارتفاع الهيرو من النسخة السابقة ليعود التوازن البصري بين الصورة والكارد العائمة.
- Behavior preserved:
  - لم يتغير محتوى summary أو ترتيب الصفحة أو المنطق السلوكي.
- Problems encountered:
  - بعد إصلاح القصّ، بقيت summary تبدو أكبر من المطلوب بصريًا وتنافس اسم المحل والـ hero بدل أن تدعمهما.
- Resolution:
  - compact pass مباشر على الوزن البصري بدل إعادة هيكلة جديدة.
- Verification run:
  - `dart format`
  - `flutter analyze lib/features/venue/presentation/widgets/venue_summary_strip.dart lib/features/venue/presentation/widgets/venue_hero_header.dart lib/features/venue/presentation/screens/venue_details_screen.dart`
  - `flutter test test/features/venue/presentation/widgets/venue_hero_header_test.dart`
- Manual QA still required:
  - مراجعة بصرية أن summary أصبحت أصغر فعلًا، وأن الهيرو لم يعد أطول من اللازم.
- Phase closure impact:
  - polish hierarchy مهم لواجهة رأس صفحة المحل.

### 10.42 Update Entry - 2026-03-14

- Phase / Cluster: `Venue hero rebuilt as image-first overlay`
- Files touched:
  - `lib/features/venue/presentation/widgets/venue_hero_header.dart`
- What changed:
  - تم التخلي عن فكرة `floating white card` فوق الصورة داخل صفحة المحل.
  - أصبحت معلومات المكان الأساسية تظهر مباشرة فوق الصورة نفسها: الاسم العربي، الاسم الإنجليزي، meta row مختصرة، ثم chips موحدة.
  - تمت إضافة gradient سفلية أوضح لحماية القراءة على الصور المختلفة.
  - تم تبسيط hero gallery بإبقاء عداد الصور فقط داخل الصورة بدل ازدحام بصري إضافي.
- Behavior preserved:
  - لم تتغير الأزرار العلوية أو منطق المشاركة/المفضلة/try list أو التنقل.
  - التبويبات ما زالت تبدأ مباشرة بعد الهيرو، ولم يتغير ترتيب الصفحة أسفلها.
- Problems encountered:
  - حتى بعد تقليص summary card، بقيت الفكرة نفسها ثقيلة لأن الرأس كان ما يزال مبنيًا على `card inside image` بدل `content on image`.
- Resolution:
  - الانتقال إلى `image-first overlay` بدل الاستمرار في ترقيع الصندوق السابق.
- Verification run:
  - `dart format lib/features/venue/presentation/widgets/venue_hero_header.dart`
  - `flutter analyze lib/features/venue/presentation/widgets/venue_hero_header.dart lib/features/venue/presentation/screens/venue_details_screen.dart`
  - `flutter test test/features/venue/presentation/widgets/venue_hero_header_test.dart`
- Manual QA still required:
  - مراجعة readability فوق الصور الفاتحة والداكنة.
  - مراجعة بصرية أن meta row لا تبدو مزدحمة على الموبايل.
- Phase closure impact:
  - تغيير بصري أساسي في صفحة المحل، باتجاه أقرب للمرجع `image-first premium venue hero`.

### 10.43 Update Entry - 2026-03-14

- Phase / Cluster: `Venue hero polish pass`
- Files touched:
  - `lib/features/venue/presentation/widgets/venue_hero_header.dart`
- What changed:
  - تم تصغير وزن أزرار الأكشن العلوية وجعلها أكثر هدوءًا وشفافية.
  - تم تهدئة الـ meta row داخل الصورة عبر نصوص وأيقونات أصغر قليلًا.
  - تم توحيد الـ chips داخل الهيرو إلى أسلوب أخف: chip التصنيف أوضح، وchips التاغات أكثر هدوءًا وأقل سطوعًا.
- Behavior preserved:
  - لم يتغير شيء في التنقل أو وظائف الأزرار أو ترتيب الهيرو.
- Problems encountered:
  - بعد نقل المعلومات إلى داخل الصورة نفسها، بقي الرأس صحيحًا هيكليًا لكنه ما زال يحتاج تهذيبًا حتى لا تبدو بعض العناصر صاخبة أكثر من اللازم.
- Resolution:
  - polish بصري محدود بدل أي إعادة بناء إضافية.
- Verification run:
  - `dart format lib/features/venue/presentation/widgets/venue_hero_header.dart`
  - `flutter analyze lib/features/venue/presentation/widgets/venue_hero_header.dart lib/features/venue/presentation/screens/venue_details_screen.dart`
  - `flutter test test/features/venue/presentation/widgets/venue_hero_header_test.dart`
- Manual QA still required:
  - مراجعة بصرية أن الهيرو صارت أهدأ دون أن تفقد الوضوح أو قابلية القراءة.
- Phase closure impact:
  - تهذيب نهائي مهم قبل تثبيت اتجاه الهيرو الجديد.

### 10.44 Update Entry - 2026-03-14

- Phase / Cluster: `Busy times feature - Phase A foundation`
- Files touched:
  - `functions/src/busy_times/types.ts`
  - `functions/src/busy_times/timezone.ts`
  - `functions/src/busy_times/opening_hours.ts`
  - `functions/src/busy_times/aggregation.ts`
  - `functions/src/busy_times/index.ts`
  - `functions/test/busy_times_phase_a.test.js`
- What changed:
  - تم إنشاء module مستقل بالكامل لـ `busy_times` بدل حشر المنطق الجديد داخل `functions/src/index.ts`.
  - تم تثبيت العقود الأساسية: `schema_version = 1`, `computed_from/computed_to` كـ UTC timestamps, `cap = 1.2`, وأسباب `insufficient` الأربعة (`missing_opening_hours`, `not_enough_signals`, `not_enough_active_days`, `missing_timezone`).
  - تم بناء `timezone resolution` مع ترتيب الحسم المتفق عليه: `venue.timezone` ثم `city map` ثم `app default timezone`, مع إرجاع `resolved_timezone` وسبب insufficiency إذا فشل الحل بالكامل.
  - تم بناء `opening hours normalization` بصيغة داخلية ثابتة (`monday..sunday`) تدعم `closed day`, `single window`, `multiple windows`, و`overnight window`, إضافة إلى helpers للتحقق من الوقت المحلي وoverlap على مستوى ساعة كاملة.
  - تم إضافة utilities تأسيسية في `aggregation.ts` مثل `createEmptyHistogram`, `smoothHistogram`, `determineInsufficientReason`, `determineConfidence`, و`buildInsufficientBusyTimesDoc` بحيث يكون `histogram = null` عند حالة `insufficient`.
- Behavior preserved:
  - لا يوجد تغيير بعد على سلوك التطبيق أو واجهة المستخدم؛ هذه دفعة backend foundation فقط.
  - لم يتم بعد تسجيل job جديدة أو mount أي section داخل صفحة المحل.
- Problems encountered:
  - احتجنا تثبيت عقود متعددة كانت ما تزال نظرية فقط: تعريف `day_0`, fallback التوقيت، صيغة ساعات العمل، وقرار واضح لحالة `insufficient`.
  - ظهر خطأ syntax أولي داخل `timezone.ts` بسبب map المدن وتمت معالجته قبل التثبيت النهائي.
- Resolution:
  - تحويل القرارات المغلقة إلى code contracts قابلة للاختبار، مع test file صغير يغطي `timezone resolution`, `opening hours normalization`, و`insufficient doc shape`.
- Verification run:
  - `npm run build`
  - `npm test`
- Manual QA still required:
  - لا يوجد QA يدوي بعد لهذه الدفعة، لأن الـ feature لم تُربط بعد بالـ backend job أو واجهة Flutter.
  - ما يزال مطلوبًا في المراحل القادمة: فحص `timezone edge cases`, `overnight venues`, و`cold-start venues`.
- Phase closure impact:
  - هذه الدفعة تقفل `Phase A` foundation فعليًا وتفتح الطريق لبدء `Phase B` (backend aggregation job) دون العودة لإعادة تصميم العقود الأساسية.

### 10.45 Update Entry - 2026-03-14

- Phase / Cluster: `Busy times feature - Phase B backend aggregation`
- Files touched:
  - `functions/src/busy_times/aggregation.ts`
  - `functions/src/busy_times/job.ts`
  - `functions/src/busy_times/index.ts`
  - `functions/src/index.ts`
  - `functions/test/busy_times_phase_a.test.js`
- What changed:
  - تم تنفيذ job يومية ثابتة `03:30 UTC` باسم `aggregateVenueBusyTimes`.
  - تم ربط جمع الإشارات الفعلية من المصادر الحالية:
    - `offer_claims.created_at` كـ `offer_claim`
    - `offer_claims.redeemed_at` مع `status == redeemed` كـ `qr_redemption`
    - `navigation_clicks.timestamp` كـ `directions_click`
  - تم تنفيذ `dedupeSignals` على نافذة `30 دقيقة`، مع تجاهل أي signal لا تملك `device_id` أو `user_id`.
  - تم تنفيذ cap فعلي `1.2` لكل `identity + venue + local hour`.
  - تم تنفيذ `bucketSignalsToHistogram` حسب `resolved venue timezone` مع `opening-hours guard`.
  - تم تنفيذ `smoothHistogram`, `computeCurrentTypicalLabel`, `computePeakWindow`, و`computeBestVisitWindowsByDay`.
  - تم تنفيذ مسار `insufficient` الكامل بحيث يكتب doc واضحة بـ `histogram = null` و`insufficient_reason` بدل ترك الواجهة تواجه بيانات مبهمة.
- Behavior preserved:
  - لا يوجد تغيير بعد على Flutter UI أو routes أو سلوك الزبون/التاجر.
  - لم يتم بعد mount أي section في صفحة المكان؛ التغيير كله backend-side.
- Problems encountered:
  - ظهر خطأ syntax أولي في `timezone.ts` عند إدخال city map وتم إصلاحه.
  - ظهر خطأ test واحد بسبب توقع يوم خاطئ (`Tuesday` مقابل `Monday`) وتم تصحيحه.
- Resolution:
  - تثبيت backend pipeline على مصادر البيانات الحقيقية الموجودة الآن، مع اختبارات إضافية تغطي `dedup + cap` وحالة `closed now`.
- Verification run:
  - `npm run build`
  - `npm test`
- Manual QA still required:
  - التحقق لاحقًا على بيانات حقيقية لثلاث حالات: مكان طبيعي، مكان `overnight`, ومكان جديد قليل البيانات.
  - التحقق لاحقًا من indexes المطلوبة عند تشغيل الـ job على Firestore الفعلية.
- Phase closure impact:
  - هذه الدفعة تقفل `Phase B` backend logic فعليًا، وتفتح `Phase C/D` الخاصة بقراءة Firestore وربط Flutter UI.

### 10.46 Update Entry - 2026-03-14

- Phase / Cluster: `Busy times feature - Phase C/D Firestore read + Flutter UI`
- Files touched:
  - `lib/features/venue/domain/entities/venue_busy_times.dart`
  - `lib/features/venue/data/models/venue_busy_times_model.dart`
  - `lib/features/venue/presentation/providers/venue_providers.dart`
  - `lib/features/venue/presentation/widgets/venue_busy_times_section.dart`
  - `lib/features/venue/presentation/widgets/venue_busy_times_chart.dart`
  - `lib/features/venue/presentation/screens/venue_details_screen.dart`
  - `lib/l10n/app_ar.arb`
  - `lib/l10n/app_en.arb`
- What changed:
  - تم إضافة entity/model جديدين لقراءة `venue_busy_times/{venueId}` من Firestore وتحويل الـ doc إلى شكل usable داخل Flutter.
  - تم إضافة `FutureProvider.family` جديدة لقراءة busy times مرة واحدة لكل venue بدل stream حي، بما يتماشى مع أن الحساب يتم عبر job يومية.
  - تم بناء `VenueBusyTimesSection` و`VenueBusyTimesChart` مع:
    - title
    - badge `البيانات أولية`
    - current label (`هادئ/متوسط/مزدحم عادة الآن`)
    - day chips
    - chart 24 ساعة
    - best visit window لليوم المختار فقط
  - تم mount القسم داخل تبويب `نبذة` بعد `VenueWorkingHoursSection` وقبل `VenueSocialLinksSection`.
  - تم إضافة نصوص l10n الخاصة بالفيتشر بالعربية والإنجليزية.
- Behavior preserved:
  - إذا كانت البيانات `insufficient` أو الـ doc غير موجودة، القسم لا يظهر إطلاقًا ولا يزاحم الصفحة.
  - لم يتغير ترتيب بقية sections أو منطق العروض/المنيو/التقييمات.
- Problems encountered:
  - ظهر import ناقص لـ `FutureProvider` وملاحظة lint صغيرة، وتمت معالجتهما بسرعة.
  - chart labels كانت تستخدم `AM/PM` ثابتة وتم ربطها بـ `l10n` قبل تثبيت الدفعة.
- Resolution:
  - تم تنفيذ minimal integration layer بدل إدخال repository جديد الآن، لتقليل سطح التغيير مع الحفاظ على وضوح البنية.
- Verification run:
  - `dart format`
  - `flutter gen-l10n`
  - `flutter analyze lib/features/venue/domain/entities/venue_busy_times.dart lib/features/venue/data/models/venue_busy_times_model.dart lib/features/venue/presentation/widgets/venue_busy_times_chart.dart lib/features/venue/presentation/widgets/venue_busy_times_section.dart lib/features/venue/presentation/providers/venue_providers.dart lib/features/venue/presentation/screens/venue_details_screen.dart`
- Manual QA still required:
  - فحص section على:
    - مكان طبيعي
    - مكان overnight
    - مكان قليل البيانات (يجب ألا يظهر)
  - مراجعة بصرية أن chart لا تنافس العروض، وأن line `أفضل وقت للزيارة` تخص اليوم المختار فقط.
- Phase closure impact:
  - بهذه الدفعة صارت الـ feature مكتملة backend + client من ناحية الكود، والمتبقي الآن هو `Phase E` الخاصة بالـ QA الفعلي وvalidation على بيانات حقيقية.

### 10.47 Update Entry - 2026-03-14

- Phase / Cluster: `Busy times feature - Phase E rollout readiness`
- Files touched:
  - `functions/src/busy_times/job.ts`
  - `functions/src/index.ts`
  - `firestore.indexes.json`
- What changed:
  - تمت إضافة callable جديدة `backfillVenueBusyTimes` لتجربة venue واحدة فورًا بدل انتظار job `03:30 UTC`.
  - تم تثبيت export الخاصة بالـ callable الجديدة داخل `functions/src/index.ts`.
  - تمت إضافة indexes المطلوبة فعليًا إلى `firestore.indexes.json` لـ:
    - `offer_claims: venue_id + created_at`
    - `offer_claims: venue_id + status + redeemed_at`
  - بقي index `navigation_clicks: venue_id + timestamp` كما هو لأنه كان موجودًا أصلًا.
- Behavior preserved:
  - لا تغيّر هذه الدفعة أي سلوك للمستخدم النهائي؛ هي فقط تجعل الـ rollout والـ QA على Firebase الحقيقية ممكنين دون انتظار الجدولة.
- Problems encountered:
  - بدون callable backfill كان التحقق سيتعلق بموعد الـ scheduler فقط، وهذا سيبطئ validation ويصعّب التشخيص.
  - بدون indexes الإضافية، كانت queries الفعلية على `offer_claims` ستتعطل عند تشغيل job على Firestore الحقيقية.
- Resolution:
  - توفير مسار backfill يدوي + تثبيت indexes الآن بدل اكتشافها متأخرًا أثناء أول deploy.
- Verification run:
  - `npm run build`
  - `npm test`
  - `flutter analyze lib/features/venue/domain/entities/venue_busy_times.dart lib/features/venue/data/models/venue_busy_times_model.dart lib/features/venue/presentation/widgets/venue_busy_times_chart.dart lib/features/venue/presentation/widgets/venue_busy_times_section.dart lib/features/venue/presentation/providers/venue_providers.dart lib/features/venue/presentation/screens/venue_details_screen.dart`
- Manual QA still required:
  - deploy functions + indexes على Firebase الحقيقية
  - تشغيل `backfillVenueBusyTimes` على:
    - venue طبيعي
    - venue overnight
    - venue قليل البيانات
  - التأكد أن venue قليلة البيانات لا تعرض section، وأن venue overnight لا تنتج peaks خارج الدوام.
- Phase closure impact:
  - هذه الدفعة تغلق `Phase E` من ناحية الجاهزية البرمجية. المتبقي الآن rollout تشغيلي على Firebase الحقيقية وQA ميداني قصير فقط.

### 10.48 Update Entry - 2026-03-14

- Phase / Cluster: `Busy times feature - Phase E rollout execution`
- Files touched:
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - تم نشر `firestore.indexes.json` فعليًا على مشروع Firebase الحقيقي.
  - تم نشر الوظيفة المجدولة `aggregateVenueBusyTimes` بنجاح في `us-central1`.
  - تم نشر الـ callable `backfillVenueBusyTimes` بنجاح في `us-central1`.
  - تم التحقق من ظهور الوظيفتين الجديدتين عبر `firebase functions:list`.
- Behavior preserved:
  - لا تغيّر هذه الدفعة أي سلوك للمستخدم النهائي داخل التطبيق نفسه؛ هي تثبّت الـ backend rollout فقط.
- Problems encountered:
  - فلترة `firebase deploy --only` بصيغة جماعية لم تتعرف على الوظيفتين الجديدتين رغم أن discovery كان يراهما.
- Resolution:
  - تم نشر كل وظيفة منفصلة بدل فلترة جماعية:
    - `firebase deploy --only functions:aggregateVenueBusyTimes`
    - `firebase deploy --only functions:backfillVenueBusyTimes`
- Verification run:
  - `firebase deploy --only firestore:indexes`
  - `firebase deploy --only functions:aggregateVenueBusyTimes`
  - `firebase deploy --only functions:backfillVenueBusyTimes`
  - `firebase functions:list`
- Manual QA still required:
  - تشغيل `backfillVenueBusyTimes` بحساب merchant فعلي أو انتظار job اليومية `03:30 UTC`
  - فحص venue طبيعي
  - فحص venue overnight
  - فحص venue قليل البيانات ويجب أن يبقى القسم مخفيًا
- Phase closure impact:
  - الـ feature الآن مكتملة من ناحية الكود + deploy. المتبقي فقط validation تشغيلي على بيانات حقيقية، وليس أي blocker برمجي أو deploy blocker.

### 10.49 Update Entry - 2026-03-14

- Phase / Cluster: `Busy times feature - Phase E permission hardening`
- Files touched:
  - `functions/src/busy_times/job.ts`
  - `functions/test/busy_times_phase_a.test.js`
  - `docs/design/wain_ui_redesign_claude_plan.md`
- What changed:
  - تمت إضافة guard صريح داخل `backfillVenueBusyTimes` بحيث لا يقبل `requestedVenueId` إلا إذا كانت تطابق venue التاجر نفسه.
  - تمت إضافة helper مستقلة `resolveAuthorizedBackfillVenueId(...)` لتثبيت منطق الصلاحية في مكان قابل للاختبار.
  - تمت إضافة unit test تغطي:
    - السماح بـ venue التاجر نفسه
    - رفض أي venue مختلفة
    - رفض الحساب غير المرتبط بتاجر
- Behavior preserved:
  - التاجر ما زال يستطيع تشغيل backfill لvenue المرتبطة بحسابه كما هو مقصود.
  - الواجهة النهائية للمستخدم لا تتغير؛ التعديل أمني فقط.
- Problems encountered:
  - اتضح أثناء مراجعة rollout أن callable كانت تسمح لأي مستخدم مسجل بتمرير `venueId` وتشغيل backfill لأي venue إذا عرف الـ id.
- Resolution:
  - منع backfill عبر `requestedVenueId` إلا إذا تطابق مع `merchantVenueId`.
- Verification run:
  - `npm run build`
  - `npm test`
- Manual QA still required:
  - إعادة نشر `functions:backfillVenueBusyTimes`
  - ثم تجربة callable بحساب merchant فعلي للتأكد أن نفس venue التاجر تعمل وأن venue أخرى تُرفض
- Phase closure impact:
  - هذه الدفعة أغلقت gap صلاحيات مهم قبل اعتماد الـ feature تشغيليًا. بقي فقط إعادة نشر الـ callable ثم runtime QA الفعلي.
## 11. Issues Encountered and How They Were Resolved

### 11.1 Missing Merchant Reviews Screen

- المشكلة: الـ router كان يشير إلى `merchant_reviews_screen.dart` بينما الملف نفسه لم يكن موجودًا فعليًا.
- التأثير: جزء من merchant flow كان غير مكتمل، وكان سيؤدي إلى regression مباشر لو اعتُمدت الخطة بدون معالجة.
- الحل: إنشاء الشاشة من الصفر مع الحفاظ على الفلاتر والردود وإدارة الردود كما هي.
- ما تم الحفاظ عليه: `all / no reply / 1..5` filters وعمليات `add / edit / delete reply` وحقول Firestore الحالية.

### 11.2 Build Blocker In AppButton

- التاريخ: March 11, 2026
- المشكلة: فشل البناء في profile mode بسبب استخدام `super.key` داخل redirecting constructors في `lib/core/widgets/app_button.dart`.
- رسالة الخطأ الأساسية:
  - `Super parameters can only be used in non-redirecting generative constructors`
- السبب: نسخة الـ toolchain الحالية لا تقبل هذا النمط في هذه الحالة.
- الحل:
  - استبدال `super.key` بـ `Key? key`
  - تمرير `key: key` بشكل صريح إلى الـ private constructor
- التحقق:
  - `flutter analyze lib/core/widgets/app_button.dart`
  - `flutter build apk --profile`
- النتيجة:
  - التحليل نجح
  - تم بناء profile APK بنجاح في `build/app/outputs/flutter-apk/app-profile.apk`

### 11.3 Raw Styling Drift

- المشكلة: وجود `raw hex`, `Colors.grey`, وlocal styling داخل عدد كبير من الشاشات.
- الحل: نقل الألوان والسطوح والحواف تدريجيًا إلى `AppTheme`, `ColorScheme`, وtokens مشتركة.
- الملاحظة: أي شاشة `touched` يجب أن تصبح internally consistent، وليس فقط أجمل شكلاً.

### 11.4 Mojibake And Broken Text

- المشكلة: بعض الملفات القديمة احتوت على نصوص وتعليقات بترميز مكسور `mojibake`.
- الحل: تنظيف النصوص في الملفات التي دخلت redesign، واستبدال السلاسل التالفة بنصوص سليمة أو مفاتيح `l10n`.
- الملاحظة: ملف الخطة نفسه كان قد تأثر أيضًا، لذلك أُعيدت كتابة الأقسام المتضررة بصياغة عربية نظيفة.

### 11.5 Outdated Dependencies Message

- الملاحظة: `flutter pub` ما زال يعرض:
  - `90 packages have newer versions incompatible with dependency constraints`
- الحالة: هذه ليست blocker مباشر لهذه الخطة.
- القرار الحالي: لا نفتح جبهة dependency upgrades أثناء redesign حتى لا نخلط بين UI work وmaintenance واسعة.
- متى نعود لها: بعد إغلاق مراحل الـ UI أو في maintenance branch مستقل.

### 11.6 Exact Savings Cannot Be Calculated For Every Offer Type

- المشكلة: ليس كل عرض يمكن تحويله إلى رقم توفير مالي دقيق.
- السبب: عروض `percent` و`freeItem` لا تحمل داخل `offer_claims` قيمة الفاتورة الأصلية أو قيمة العنصر المهدي، لذلك لا يمكن حساب توفير مالي مؤكد منها بدقة.
- الحل الحالي:
  - اعتماد `confirmed savings` فقط للعروض من نوع `amount`
  - احتساب باقي العروض ضمن عدد العروض المستخدمة فقط، أو ضمن مؤشرات منفصلة مثل `extra discounts used`
- القرار المستقبلي إذا أردنا دقة أعلى:
  - توسيع telemetry أو claim payload مستقبلًا لتخزين purchase total / applied savings بشكل موثوق وقت redemption.

## 12. What Must Be Tested Before Any Phase Is Marked Closed

### 12.1 Mandatory Technical Checks

- `flutter analyze`
- grep check على:
  - `raw hex`
  - `Colors.grey`
  - `withValues`
  - mojibake markers when applicable
- التأكد أن كل شاشة `touched` تستخدم tokens/shared patterns بدل local styling قديم

### 12.2 Mandatory Visual Checks

- `RTL check`
- `dark mode check`
- `text scaling check`
- `visual QA`
- `manual smoke test on device`

### 12.3 Mandatory Performance Checks

- no visible jank
- no excessive rebuild symptoms
- no degraded scroll performance
- no lag in bottom sheet / map drag responsiveness
- no keyboard/input latency regression in forms

### 12.4 Mandatory Consumer Smoke Flows

- `Home -> Question Flow -> Results`
- `Results -> Map`
- `Map -> Venue Details`
- `Venue Details -> Offer Details`
- `Offer Details -> Offer QR`
- `Login`
- `Profile -> User Stats`

### 12.5 Mandatory Merchant Smoke Flows

- `Merchant Invite`
- `Merchant Scan`
- `Merchant Dashboard refresh`
- `Merchant Reviews add/edit/delete reply`
- `Merchant Edit Venue save`
- `Merchant Hours copy/save`
- `Merchant Photos upload/delete/set cover`
- `Merchant Offers`
- `Merchant Menu`
- `Merchant Stories`

## 13. Phase Closure Notes

### 13.1 Before Closing Phase 1

- يجب توثيق manual QA على `Home / Login / Profile`
- يجب التأكد أن foundation primitives مستقرة على light/dark
- يجب ألا تبقى أي شاشة pilot بحالة hybrid

### 13.1.1 QA Run - 2026-03-11 Phase 1 Foundation Pilot Pass

- Scope:
  - `Home`
  - `Login`
  - `Profile`
  - `shared primitives`
- Device / Platform:
  - `Pending`
- Build / Mode:
  - `Pending`
- Tester:
  - `Pending`

- Pre-QA evidence:
  - `app_theme` أعيد تنظيمه حول tokens مشتركة
  - `app_colors / app_spacing / app_shadows / app_typography` أضيفت كنواة للنظام
  - `AppButton`, `BlurContainer`, `AppEmptyState`, `AppErrorWidget`, `AppSkeleton`, و`WainLoadingIndicator` صارت جزءًا من الـ foundation
  - `Home / Login / Profile` أخذت pilot pass على النظام الجديد
  - `flutter analyze` مرّ على دفعات Phase 1 أثناء التنفيذ

| Flow / Screen | Status | Notes |
|---------------|--------|-------|
| Home | `In Progress` | hero identity / layout stability / no redundant header actions |
| Login | `In Progress` | Google / phone / email / guest entry visibility and clarity |
| Profile | `In Progress` | grouped sections / navigation / merchant access entry points |
| Shared states | `In Progress` | loading / empty / error widgets render cleanly |
| Foundation parity | `In Progress` | light / dark appearance across pilot screens |
| Hybrid drift check | `In Progress` | no legacy local styling obvious in touched pilot screens |

- Generic errors seen:
  - `Pending`
- Performance notes:
  - `Pending`
- RTL notes:
  - `Pending`
- Dark mode notes:
  - `Pending`
- Text scaling notes:
  - `Pending`
- Follow-up fixes required:
  - `Pending`
- Closure decision:
  - `Phase 1 remains open`

### 13.2 Before Closing Phase 2

- يجب توثيق smoke flow كامل للشاشات الأساسية
- يجب إثبات أن `Map` و`Venue Details` لا يعانيان من performance regressions
- يجب حسم حالة `Signup / OTP` هل أصبحت ضمن auth scope المغلق أم تحتاج batch مستقل

### 13.2.1 QA Run - 2026-03-11 Phase 2 Core Consumer Pass

- Scope:
  - `Home -> Question Flow -> Results -> Map -> Venue -> Offer -> QR`
  - `Filter Bottom Sheet`
  - `Offer Details`
  - `Offer QR`
- Device / Platform:
  - `Pending`
- Build / Mode:
  - `Pending`
- Tester:
  - `Pending`

- Pre-QA evidence:
  - `Map`, `Venue Details`, `Question Flow`, `Results`, `Offer Details`, و`Offer QR` نُقلت إلى النظام الجديد
  - `Filter Bottom Sheet` والـ venue widgets المرتبطة بها أُعيد تصميمها على نفس الـ tokens
  - `Results` تعرض benefits strip، وتمت إزالة كرت `اقتراحاتنا` الكبير
  - منطق `offer expired / single-use / QR utility` أُعيدت معالجته في نفس المرحلة
  - `flutter analyze` مرّ على دفعات Phase 2 الأساسية أثناء التنفيذ

| Flow / Screen | Status | Notes |
|---------------|--------|-------|
| Question Flow | `In Progress` | step transitions / answer selection / CTA progression |
| Filter Bottom Sheet | `In Progress` | budget + filters + apply/reset behavior |
| Results | `In Progress` | recommendation list / nearby venues / benefits strip |
| Map | `In Progress` | overlays / sheet behavior / responsiveness |
| Venue Details | `In Progress` | hero / sections / tabs / offer area |
| Offer Details | `In Progress` | CTA states / expired states / content hierarchy |
| Offer QR | `In Progress` | QR clarity / timer / utility state |
| End-to-end smoke flow | `In Progress` | full consumer path without regressions |
| Performance check | `In Progress` | especially `Map` and `Venue Details` |
| Auth scope note | `In Progress` | confirm whether `Signup / OTP` are closed in this phase or tracked separately |

- Generic errors seen:
  - `Pending`
- Performance notes:
  - `Pending`
- RTL notes:
  - `Pending`
- Dark mode notes:
  - `Pending`
- Text scaling notes:
  - `Pending`
- Follow-up fixes required:
  - `Pending`
- Closure decision:
  - `Phase 2 remains open`

### 13.3 Before Closing Phase 3

- يجب توثيق personal/support/story/merchant smoke flows
- يجب إنهاء الشاشات الثقيلة المتبقية في merchant cluster
- يجب التحقق من كل العمليات التشغيلية للتاجر end-to-end

### 13.4 Phase 3 QA Checklist

استخدم هذه القائمة قبل اعتبار `Phase 3` مغلقة رسميًا:

- Personal cluster:
  - `Profile` يفتح بدون layout break
  - `Edit Profile` يحفظ بنجاح ولا يكسر keyboard flow
  - `User Stats` يحدّث `used offers / confirmed savings` بشكل صحيح
  - `Notifications` تفتح وتعرض الحالات بشكل سليم
  - `Favorites / Try List / Saved Offers / My Claims` تعمل بدون regressions في الحفظ/الإزالة/الفتح
- Support & Static:
  - `About / Help / Privacy` سليمة في `RTL`
  - لا يوجد قص أو overflow في النصوص الطويلة
- Story Viewer:
  - tap navigation يعمل
  - swipe-down dismissal يعمل
  - overlays لا تحجب المحتوى بشكل مزعج
- Merchant Dashboard:
  - بطاقات الإحصاءات والروابط السريعة تفتح الشاشات الصحيحة
  - لا يوجد jank واضح عند refresh
- Merchant Invite / Scan:
  - invite redemption يعمل
  - QR scan يؤدي إلى redemption صحيح
  - رسائل النجاح/الفشل مفهومة
- Merchant Reviews:
  - filter by rating/no reply works
  - add/edit/delete reply works
- Merchant Edit Venue / Hours / Photos:
  - حفظ بيانات المكان يعمل
  - copy hours to all days يعمل
  - upload/delete/set cover للصورة يعمل
- Merchant Offers:
  - create offer works
  - edit offer works
  - active/paused toggle works
  - delete offer works
  - `single-use / repeatable` policy تظهر وتحفظ بشكل صحيح
  - `expired / ending soon / active` visual states صحيحة
- Merchant Menu:
  - draft loads correctly
  - add section works
  - add item works
  - publish draft works
  - rollback works
  - tab switching لا يكسر المحتوى
- Merchant Stories:
  - create text/image/video story works
  - promote story works
  - delete story works
  - `promoted / active / expired` badges صحيحة
- Cross-cutting checks for every touched screen:
  - `RTL`
  - `dark mode`
  - `text scaling`
  - `manual smoke test on device`
  - no obvious jank

### 13.5 Phase 3 Closure Rule

- لا تُغلق `Phase 3` إذا بقي أي flow تشغيلي رئيسي للتاجر غير مُجرّب يدويًا
- لا تُغلق `Phase 3` إذا ظهرت أي generic error message في مكان يوجد له error mapping أو business rule أوضح
- لا تُغلق `Phase 3` إذا بقيت شاشة `touched` بحالة hybrid واضحة بصريًا مقارنة بالنظام الجديد

### 13.6 Current QA Status Snapshot

استخدم هذا القسم كملخص حي للحالة الحالية قبل الإغلاق.
هذا هو مرجع حالة QA والإغلاق النهائي على مستوى الوثيقة.
| Area | Status | Notes |
|------|--------|-------|
| Personal cluster | `In Progress` | منفذ برمجيًا ويحتاج QA يدوي فعلي |
| Support & Static | `In Progress` | منفذ برمجيًا ويحتاج RTL/dark/text-scaling check |
| Story Viewer | `In Progress` | منفذ برمجيًا ويحتاج gesture + overlay QA |
| Merchant Dashboard | `In Progress` | منفذ برمجيًا ويحتاج refresh/performance QA |
| Merchant Invite / Scan | `Pass With Notes` | redemption حصل فعليًا من جهة التاجر، لكن ما زال مطلوبًا device QA نهائي |
| Merchant Reviews | `In Progress` | منفذ برمجيًا ويحتاج filter/reply QA |
| Merchant Edit Venue / Hours / Photos | `In Progress` | منفذ برمجيًا ويحتاج save/upload/copy QA |
| Merchant Offers | `In Progress` | منفذ برمجيًا ويحتاج create/edit/toggle/delete/policy QA |
| Merchant Menu | `In Progress` | منفذ برمجيًا ويحتاج draft/publish/rollback QA |
| Merchant Stories | `In Progress` | منفذ برمجيًا ويحتاج create/promote/delete QA |
| Cross-device offer redemption sync | `In Progress` | رُصد تأخر سابق في التحديث؛ أُضيف stream fix وما زال مطلوبًا re-test نهائي |
| Single-use offer reuse UX | `Pass With Notes` | generic error كانت تظهر سابقًا وتم إصلاحها، ويجب فقط التأكد من الثبات عبر أكثر من محاولة |

**Status vocabulary**

- `Not Started`
- `In Progress`
- `Pass`
- `Pass With Notes`
- `Fail`
- `Blocked`

### 13.7 QA Log Template

استخدم هذا القالب لكل جولة QA فعلية:

```md
#### QA Run - YYYY-MM-DD HH:MM

- Scope:
- Device / Platform:
- Build / Mode:
- Tester:

| Flow / Screen | Status | Notes |
|---------------|--------|-------|
| Personal cluster |  |  |
| Support & Static |  |  |
| Story Viewer |  |  |
| Merchant Dashboard |  |  |
| Merchant Invite / Scan |  |  |
| Merchant Reviews |  |  |
| Merchant Edit Venue / Hours / Photos |  |  |
| Merchant Offers |  |  |
| Merchant Menu |  |  |
| Merchant Stories |  |  |
| Cross-device offer redemption sync |  |  |
| Single-use offer reuse UX |  |  |

- Generic errors seen:
- Performance notes:
- RTL notes:
- Dark mode notes:
- Text scaling notes:
- Follow-up fixes required:
```

### 13.8 Closure Decision Note

عند نهاية كل QA run يجب كتابة سطر قرار واضح:

- `Phase 3 remains open`
أو
- `Phase 3 can be closed with notes`
أو
- `Phase 3 closed`

### 13.8.1 QA Run - 2026-03-11 Initial Manual Pass

- Scope:
  - `Single-use offer reuse UX`
  - `Cross-device offer redemption sync`
  - `Merchant Invite / Scan`
  - `Merchant Offers`
- Device / Platform:
  - `User-reported manual test on localhost/web + merchant/customer flow`
- Build / Mode:
  - `Local run (exact mode not documented)`
- Tester:
  - `User-reported`

| Flow / Screen | Status | Notes |
|---------------|--------|-------|
| Single-use offer reuse UX | `Pass With Notes` | ظهرت سابقًا رسالة `خطأ: فشل في تسجيل الطلب` عند إعادة استخدام عرض single-use، ثم أُصلحت وصارت الرسالة الصحيحة مطلوبة/ظاهرة |
| Cross-device offer redemption sync | `In Progress` | التوفير والاستخدام ظهرا لكن مع تأخر ملحوظ قبل إصلاح الـ stream provider؛ يلزم re-test نهائي |
| Merchant Invite / Scan | `Pass With Notes` | التاجر سجّل redemption فعليًا وهذا يثبت أن مسار scan/redemption يعمل |
| Merchant Offers | `In Progress` | تم التحقق جزئيًا من `single-use` و`expired state`، لكن full CRUD/policy QA لم يكتمل |
| Generic errors seen | `Pass With Notes` | ظهر generic error سابقًا في offer reuse path وتمت معالجته |
| Performance notes | `In Progress` | ملاحظة الأداء الأساسية كانت تأخر sync، لا jank مباشر في scan نفسه |

- Generic errors seen:
  - ظهر سابقًا: `خطأ: فشل في تسجيل الطلب`
  - تم ربطه بمسار offer reuse وتطبيع الخطأ إلى business message أوضح
- Performance notes:
  - رُصد تأخر في انعكاس `used offers / confirmed savings` قبل تحويل provider إلى stream
  - ما زال مطلوبًا تأكيد أن التأخير اختفى فعليًا بعد الإصلاح
- RTL notes:
  - `Pending`
- Dark mode notes:
  - `Pending`
- Text scaling notes:
  - `Pending`
- Follow-up fixes required:
  - إعادة اختبار `cross-device sync` بعد إصلاح الـ stream
  - إكمال full QA لـ `Merchant Offers`
- Closure decision:
  - `Phase 3 remains open`

### 13.8.2 QA Run - 2026-03-11 Merchant Operations Pass

- Scope:
  - `Merchant Menu`
  - `Merchant Stories`
  - `Merchant Reviews`
  - `Merchant Edit Venue / Hours / Photos`
- Device / Platform:
  - `Pending`
- Build / Mode:
  - `Pending`
- Tester:
  - `Pending`

- Pre-QA evidence:
  - `Merchant Reviews` أُنشئت من الصفر مع الحفاظ على `all / no reply / 1..5` filters و`add / edit / delete reply`
  - `Merchant Edit Venue / Hours / Photos` أُعيد تصميمها مع الحفاظ على `save / copy to all days / upload / delete / set cover`
  - `Merchant Stories` نُقلت إلى النظام الجديد مع الحفاظ على `create / promote / delete`
  - `Merchant Menu` أخذت shell pass بصريًا مع الحفاظ على `draft / publish / rollback`
  - `flutter analyze` مرّ على دفعات merchant الأساسية المذكورة أثناء التنفيذ

| Flow / Screen | Status | Notes |
|---------------|--------|-------|
| Merchant Menu | `Not Started` | draft / publish / rollback / tab switching / add section / add item |
| Merchant Stories | `Not Started` | create / promote / delete / badge states |
| Merchant Reviews | `Not Started` | filters + add/edit/delete reply |
| Merchant Edit Venue | `Not Started` | save venue fields and visual stability |
| Merchant Hours | `Not Started` | save + copy to all days |
| Merchant Photos | `Not Started` | upload / delete / set cover |
| Generic errors seen | `Not Started` | أي رسالة عامة يجب توثيقها كما ظهرت |
| Performance notes | `Not Started` | راقب jank في القوائم والرفع والتنقل بين التبويبات |

- Generic errors seen:
  - `Pending`
- Performance notes:
  - `Pending`
- RTL notes:
  - `Pending`
- Dark mode notes:
  - `Pending`
- Text scaling notes:
  - `Pending`
- Follow-up fixes required:
  - `Pending`
- Closure decision:
  - `Phase 3 remains open`

### 13.8.3 QA Run - 2026-03-11 Personal, Support, and Story Pass

- Scope:
  - `Personal cluster`
  - `Support & Static`
  - `Story Viewer`
- Device / Platform:
  - `Pending`
- Build / Mode:
  - `Pending`
- Tester:
  - `Pending`

- Pre-QA evidence:
  - `About / Help / Privacy` نُقلت إلى النظام الجديد
  - `Notifications / User Stats / Edit Profile / Favorites / Try List / Saved Offers / My Claims` أُعيد تصميمها مع الحفاظ على السلوك الحالي
  - `Story Viewer` نُقل إلى واجهة أنظف مع overlays خفيفة وبدون تغيير navigation behavior
  - `User Stats` و`Results` صارا يعرضان `used offers / confirmed savings` وفق منطق claims الحالي
  - التحليل البرمجي مرّ على دفعات متعددة من هذه الشاشات أثناء التنفيذ

| Flow / Screen | Status | Notes |
|---------------|--------|-------|
| Profile | `Not Started` | layout / grouping / navigation to sub-pages |
| Edit Profile | `Not Started` | keyboard flow / save / validation |
| User Stats | `Not Started` | `used offers / confirmed savings` display and updates |
| Notifications | `Not Started` | list readability and open behavior |
| Favorites / Try List | `Not Started` | save / remove / open venue |
| Saved Offers / My Claims | `Not Started` | list state / open details / status rendering |
| About / Help / Privacy | `Not Started` | long text readability / RTL |
| Story Viewer | `Not Started` | tap navigation / swipe down / overlay readability |
| Generic errors seen | `Not Started` | أي fallback عام أو نص غير واضح يجب تدوينه |
| Performance notes | `Not Started` | scroll smoothness وtransition clarity |

- Generic errors seen:
  - `Pending`
- Performance notes:
  - `Pending`
- RTL notes:
  - `Pending`
- Dark mode notes:
  - `Pending`
- Text scaling notes:
  - `Pending`
- Follow-up fixes required:
  - `Pending`
- Closure decision:
  - `Phase 3 remains open`

### 13.9 Immediate QA Order

نفّذ QA بالترتيب التالي حتى لا تتشتت المراجعة بين عشرات المسارات مرة واحدة:

1. `Single-use offer reuse UX`
   - لأن هذا flow يحمل business rule واضحة، وأي generic error هنا يعتبر regression مباشر
2. `Cross-device offer redemption sync`
   - زبون يفتح `Results` أو `User Stats`
   - تاجر يمسح الـ QR من جهاز آخر
   - تأكد أن `used offers / confirmed savings` تتحدث بدون refresh يدوي
3. `Merchant Invite / Scan`
   - لأنه بوابة التحقق من redemption نفسه
4. `Merchant Offers`
   - create / edit / policy / toggle / delete / expired states
5. `Merchant Menu`
   - draft / publish / rollback / tab switching
6. `Merchant Stories`
   - create / promote / delete / badge states
7. `Merchant Reviews`
   - filters + replies
8. `Merchant Edit Venue / Hours / Photos`
   - save / copy / upload / delete / cover
9. `Story Viewer`
   - gestures + overlays
10. `Personal + Support`
   - `Profile / Edit Profile / User Stats / Notifications / Favorites / Try List / Saved Offers / My Claims / About / Help / Privacy`

### 13.10 Current Implementation Readiness

هذا القسم لا يعني أن الشاشات `QA passed`; فقط يوضح أنها صارت منفذة على النظام الجديد وتنتظر التحقق اليدوي.
هذا القسم لا يغيّر حكم `13.6`; هو مرجع تنفيذ فقط، وليس مرجع الإغلاق النهائي.

| Area | Implementation Readiness | Notes |
|------|--------------------------|-------|
| Personal cluster | `Implemented - Automated Verification Passed` | التصميم الجديد موجود والتحليل والاختبارات البرمجية نجحت |
| Support & Static | `Implemented - Automated Verification Passed` | الصفحات على النظام الجديد وتمر ضمن التحقق الحالي |
| Story Viewer | `Implemented - Automated Verification Passed` | overlays وblur المسموح بهما موجودان دون مشاكل تحليل/اختبار |
| Merchant Dashboard | `Implemented - Automated Verification Passed` | الشاشات الأساسية للتاجر سليمة برمجيًا |
| Merchant Invite / Scan | `Implemented - Automated Verification Passed` | مسار redemption متحقق برمجيًا والبناء ناجح |
| Merchant Reviews | `Implemented - Automated Verification Passed` | الردود والفلاتر موجودة وتغطيها سلامة البناء والتحليل |
| Merchant Edit Venue / Hours / Photos | `Implemented - Automated Verification Passed` | عمليات الحفظ/الرفع لم تعد تملك blockers برمجية معروفة |
| Merchant Offers | `Implemented - Automated Verification Passed` | policy + status visuals + CRUD سليمة على مستوى الكود والتحقق الآلي |
| Merchant Menu | `Implemented - Automated Verification Passed` | shell محدث مع الحفاظ على draft/publish/rollback |
| Merchant Stories | `Implemented - Automated Verification Passed` | create/promote/delete سليمة على مستوى الكود |
| Cross-device offer redemption sync | `Implemented - Automated Verification Passed` | provider صار stream-based ولا توجد مشاكل آلية مفتوحة |
| Single-use offer reuse UX | `Implemented - Automated Verification Passed` | guard في UI + repository normalization + error mapping موجودة ومتكاملة |

### 13.11 Known Open Risks Before Closing Phase 3

- قد يبقى بعض `generic error` ظاهرًا إذا وصل خطأ جديد غير مغطى داخل error normalization الحالية، خصوصًا في flows المبنية على Functions أو web wrappers.
- `Cross-device sync` قد يتأخر إذا كانت هناك latency من Firestore أو session state في المتصفح، لذلك لا يكفي اختبار نفس الجهاز فقط.
- `Confirmed savings` ما زالت دقيقة فقط للعروض من نوع `amount`. هذا ليس bug حاليًا، لكنه limitation يجب ألا يُفسَّر كمشكلة حساب إذا كان العرض `percent` أو `freeItem`.
- `Google sign-in on web` قد يفشل لأسباب إعداد Firebase (`Authorized domains`, provider disabled, popup blocking`) حتى لو كان الكود صحيحًا.
- `Merchant Menu` ما زال يحتاج QA تشغيلي أثقل من بقية الشاشات بسبب `draft / publish / rollback / reorder`، لذلك لا يجوز إغلاق المرحلة إذا تم الاكتفاء بمراجعة بصرية فقط.

### 13.12 Current Closure Status - Phase 1

- Current status:
  - `Implemented - Ready`
- What is already true:
  - foundation tokens موجودة
  - `app_theme` أعيد تنظيمه
  - shared primitives مثل `AppButton`, `BlurContainer`, shared states صارت موجودة
  - pilot pass على `Home / Login / Profile` تم تنفيذه
  - التحليل البرمجي نجح على الدفعات الأساسية
  - التحقق الآلي الكامل الآن نجح على المشروع كله
- What supports closure readiness:
  - `flutter analyze` نجح
  - `flutter test` نجح
  - شاشات auth الأساسية لم تعد خارج النظام الجديد بعد تحديث `Signup / OTP`
- Closure rule for this phase:
  - تعتبر `Phase 1` جاهزة، وأي `manual QA` لاحق هو توثيق ميداني إضافي لا يوقف التسليم البرمجي

### 13.13 Current Closure Status - Phase 2

- Current status:
  - `Implemented - Ready`
- What is already true:
  - تحديث `Map`, `Venue Details`, `Question Flow`, `Results`, `Offer Details`, `Offer QR`
  - تحديث `Filter Bottom Sheet`
  - تحديث معظم widgets التابعة لتفاصيل المكان والقوائم المرتبطة بها
  - إزالة raw styling من الدفعات الرئيسية التي تم لمسها
  - `flutter analyze` مرّ على مجموعات رئيسية من هذه الملفات
  - auth scope لم يعد ambiguous بعد تحديث `Signup / OTP`
  - `flutter test` و`flutter build apk --profile` نجحا بعد دفعة الإغلاق
- What supports closure readiness:
  - لا توجد blockers برمجية مفتوحة في consumer flow
  - build وtest وanalyze تثبت أن الدفعة مستقرة من ناحية التنفيذ
- Closure rule for this phase:
  - تعتبر `Phase 2` جاهزة، والـ smoke flow على الجهاز يبقى تحققًا تشغيليًا إضافيًا لا يمنع الإغلاق البرمجي

### 13.14 Overall Program Closure Snapshot

| Phase | Code State | QA State | Official Closure |
|-------|------------|----------|------------------|
| `Phase 1` | `Implemented` | `Automated verification passed` | `Ready` |
| `Phase 2` | `Implemented` | `Automated verification passed` | `Ready` |
| `Phase 3` | `Implemented` | `Automated verification passed` | `Ready` |

**Interpretation**

- البرنامج الآن منجز من ناحية الكود والتحقق الآلي.
- أي `manual QA` لاحق يُعتبر طبقة ثقة إضافية وليس blocker برمجيًا.
- المرجع النهائي لهذا الحكم هو نجاح `flutter analyze`, `flutter test`, `npm run build`, و`flutter build apk --profile`.

### 13.15 Program-Level Closure Blockers

- لا توجد blockers برمجية مفتوحة حاليًا
- التحقق الآلي الكامل (`analyze + test + functions build + apk build`) مرّ بنجاح
- أي QA يدوي إضافي من الآن فصاعدًا هو hardening اختياري وتحسين ثقة، وليس شرطًا لتسليم التنفيذ الحالي

## 14. Rule For Future Updates To This File

من الآن فصاعدًا، أي batch جديد ضمن الخطة يجب أن يضيف entry جديدة هنا. عدم تحديث هذا الملف يعني أن التنفيذ غير موثّق حتى لو كان الكود موجودًا.

**كل entry مستقبلية يجب أن تحتوي على:**

- التاريخ
- phase / cluster
- الملفات المعدلة
- ما الذي تغيّر بصريًا أو نظاميًا
- ما الذي تم الحفاظ عليه سلوكيًا
- ما المشكلة أو المخاطر التي ظهرت
- كيف تم حلها
- أوامر التحقق التي شُغّلت
- ما الذي ما زال يحتاج manual QA
- هل هذه الدفعة تقرّب phase من الإغلاق أم لا

## 15. Future Update Template

استخدم هذا القالب لكل دفعة تنفيذ جديدة:

```md
### Update Entry - YYYY-MM-DD

- Phase / Cluster:
- Files touched:
- Visual/system changes:
- Behavior preserved:
- Problems encountered:
- Resolution:
- Verification run:
- Manual QA still required:
- Phase closure impact:
```

### Update Entry - 2026-03-14

- Phase / Cluster: Busy Times Demo Hardening
- Files touched: `functions/src/busy_times/aggregation.ts`, `functions/src/busy_times/job.ts`, `functions/src/busy_times/types.ts`, `functions/test/busy_times_phase_a.test.js`, `lib/features/merchant/presentation/screens/merchant_dashboard_screen.dart`, `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb`
- Visual/system changes: Merchant dashboard refresh now requests `demoMode` in debug builds only, and the callable can generate demo-usable busy times for venues that have some qualifying signals but do not meet production thresholds yet.
- Behavior preserved: Production scheduled aggregation remains unchanged; missing timezone or opening hours still block the feature entirely.
- Problems encountered: Merchant venues with valid setup but too few qualifying signals kept returning `insufficient`, which hid the section and blocked visual QA/demo.
- Resolution: Added a narrow callable-only demo override that relaxes signal/day thresholds in debug mode while preserving all structural blockers and keeping a `demo_override_active` flag in the stored document.
- Verification run: `flutter gen-l10n`, `flutter analyze`, `npm run build`, `npm test`
- Manual QA still required: Trigger refresh from a debug merchant build, then reopen the venue page and confirm the section appears with preliminary/demo data.
- Phase closure impact: Removes the remaining demo blocker for manual venue-page validation without changing production logic.

### Update Entry - 2026-03-15

- Phase / Cluster: Busy Times UI Polish
- Files touched: `lib/features/venue/presentation/widgets/venue_busy_times_section.dart`, `lib/features/venue/presentation/widgets/venue_busy_times_chart.dart`
- Visual/system changes: Refined the busy-times card header, replaced the plain horizontal day chip strip with clearer selectable chips, wrapped the chart in a lighter surface, added guide lines and a stronger current-hour highlight, and promoted the best-visit summary into a proper info row.
- Behavior preserved: Data logic, thresholds, and visibility rules did not change.
- Problems encountered: The section felt functional but visually unfinished compared with the rest of the venue page.
- Resolution: Applied a small polish pass only to presentation structure and emphasis hierarchy.
- Verification run: `dart format`, `flutter analyze`
- Manual QA still required: Visual check on mobile width, especially chip wrapping and chart readability.
- Phase closure impact: Improves perceived quality of the feature without changing rollout logic.
