import { FinanceAdminPageShell } from "@/components/finance/finance-admin-page-shell";
import { FinanceReadStateBanner } from "@/components/finance/finance-read-banner";
import { TopUpQueueTable } from "@/components/finance/topup-queue-table";
import { FinanceCommandProvider } from "@/components/finance/finance-command-provider";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import { loadTopUpQueueRead } from "@/lib/finance/finance-read-loader";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";

export const dynamic = "force-dynamic";

export default async function TopUpsPage() {
  const route = getRouteDefinition("topups");
  const session = await requireRouteAccess(route.key, route.path);
  const topUpRead = await loadTopUpQueueRead();

  return (
    <FinanceAdminPageShell
      title={route.title}
      scopeNote={route.scopeNote}
      readBanner={
        <FinanceReadStateBanner result={topUpRead} label="قراءة طلبات الشحن" />
      }
    >
      <FinanceCommandProvider session={session}>
        <TopUpQueueTable readResult={topUpRead} />
      </FinanceCommandProvider>
    </FinanceAdminPageShell>
  );
}
