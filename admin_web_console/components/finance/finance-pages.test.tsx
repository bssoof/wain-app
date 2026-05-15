import { render, screen } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type {
  LedgerReadData,
  TopUpReadData,
} from "@/lib/finance/finance-read-loader";
import type { FinanceReadResult } from "@/lib/finance/finance-read-types";
import type { TopUpRequest, WalletLedgerEntry } from "@/lib/finance/read-models";

const requireRouteAccessMock = vi.fn();
const getRouteDefinitionMock = vi.fn();
const loadTopUpQueueReadMock = vi.fn();
const loadWalletLedgerReadMock = vi.fn();
const routerRefreshMock = vi.fn();

vi.mock("next/navigation", () => ({
  useRouter: () => ({
    refresh: routerRefreshMock,
  }),
}));

vi.mock("@/lib/auth/route-guards", () => ({
  requireRouteAccess: (...args: unknown[]) => requireRouteAccessMock(...args),
}));

vi.mock("@/lib/navigation/admin-route-map", () => ({
  getRouteDefinition: (...args: unknown[]) => getRouteDefinitionMock(...args),
}));

vi.mock("@/lib/finance/finance-read-loader", () => ({
  loadTopUpQueueRead: (...args: unknown[]) => loadTopUpQueueReadMock(...args),
  loadWalletLedgerRead: (...args: unknown[]) => loadWalletLedgerReadMock(...args),
}));

vi.mock("@/components/finance/reversals-tabs", () => ({
  ReversalsTabs: () => (
    <div>
      <div role="tablist" aria-label="أنواع طلبات العكس">
        <button role="tab" type="button">
          طلبات التجار
        </button>
        <button role="tab" type="button">
          طلبات إدارية
        </button>
      </div>
      <label>
        رقم طلب التصحيح
        <input aria-label="رقم طلب التصحيح" />
      </label>
    </div>
  ),
}));

const sampleTopUp: TopUpRequest = {
  id: "topup_route_1",
  userId: "user_route_1",
  userName: "Route User",
  venueId: "venue_route_1",
  amount: 25,
  currency: "ILS",
  providerReference: "PSP-ROUTE",
  createdAt: "2026-04-01T10:00:00.000Z",
  status: "pending",
};

const sampleLedgerEntry: WalletLedgerEntry = {
  id: "entry_route_1",
  venueId: "venue_route_1",
  userId: "user_route_2",
  userName: "Route Ledger User",
  type: "debit",
  amount: 15,
  currency: "ILS",
  description: "Story promotion",
  reference: "story_route_1",
  createdAt: "2026-04-01T10:05:00.000Z",
};

function session(): AdminSession {
  return {
    uid: "finance-route-admin",
    primaryRole: "finance_admin",
    roles: ["finance_admin"],
    roleSource: "claims",
  };
}

function topUpReadResult(): FinanceReadResult<TopUpReadData> {
  return {
    kind: "success",
    data: { pending: [sampleTopUp] },
    asOf: "2026-04-01T10:00:00.000Z",
    fetchedAt: "2026-04-01T10:00:05.000Z",
    source: "route-test",
    stale: false,
  };
}

function ledgerReadResult(): FinanceReadResult<LedgerReadData> {
  return {
    kind: "success",
    data: { entries: [sampleLedgerEntry] },
    asOf: "2026-04-01T10:00:00.000Z",
    fetchedAt: "2026-04-01T10:00:05.000Z",
    source: "route-test",
    stale: false,
  };
}

beforeEach(() => {
  vi.clearAllMocks();
  requireRouteAccessMock.mockResolvedValue(session());
  getRouteDefinitionMock.mockImplementation((key: string) => ({
    key,
    path:
      key === "wallet_audit"
        ? "/admin/wallet-audit"
        : key === "reversals"
          ? "/admin/reversals"
          : "/admin/topups",
    title: key,
    scopeNote: "route scope",
  }));
});

describe("finance pages", () => {
  it("renders top-ups PageHeader with export action slot", async () => {
    loadTopUpQueueReadMock.mockResolvedValue(topUpReadResult());

    const module = await import("@/app/(protected)/admin/topups/page");
    const TopUpsPage = module.default;

    render(await TopUpsPage());

    expect(requireRouteAccessMock).toHaveBeenCalledWith("topups", "/admin/topups");
    expect(loadTopUpQueueReadMock).toHaveBeenCalledTimes(1);
    expect(
      screen.getByRole("heading", { level: 1, name: "عمليات الشحن" }),
    ).toBeTruthy();
    expect(screen.getByRole("button", { name: "تنزيل الجدول" })).toBeTruthy();
  });

  it("renders wallet audit PageHeader with compact ledger table", async () => {
    loadWalletLedgerReadMock.mockResolvedValue(ledgerReadResult());

    const module = await import("@/app/(protected)/admin/wallet-audit/page");
    const WalletAuditPage = module.default;

    render(await WalletAuditPage());

    expect(requireRouteAccessMock).toHaveBeenCalledWith(
      "wallet_audit",
      "/admin/wallet-audit",
    );
    expect(loadWalletLedgerReadMock).toHaveBeenCalledTimes(1);
    expect(
      screen.getByRole("heading", { level: 1, name: "سجل المحفظة" }),
    ).toBeTruthy();
    expect(screen.getByTestId("finance-ledger-table").getAttribute("data-table-density")).toBe(
      "compact",
    );
  });

  it("renders reversals PageHeader while preserving approval panel", async () => {
    const module = await import("@/app/(protected)/admin/reversals/page");
    const AdminReversalsPage = module.default;

    render(await AdminReversalsPage());

    expect(requireRouteAccessMock).toHaveBeenCalledWith(
      "reversals",
      "/admin/reversals",
    );
    expect(
      screen.getByRole("heading", { level: 1, name: "طلبات العكس" }),
    ).toBeTruthy();
    expect(screen.getByRole("tab", { name: "طلبات التجار" })).toBeTruthy();
    expect(screen.getByRole("tab", { name: "طلبات إدارية" })).toBeTruthy();
    expect(screen.getByLabelText(/رقم طلب التصحيح/i)).toBeTruthy();
  });
});
