import { describe, expect, it } from "vitest";

import {
  resolveDefaultMediaTransportMode,
  type DefaultMediaTransportMode,
} from "./default-media-command-transport";

function resolveMode(env: Record<string, string | undefined>): DefaultMediaTransportMode {
  return resolveDefaultMediaTransportMode(env);
}

describe("resolveDefaultMediaTransportMode", () => {
  it("uses server proxy mode for production live callable URLs", () => {
    expect(
      resolveMode({
        NODE_ENV: "production",
        NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL:
          "https://us-central1-wain-d2e28.cloudfunctions.net",
      }),
    ).toBe("proxy");
  });

  it("keeps callable mode for emulator URLs", () => {
    expect(
      resolveMode({
        NODE_ENV: "production",
        NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL:
          "http://127.0.0.1:5001/wain-d2e28/us-central1",
      }),
    ).toBe("callable");
  });

  it("keeps callable mode outside production", () => {
    expect(
      resolveMode({
        NODE_ENV: "development",
        NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL:
          "https://us-central1-wain-d2e28.cloudfunctions.net",
      }),
    ).toBe("callable");
  });
});
