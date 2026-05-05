import type { ReactNode } from "react";

type ClassValue = string | false | null | undefined;

export interface CommandBarProps {
  primary?: ReactNode;
  secondary?: ReactNode;
  dense?: boolean;
}

export function CommandBar({
  primary,
  secondary,
  dense = false,
}: CommandBarProps): JSX.Element {
  return (
    <div
      className={classNames("command-bar", dense && "command-bar--dense")}
      role="toolbar"
      aria-label="شريط الأوامر"
    >
      <div className="command-bar__primary">{primary}</div>
      <div className="command-bar__secondary">{secondary}</div>
    </div>
  );
}

function classNames(...values: ClassValue[]) {
  return values.filter(Boolean).join(" ");
}
