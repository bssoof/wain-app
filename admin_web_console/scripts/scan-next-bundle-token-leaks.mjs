import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join, resolve } from "node:path";
import process from "node:process";

const FORBIDDEN_PUBLIC_KEYS = [
  "NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN",
  "NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN",
  "NEXT_PUBLIC_WAIN_CONTENT_AUTH_TOKEN",
  "NEXT_PUBLIC_WAIN_CONTENT_APP_CHECK_TOKEN",
  "NEXT_PUBLIC_WAIN_VENUE_AUTH_TOKEN",
  "NEXT_PUBLIC_WAIN_VENUE_APP_CHECK_TOKEN",
  "NEXT_PUBLIC_WAIN_CONFIG_AUTH_TOKEN",
  "NEXT_PUBLIC_WAIN_CONFIG_APP_CHECK_TOKEN",
  "NEXT_PUBLIC_WAIN_MEDIA_AUTH_TOKEN",
  "NEXT_PUBLIC_WAIN_MEDIA_APP_CHECK_TOKEN",
];

const args = process.argv.slice(2);
const sentinelIndex = args.indexOf("--sentinel");
const sentinelFromArg = sentinelIndex >= 0 ? args[sentinelIndex + 1] : undefined;
const sentinel =
  (sentinelFromArg && sentinelFromArg.trim()) ||
  process.env.WAIN_BUNDLE_SCAN_SENTINEL_TOKEN?.trim();

if (!sentinel) {
  console.error(
    "[bundle-scan] Missing sentinel token. Pass --sentinel <value> or set WAIN_BUNDLE_SCAN_SENTINEL_TOKEN.",
  );
  process.exit(1);
}

const nextDir = resolve(process.cwd(), ".next");
if (!existsSync(nextDir)) {
  console.error(`[bundle-scan] Build output folder not found: ${nextDir}`);
  process.exit(1);
}

const needles = new Set([sentinel]);
for (const key of FORBIDDEN_PUBLIC_KEYS) {
  const value = process.env[key];
  if (typeof value === "string" && value.trim().length > 0) {
    needles.add(value.trim());
  }
}

const files = walkFiles(nextDir).filter(
  (filePath) => !filePath.includes(`${join(".next", "cache")}`),
);
const leaks = [];

for (const filePath of files) {
  let content;
  try {
    content = readFileSync(filePath, "utf8");
  } catch {
    continue;
  }

  for (const needle of needles) {
    if (needle.length === 0) {
      continue;
    }

    if (content.includes(needle)) {
      leaks.push({ filePath, needle });
    }
  }
}

if (leaks.length > 0) {
  console.error("[bundle-scan] Detected possible token leaks in .next output:");
  for (const leak of leaks.slice(0, 20)) {
    console.error(` - ${leak.filePath} (matched: ${truncate(leak.needle, 24)})`);
  }
  if (leaks.length > 20) {
    console.error(` - ... and ${leaks.length - 20} more`);
  }
  process.exit(1);
}

console.log(
  `[bundle-scan] Passed. No sentinel/forbidden token values found in ${files.length} .next files.`,
);

function walkFiles(startDir) {
  const output = [];
  const entries = readdirSync(startDir);

  for (const entry of entries) {
    const absolute = join(startDir, entry);
    const stats = statSync(absolute);
    if (stats.isDirectory()) {
      output.push(...walkFiles(absolute));
      continue;
    }

    if (stats.isFile()) {
      output.push(absolute);
    }
  }

  return output;
}

function truncate(value, maxLength) {
  if (value.length <= maxLength) {
    return value;
  }

  return `${value.slice(0, maxLength)}...`;
}
