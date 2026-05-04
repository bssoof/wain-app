import { Suspense } from "react";

import { requireRouteAccess } from "@/lib/auth/route-guards";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";
import { loadDashboardSummary } from "@/lib/dashboard/dashboard-loader";
import type { OpsDashboardSummary } from "@/lib/dashboard/dashboard-models";
import { OperationalDashboardShell } from "@/components/dashboard/operational-dashboard-shell";

export const dynamic = "force-dynamic";

export default async function AdminDashboardPage() {
  const route = getRouteDefinition("dashboard");
  await requireRouteAccess(route.key, route.path);

  return (
    <div className="admin-page-shell" dir="rtl" lang="ar">
      <Suspense fallback={<OperationalDashboardShell summary={buildLoadingSummary()} />}>
        <DashboardSummaryContent />
      </Suspense>
    </div>
  );
}

async function DashboardSummaryContent() {
  const summary = await loadDashboardSummary();
  return <OperationalDashboardShell summary={summary} />;
}

function buildLoadingSummary(): OpsDashboardSummary {
  const nowIso = new Date().toISOString();

  return {
    generatedAt: nowIso,
    topUpQueue: {
      state: "empty",
      asOf: nowIso,
      source: "dashboard_streaming_fallback",
      message: "جاري تحميل ملخص طلبات الشحن...",
      data: null,
    },
    walletReadiness: {
      state: "empty",
      asOf: nowIso,
      source: "dashboard_streaming_fallback",
      message: "جاري تحميل حالة النظام...",
      data: null,
    },
    venueDirectory: {
      state: "empty",
      asOf: nowIso,
      source: "dashboard_streaming_fallback",
      message: "جاري تحميل ملخص الجهات...",
      data: null,
    },
    contentModeration: {
      state: "empty",
      asOf: nowIso,
      source: "dashboard_streaming_fallback",
      message: "جاري تحميل ملخص المحتوى...",
      data: null,
    },
  };
}
