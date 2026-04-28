import { describe, expect, it, vi } from "vitest";

import type { MediaCommandRequestMap } from "./media-command-contracts";
import {
  MEDIA_COMMAND_CALLABLE_SURFACES,
  createMediaCommandAdaptersTransport,
} from "./media-command-adapters";
import {
  createTypeSafeMockInvoker,
  readCallableMockCall,
} from "../testing/type-safe-mock-invoker";

const TARGET: MediaCommandRequestMap["media_soft_delete"]["target"] = {
  targetType: "topup_proof",
  targetId: "media-proof-1",
  sourceCollection: "merchant_topup_requests",
  sourceDocumentId: "media-proof-1",
  mediaUrl: "venues/venue-a/wallet_topups/proof-1.jpg",
  referenceType: "topup_request",
  referenceId: "media-proof-1",
};

function makeSoftDeleteRequest(): MediaCommandRequestMap["media_soft_delete"] {
  return {
    action: "media_soft_delete",
    commandId: "media-soft-delete-cmd-1",
    correlationId: "media-soft-delete-corr-1",
    reason: "policy_violation",
    submittedAt: "2026-04-10T10:00:00.000Z",
    target: TARGET,
    expectedState: {
      media_state: "active",
    },
  };
}

function makeReferenceCheckRequest(): MediaCommandRequestMap["media_reference_check"] {
  return {
    action: "media_reference_check",
    commandId: "media-reference-check-cmd-1",
    correlationId: "media-reference-check-corr-1",
    reason: "pre_purge_validation",
    submittedAt: "2026-04-10T10:02:00.000Z",
    target: TARGET,
    expectedState: {
      reference_index_health: "healthy",
    },
  };
}

function makePurgeRequest(): MediaCommandRequestMap["media_purge"] {
  return {
    action: "media_purge",
    commandId: "media-purge-cmd-1",
    correlationId: "media-purge-corr-1",
    reason: "quarantine_elapsed",
    submittedAt: "2026-04-10T10:03:00.000Z",
    target: TARGET,
    expectedState: {
      media_state: "quarantined",
      reference_count: 0,
      reference_index_health: "healthy",
    },
  };
}

describe("media command adapters", () => {
  it("maps media_soft_delete to callable payload with idempotency + expected_state", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      status: "soft_deleted",
      targetType: "topup_proof",
      targetId: "media-proof-1",
      referenceCheck: {
        checkedAt: "2026-04-10T10:00:10.000Z",
        referenceCount: 1,
        indexStatus: "healthy",
        indexAsOf: "2026-04-10T09:59:50.000Z",
        indexDetail: "ok",
        purgeEligible: false,
        blockedReason: "references_present",
        matchedSourcePaths: ["merchant_topup_requests/media-proof-1"],
      },
      auditEventId: "media_soft_deleted_cmd_1",
    }));

    const transport = createMediaCommandAdaptersTransport({ invokeCallable });
    const request = makeSoftDeleteRequest();
    const result = await transport.execute("media_soft_delete", request);

    expect(invokeCallable).toHaveBeenCalledTimes(1);
    const [callableName, payload] = readCallableMockCall(invokeCallable);

    expect(callableName).toBe(MEDIA_COMMAND_CALLABLE_SURFACES.media_soft_delete);
    expect(payload.commandId).toBe(request.commandId);
    expect(payload.idempotencyKey).toBe(request.commandId);
    expect(payload.expectedState).toEqual(request.expectedState);
    expect(payload.targetType).toBe("topup_proof");
    expect(payload.targetId).toBe("media-proof-1");

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.status).toBe("soft_deleted");
      expect(result.data.referenceCheck.referenceCount).toBe(1);
      expect(result.data.referenceCheck.blockedReason).toBe("references_present");
      expect(result.data.auditEventId).toBe("media_soft_deleted_cmd_1");
    }
  });

  it("maps media_reference_check response into explicit reference-check summary", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      status: "checked",
      target_type: "topup_proof",
      target_id: "media-proof-1",
      reference_check: {
        checked_at: "2026-04-10T10:02:15.000Z",
        reference_count: 0,
        index_status: "healthy",
        index_as_of: "2026-04-10T10:02:10.000Z",
        index_detail: "ok",
        purge_eligible: true,
        blocked_reason: null,
        matched_source_paths: [],
      },
      audit_event_id: "media_reference_checked_cmd_1",
    }));

    const transport = createMediaCommandAdaptersTransport({ invokeCallable });
    const request = makeReferenceCheckRequest();
    const result = await transport.execute("media_reference_check", request);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.status).toBe("checked");
      expect(result.data.referenceCheck.indexStatus).toBe("healthy");
      expect(result.data.referenceCheck.referenceCount).toBe(0);
      expect(result.data.referenceCheck.purgeEligible).toBe(true);
      expect(result.data.auditEventId).toBe("media_reference_checked_cmd_1");
    }
  });

  it("maps media_purge payload and storage delete status", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      status: "purged",
      storageDeleteStatus: "not_found",
      referenceCheck: {
        checkedAt: "2026-04-10T10:03:20.000Z",
        referenceCount: 0,
        indexStatus: "healthy",
        indexAsOf: "2026-04-10T10:03:00.000Z",
        indexDetail: "ok",
        purgeEligible: true,
        blockedReason: null,
        matchedSourcePaths: [],
      },
      auditEventId: "media_purged_cmd_1",
    }));

    const transport = createMediaCommandAdaptersTransport({ invokeCallable });
    const request = makePurgeRequest();
    const result = await transport.execute("media_purge", request);

    const [, payload] = readCallableMockCall(invokeCallable);

    expect(payload.expectedState).toEqual(request.expectedState);
    expect(payload.commandId).toBe(request.commandId);
    expect(payload.reason).toBe(request.reason);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.status).toBe("purged");
      expect(result.data.storageDeleteStatus).toBe("not_found");
      expect(result.data.referenceCheck.purgeEligible).toBe(true);
      expect(result.data.auditEventId).toBe("media_purged_cmd_1");
    }
  });

  it("normalizes callable permission errors into transport failures", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => {
      throw {
        code: "permission-denied",
        message: "media_role_not_authorized",
      };
    });

    const transport = createMediaCommandAdaptersTransport({ invokeCallable });
    const request = makePurgeRequest();
    const result = await transport.execute("media_purge", request);

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error).toEqual(
        expect.objectContaining({
          status: 403,
          message: "media_role_not_authorized",
        }),
      );
    }
  });
});
