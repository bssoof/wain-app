const MAX_WARMUP_DEDUPE_CACHE_SIZE = 256;

export type WarmupDedupeEntry = {
  expiresAt: number;
};

const g = globalThis as typeof globalThis & {
  adminWarmupDedupeCache?: Map<string, WarmupDedupeEntry>;
};

g.adminWarmupDedupeCache ??= new Map<string, WarmupDedupeEntry>();
const adminWarmupDedupeCache = g.adminWarmupDedupeCache;

export function claimAdminWarmupRequest(uid: string, ttlMs: number): boolean {
  if (ttlMs <= 0) {
    return true;
  }

  const now = Date.now();
  const existing = adminWarmupDedupeCache.get(uid);
  if (existing && existing.expiresAt > now) {
    return false;
  }

  adminWarmupDedupeCache.set(uid, { expiresAt: now + ttlMs });
  pruneAdminWarmupDedupeCache(now);
  return true;
}

export function __resetAdminWarmupDedupeForTests(): void {
  adminWarmupDedupeCache.clear();
}

function pruneAdminWarmupDedupeCache(now: number): void {
  for (const [key, entry] of adminWarmupDedupeCache) {
    if (entry.expiresAt <= now) {
      adminWarmupDedupeCache.delete(key);
    }
  }

  while (adminWarmupDedupeCache.size > MAX_WARMUP_DEDUPE_CACHE_SIZE) {
    const oldestKey = adminWarmupDedupeCache.keys().next().value as
      | string
      | undefined;
    if (!oldestKey) {
      return;
    }
    adminWarmupDedupeCache.delete(oldestKey);
  }
}
