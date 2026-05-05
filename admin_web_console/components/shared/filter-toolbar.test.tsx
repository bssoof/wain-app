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

  it("renders active filter chips with label and value", () => {
    render(
      <FilterToolbar
        activeFilters={[
          {
            key: "status",
            label: "الحالة",
            value: "نشط",
            onRemove: vi.fn(),
          },
        ]}
      >
        <span>المحتوى</span>
      </FilterToolbar>,
    );

    expect(screen.getByRole("button", { name: "إزالة الحالة: نشط" })).toBeTruthy();
    expect(screen.getByText("الحالة: نشط")).toBeTruthy();
  });

  it("clicking an active filter chip calls onRemove", () => {
    const onRemove = vi.fn();

    render(
      <FilterToolbar
        activeFilters={[
          {
            key: "city",
            label: "المدينة",
            value: "رام الله",
            onRemove,
          },
        ]}
      >
        <span>المحتوى</span>
      </FilterToolbar>,
    );

    fireEvent.click(screen.getByRole("button", { name: "إزالة المدينة: رام الله" }));

    expect(onRemove).toHaveBeenCalledTimes(1);
  });

  it("active filter chip has the correct aria-label", () => {
    render(
      <FilterToolbar
        activeFilters={[
          {
            key: "type",
            label: "النوع",
            value: "صور",
            onRemove: vi.fn(),
          },
        ]}
      >
        <span>المحتوى</span>
      </FilterToolbar>,
    );

    expect(
      screen
        .getByRole("button", { name: "إزالة النوع: صور" })
        .getAttribute("aria-label"),
    ).toBe("إزالة النوع: صور");
  });

  it("renders clear all button when active filters and onClearAll are provided", () => {
    render(
      <FilterToolbar
        activeFilters={[
          {
            key: "status",
            label: "الحالة",
            value: "نشط",
            onRemove: vi.fn(),
          },
        ]}
        onClearAll={vi.fn()}
      >
        <span>المحتوى</span>
      </FilterToolbar>,
    );

    expect(screen.getByRole("button", { name: "مسح الكل" })).toBeTruthy();
  });

  it("clicking clear all calls onClearAll", () => {
    const onClearAll = vi.fn();

    render(
      <FilterToolbar
        activeFilters={[
          {
            key: "status",
            label: "الحالة",
            value: "نشط",
            onRemove: vi.fn(),
          },
        ]}
        onClearAll={onClearAll}
      >
        <span>المحتوى</span>
      </FilterToolbar>,
    );

    fireEvent.click(screen.getByRole("button", { name: "مسح الكل" }));

    expect(onClearAll).toHaveBeenCalledTimes(1);
  });

  it("renders a controlled search input when search props are provided", () => {
    render(
      <FilterToolbar searchValue="alpha" onSearchChange={vi.fn()}>
        <span>المحتوى</span>
      </FilterToolbar>,
    );

    expect((screen.getByRole("searchbox", { name: "بحث..." }) as HTMLInputElement).value).toBe(
      "alpha",
    );
  });

  it("typing in the controlled search input calls onSearchChange", () => {
    const onSearchChange = vi.fn();

    render(
      <FilterToolbar
        searchValue=""
        onSearchChange={onSearchChange}
        searchPlaceholder="بحث في النتائج"
      >
        <span>المحتوى</span>
      </FilterToolbar>,
    );

    fireEvent.change(screen.getByRole("searchbox", { name: "بحث في النتائج" }), {
      target: { value: "wallet" },
    });

    expect(onSearchChange).toHaveBeenCalledWith("wallet");
  });

  it("renders the search icon with the positioning class", () => {
    render(
      <FilterToolbar searchValue="" onSearchChange={vi.fn()}>
        <span>المحتوى</span>
      </FilterToolbar>,
    );

    const icon = screen.getByTestId("filter-toolbar-search-icon");
    expect(icon.getAttribute("class")).toContain("filter-toolbar__search-icon");
    expect(icon.getAttribute("aria-hidden")).toBe("true");
  });
});
