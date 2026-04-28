import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { ReadStateBanner } from "./read-state-banner";

const AS_OF = "2026-04-01T12:00:00.000Z";
const FETCHED_AT = "2026-04-01T12:05:00.000Z";

describe("ReadStateBanner", () => {
  it("renders fresh read metadata without alert semantics", () => {
    render(
      <ReadStateBanner
        state="success"
        source="callable:testRead"
        asOf={AS_OF}
        fetchedAt={FETCHED_AT}
        testId="read-banner"
      />,
    );

    const banner = screen.getByTestId("read-banner");
    expect(banner.getAttribute("data-read-kind")).toBe("success");
    expect(banner.getAttribute("data-read-state")).toBe("success");
    expect(banner.getAttribute("data-read-stale")).toBe("false");
    expect(screen.queryByRole("alert")).toBeNull();
    expect(screen.getByText(/مصدر البيانات/i)).toBeTruthy();
  });

  it("renders stale read metadata with an operator-visible status note", () => {
    render(
      <ReadStateBanner
        state="stale"
        source="development_fixture"
        asOf={AS_OF}
        fetchedAt={FETCHED_AT}
        staleMessage="هذه البيانات قديمة."
        testId="read-banner"
        staleTestId="read-stale"
      />,
    );

    const banner = screen.getByTestId("read-banner");
    expect(banner.getAttribute("data-read-kind")).toBe("success");
    expect(banner.getAttribute("data-read-state")).toBe("stale");
    expect(banner.getAttribute("data-read-stale")).toBe("true");
    expect(screen.getByTestId("read-stale").textContent).toContain(
      "هذه البيانات قديمة.",
    );
  });

  it("renders empty read copy as a non-error status", () => {
    render(
      <ReadStateBanner
        state="empty"
        source="callable:testRead"
        message="لا توجد سجلات للعرض."
        testId="read-banner"
      />,
    );

    const banner = screen.getByTestId("read-banner");
    expect(banner.getAttribute("data-read-state")).toBe("empty");
    expect(banner.getAttribute("role")).toBe("status");
    expect(screen.getByText("لا توجد سجلات للعرض.")).toBeTruthy();
  });

  it("renders unavailable reads as alerts with attempted source context", () => {
    render(
      <ReadStateBanner
        state="unavailable"
        label="قراءة الدليل"
        message="المصدر غير متاح."
        attemptedSource="callable:listVenuesForAdmin"
        testId="read-banner"
      />,
    );

    const banner = screen.getByTestId("read-banner");
    expect(banner.getAttribute("data-read-kind")).toBe("unavailable");
    expect(banner.getAttribute("data-read-state")).toBe("unavailable");
    expect(screen.getByRole("alert")).toBe(banner);
    expect(screen.getByText(/مصدر البيانات الذي تمت تجربته/i)).toBeTruthy();
    expect(screen.getByText(/الخدمة المتصلة/i)).toBeTruthy();
  });
});
