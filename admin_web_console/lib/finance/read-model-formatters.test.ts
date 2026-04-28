import { describe, expect, it } from "vitest";

import {
  formatArabicDate,
  formatCurrency,
  formatDate,
  formatStatus,
  getStatusColorClass,
} from "./read-model-formatters";

describe("finance read-model formatters", () => {
  it("formats currency with fixed decimals", () => {
    expect(formatCurrency(500, "ILS")).toMatch(/500\.00/);
    const usd = formatCurrency(42.5, "USD");
    expect(usd).toContain("42.50");
    expect(usd).toMatch(/\$|US\$/);
  });

  it("formats timestamps for display", () => {
    const formatted = formatDate("2026-04-01T10:30:00.000Z");

    expect(formatted).toContain("نيسان");
    expect(formatted).toContain("2026");
    expect(formatted).toContain("10:30");
  });

  it("formats date-only values with fixed locale and timezone", () => {
    const formatted = formatArabicDate("2026-04-14T12:00:00.000Z", {
      dateOnly: true,
    });

    expect(formatted).toContain("2026");
    expect(formatted).toContain("نيسان");
    expect(formatted).not.toContain(":");
  });

  it("returns unavailable label for invalid dates", () => {
    expect(formatArabicDate("not-a-date")).toBe("غير متاح");
  });

  it("humanizes status labels", () => {
    expect(formatStatus("approved_and_executed")).toBe("معتمد ومنفذ");
    expect(formatStatus("warn")).toBe("تحذير");
  });

  it("maps statuses to semantic color classes", () => {
    expect(getStatusColorClass("credited")).toBe("status-success");
    expect(getStatusColorClass("pending")).toBe("status-warning");
    expect(getStatusColorClass("fail")).toBe("status-danger");
    expect(getStatusColorClass("unknown_state")).toBe("status-neutral");
  });
});
