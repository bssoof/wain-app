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

const allowUnsafe = process.env.WAIN_ALLOW_UNSAFE_PUBLIC_PRIVILEGED_TOKENS === "true";
if (allowUnsafe) {
  console.warn(
    "[security-guard] bypass enabled via WAIN_ALLOW_UNSAFE_PUBLIC_PRIVILEGED_TOKENS=true",
  );
  process.exit(0);
}

const configured = FORBIDDEN_PUBLIC_KEYS.filter((key) => {
  const value = process.env[key];
  return typeof value === "string" && value.trim().length > 0;
});

if (configured.length > 0) {
  console.error("[security-guard] Forbidden NEXT_PUBLIC privileged tokens detected:");
  for (const key of configured) {
    console.error(` - ${key}`);
  }
  console.error(
    "[security-guard] Remove these variables from production/staging build environment.",
  );
  process.exit(1);
}

console.log("[security-guard] No forbidden NEXT_PUBLIC privileged tokens detected.");
