import type { ComponentPropsWithoutRef, ReactNode } from "react";
import { Search, X } from "lucide-react";

type ClassValue = string | false | null | undefined;

export type ActiveFilterChip = {
  key: string;
  label: string;
  value: string;
  onRemove: () => void;
};

export type FilterToolbarProps = {
  children: ReactNode;
  className?: string;
  testId?: string;
  activeFilters?: ActiveFilterChip[];
  onClearAll?: () => void;
  searchValue?: string;
  onSearchChange?: (value: string) => void;
  searchPlaceholder?: string;
};

export type FilterFieldProps = {
  label: ReactNode;
  children: ReactNode;
  className?: string;
  labelClassName?: string;
};

export type FilterTextInputProps = ComponentPropsWithoutRef<"input">;
export type FilterSelectProps = ComponentPropsWithoutRef<"select">;

export function FilterToolbar({
  children,
  className,
  testId,
  activeFilters = [],
  onClearAll,
  searchValue,
  onSearchChange,
  searchPlaceholder = "بحث...",
}: FilterToolbarProps) {
  const hasActiveFilters = activeFilters.length > 0;
  const hasSearch = searchValue !== undefined && onSearchChange !== undefined;

  return (
    <div className={classNames("filter-toolbar", className)} data-testid={testId}>
      {hasActiveFilters ? (
        <div className="filter-toolbar__chips" aria-label="الفلاتر المطبقة">
          {activeFilters.map((filter) => (
            <button
              key={filter.key}
              type="button"
              className="filter-chip"
              aria-label={`إزالة ${filter.label}: ${filter.value}`}
              onClick={filter.onRemove}
            >
              <span>
                {filter.label}: {filter.value}
              </span>
              <X
                aria-hidden="true"
                className="filter-chip__close-icon"
                size={12}
                strokeWidth={2}
              />
            </button>
          ))}
          {onClearAll ? (
            <button
              type="button"
              className="filter-toolbar__clear-all"
              onClick={onClearAll}
            >
              مسح الكل
            </button>
          ) : null}
        </div>
      ) : null}
      {hasSearch ? (
        <div className="filter-toolbar__search-input-wrapper">
          <Search
            aria-hidden="true"
            className="filter-toolbar__search-icon"
            data-testid="filter-toolbar-search-icon"
            size={14}
            strokeWidth={2}
          />
          <input
            type="search"
            className="filter-toolbar__search-input"
            value={searchValue}
            onChange={(event) => onSearchChange(event.target.value)}
            placeholder={searchPlaceholder}
            aria-label={searchPlaceholder}
          />
        </div>
      ) : null}
      {children}
    </div>
  );
}

export function FilterField({
  label,
  children,
  className,
  labelClassName = "muted-text",
}: FilterFieldProps) {
  return (
    <label className={classNames("filter-toolbar__field", className)}>
      <span className={labelClassName}>{label}</span>
      {children}
    </label>
  );
}

export function FilterTextInput({
  className,
  ...props
}: FilterTextInputProps) {
  return (
    <input
      className={classNames(
        "filter-toolbar__control",
        "filter-toolbar__input",
        className,
      )}
      {...props}
    />
  );
}

export function FilterSelect({ className, ...props }: FilterSelectProps) {
  return (
    <select
      className={classNames(
        "filter-toolbar__control",
        "filter-toolbar__select",
        className,
      )}
      {...props}
    />
  );
}

function classNames(...values: ClassValue[]) {
  return values.filter(Boolean).join(" ");
}
