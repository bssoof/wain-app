import { VenueWorkspaceShell } from "@/components/venue-workspace";
import { PageHeader } from "@/components/shared/ui/page-header";
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
      <PageHeader
        title="تفاصيل الجهة"
        description="تعرض هذه الصفحة بيانات الجهة وأقسام المحفظة والعروض والقصص والمراجعات."
        breadcrumb={[
          { label: "الإدارة", href: "/admin" },
          { label: "الفنادق", href: "/admin/venues" },
          { label: venueId },
        ]}
        actions={
          <a className="action-button action-button-secondary" href="/admin/venues">
            العودة إلى الفنادق
          </a>
        }
      />
      <p className="muted-text venue-workspace-page-meta">
        دور المشغّل: {localizeAdminLabel(session.primaryRole)}
      </p>
      <VenueWorkspaceShell venueId={venueId} readBundle={readBundle} />
    </div>
  );
}
