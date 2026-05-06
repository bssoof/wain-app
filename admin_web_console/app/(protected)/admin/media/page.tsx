import { MediaCenterShell } from "@/components/media/media-center-shell";
import { MediaCommandProvider } from "@/components/media/media-command-provider";
import { PageHeader } from "@/components/shared/ui/page-header";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import { loadMediaCenterBaseline } from "@/lib/media/media-center-baseline";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";

export default async function AdminMediaPage() {
  const route = getRouteDefinition("media");
  const session = await requireRouteAccess(route.key, route.path);
  const mediaCenterBaseline = await loadMediaCenterBaseline();

  return (
    <div className="admin-page-shell" dir="rtl" lang="ar">
      <PageHeader
        title={route.title}
        description={route.scopeNote}
        breadcrumb={[
          { label: "الإدارة", href: "/admin" },
          { label: "الميديا" },
        ]}
      />
      <MediaCommandProvider session={session}>
        <MediaCenterShell baseline={mediaCenterBaseline} />
      </MediaCommandProvider>
    </div>
  );
}
