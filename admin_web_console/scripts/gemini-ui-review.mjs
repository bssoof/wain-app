#!/usr/bin/env node
/**
 * Gemini Vision UI Review Script
 *
 * Reads baseline screenshots and asks Gemini to produce structured findings.
 * Output is appended to docs/release/ui_a02_baseline_findings.md replacing the
 * placeholder lines for each route.
 *
 * Usage:
 *   GEMINI_API_KEY=AIza... node admin_web_console/scripts/gemini-ui-review.mjs
 *
 * Env:
 *   GEMINI_API_KEY (required)
 *   GEMINI_MODEL   (optional, default "gemini-1.5-flash")
 *   GEMINI_DRY_RUN (optional, "1" = no API calls, prints plan only)
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, "..", "..");

const SHOTS_DIR = path.join(REPO_ROOT, "docs", "release", "ui_a02_baseline_screenshots");
const FINDINGS_PATH = path.join(REPO_ROOT, "docs", "release", "ui_a02_baseline_findings.md");
const REPORT_JSON = path.join(REPO_ROOT, "docs", "release", "ui_a02_baseline_findings_gemini.json");

const API_KEY = process.env.GEMINI_API_KEY;
const MODEL = process.env.GEMINI_MODEL || "gemini-2.5-flash";
const DRY_RUN = process.env.GEMINI_DRY_RUN === "1";
const RPM_DELAY_MS = 1500;

if (!API_KEY) {
    console.error("ERROR: GEMINI_API_KEY env var is required.");
    process.exit(1);
}

const ROUTE_MAP = [
    { file: "01_admin_index.png", route: "/admin", label: "Admin root", priority: "P2" },
    { file: "02_sign_in.png", route: "/admin/sign-in", label: "Sign-in page", priority: "P2" },
    { file: "03_access_denied.png", route: "/admin/access-denied", label: "Access denied", priority: "P2" },
    { file: "04_dashboard.png", route: "/admin/dashboard", label: "Operational dashboard", priority: "P0" },
    { file: "05_topups.png", route: "/admin/topups", label: "Top-up queue", priority: "P0" },
    { file: "06_wallet_audit.png", route: "/admin/wallet-audit", label: "Wallet audit", priority: "P1" },
    { file: "07_reversals.png", route: "/admin/reversals", label: "Reversals", priority: "P1" },
    { file: "08_readiness.png", route: "/admin/readiness", label: "Readiness/health", priority: "P1" },
    { file: "09_venues_directory.png", route: "/admin/venues", label: "Venues directory", priority: "P0" },
    { file: "10_venues_workspace.png", route: "/admin/venues/[venue]", label: "Venue workspace", priority: "P1" },
    { file: "11_media.png", route: "/admin/media", label: "Media library", priority: "P1" },
    { file: "12_content_offers.png", route: "/admin/content/offers", label: "Content offers", priority: "P1" },
    { file: "13_content_stories.png", route: "/admin/content/stories", label: "Content stories", priority: "P1" },
    { file: "14_content_reviews.png", route: "/admin/content/reviews", label: "Content reviews", priority: "P0" },
    { file: "15_config.png", route: "/admin/config", label: "Config governance", priority: "P0" },
];

const SYSTEM_PROMPT = `أنت مراجع UX/UI خبير لشاشة إدارية عربية بنظام RTL لمنتج اسمه WAIN. ستتلقى صورة كاملة لصفحة admin (viewport 1728x1117). مهمتك تحليل الصفحة وكتابة ملاحظات بصرية منظمة.

اعتبر السياق:
- المستخدمون: أدمنز فنيون (super_admin, finance_admin, content_admin, support_admin, ops_viewer)
- الاتجاه: operational SaaS dashboard (مش marketing/hero)
- اللغة: عربية، RTL
- الأهداف: density عالية، scan-friendly، قرار سريع، hierarchy واضح

ركّز على:
1. Visual hierarchy (شو يبرز، شو يضيع)
2. Density (مزدحم vs مساحات مهدورة)
3. Color usage (semantic vs decorative، تباين)
4. Typography (sizes, weights, alignment)
5. Iconography (مفقودة/متاحة، أزرار نصية فقط vs icon+label)
6. State clarity (loading/empty/error/unavailable)
7. Action affordances (وضوح الـ CTAs، مسار القرار)
8. Information architecture (تجميع البيانات، sections)

أرجع JSON فقط، بدون markdown wrappers. الـ schema:

{
  "p0_issues": [
    "وصف واضح ومحدد لمشكلة P0 (مشكلة تعطل العمل أو تربك القرار)"
  ],
  "p1_issues": [
    "وصف لمشكلة P1 (مشكلة وضوح أو hierarchy)"
  ],
  "p2_issues": [
    "وصف لمشكلة P2 (تلميع/polish)"
  ],
  "action_items": [
    {
      "phase": "Phase 1|Phase 2|Phase 3|Phase 4|Phase 5|Phase 6|Phase 7|Phase 8|Phase 9|Phase 10",
      "action": "إجراء محدد قابل للتنفيذ"
    }
  ],
  "overall_quality": "جيد|متوسط|يحتاج عمل|ضعيف",
  "screenshot_health": "سليم|partial|broken (وصف مختصر)"
}

كن صريحاً ومحدداً. لا ترجع issues عامة. كل issue يجب أن يصف موقعاً أو عنصراً معيناً في الـ screenshot.
كل القوائم arrays حتى لو فاضية. لا تضف حقول إضافية.`;

async function callGemini(imageBase64, mimeType, route) {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${API_KEY}`;
    const userPrompt = `هذه صورة لصفحة "${route.label}" على المسار ${route.route}. حللها وأعطني findings JSON.`;

    const body = {
        contents: [
            {
                role: "user",
                parts: [
                    { text: SYSTEM_PROMPT },
                    { text: userPrompt },
                    { inline_data: { mime_type: mimeType, data: imageBase64 } },
                ],
            },
        ],
        generationConfig: {
            temperature: 0.3,
            maxOutputTokens: 2048,
            responseMimeType: "application/json",
        },
    };

    const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
    });

    if (!res.ok) {
        const errText = await res.text();
        throw new Error(`HTTP ${res.status}: ${errText.slice(0, 500)}`);
    }

    const data = await res.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
        throw new Error("No text in Gemini response: " + JSON.stringify(data).slice(0, 500));
    }

    let parsed;
    try {
        parsed = JSON.parse(text);
    } catch (e) {
        throw new Error("Gemini returned invalid JSON: " + text.slice(0, 500));
    }
    return parsed;
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function main() {
    console.log("=== Gemini UI Review ===");
    console.log(`Model: ${MODEL}`);
    console.log(`Dry run: ${DRY_RUN}`);
    console.log(`Screenshots dir: ${SHOTS_DIR}`);

    const missingShots = ROUTE_MAP.filter(r => !fs.existsSync(path.join(SHOTS_DIR, r.file)));
    if (missingShots.length > 0) {
        console.error("Missing screenshots:");
        missingShots.forEach(r => console.error(`  ${r.file}`));
        process.exit(1);
    }
    console.log("All 15 screenshots present.");

    if (DRY_RUN) {
        console.log("\nDRY RUN — would call Gemini for:");
        ROUTE_MAP.forEach(r => console.log(`  ${r.file} (${r.route})`));
        return;
    }

    const findings = [];

    for (let i = 0; i < ROUTE_MAP.length; i++) {
        const route = ROUTE_MAP[i];
        const shotPath = path.join(SHOTS_DIR, route.file);
        const buf = fs.readFileSync(shotPath);
        const sizeKB = (buf.length / 1024).toFixed(1);
        console.log(`\n[${i + 1}/15] ${route.file} (${sizeKB} KB) -> ${route.route}`);

        const startMs = Date.now();
        try {
            const result = await callGemini(buf.toString("base64"), "image/png", route);
            const elapsedMs = Date.now() - startMs;
            console.log(`  ok in ${elapsedMs}ms — P0:${result.p0_issues?.length ?? 0} P1:${result.p1_issues?.length ?? 0} P2:${result.p2_issues?.length ?? 0} actions:${result.action_items?.length ?? 0}`);
            findings.push({
                route: route.route,
                label: route.label,
                priority: route.priority,
                file: route.file,
                fileSizeKB: parseFloat(sizeKB),
                elapsedMs,
                ...result,
            });
        } catch (err) {
            console.error(`  FAILED: ${err.message}`);
            findings.push({
                route: route.route,
                label: route.label,
                priority: route.priority,
                file: route.file,
                fileSizeKB: parseFloat(sizeKB),
                error: err.message,
            });
        }

        if (i < ROUTE_MAP.length - 1) {
            await sleep(RPM_DELAY_MS);
        }
    }

    fs.writeFileSync(REPORT_JSON, JSON.stringify(findings, null, 2), "utf8");
    console.log(`\nSaved raw report: ${REPORT_JSON}`);

    renderFindingsMd(findings);
}

function renderFindingsMd(findings) {
    if (!fs.existsSync(FINDINGS_PATH)) {
        console.warn(`Findings doc not found: ${FINDINGS_PATH}`);
        return;
    }

    let md = fs.readFileSync(FINDINGS_PATH, "utf8");

    for (const f of findings) {
        const escapedRoute = f.route.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
        const sectionRegex = new RegExp(
            `(## \`${escapedRoute}\` —[^\n]*\n[\\s\\S]*?)(?=\n---\n)`,
            "g"
        );
        const match = sectionRegex.exec(md);
        if (!match) {
            console.warn(`  Could not locate section for ${f.route} in findings.md`);
            continue;
        }

        const buildList = (items) => {
            if (!items || items.length === 0) {
                return "- [ ] _(Gemini saw no issues at this priority)_\n";
            }
            return items.map(it => `- [ ] ${String(it).replace(/\n/g, " ")}`).join("\n") + "\n";
        };

        const buildActions = (actions) => {
            if (!actions || actions.length === 0) {
                return "- [ ] _(no specific phase actions)_\n";
            }
            return actions.map(a => `- [ ] **${a.phase}:** ${String(a.action).replace(/\n/g, " ")}`).join("\n") + "\n";
        };

        const newBlock = match[1]
            .replace(/(\*\*P0:\*\*\n)[\s\S]*?(?=\n\*\*P1)/, `$1${buildList(f.p0_issues)}\n`)
            .replace(/(\*\*P1:\*\*\n)[\s\S]*?(?=\n\*\*P2)/, `$1${buildList(f.p1_issues)}\n`)
            .replace(/(\*\*P2:\*\*\n)[\s\S]*?(?=\n### Action items)/, `$1${buildList(f.p2_issues)}\n`)
            .replace(/(### Action items[^\n]*\n\n)[\s\S]*$/, `$1${buildActions(f.action_items)}`);

        md = md.replace(match[1], newBlock);
    }

    if (!md.includes("## Gemini Vision review metadata")) {
        const reviewedCount = findings.filter(f => !f.error).length;
        const errorCount = findings.filter(f => f.error).length;
        const ts = new Date().toISOString();
        md += `\n\n## Gemini Vision review metadata\n\n`;
        md += `- **Model:** ${MODEL}\n`;
        md += `- **Reviewed at:** ${ts}\n`;
        md += `- **Successful reviews:** ${reviewedCount}/15\n`;
        md += `- **Errors:** ${errorCount}\n`;
        md += `- **Raw JSON:** ../release/ui_a02_baseline_findings_gemini.json\n`;
        md += `\n_Note: Findings are AI-generated and require human review before acting on them._\n`;
    }

    fs.writeFileSync(FINDINGS_PATH, md, "utf8");
    console.log(`Updated findings doc: ${FINDINGS_PATH}`);
}

main().catch(err => {
    console.error("Fatal:", err);
    process.exit(1);
});
