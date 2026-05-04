export type FixtureFallbackTier = "local" | "staging" | "production";

export type FixtureFallbackPolicy = {
  tier: FixtureFallbackTier;
  allowed: boolean;
  reason:
    | "local_allowed"
    | "staging_explicit_allowed"
    | "staging_explicit_required"
    | "production_blocked";
  cacheKey: string;
};

export const FIXTURE_FALLBACK_DISABLED_MESSAGE_AR =
  "مصدر البيانات غير متاح حاليًا لأن بيانات التجربة معطلة في هذه البيئة.";

export function resolveFixtureFallbackPolicy(
  env: Record<string, string | undefined>,
): FixtureFallbackPolicy {
  const tier = resolveFixtureFallbackTier(env);
  const explicitAllow = isTruthy(readEnv(env, "WAIN_ALLOW_FIXTURE_FALLBACK"));

  if (tier === "local") {
    return {
      tier,
      allowed: true,
      reason: "local_allowed",
      cacheKey: buildPolicyCacheKey(tier, explicitAllow),
    };
  }

  if (tier === "staging" && explicitAllow) {
    return {
      tier,
      allowed: true,
      reason: "staging_explicit_allowed",
      cacheKey: buildPolicyCacheKey(tier, explicitAllow),
    };
  }

  if (tier === "staging") {
    return {
      tier,
      allowed: false,
      reason: "staging_explicit_required",
      cacheKey: buildPolicyCacheKey(tier, explicitAllow),
    };
  }

  return {
    tier,
    allowed: false,
    reason: "production_blocked",
    cacheKey: buildPolicyCacheKey(tier, explicitAllow),
  };
}

export function resolveFixtureFallbackTier(
  env: Record<string, string | undefined>,
): FixtureFallbackTier {
  const explicitTier = normalize(
    readEnv(env, "WAIN_ADMIN_ENV_TIER") ??
      readEnv(env, "WAIN_ENV_TIER") ??
      readEnv(env, "WAIN_RUNTIME_ENV"),
  );
  if (explicitTier === "production" || explicitTier === "prod") {
    return "production";
  }
  if (explicitTier === "staging" || explicitTier === "preview") {
    return "staging";
  }
  if (
    explicitTier === "local" ||
    explicitTier === "dev" ||
    explicitTier === "development"
  ) {
    return "local";
  }

  const vercelEnv = normalize(readEnv(env, "VERCEL_ENV"));
  if (vercelEnv === "production") {
    return "production";
  }
  if (vercelEnv === "preview") {
    return "staging";
  }

  const nodeEnv = normalize(readEnv(env, "NODE_ENV"));
  if (nodeEnv !== "production") {
    return "local";
  }

  if (hasLocalFunctionsBaseUrl(env)) {
    return "local";
  }

  // Fail closed in production-like runtimes where tier is not explicitly known.
  return "staging";
}

function hasLocalFunctionsBaseUrl(
  env: Record<string, string | undefined>,
): boolean {
  const candidateUrls = [
    readEnv(env, "NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL"),
    readEnv(env, "NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL"),
    readEnv(env, "NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL"),
    readEnv(env, "NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL"),
    readEnv(env, "NEXT_PUBLIC_WAIN_REVIEWS_FUNCTIONS_BASE_URL"),
    readEnv(env, "NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL"),
  ];

  return candidateUrls.some((value) => {
    if (typeof value !== "string") {
      return false;
    }

    const normalized = value.trim().toLowerCase();
    return (
      normalized.includes("localhost") ||
      normalized.includes("127.0.0.1") ||
      normalized.includes("0.0.0.0")
    );
  });
}

function readEnv(
  env: Record<string, string | undefined>,
  key: string,
): string | undefined {
  return env[key] ?? process.env[key];
}

function isTruthy(value: string | undefined): boolean {
  if (typeof value !== "string") {
    return false;
  }

  const normalized = value.trim().toLowerCase();
  return (
    normalized === "1" ||
    normalized === "true" ||
    normalized === "yes" ||
    normalized === "on"
  );
}

function normalize(value: string | undefined): string {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

function buildPolicyCacheKey(
  tier: FixtureFallbackTier,
  explicitAllow: boolean,
): string {
  return `fixtureTier=${tier}|fixtureAllow=${explicitAllow ? "1" : "0"}`;
}
