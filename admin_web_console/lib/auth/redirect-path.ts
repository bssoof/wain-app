const DEFAULT_ADMIN_PREFIX = "/admin";

export function normalizeAdminNextPath(
  rawValue: string | null | undefined,
): string | null {
  if (!rawValue) {
    return null;
  }

  const trimmed = rawValue.trim();
  if (!trimmed) {
    return null;
  }

  if (trimmed.startsWith("/")) {
    if (trimmed.startsWith("//")) {
      return null;
    }
    return trimmed.startsWith(DEFAULT_ADMIN_PREFIX) ? trimmed : null;
  }

  try {
    const parsed = new URL(trimmed);
    const candidate = `${parsed.pathname}${parsed.search}`;
    return candidate.startsWith(DEFAULT_ADMIN_PREFIX) ? candidate : null;
  } catch {
    return null;
  }
}

export function resolveAdminNextPath(
  rawValue: string | null | undefined,
  fallbackPath: string,
): string {
  return normalizeAdminNextPath(rawValue) ?? fallbackPath;
}

export function resolveAdminNextPathFromCandidates(
  candidates: Array<string | null | undefined>,
  fallbackPath: string,
): string {
  for (const candidate of candidates) {
    const normalized = normalizeAdminNextPath(candidate);
    if (normalized) {
      return normalized;
    }
  }

  return fallbackPath;
}