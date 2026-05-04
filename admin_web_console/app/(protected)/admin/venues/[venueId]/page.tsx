import { VenueWorkspaceShell } from "@/components/venue-workspace";
import { localizeAdminLabel } from "@/lib/admin/admin-localization";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";
import { loadVenueWorkspaceReadBundle } from "@/lib/venues";

export default async function AdminVenueWorkspacePage({
  params,
}: {
  params: { venueId: string };
}) {
  const route = getRouteDefinition("venues");
  const venueId = decodeURIComponent(params.venueId);
  const session = await requireRouteAccess(route.key, `${route.path}/${venueId}`);
  const readBundle = await loadVenueWorkspaceReadBundle(venueId);

  return (
    <div className="admin-page-shell">
      <h1>تفاصيل الجهة</h1>
      <p className="status-note">
        تعرض هذه الصفحة بيانات الجهة وأقسام المحفظة والعروض والقصص والمراجعات.
      </p>
      <p className="muted-text">دور المشغّل: {localizeAdminLabel(session.primaryRole)}</p>
      <VenueWorkspaceShell venueId={venueId} readBundle={readBundle} />
    </div>
  );
}
