import type { ComponentPropsWithoutRef, ReactNode } from "react";

type ClassValue = string | false | null | undefined;

export type DataTableDensity = "default" | "compact";

export type DataTableProps = Omit<
  ComponentPropsWithoutRef<"table">,
  "children" | "className"
> & {
  children: ReactNode;
  className?: string;
  caption?: ReactNode;
  captionClassName?: string;
  density?: DataTableDensity;
  scrollClassName?: string;
  scrollTestId?: string;
  testId?: string;
};

export function DataTable({
  children,
  className,
  caption,
  captionClassName,
  density = "default",
  scrollClassName,
  scrollTestId,
  testId,
  ...tableProps
}: DataTableProps) {
  return (
    <div
      className={classNames("data-table-scroll", "table-scroll", scrollClassName)}
      data-table-density={density}
      data-testid={scrollTestId}
    >
      <table
        {...tableProps}
        className={classNames(
          "data-table",
          density === "compact" && "data-table--compact",
          className,
        )}
        data-table-density={density}
        data-table-mode="display-table"
        data-testid={testId}
      >
        {caption ? (
          <caption className={classNames("data-table__caption", captionClassName)}>
            {caption}
          </caption>
        ) : null}
        {children}
      </table>
    </div>
  );
}

function classNames(...values: ClassValue[]) {
  return values.filter(Boolean).join(" ");
}
