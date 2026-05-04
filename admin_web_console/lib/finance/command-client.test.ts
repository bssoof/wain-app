import { describe, expect, it } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type { AdminRole } from "@/lib/navigation/admin-contract";

import {
  createFinanceCommandClient,
  normalizeFinanceCommandError,
} from "./command-client";
import type { ApproveTopUpCommandRequest } from "./command-contracts";
import type { FinanceCommandTransport } from "./finance-command-transport";

function createSession(primaryRole: AdminRole, roles: AdminRole[] = [primaryRole]): AdminSession {
  return {
    uid: "admin-uid",
    primaryRole,
    roles,
    roleSource: "claims",
  };
}

function makeApproveTopUpRequest(): ApproveTopUpCommandRequest {
  return {
    action: "approve_topup",
    commandId: "cmd-approve-topup-001",
    correlationId: "corr-approve-topup-001",
    reason: "manual review approved",
    submittedAt: "2026-04-09T22:10:00.000Z",
    requestId: "topup-request-001",
    venueId: "venue-001",
    expectedState: {
      status: "pending",
      decision_state: "unreviewed",
    },
  };
}

describe("finance command client", () => {
  it("refuses execution locally when capability is missing", async () => {
    let transportCallCount = 0;

    const transport: FinanceCommandTransport = {
      execute: (async () => {
        transportCallCount += 1;
        return {
          ok: true,
          data: {
            action: "approve_topup",
            requestId: "topup-request-001",
            venueId: "venue-001",
            status: "credited",
            linkedEntryId: "entry-001",
            reviewedAt: "2026-04-09T22:10:30.000Z",
          },
        } as any;
      }) as FinanceCommandTransport["execute"],
    };

    const client = createFinanceCommandClient(transport);
    const result = await client.execute({
      session: createSession("ops_viewer"),
      command: "approve_topup",
      request: makeApproveTopUpRequest(),
    });

    expect(result.ok).toBe(false);
    expect(transportCallCount).toBe(0);

    if (!result.ok) {
      expect(result.error.code).toBe("forbidden");
      expect(result.error.status).toBe(403);
    }
  });

  it("normalizes conflict errors from transport status", async () => {
    const transport: FinanceCommandTransport = {
      async execute() {
        return {
          ok: false,
          error: {
            status: 409,
            message: "expected_state conflict",
            details: { field: "expectedState" },
          },
        };
      },
    };

    const client = createFinanceCommandClient(transport);
    const result = await client.execute({
      session: createSession("finance_admin"),
      command: "approve_topup",
      request: makeApproveTopUpRequest(),
    });

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error.code).toBe("conflict");
      expect(result.error.status).toBe(409);
      expect(result.error.retryable).toBe(true);
    }
  });

  it("normalizes explicit validation errors", () => {
    const normalized = normalizeFinanceCommandError({
      code: "validation_error",
      message: "reason is required",
      details: { field: "reason" },
    });

    expect(normalized.code).toBe("validation_error");
    expect(normalized.status).toBe(422);
    expect(normalized.retryable).toBe(false);
    expect(normalized.message).toBe("reason is required");
  });

  it("preserves explicit step-up required errors from a 403 proxy response", () => {
    const normalized = normalizeFinanceCommandError({
      status: 403,
      code: "step_up_required",
      message: "STEP_UP_REQUIRED",
      details: { scope: "finance", command: "approve_topup" },
    });

    expect(normalized.code).toBe("step_up_required");
    expect(normalized.status).toBe(403);
    expect(normalized.retryable).toBe(false);
    expect(normalized.message).toBe("STEP_UP_REQUIRED");
  });

  it("maps unknown runtime failures to unavailable", async () => {
    const transport: FinanceCommandTransport = {
      async execute() {
        throw new Error("network unavailable");
      },
    };

    const client = createFinanceCommandClient(transport);
    const result = await client.execute({
      session: createSession("finance_admin"),
      command: "approve_topup",
      request: makeApproveTopUpRequest(),
    });

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error.code).toBe("unavailable");
      expect(result.error.status).toBe(503);
    }
  });
});
