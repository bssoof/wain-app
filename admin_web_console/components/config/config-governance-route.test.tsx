import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type { ConfigGovernanceSnapshot } from "@/lib/config";

const requireRouteAccessMock = vi.fn();
const getRouteDefinitionMock = vi.fn();
const loadConfigGovernanceSnapshotMock = vi.fn();
const computeConfigAffordancesMock = vi.fn();

vi.mock("@/lib/auth/route-guards", () => ({
  requireRouteAccess: (...args: unknown[]) => requireRouteAccessMock(...args),
}));

vi.mock("@/lib/navigation/admin-route-map", () => ({
  getRouteDefinition: (...args: unknown[]) => getRouteDefinitionMock(...args),
}));

vi.mock("@/lib/config", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/lib/config")>();
  return {
    ...actual,
    computeConfigAffordances: (...args: unknown[]) =>
      computeConfigAffordancesMock(...args),
  };
});

vi.mock("@/lib/config/config-read-loader", () => ({
  loadConfigGovernanceSnapshot: (...args: unknown[]) =>
    loadConfigGovernanceSnapshotMock(...args),
}));

function session(): AdminSession {
  return {
    uid: "finance-admin-1",
    primaryRole: "finance_admin",
    roles: ["finance_admin"],
    roleSource: "claims",
  };
}

function snapshot(): ConfigGovernanceSnapshot {
  return {
    generatedAt: "2026-04-12T12:00:00.000Z",
    source: "callable:getAdminConfigGovernanceBundle",
    scope: "wallet_feature_pricing/default",
    state: "success",
    freshnessNote: "Snapshot is fresh.",
    live: {
      exists: true,
      version: 2,
      pricing: {
        story_promote_1d: 4,
        story_promote_3d: 8,
        story_promote_7d: 15,
        offer_pin_1d: 5,
        offer_pin_3d: 10,
        offer_pin_7d: 18,
        currency: "ILS",
      },
      updatedAt: "2026-04-12T11:59:00.000Z",
      updatedByUid: "finance-admin-a",
      updatedByRole: "finance_admin",
    },
    draft: {
      exists: true,
      status: "reviewed",
      draftVersion: 3,
      pricing: {
        story_promote_1d: 5,
        story_promote_3d: 9,
        story_promote_7d: 16,
        offer_pin_1d: 6,
        offer_pin_3d: 11,
        offer_pin_7d: 20,
        currency: "ILS",
      },
      validationIssues: [],
      reviewedByUid: "finance-admin-a",
      reviewedAt: "2026-04-12T11:58:00.000Z",
      updatedAt: "2026-04-12T11:58:00.000Z",
    },
    history: [],
  };
}

describe("config governance route", () => {
  it("requires route access and renders config governance shell", async () => {
    getRouteDefinitionMock.mockReturnValue({
      key: "config",
      path: "/admin/config",
      title: "إدارة الإعدادات",
      scopeNote: "مسودة ومراجعة ونشر واسترجاع للإعدادات مع تاريخ تغييرات مدعوم من الخادم.",
    });
    requireRouteAccessMock.mockResolvedValue(session());
    computeConfigAffordancesMock.mockReturnValue({
      canView: true,
      canDraft: true,
      canReview: true,
      canPublish: true,
      canRollback: true,
    });
    loadConfigGovernanceSnapshotMock.mockResolvedValue(snapshot());

    const module = await import("@/app/(protected)/admin/config/page");
    const AdminConfigPage = module.default;

    render(await AdminConfigPage());

    expect(requireRouteAccessMock).toHaveBeenCalledWith("config", "/admin/config");
    expect(loadConfigGovernanceSnapshotMock).toHaveBeenCalledTimes(1);
    expect(computeConfigAffordancesMock).toHaveBeenCalledTimes(1);
    expect(screen.getByRole("heading", { name: "إدارة الإعدادات" })).toBeTruthy();
    expect(screen.getByTestId("config-governance-shell")).toBeTruthy();
  });
});
