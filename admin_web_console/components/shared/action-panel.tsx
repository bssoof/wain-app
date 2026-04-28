import type { ComponentPropsWithoutRef, ReactNode } from "react";

type ClassValue = string | false | null | undefined;

type DivProps = Omit<ComponentPropsWithoutRef<"div">, "children" | "className"> & {
  children: ReactNode;
  className?: string;
  testId?: string;
};

type MessageProps = Omit<ComponentPropsWithoutRef<"p">, "children" | "className"> & {
  children: ReactNode;
  className?: string;
  testId?: string;
};

export function ActionPanel({ children, className, testId, ...divProps }: DivProps) {
  return (
    <div
      {...divProps}
      className={classNames("action-panel", className)}
      data-testid={testId}
    >
      {children}
    </div>
  );
}

export function ActionPanelItem({ children, className, testId, ...divProps }: DivProps) {
  return (
    <div
      {...divProps}
      className={classNames("action-panel__item", className)}
      data-testid={testId}
    >
      {children}
    </div>
  );
}

export function ActionPanelHeader({ children, className, testId, ...divProps }: DivProps) {
  return (
    <div
      {...divProps}
      className={classNames("action-panel__header", className)}
      data-testid={testId}
    >
      {children}
    </div>
  );
}

export function ActionPanelActions({ children, className, testId, ...divProps }: DivProps) {
  return (
    <div
      {...divProps}
      className={classNames("action-panel__actions", className)}
      data-testid={testId}
    >
      {children}
    </div>
  );
}

export function ActionPanelMessage({
  children,
  className,
  testId,
  ...messageProps
}: MessageProps) {
  return (
    <p
      {...messageProps}
      className={classNames("action-panel__message", className)}
      data-testid={testId}
    >
      {children}
    </p>
  );
}

function classNames(...values: ClassValue[]) {
  return values.filter(Boolean).join(" ");
}