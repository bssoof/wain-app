import { FinanceAdminPageShell } from "@/components/finance/finance-admin-page-shell";
import { FinanceReadStateBanner } from "@/components/finance/finance-read-banner";
import { WalletAuditTable } from "@/components/finance/wallet-audit-table";
import { FinanceCommandProvider } from "@/components/finance/finance-command-provider";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import { loadWalletLedgerRead } from "@/lib/finance/finance-read-loader";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";

export default async function WalletAuditPage() {
  const route = getRouteDefinition("wallet_audit");
  const session = await requireRouteAccess(route.key, route.path);
  const ledgerRead = await loadWalletLedgerRead();

  return (
    <FinanceAdminPageShell
      title={route.title}
      scopeNote={route.scopeNote}
      readBanner={
        <FinanceReadStateBanner result={ledgerRead} label="قراءة سجل المحفظة" />
      }
    >
      <FinanceCommandProvider session={session}>
        <WalletAuditTable readResult={ledgerRead} />
      </FinanceCommandProvider>
    </FinanceAdminPageShell>
  );
}
