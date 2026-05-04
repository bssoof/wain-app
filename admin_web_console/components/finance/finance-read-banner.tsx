import { ReadStateBanner } from "@/components/shared/read-state-banner";
import type { FinanceReadResult } from "@/lib/finance/finance-read-types";

export function FinanceReadStateBanner<T>({
  result,
  label,
}: {
  result: FinanceReadResult<T>;
  label: string;
}) {
  if (result.kind === "unavailable") {
    return (
      <ReadStateBanner
        state="unavailable"
        label={label}
        message={result.message}
        attemptedSource={result.attemptedSource}
        testId="finance-read-banner"
      />
    );
  }

  return (
    <ReadStateBanner
      state={result.stale ? "stale" : "success"}
      source={result.source}
      asOf={result.asOf}
      fetchedAt={result.fetchedAt}
      staleMessage="هذه البيانات أقدم من الوقت المعتمد. تعامل معها كبيانات قديمة حتى تعيد التحديث أو تتأكد من سلامة المصدر."
      testId="finance-read-banner"
      staleTestId="finance-read-stale"
    />
  );
}
