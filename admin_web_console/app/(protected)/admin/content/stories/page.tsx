import { StoriesManagementShell } from "@/components/content/stories-management-shell";
import { ContentCommandProvider } from "@/components/content/content-command-provider";
import { computeContentAffordances } from "@/lib/content/content-surface-affordances";
import { requireRouteAccess } from "@/lib/auth/route-guards";
import { loadStoryModerationSnapshot } from "@/lib/content/content-read-loader";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";

export const dynamic = "force-dynamic";

export default async function AdminStoriesPage() {
  const route = getRouteDefinition("content_stories");
  const session = await requireRouteAccess(route.key, route.path);
  const affordances = computeContentAffordances(session);
  const snapshot = await loadStoryModerationSnapshot();

  return (
    <div className="admin-page-shell">
      <h1>{route.title}</h1>
      <p className="status-note">{route.scopeNote}</p>
      <ContentCommandProvider session={session}>
        <StoriesManagementShell
          snapshot={snapshot}
          canModerate={affordances.canModerateStories}
        />
      </ContentCommandProvider>
    </div>
  );
}
