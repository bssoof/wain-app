export type HeaderBreadcrumbItem = {
  label: string;
  href?: string;
};

export type HeaderBreadcrumbProps = {
  items: HeaderBreadcrumbItem[];
};

export function HeaderBreadcrumb({ items }: HeaderBreadcrumbProps): JSX.Element | null {
  if (items.length === 0) {
    return null;
  }

  return (
    <nav aria-label="مسار الصفحات">
      <ol className="header-breadcrumb">
        {items.map((item, index) => {
          const isCurrentPage = index === items.length - 1 || !item.href;

          return (
            <li className="header-breadcrumb__item" key={`${item.label}-${index}`}>
              {item.href && !isCurrentPage ? (
                <a href={item.href}>{item.label}</a>
              ) : (
                <span aria-current="page">{item.label}</span>
              )}
            </li>
          );
        })}
      </ol>
    </nav>
  );
}
