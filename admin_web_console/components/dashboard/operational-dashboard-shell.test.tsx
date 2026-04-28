import React from "react";
import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import { OperationalDashboardShell } from "./operational-dashboard-shell";
import type { OpsDashboardSummary } from "@/lib/dashboard/dashboard-models";

describe("OperationalDashboardShell", () => {
  const baseSummary: OpsDashboardSummary = {
    generatedAt: "2026-04-11T00:00:00.000Z",
    topUpQueue: {
      state: "success",
      asOf: "2026-04-11T00:00:00.000Z",
      source: "mock1",
      data: { pendingCount: 4, recentPending: [] },
    },
    walletReadiness: {
      state: "success",
      asOf: "2026-04-11T00:00:00.000Z",
      source: "mock2",
      data: {
        overallStatus: "ready",
        failingChecksCount: 0,
        warningChecksCount: 0,
        failingChecksPreview: [],
      },
    },
    venueDirectory: {
      state: "success",
      asOf: "2026-04-11T00:00:00.000Z",
      source: "mock3",
      data: {
        totalVenues: 10,
        readyVenues: 8,
        lowBalanceVenues: 1,
        inactiveWallets: 1,
        lowBalancePreview: [],
      },
    },
    contentModeration: {
      state: "success",
      asOf: "2026-04-11T00:00:00.000Z",
      source: "mock4",
      data: { pendingOffers: 2, pendingStories: 3, recentOffersPreview: [] },
    },
  };

  it("renders all widgets for success state", () => {
    render(<OperationalDashboardShell summary={baseSummary} />);

    expect(screen.getByText("نظرة عامة")).toBeDefined();
    expect(screen.getByLabelText("ملخص سريع")).toBeDefined();
    expect(screen.getByText("طلبات تحتاج قرار")).toBeDefined();
    expect(screen.getByText("محتوى للمراجعة")).toBeDefined();
    expect(screen.getByText("8 من 10")).toBeDefined();

    // TopUp
    expect(screen.getAllByText("4").length).toBeGreaterThan(0);
    expect(screen.getByText("طلبات بانتظار المراجعة")).toBeDefined();

    // Wallet Readiness
    expect(screen.getByText("جميع الأنظمة تعمل بشكل طبيعي")).toBeDefined();

    // Venue Directory
    expect(screen.getByText("10")).toBeDefined();
    expect(screen.getByText("الإجمالي")).toBeDefined();
    expect(screen.getByText("8")).toBeDefined();
    expect(screen.getAllByText("جاهز").length).toBeGreaterThan(0);

    // Content Moderation
    expect(screen.getAllByText("5").length).toBeGreaterThan(0); // total pending 2+3
    expect(screen.getByText("2 عروض")).toBeDefined();
  });

  it("renders global stale warning if any widget is stale", () => {
    const summary: OpsDashboardSummary = {
      ...baseSummary,
      venueDirectory: {
        ...baseSummary.venueDirectory,
        state: "stale"
      }
    };

    render(<OperationalDashboardShell summary={summary} />);
    expect(screen.getByText("بعض الأقسام تعتمد على بيانات قديمة.")).toBeDefined();
  });

  it("gracefully renders unavailable lock block and hides data rendering", () => {
    const summary: OpsDashboardSummary = {
      ...baseSummary,
      contentModeration: {
        state: "unavailable",
        asOf: "2026-04-11T00:00:00.000Z",
        source: "mock-fail",
        data: null,
        message: "Forbidden: insufficient claims for this section.",
      }
    };

    render(<OperationalDashboardShell summary={summary} />);

    expect(screen.getByText("المعلومات غير متاحة")).toBeDefined();
    expect(screen.getByText("تم رفض الوصول إلى هذا المصدر.")).toBeDefined();

    // Total number of pending items (5) shouldn't appear from Content Moderation
    expect(screen.queryByText("5")).toBeNull();
    // We can be sure Offers 2 doesn't show
    expect(screen.queryByText("2 عروض")).toBeNull();
  });

  it("gracefully renders empty notification without data", () => {
    const summary: OpsDashboardSummary = {
      ...baseSummary,
      topUpQueue: {
        state: "empty",
        asOf: "2026-04-11T00:00:00.000Z",
        source: "mock-empty",
        data: { pendingCount: 0, recentPending: [] },
        message: "No mock data present."
      }
    };

    render(<OperationalDashboardShell summary={summary} />);
    expect(screen.getByText("لا توجد بيانات تجريبية حاليًا.")).toBeDefined();
    expect(screen.queryByText("طلبات بانتظار المراجعة")).toBeNull();
  });
});
