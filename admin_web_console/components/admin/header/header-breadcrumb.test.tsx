import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { HeaderBreadcrumb } from "./header-breadcrumb";

describe("HeaderBreadcrumb", () => {
  it("renders all items", () => {
    render(
      <HeaderBreadcrumb
        items={[
          { label: "الرئيسية", href: "/admin" },
          { label: "المالية", href: "/admin/topups" },
          { label: "طلبات الشحن" },
        ]}
      />,
    );

    expect(screen.getByText("الرئيسية")).toBeTruthy();
    expect(screen.getByText("المالية")).toBeTruthy();
    expect(screen.getByText("طلبات الشحن")).toBeTruthy();
    expect(screen.getAllByRole("listitem")).toHaveLength(3);
  });

  it("marks the last item as the current page", () => {
    render(
      <HeaderBreadcrumb
        items={[
          { label: "الرئيسية", href: "/admin" },
          { label: "الجهات", href: "/admin/venues" },
        ]}
      />,
    );

    const nav = screen.getByRole("navigation", { name: "مسار الصفحات" });
    expect(within(nav).getByText("الجهات").getAttribute("aria-current")).toBe("page");
  });

  it("renders href items before the last item as anchors", () => {
    render(
      <HeaderBreadcrumb
        items={[
          { label: "الرئيسية", href: "/admin" },
          { label: "الصور" },
        ]}
      />,
    );

    expect(screen.getByRole("link", { name: "الرئيسية" }).getAttribute("href")).toBe(
      "/admin",
    );
  });

  it("renders nothing when items array is empty", () => {
    const { container } = render(<HeaderBreadcrumb items={[]} />);

    expect(container.firstChild).toBeNull();
  });
});
