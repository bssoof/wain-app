import { describe, expect, it } from "vitest";

import { createFinanceCallableInvokerFromEnv } from "@/lib/finance/finance-command-transport";

describe("security: production blocks NEXT_PUBLIC privileged tokens", () => {
  const liveBaseUrl = "https://us-central1-wain-d2e28.cloudfunctions.net";

  it("rejects NEXT_PUBLIC auth token in production", () => {
    const result = createFinanceCallableInvokerFromEnv({
      NODE_ENV: "production",
      NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: liveBaseUrl,
      NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN: "public-privileged-auth-token",
    });

    expect(result).toMatchObject({
      ok: false,
      reason:
        "NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN is forbidden in production. Use a server-side admin command proxy.",
    });
  });

  it("rejects NEXT_PUBLIC app check token in production", () => {
    const result = createFinanceCallableInvokerFromEnv({
      NODE_ENV: "production",
      NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: liveBaseUrl,
      NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN: "public-app-check-token",
    });

    expect(result).toMatchObject({
      ok: false,
      reason:
        "NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN is forbidden in production. Use a server-side admin command proxy.",
    });
  });

  it("keeps non-production behavior unchanged", () => {
    const result = createFinanceCallableInvokerFromEnv({
      NODE_ENV: "test",
      NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: liveBaseUrl,
      NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN: "test-auth-token",
      NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN: "test-app-check-token",
    });

    expect(result).toMatchObject({
      ok: true,
    });
  });
});
