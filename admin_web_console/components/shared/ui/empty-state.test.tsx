import { fireEvent, render, screen } from "@testing-library/react";
import { Search } from "lucide-react";
import { describe, expect, it, vi } from "vitest";

import { EmptyState } from "./empty-state";

describe("EmptyState", () => {
  it("renders the title", () => {
    render(<EmptyState title="لا توجد نتائج" />);

    expect(screen.getByText("لا توجد نتائج")).not.toBeNull();
    expect(screen.getByRole("status")).not.toBeNull();
  });

  it("renders the description when provided", () => {
    render(<EmptyState description="غيّر الفلتر وحاول مرة أخرى." title="لا توجد نتائج" />);

    expect(screen.getByText("غيّر الفلتر وحاول مرة أخرى.")).not.toBeNull();
  });

  it("renders an action button when action is provided", () => {
    render(
      <EmptyState
        action={{ label: "إعادة المحاولة", onClick: vi.fn() }}
        title="فشل التحميل"
      />,
    );

    const action = screen.getByRole("button", { name: "إعادة المحاولة" });
    expect(action.className).toContain("empty-state__action");
  });

  it("calls action.onClick when the action button is clicked", () => {
    const onClick = vi.fn();

    render(
      <EmptyState
        action={{ label: "إعادة المحاولة", onClick }}
        title="فشل التحميل"
      />,
    );

    fireEvent.click(screen.getByRole("button", { name: "إعادة المحاولة" }));

    expect(onClick).toHaveBeenCalledTimes(1);
  });

  it("uses Inbox as the default icon and supports compact/custom variants", () => {
    const { rerender } = render(<EmptyState compact title="فارغ" />);

    const defaultIcon = screen.getByTestId("empty-state-icon");
    expect(defaultIcon.getAttribute("class")).toContain("empty-state__icon");
    expect(defaultIcon.getAttribute("class")).toContain("lucide-inbox");
    expect(screen.getByRole("status").className).toContain("empty-state--compact");

    rerender(<EmptyState icon={Search} title="بحث" />);
    expect(screen.getByTestId("empty-state-icon").getAttribute("class")).toContain(
      "lucide-search",
    );
  });
});
