import { chromium } from "@playwright/test";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const adminWebRoot = path.resolve(__dirname, "..");
const wainRoot = path.resolve(adminWebRoot, "..");
const releaseDir = path.resolve(wainRoot, "docs", "release");
const screenshotsDir = path.resolve(releaseDir, "ui_a02_baseline_screenshots");
const manifestPath = path.resolve(
  releaseDir,
  "admin_web_console_ui_a02_baseline_capture.json",
);
const summaryPath = path.resolve(
  releaseDir,
  "admin_web_console_ui_a02_baseline_capture.md",
);

const baseUrl = process.env.WAIN_UI_A02_BASE_URL ?? "http://127.0.0.1:3010";

const routePlan = [
  { key: "admin_index", path: "/admin", label: "Admin index" },
  { key: "sign_in", path: "/admin/sign-in", label: "Sign in" },
  {
    key: "access_denied",
    path: "/admin/access-denied?route=dashboard",
    label: "Access denied",
  },
  { key: "dashboard", path: "/admin/dashboard", label: "Dashboard" },
  { key: "topups", path: "/admin/topups", label: "Top-ups" },
  {
    key: "wallet_audit",
    path: "/admin/wallet-audit",
    label: "Wallet audit",
  },
  { key: "reversals", path: "/admin/reversals", label: "Reversals" },
  { key: "readiness", path: "/admin/readiness", label: "Readiness" },
  {
    key: "venues_directory",
    path: "/admin/venues",
    label: "Venues directory",
  },
  {
    key: "venues_workspace",
    path: null,
    resolver: "firstVenue",
    label: "Venue workspace",
  },
  { key: "media", path: "/admin/media", label: "Media" },
  {
    key: "content_offers",
    path: "/admin/content/offers",
    label: "Content offers",
  },
  {
    key: "content_stories",
    path: "/admin/content/stories",
    label: "Content stories",
  },
  {
    key: "content_reviews",
    path: "/admin/content/reviews",
    label: "Content reviews",
  },
  { key: "config", path: "/admin/config", label: "Config" },
];

function toAbsolute(pathname) {
  return new URL(pathname, baseUrl).toString();
}

function toRoutePath(urlValue) {
  try {
    const parsed = new URL(urlValue);
    return `${parsed.pathname}${parsed.search}`;
  } catch {
    return urlValue;
  }
}

function sanitizeFilePart(value) {
  return value.replace(/[^a-z0-9_\-]+/gi, "_").replace(/_+/g, "_");
}

function toWorkspaceRelative(absolutePath) {
  return path.relative(wainRoot, absolutePath).replace(/\\/g, "/");
}

async function ensureOutputDirectories() {
  await fs.mkdir(screenshotsDir, { recursive: true });
}

async function resolveFirstVenueWorkspacePath(page) {
  await page.goto(toAbsolute("/admin/venues"), {
    waitUntil: "domcontentloaded",
    timeout: 45_000,
  });
  await page.waitForTimeout(1_200);

  const resolved = await page.evaluate(() => {
    const links = Array.from(document.querySelectorAll("a[href]"));
    for (const link of links) {
      const rawHref = link.getAttribute("href") ?? "";
      if (/^\/admin\/venues\/[^/?#]+/.test(rawHref)) {
        return rawHref.split("#")[0];
      }
    }
    return null;
  });

  return resolved;
}

function buildMarkdownSummary({
  capturedAt,
  baseUrlValue,
  totalRoutes,
  successfulRoutes,
  redirectedRoutes,
  failedRoutes,
  entries,
}) {
  const lines = [
    "# UI-A02 Baseline Screenshot Evidence",
    "",
    `Captured at: ${capturedAt}`,
    `Base URL: ${baseUrlValue}`,
    `Total planned routes: ${totalRoutes}`,
    `Successful captures: ${successfulRoutes}`,
    `Guard redirects observed: ${redirectedRoutes}`,
    `Failed captures: ${failedRoutes}`,
    "",
    "## Artifacts",
    "",
    "- JSON manifest: docs/release/admin_web_console_ui_a02_baseline_capture.json",
    "- Screenshot directory: docs/release/ui_a02_baseline_screenshots",
    "",
    "## Route Results",
    "",
    "| Key | Planned Path | Final Path | HTTP | Redirected to Sign-in | Screenshot | Error |",
    "|---|---|---|---:|---|---|---|",
  ];

  for (const entry of entries) {
    lines.push(
      `| ${entry.key} | ${entry.plannedPath ?? "(resolved)"} | ${entry.finalPath ?? "-"} | ${entry.httpStatus ?? "-"} | ${entry.redirectedToSignIn ? "yes" : "no"} | ${entry.screenshotPath ?? "-"} | ${entry.error ?? "-"} |`,
    );
  }

  return `${lines.join("\n")}\n`;
}

async function main() {
  await ensureOutputDirectories();

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1728, height: 1117 },
    locale: "ar-SA",
  });
  const page = await context.newPage();

  const entries = [];
  let captureIndex = 0;

  try {
    for (const route of routePlan) {
      let plannedPath = route.path;
      let resolvedPath = route.path;
      let resolutionNote = null;

      if (route.resolver === "firstVenue") {
        const candidate = await resolveFirstVenueWorkspacePath(page);
        if (candidate) {
          resolvedPath = candidate;
          plannedPath = candidate;
          resolutionNote = "Resolved from /admin/venues links";
        } else {
          resolvedPath = "/admin/venues";
          plannedPath = "(resolver:fallback)/admin/venues";
          resolutionNote = "No venue workspace link was discoverable";
        }
      }

      captureIndex += 1;
      const fileName = `${String(captureIndex).padStart(2, "0")}_${sanitizeFilePart(route.key)}.png`;
      const screenshotAbsolutePath = path.resolve(screenshotsDir, fileName);
      const screenshotRelativePath = toWorkspaceRelative(screenshotAbsolutePath);

      try {
        const targetUrl = toAbsolute(resolvedPath);
        const response = await page.goto(targetUrl, {
          waitUntil: "domcontentloaded",
          timeout: 45_000,
        });

        await page.waitForTimeout(1_200);

        const finalUrl = page.url();
        const finalPath = toRoutePath(finalUrl);
        const httpStatus = response?.status() ?? null;
        const redirectedToSignIn =
          finalPath.startsWith("/admin/sign-in") &&
          !String(resolvedPath).startsWith("/admin/sign-in");

        await page.screenshot({
          path: screenshotAbsolutePath,
          fullPage: true,
        });

        entries.push({
          key: route.key,
          label: route.label,
          plannedPath,
          resolvedPath,
          finalPath,
          httpStatus,
          redirectedToSignIn,
          screenshotPath: screenshotRelativePath,
          resolutionNote,
          title: await page.title(),
          error: null,
        });
      } catch (error) {
        entries.push({
          key: route.key,
          label: route.label,
          plannedPath,
          resolvedPath,
          finalPath: null,
          httpStatus: null,
          redirectedToSignIn: false,
          screenshotPath: null,
          resolutionNote,
          title: null,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }
  } finally {
    await context.close();
    await browser.close();
  }

  const successfulRoutes = entries.filter((entry) => entry.screenshotPath).length;
  const redirectedRoutes = entries.filter((entry) => entry.redirectedToSignIn).length;
  const failedRoutes = entries.filter((entry) => entry.error).length;

  const manifest = {
    round: "UI-A02",
    capturedAt: new Date().toISOString(),
    baseUrl,
    totalRoutes: routePlan.length,
    successfulRoutes,
    redirectedRoutes,
    failedRoutes,
    environment: {
      nodeVersion: process.version,
      sessionJsonProvided: Boolean(process.env.WAIN_ADMIN_SESSION_JSON),
      strictAuth: process.env.WAIN_STRICT_AUTH ?? null,
    },
    routes: entries,
  };

  await fs.writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, "utf8");

  const summaryContent = buildMarkdownSummary({
    capturedAt: manifest.capturedAt,
    baseUrlValue: baseUrl,
    totalRoutes: manifest.totalRoutes,
    successfulRoutes,
    redirectedRoutes,
    failedRoutes,
    entries,
  });

  await fs.writeFile(summaryPath, summaryContent, "utf8");

  console.log(
    JSON.stringify(
      {
        ok: failedRoutes === 0,
        totalRoutes: routePlan.length,
        successfulRoutes,
        redirectedRoutes,
        failedRoutes,
        manifestPath: toWorkspaceRelative(manifestPath),
        summaryPath: toWorkspaceRelative(summaryPath),
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
