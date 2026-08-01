import {
  Children,
  cloneElement,
  isValidElement,
  type ComponentPropsWithoutRef,
  type ReactElement,
  type ReactNode,
} from "react";
import type { LucideIcon } from "lucide-react";

import { EmptyState } from "@/components/shared/ui/empty-state";
import { SkeletonBlock } from "@/components/shared/ui/skeleton-block";

type ClassValue = string | false | null | undefined;

export type DataTableDensity = "default" | "comfortable" | "compact";

type TableChildProps = {
  children?: ReactNode;
  className?: string;
};

export type DataTableEmptyState = {
  title: string;
  description?: string;
  action?: { label: string; onClick: () => void };
};

export type DataTableSelection<T> =
  | {
      mode?: "none";
      selectedKeys?: Set<string>;
      onSelectionChange?: (keys: Set<string>) => void;
      getRowKey?: (row: T) => string;
    }
  | {
      mode: "single" | "multi";
      selectedKeys: Set<string>;
      onSelectionChange: (keys: Set<string>) => void;
      getRowKey: (row: T) => string;
    };

type ActiveDataTableSelection<T> = Extract<
  DataTableSelection<T>,
  { mode: "single" | "multi" }
>;

export type DataTableBulkAction = {
  label: string;
  icon?: LucideIcon;
  variant?: "default" | "danger";
  onAction: (selectedKeys: Set<string>) => void | Promise<void>;
};

export type DataTableProps<T = unknown> = Omit<
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
  stickyHeader?: boolean;
  loading?: boolean;
  loadingRowCount?: number;
  emptyState?: DataTableEmptyState;
  rows?: readonly T[];
  selection?: DataTableSelection<T>;
  bulkActions?: DataTableBulkAction[];
};

export function DataTable<T = unknown>({
  children,
  className,
  caption,
  captionClassName,
  density = "default",
  stickyHeader = false,
  loading = false,
  loadingRowCount = 5,
  emptyState,
  rows,
  selection,
  bulkActions = [],
  scrollClassName,
  scrollTestId,
  testId,
  ...tableProps
}: DataTableProps<T>) {
  const activeSelection = getActiveSelection(selection);
  const selectionMode = activeSelection?.mode ?? "none";
  const selectionEnabled = activeSelection !== null;
  const selectedKeys = activeSelection?.selectedKeys ?? new Set<string>();
  const childrenArray = Children.toArray(children);
  const tableHead = childrenArray.find((child) => isElementOfType(child, "thead"));
  const tableBody = childrenArray.find((child) => isElementOfType(child, "tbody"));
  const baseColumnCount = getColumnCount(tableHead) || getColumnCount(tableBody) || 1;
  const bodyRowCount = rows?.length ?? getRowCount(tableBody);
  const selectableKeys =
    activeSelection
      ? getSelectableKeys(tableBody, rows, activeSelection.getRowKey)
      : [];
  const selectedCount = selectedKeys.size;
  const showBulkBar = selectedCount > 0;
  let bodyHandled = false;

  const enhancedChildren = childrenArray.map((child) => {
    if (isElementOfType(child, "thead")) {
      return enhanceTableHead({
        tableHead: child,
        stickyHeader,
        selectionEnabled,
        selectionMode,
        loading,
        selectedKeys,
        selectableKeys,
        onSelectionChange:
          selectionEnabled && selection ? selection.onSelectionChange : undefined,
      });
    }

    if (isElementOfType(child, "tbody")) {
      bodyHandled = true;
      return enhanceTableBody({
        tableBody: child,
        columnCount: baseColumnCount,
        emptyState,
        loading,
        loadingRowCount,
        rows,
        selectedKeys,
        selection: activeSelection,
        selectionEnabled,
      });
    }

    return child;
  });

  if (!bodyHandled && (loading || (bodyRowCount === 0 && emptyState))) {
    enhancedChildren.push(
      <tbody key="data-table-generated-body">
        {renderGeneratedBodyContent({
          columnCount: baseColumnCount,
          emptyState,
          loading,
          loadingRowCount,
          selectionEnabled,
        })}
      </tbody>,
    );
  }

  return (
    <div
      className={classNames("data-table-scroll", "table-scroll", scrollClassName)}
      data-table-density={density}
      data-testid={scrollTestId}
    >
      {showBulkBar ? (
        <DataTableBulkBar actions={bulkActions} selectedKeys={selectedKeys} />
      ) : null}
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
        {enhancedChildren}
      </table>
    </div>
  );
}

function classNames(...values: ClassValue[]) {
  return values.filter(Boolean).join(" ");
}

function getActiveSelection<T>(
  selection: DataTableSelection<T> | undefined,
): ActiveDataTableSelection<T> | null {
  if (selection?.mode === "single" || selection?.mode === "multi") {
    return selection as ActiveDataTableSelection<T>;
  }

  return null;
}

function isElementOfType(
  node: ReactNode,
  type: "thead" | "tbody" | "tr" | "th" | "td",
): node is ReactElement<TableChildProps> {
  return isValidElement<TableChildProps>(node) && node.type === type;
}

function getColumnCount(section: ReactNode): number {
  if (!isValidElement<TableChildProps>(section)) {
    return 0;
  }

  const firstRow = Children.toArray(section.props.children).find((child) =>
    isElementOfType(child, "tr"),
  );
  if (!isElementOfType(firstRow, "tr")) {
    return 0;
  }

  return Children.toArray(firstRow.props.children).filter(
    (child) => isElementOfType(child, "th") || isElementOfType(child, "td"),
  ).length;
}

function getRowCount(section: ReactNode): number {
  if (!isValidElement<TableChildProps>(section)) {
    return 0;
  }

  return Children.toArray(section.props.children).filter((child) =>
    isElementOfType(child, "tr"),
  ).length;
}

function getSelectableKeys<T>(
  tableBody: ReactNode,
  rows: readonly T[] | undefined,
  getRowKey: (row: T) => string,
): string[] {
  const rowCount = rows?.length ?? getRowCount(tableBody);
  return Array.from({ length: rowCount }, (_, index) =>
    rows?.[index] !== undefined ? getRowKey(rows[index]) : String(index),
  );
}

function enhanceTableHead<T>({
  tableHead,
  stickyHeader,
  selectionEnabled,
  selectionMode,
  loading,
  selectedKeys,
  selectableKeys,
  onSelectionChange,
}: {
  tableHead: ReactElement<TableChildProps>;
  stickyHeader: boolean;
  selectionEnabled: boolean;
  selectionMode: "none" | "single" | "multi";
  loading: boolean;
  selectedKeys: Set<string>;
  selectableKeys: string[];
  onSelectionChange?: (keys: Set<string>) => void;
}) {
  let firstRowEnhanced = false;
  const allSelected =
    selectableKeys.length > 0 && selectableKeys.every((key) => selectedKeys.has(key));

  const enhancedRows = Children.map(tableHead.props.children, (child) => {
    if (!isElementOfType(child, "tr") || firstRowEnhanced || !selectionEnabled) {
      return child;
    }

    firstRowEnhanced = true;
    return cloneElement(child, undefined, [
      <th className="data-table__selection-cell" key="selection-header" scope="col">
        {selectionMode === "multi" ? (
          <input
            aria-label="تحديد الكل"
            checked={allSelected}
            disabled={loading || selectableKeys.length === 0}
            onChange={() => {
              if (!onSelectionChange) {
                return;
              }

              const nextKeys = new Set(selectedKeys);
              if (allSelected) {
                selectableKeys.forEach((key) => nextKeys.delete(key));
              } else {
                selectableKeys.forEach((key) => nextKeys.add(key));
              }
              onSelectionChange(nextKeys);
            }}
            type="checkbox"
          />
        ) : null}
      </th>,
      child.props.children,
    ]);
  });

  return cloneElement(
    tableHead,
    {
      className: classNames(
        tableHead.props.className,
        stickyHeader && "data-table__sticky-header",
      ),
    },
    enhancedRows,
  );
}

function enhanceTableBody<T>({
  tableBody,
  columnCount,
  emptyState,
  loading,
  loadingRowCount,
  rows,
  selectedKeys,
  selection,
  selectionEnabled,
}: {
  tableBody: ReactElement<TableChildProps>;
  columnCount: number;
  emptyState?: DataTableEmptyState;
  loading: boolean;
  loadingRowCount: number;
  rows?: readonly T[];
  selectedKeys: Set<string>;
  selection: ActiveDataTableSelection<T> | null;
  selectionEnabled: boolean;
}) {
  const rowCount = rows?.length ?? getRowCount(tableBody);
  const bodyContent =
    loading || (rowCount === 0 && emptyState)
      ? renderGeneratedBodyContent({
          columnCount,
          emptyState,
          loading,
          loadingRowCount,
          selectionEnabled,
        })
      : enhanceBodyRows({
          children: tableBody.props.children,
          rows,
          selectedKeys,
          selection,
          selectionEnabled,
        });

  return cloneElement(tableBody, undefined, bodyContent);
}

function renderGeneratedBodyContent({
  columnCount,
  emptyState,
  loading,
  loadingRowCount,
  selectionEnabled,
}: {
  columnCount: number;
  emptyState?: DataTableEmptyState;
  loading: boolean;
  loadingRowCount: number;
  selectionEnabled: boolean;
}) {
  const totalColumns = columnCount + (selectionEnabled ? 1 : 0);

  if (loading) {
    return Array.from({ length: loadingRowCount }, (_, rowIndex) => (
      <tr key={`loading-row-${rowIndex}`}>
        {Array.from({ length: totalColumns }, (_, cellIndex) => (
          <td className="data-table__loading-cell" key={`loading-cell-${cellIndex}`}>
            <SkeletonBlock height={16} />
          </td>
        ))}
      </tr>
    ));
  }

  if (emptyState) {
    return (
      <tr className="data-table__empty-row">
        <td colSpan={totalColumns}>
          <EmptyState {...emptyState} />
        </td>
      </tr>
    );
  }

  return null;
}

function enhanceBodyRows<T>({
  children,
  rows,
  selectedKeys,
  selection,
  selectionEnabled,
}: {
  children?: ReactNode;
  rows?: readonly T[];
  selectedKeys: Set<string>;
  selection: ActiveDataTableSelection<T> | null;
  selectionEnabled: boolean;
}) {
  let rowIndex = 0;

  return Children.map(children, (child) => {
    if (!isElementOfType(child, "tr") || !selectionEnabled || !selection) {
      return child;
    }

    const currentIndex = rowIndex;
    rowIndex += 1;
    const rowData = rows?.[currentIndex];
    const rowKey =
      rowData !== undefined
        ? selection.getRowKey(rowData)
        : String(currentIndex);
    const checked = selectedKeys.has(rowKey);

    return cloneElement(child, undefined, [
      <td className="data-table__selection-cell" key="selection-cell">
        <input
          aria-label="تحديد الصف"
          checked={checked}
          onChange={() => {
            if (selection.mode === "single") {
              selection.onSelectionChange(checked ? new Set() : new Set([rowKey]));
              return;
            }

            if (selection.mode === "multi") {
              const nextKeys = new Set(selectedKeys);
              if (checked) {
                nextKeys.delete(rowKey);
              } else {
                nextKeys.add(rowKey);
              }
              selection.onSelectionChange(nextKeys);
            }
          }}
          type="checkbox"
        />
      </td>,
      child.props.children,
    ]);
  });
}

function DataTableBulkBar({
  actions,
  selectedKeys,
}: {
  actions: DataTableBulkAction[];
  selectedKeys: Set<string>;
}) {
  return (
    <div className="data-table-bulk-bar">
      <span className="data-table-bulk-bar__count">
        {selectedKeys.size} محدد
      </span>
      {actions.length > 0 ? (
        <div className="data-table-bulk-bar__actions">
          {actions.map((action) => {
            const Icon = action.icon;
            return (
              <button
                className={classNames(
                  "data-table-bulk-bar__btn",
                  action.variant === "danger" && "data-table-bulk-bar__btn--danger",
                )}
                key={action.label}
                onClick={() => {
                  void action.onAction(new Set(selectedKeys));
                }}
                type="button"
              >
                {Icon ? <Icon aria-hidden="true" size={14} strokeWidth={2} /> : null}
                <span>{action.label}</span>
              </button>
            );
          })}
        </div>
      ) : null}
    </div>
  );
}
