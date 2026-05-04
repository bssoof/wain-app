import { requireRouteAccess } from "@/lib/auth/route-guards";
import { getRouteDefinition } from "@/lib/navigation/admin-route-map";
import { loadReviewModerationSnapshot } from "@/lib/reviews/review-moderation-loader";

import { ReviewCommandProvider, ReviewModerationShell } from "@/components/reviews";

export const dynamic = "force-dynamic";

export default async function AdminReviewsPage() {
  const route = getRouteDefinition("reviews_moderation");
  const session = await requireRouteAccess(route.key, route.path);
  const snapshot = await loadReviewModerationSnapshot();

  return (
    <div className="admin-page-shell">
      <h1>{route.title}</h1>
      <p className="status-note">{route.scopeNote}</p>
      <ReviewCommandProvider session={session}>
        <ReviewModerationShell snapshot={snapshot} canModerate />
      </ReviewCommandProvider>
    </div>
  );
}
