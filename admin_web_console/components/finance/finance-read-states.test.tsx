import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type {
  LedgerReadData,
  ReadinessReadData,
  TopUpReadData,
} from "@/lib/finance/finance-read-loader";
import type { FinanceReadResult } from "@/lib/finance/finance-read-types";
import { MOCK_READINESS_REPORT } from "@/lib/finance/read-models";

import { FinanceReadStateBanner } from "./finance-read-banner";
import { FinanceCommandProvider } from "./finance-command-provider";
import {
  ReadinessChecksPanel,
  ReadinessCommandPanel,
  ReadinessReportCard,
} from "./readiness-panel";
import { TopUpQueueTable } from "./topup-queue-table";
import { WalletAuditTable } from "./wallet-audit-table";

vi.mock("next/navigation", () => ({
  useRouter: () => ({
    refresh: vi.fn(),
  }),
}));

const AS_OF = "2026-04-01T12:00:00.000Z";
const FETCHED = "2026-04-01T12:00:05.000Z";
const SRC = "test snapshot";

function ok<T>(data: T, stale: boolean): FinanceReadResult<T> {
  return {
    kind: "success",
    data,
    asOf: AS_OF,
    fetchedAt: FETCHED,
    source: SRC,
    stale,
  };
}

function financeSession(): AdminSession {
  return {
    uid: "admin-1",
    primaryRole: "finance_admin",
    roles: ["finance_admin"],
    roleSource: "claims",
  };
}

function opsSession(): AdminSession {
  return {
    uid: "admin-2",
    primaryRole: "ops_viewer",
    roles: ["ops_viewer"],
    roleSource: "claims",
  };
}

describe("finance read-state rendering", () => {
  it("renders empty top-up queue without fabricating rows", () => {
    const read: FinanceReadResult<TopUpReadData> = ok({ pending: [] }, false);
    render(
      <FinanceCommandProvider session={financeSession()}>
        <TopUpQueueTable readResult={read} />
      </FinanceCommandProvider>,
    );
    expect(screen.getByTestId("finance-read-empty").textContent).toMatch(
      /لا توجد طلبات شحن تنتظر القرار/i,
    );
  });

  it("renders empty ledger read state", () => {
    const read: FinanceReadResult<LedgerReadData> = ok({ entries: [] }, false);
    render(
      <FinanceCommandProvider session={financeSession()}>
        <WalletAuditTable readResult={read} />
      </FinanceCommandProvider>,
    );
    expect(screen.getByTestId("finance-read-empty").textContent).toMatch(
      /لا توجد عمليات/i,
    );
  });

  it("renders readiness unavailable for report and checks panel", () => {
    const read: FinanceReadResult<ReadinessReadData> = {
      kind: "unavailable",
      message: "Upstream readiness feed failed.",
      attemptedSource: "https://example.test/readiness",
    };

    render(
      <>
        <ReadinessReportCard readResult={read} />
        <ReadinessChecksPanel readResult={read} />
      </>,
    );

    expect(screen.getByText(/تعذر عرض حالة المحفظة/i)).toBeTruthy();
    expect(screen.getByTestId("finance-readiness-checks-unavailable")).toBeTruthy();
  });

  it("renders empty readiness checks list", () => {
    const read: FinanceReadResult<ReadinessReadData> = ok(
      {
        report: {
          generatedAt: AS_OF,
          overallStatus: "ready",
          summary: "All quiet",
          checks: [],
        },
      },
      false,
    );

    render(<ReadinessChecksPanel readResult={read} />);
    expect(screen.getByTestId("finance-read-empty").textContent).toMatch(
      /لا توجد فحوصات نظام/i,
    );
  });

  it("renders readiness report and checks with operator-friendly Arabic copy", () => {
    const read: FinanceReadResult<ReadinessReadData> = ok(
      { report: MOCK_READINESS_REPORT },
      false,
    );

    render(
      <>
        <ReadinessReportCard readResult={read} />
        <ReadinessChecksPanel readResult={read} />
      </>,
    );

    expect(screen.getByTestId("finance-readiness-summary")).toBeTruthy();
    expect(screen.getByText(/النظام يعمل، مع وجود نقاط تحتاج متابعة/i)).toBeTruthy();
    expect(screen.getByText(/تدفق عمليات المحفظة/i)).toBeTruthy();
    expect(screen.queryByText(/Core wallet services/i)).toBeNull();
    expect(screen.queryByText(/Ledger stream health/i)).toBeNull();
  });

  it("shows a direct venues link for wallet reports coverage check", () => {
    const read: FinanceReadResult<ReadinessReadData> = ok(
      {
        report: {
          generatedAt: AS_OF,
          overallStatus: "warning",
          summary: "Wallet reports need attention",
          checks: [
            {
              id: "wallet_reports_coverage",
              label: "wallet reports coverage",
              status: "warn",
              details: "reports: 2",
            },
          ],
        },
      },
      false,
    );

    render(<ReadinessChecksPanel readResult={read} session={financeSession()} />);

    const reportAction = screen.getByTestId("readiness-check-action-wallet_reports_coverage");
    expect(reportAction.getAttribute("href")).toBe("/admin/venues");
    expect(reportAction.textContent).toMatch(/عرض تقارير الجهات/i);
  });

  it("shows a direct venues link for low balance scan check", () => {
    const read: FinanceReadResult<ReadinessReadData> = ok(
      {
        report: {
          generatedAt: AS_OF,
          overallStatus: "warning",
          summary: "Low balance scan requires review",
          checks: [
            {
              id: "wallet_low_balance_scan",
              label: "wallet low balance scan",
              status: "warn",
              details: "low balances: 3",
            },
          ],
        },
      },
      false,
    );

    render(<ReadinessChecksPanel readResult={read} session={financeSession()} />);

    const reportAction = screen.getByTestId("readiness-check-action-wallet_low_balance_scan");
    expect(reportAction.getAttribute("href")).toBe("/admin/venues");
    expect(reportAction.textContent).toMatch(/مراجعة أرصدة الجهات/i);
  });

  it("hides readiness deep links when session is missing", () => {
    const read: FinanceReadResult<ReadinessReadData> = ok(
      {
        report: {
          generatedAt: AS_OF,
          overallStatus: "warning",
          summary: "Wallet reports need attention",
          checks: [
            {
              id: "wallet_reports_coverage",
              label: "wallet reports coverage",
              status: "warn",
              details: "reports: 2",
            },
          ],
        },
      },
      false,
    );

    render(<ReadinessChecksPanel readResult={read} />);

    expect(screen.queryByTestId("readiness-check-action-wallet_reports_coverage")).toBeNull();
  });

  it("shows stale banner copy when snapshot is stale", () => {
    const read: FinanceReadResult<TopUpReadData> = ok({ pending: [] }, true);
    render(<FinanceReadStateBanner result={read} label="قراءة طلبات الشحن" />);
    expect(screen.getByTestId("finance-read-stale")).toBeTruthy();
    expect(screen.getByTestId("finance-read-banner").getAttribute("data-read-stale")).toBe(
      "true",
    );
  });

  it("shows unavailable read banner with attempted source", () => {
    const read: FinanceReadResult<TopUpReadData> = {
      kind: "unavailable",
      message: "Network error",
      attemptedSource: "https://x",
    };
    render(<FinanceReadStateBanner result={read} label="قراءة سجل المحفظة" />);
    expect(screen.getByTestId("finance-read-banner").getAttribute("data-read-kind")).toBe(
      "unavailable",
    );
    expect(screen.getByText(/مصدر البيانات الذي تمت تجربته/i)).toBeTruthy();
  });

  it("keeps mutation controls hidden for non-finance roles on successful read", () => {
    const read: FinanceReadResult<TopUpReadData> = ok(
      {
        pending: [
          {
            id: "t1",
            userId: "u1",
            userName: "U",
            amount: 1,
            currency: "ILS",
            providerReference: "p",
            createdAt: AS_OF,
            status: "pending",
          },
        ],
      },
      false,
    );

    render(
      <FinanceCommandProvider session={opsSession()}>
        <TopUpQueueTable readResult={read} />
      </FinanceCommandProvider>,
    );

    expect(screen.queryByTestId("finance-topup-t1-approve")).toBeNull();
  });

  it("shows finance mutation controls when role and read succeed", () => {
    const read: FinanceReadResult<TopUpReadData> = ok(
      {
        pending: [
          {
            id: "t_finance",
            userId: "u1",
            userName: "U",
            amount: 1,
            currency: "ILS",
            providerReference: "p",
            createdAt: AS_OF,
            status: "pending",
          },
        ],
      },
      false,
    );

    render(
      <FinanceCommandProvider session={financeSession()}>
        <TopUpQueueTable readResult={read} />
      </FinanceCommandProvider>,
    );

    expect(screen.getByTestId("finance-topup-t_finance-approve")).toBeTruthy();
  });

  it("still exposes readiness command for ops_viewer when report read succeeds", () => {
    const read: FinanceReadResult<ReadinessReadData> = ok(
      { report: MOCK_READINESS_REPORT },
      false,
    );

    render(
      <FinanceCommandProvider session={opsSession()}>
        <ReadinessReportCard readResult={read} />
        <ReadinessCommandPanel />
      </FinanceCommandProvider>,
    );

    expect(screen.getByRole("button", { name: /تحديث حالة النظام/i })).toBeTruthy();
  });
});
