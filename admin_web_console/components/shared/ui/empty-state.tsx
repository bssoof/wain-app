import { Inbox } from "lucide-react";
import type { LucideIcon } from "lucide-react";

export interface EmptyStateProps {
  icon?: LucideIcon;
  title: string;
  description?: string;
  action?: { label: string; onClick: () => void };
  compact?: boolean;
}

function joinClassNames(...classNames: Array<string | false | null | undefined>): string {
  return classNames.filter(Boolean).join(" ");
}

export function EmptyState({
  icon: Icon = Inbox,
  title,
  description,
  action,
  compact = false,
}: EmptyStateProps): JSX.Element {
  const iconSize = compact ? 16 : 32;

  return (
    <div
      className={joinClassNames("empty-state", compact && "empty-state--compact")}
      role="status"
    >
      <Icon
        aria-hidden="true"
        className="empty-state__icon"
        data-testid="empty-state-icon"
        size={iconSize}
        strokeWidth={2}
      />
      <p className="empty-state__title">{title}</p>
      {description ? <p className="empty-state__description">{description}</p> : null}
      {action ? (
        <button className="empty-state__action" onClick={action.onClick} type="button">
          {action.label}
        </button>
      ) : null}
    </div>
  );
}
