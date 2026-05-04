import { describe, expect, it } from "vitest";

import {
  resolveDefaultFinanceTransportMode,
  type DefaultFinanceTransportMode,
} from "./default-command-transport";

function resolveMode(env: Record<string, string | undefined>): DefaultFinanceTransportMode {
  return resolveDefaultFinanceTransportMode(env);
}

describe("resolveDefaultFinanceTransportMode", () => {
  it("uses server proxy mode for production live callable URLs", () => {
    expect(
      resolveMode({
        NODE_ENV: "production",
        NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
          "https://us-central1-wain-d2e28.cloudfunctions.net",
      }),
    ).toBe("proxy");
  });

  it("uses server proxy mode in production when no public callable URL is configured", () => {
    expect(
      resolveMode({
        NODE_ENV: "production",
      }),
    ).toBe("proxy");
  });

  it("keeps callable mode for emulator URLs", () => {
    expect(
      resolveMode({
        NODE_ENV: "production",
        NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
          "http://127.0.0.1:5001/wain-d2e28/us-central1",
      }),
    ).toBe("callable");
  });

  it("keeps callable mode outside production", () => {
    expect(
      resolveMode({
        NODE_ENV: "development",
        NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
          "https://us-central1-wain-d2e28.cloudfunctions.net",
      }),
    ).toBe("callable");
  });
});
