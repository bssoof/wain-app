// Finance read-model formatters

const ARABIC_DATE_LOCALE = "ar-PS-u-nu-latn";
const ARABIC_DATE_TIME_ZONE = "UTC";

type ArabicDateFormatOptions = {
  dateOnly?: boolean;
};

export function formatCurrency(amount: number, currency: string): string {
  return new Intl.NumberFormat(ARABIC_DATE_LOCALE, {
    style: "currency",
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

export function formatArabicDate(
  isoDate: string,
  options: ArabicDateFormatOptions = {},
): string {
  const date = new Date(isoDate);
  if (Number.isNaN(date.getTime())) {
    return "غير متاح";
  }

  if (options.dateOnly) {
    return new Intl.DateTimeFormat(ARABIC_DATE_LOCALE, {
      month: "short",
      day: "numeric",
      year: "numeric",
      timeZone: ARABIC_DATE_TIME_ZONE,
    }).format(date);
  }

  return new Intl.DateTimeFormat(ARABIC_DATE_LOCALE, {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
    timeZone: ARABIC_DATE_TIME_ZONE,
  }).format(date);
}

export function formatDate(isoDate: string): string {
  return formatArabicDate(isoDate);
}

export function formatStatus(status: string): string {
  const normalized = status.replace(/[_-]+/g, " ").trim().toLowerCase();
  if (!normalized) {
    return "غير معروف";
  }

  const labels: Record<string, string> = {
    active: "نشط",
    archived: "مؤرشف",
    approved: "معتمد",
    approved_and_executed: "معتمد ومنفذ",
    "approved and executed": "معتمد ومنفذ",
    blocked: "محظور",
    conflict: "تعارض",
    created: "تم الإنشاء",
    credit: "إضافة",
    credited: "مقيّد",
    dashboard: "نظرة عامة",
    debit: "خصم",
    draft: "مسودة",
    drafted: "تمت المسودة",
    empty: "لا توجد بيانات",
    expired: "منتهي",
    fail: "فشل",
    flagged: "عليه علامة",
    forbidden: "غير مسموح",
    hidden: "مخفي",
    inactive: "غير نشط",
    linked: "مرتبط",
    "low balance": "رصيد منخفض",
    low_balance: "رصيد منخفض",
    media: "الصور والملفات",
    "pending second approval": "ينتظر الموافقة الثانية",
    pending_second_approval: "ينتظر الموافقة الثانية",
    pass: "سليم",
    paused: "موقوف",
    pending: "قيد الانتظار",
    published: "منشور",
    ready: "جاهز",
    rejected: "مرفوض",
    reversals: "طلبات عكس العمليات",
    reviews: "المراجعات",
    reviewed: "تمت المراجعة",
    reversal: "عكس عملية",
    stories: "القصص",
    stale: "بيانات قديمة",
    suspended: "معلّق",
    success: "ناجح",
    system: "النظام",
    topups: "طلبات الشحن",
    unavailable: "غير متاح",
    unauthorized: "غير مصرّح",
    unlinked: "غير مرتبط",
    unknown: "غير معروف",
    updated: "تم التحديث",
    visible: "ظاهر",
    venues: "الجهات",
    wallet: "المحفظة",
    warn: "تحذير",
    warning: "تحذير",
    offers: "العروض",
  };

  if (labels[normalized]) {
    return labels[normalized];
  }

  // Keep end-user copy Arabic even when upstream introduces a new latin status key.
  if (/^[a-z0-9 ]+$/.test(normalized)) {
    return "غير معروف";
  }

  return normalized;
}

export function getStatusColorClass(status: string):
  | "status-success"
  | "status-warning"
  | "status-danger"
  | "status-neutral" {
  const normalized = status.trim().toLowerCase();

  if (
    normalized === "credited" ||
    normalized === "approved" ||
    normalized === "approved_and_executed" ||
    normalized === "pass" ||
    normalized === "ready" ||
    normalized === "visible"
  ) {
    return "status-success";
  }

  if (
    normalized === "pending" ||
    normalized === "warn" ||
    normalized === "warning" ||
    normalized === "unavailable" ||
    normalized === "conflict"
  ) {
    return "status-warning";
  }

  if (
    normalized === "expired" ||
    normalized === "rejected" ||
    normalized === "fail" ||
    normalized === "blocked" ||
    normalized === "forbidden" ||
    normalized === "suspended" ||
    normalized === "archived" ||
    normalized === "unauthorized"
  ) {
    return "status-danger";
  }

  return "status-neutral";
}
