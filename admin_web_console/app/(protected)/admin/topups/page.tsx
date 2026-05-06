import { FinanceReadStateBanner } from "@/components/finance/finance-read-banner";
import {
  TopUpQueueActions,
  TopUpQueueTable,
} from "@/components/finance/topup-queue-table";
import { FinanceCommandProvider } from "@/components/finance/finance-command-provider";
import { PageHeader } from "@/components/shared/ui/page-header";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import { loadTopUpQueueRead } from "@/lib/finance/finance-read-loader";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";

export const dynamic = "force-dynamic";

export default async function TopUpsPage() {
  const route = getRouteDefinition("topups");
  const session = await requireRouteAccess(route.key, route.path);
  const topUpRead = await loadTopUpQueueRead();
  const pending = topUpRead.kind === "success" ? topUpRead.data.pending : [];
  const canExport = session.roles.some(
    (role) => role === "finance_admin" || role === "super_admin",
  );

  return (
    <div className="admin-page-shell">
      <PageHeader
        title="عمليات الشحن"
        description="إدارة طلبات شحن المحفظة"
        actions={<TopUpQueueActions canExport={canExport} pending={pending} />}
      />
      <FinanceReadStateBanner result={topUpRead} label="قراءة طلبات الشحن" />
      <FinanceCommandProvider session={session}>
        <TopUpQueueTable readResult={topUpRead} />
      </FinanceCommandProvider>
    </div>
  );
}
