import { describe, expect, it } from "vitest";

import { predictReversalPath } from "./merchant-reversal-review";

describe("predictReversalPath", () => {
  it("routes amount below single-approval limit to direct execution", () => {
    expect(predictReversalPath(50)).toEqual({
      kind: "direct",
      label: "سيُنفَّذ التصحيح مباشرة",
    });
  });

  it("routes amount at 100 ILS to direct execution", () => {
    expect(predictReversalPath(100).kind).toBe("direct");
  });

  it("routes amount above 100 ILS to finance admin second approval", () => {
    expect(predictReversalPath(100.01).kind).toBe("needs_finance_admin");
  });

  it("routes amount at 500 ILS to finance admin second approval", () => {
    expect(predictReversalPath(500).kind).toBe("needs_finance_admin");
  });

  it("routes amount above 500 ILS to super admin second approval", () => {
    expect(predictReversalPath(500.01).kind).toBe("needs_super_admin");
  });
});
