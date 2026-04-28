import { Timestamp } from "firebase-admin/firestore";

export function workspaceString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

export function financeTimestampToMillis(value: unknown): number {
  if (value instanceof Timestamp) {
    return value.toMillis();
  }
  if (value && typeof value === "object") {
    const maybe = value as { _seconds?: unknown; _nanoseconds?: unknown };
    if (
      typeof maybe._seconds === "number" &&
      Number.isFinite(maybe._seconds)
    ) {
      const nanos =
        typeof maybe._nanoseconds === "number" &&
        Number.isFinite(maybe._nanoseconds)
          ? maybe._nanoseconds
          : 0;
      return Math.round(maybe._seconds * 1000 + nanos / 1e6);
    }

    const maybeToDate = value as { toDate?: () => Date };
    if (typeof maybeToDate.toDate === "function") {
      const date = maybeToDate.toDate();
      return date.getTime();
    }
  }

  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return value;
  }

  if (typeof value === "string") {
    const parsed = Date.parse(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }
  return 0;
}

export function financeTimestampToIso(value: unknown): string {
  const ms = financeTimestampToMillis(value);
  return new Date(ms).toISOString();
}

export function financeTimestampToIsoWithFallback(
  value: unknown,
  fallback: Timestamp,
): string {
  const ms = financeTimestampToMillis(value);
  return ms > 0 ? new Date(ms).toISOString() : fallback.toDate().toISOString();
}

export function financeTimestampToOptionalIso(value: unknown): string | null {
  const ms = financeTimestampToMillis(value);
  return ms > 0 ? new Date(ms).toISOString() : null;
}

export function mediaRecordOrNull(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== "object") {
    return null;
  }
  return value as Record<string, unknown>;
}

export function normalizeMediaIsoTimestamp(
  value: unknown,
  fallback: Timestamp,
): string {
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Date.parse(value);
    if (Number.isFinite(parsed)) {
      return new Date(parsed).toISOString();
    }
  }
  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return new Date(value).toISOString();
  }
  return fallback.toDate().toISOString();
}
