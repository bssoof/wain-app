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
    fireEvent.click(screen.getByRole("button", { name: /تأكيد النشر/i }));

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
      expect(within(actionRow).getByRole("status", { name: "جاري التحميل" })).toBeTruthy();
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
    fireEvent.click(screen.getByRole("button", { name: /تأكيد النشر/i }));

    const actionRow = screen.getByTestId("config-command-publish_config");
    await waitFor(() => {
      expect(within(actionRow).getByTestId("config-command-conflict-message").textContent).toMatch(
        /تعارض في الإصدار المباشر للإعدادات/i,
      );
    });
  });

  it("opens publish confirmation without executing transport immediately", () => {
    const execute = vi.fn(async () => {
      throw new Error("Publish should wait for confirmation.");
    });
    const transport: ConfigCommandTransport = {
      execute: execute as ConfigCommandTransport["execute"],
    };

    renderShell({ role: "finance_admin", transport });

    fireEvent.click(screen.getByRole("button", { name: /^نشر$/i }));

    const dialog = screen.getByRole("dialog", { name: /نشر التغييرات/i });
    const confirmButton = screen.getByRole("button", { name: /تأكيد النشر/i });

    expect(dialog.getAttribute("aria-modal")).toBe("true");
    expect(confirmButton.className).not.toContain("confirm-dialog__btn--danger");
    expect(execute).not.toHaveBeenCalled();
  });

  it("opens rollback confirmation with danger variant and version preview", () => {
    renderShell({ role: "finance_admin" });

    fireEvent.change(screen.getByTestId("config-rollback-version-input"), {
      target: { value: "1" },
    });
    fireEvent.click(screen.getByRole("button", { name: /^استرجاع$/i }));

    const dialog = screen.getByRole("dialog", { name: /استرجاع آخر نسخة/i });
    const confirmButton = screen.getByRole("button", { name: /تأكيد الاسترجاع/i });
    const versionRow = screen.getByTestId("config-diff-row-rollback-version");

    expect(dialog.getAttribute("aria-modal")).toBe("true");
    expect(confirmButton.className).toContain("confirm-dialog__btn--danger");
    expect(versionRow.textContent).toContain("2");
    expect(versionRow.textContent).toContain("1");
  });

  it("cancel closes confirmation without calling backend", async () => {
    const execute = vi.fn(async () => {
      throw new Error("Publish should not run after cancel.");
    });
    const transport: ConfigCommandTransport = {
      execute: execute as ConfigCommandTransport["execute"],
    };

    renderShell({ role: "finance_admin", transport });

    fireEvent.click(screen.getByRole("button", { name: /^نشر$/i }));
    fireEvent.click(screen.getByRole("button", { name: /^إلغاء$/i }));

    await waitFor(() => {
      expect(screen.queryByRole("dialog", { name: /نشر التغييرات/i })).toBeNull();
    });
    expect(execute).not.toHaveBeenCalled();
  });

  it("confirming publish calls the existing publish command handler", async () => {
    const execute = vi.fn(async () => ({
      ok: true,
      correlationId: "config:publish_config:1",
      data: {
        status: "published",
        liveVersion: 3,
        draftVersion: 4,
        auditEventId: "config_published_2",
      },
    }));
    const transport: ConfigCommandTransport = {
      execute: execute as ConfigCommandTransport["execute"],
    };

    renderShell({ role: "finance_admin", transport });

    fireEvent.click(screen.getByRole("button", { name: /^نشر$/i }));
    fireEvent.click(screen.getByRole("button", { name: /تأكيد النشر/i }));

    await waitFor(() => {
      expect(execute).toHaveBeenCalledTimes(1);
      expect(execute).toHaveBeenCalledWith("publish_config", expect.anything());
    });
  });

  it("loading state prevents duplicate publish confirmation clicks", async () => {
    let release: (() => void) | undefined;
    const barrier = new Promise<void>((resolve) => {
      release = resolve;
    });
    const execute = vi.fn(async () => {
      await barrier;
      return {
        ok: true,
        correlationId: "config:publish_config:1",
        data: {
          status: "published",
          liveVersion: 3,
          draftVersion: 4,
          auditEventId: "config_published_2",
        },
      };
    });
    const transport: ConfigCommandTransport = {
      execute: execute as ConfigCommandTransport["execute"],
    };

    renderShell({ role: "finance_admin", transport });

    fireEvent.click(screen.getByRole("button", { name: /^نشر$/i }));
    fireEvent.click(screen.getByRole("button", { name: /تأكيد النشر/i }));

    await waitFor(() => {
      const pendingButton = screen.getByRole("button", { name: /جارٍ التنفيذ/i }) as HTMLButtonElement;
      expect(pendingButton.disabled).toBe(true);
    });

    fireEvent.click(screen.getByRole("button", { name: /جارٍ التنفيذ/i }));
    expect(execute).toHaveBeenCalledTimes(1);

    release?.();

    await waitFor(() => {
      expect(screen.queryByRole("dialog", { name: /نشر التغييرات/i })).toBeNull();
    });
  });

  it("renders changed pricing keys in the publish diff preview", () => {
    renderShell({ role: "finance_admin" });

    fireEvent.click(screen.getByRole("button", { name: /^نشر$/i }));

    const preview = screen.getByTestId("config-confirm-diff-preview");
    const storyRow = screen.getByTestId("config-diff-row-story_promote_1d");
    const offerRow = screen.getByTestId("config-diff-row-offer_pin_7d");

    expect(within(preview).getByText("معاينة الفروقات")).toBeTruthy();
    expect(storyRow.textContent).toContain("ترويج القصة ليوم واحد");
    expect(storyRow.textContent).toContain("4");
    expect(storyRow.textContent).toContain("5");
    expect(offerRow.textContent).toContain("تثبيت العرض لسبعة أيام");
    expect(offerRow.textContent).toContain("18");
    expect(offerRow.textContent).toContain("20");
  });

  it("renders an empty state when publish history has no rows", () => {
    renderShell({
      snapshot: {
        ...createSnapshot(),
        history: [],
      },
    });

    expect(screen.getByText("لا يوجد سجل نشر بعد")).toBeTruthy();
    expect(screen.getByText(/سيظهر سجل النشر والاسترجاع هنا/i)).toBeTruthy();
  });
});
