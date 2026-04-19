import { readFileSync } from "node:fs";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

const ROOT = process.cwd();

const PROTECTED_PAGES = [
  "app/(protected)/admin/config/page.tsx",
  "app/(protected)/admin/readiness/page.tsx",
  "app/(protected)/admin/content/offers/page.tsx",
  "app/(protected)/admin/content/stories/page.tsx",
  "app/(protected)/admin/content/reviews/page.tsx",
  "app/(protected)/admin/wallet-audit/page.tsx",
  "app/(protected)/admin/venues/page.tsx",
  "app/(protected)/admin/venues/[venueId]/page.tsx",
  "app/(protected)/admin/topups/page.tsx",
  "app/(protected)/admin/media/page.tsx",
] as const;

describe("protected route loader ordering", () => {
  for (const relativePath of PROTECTED_PAGES) {
    it(`${relativePath} awaits route access before sensitive loader calls`, () => {
      const absolutePath = join(ROOT, relativePath);
      const content = readFileSync(absolutePath, "utf8");

      const lines = content.split(/\r?\n/);
      const guardLineIndex = lines.findIndex((line) =>
        line.includes("await requireRouteAccess("),
      );

      expect(guardLineIndex, "missing await requireRouteAccess").toBeGreaterThan(-1);

      const forbiddenParallelPattern =
        /const\s+\w+Promise\s*=\s*(load\w+|load\w+\(|requireRouteAccess\()/;
      expect(forbiddenParallelPattern.test(content)).toBe(false);

      const loaderCallLineIndexes = lines
        .map((line, index) => ({ line, index }))
        .filter(({ line }) => /await\s+load[A-Z]\w*\(/.test(line))
        .map(({ index }) => index);

      expect(loaderCallLineIndexes.length).toBeGreaterThan(0);
      for (const index of loaderCallLineIndexes) {
        expect(index).toBeGreaterThan(guardLineIndex);
      }
    });
  }
});
