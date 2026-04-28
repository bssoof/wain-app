import {
  fireEvent,
  render,
  screen,
  waitFor,
  within,
} from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { AdminRole } from "@/lib/navigation/admin-contract";
import type {
  MediaCenterBaseline,
  MediaCommandTransport,
} from "@/lib/media";

import { MediaCommandProvider } from "./media-command-provider";
import { MediaCenterShell } from "./media-center-shell";

function createBaseline(): MediaCenterBaseline {
  return {
    generatedAt: "2026-04-10T12:00:00.000Z",
    sections: [
      {
        key: "proofs",
        title: "صور الإثبات",
        scopeNote: "صور إثبات الشحن المعروضة للمراجعة.",
        state: "stale",
        source: "callable:getAdminMediaInventoryReadBundle",
        freshnessNote: "ارتباط بعض الملفات يحتاج مراجعة؛ لذلك يبقى الحذف النهائي ممنوعًا.",
        referenceSafetyNote: "ارتباط الملفات قديم. الحذف النهائي محظور إلى أن يتم التحديث.",
        referenceIndexHealth: "stale",
        purgeBlocked: true,
        items: [
          {
            id: "proof_1",
            title: "Proof alpha",
            venueName: "Alpha Cafe",
            uploadedAt: "2026-04-09T10:00:00.000Z",
            sourceDocument: "merchant_topup_requests/proof_1",
            referenceType: "topup_request",
            referenceId: "topup_1",
            sourceLabel: "merchant_topup_requests",
            referenceSafety: "unknown",
            referenceIndexHealth: "stale",
            purgeBlocked: true,
            mediaUrl: "https://cdn.wain.test/media/proof_1.jpg",
            previewNote: "Alpha proof preview",
          },
          {
            id: "proof_2",
            title: "Proof beta",
            venueName: "Beta Grill",
            uploadedAt: "2026-04-09T11:00:00.000Z",
            sourceDocument: "merchant_topup_requests/proof_2",
            referenceType: "topup_request",
            referenceId: "topup_2",
            sourceLabel: "merchant_topup_requests",
            referenceSafety: "safe",
            referenceIndexHealth: "healthy",
            purgeBlocked: false,
            mediaUrl: "venues/venue_beta/wallet_topups/proof_2.jpg",
            previewNote: "Beta proof preview",
          },
        ],
      },
      {
        key: "venue_photos",
        title: "صور الجهات",
        scopeNote: "صور الجهات المعروضة داخل التطبيق.",
        state: "success",
        source: "callable:getAdminMediaInventoryReadBundle",
        freshnessNote: "حداثة اللقطة ضمن الحد المقبول شبه الآني.",
        referenceSafetyNote: "ارتباط الملفات سليم اعتبارًا من 2026-04-10T12:00:00.000Z.",
        referenceIndexHealth: "healthy",
        purgeBlocked: false,
        items: [
          {
            id: "venue_1",
            title: "Storefront",
            venueName: "Alpha Cafe",
            uploadedAt: "2026-04-09T12:00:00.000Z",
            sourceDocument: "venues/venue_alpha",
            referenceType: "venue",
            referenceId: "venue_alpha",
            sourceLabel: "venues",
            referenceSafety: "safe",
            referenceIndexHealth: "healthy",
            purgeBlocked: false,
            mediaUrl: "https://cdn.wain.test/media/venue_alpha.jpg",
            previewNote: "Alpha storefront image",
          },
        ],
      },
      {
        key: "offer_images",
        title: "صور العروض",
        scopeNote: "صور العروض المعروضة للمستخدمين.",
        state: "empty",
        source: "callable:getAdminMediaInventoryReadBundle",
        freshnessNote: "لم تُرجع اللقطة الحالية أي صفوف لهذا القسم.",
        referenceSafetyNote: "لا توجد عناصر يمكن التحقق منها.",
        referenceIndexHealth: "healthy",
        purgeBlocked: false,
        items: [],
        message: "قسم صور العروض فارغ.",
      },
      {
        key: "story_images",
        title: "صور القصص",
        scopeNote: "صور القصص المعروضة للمستخدمين.",
        state: "unavailable",
        source: "unavailable",
        freshnessNote: "حداثة البيانات غير معروفة.",
        referenceSafetyNote: "حالة الارتباط غير متاحة.",
        referenceIndexHealth: "unavailable",
        purgeBlocked: true,
        items: [],
        message: "قسم صور القصص غير متاح.",
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

function renderShell(options?: {
  role?: AdminRole;
  transport?: MediaCommandTransport;
  baseline?: MediaCenterBaseline;
}) {
  const baseline = options?.baseline ?? createBaseline();
  const ui = <MediaCenterShell baseline={baseline} />;

  if (!options?.role) {
    return render(ui);
  }

  return render(
    <MediaCommandProvider
      session={createSession(options.role)}
      transport={options.transport}
    >
      {ui}
    </MediaCommandProvider>,
  );
}

function createSuccessfulTransport(
  handler?: MediaCommandTransport["execute"],
): MediaCommandTransport {
  return {
    execute:
      handler ??
      (async (command, request) => ({
        ok: true,
        correlationId: request.correlationId,
        data: {
          action: command,
          status:
            command === "media_reference_check"
              ? "checked"
              : command === "media_purge"
                ? "purged"
                : command === "media_quarantine"
                  ? "quarantined"
                  : "soft_deleted",
          targetType: request.target.targetType,
          targetId: request.target.targetId,
          ...(command === "media_reference_check"
            ? {
                referenceCheck: {
                  checkedAt: request.submittedAt,
                  referenceCount: 0,
                  indexStatus: "healthy",
                  indexAsOf: request.submittedAt,
                  indexDetail: "healthy",
                  purgeEligible: true,
                  blockedReason: null,
                  matchedSourcePaths: [],
                },
                auditEventId: `${request.commandId}:checked`,
              }
            : {
                assetState:
                  command === "media_quarantine"
                    ? "quarantined"
                    : command === "media_purge"
                      ? "purged"
                      : "soft_deleted",
                referenceCheck: {
                  checkedAt: request.submittedAt,
                  referenceCount: 0,
                  indexStatus: "healthy",
                  indexAsOf: request.submittedAt,
                  indexDetail: "healthy",
                  purgeEligible: true,
                  blockedReason: null,
                  matchedSourcePaths: [],
                },
                auditEventId: `${request.commandId}:done`,
                ...(command === "media_quarantine"
                  ? { quarantineUntil: request.submittedAt }
                  : {}),
                ...(command === "media_purge"
                  ? { storageDeleteStatus: "deleted" }
                  : {}),
              }),
        },
      })) as MediaCommandTransport["execute"],
  };
}

describe("media center shell", () => {
  it("renders section tabs and governed action note", () => {
    renderShell();

    expect(screen.getByTestId("media-center-shell")).toBeTruthy();
    expect(screen.getByTestId("media-center-read-only-note").textContent).toMatch(
      /كل تعديل يمر عبر الخادم/i,
    );
    expect(screen.getByTestId("media-center-non-goals").textContent).toMatch(
      /حالة واضحة/i,
    );
  });

  it("filters the active section by search, venue, and safety", () => {
    renderShell();

    expect(screen.getByTestId("media-center-row-proof_1")).toBeTruthy();
    expect(screen.getByTestId("media-center-row-proof_2")).toBeTruthy();

    fireEvent.change(screen.getByTestId("media-center-search-input"), {
      target: { value: "alpha" },
    });

    expect(screen.getByTestId("media-center-row-proof_1")).toBeTruthy();
    expect(screen.queryByTestId("media-center-row-proof_2")).toBeNull();

    fireEvent.change(screen.getByTestId("media-center-search-input"), {
      target: { value: "" },
    });
    fireEvent.change(screen.getByTestId("media-center-venue-filter"), {
      target: { value: "Beta Grill" },
    });

    expect(screen.queryByTestId("media-center-row-proof_1")).toBeNull();
    expect(screen.getByTestId("media-center-row-proof_2")).toBeTruthy();

    fireEvent.change(screen.getByTestId("media-center-venue-filter"), {
      target: { value: "" },
    });
    fireEvent.change(screen.getByTestId("media-center-safety-filter"), {
      target: { value: "safe" },
    });

    expect(screen.queryByTestId("media-center-row-proof_1")).toBeNull();
    expect(screen.getByTestId("media-center-row-proof_2")).toBeTruthy();
  });

  it("renders explicit empty and unavailable section states", () => {
    renderShell();

    fireEvent.click(screen.getByTestId("media-center-tab-offer_images"));
    expect(screen.getByTestId("media-center-empty").textContent).toMatch(
      /قسم صور العروض فارغ|لا توجد/i,
    );

    fireEvent.click(screen.getByTestId("media-center-tab-story_images"));
    expect(screen.getByTestId("media-center-unavailable").textContent).toMatch(
      /قسم صور القصص غير متاح|غير متاح/i,
    );
  });

  it("renders stale state and source honesty for proof inventory", () => {
    renderShell();

    expect(screen.getByTestId("media-center-state-badge").textContent).toMatch(/بيانات قديمة/i);
    expect(screen.getByTestId("media-center-source-note").textContent).toMatch(
      /الخدمة المتصلة/i,
    );
    expect(screen.getByTestId("media-center-source-note").textContent).toMatch(
      /محظور/i,
    );
  });

  it("shows filter-empty state when active section items do not match", () => {
    renderShell();

    fireEvent.change(screen.getByTestId("media-center-search-input"), {
      target: { value: "does-not-exist" },
    });

    expect(screen.getByTestId("media-center-filter-empty").textContent).toMatch(
      /لا توجد صور أو ملفات تطابق/i,
    );
  });

  it("opens and closes read-only media preview viewer", async () => {
    renderShell();

    fireEvent.click(screen.getByTestId("media-preview-open-proof_1"));

    const dialog = screen.getByTestId("media-preview-dialog");
    expect(dialog).toBeTruthy();
    expect(screen.getByTestId("media-preview-image").getAttribute("src")).toBe(
      "https://cdn.wain.test/media/proof_1.jpg",
    );

    fireEvent.click(screen.getByTestId("media-preview-close"));

    await waitFor(() => {
      expect(screen.queryByTestId("media-preview-dialog")).toBeNull();
    });
  });

  it("shows explicit unavailable preview notice when direct media URL is absent", () => {
    renderShell();

    fireEvent.click(screen.getByTestId("media-preview-open-proof_2"));

    expect(screen.getByTestId("media-preview-unavailable").textContent).toMatch(
      /لا توجد معاينة مباشرة/i,
    );
  });

  it("opens replace draft dialog and validates required fields", () => {
    renderShell({ role: "content_admin" });

    fireEvent.click(screen.getByTestId("media-replace-open-proof_1"));

    expect(screen.getByTestId("media-replace-dialog")).toBeTruthy();

    fireEvent.change(screen.getByTestId("media-replace-url-input-proof_1"), {
      target: { value: "ftp://invalid.example/media.jpg" },
    });
    fireEvent.change(screen.getByTestId("media-replace-reason-input-proof_1"), {
      target: { value: "قصير" },
    });

    fireEvent.click(screen.getByTestId("media-replace-submit"));

    expect(screen.getByTestId("media-replace-url-error").textContent).toMatch(
      /رابطًا مباشرًا صالحًا/i,
    );
    expect(screen.getByTestId("media-replace-reason-error").textContent).toMatch(
      /8 أحرف/i,
    );
  });

  it("builds replace draft payload when valid input is provided", async () => {
    renderShell({ role: "content_admin" });

    fireEvent.click(screen.getByTestId("media-replace-open-proof_1"));

    fireEvent.change(screen.getByTestId("media-replace-url-input-proof_1"), {
      target: { value: "https://cdn.wain.test/media/proof_1_replacement.jpg" },
    });
    fireEvent.change(screen.getByTestId("media-replace-reason-input-proof_1"), {
      target: { value: "تحديث نسخة أوضح بعد مراجعة الجودة." },
    });

    fireEvent.click(screen.getByTestId("media-replace-submit"));

    await waitFor(() => {
      expect(screen.getByTestId("media-replace-draft-payload")).toBeTruthy();
    });

    const payloadText =
      screen.getByTestId("media-replace-draft-payload").textContent ?? "";
    const payload = JSON.parse(payloadText) as {
      action: string;
      target: { assetId: string; referenceId: string };
      replacement: { mediaUrl: string; reason: string };
    };

    expect(payload.action).toBe("media_replace_draft");
    expect(payload.target.assetId).toBe("proof_1");
    expect(payload.target.referenceId).toBe("topup_1");
    expect(payload.replacement.mediaUrl).toBe(
      "https://cdn.wain.test/media/proof_1_replacement.jpg",
    );
    expect(payload.replacement.reason).toMatch(/مراجعة الجودة/i);
  });

  it("keeps mutation controls absent for read-only roles", () => {
    renderShell({ role: "ops_viewer" });

    expect(screen.getByTestId("media-center-read-only-proof_1").textContent).toMatch(
      /صلاحية القراءة فقط/i,
    );
    expect(screen.queryByTestId("media-action-select-proof_1")).toBeNull();
  });

  it("shows governed action controls for content_admin", () => {
    renderShell({ role: "content_admin" });

    const actionSelect = screen.getByTestId("media-action-select-proof_1");
    expect(within(actionSelect).getByRole("option", { name: /إخفاء من القائمة/i })).toBeTruthy();
    expect(within(actionSelect).getByRole("option", { name: /عزل الملف/i })).toBeTruthy();
    expect(within(actionSelect).getByRole("option", { name: /فحص الارتباط/i })).toBeTruthy();
    expect(within(actionSelect).getByRole("option", { name: /حذف نهائي/i })).toBeTruthy();
    expect(screen.getByTestId("media-action-run-proof_1")).toBeTruthy();
  });

  it("shows blocked purge messaging when reference safety is degraded", () => {
    renderShell({ role: "content_admin" });

    fireEvent.change(screen.getByTestId("media-action-select-proof_1"), {
      target: { value: "media_purge" },
    });

    const purgeAction = screen.getByTestId("media-command-media_purge-proof_1");
    const purgeButton = screen.getByTestId("media-action-run-proof_1");

    expect(purgeButton).toHaveProperty("disabled", true);
    expect(within(purgeAction).getByTestId("media-command-blocked-message").textContent).toMatch(
      /ارتباط الملفات|ارتباط الملف/i,
    );
  });

  it("surfaces unavailable runtime when transport is not connected", async () => {
    renderShell({ role: "content_admin" });

    fireEvent.change(screen.getByTestId("media-action-select-proof_1"), {
      target: { value: "media_reference_check" },
    });
    fireEvent.click(screen.getByTestId("media-action-run-proof_1"));

    const actionRow = screen.getByTestId("media-command-media_reference_check-proof_1");
    await waitFor(() => {
      expect(within(actionRow).getByTestId("media-command-unavailable-message")).toBeTruthy();
    });
  });

  it("shows pending then success for a successful media command", async () => {
    let release: (() => void) | undefined;
    const barrier = new Promise<void>((resolve) => {
      release = resolve;
    });

    const transport: MediaCommandTransport = {
      execute: (async () => {
        await barrier;
        return {
          ok: true,
          correlationId: "media-center:proofs:proof_1",
          data: {
            action: "media_reference_check",
            status: "checked",
            targetType: "topup_proof",
            targetId: "proof_1",
            referenceCheck: {
              checkedAt: "2026-04-10T12:00:00.000Z",
              referenceCount: 0,
              indexStatus: "healthy",
              indexAsOf: "2026-04-10T12:00:00.000Z",
              indexDetail: "healthy",
              purgeEligible: true,
              blockedReason: null,
              matchedSourcePaths: [],
            },
            auditEventId: "media-check-proof-1",
          },
        } as any;
      }) as MediaCommandTransport["execute"],
    };

    renderShell({ role: "content_admin", transport });

    fireEvent.change(screen.getByTestId("media-action-select-proof_1"), {
      target: { value: "media_reference_check" },
    });
    fireEvent.click(screen.getByTestId("media-action-run-proof_1"));

    const sidebar = screen.getByTestId("media-center-actions-proof_1");
    const actionRow = screen.getByTestId("media-command-media_reference_check-proof_1");
    await waitFor(() => {
      expect(within(sidebar).getByText(/قيد التنفيذ/i)).toBeTruthy();
    });

    release?.();

    await waitFor(() => {
      expect(within(actionRow).getByTestId("media-command-success-message").textContent).toMatch(
        /فحص الارتباط تم بنجاح/i,
      );
    });
  });

  it("shows conflict messaging when the transport reports expected-state drift", async () => {
    const transport = createSuccessfulTransport(async () => ({
      ok: false,
      error: {
        status: 409,
        message: "Conflict with latest reference state.",
      },
    }));

    renderShell({ role: "content_admin", transport });

    fireEvent.change(screen.getByTestId("media-action-select-proof_1"), {
      target: { value: "media_soft_delete" },
    });
    fireEvent.click(screen.getByTestId("media-action-run-proof_1"));

    const actionRow = screen.getByTestId("media-command-media_soft_delete-proof_1");
    await waitFor(() => {
      expect(within(actionRow).getByTestId("media-command-conflict-message").textContent).toMatch(
        /تعذر إكمال الطلب حاليًا|تعارض/i,
      );
    });
  });
});
