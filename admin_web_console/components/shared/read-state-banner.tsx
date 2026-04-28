import { formatDate } from "@/lib/finance/read-model-formatters";
import { localizeAdminLabel } from "@/lib/admin/admin-localization";

export type ReadStateBannerState =
  | "success"
  | "stale"
  | "empty"
  | "unavailable";

export type ReadStateBannerProps = {
  state: ReadStateBannerState;
  label?: string;
  message?: string;
  source?: string;
  asOf?: string;
  fetchedAt?: string;
  attemptedSource?: string;
  staleMessage?: string;
  testId?: string;
  staleTestId?: string;
  formatTimestamp?: (value: string) => string;
};

const DEFAULT_STALE_MESSAGE =
  "هذه اللقطة أقدم من نافذة الحداثة المعتمدة. تحقق من سلامة المصدر قبل اتخاذ قرار تشغيلي.";

export function ReadStateBanner({
  state,
  label,
  message,
  source,
  asOf,
  fetchedAt,
  attemptedSource,
  staleMessage,
  testId = "read-state-banner",
  staleTestId = "read-state-stale",
  formatTimestamp = formatDate,
}: ReadStateBannerProps) {
  if (state === "unavailable") {
    return (
      <div
        className="read-state-banner read-state-banner--unavailable finance-read-banner finance-read-banner--unavailable"
        role="alert"
        data-testid={testId}
        data-read-kind="unavailable"
        data-read-state="unavailable"
      >
        {label ? <strong>{label}</strong> : null}
        {message ? <p>{message}</p> : null}
        {attemptedSource ? (
          <p className="muted-text">
            مصدر البيانات الذي تمت تجربته: {localizeAdminLabel(attemptedSource)}
          </p>
        ) : null}
      </div>
    );
  }

  const isStale = state === "stale";
  const isEmpty = state === "empty";

  return (
    <div
      className={[
        "read-state-banner",
        `read-state-banner--${state}`,
        "finance-read-banner",
        isEmpty ? "finance-read-banner--empty" : "finance-read-banner--success",
      ].join(" ")}
      role={isEmpty ? "status" : undefined}
      data-testid={testId}
      data-read-kind={isStale ? "success" : state}
      data-read-state={state}
      data-read-stale={isStale ? "true" : "false"}
    >
      {source || asOf || fetchedAt ? (
        <p className="muted-text read-state-banner__line finance-read-banner__line">
          {source ? (
            <span>
              مصدر البيانات: <strong>{localizeAdminLabel(source)}</strong>
            </span>
          ) : null}
          {source && asOf ? <span className="read-state-banner__sep finance-read-banner__sep"> · </span> : null}
          {asOf ? <span>اللقطة حتى {formatTimestamp(asOf)}</span> : null}
          {(source || asOf) && fetchedAt ? (
            <span className="read-state-banner__sep finance-read-banner__sep"> · </span>
          ) : null}
          {fetchedAt ? <span>تم الجلب {formatTimestamp(fetchedAt)}</span> : null}
        </p>
      ) : null}

      {isEmpty && message ? <p>{message}</p> : null}

      {isStale ? (
        <p
          className="read-state-banner__state-note finance-read-stale-note"
          role="status"
          data-testid={staleTestId}
        >
          {staleMessage ?? message ?? DEFAULT_STALE_MESSAGE}
        </p>
      ) : null}
    </div>
  );
}
