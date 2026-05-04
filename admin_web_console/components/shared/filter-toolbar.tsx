import type { ComponentPropsWithoutRef, ReactNode } from "react";

type ClassValue = string | false | null | undefined;

export type FilterToolbarProps = {
  children: ReactNode;
  className?: string;
  testId?: string;
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
}: FilterToolbarProps) {
  return (
    <div className={classNames("filter-toolbar", className)} data-testid={testId}>
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
