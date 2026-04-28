import * as crypto from "crypto";

export type ContentCommandEnvelopeShape = {
  action: string;
  commandId: string;
  idempotencyKey: string;
  reason: string;
  note: string | null;
  expectedState: Record<string, unknown> | null;
};

function sortObjectForContentHash(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map((entry) => sortObjectForContentHash(entry));
  }

  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    const sorted: Record<string, unknown> = {};
    for (const key of Object.keys(record).sort()) {
      sorted[key] = sortObjectForContentHash(record[key]);
    }
    return sorted;
  }

  return value;
}

export function hashContentModerationPayload(payload: Record<string, unknown>): string {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify(sortObjectForContentHash(payload)))
    .digest("hex");
}

export function contentModerationCommandDocId(
  targetType: "offer" | "story",
  targetId: string,
  commandId: string,
): string {
  return crypto
    .createHash("sha1")
    .update(`${targetType}|${targetId}|${commandId}`)
    .digest("hex");
}

export function buildContentModerationPayloadShape(
  targetType: "offer" | "story",
  targetId: string,
  venueId: string,
  envelope: ContentCommandEnvelopeShape,
): Record<string, unknown> {
  return {
    action: envelope.action,
    commandId: envelope.commandId,
    idempotencyKey: envelope.idempotencyKey,
    reason: envelope.reason,
    note: envelope.note,
    expectedState: envelope.expectedState,
    target: {
      targetType,
      targetId,
      venueId,
    },
  };
}
