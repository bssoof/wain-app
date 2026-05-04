import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import {
  FilterField,
  FilterSelect,
  FilterTextInput,
  FilterToolbar,
} from "./filter-toolbar";

describe("FilterToolbar", () => {
  it("renders labeled controls with stable class hooks and test ids", () => {
    render(
      <FilterToolbar className="legacy-filter-row" testId="filters">
        <FilterField label="Search" className="legacy-filter-field">
          <FilterTextInput
            className="legacy-filter-input"
            data-testid="search-input"
            value=""
            onChange={() => {}}
          />
        </FilterField>
        <FilterField label="Status" className="legacy-filter-field">
          <FilterSelect
            className="legacy-filter-select"
            data-testid="status-filter"
            value=""
            onChange={() => {}}
          >
            <option value="">All</option>
          </FilterSelect>
        </FilterField>
      </FilterToolbar>,
    );

    const toolbar = screen.getByTestId("filters");
    const input = screen.getByTestId("search-input");
    const select = screen.getByTestId("status-filter");

    expect(toolbar.className).toContain("filter-toolbar");
    expect(toolbar.className).toContain("legacy-filter-row");
    expect(input.className).toContain("filter-toolbar__input");
    expect(input.className).toContain("legacy-filter-input");
    expect(select.className).toContain("filter-toolbar__select");
    expect(select.className).toContain("legacy-filter-select");
    expect(screen.getByText("Search").closest("label")?.contains(input)).toBe(
      true,
    );
    expect(screen.getByText("Status").closest("label")?.contains(select)).toBe(
      true,
    );
  });

  it("passes input and select change events through unchanged", () => {
    const onInputChange = vi.fn();
    const onSelectChange = vi.fn();

    render(
      <FilterToolbar>
        <FilterField label="Search">
          <FilterTextInput
            data-testid="search-input"
            value=""
            onChange={onInputChange}
          />
        </FilterField>
        <FilterField label="Status">
          <FilterSelect
            data-testid="status-filter"
            value=""
            onChange={onSelectChange}
          >
            <option value="">All</option>
            <option value="active">Active</option>
          </FilterSelect>
        </FilterField>
      </FilterToolbar>,
    );

    fireEvent.change(screen.getByTestId("search-input"), {
      target: { value: "alpha" },
    });
    fireEvent.change(screen.getByTestId("status-filter"), {
      target: { value: "active" },
    });

    expect(onInputChange).toHaveBeenCalledTimes(1);
    expect(onSelectChange).toHaveBeenCalledTimes(1);
  });
});
