import { ReadStateBanner } from "@/components/shared/read-state-banner";
import { localizeAdminMessage } from "@/lib/admin/admin-localization";
import type { VenueDirectoryReadData } from "@/lib/venues/venue-directory-models";
import type { VenueDirectoryReadResult } from "@/lib/venues/venue-directory-read-types";

export function VenueDirectoryReadBanner({
  result,
  label,
}: {
  result: VenueDirectoryReadResult<VenueDirectoryReadData>;
  label: string;
}) {
  if (result.kind === "unavailable") {
    return (
      <ReadStateBanner
        state="unavailable"
        label={label}
        message={localizeAdminMessage(result.message) ?? result.message}
        attemptedSource={result.attemptedSource}
        testId="venue-directory-read-banner"
      />
    );
  }

  return (
    <ReadStateBanner
      state={result.stale ? "stale" : "success"}
      source={result.source}
      asOf={result.asOf}
      fetchedAt={result.fetchedAt}
      staleMessage="قد تكون بيانات الجهات قديمة. حدّث الصفحة قبل اتخاذ قرار مهم."
      testId="venue-directory-read-banner"
      staleTestId="venue-directory-read-stale"
    />
  );
}
