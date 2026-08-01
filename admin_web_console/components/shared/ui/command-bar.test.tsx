import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { CommandBar } from "./command-bar";

describe("CommandBar", () => {
  it("has role toolbar", () => {
    render(<CommandBar />);

    expect(screen.getByRole("toolbar")).toBeTruthy();
  });

  it("renders primary slot content", () => {
    render(<CommandBar primary={<button type="button">حفظ</button>} />);

    expect(screen.getByRole("button", { name: "حفظ" })).toBeTruthy();
  });

  it("renders secondary slot content", () => {
    render(<CommandBar secondary={<button type="button">تصدير</button>} />);

    expect(screen.getByRole("button", { name: "تصدير" })).toBeTruthy();
  });

  it("applies dense class when dense is true", () => {
    render(<CommandBar dense />);

    expect(screen.getByRole("toolbar").className).toContain("command-bar--dense");
  });

  it("has aria-label", () => {
    render(<CommandBar />);

    expect(screen.getByRole("toolbar").getAttribute("aria-label")).toBe("شريط الأوامر");
  });
});
