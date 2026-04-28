# Phase A — Governance Lock: إدارة الجهات

> هذا المستند هو **وثيقة القرار الملزمة** لـ Phase A من خطة إدارة الجهات.
> لا يبدأ أي كود قبل إغلاق كل بند في هذا المستند.

---

## A1. قفل نموذج البيانات (Data Model Lock)

### A1.1 الحقول الجديدة المطلوبة على `venues/{venueId}`

هذه الحقول **تُضاف مباشرة** على مستند الجهة الحالي في Firestore، وليس في مستند فرعي منفصل.

| اسم الحقل | النوع | القيم المسموحة | القيمة الافتراضية | ملاحظات |
| --- | --- | --- | --- | --- |
| `subscription_status` | `string` | `active`, `expired`, `paused` | `active` | حالة الاشتراك التجاري |
| `visibility_status` | `string` | `visible`, `hidden` | `visible` | هل تظهر للمستخدم النهائي |
| `operational_status` | `string` | `active`, `suspended`, `archived` | `active` | الحالة التشغيلية الداخلية |
| `admin_status_updated_at` | `Timestamp` | — | `null` | آخر تغيير حالة من الأدمن |
| `admin_status_updated_by` | `string` | UID | `null` | من أجرى آخر تغيير |

### A1.2 لماذا على المستند الأصلي وليس مستند فرعي؟

- حقول الحالة تحتاج أن تُقرأ مع كل query على مجموعة `venues` — مستند فرعي يعني join إضافي.
- الحقول خفيفة (3 strings + timestamp + string) ولا تُثقل المستند.
- تطبيق الموبايل يحتاج يقرأها مع الجهة مباشرة لتحديد الظهور.

### A1.3 الحقول الموجودة حالياً (مرجع)

من [`venue.dart`](file:///c:/Users/a-z/OneDrive/Desktop/googleAITest/WAIN%20APP/wain_app/lib/features/venue/domain/entities/venue.dart):

```
name_ar, name_en, name_ar_norm, name_en_norm,
lat, lng, city, categories, tags, all_tags,
min_price, max_price, currency, rating,
phone, instagram, whatsapp, facebook, website,
photos, menu_images, hours, is_24h,
partner, has_active_offers, transport_enabled,
transport_partner_ids, transport_notes_ar, transport_notes_en,
last_story_at, created_at, updated_at
```

**لا حذف أو تعديل** على أي حقل موجود.

---

## A2. خطة Migration / Backfill

### A2.1 القرار: Lazy Initialization + Optional One-time Backfill

| الخيار | المعتمد | السبب |
| --- | --- | --- |
| Migration مرة واحدة | ❌ | مكلف ولا يوجد حاجة عاجلة لتحديث كل المستندات |
| Backfill تدريجي | 🔄 اختياري | يمكن تشغيله لاحقاً كـ script لتنظيف المستندات |
| **Lazy initialization عند أول قراءة** | ✅ **معتمد** | كل كود يقرأ الجهة يعامل الحقل الغائب كقيمة افتراضية |

### A2.2 القيم الافتراضية للجهات الحالية

أي جهة لا تملك الحقول الجديدة تُعامل هكذا:

| الحقل | القيمة المفترضة عند الغياب |
| --- | --- |
| `subscription_status` | `active` |
| `visibility_status` | `visible` |
| `operational_status` | `active` |

**المنطق**: كل الجهات الموجودة حالياً تعمل وتظهر في التطبيق → إذن هي `active + visible + active` ضمنياً.

### A2.3 تعديل مطلوب على `venue.dart` (Flutter)

```dart
// حقول جديدة - كل منها اختياري مع default
@Default('active') String subscriptionStatus,
@Default('visible') String visibilityStatus,
@Default('active') String operationalStatus,
@JsonKey(name: 'admin_status_updated_at', fromJson: _toTimestamp, toJson: _timestampToJson)
  Timestamp? adminStatusUpdatedAt,
@JsonKey(name: 'admin_status_updated_by') String? adminStatusUpdatedBy,
```

بما أن كل حقل له `@Default`، الجهات القديمة **لن تنكسر** عند deserialization.

### A2.4 تعديل مطلوب على `venue-directory-models.ts` (Admin Console)

```typescript
// يُضاف على VenueDirectoryItem
subscriptionStatus: "active" | "expired" | "paused";
visibilityStatus: "visible" | "hidden";
operationalStatus: "active" | "suspended" | "archived";
```

مع fallback parsing: إذا الحقل `undefined` → يأخذ القيمة الافتراضية.

---

## A3. مصفوفة الصلاحيات النهائية (Policy Matrix)

### A3.1 الأوامر والأدوار

| الأمر | `super_admin` | `content_admin` | `finance_admin` | `support_admin` | `ops_viewer` |
| --- | --- | --- | --- | --- | --- |
| `view_venues` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `create_venue` | ✅ | ❌ | ❌ | ❌ | ❌ |
| `edit_venue_profile` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `change_visibility` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `change_operational_status` | ✅ | ❌ | ❌ | ❌ | ❌ |
| `change_subscription_status` | ✅ | ❌ | ❌ | ❌ | ❌ |

### A3.2 تبرير القرارات

- **`content_admin` يعدّل ملف الجهة ويتحكم بالظهور**: لأن الجهة جزء من المحتوى المعروض للمستخدم النهائي.
- **`content_admin` لا يغيّر حالة الاشتراك أو الحالة التشغيلية**: لأن هاي قرارات إدارية/تعاقدية وليست قرارات محتوى.
- **`finance_admin` لا يكتب على الجهات**: لأن الجهة ليست كياناً مالياً — العمليات المالية تتم على المحفظة.
- **`support_admin` و `ops_viewer` قراءة فقط**.

### A3.3 Capabilities المطلوب إضافتها لـ `admin-contract.ts`

```typescript
export const VENUE_MANAGEMENT_CAPABILITY_KEYS = [
  "view_venues",
  "create_venue",
  "edit_venue_profile",
  "change_venue_visibility",
  "change_venue_operational_status",
  "change_venue_subscription_status",
] as const;
```

---

## A4. مصفوفة سلوك التطبيق (App Behavior Matrix)

### A4.1 تأثير الحالة على التطبيق العميل (Flutter)

| `visibility_status` | `operational_status` | `subscription_status` | تظهر بالخريطة | تظهر بالبحث | صفحة الجهة قابلة للفتح | العروض تظهر | يمكن للتاجر إدارتها |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `visible` | `active` | `active` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `visible` | `active` | `expired` | ✅ | ✅ | ✅ | ✅ | ⚠️ محدود |
| `visible` | `active` | `paused` | ✅ | ✅ | ✅ | ❌ | ⚠️ محدود |
| `hidden` | `active` | `active` | ❌ | ❌ | ❌ | ❌ | ✅ |
| `hidden` | `active` | أي قيمة | ❌ | ❌ | ❌ | ❌ | ⚠️ حسب الاشتراك |
| أي قيمة | `suspended` | أي قيمة | ❌ | ❌ | ❌ | ❌ | ❌ |
| أي قيمة | `archived` | أي قيمة | ❌ | ❌ | ❌ | ❌ | ❌ |

### A4.2 قاعدة الأولوية

```
إذا operational_status == "suspended" أو "archived" → الجهة محجوبة كلياً (أعلى أولوية)
وإلا إذا visibility_status == "hidden" → الجهة مخفية عن المستخدم النهائي
وإلا → الجهة ظاهرة حسب subscription_status
```

### A4.3 تأثير على العروض والقصص المرتبطة

| سيناريو | العروض القائمة | القصص القائمة | المراجعات |
| --- | --- | --- | --- |
| الجهة `hidden` | لا تظهر في feeds المستخدم | لا تظهر | تبقى موجودة بس ما تظهر |
| الجهة `suspended` | لا تظهر ولا تُنفذ | لا تظهر | تبقى لأغراض التدقيق |
| الجهة `archived` | لا تظهر ولا تُنفذ | لا تظهر | تبقى لأغراض التدقيق |

**ملاحظة**: لا يتم **حذف** أي عرض أو قصة عند تغيير حالة الجهة. فقط يتغير الظهور.

### A4.4 تأثير على لوحة الأدمن

كل الجهات تظهر في دليل الجهات بالأدمن **بغض النظر عن حالتها** — مع badge واضح يوضح الحالة.

---

## A5. عقود الأوامر (Command Contracts)

### A5.1 النمط المعتمد

نستخدم **نفس بنية Finance Command Contracts** المعتمدة في المشروع:

- `commandId` + `correlationId` لكل أمر
- `expectedState` للأوامر الحساسة
- `reason` إلزامي لتغيير الحالة
- idempotency: `same_command_same_payload_returns_original`

### A5.2 عقد `create_venue`

```typescript
interface CreateVenueCommand {
  commandId: string;
  correlationId: string;
  submittedAt: string;
  // الحقول الإلزامية
  nameAr: string;
  city: string;
  categories: string[];
  // الحقول الاختيارية في V1
  nameEn?: string;
  phone?: string;
  lat?: number;
  lng?: number;
  // الحالة الأولية — يحددها السيرفر وليس الواجهة
}
```

**ملاحظة**: `subscription_status`, `visibility_status`, `operational_status` لا تُرسل من الواجهة عند الإنشاء. السيرفر يبدأهم كـ `active + visible + active`.

### A5.3 عقد `update_venue_profile`

```typescript
interface UpdateVenueProfileCommand {
  commandId: string;
  correlationId: string;
  submittedAt: string;
  venueId: string;
  reason: string;
  updates: {
    nameAr?: string;
    nameEn?: string;
    city?: string;
    categories?: string[];
    phone?: string;
  };
  expectedState: {
    operational_status: "active"; // لا يسمح بتعديل جهة suspended/archived
  };
}
```

### A5.4 عقد `update_venue_visibility`

```typescript
interface UpdateVenueVisibilityCommand {
  commandId: string;
  correlationId: string;
  submittedAt: string;
  venueId: string;
  reason: string;
  newVisibility: "visible" | "hidden";
  expectedState: {
    current_visibility: "visible" | "hidden";  // conflict check
    operational_status: "active";                // لا يسمح بتغيير ظهور جهة suspended
  };
}
```

### A5.5 عقد `update_venue_operational_status`

```typescript
interface UpdateVenueOperationalStatusCommand {
  commandId: string;
  correlationId: string;
  submittedAt: string;
  venueId: string;
  reason: string; // إلزامي دائماً
  newStatus: "active" | "suspended" | "archived";
  expectedState: {
    current_operational_status: "active" | "suspended" | "archived";
  };
}
```

### A5.6 عقد `update_venue_subscription_status`

```typescript
interface UpdateVenueSubscriptionStatusCommand {
  commandId: string;
  correlationId: string;
  submittedAt: string;
  venueId: string;
  reason: string; // إلزامي دائماً
  newStatus: "active" | "expired" | "paused";
  expectedState: {
    current_subscription_status: "active" | "expired" | "paused";
  };
}
```

### A5.7 الاستجابة الموحدة

```typescript
interface VenueCommandResult {
  success: boolean;
  commandId: string;
  venueId: string;
  action: string;
  newState: Record<string, string>;
  auditEventId: string;
  replay?: boolean;  // true إذا كان الأمر مكرراً (idempotent replay)
}
```

---

## A6. أحداث التدقيق (Audit Events)

كل أمر يُنشئ حدث تدقيق في `venue_admin_events/{eventId}`:

```typescript
{
  eventId: string;
  eventType: "venue_created" | "venue_profile_updated" | "venue_visibility_changed"
             | "venue_operational_status_changed" | "venue_subscription_status_changed";
  venueId: string;
  actorUid: string;
  actorRole: string;
  commandId: string;
  reason: string;
  previousState: Record<string, unknown>;
  newState: Record<string, unknown>;
  timestamp: Timestamp;
}
```

---

## A7. الحقول الإلزامية vs الاختيارية في V1

### A7.1 عند الإنشاء (`create_venue`)

| الحقل | إلزامي | ملاحظة |
| --- | --- | --- |
| `name_ar` | ✅ | اسم الجهة بالعربي — الحد الأدنى لتعريف الجهة |
| `name_en` | ❌ | اختياري في V1، يمكن إضافته لاحقاً عبر تعديل |
| `city` | ✅ | مطلوب للتصفية والبحث |
| `categories` | ✅ | واحد على الأقل مطلوب |
| `phone` | ❌ | اختياري عند الإنشاء، **يُطلب عند تفعيل الظهور** |
| `lat / lng` | ❌ | ليست إلزامية لحظة الإنشاء |

### A7.2 شرط الظهور (Pre-visibility Gate)

قبل ما الجهة تصبح `visible`، السيرفر يتحقق من:
- `name_ar` موجود
- `city` موجود
- `categories` غير فارغ
- `phone` موجود (إذا تم اعتماد هذا الشرط)

إذا أي شرط مفقود → السيرفر يرفض `update_venue_visibility` بخطأ `validation_error`.

### A7.3 الإحداثيات (`lat/lng`)

- **لا تُطلب يدوياً كأرقام خام** عند الإنشاء.
- في V1: تُترك فارغة (`0.0, 0.0`) عند الإنشاء.
- في V2 أو تحسين لاحق: يُضاف map picker أو geocoding مبني على المدينة.
- الجهة بدون إحداثيات **لا تظهر على الخريطة** لكن تظهر في البحث النصي.

---

## A8. ملخص القرارات الملزمة

| البند | القرار | مُقفل |
| --- | --- | --- |
| موقع الحقول الجديدة | على `venues/{venueId}` مباشرة | ✅ |
| استراتيجية Migration | Lazy initialization + backfill اختياري | ✅ |
| القيم الافتراضية | `active + visible + active` | ✅ |
| `finance_admin` على الجهات | قراءة فقط، لا كتابة | ✅ |
| `content_admin` | يعدّل الملف ويتحكم بالظهور فقط | ✅ |
| `create_venue` حصري لـ `super_admin` | ✅ | ✅ |
| أوامر status حصرية لـ `super_admin` | operational + subscription | ✅ |
| `name_ar` إلزامي عند الإنشاء | ✅ | ✅ |
| `name_en` اختياري في V1 | ✅ | ✅ |
| `lat/lng` ليست إلزامية عند الإنشاء | ✅ | ✅ |
| `phone` اختياري عند الإنشاء، مطلوب للظهور | ✅ | ✅ |
| لا hard delete | ✅ | ✅ |
| لا menu editing في V1 | ✅ | ✅ |
| Audit على كل أمر | ✅ | ✅ |
| Idempotency على كل أمر | ✅ | ✅ |

---

## A9. الحالة

- **Phase A Status**: `done`
- **جاهز لبدء Phase B**: ✅ نعم، بعد مراجعة هذا المستند والموافقة عليه.
