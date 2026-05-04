#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

function canonicalDecision(value) {
  const normalized = String(value || "")
    .trim()
    .toUpperCase()
    .replace(/`/g, "")
    .replace(/\s+/g, " ");

  if (normalized === "NO-GO" || normalized === "NO_GO") {
    return "NO_GO";
  }
  if (normalized === "CONDITIONAL GO" || normalized === "CONDITIONAL_GO") {
    return "CONDITIONAL_GO";
  }
  if (
    normalized === "GO" ||
    normalized === "GO_LIVE_READY" ||
    normalized === "GO-LIVE-READY"
  ) {
    return "GO";
  }
  return null;
}

function readText(filePath) {
  return fs.readFileSync(filePath, "utf8");
}

function extractReportDecision(reportText) {
  const match = reportText.match(
    /Current recommendation:\s*\*\*(NO-GO|NO_GO|CONDITIONAL GO|CONDITIONAL_GO|GO|GO_LIVE_READY|GO-LIVE-READY)\*\*/i,
  );
  if (!match) {
    return null;
  }
  return canonicalDecision(match[1]);
}

function extractChecklistDecision(checklistText) {
  const match = checklistText.match(/- Decision:\s*`([^`]+)`/i);
  if (!match) {
    return null;
  }
  return canonicalDecision(match[1]);
}

function extractChecklistRecommendation(checklistText) {
  const sectionMatch = checklistText.match(
    /##\s*6\.\s*Current Recommendation[\s\S]*?(?:\n-\s*`([^`]+)`)/i,
  );
  if (!sectionMatch) {
    return null;
  }
  return canonicalDecision(sectionMatch[1]);
}

function hasStaleSuiteCountSnapshot(checklistText) {
  return /npm\s+(?:test|run\s+test|run\s+build)[^\n]*->\s*`\d+\s*\/\s*\d+`/i.test(
    checklistText,
  );
}

function latestReadinessReportPath(releaseDir) {
  const candidates = fs
    .readdirSync(releaseDir)
    .filter((name) =>
      name.startsWith("admin_web_console_full_launch_readiness_report_") &&
      name.endsWith(".md"),
    )
    .sort();

  if (candidates.length === 0) {
    return null;
  }

  return path.join(releaseDir, candidates[candidates.length - 1]);
}

function main() {
  const scriptDir = path.dirname(fileURLToPath(import.meta.url));
  const repoRoot = path.resolve(scriptDir, "..");
  const releaseDir = path.join(repoRoot, "docs", "release");
  const checklistPath = path.join(
    releaseDir,
    "admin_web_console_release_checklist.md",
  );
  const reportPath = latestReadinessReportPath(releaseDir);

  const errors = [];

  if (!fs.existsSync(checklistPath)) {
    errors.push(`Missing checklist file: ${checklistPath}`);
  }
  if (!reportPath) {
    errors.push(
      "Missing readiness report file matching admin_web_console_full_launch_readiness_report_*.md",
    );
  }

  if (errors.length > 0) {
    for (const error of errors) {
      console.error(`[release-checklist] ${error}`);
    }
    process.exit(1);
  }

  const checklistText = readText(checklistPath);
  const reportText = readText(reportPath);

  const reportDecision = extractReportDecision(reportText);
  const checklistDecision = extractChecklistDecision(checklistText);
  const checklistRecommendation = extractChecklistRecommendation(checklistText);

  if (!reportDecision) {
    errors.push(
      `Could not parse Current recommendation from readiness report: ${path.basename(reportPath)}`,
    );
  }
  if (!checklistDecision) {
    errors.push("Could not parse Decision value from release checklist.");
  }
  if (!checklistRecommendation) {
    errors.push("Could not parse Current Recommendation value from release checklist.");
  }

  if (checklistText.includes("GO_LIVE_READY")) {
    errors.push(
      "Release checklist still contains legacy GO_LIVE_READY token. Use explicit NO_GO | CONDITIONAL_GO | GO.",
    );
  }

  if (hasStaleSuiteCountSnapshot(checklistText)) {
    errors.push(
      "Release checklist still contains stale hard-coded suite count snapshots (e.g. `219/219`) in command evidence lines.",
    );
  }

  if (reportDecision && checklistDecision && reportDecision !== checklistDecision) {
    errors.push(
      `Decision mismatch: report=${reportDecision} checklist=${checklistDecision}`,
    );
  }

  if (
    reportDecision &&
    checklistRecommendation &&
    reportDecision !== checklistRecommendation
  ) {
    errors.push(
      `Current Recommendation mismatch: report=${reportDecision} checklist=${checklistRecommendation}`,
    );
  }

  if (errors.length > 0) {
    for (const error of errors) {
      console.error(`[release-checklist] ${error}`);
    }
    process.exit(1);
  }

  console.log(
    `[release-checklist] PASS decision=${reportDecision} report=${path.basename(reportPath)} checklist=${path.basename(checklistPath)}`,
  );
}

main();
