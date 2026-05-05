import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import {
  HeaderEnvironmentBadge,
  type HeaderEnvironment,
} from "./header-env-badge";

const CASES: Array<{ value: HeaderEnvironment; label: string }> = [
  { value: "production", label: "إنتاج" },
  { value: "preview", label: "معاينة" },
  { value: "local", label: "محلي" },
  { value: "unknown", label: "غير محدد" },
];

describe("HeaderEnvironmentBadge", () => {
  it.each(CASES)("renders the correct label for $value", ({ value, label }) => {
    render(<HeaderEnvironmentBadge value={value} />);

    expect(screen.getByText(label)).toBeTruthy();
  });

  it("applies the correct variant class", () => {
    render(<HeaderEnvironmentBadge value="preview" />);

    expect(screen.getByText("معاينة").className).toContain(
      "header-env-badge--preview",
    );
  });

  it("uses the contrast class hook for the selected variant", () => {
    render(<HeaderEnvironmentBadge value="production" />);

    const badge = screen.getByText("إنتاج");
    expect(badge.className).toContain("header-env-badge");
    expect(badge.className).toContain("header-env-badge--production");
  });
});
