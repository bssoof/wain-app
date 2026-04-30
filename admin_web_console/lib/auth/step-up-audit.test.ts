import { describe, expect, it, vi } from "vitest";

vi.mock("server-only", () => ({}));

import {
  emitStepUpAuditEvent,
  resolveStepUpKeyVersionLabels,
} from "./step-up-audit";

describe("step-up audit emitter", () => {
  it("emits a structured console and Firestore audit record", async () => {
    const add = vi.fn().mockResolvedValue({ id: "audit-1" });
    const logger = vi.fn();

    const record = await emitStepUpAuditEvent(
      {
        eventType: "step_up_verified",
        userId: "admin-1",
        sessionRole: "finance_admin",
        command: "approve_topup",
        correlationId: "corr-1",
        scope: "finance",
        enforcementMode: "enabled",
        tokenJti: "jti-1",
        tokenIssuedAt: "2026-04-30T10:00:00.000Z",
        tokenAge_ms: 61_234.9,
        expiresAt: "2026-04-30T10:15:00.000Z",
      },
      {
        db: {
          collection: vi.fn(() => ({ add })),
        },
        now: () => new Date("2026-04-30T10:01:01.000Z"),
        logger,
      },
    );

    expect(record).toMatchObject({
      timestamp: "2026-04-30T10:01:01.000Z",
      source: "step-up-auth",
      event: "step_up_verified",
      eventType: "step_up_verified",
      userId: "admin-1",
      command: "approve_topup",
      scope: "finance",
      tokenAge_ms: 61234,
    });
    expect(add).toHaveBeenCalledWith(record);
    expect(String(logger.mock.calls[0]?.[0] ?? "")).toContain(
      '"eventType":"step_up_verified"',
    );
  });

  it("does not throw when the Firestore write fails", async () => {
    const errorLogger = vi.fn();

    await expect(
      emitStepUpAuditEvent(
        {
          eventType: "step_up_rejected",
          userId: "admin-1",
          command: "approve_topup",
          scope: "finance",
          reason: "missing_token",
          enforcementMode: "enabled",
        },
        {
          db: {
            collection: vi.fn(() => ({
              add: vi.fn().mockRejectedValue(new Error("firestore unavailable")),
            })),
          },
          logger: vi.fn(),
          errorLogger,
        },
      ),
    ).resolves.toMatchObject({
      eventType: "step_up_rejected",
      reason: "missing_token",
    });
    expect(errorLogger).toHaveBeenCalled();
  });

  it("omits empty optional fields and does not accept password-like fields", async () => {
    const record = await emitStepUpAuditEvent(
      {
        eventType: "step_up_required",
        userId: "admin-1",
        command: "approve_topup",
        reason: "",
        scope: "finance",
      },
      {
        logger: vi.fn(),
        writeToFirestore: false,
      },
    );

    expect(record).not.toHaveProperty("reason");
    expect(JSON.stringify(record)).not.toContain("password");
  });

  it("extracts key version labels from Secret Manager resources", () => {
    expect(
      resolveStepUpKeyVersionLabels({
        WAIN_ADMIN_STEP_UP_SIGNING_KEY_SECRET_VERSION:
          "projects/wain-d2e28/secrets/current/versions/3",
        WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_VERSION:
          "projects/wain-d2e28/secrets/previous/versions/2",
      }),
    ).toEqual({
      currentKeyVersion: "3",
      previousKeyVersion: "2",
    });
  });
});
