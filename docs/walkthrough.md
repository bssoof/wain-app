# دليل الاستخدام والتحديثات (Walkthrough)

## تحديث V2.2 - تحسين صفحة المطعم (Venue UX)

### Sprint 0
- تم إصلاح النصوص المشوهة (Mojibake) في `app_ar.arb` وشاشة إدارة منيو التاجر.
- تم إضافة خط `Cairo` وتفعيله داخل الثيم الفاتح والداكن.
- تمت إضافة اختبار حارس: `test/core/mojibake_guard_test.dart`.

### Sprint 1
- تم استخراج منطق تبويب المنيو من `venue_details_screen.dart` إلى:
  - `lib/features/venue/presentation/widgets/venue_menu_tab.dart`
- تمت إضافة شريط ملخص علوي جديد:
  - `lib/features/venue/presentation/widgets/venue_summary_strip.dart`
- تم تخفيف ارتفاع الهيدر البصري في `venue_hero_header.dart` لتحسين المساحة المفيدة للمنيو.

### Sprint 2
- تم تثبيت سلوك الأقسام:
  - أول قسم مفتوح افتراضيًا.
  - باقي الأقسام مغلق مع معاينة 4 عناصر.
  - `عرض الكل (+N)` و `عرض أقل`.
- تم تحسين مزامنة الـ chips مع التمرير بعكس الاتجاهين مع حماية من loop عبر:
  - `Timer` debounce (120ms)
  - `isProgrammaticScroll` guard
- تم تحسين صف العنصر ليعرض وصفًا خفيفًا مع الحفاظ على الكثافة.

### Sprint 3
- تم نقل النصوص الحرجة في واجهة المنيو إلى ARB وإعادة توليد ملفات الترجمة.
- تم التحقق بـ:
  - `flutter analyze` (نظيف)
  - اختبارات widgets الخاصة بالمنيو + mojibake guard.

## المرحلة 2: إعادة تصميم واجهة التاجر وتجربة العميل (Merchant Menu UX & Customer View UX)

### ملخص الأعمال المنجزة

1. **ميزة السحب والإفلات للتاجر (Merchant Menu Drag & Drop):**
   - تم تعديل `merchant_menu_screen.dart` لاستخدام `ReorderableListView` في إدارة الأقسام (Categories) قوائم العناصر داخل تبويبات `MerchantMenuScreen`.
   - تمت إضافة دوال قوية `reorderMenuSections` و `reorderMenuItems` في `menu_repository.dart` لتحديث ترتيب العناصر `sort_order` بأمان عبر Firestore Batches (تم تجهيزها لتفادي حد الـ 500 عملية).

2. **إعادة تصميم واجهة العميل (Premium Customer Menu Redesign):**
   - تم التعديل الشامل لمظهر المكونات في `venue_menu_section.dart` (بما في ذلك `VenueMenuSectionBlock` و `VenueMenuItemTile`).
   - تم إزالة الإطارات البسيطة (Borders) واستبدالها بتصميم مسطح يعتمد على الفواصل وتكبير الصور (تماشياً مع تطبيقات التوصيل الحديثة).
   - تم إصلاح جميع إنذارات المحلل (Analyzer Warnings) مثل `use_build_context_synchronously`.

---

# Merchant Experience Walkthrough - Phase 3 (COULD)

## Phase 2: Core Merchant Features (Completed)

- **Edit Venue**: Can update name, description, category, and city.
- **Manage Photos**: Upload, Order, Delete photos.
- **Reviews**: View user reviews, Reply to them, Delete replies.
- **Stories**: Add/Delete stories, View active stories.
- **Offers**: List offers, Toggle active status.

### Verification

- [x] Edit Venue: Updates reflected in Firestore.
- [x] Photos: Storage interaction works (mocked/real).
- [x] Reviews: Reply/Delete UI functional.
- [x] Offers: Switch toggle updates Firestore (deprecated `activeColor` fixed).

---

## Phase 3: Notifications & Scanner (Completed)

### 1. Notification Center 🔔

- **Location**: Top of Merchant Dashboard (Bell Icon).
- **Features**:
  - Badge showing unread count.
  - List of notifications (Reviews, Offers, System).
  - Mark as read functionality.
  - "Mark All Read" button.

### 2. QR Redemption System 📷

- **Location**: "ماسح الكود" Button in Dashboard Quick Actions.
- **Security**:
  - ✅ Merchant must own the venue to validate/redeem offers
  - ✅ Cross-venue scanning blocked (e.g., Stono cannot scan Vanilla's offers)
- **Features**:
  - **Scanner**: Uses camera to scan User QR codes.
  - **Validation**: Calls `validateToken` Cloud Function (with ownership check).
  - **Result Sheet**: Shows Offer/Venue details and "Redeem" button.
  - **Redemption**: Calls `redeemToken` Cloud Function (with ownership verification).

### Manual Testing Steps

1.  **Notifications**:
    - Click the Bell Icon.
    - Verify the list loads.
    - Tap an item -> Should mark as read (icon changes).
2.  **QR Scanner (Same Venue)**:
    - Click "ماسح الكود".
    - Accept Camera Permission.
    - Scan a QR code from User App (same venue) -> See Result Sheet.
    - Click "Redeem" -> See Success message.

3.  **QR Scanner (Cross-Venue) - Security Test**:
    - Login as merchant for Venue A (e.g., Stono)
    - Scan QR code for offer from Venue B (e.g., Vanilla)
    - Should see error: "This offer belongs to a different venue"

---

## Security Updates (Post-Deployment)

### Critical Fix: QR Cross-Venue Validation

- **Issue**: Any merchant could view offers from other venues
- **Fix**: Added `venue_id` ownership check in `validateToken`
- **Status**: Deployed to Cloud Functions

