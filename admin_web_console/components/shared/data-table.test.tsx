import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { DataTable } from "./data-table";

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
});
