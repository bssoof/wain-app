import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { SkeletonBlock } from "./skeleton-block";

describe("SkeletonBlock", () => {
  it("renders with role=status", () => {
    render(<SkeletonBlock />);

    const block = screen.getByRole("status", { name: "جاري التحميل" });
    expect(block.className).toContain("skeleton-block");
  });

  it("renders multiple blocks when count is greater than one", () => {
    const { container } = render(<SkeletonBlock count={3} />);

    const wrapper = screen.getByRole("status", { name: "جاري التحميل" });
    expect(wrapper.className).toContain("skeleton-block-group");
    expect(container.querySelectorAll(".skeleton-block")).toHaveLength(3);
  });

  it("applies the requested variant class", () => {
    const { rerender } = render(<SkeletonBlock variant="text" />);

    expect(screen.getByRole("status").className).toContain("skeleton-block--text");

    rerender(<SkeletonBlock variant="circle" />);
    expect(screen.getByRole("status").className).toContain("skeleton-block--circle");
  });

  it("applies width and height styles with number values converted to px", () => {
    render(<SkeletonBlock height={24} width={120} />);

    const block = screen.getByRole("status") as HTMLElement;
    expect(block.style.width).toBe("120px");
    expect(block.style.height).toBe("24px");
  });

  it("keeps string width and height values as provided", () => {
    render(<SkeletonBlock height="2rem" width="50%" />);

    const block = screen.getByRole("status") as HTMLElement;
    expect(block.style.width).toBe("50%");
    expect(block.style.height).toBe("2rem");
  });
});
