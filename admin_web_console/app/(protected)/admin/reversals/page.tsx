import { FinanceCommandProvider } from "@/components/finance/finance-command-provider";
import { ReversalApprovalPanel } from "@/components/finance/reversal-approval-panel";
import { PageHeader } from "@/components/shared/ui/page-header";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";

export default async function AdminReversalsPage() {
  const route = getRouteDefinition("reversals");
  const session = await requireRouteAccess(route.key, route.path);

  return (
    <div className="admin-page-shell">
      <PageHeader
        title="طلبات العكس"
        description="مراجعة طلبات عكس العمليات"
      />

      <FinanceCommandProvider session={session}>
        <ReversalApprovalPanel />
      </FinanceCommandProvider>
    </div>
  );
}
