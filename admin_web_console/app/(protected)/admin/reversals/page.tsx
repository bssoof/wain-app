import { FinanceCommandProvider } from "@/components/finance/finance-command-provider";
import { ReversalApprovalPanel } from "@/components/finance/reversal-approval-panel";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";

export default async function AdminReversalsPage() {
  const route = getRouteDefinition("reversals");
  const session = await requireRouteAccess(route.key, route.path);

  return (
    <div className="admin-page-shell">
      <h1>{route.title}</h1>
      <p className="status-note">
        اعتماد طلبات تصحيح العمليات التي تحتاج موافقة ثانية.
      </p>

      <FinanceCommandProvider session={session}>
        <ReversalApprovalPanel />
      </FinanceCommandProvider>
    </div>
  );
}
