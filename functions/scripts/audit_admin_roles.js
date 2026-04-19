#!/usr/bin/env node
/* eslint-disable no-console */

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const VALID_ADMIN_ROLES = new Set([
  "super_admin",
  "finance_admin",
  "content_admin",
  "support_admin",
  "ops_viewer",
]);

function parseArgs(argv) {
  const args = {};
  for (const token of argv) {
    if (!token.startsWith("--")) continue;
    const [rawKey, ...valueParts] = token.slice(2).split("=");
    if (!rawKey) continue;
    args[rawKey.trim()] = valueParts.length > 0 ? valueParts.join("=").trim() : true;
  }
  return args;
}

function printUsage() {
  console.log(
    [
      "Usage:",
      "  node scripts/audit_admin_roles.js [--project=<id>] [--output=<path>]",
      "",
      "Examples:",
      "  node scripts/audit_admin_roles.js",
      "  node scripts/audit_admin_roles.js --project=wain-d2e28",
      "  node scripts/audit_admin_roles.js --output=../docs/release/admin_role_audit_report_latest.json",
    ].join("\n"),
  );
}

function resolveProjectId(rootDir, args) {
  const fromArgs = typeof args.project === "string" ? args.project.trim() : "";
  if (fromArgs.length > 0) {
    return fromArgs;
  }

  const direct =
    process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
  if (typeof direct === "string" && direct.trim().length > 0) {
    return direct.trim();
  }

  const firebasercPath = path.join(rootDir, ".firebaserc");
  if (!fs.existsSync(firebasercPath)) {
    throw new Error("Missing .firebaserc and no --project/GCLOUD_PROJECT was provided.");
  }

  const firebaserc = JSON.parse(fs.readFileSync(firebasercPath, "utf8"));
  const projectId = firebaserc?.projects?.default;
  if (typeof projectId !== "string" || projectId.trim().length === 0) {
    throw new Error("Unable to resolve project id from .firebaserc.");
  }

  return projectId.trim();
}

function resolveServiceAccountPath(rootDir) {
  const envPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (typeof envPath === "string" && envPath.trim().length > 0 && fs.existsSync(envPath.trim())) {
    return envPath.trim();
  }

  const candidates = [
    path.join(rootDir, "service-account-key.json"),
    path.join(path.dirname(rootDir), "scripts", "serviceAccountKey.json"),
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  throw new Error(
    "Missing service-account key. Set GOOGLE_APPLICATION_CREDENTIALS or place service-account-key.json under wain_app/.",
  );
}

function collectRoles(raw) {
  const roles = [];

  if (typeof raw.role === "string" && raw.role.trim().length > 0) {
    roles.push(raw.role.trim());
  }

  const rawRoles = raw.roles;
  if (Array.isArray(rawRoles)) {
    for (const item of rawRoles) {
      if (typeof item === "string" && item.trim().length > 0) {
        roles.push(item.trim());
      }
    }
  } else if (typeof rawRoles === "string" && rawRoles.trim().length > 0) {
    roles.push(
      ...rawRoles
        .split(",")
        .map((item) => item.trim())
        .filter(Boolean),
    );
  }

  return Array.from(new Set(roles));
}

function toIso(value) {
  if (!value) return null;

  if (typeof value.toDate === "function") {
    return value.toDate().toISOString();
  }

  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
}

async function writeJson(outputPath, payload) {
  await fs.promises.mkdir(path.dirname(outputPath), { recursive: true });
  await fs.promises.writeFile(outputPath, `${JSON.stringify(payload, null, 2)}\n`, "utf8");
}

async function run() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help || args.h) {
    printUsage();
    return;
  }

  const rootDir = path.resolve(__dirname, "..", "..");
  const outputPath =
    typeof args.output === "string" && args.output.trim().length > 0
      ? path.resolve(process.cwd(), args.output.trim())
      : path.join(rootDir, "docs", "release", "admin_role_audit_report_latest.json");

  const projectId = resolveProjectId(rootDir, args);
  const serviceAccountPath = resolveServiceAccountPath(rootDir);
  const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, "utf8"));

  process.env.GOOGLE_APPLICATION_CREDENTIALS = serviceAccountPath;
  process.env.GCLOUD_PROJECT = projectId;

  const app = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId,
  });

  try {
    const db = admin.firestore();
    const adminsSnap = await db.collection("admins").get();

    const summary = {
      total: adminsSnap.size,
      active: 0,
      inactive: 0,
      missingRole: 0,
      invalidRole: 0,
    };

    const findings = [];

    for (const doc of adminsSnap.docs) {
      const raw = doc.data() || {};
      const active = raw.active !== false;
      const roles = collectRoles(raw);
      const invalidRoles = roles.filter((role) => !VALID_ADMIN_ROLES.has(role));
      const issueCodes = [];

      if (active) {
        summary.active += 1;
      } else {
        summary.inactive += 1;
      }

      if (roles.length === 0) {
        issueCodes.push("missing_role");
        summary.missingRole += 1;
      }

      if (invalidRoles.length > 0) {
        issueCodes.push("invalid_role");
        summary.invalidRole += 1;
      }

      if (issueCodes.length === 0) {
        continue;
      }

      findings.push({
        uid: doc.id,
        active,
        roles,
        invalidRoles,
        issueCodes,
        updatedAt: toIso(raw.updated_at),
        createdAt: toIso(raw.created_at),
      });
    }

    const report = {
      generatedAt: new Date().toISOString(),
      projectId,
      source: "admins",
      validRoles: Array.from(VALID_ADMIN_ROLES),
      summary,
      findings,
    };

    await writeJson(outputPath, report);

    console.log(`[audit-admin-roles] Project: ${projectId}`);
    console.log(`[audit-admin-roles] Admin docs scanned: ${summary.total}`);
    console.log(`[audit-admin-roles] Active: ${summary.active}, Inactive: ${summary.inactive}`);
    console.log(
      `[audit-admin-roles] Findings => missing_role: ${summary.missingRole}, invalid_role: ${summary.invalidRole}`,
    );
    console.log(`[audit-admin-roles] Report: ${outputPath}`);
  } finally {
    await app.delete();
  }
}

run().catch((error) => {
  console.error("[audit-admin-roles] Failed:", error && error.message ? error.message : error);
  process.exit(1);
});
