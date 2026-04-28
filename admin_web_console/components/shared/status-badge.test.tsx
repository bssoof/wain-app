import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { StatusBadge } from "./status-badge";

describe("StatusBadge", () => {
  it("renders a normalized status pill with an explicit tone", () => {
    render(
      <StatusBadge tone="success" testId="status-badge">
        جاهز
      </StatusBadge>,
    );

    const badge = screen.getByTestId("status-badge");
    expect(badge.className).toContain("status-pill");
    expect(badge.className).toContain("status-success");
    expect(badge.textContent).toBe("جاهز");
  });

  it("keeps legacy class hooks and span attributes when provided", () => {
    render(
      <StatusBadge
        className="status-warning custom-hook"
        testId="status-badge-legacy"
        title="legacy"
      >
        تحذير
      </StatusBadge>,
    );

    const badge = screen.getByTestId("status-badge-legacy");
    expect(badge.className).toContain("status-pill");
    expect(badge.className).toContain("status-warning");
    expect(badge.className).toContain("custom-hook");
    expect(badge.getAttribute("title")).toBe("legacy");
  });
});
