import type { ReactNode } from "react";

export function FinanceAdminPageShell({
  title,
  scopeNote,
  readBanner,
  children,
}: {
  title: string;
  scopeNote: string;
  readBanner: ReactNode;
  children: ReactNode;
}) {
  return (
    <div className="admin-page-shell">
      <h1>{title}</h1>
      <p className="status-note">{scopeNote}</p>
      {readBanner}
      {children}
    </div>
  );
}
