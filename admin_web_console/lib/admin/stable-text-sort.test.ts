import { describe, expect, it } from "vitest";

import { compareAdminText } from "./stable-text-sort";

describe("compareAdminText", () => {
  it("sorts mixed Arabic and Latin labels deterministically", () => {
    const labels = [
      "Phase7 venue_phase7_1775874615957",
      "ستونز",
      "Alpha",
      "بيت لحم",
    ];

    expect([...labels].sort(compareAdminText)).toEqual([
      "بيت لحم",
      "ستونز",
      "Alpha",
      "Phase7 venue_phase7_1775874615957",
    ]);
  });

  it("normalizes whitespace and casing without relying on locale collation", () => {
    const labels = [" beta", "Alpha", "alpha"];

    expect([...labels].sort(compareAdminText)).toEqual(["Alpha", "alpha", " beta"]);
  });
});
