import { fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { AdminRole } from "@/lib/navigation/admin-contract";
import type {
  ConfigCommandTransport,
  ConfigGovernanceSnapshot,
  ConfigSurfaceAffordances,
} from "@/lib/config";

import { ConfigCommandProvider } from "./config-command-provider";
import { ConfigGovernanceShell } from "./config-governance-shell";

function createSnapshot(): ConfigGovernanceSnapshot {
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
    history: [
      {
        id: "history-1",
        eventType: "config_published",
        liveVersion: 2,
        previousLiveVersion: 1,
        rollbackToVersion: null,
        sourceHistoryId: null,
        commandId: "publish_cmd_1",
        correlationId: "publish_corr_1",
        reason: "weekly_pricing_update",
        note: null,
        publishedByUid: "finance-admin-b",
        publishedByRole: "finance_admin",
        reviewedByUid: "finance-admin-a",
        publishedAt: "2026-04-12T11:59:00.000Z",
      },
    ],
  };
}

function createSession(role: AdminRole) {
  return {
    uid: `${role}-uid`,
    primaryRole: role,
    roles: [role],
    roleSource: "claims" as const,
  };
}

const FULL_AFFORDANCES: ConfigSurfaceAffordances = {
  canView: true,
  canDraft: true,
  canReview: true,
  canPublish: true,
  canRollback: true,
};

const READ_ONLY_AFFORDANCES: ConfigSurfaceAffordances = {
  canView: true,
  canDraft: false,
  canReview: false,
  canPublish: false,
  canRollback: false,
};

function renderShell(options?: {
  role?: AdminRole;
  transport?: ConfigCommandTransport;
  snapshot?: ConfigGovernanceSnapshot;
  affordances?: ConfigSurfaceAffordances;
}) {
  const snapshot = options?.snapshot ?? createSnapshot();
  const affordances = options?.affordances ?? FULL_AFFORDANCES;
  const ui = <ConfigGovernanceShell snapshot={snapshot} affordances={affordances} />;

  if (!options?.role) {
    return render(ui);
  }

  return render(
    <ConfigCommandProvider session={createSession(options.role)} transport={options.transport}>
      {ui}
    </ConfigCommandProvider>,
  );
}

describe("config governance shell", () => {
  it("renders snapshot summary and history baseline", () => {
    renderShell();

    expect(screen.getByTestId("config-governance-shell")).toBeTruthy();
    expect(screen.getByTestId("config-workflow-guide").textContent).toMatch(/خريطة العمل/i);
    expect(screen.getByTestId("config-summary-grid").textContent).toMatch(/النسخة المنشورة/i);
    expect(screen.getByTestId("config-pricing-panel").textContent).toMatch(/الخطوة 1/i);
    expect(screen.getByTestId("config-change-panel").textContent).toMatch(/الخطوة 2/i);
    expect(screen.getByTestId("config-rollback-panel").textContent).toMatch(/الخطوة 3/i);
    expect(screen.getByTestId("config-history-table")).toBeTruthy();
    expect(screen.getByTestId("config-non-goals").textContent).toMatch(
      /الكتابة من المتصفح لا تكون مباشرة أبدًا/i,
    );
  });

  it("hides mutation controls for read-only affordances", () => {
    renderShell({
      role: "ops_viewer",
      affordances: READ_ONLY_AFFORDANCES,
    });

    expect(screen.queryByRole("button", { name: /حفظ المسودة/i })).toBeNull();
    expect(screen.queryByRole("button", { name: /اعتماد المراجعة/i })).toBeNull();
    expect(screen.queryByRole("button", { name: /^نشر$/i })).toBeNull();
    expect(screen.queryByRole("button", { name: /^استرجاع$/i })).toBeNull();
    expect(screen.getByTestId("config-read-only-note")).toBeTruthy();
  });

  it("shows governed action controls for finance admin", () => {
    renderShell({ role: "finance_admin" });

    expect(screen.getByRole("button", { name: /حفظ المسودة/i })).toBeTruthy();
    expect(screen.getByRole("button", { name: /اعتماد المراجعة/i })).toBeTruthy();
    expect(screen.getByRole("button", { name: /^نشر$/i })).toBeTruthy();
    expect(screen.getByRole("button", { name: /^استرجاع$/i })).toBeTruthy();
  });

  it("surfaces unavailable runtime when transport is unavailable", async () => {
    const transport: ConfigCommandTransport = {
      execute: async () => ({
        ok: false,
        error: {
          status: 503,
          message: "Config governance transport is unavailable.",
        },
      }),
    };

    renderShell({ role: "finance_admin", transport });

    fireEvent.click(screen.getByRole("button", { name: /^نشر$/i }));

    const actionRow = screen.getByTestId("config-command-publish_config");
    await waitFor(() => {
      expect(within(actionRow).getByTestId("config-command-unavailable-message")).toBeTruthy();
    });
  });

  it("shows pending then success for successful draft save", async () => {
    let release: (() => void) | undefined;
    const barrier = new Promise<void>((resolve) => {
      release = resolve;
    });

    const transport: ConfigCommandTransport = {
      execute: (async () => {
        await barrier;
        return {
          ok: true,
          correlationId: "config:config_upsert_draft:1",
          data: {
            status: "drafted",
            draftStatus: "drafted",
            draftVersion: 4,
            auditEventId: "config_draft_saved_1",
          },
        } as any;
      }) as ConfigCommandTransport["execute"],
    };

    renderShell({ role: "finance_admin", transport });

    fireEvent.click(screen.getByRole("button", { name: /حفظ المسودة/i }));

    const actionRow = screen.getByTestId("config-command-config_upsert_draft");
    await waitFor(() => {
      expect(within(actionRow).getByTestId("config-command-pending-message")).toBeTruthy();
    });

    release?.();

    await waitFor(() => {
      expect(within(actionRow).getByTestId("config-command-success-message").textContent).toMatch(
        /تم تنفيذ حفظ المسودة بنجاح/i,
      );
    });
  });

  it("shows conflict runtime state when publish reports expected-state drift", async () => {
    const transport: ConfigCommandTransport = {
      execute: async () => ({
        ok: false,
        error: {
          status: 409,
          message: "config_live_version_conflict",
        },
      }),
    };

    renderShell({ role: "finance_admin", transport });

    fireEvent.click(screen.getByRole("button", { name: /^نشر$/i }));

    const actionRow = screen.getByTestId("config-command-publish_config");
    await waitFor(() => {
      expect(within(actionRow).getByTestId("config-command-conflict-message").textContent).toMatch(
        /تعارض في الإصدار المباشر للإعدادات/i,
      );
    });
  });
});
