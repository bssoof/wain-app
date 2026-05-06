import { OffersManagementShell } from "@/components/content/offers-management-shell";
import { ContentCommandProvider } from "@/components/content/content-command-provider";
import { PageHeader } from "@/components/shared/ui/page-header";
import { computeContentAffordances } from "@/lib/content/content-surface-affordances";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import { loadOfferModerationSnapshot } from "@/lib/content/content-read-loader";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";

export const dynamic = "force-dynamic";

export default async function AdminOffersPage() {
  const route = getRouteDefinition("content_offers");
  const session = await requireRouteAccess(route.key, route.path);
  const affordances = computeContentAffordances(session);
  const snapshot = await loadOfferModerationSnapshot();

  return (
    <div className="admin-page-shell">
      <PageHeader
        title={route.title}
        description={route.scopeNote}
        breadcrumb={[
          { label: "الإدارة", href: "/admin" },
          { label: "المحتوى", href: "/admin/content/offers" },
          { label: "العروض" },
        ]}
      />
      <ContentCommandProvider session={session}>
        <OffersManagementShell
          snapshot={snapshot}
          canModerate={affordances.canModerateOffers}
        />
      </ContentCommandProvider>
    </div>
  );
}
