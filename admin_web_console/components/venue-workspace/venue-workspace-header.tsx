import Link from "next/link";

import {
  formatCurrency,
  formatStatus,
  getStatusColorClass,
} from "@/lib/finance/read-model-formatters";
import type { VenueWorkspaceContext } from "@/lib/venues/venue-workspace-models";
import { StatusBadge } from "../shared/status-badge";

export function VenueWorkspaceHeader({
  venueId,
  context,
}: {
  venueId: string;
  context: VenueWorkspaceContext;
}) {
  return (
    <div className="card venue-workspace-header">
      <div className="venue-workspace-header-top-row">
        <div>
          <h2 data-testid="venue-workspace-venue-name">{context.venueName}</h2>
          <p className="muted-text">معرّف الجهة: {venueId}</p>
        </div>
        <Link
          href="/admin/venues"
          className="venue-workspace-back-link"
          data-testid="venue-workspace-back-link"
        >
          العودة إلى الجهات
        </Link>
      </div>

      <div className="venue-workspace-summary-row">
        <StatusBadge
          className={getStatusColorClass(context.readinessStatus)}
          testId="venue-workspace-readiness-badge"
        >
          حالة النظام: {formatStatus(context.readinessStatus)}
        </StatusBadge>
        <StatusBadge tone="neutral" testId="venue-workspace-wallet-summary">
          المحفظة: {formatCurrency(context.walletBalance, context.walletCurrency)}
        </StatusBadge>
      </div>

      <p className="muted-text">{localizeReadinessSummary(context.readinessSummary)}</p>
    </div>
  );
}

function localizeReadinessSummary(summary: string): string {
  const normalized = summary.trim().toLowerCase();
  if (normalized === "ready") {
    return "جاهز";
  }
  if (normalized === "warning") {
    return "تحذير";
  }
  if (normalized === "one upstream warning is active.") {
    return "يوجد تحذير واحد نشط في أحد المصادر العليا.";
  }
  return summary;
}
