import { Timestamp } from "firebase-admin/firestore";

import {
  financeTimestampToMillis,
  workspaceString,
} from "./finance-media-normalizers";
import { db } from "./firestore-db";

export function clampFinanceReadLimit(
  value: unknown,
  fallback: number,
  min: number,
  max: number,
): number {
  const n =
    typeof value === "number" && Number.isFinite(value)
      ? Math.floor(value)
      : fallback;
  return Math.min(max, Math.max(min, n));
}

export function normalizeNumber(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

export function roundMoney(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

export function resolveWalletLedgerUiType(
  data: FirebaseFirestore.DocumentData,
): "credit" | "debit" | "reversal" {
  const idem =
    typeof data.idempotency_key === "string" ? data.idempotency_key : "";
  const meta =
    data.metadata && typeof data.metadata === "object"
      ? (data.metadata as Record<string, unknown>)
      : {};
  if (
    data.type === "credit" &&
    (idem.startsWith("reversal_") ||
      typeof meta.reversal_of_entry_id === "string")
  ) {
    return "reversal";
  }
  if (data.type === "debit") {
    return "debit";
  }
  return "credit";
}

export function workspaceStoryStatus(
  data: FirebaseFirestore.DocumentData,
  now: Timestamp,
): "published" | "expired" | "draft" {
  const explicit = workspaceString(data.status).toLowerCase();
  if (explicit === "published" || explicit === "expired" || explicit === "draft") {
    return explicit;
  }

  const expiresAt = financeTimestampToMillis(data.expires_at ?? data.expiresAt);
  if (expiresAt > 0 && expiresAt <= now.toMillis()) {
    return "expired";
  }

  if (data.is_active === false || data.is_published === false) {
    return "draft";
  }

  return "published";
}

export function workspaceOfferStatus(
  data: FirebaseFirestore.DocumentData,
  now: Timestamp,
): "active" | "paused" | "expired" {
  const explicit = workspaceString(data.status).toLowerCase();
  if (explicit === "active" || explicit === "paused" || explicit === "expired") {
    return explicit;
  }

  const endAt = financeTimestampToMillis(data.end_at ?? data.ends_at ?? data.endAt);
  if (endAt > 0 && endAt <= now.toMillis()) {
    return "expired";
  }

  if (data.is_active === false || data.is_featured === false) {
    return "paused";
  }

  return "active";
}

export function workspaceReviewStatus(
  data: FirebaseFirestore.DocumentData,
): "published" | "flagged" | "hidden" {
  const explicit = workspaceString(data.status).toLowerCase();
  if (explicit === "published" || explicit === "flagged" || explicit === "hidden") {
    return explicit;
  }

  if (data.hidden === true || data.is_hidden === true) {
    return "hidden";
  }

  if (data.flagged === true || data.is_flagged === true) {
    return "flagged";
  }

  return "published";
}

export function workspaceStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => workspaceString(entry))
    .filter((entry) => entry.length > 0);
}

export function workspaceMediaUrl(
  data: FirebaseFirestore.DocumentData,
  candidates: string[],
): string {
  for (const candidate of candidates) {
    const value = workspaceString(data[candidate]);
    if (value.length > 0) {
      return value;
    }
  }
  return "";
}

export async function loadVenueDisplayLabels(
  venueIds: string[],
): Promise<Map<string, string>> {
  const unique = [...new Set(venueIds.filter((id) => id.trim().length > 0))].slice(
    0,
    200,
  );
  const map = new Map<string, string>();

  await Promise.all(
    unique.map(async (id) => {
      const snap = await db.collection("venues").doc(id).get();
      if (!snap.exists) {
        map.set(id, id);
        return;
      }

      const d = snap.data() ?? {};
      const ar = typeof d.name_ar === "string" ? d.name_ar.trim() : "";
      const en = typeof d.name === "string" ? d.name.trim() : "";
      map.set(id, ar || en || id);
    }),
  );

  return map;
}
