import { OffersManagementShell } from "@/components/content/offers-management-shell";
import { ContentCommandProvider } from "@/components/content/content-command-provider";
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
      <h1>{route.title}</h1>
      <p className="status-note">{route.scopeNote}</p>
      <ContentCommandProvider session={session}>
        <OffersManagementShell
          snapshot={snapshot}
          canModerate={affordances.canModerateOffers}
        />
      </ContentCommandProvider>
    </div>
  );
}
