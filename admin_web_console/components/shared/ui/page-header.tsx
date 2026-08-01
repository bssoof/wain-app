import type { ReactNode } from "react";

export interface PageHeaderProps {
  title: string;
  description?: string;
  breadcrumb?: Array<{ label: string; href?: string }>;
  actions?: ReactNode;
  badge?: ReactNode;
}

export function PageHeader({
  title,
  description,
  breadcrumb,
  actions,
  badge,
}: PageHeaderProps): JSX.Element {
  const hasBreadcrumb = Boolean(breadcrumb?.length);

  return (
    <header className="page-header">
      {hasBreadcrumb ? (
        <nav aria-label="مسار الصفحات">
          <ol className="page-header__breadcrumb">
            {breadcrumb?.map((item, index) => (
              <li className="page-header__breadcrumb-item" key={`${item.label}-${index}`}>
                {item.href ? (
                  <a href={item.href}>{item.label}</a>
                ) : (
                  <span aria-current="page">{item.label}</span>
                )}
              </li>
            ))}
          </ol>
        </nav>
      ) : null}

      <div className="page-header__main">
        <div>
          <div className="page-header__title-row">
            <h1 className="page-header__title">{title}</h1>
            {badge}
          </div>
          {description ? (
            <p className="page-header__description">{description}</p>
          ) : null}
        </div>

        {actions ? <div className="page-header__actions">{actions}</div> : null}
      </div>
    </header>
  );
}
