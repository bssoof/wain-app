import { FinanceReadStateBanner } from "@/components/finance/finance-read-banner";
import {
  WalletAuditActions,
  WalletAuditTable,
} from "@/components/finance/wallet-audit-table";
import { FinanceCommandProvider } from "@/components/finance/finance-command-provider";
import { PageHeader } from "@/components/shared/ui/page-header";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import { loadWalletLedgerRead } from "@/lib/finance/finance-read-loader";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";

export default async function WalletAuditPage() {
  const route = getRouteDefinition("wallet_audit");
  const session = await requireRouteAccess(route.key, route.path);
  const ledgerRead = await loadWalletLedgerRead();
  const entries = ledgerRead.kind === "success" ? ledgerRead.data.entries : [];
  const canExport = session.roles.some(
    (role) => role === "finance_admin" || role === "super_admin",
  );

  return (
    <div className="admin-page-shell">
      <PageHeader
        title="سجل المحفظة"
        description="مراجعة حركات المحفظة"
        actions={<WalletAuditActions canExport={canExport} entries={entries} />}
      />
      <FinanceReadStateBanner result={ledgerRead} label="قراءة سجل المحفظة" />
      <FinanceCommandProvider session={session}>
        <WalletAuditTable readResult={ledgerRead} />
      </FinanceCommandProvider>
    </div>
  );
}
