import { ReadStateBanner } from "@/components/shared/read-state-banner";
import { localizeAdminMessage } from "@/lib/admin/admin-localization";
import type { VenueWorkspaceReadResult } from "@/lib/venues/venue-workspace-read-types";

export function VenueWorkspaceReadBanner<T>({
  result,
  label,
  tabKey,
}: {
  result: VenueWorkspaceReadResult<T>;
  label: string;
  tabKey: string;
}) {
  if (result.kind === "unavailable") {
    return (
      <ReadStateBanner
        state="unavailable"
        label={label}
        message={localizeAdminMessage(result.message) ?? result.message}
        attemptedSource={result.attemptedSource}
        testId={`venue-read-banner-${tabKey}`}
      />
    );
  }

  return (
    <ReadStateBanner
      state={result.stale ? "stale" : "success"}
      source={result.source}
      asOf={result.asOf}
      fetchedAt={result.fetchedAt}
      staleMessage="هذا القسم يعرض بيانات قديمة. حدّث الصفحة قبل اتخاذ قرار مهم."
      testId={`venue-read-banner-${tabKey}`}
      staleTestId={`venue-read-stale-${tabKey}`}
    />
  );
}
