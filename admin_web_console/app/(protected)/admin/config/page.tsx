import { ConfigCommandProvider, ConfigGovernanceShell } from "@/components/config";
import { PageHeader } from "@/components/shared/ui/page-header";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import {
  computeConfigAffordances,
} from "@/lib/config";
import { loadConfigGovernanceSnapshot } from "@/lib/config/config-read-loader";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";

export default async function AdminConfigPage() {
  const route = getRouteDefinition("config");
  const session = await requireRouteAccess(route.key, route.path);
  const affordances = computeConfigAffordances(session);
  const snapshot = await loadConfigGovernanceSnapshot();

  return (
    <div className="admin-page-shell" dir="rtl" lang="ar">
      <PageHeader
        title={route.title}
        description={route.scopeNote}
        breadcrumb={[
          { label: "الإدارة", href: "/admin" },
          { label: "الإعدادات" },
        ]}
      />
      <ConfigCommandProvider session={session}>
        <ConfigGovernanceShell snapshot={snapshot} affordances={affordances} />
      </ConfigCommandProvider>
    </div>
  );
}
