import { VenueCommandProvider, VenueDirectoryReadBanner, VenueDirectoryShell } from "@/components/venues";
import { PageHeader } from "@/components/shared/ui/page-header";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";
import { loadVenueDirectoryRead } from "@/lib/venues";

export default async function AdminVenuesPage() {
  const route = getRouteDefinition("venues");
  const session = await requireRouteAccess(route.key, route.path);
  const venueDirectoryRead = await loadVenueDirectoryRead();

  return (
    <div className="admin-page-shell">
      <PageHeader
        title="إدارة الفنادق"
        description={route.scopeNote}
        breadcrumb={[
          { label: "الإدارة", href: "/admin" },
          { label: "الفنادق" },
        ]}
      />

      <VenueDirectoryReadBanner result={venueDirectoryRead} label="قراءة قائمة الجهات" />
      <VenueCommandProvider session={session}>
        <VenueDirectoryShell readResult={venueDirectoryRead} />
      </VenueCommandProvider>
    </div>
  );
}
