import { execFileSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const adminWebRoot = path.resolve(__dirname, "..");
const wainRoot = path.resolve(adminWebRoot, "..");

const captureManifestPath = path.resolve(
  wainRoot,
  "docs",
  "release",
  "admin_web_console_ui_a02_baseline_capture.json",
);

const reportJsonPath = path.resolve(
  wainRoot,
  "docs",
  "release",
  "admin_web_console_ui_visual_diff_triage_ui_026.json",
);

const reportMarkdownPath = path.resolve(
  wainRoot,
  "docs",
  "release",
  "admin_web_console_ui_visual_diff_triage_ui_026.md",
);

function toWorkspaceRelative(absolutePath) {
  return path.relative(wainRoot, absolutePath).replace(/\\/g, "/");
}

function normalizeRepoPath(workspaceRelativePath) {
  return workspaceRelativePath.replace(/\\/g, "/");
}

function sha256(buffer) {
  return crypto.createHash("sha256").update(buffer).digest("hex");
}

function readPngDimensions(buffer) {
  if (!buffer || buffer.length < 24) {
    return null;
  }

  const signature = buffer.subarray(0, 8);
  const expected = Buffer.from([
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
  ]);

  if (!signature.equals(expected)) {
    return null;
  }

  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20),
  };
}

function headBlobExists(relativePath) {
  try {
    execFileSync("git", ["cat-file", "-e", `HEAD:${relativePath}`], {
      cwd: wainRoot,
      stdio: ["ignore", "ignore", "ignore"],
    });
    return true;
  } catch {
    return false;
  }
}

function readHeadBlob(relativePath) {
  if (!headBlobExists(relativePath)) {
    return null;
  }

  try {
    return execFileSync("git", ["show", `HEAD:${relativePath}`], {
      cwd: wainRoot,
      encoding: "buffer",
      maxBuffer: 128 * 1024 * 1024,
      stdio: ["ignore", "pipe", "ignore"],
    });
  } catch {
    return null;
  }
}

async function readCurrentFile(absolutePath) {
  try {
    return await fs.readFile(absolutePath);
  } catch {
    return null;
  }
}

function classifyDiff({ currentMeta, headMeta }) {
  if (!currentMeta && !headMeta) {
    return { status: "missing-both", severity: "critical" };
  }

  if (!currentMeta && headMeta) {
    return { status: "missing-current", severity: "critical" };
  }

  if (currentMeta && !headMeta) {
    return { status: "new-file", severity: "review" };
  }

  if (currentMeta.sha256 === headMeta.sha256) {
    return { status: "unchanged", severity: "info" };
  }

  const dimensionsChanged =
    currentMeta.width !== headMeta.width ||
    currentMeta.height !== headMeta.height;

  if (dimensionsChanged) {
    return { status: "changed-dimensions", severity: "critical" };
  }

  return { status: "changed-same-dimensions", severity: "review" };
}

function formatPercent(value) {
  if (typeof value !== "number" || Number.isNaN(value)) {
    return "-";
  }
  return `${(value * 100).toFixed(2)}%`;
}

function buildMarkdown({ generatedAt, sourceCaptureAt, entries, summary }) {
  const lines = [
    "# UI-026 - Visual Diff Triage (HEAD vs current artifacts)",
    "",
    `Generated at: ${generatedAt}`,
    `Source capture timestamp: ${sourceCaptureAt ?? "unknown"}`,
    "Method: screenshot artifact triage based on SHA-256, byte delta, and PNG dimensions.",
    "",
    "## Summary",
    "",
    `- Total screenshot entries: ${summary.total}`,
    `- Unchanged: ${summary.unchanged}`,
    `- Changed (same dimensions): ${summary.changedSameDimensions}`,
    `- Changed (dimensions): ${summary.changedDimensions}`,
    `- New files (not in HEAD): ${summary.newFiles}`,
    `- Missing current files: ${summary.missingCurrent}`,
    `- Critical findings: ${summary.critical}`,
    "",
    "## Decision",
    "",
    summary.critical === 0
      ? "- No critical visual artifact regressions were detected by this triage method."
      : "- Critical visual artifact drift exists and should be reviewed before acceptance.",
    "",
    "## Route Breakdown",
    "",
    "| Key | Screenshot | Status | Severity | Current Size | HEAD Size | Delta | Delta % | Current Dimensions | HEAD Dimensions |",
    "|---|---|---|---|---:|---:|---:|---:|---|---|",
  ];

  for (const entry of entries) {
    const currentDimensions = entry.current
      ? `${entry.current.width}x${entry.current.height}`
      : "-";
    const headDimensions = entry.head ? `${entry.head.width}x${entry.head.height}` : "-";

    lines.push(
      `| ${entry.key} | ${entry.screenshotPath} | ${entry.status} | ${entry.severity} | ${entry.current?.sizeBytes ?? "-"} | ${entry.head?.sizeBytes ?? "-"} | ${entry.sizeDeltaBytes ?? "-"} | ${formatPercent(entry.sizeDeltaRatio)} | ${currentDimensions} | ${headDimensions} |`,
    );
  }

  return `${lines.join("\n")}\n`;
}

async function main() {
  const captureRaw = await fs.readFile(captureManifestPath, "utf8");
  const capture = JSON.parse(captureRaw);

  const screenshotEntries = (capture.routes ?? []).filter(
    (route) => typeof route.screenshotPath === "string" && route.screenshotPath.length > 0,
  );

  const entries = [];

  for (const route of screenshotEntries) {
    const relativePath = normalizeRepoPath(route.screenshotPath);
    const absolutePath = path.resolve(wainRoot, relativePath);

    const currentBuffer = await readCurrentFile(absolutePath);
    const headBuffer = readHeadBlob(relativePath);

    const currentDims = currentBuffer ? readPngDimensions(currentBuffer) : null;
    const headDims = headBuffer ? readPngDimensions(headBuffer) : null;

    const currentMeta =
      currentBuffer && currentDims
        ? {
            sizeBytes: currentBuffer.length,
            sha256: sha256(currentBuffer),
            width: currentDims.width,
            height: currentDims.height,
          }
        : null;

    const headMeta =
      headBuffer && headDims
        ? {
            sizeBytes: headBuffer.length,
            sha256: sha256(headBuffer),
            width: headDims.width,
            height: headDims.height,
          }
        : null;

    const classified = classifyDiff({ currentMeta, headMeta });

    const sizeDeltaBytes =
      currentMeta && headMeta ? currentMeta.sizeBytes - headMeta.sizeBytes : null;
    const sizeDeltaRatio =
      currentMeta && headMeta && headMeta.sizeBytes > 0
        ? sizeDeltaBytes / headMeta.sizeBytes
        : null;

    entries.push({
      key: route.key,
      plannedPath: route.plannedPath ?? null,
      finalPath: route.finalPath ?? null,
      screenshotPath: relativePath,
      status: classified.status,
      severity: classified.severity,
      current: currentMeta,
      head: headMeta,
      sizeDeltaBytes,
      sizeDeltaRatio,
    });
  }

  const summary = {
    total: entries.length,
    unchanged: entries.filter((entry) => entry.status === "unchanged").length,
    changedSameDimensions: entries.filter(
      (entry) => entry.status === "changed-same-dimensions",
    ).length,
    changedDimensions: entries.filter((entry) => entry.status === "changed-dimensions").length,
    newFiles: entries.filter((entry) => entry.status === "new-file").length,
    missingCurrent: entries.filter((entry) => entry.status === "missing-current").length,
    critical: entries.filter((entry) => entry.severity === "critical").length,
    review: entries.filter((entry) => entry.severity === "review").length,
  };

  const report = {
    round: "UI-026",
    generatedAt: new Date().toISOString(),
    sourceCaptureAt: capture.capturedAt ?? null,
    sourceManifestPath: toWorkspaceRelative(captureManifestPath),
    method: {
      type: "artifact-diff",
      baselineRef: "HEAD",
      checks: ["sha256", "size-bytes", "png-dimensions"],
      note: "This triage does not perform pixel-level semantic diffing.",
    },
    summary,
    entries,
  };

  await fs.writeFile(reportJsonPath, `${JSON.stringify(report, null, 2)}\n`, "utf8");

  const markdown = buildMarkdown({
    generatedAt: report.generatedAt,
    sourceCaptureAt: report.sourceCaptureAt,
    entries,
    summary,
  });

  await fs.writeFile(reportMarkdownPath, markdown, "utf8");

  console.log(
    JSON.stringify(
      {
        ok: summary.critical === 0,
        total: summary.total,
        unchanged: summary.unchanged,
        changedSameDimensions: summary.changedSameDimensions,
        changedDimensions: summary.changedDimensions,
        newFiles: summary.newFiles,
        missingCurrent: summary.missingCurrent,
        reportJsonPath: toWorkspaceRelative(reportJsonPath),
        reportMarkdownPath: toWorkspaceRelative(reportMarkdownPath),
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
