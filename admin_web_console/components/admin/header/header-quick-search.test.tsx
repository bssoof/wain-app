import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { HeaderQuickSearch } from "./header-quick-search";

const routes = [
  { path: "/admin/dashboard", label: "نظرة عامة" },
  { path: "/admin/topups", label: "طلبات الشحن" },
  { path: "/admin/venues", label: "الجهات" },
];

describe("HeaderQuickSearch", () => {
  it("opens via trigger click", async () => {
    render(<HeaderQuickSearch routes={routes} onNavigate={vi.fn()} />);

    fireEvent.click(screen.getByRole("button", { name: "بحث" }));

    expect(screen.getByRole("dialog")).toBeTruthy();
    await waitFor(() => {
      expect(document.activeElement).toBe(
        screen.getByRole("searchbox", { name: "بحث في صفحات الإدارة" }),
      );
    });
  });

  it("opens via Cmd+K", () => {
    render(<HeaderQuickSearch routes={routes} onNavigate={vi.fn()} />);

    fireEvent.keyDown(document, { key: "k", metaKey: true });

    expect(screen.getByRole("dialog")).toBeTruthy();
  });

  it("filters routes by query", () => {
    render(<HeaderQuickSearch routes={routes} onNavigate={vi.fn()} />);

    fireEvent.click(screen.getByRole("button", { name: "بحث" }));
    fireEvent.change(screen.getByRole("searchbox"), {
      target: { value: "topups" },
    });

    expect(screen.getByText("طلبات الشحن")).toBeTruthy();
    expect(screen.queryByText("الجهات")).toBeNull();
  });

  it("Enter on highlighted result calls onNavigate", () => {
    const onNavigate = vi.fn();
    render(<HeaderQuickSearch routes={routes} onNavigate={onNavigate} />);

    fireEvent.click(screen.getByRole("button", { name: "بحث" }));
    fireEvent.change(screen.getByRole("searchbox"), {
      target: { value: "venues" },
    });
    fireEvent.keyDown(screen.getByRole("searchbox"), { key: "Enter" });

    expect(onNavigate).toHaveBeenCalledWith("/admin/venues");
    expect(screen.queryByRole("dialog")).toBeNull();
  });

  it("ArrowDown changes the highlighted result before Enter", () => {
    const onNavigate = vi.fn();
    render(<HeaderQuickSearch routes={routes} onNavigate={onNavigate} />);

    fireEvent.click(screen.getByRole("button", { name: "بحث" }));
    fireEvent.keyDown(screen.getByRole("searchbox"), { key: "ArrowDown" });
    fireEvent.keyDown(screen.getByRole("searchbox"), { key: "Enter" });

    expect(onNavigate).toHaveBeenCalledWith("/admin/topups");
  });

  it("Esc closes", () => {
    render(<HeaderQuickSearch routes={routes} onNavigate={vi.fn()} />);

    fireEvent.click(screen.getByRole("button", { name: "بحث" }));
    fireEvent.keyDown(document, { key: "Escape" });

    expect(screen.queryByRole("dialog")).toBeNull();
  });

  it("has aria-modal true", () => {
    render(<HeaderQuickSearch routes={routes} onNavigate={vi.fn()} />);

    fireEvent.click(screen.getByRole("button", { name: "بحث" }));

    expect(screen.getByRole("dialog").getAttribute("aria-modal")).toBe("true");
  });

  it("closes via backdrop click", () => {
    render(<HeaderQuickSearch routes={routes} onNavigate={vi.fn()} />);

    fireEvent.click(screen.getByRole("button", { name: "بحث" }));
    fireEvent.click(screen.getByTestId("header-quick-search-backdrop"));

    expect(screen.queryByRole("dialog")).toBeNull();
  });
});
