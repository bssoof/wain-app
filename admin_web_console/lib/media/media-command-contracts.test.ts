import { describe, expect, it } from "vitest";

import {
  MEDIA_COMMANDS,
  MEDIA_COMMAND_METADATA,
} from "./media-command-contracts";

describe("media command contracts", () => {
  it("has complete metadata coverage for every media command", () => {
    const commandKeys = [...MEDIA_COMMANDS].sort();
    const metadataKeys = Object.keys(MEDIA_COMMAND_METADATA).sort();

    expect(metadataKeys).toEqual(commandKeys);

    for (const command of MEDIA_COMMANDS) {
      const metadata = MEDIA_COMMAND_METADATA[command];
      expect(metadata.requiredCapability.length).toBeGreaterThan(0);
      expect(metadata.allowedRoles).toEqual(["super_admin", "content_admin"]);
      expect(metadata.idempotency.required).toBe(true);
      expect(metadata.idempotency.keyField).toBe("commandId");
    }
  });

  it("locks purge expected_state requirements for safety gates", () => {
    expect(MEDIA_COMMAND_METADATA.media_purge.expectedState).toEqual({
      required: true,
      requiredFields: [
        "media_state",
        "reference_count",
        "reference_index_health",
      ],
    });

    expect(MEDIA_COMMAND_METADATA.media_reference_check.expectedState).toEqual({
      required: false,
      requiredFields: [],
    });
  });
});
