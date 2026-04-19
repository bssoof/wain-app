import { VenueCommandProvider, VenueDirectoryReadBanner, VenueDirectoryShell } from "@/components/venues";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";
import { loadVenueDirectoryRead } from "@/lib/venues";

export default async function AdminVenuesPage() {
  const route = getRouteDefinition("venues");
  const session = await requireRouteAccess(route.key, route.path);
  const venueDirectoryRead = await loadVenueDirectoryRead();

  return (
    <div className="admin-page-shell">
      <h1>{route.title}</h1>
      <p className="status-note">{route.scopeNote}</p>

      <VenueDirectoryReadBanner result={venueDirectoryRead} label="قراءة قائمة الجهات" />
      <VenueCommandProvider session={session}>
        <VenueDirectoryShell readResult={venueDirectoryRead} />
      </VenueCommandProvider>
    </div>
  );
}
