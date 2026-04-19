import { MediaCenterShell } from "@/components/media/media-center-shell";
import { MediaCommandProvider } from "@/components/media/media-command-provider";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import { loadMediaCenterBaseline } from "@/lib/media/media-center-baseline";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";

export default async function AdminMediaPage() {
  const route = getRouteDefinition("media");
  const session = await requireRouteAccess(route.key, route.path);
  const mediaCenterBaseline = await loadMediaCenterBaseline();

  return (
    <div className="admin-page-shell" dir="rtl" lang="ar">
      <h1>{route.title}</h1>
      <p className="status-note">{route.scopeNote}</p>
      <MediaCommandProvider session={session}>
        <MediaCenterShell baseline={mediaCenterBaseline} />
      </MediaCommandProvider>
    </div>
  );
}
