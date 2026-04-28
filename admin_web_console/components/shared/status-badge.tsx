import type { ComponentPropsWithoutRef, ReactNode } from "react";

type ClassValue = string | false | null | undefined;

export type StatusBadgeTone = "success" | "warning" | "danger" | "neutral";

export type StatusBadgeProps = Omit<
  ComponentPropsWithoutRef<"span">,
  "children" | "className"
> & {
  children: ReactNode;
  tone?: StatusBadgeTone;
  className?: string;
  testId?: string;
};

export function StatusBadge({
  children,
  tone,
  className,
  testId,
  ...spanProps
}: StatusBadgeProps) {
  const toneClassName = tone ? `status-${tone}` : undefined;

  return (
    <span
      {...spanProps}
      className={classNames("status-pill", toneClassName, className)}
      data-testid={testId}
    >
      {children}
    </span>
  );
}

function classNames(...values: ClassValue[]) {
  return values.filter(Boolean).join(" ");
}
