export type HeaderEnvironment = "production" | "preview" | "local" | "unknown";

export type HeaderEnvironmentBadgeProps = {
  value: HeaderEnvironment;
};

const ENVIRONMENT_LABELS: Record<HeaderEnvironment, string> = {
  production: "إنتاج",
  preview: "معاينة",
  local: "محلي",
  unknown: "غير محدد",
};

export function HeaderEnvironmentBadge({
  value,
}: HeaderEnvironmentBadgeProps): JSX.Element {
  return (
    <span className={`header-env-badge header-env-badge--${value}`}>
      {ENVIRONMENT_LABELS[value]}
    </span>
  );
}
