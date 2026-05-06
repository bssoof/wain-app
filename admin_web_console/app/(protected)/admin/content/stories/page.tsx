import { StoriesManagementShell } from "@/components/content/stories-management-shell";
import { ContentCommandProvider } from "@/components/content/content-command-provider";
import { PageHeader } from "@/components/shared/ui/page-header";
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
      <PageHeader
        title={route.title}
        description={route.scopeNote}
        breadcrumb={[
          { label: "الإدارة", href: "/admin" },
          { label: "المحتوى", href: "/admin/content/offers" },
          { label: "القصص" },
        ]}
      />
      <ContentCommandProvider session={session}>
        <StoriesManagementShell
          snapshot={snapshot}
          canModerate={affordances.canModerateStories}
        />
      </ContentCommandProvider>
    </div>
  );
}
