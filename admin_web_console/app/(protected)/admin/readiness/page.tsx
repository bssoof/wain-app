import { FinanceAdminPageShell } from "@/components/finance/finance-admin-page-shell";
import { FinanceReadStateBanner } from "@/components/finance/finance-read-banner";
import {
  ReadinessChecksPanel,
  ReadinessCommandPanel,
  ReadinessReportCard,
} from "@/components/finance/readiness-panel";
import { FinanceCommandProvider } from "@/components/finance/finance-command-provider";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import { loadReadinessRead } from "@/lib/finance/finance-read-loader";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";

export default async function ReadinessPage() {
  const route = getRouteDefinition("readiness");
  const session = await requireRouteAccess(route.key, route.path);
  const readinessRead = await loadReadinessRead();

  return (
    <FinanceAdminPageShell
      title={route.title}
      scopeNote={route.scopeNote}
      readBanner={
        <FinanceReadStateBanner result={readinessRead} label="قراءة حالة النظام" />
      }
    >
      <FinanceCommandProvider session={session}>
        <ReadinessReportCard readResult={readinessRead} />
        <ReadinessCommandPanel />
        <ReadinessChecksPanel readResult={readinessRead} session={session} />
      </FinanceCommandProvider>
    </FinanceAdminPageShell>
  );
}
