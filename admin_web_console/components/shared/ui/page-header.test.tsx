import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { PageHeader } from "./page-header";

describe("PageHeader", () => {
  it("renders title as h1", () => {
    render(<PageHeader title="لوحة التحكم" />);

    expect(
      screen.getByRole("heading", { level: 1, name: "لوحة التحكم" }),
    ).toBeTruthy();
  });

  it("renders breadcrumb items with proper roles", () => {
    render(
      <PageHeader
        title="المراجعة"
        breadcrumb={[
          { label: "الرئيسية", href: "/admin" },
          { label: "المراجعة" },
        ]}
      />,
    );

    expect(screen.getByRole("navigation", { name: "مسار الصفحات" })).toBeTruthy();
    expect(screen.getByRole("list")).toBeTruthy();
    expect(screen.getAllByRole("listitem")).toHaveLength(2);
    expect(screen.getByRole("link", { name: "الرئيسية" }).getAttribute("href")).toBe(
      "/admin",
    );
  });

  it("marks the last breadcrumb item without href as current page", () => {
    render(
      <PageHeader
        title="التفاصيل"
        breadcrumb={[
          { label: "الأماكن", href: "/admin/venues" },
          { label: "التفاصيل" },
        ]}
      />,
    );

    const breadcrumbNav = screen.getByRole("navigation", { name: "مسار الصفحات" });
    expect(within(breadcrumbNav).getByText("التفاصيل").getAttribute("aria-current")).toBe(
      "page",
    );
  });

  it("renders actions slot", () => {
    render(
      <PageHeader
        title="طلبات الشحن"
        actions={<button type="button">تحديث</button>}
      />,
    );

    expect(screen.getByRole("button", { name: "تحديث" })).toBeTruthy();
  });

  it("omits description element when not provided", () => {
    const { container } = render(<PageHeader title="الإعدادات" />);

    expect(container.querySelector(".page-header__description")).toBeNull();
  });
});
