import { formatArabicDate } from "@/lib/finance/read-model-formatters";

const ADMIN_LABELS: Record<string, string> = {
  success: "ناجح",
  stale: "بيانات قديمة",
  empty: "لا توجد بيانات",
  unavailable: "غير متاح",
  unknown: "غير معروف",
  idle: "جاهز",
  pending: "قيد التنفيذ",
  conflict: "تعارض",
  blocked: "محظور",
  none: "لا يوجد",
  active: "نشط",
  inactive: "غير نشط",
  wallet: "المحفظة",
  offers: "العروض",
  stories: "القصص",
  reviews: "المراجعات",
  topups: "طلبات الشحن",
  reversals: "طلبات عكس العمليات",
  dashboard: "نظرة عامة",
  readiness: "حالة النظام",
  venues: "الجهات",
  media: "الصور والملفات",
  content: "المحتوى",
  content_offers: "العروض",
  content_stories: "القصص",
  reviews_moderation: "المراجعات",
  config: "الإعدادات",
  wallet_audit: "سجل المحفظة",
  system: "النظام",
  approve: "اعتماد",
  reject: "رفض",
  flag: "وضع علامة",
  pause: "إيقاف",
  drafted: "تمت المسودة",
  reviewed: "تمت المراجعة",
  published: "منشور",
  flagged: "عليه علامة",
  hidden: "مخفي",
  approved: "معتمد",
  rejected: "مرفوض",
  paused: "موقوف",
  manual_review: "يحتاج مراجعة",
  spam: "رسائل مزعجة",
  abusive_language: "لغة مسيئة",
  off_topic: "خارج الموضوع",
  privacy_request: "طلب خصوصية",
  legal_request: "طلب قانوني",
  duplicate: "مكرر",
  appeal_approved: "استئناف مقبول",
  policy_violation: "انتهاك السياسة",
  inappropriate_content: "محتوى غير لائق",
  merchant_request: "طلب التاجر",
  quality_standard: "معايير الجودة",
  other: "أخرى",
  development_fixture: "بيانات محلية للتجربة",
  fixture: "بيانات تجريبية",
  snapshot: "لقطة بيانات",
  admin_list_callable: "قراءة مباشرة من الخدمة",
  firestore_fallback: "قاعدة البيانات الاحتياطية",
  fixture_fallback: "بيانات تجريبية احتياطية",
  fixture_fallback_disabled: "بيانات التجربة معطلة",
  unknown_source: "مصدر غير معروف",
  media_center_unavailable: "تعذر تحميل مركز الصور والملفات",
  venue_workspace_unavailable: "تعذر تحميل مساحة عمل الجهة",
  venue_directory_forced_unavailable: "تعطيل قراءة دليل الجهات",
  dashboard_loader: "ملخص النظرة العامة",
  review_publish: "نشر",
  review_hide: "إخفاء",
  review_escalate: "إرسال للمراجعة",
  config_upsert_draft: "حفظ المسودة",
  config_review_draft: "اعتماد المراجعة",
  publish_config: "نشر الإعدادات",
  rollback_config: "استرجاع الإعدادات",
  config_published: "نشر الإعدادات",
  config_rolled_back: "استرجاع الإعدادات",
  config_rollback: "استرجاع الإعدادات",
  media_soft_delete: "إخفاء الملف",
  media_quarantine: "عزل الملف",
  media_reference_check: "فحص الارتباط",
  media_purge: "الحذف النهائي",
  view_dashboard: "عرض النظرة العامة",
  view_topups: "عرض طلبات الشحن",
  approve_topup: "اعتماد طلب الشحن",
  reject_topup: "رفض طلب الشحن",
  view_wallet_audit: "عرض سجل المحفظة",
  create_reversal: "طلب تصحيح عملية",
  approve_reversal: "اعتماد طلب التصحيح",
  view_venues: "عرض الجهات",
  create_venue: "إنشاء جهة",
  edit_venue_profile: "تعديل ملف الجهة",
  change_venue_visibility: "تغيير الظهور",
  change_venue_operational_status: "تغيير الحالة التشغيلية",
  change_venue_subscription_status: "تغيير حالة الاشتراك",
  view_readiness: "عرض حالة النظام",
  view_media: "عرض الصور والملفات",
  view_reviews_moderation: "عرض المراجعات",
  offer_approve: "اعتماد العرض",
  offer_reject: "رفض العرض",
  offer_flag: "وضع علامة على العرض",
  offer_pause: "إيقاف العرض",
  story_approve: "اعتماد القصة",
  story_reject: "رفض القصة",
  story_flag: "وضع علامة على القصة",
  story_pause: "إيقاف القصة",
  view_config_governance: "عرض إعدادات التطبيق",
  config_draft_write: "تعديل المسودة",
  config_review: "مراجعة الإعدادات",
  commandid: "رمز منع التكرار",
  suspended: "معلّق",
  archived: "مؤرشف",
  expired: "منتهي",
  visible: "ظاهر",
  super_admin: "مسؤول أعلى",
  finance_admin: "مسؤول مالي",
  content_admin: "مسؤول محتوى",
  support_admin: "مسؤول دعم",
  ops_viewer: "مشاهد عمليات",
  "local admin": "مسؤول محلي",
  "admin operator": "مشغّل إداري",
};

export function localizeAdminLabel(value: string | null | undefined): string {
  if (!value) {
    return "غير متاح";
  }

  if (value.includes(" -> ")) {
    return value
      .split(" -> ")
      .map((part) => localizeAdminLabel(part))
      .join(" ← ");
  }

  if (value.includes(" / ")) {
    return value
      .split(" / ")
      .map((part) => localizeAdminLabel(part))
      .join(" / ");
  }

  const normalized = value.trim().toLowerCase();

  if (normalized.startsWith("callable:")) {
    return "الخدمة المتصلة";
  }

  if (normalized.startsWith("http:")) {
    return "اتصال مباشر بالخدمة";
  }

  if (normalized.startsWith("firestore:")) {
    return "قاعدة البيانات";
  }

  if (normalized.startsWith("missing_surface:")) {
    return "مصدر غير مهيأ";
  }

  if (/^[a-z0-9_-]+(\/[a-z0-9_-]+)+$/.test(normalized)) {
    return normalized
      .split("/")
      .map((part) => localizeAdminLabel(part))
      .join(" / ");
  }

  const directLabel = ADMIN_LABELS[normalized];
  if (directLabel) {
    return directLabel;
  }

  const tokenized = normalized.split(/[_\s-]+/).filter(Boolean);
  if (tokenized.length > 1) {
    const localizedTokens = tokenized.map((token) => ADMIN_LABELS[token]);
    if (localizedTokens.every(Boolean)) {
      return localizedTokens.join(" ");
    }
  }

  if (/^[a-z0-9_:\- ]+$/.test(normalized)) {
    return "غير معروف";
  }

  return value;
}

export function localizeAdminFreshnessNote(note: string | null | undefined): string {
  if (!note) {
    return "حداثة البيانات غير معروفة.";
  }

  if (/[\u0600-\u06ff]/.test(note)) {
    return note;
  }

  const normalized = note.trim().toLowerCase();

  if (
    normalized.includes("older than expected") ||
    normalized.includes("older than the configured freshness window") ||
    normalized === "fixture is stale." ||
    normalized.includes("is stale")
  ) {
    return "البيانات قديمة مقارنة بالوقت المتوقع.";
  }

  if (
    normalized.includes("within the expected freshness window") ||
    normalized.includes("is fresh") ||
    normalized.includes("current enough")
  ) {
    return "البيانات ضمن نافذة الحداثة المتوقعة.";
  }

  if (normalized.includes("no rows")) {
    return "لم تُرجع اللقطة الحالية أي صفوف.";
  }

  if (normalized.includes("source unavailable") || normalized === "unavailable") {
    return "مصدر البيانات غير متاح.";
  }

  if (normalized.includes("loaded directly from firestore")) {
    return "تم تحميل البيانات مباشرة من قاعدة البيانات.";
  }

  if (normalized.includes("fixture data is stale")) {
    return "البيانات التجريبية قديمة مقارنة بالوقت المتوقع.";
  }

  if (normalized.includes("fixture data is being used")) {
    return "يتم عرض بيانات تجريبية مؤقتة.";
  }

  return "معلومة حداثة البيانات غير متاحة حاليًا.";
}

export function localizeAdminMessage(message: string | null | undefined): string | undefined {
  if (!message) {
    return undefined;
  }

  if (/[\u0600-\u06ff]/.test(message)) {
    return message;
  }

  const normalized = message.trim().toLowerCase();

  if (normalized.includes("dashboard_widget_timeout:")) {
    return "انتهت مهلة تحميل أحد أقسام لوحة المؤشرات.";
  }

  if (normalized.includes("queue data is stale")) {
    return "بيانات الطوابير قديمة مقارنة بالوقت المتوقع.";
  }

  if (normalized.includes("readiness report is stale")) {
    return "تقرير الجاهزية قديم مقارنة بالوقت المتوقع.";
  }

  if (normalized.includes("venue directory read is stale")) {
    return "بيانات دليل الجهات قديمة مقارنة بالوقت المتوقع.";
  }

  if (normalized.includes("content moderation backlog is stale")) {
    return "بيانات انتظار مراجعة المحتوى قديمة مقارنة بالوقت المتوقع.";
  }

  if (normalized.includes("venue directory read is unavailable")) {
    return "قراءة دليل الجهات غير متاحة حاليًا.";
  }

  if (normalized.includes("venue workspace read is unavailable")) {
    return "قراءة مساحة عمل الجهة غير متاحة حاليًا.";
  }

  if (normalized.includes("venue directory callable read failed")) {
    return "تعذر جلب دليل الجهات من الخدمة المتصلة.";
  }

  if (normalized.includes("venue directory firestore read failed")) {
    return "تعذر جلب دليل الجهات من قاعدة البيانات.";
  }

  if (normalized.includes("venue directory fetch failed")) {
    return "تعذر تنزيل بيانات دليل الجهات من المصدر.";
  }

  if (normalized.includes("snapshot is missing an items or venues array")) {
    return "البيانات الواردة ناقصة: لا توجد قائمة جهات.";
  }

  if (normalized.includes("snapshot rows must be objects")) {
    return "تنسيق صفوف البيانات غير صالح.";
  }

  if (normalized.includes("snapshot contained an item without venue id")) {
    return "بعض صفوف البيانات تفتقد معرّف الجهة.";
  }

  if (normalized.includes("not a valid json object")) {
    return "صيغة البيانات الواردة غير صالحة.";
  }

  if (normalized.includes("response was not a json object")) {
    return "صيغة البيانات الواردة غير صالحة.";
  }

  if (normalized.includes("reviews moderation surface is using fixture data")) {
    return "يتم عرض بيانات تجريبية للمراجعات مؤقتًا.";
  }

  if (normalized.includes("reviews callable read failed")) {
    return "تعذر جلب بيانات المراجعات من الخدمة المتصلة.";
  }

  if (normalized.includes("no reviews matched the current moderation surface")) {
    return "لا توجد مراجعات مطابقة للعرض الحالي.";
  }

  if (normalized.includes("no review snippet available")) {
    return "لا يوجد نص مختصر لهذه المراجعة.";
  }

  if (normalized.includes("config governance surface is using fixture data")) {
    return "يتم عرض بيانات تجريبية للإعدادات مؤقتًا.";
  }

  if (normalized.includes("config governance callable read failed")) {
    return "تعذر جلب بيانات الإعدادات من الخدمة المتصلة.";
  }

  if (normalized.includes("content moderation read is unavailable")) {
    return "قراءة إدارة المحتوى غير متاحة حاليًا.";
  }

  if (normalized.includes("app check verification failed")) {
    return "تعذر التحقق من أمان الطلب الحالي.";
  }

  if (
    (normalized.includes("app check token") ||
      normalized.includes("app_check_token")) &&
    normalized.includes("placeholder")
  ) {
    return "توكن أمان الطلب الحالي تجريبي، لذلك لا يمكن تنفيذ القرار على الخدمة الحية.";
  }

  if (
    (normalized.includes("app check token") ||
      normalized.includes("app_check_token")) &&
    normalized.includes("not configured")
  ) {
    return "توكن أمان الطلب غير مضبوط، لذلك لا يمكن تنفيذ القرار على الخدمة الحية.";
  }

  if (normalized.includes("content moderation transport is not connected")) {
    return "اتصال إدارة المحتوى غير مهيأ.";
  }

  if (normalized.includes("workspace context is in fallback mode")) {
    return "بيانات مساحة العمل تعمل بوضع احتياطي مؤقت.";
  }

  if (normalized.includes("workspace context is available from the admin read surface")) {
    return "بيانات مساحة العمل متاحة من القراءة الإدارية.";
  }

  if (normalized.includes("non-object response")) {
    return "الاستجابة القادمة من الخدمة غير صالحة.";
  }

  if (normalized.includes("promise rejected or crashed")) {
    return "فشل تحميل هذا القسم بسبب خطأ غير متوقع.";
  }

  if (normalized.includes("transport is not connected")) {
    return "اتصال الخدمة غير مهيأ.";
  }

  if (normalized.includes("no mock data present")) {
    return "لا توجد بيانات تجريبية حاليًا.";
  }

  if (normalized.includes("transport is unavailable")) {
    return "الاتصال بالخدمة غير متاح.";
  }

  if (
    normalized.includes("reference index") &&
    normalized.includes("stale")
  ) {
    return "فهرس المراجع قديم، لذلك تبقى إجراءات الحذف النهائي محظورة حاليًا.";
  }

  if (
    normalized.includes("reference index") &&
    normalized.includes("healthy")
  ) {
    return "فهرس المراجع سليم ويمكن الاعتماد عليه.";
  }

  if (normalized.includes("purge blocked")) {
    return "الحذف النهائي محظور حتى تصبح حالة فهرس المراجع سليمة.";
  }

  if (normalized.includes("not mapped to a callable surface yet")) {
    return "لا توجد خدمة مربوطة لهذا الإجراء بعد.";
  }

  if (normalized.includes("forbidden")) {
    return "تم رفض الوصول إلى هذا المصدر.";
  }

  if (normalized.includes("venue_phone_required_for_visibility")) {
    return "لا يمكن إظهار الجهة قبل إضافة رقم هاتف صالح.";
  }

  if (normalized.includes("venue_expected_state_conflict")) {
    return "تعذر تنفيذ العملية لأن حالة الجهة تغيّرت قبل اعتماد الطلب.";
  }

  if (normalized.includes("venue_profile_inactive")) {
    return "لا يمكن تعديل ملف جهة غير نشطة تشغيليًا.";
  }

  if (normalized.includes("venue_expected_state_required")) {
    return "الطلب يحتاج بيانات الحالة الحالية كاملة قبل تنفيذ التعديل.";
  }

  if (normalized.includes("invalid_venue_visibility_status")) {
    return "قيمة حالة الظهور غير صالحة.";
  }

  if (normalized.includes("invalid_venue_operational_status")) {
    return "قيمة الحالة التشغيلية غير صالحة.";
  }

  if (normalized.includes("invalid_venue_subscription_status")) {
    return "قيمة حالة الاشتراك غير صالحة.";
  }

  if (normalized.includes("venue_already_in_target_state")) {
    return "الجهة موجودة أصلًا في الحالة المطلوبة.";
  }

  if (normalized.includes("review_already_in_target_state")) {
    return "المراجعة موجودة أصلًا في الحالة المطلوبة.";
  }

  if (normalized.includes("review_moderation_expected_state_conflict")) {
    return "تعذر تنفيذ القرار لأن حالة المراجعة تغيّرت قبل اعتماد الطلب.";
  }

  if (normalized.includes("review_moderation_reason_invalid")) {
    return "سبب القرار غير صالح، اختر سببًا معتمدًا ثم أعد المحاولة.";
  }

  if (normalized.includes("review_target_requires_venue_and_review_id")) {
    return "بيانات المراجعة ناقصة: يلزم معرّف الجهة ومعرّف المراجعة.";
  }

  if (normalized.includes("missing_required_venue_fields")) {
    return "بعض الحقول الأساسية للجهة مفقودة.";
  }

  if (normalized.includes("source unavailable")) {
    return "مصدر البيانات غير متاح.";
  }

  if (normalized.includes(" is stale") || normalized.endsWith("stale.")) {
    return "البيانات قديمة مقارنة بالوقت المتوقع.";
  }

  if (normalized.includes("unavailable")) {
    return "الخدمة غير متاحة حاليًا.";
  }

  if (normalized.includes("timed out")) {
    return "انتهت مهلة المصدر.";
  }

  if (normalized === "config_live_version_conflict") {
    return "تعارض في الإصدار المباشر للإعدادات.";
  }

  if (normalized.includes("promise rejected")) {
    return "فشل تحميل هذا القسم بسبب خطأ غير متوقع.";
  }

  if (/^[a-z0-9_:\-./ ]+$/.test(normalized)) {
    return "تعذر إكمال الطلب حاليًا.";
  }

  return "تعذر إكمال الطلب حاليًا.";
}

export function formatAdminDate(
  value: string | null | undefined,
  options?: {
    dateOnly?: boolean;
  },
): string {
  if (!value) {
    return "غير متاح";
  }

  return formatArabicDate(value, options);
}
