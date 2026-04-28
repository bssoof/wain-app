import { canAccessRoute, type AdminSession } from "@/lib/auth/guard-api";
import type {
  AdminCapabilityKey,
  AdminRoutePrefetchMode,
  AdminRouteKey,
} from "@/lib/navigation/admin-contract";

export type AdminSidebarGroupKey = "finance" | "content" | "system";

export type AdminSidebarRouteGroup = {
  key: AdminSidebarGroupKey;
  title: string;
  routes: AdminRouteDefinition[];
};

const ADMIN_SIDEBAR_GROUP_ORDER: readonly AdminSidebarGroupKey[] = [
  "finance",
  "content",
  "system",
];

const ADMIN_SIDEBAR_GROUP_TITLES: Record<AdminSidebarGroupKey, string> = {
  finance: "المالية",
  content: "المحتوى",
  system: "النظام",
};

export type AdminRouteDefinition = {
  key: AdminRouteKey;
  path: string;
  title: string;
  scopeNote: string;
  sidebarGroup: AdminSidebarGroupKey;
  navGroup: "Phase1" | "Phase4" | "Phase5" | "Phase6";
  routeCapability: AdminCapabilityKey | null;
  mutationCapabilities: AdminCapabilityKey[];
  prefetchMode: AdminRoutePrefetchMode;
};

export const ADMIN_ROUTE_MAP: AdminRouteDefinition[] = [
  {
    key: "dashboard",
    path: "/admin/dashboard",
    title: "نظرة عامة",
    scopeNote: "أهم الأرقام والتنبيهات التي تحتاج متابعة.",
    sidebarGroup: "finance",
    navGroup: "Phase1",
    routeCapability: "view_dashboard",
    mutationCapabilities: [],
    prefetchMode: "auto",
  },
  {
    key: "topups",
    path: "/admin/topups",
    title: "طلبات الشحن",
    scopeNote: "راجع طلبات الشحن واقبلها أو ارفضها حسب صلاحيتك.",
    sidebarGroup: "finance",
    navGroup: "Phase1",
    routeCapability: "view_topups",
    mutationCapabilities: ["approve_topup", "reject_topup"],
    prefetchMode: "auto",
  },
  {
    key: "wallet_audit",
    path: "/admin/wallet-audit",
    title: "سجل المحفظة",
    scopeNote: "تابع عمليات المحفظة والمبالغ والأسباب المرتبطة بها.",
    sidebarGroup: "finance",
    navGroup: "Phase1",
    routeCapability: "view_wallet_audit",
    mutationCapabilities: [],
    prefetchMode: "auto",
  },
  {
    key: "reversals",
    path: "/admin/reversals",
    title: "طلبات عكس العمليات",
    scopeNote: "راجع طلبات تصحيح العمليات التي تحتاج موافقة ثانية.",
    sidebarGroup: "finance",
    navGroup: "Phase1",
    routeCapability: "create_reversal",
    mutationCapabilities: ["create_reversal", "approve_reversal"],
    prefetchMode: "disabled",
  },
  {
    key: "venues",
    path: "/admin/venues",
    title: "الجهات",
    scopeNote:
      "إدارة الجهات وظهورها وحالة تشغيلها واشتراكها حسب الصلاحية.",
    sidebarGroup: "content",
    navGroup: "Phase1",
    routeCapability: "view_venues",
    mutationCapabilities: [
      "create_venue",
      "edit_venue_profile",
      "change_venue_visibility",
      "change_venue_operational_status",
      "change_venue_subscription_status",
    ],
    prefetchMode: "auto",
  },
  {
    key: "media",
    path: "/admin/media",
    title: "الصور والملفات",
    scopeNote:
      "عرض صور وملفات الجهات ومراجعة سلامة مراجعها وإجراءاتها.",
    sidebarGroup: "content",
    navGroup: "Phase4",
    routeCapability: "view_media",
    mutationCapabilities: [
      "media_soft_delete",
      "media_quarantine",
      "media_reference_check",
      "media_purge",
    ],
    prefetchMode: "hover-intent",
  },
  {
    key: "content_offers",
    path: "/admin/content/offers",
    title: "العروض",
    scopeNote:
      "مراجعة عروض الجهات واتخاذ قرار واضح: قبول أو رفض أو إيقاف.",
    sidebarGroup: "content",
    navGroup: "Phase5",
    routeCapability: "offer_approve",
    mutationCapabilities: [
      "offer_approve",
      "offer_reject",
      "offer_flag",
      "offer_pause",
    ],
    prefetchMode: "hover-intent",
  },
  {
    key: "content_stories",
    path: "/admin/content/stories",
    title: "القصص",
    scopeNote:
      "مراجعة قصص الجهات واتخاذ قرار واضح: قبول أو رفض أو إيقاف.",
    sidebarGroup: "content",
    navGroup: "Phase5",
    routeCapability: "story_approve",
    mutationCapabilities: [
      "story_approve",
      "story_reject",
      "story_flag",
      "story_pause",
    ],
    prefetchMode: "hover-intent",
  },
  {
    key: "reviews_moderation",
    path: "/admin/content/reviews",
    title: "المراجعات",
    scopeNote:
      "مراجعة تعليقات المستخدمين وإظهارها أو إخفاؤها أو إرسالها للمراجعة مع سبب واضح.",
    sidebarGroup: "content",
    navGroup: "Phase5",
    routeCapability: "view_reviews_moderation",
    mutationCapabilities: [
      "review_publish",
      "review_hide",
      "review_escalate",
    ],
    prefetchMode: "hover-intent",
  },
  {
    key: "config",
    path: "/admin/config",
    title: "إعدادات التطبيق",
    scopeNote:
      "تعديل مسودات الإعدادات ومراجعتها ونشرها أو استرجاع نسخة سابقة.",
    sidebarGroup: "system",
    navGroup: "Phase6",
    routeCapability: "view_config_governance",
    mutationCapabilities: [
      "config_draft_write",
      "config_review",
      "publish_config",
      "rollback_config",
    ],
    prefetchMode: "hover-intent",
  },
  {
    key: "readiness",
    path: "/admin/readiness",
    title: "حالة النظام",
    scopeNote: "فحص حالة خدمات المحفظة والتنبيه عند وجود مشكلة.",
    sidebarGroup: "finance",
    navGroup: "Phase1",
    routeCapability: "view_readiness",
    mutationCapabilities: [],
    prefetchMode: "auto",
  },
];

export function getVisibleNavigationRoutes(
  session: AdminSession,
): AdminRouteDefinition[] {
  return ADMIN_ROUTE_MAP.filter((route) => canAccessRoute(session, route.key));
}

export function getVisibleNavigationRouteGroups(
  session: AdminSession,
): AdminSidebarRouteGroup[] {
  const groupedRoutes: Record<AdminSidebarGroupKey, AdminRouteDefinition[]> = {
    finance: [],
    content: [],
    system: [],
  };

  for (const route of getVisibleNavigationRoutes(session)) {
    groupedRoutes[route.sidebarGroup].push(route);
  }

  return ADMIN_SIDEBAR_GROUP_ORDER
    .map((groupKey) => ({
      key: groupKey,
      title: ADMIN_SIDEBAR_GROUP_TITLES[groupKey],
      routes: groupedRoutes[groupKey],
    }))
    .filter((group) => group.routes.length > 0);
}

export function getRouteDefinition(routeKey: AdminRouteKey): AdminRouteDefinition {
  const route = ADMIN_ROUTE_MAP.find((candidate) => candidate.key === routeKey);
  if (!route) {
    throw new Error(`Unknown admin route key: ${routeKey}`);
  }
  return route;
}
