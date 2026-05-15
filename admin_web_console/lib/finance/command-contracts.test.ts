import { describe, expect, it } from "vitest";

import {
  FINANCE_COMMANDS,
  FINANCE_COMMAND_METADATA,
} from "./command-contracts";

describe("finance command contracts", () => {
  it("has complete metadata for every command", () => {
    const commandKeys = [...FINANCE_COMMANDS].sort();
    const metadataKeys = Object.keys(FINANCE_COMMAND_METADATA).sort();

    expect(metadataKeys).toEqual(commandKeys);

    for (const command of FINANCE_COMMANDS) {
      const metadata = FINANCE_COMMAND_METADATA[command];
      expect(metadata.requiredCapability.length).toBeGreaterThan(0);
      expect(metadata.allowedRoles.length).toBeGreaterThan(0);
      expect(metadata.idempotency.required).toBe(true);
      expect(metadata.idempotency.keyField).toBe("commandId");
    }
  });

  it("locks expected_state requirements for sensitive write commands", () => {
    expect(FINANCE_COMMAND_METADATA.approve_topup.expectedState).toEqual({
      required: true,
      requiredFields: ["status", "decision_state"],
    });

    expect(FINANCE_COMMAND_METADATA.reject_topup.expectedState).toEqual({
      required: true,
      requiredFields: ["status", "decision_state"],
    });

    expect(FINANCE_COMMAND_METADATA.reverse_wallet_entry.expectedState).toEqual({
      required: true,
      requiredFields: ["entry_status", "reversal_state", "entry_type"],
    });

    expect(FINANCE_COMMAND_METADATA.approve_reversal.expectedState).toEqual({
      required: true,
      requiredFields: ["approval_state", "request_not_expired"],
    });

    expect(FINANCE_COMMAND_METADATA.review_merchant_reversal.expectedState).toEqual({
      required: false,
      requiredFields: [],
    });

    expect(FINANCE_COMMAND_METADATA.verify_wallet_readiness.expectedState).toEqual({
      required: false,
      requiredFields: [],
    });
  });
});
