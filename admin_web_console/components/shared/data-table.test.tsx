import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { DataTable } from "./data-table";

const rows = [
  { id: "row-1", label: "First" },
  { id: "row-2", label: "Second" },
];

function renderSelectableTable({
  mode = "multi",
  selectedKeys = new Set<string>(),
  onSelectionChange = vi.fn(),
}: {
  mode?: "single" | "multi";
  selectedKeys?: Set<string>;
  onSelectionChange?: ReturnType<typeof vi.fn>;
} = {}) {
  return {
    onSelectionChange,
    ...render(
      <DataTable
        rows={rows}
        selection={{
          mode,
          selectedKeys,
          onSelectionChange,
          getRowKey: (row) => row.id,
        }}
      >
        <thead>
          <tr>
            <th>Label</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.id}>
              <td>{row.label}</td>
            </tr>
          ))}
        </tbody>
      </DataTable>,
    ),
  };
}

describe("DataTable", () => {
  it("renders a display-table wrapper with stable legacy and shared hooks", () => {
    render(
      <DataTable
        className="legacy-table"
        scrollClassName="card"
        scrollTestId="table-frame"
        testId="records-table"
      >
        <thead>
          <tr>
            <th>Label</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Value</td>
          </tr>
        </tbody>
      </DataTable>,
    );

    const frame = screen.getByTestId("table-frame");
    const table = screen.getByTestId("records-table");

    expect(frame.className).toContain("data-table-scroll");
    expect(frame.className).toContain("table-scroll");
    expect(frame.className).toContain("card");
    expect(table.tagName).toBe("TABLE");
    expect(table.className).toContain("data-table");
    expect(table.className).toContain("legacy-table");
    expect(table.getAttribute("data-table-mode")).toBe("display-table");
  });

  it("supports captions and compact density without changing table semantics", () => {
    render(
      <DataTable caption="Audit entries" density="compact" testId="audit-table">
        <tbody>
          <tr>
            <td>entry-1</td>
          </tr>
        </tbody>
      </DataTable>,
    );

    const table = screen.getByTestId("audit-table");
    expect(table.className).toContain("data-table--compact");
    expect(table.getAttribute("data-table-density")).toBe("compact");
    expect(screen.getByText("Audit entries").tagName).toBe("CAPTION");
  });

  it("applies compact density class", () => {
    render(
      <DataTable density="compact" testId="compact-table">
        <tbody>
          <tr>
            <td>entry</td>
          </tr>
        </tbody>
      </DataTable>,
    );

    expect(screen.getByTestId("compact-table").className).toContain(
      "data-table--compact",
    );
  });

  it("applies sticky header class when requested", () => {
    render(
      <DataTable stickyHeader>
        <thead>
          <tr>
            <th>Label</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Value</td>
          </tr>
        </tbody>
      </DataTable>,
    );

    expect(screen.getByText("Label").closest("thead")?.className).toContain(
      "data-table__sticky-header",
    );
  });

  it("renders skeleton cells while loading", () => {
    render(
      <DataTable loading loadingRowCount={3}>
        <thead>
          <tr>
            <th>Label</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Value</td>
            <td>Ready</td>
          </tr>
        </tbody>
      </DataTable>,
    );

    expect(screen.getAllByRole("status", { name: "جاري التحميل" })).toHaveLength(6);
    expect(screen.queryByText("Value")).toBeNull();
  });

  it("renders an empty state when there are no rows", () => {
    render(
      <DataTable
        emptyState={{
          title: "لا توجد نتائج",
          description: "غيّر الفلاتر وحاول مجددا.",
        }}
      >
        <thead>
          <tr>
            <th>Label</th>
          </tr>
        </thead>
        <tbody />
      </DataTable>,
    );

    expect(screen.getByText("لا توجد نتائج")).not.toBeNull();
    expect(screen.getByText("غيّر الفلاتر وحاول مجددا.")).not.toBeNull();
  });

  it("selects all rows from the header checkbox in multi selection mode", () => {
    const { onSelectionChange } = renderSelectableTable();

    fireEvent.click(screen.getByRole("checkbox", { name: "تحديد الكل" }));

    expect(onSelectionChange).toHaveBeenCalledTimes(1);
    expect(Array.from(onSelectionChange.mock.calls[0][0]).sort()).toEqual([
      "row-1",
      "row-2",
    ]);
  });

  it("toggles a row checkbox in multi selection mode", () => {
    const { onSelectionChange } = renderSelectableTable({
      selectedKeys: new Set(["row-1"]),
    });

    fireEvent.click(screen.getAllByRole("checkbox", { name: "تحديد الصف" })[0]);

    expect(onSelectionChange).toHaveBeenCalledWith(new Set<string>());
  });

  it("replaces selection in single selection mode", () => {
    const { onSelectionChange } = renderSelectableTable({
      mode: "single",
      selectedKeys: new Set(["row-1"]),
    });

    fireEvent.click(screen.getAllByRole("checkbox", { name: "تحديد الصف" })[1]);

    expect(onSelectionChange).toHaveBeenCalledWith(new Set(["row-2"]));
  });

  it("shows a bulk action bar when rows are selected", () => {
    renderSelectableTable({ selectedKeys: new Set(["row-1"]) });

    expect(screen.getByText("1 محدد")).not.toBeNull();
  });

  it("shows the selected count in the bulk action bar", () => {
    renderSelectableTable({ selectedKeys: new Set(["row-1", "row-2"]) });

    expect(screen.getByText("2 محدد")).not.toBeNull();
  });

  it("passes selected keys to bulk actions", () => {
    const onAction = vi.fn();
    render(
      <DataTable
        rows={rows}
        selection={{
          mode: "multi",
          selectedKeys: new Set(["row-2"]),
          onSelectionChange: vi.fn(),
          getRowKey: (row) => row.id,
        }}
        bulkActions={[{ label: "أرشفة", onAction }]}
      >
        <thead>
          <tr>
            <th>Label</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.id}>
              <td>{row.label}</td>
            </tr>
          ))}
        </tbody>
      </DataTable>,
    );

    fireEvent.click(screen.getByRole("button", { name: "أرشفة" }));

    expect(onAction).toHaveBeenCalledWith(new Set(["row-2"]));
  });
});
