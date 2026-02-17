#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const REQUIRED_FIELDS = [
  "plan_name",
  "problem_statement",
  "target_segment",
  "hypothesis",
  "primary_metric",
  "expected_delta",
  "scope_in",
  "scope_out",
  "dependencies",
  "risks_known",
  "timeline",
  "team_allocation"
];

function parseArgs(argv) {
  const args = { format: "markdown" };

  for (let i = 2; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--input") {
      args.input = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--output") {
      args.output = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--format") {
      args.format = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--help" || arg === "-h") {
      args.help = true;
      continue;
    }

    throw new Error(`Unknown argument: ${arg}`);
  }

  return args;
}

function usage() {
  return [
    "Usage:",
    "  node scripts/plan_review_scaffold.js --input <plan.json> [--output <file>] [--format markdown|json]",
    "",
    "Examples:",
    "  node scripts/plan_review_scaffold.js --input docs/plan_review/templates/plan_input_v1.template.json",
    "  node scripts/plan_review_scaffold.js --input plan.json --output docs/plan_review/reviews/my_review.md",
    "  node scripts/plan_review_scaffold.js --input plan.json --format json"
  ].join("\n");
}

function readJson(filePath) {
  const content = fs.readFileSync(filePath, "utf8").replace(/^\\uFEFF/, "");
  try {
    return JSON.parse(content);
  } catch (error) {
    throw new Error(`Invalid JSON in ${filePath}: ${error.message}`);
  }
}

function hasValue(value) {
  if (value === null || value === undefined) {
    return false;
  }
  if (typeof value === "string") {
    return value.trim().length > 0;
  }
  if (Array.isArray(value)) {
    return value.length > 0;
  }
  if (typeof value === "object") {
    return Object.keys(value).length > 0;
  }
  return true;
}

function validatePlan(plan) {
  const errors = [];

  for (const field of REQUIRED_FIELDS) {
    if (!hasValue(plan[field])) {
      errors.push(`Missing required field: ${field}`);
    }
  }

  const listFields = ["scope_in", "scope_out", "dependencies", "risks_known"];
  for (const field of listFields) {
    if (plan[field] && !Array.isArray(plan[field])) {
      errors.push(`Field must be an array: ${field}`);
    }
  }

  if (plan.team_allocation && typeof plan.team_allocation !== "object") {
    errors.push("Field must be an object: team_allocation");
  }

  const weeks = getTimelineWeeks(plan.timeline);
  if (weeks === null) {
    errors.push("timeline must provide duration in weeks (number, string with number, or object with duration_weeks/weeks)");
  }

  return errors;
}

function getTimelineWeeks(timeline) {
  if (timeline === null || timeline === undefined) {
    return null;
  }

  if (typeof timeline === "number" && Number.isFinite(timeline)) {
    return timeline;
  }

  if (typeof timeline === "string") {
    const match = timeline.match(/\d+(\.\d+)?/);
    if (!match) {
      return null;
    }
    return Number(match[0]);
  }

  if (typeof timeline === "object") {
    const candidate = timeline.duration_weeks ?? timeline.weeks;
    if (typeof candidate === "number" && Number.isFinite(candidate)) {
      return candidate;
    }
    if (typeof candidate === "string") {
      const match = candidate.match(/\d+(\.\d+)?/);
      if (!match) {
        return null;
      }
      return Number(match[0]);
    }
  }

  return null;
}

function parseDeltaPercent(expectedDelta) {
  if (!expectedDelta) {
    return null;
  }
  const match = String(expectedDelta).match(/-?\d+(\.\d+)?/);
  if (!match) {
    return null;
  }
  return Number(match[0]);
}

function teamSize(teamAllocation) {
  if (!teamAllocation || typeof teamAllocation !== "object") {
    return 0;
  }
  let total = 0;
  for (const value of Object.values(teamAllocation)) {
    if (typeof value === "number" && Number.isFinite(value)) {
      total += value;
    }
  }
  return total;
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

function scoreImpact(plan) {
  const delta = parseDeltaPercent(plan.expected_delta);
  let score = 6;

  if (delta !== null) {
    if (delta >= 40) {
      score = 9;
    } else if (delta >= 25) {
      score = 8;
    } else if (delta >= 15) {
      score = 7;
    } else if (delta >= 5) {
      score = 6;
    } else {
      score = 5;
    }
  }

  const target = String(plan.target_segment || "").toLowerCase();
  if (target.includes("merchant") || target.includes("store") || target.includes("cafe")) {
    score += 1;
  }

  if (!hasValue(plan.primary_metric)) {
    score -= 2;
  }

  return clamp(Math.round(score), 1, 10);
}

function scoreEffort(plan) {
  const scopeCount = Array.isArray(plan.scope_in) ? plan.scope_in.length : 0;
  const dependencyCount = Array.isArray(plan.dependencies) ? plan.dependencies.length : 0;
  const weeks = getTimelineWeeks(plan.timeline);
  const size = teamSize(plan.team_allocation);

  let score = 3;
  score += Math.ceil(scopeCount / 2);
  score += Math.ceil(dependencyCount / 3);

  if (weeks !== null) {
    if (weeks <= 2) {
      score -= 1;
    } else if (weeks >= 6) {
      score += 2;
    } else if (weeks >= 4) {
      score += 1;
    }
  }

  if (size >= 5) {
    score -= 1;
  }

  return clamp(Math.round(score), 1, 10);
}

function scoreRisk(plan) {
  const dependencyCount = Array.isArray(plan.dependencies) ? plan.dependencies.length : 0;
  const knownRiskCount = Array.isArray(plan.risks_known) ? plan.risks_known.length : 0;
  const scopeCount = Array.isArray(plan.scope_in) ? plan.scope_in.length : 0;
  const weeks = getTimelineWeeks(plan.timeline);

  let score = 3;
  score += Math.ceil(dependencyCount / 3);
  score += Math.ceil(knownRiskCount / 2);

  if (weeks !== null && weeks <= 2 && scopeCount >= 5) {
    score += 2;
  }

  if (!hasValue(plan.primary_metric) || !hasValue(plan.expected_delta)) {
    score += 2;
  }

  return clamp(Math.round(score), 1, 10);
}

function getCriticalGaps(plan) {
  const gaps = [];

  if (!hasValue(plan.primary_metric) || !hasValue(plan.expected_delta)) {
    gaps.push("No measurable success condition (primary_metric + expected_delta) is fully defined.");
  }
  if (!hasValue(plan.target_segment)) {
    gaps.push("Target segment is missing.");
  }
  if (!hasValue(plan.hypothesis)) {
    gaps.push("Hypothesis is missing.");
  }
  if (!Array.isArray(plan.scope_in) || plan.scope_in.length === 0) {
    gaps.push("scope_in is empty.");
  }
  if (getTimelineWeeks(plan.timeline) === null) {
    gaps.push("Timeline does not include usable week duration.");
  }

  return gaps;
}

function getWarnings(plan) {
  const warnings = [];
  const weeks = getTimelineWeeks(plan.timeline);
  const scopeCount = Array.isArray(plan.scope_in) ? plan.scope_in.length : 0;
  const dependencyCount = Array.isArray(plan.dependencies) ? plan.dependencies.length : 0;
  const scopeOutCount = Array.isArray(plan.scope_out) ? plan.scope_out.length : 0;

  if (weeks !== null && (weeks < 2 || weeks > 4)) {
    warnings.push("Timeline is outside the default 2-4 week experiment window.");
  }
  if (scopeCount > 6) {
    warnings.push("scope_in is large; likely to reduce speed and focus.");
  }
  if (dependencyCount > 6) {
    warnings.push("High dependency count may create delivery bottlenecks.");
  }
  if (scopeOutCount === 0) {
    warnings.push("scope_out is empty; boundaries may be unclear.");
  }

  return warnings;
}

function chooseVerdict(impactScore, riskScore, criticalGaps, warnings) {
  if (criticalGaps.length > 0) {
    return "No-go";
  }
  if (impactScore >= 7 && riskScore <= 6 && warnings.length === 0) {
    return "Go";
  }
  if (impactScore >= 6) {
    return "Go with changes";
  }
  return "No-go";
}

function toArray(value) {
  return Array.isArray(value) ? value : [];
}

function safeSlug(text) {
  return String(text || "plan")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "") || "plan";
}

function buildMustShouldLater(plan) {
  const scopeIn = toArray(plan.scope_in);
  const scopeOut = toArray(plan.scope_out);

  return {
    must: scopeIn.slice(0, 3),
    should: scopeIn.slice(3),
    later: scopeOut
  };
}

function buildFailureModes(plan, warnings) {
  const failures = [];

  failures.push("Primary metric does not move despite plan delivery.");

  if (toArray(plan.dependencies).length > 0) {
    failures.push("Dependency slippage delays pilot launch.");
  }
  if (toArray(plan.risks_known).length > 0) {
    failures.push("Known risks materialize without mitigation in place.");
  }
  if (warnings.length > 0) {
    failures.push("Scope/timeline mismatch reduces execution quality.");
  }

  return failures;
}

function buildMeasurementPlan(plan, weeks) {
  const slug = safeSlug(plan.plan_name);
  const primaryMetric = plan.primary_metric;
  const expectedDelta = plan.expected_delta;
  const duration = weeks || 4;
  const expectedDeltaText = String(expectedDelta);
  const deltaThreshold = expectedDeltaText.toLowerCase().includes("week")
    ? `${primaryMetric} improves by ${expectedDeltaText}`
    : `${primaryMetric} improves by ${expectedDeltaText} within ${duration} weeks`;

  return {
    primary_metric: primaryMetric,
    expected_delta: expectedDelta,
    events: [
      `${slug}_pilot_started`,
      `${slug}_activation_step_completed`,
      `${slug}_metric_checkpoint_recorded`,
      `${slug}_pilot_completed`
    ],
    funnel: [
      "target_segment_reached",
      "pilot_flow_started",
      "pilot_flow_completed",
      primaryMetric
    ],
    success_thresholds: [
      deltaThreshold,
      "At least 80% of Must scope is delivered by day 14",
      "No P1/P2 incidents introduced by the rollout"
    ]
  };
}

function buildRolloutPlan(plan, weeks) {
  const duration = weeks || 4;
  const pilotWeeks = duration >= 4 ? 2 : Math.max(1, Math.round(duration / 2));
  const scaleWeeks = Math.max(1, duration - pilotWeeks);

  return {
    pilot: {
      duration_weeks: pilotWeeks,
      segment: plan.target_segment,
      gates: [
        "Instrumentation validated",
        "Primary metric trend is positive",
        "No blocking production incidents"
      ]
    },
    scale: {
      duration_weeks: scaleWeeks,
      condition: "Pilot meets success_thresholds"
    }
  };
}

function buildKillCriteria(plan) {
  return [
    `${plan.primary_metric} improves by less than 5% by pilot end`,
    "Critical instrumentation is missing by day 5",
    "More than two severe incidents occur during pilot"
  ];
}

function buildNext14Days(plan) {
  const must = toArray(plan.scope_in).slice(0, 3);
  const steps = [
    "Lock target segment and success thresholds",
    "Finalize Must scope and freeze non-essential items",
    "Implement and validate instrumentation events",
    "Launch pilot with daily metric review",
    "Run day-14 review and record Go/No-go decision"
  ];

  if (must.length > 0) {
    return [
      `Deliver Must items: ${must.join(", ")}`,
      ...steps.slice(1)
    ];
  }

  return steps;
}

function buildImprovedPlan(plan, warnings) {
  const buckets = buildMustShouldLater(plan);
  const constraints = [
    "Keep pilot duration in 2-4 week window whenever possible",
    "Ship instrumentation before broad rollout",
    "Tie all scope directly to primary metric movement"
  ];

  return {
    focus_statement: `Run a narrow pilot for ${plan.target_segment} and optimize for ${plan.primary_metric}.`,
    must: buckets.must,
    should: buckets.should,
    later: buckets.later,
    constraints,
    warnings_to_address: warnings
  };
}

function buildReview(plan) {
  const weeks = getTimelineWeeks(plan.timeline);
  const impactScore = scoreImpact(plan);
  const effortScore = scoreEffort(plan);
  const riskScore = scoreRisk(plan);
  const criticalGaps = getCriticalGaps(plan);
  const warnings = getWarnings(plan);

  const verdict = chooseVerdict(impactScore, riskScore, criticalGaps, warnings);

  const review = {
    verdict,
    impact_score: impactScore,
    effort_score: effortScore,
    risk_score: riskScore,
    key_failure_modes: buildFailureModes(plan, warnings),
    improved_plan_v2: buildImprovedPlan(plan, warnings),
    measurement_plan: buildMeasurementPlan(plan, weeks),
    rollout_plan: buildRolloutPlan(plan, weeks),
    kill_criteria: buildKillCriteria(plan),
    next_14_days_execution: buildNext14Days(plan)
  };

  return {
    review,
    diagnostics: {
      critical_gaps: criticalGaps,
      warnings
    }
  };
}

function toMarkdown(plan, bundle) {
  const { review, diagnostics } = bundle;
  const weeks = getTimelineWeeks(plan.timeline);

  const lines = [];
  lines.push(`# Review: ${plan.plan_name}`);
  lines.push("");
  lines.push("## Plan Snapshot");
  lines.push(`- Problem: ${plan.problem_statement}`);
  lines.push(`- Target segment: ${plan.target_segment}`);
  lines.push(`- Hypothesis: ${plan.hypothesis}`);
  lines.push(`- Primary metric: ${plan.primary_metric}`);
  lines.push(`- Expected delta: ${plan.expected_delta}`);
  lines.push(`- Timeline (weeks): ${weeks !== null ? weeks : "unknown"}`);
  lines.push("");

  lines.push("## Diagnostics");
  if (diagnostics.critical_gaps.length === 0) {
    lines.push("- Critical gaps: none");
  } else {
    for (const gap of diagnostics.critical_gaps) {
      lines.push(`- Critical gap: ${gap}`);
    }
  }

  if (diagnostics.warnings.length === 0) {
    lines.push("- Warnings: none");
  } else {
    for (const warning of diagnostics.warnings) {
      lines.push(`- Warning: ${warning}`);
    }
  }

  lines.push("");
  lines.push("## ReviewOutputV1");
  lines.push("```json");
  lines.push(JSON.stringify(review, null, 2));
  lines.push("```");
  lines.push("");
  lines.push("## Must / Should / Later");
  for (const item of review.improved_plan_v2.must) {
    lines.push(`- Must: ${item}`);
  }
  for (const item of review.improved_plan_v2.should) {
    lines.push(`- Should: ${item}`);
  }
  for (const item of review.improved_plan_v2.later) {
    lines.push(`- Later: ${item}`);
  }

  return lines.join("\n");
}

function main() {
  let args;

  try {
    args = parseArgs(process.argv);
  } catch (error) {
    console.error(error.message);
    console.error("");
    console.error(usage());
    process.exit(1);
  }

  if (args.help) {
    console.log(usage());
    process.exit(0);
  }

  if (!args.input) {
    console.error("Missing --input argument.");
    console.error("");
    console.error(usage());
    process.exit(1);
  }

  if (!["markdown", "json"].includes(args.format)) {
    console.error("--format must be either 'markdown' or 'json'.");
    process.exit(1);
  }

  const inputPath = path.resolve(args.input);
  if (!fs.existsSync(inputPath)) {
    console.error(`Input file not found: ${inputPath}`);
    process.exit(1);
  }

  const plan = readJson(inputPath);
  const errors = validatePlan(plan);

  if (errors.length > 0) {
    console.error("PlanInputV1 validation failed:");
    for (const error of errors) {
      console.error(`- ${error}`);
    }
    process.exit(1);
  }

  const bundle = buildReview(plan);
  const outputContent = args.format === "json"
    ? JSON.stringify(bundle.review, null, 2)
    : toMarkdown(plan, bundle);

  if (args.output) {
    const outputPath = path.resolve(args.output);
    fs.mkdirSync(path.dirname(outputPath), { recursive: true });
    fs.writeFileSync(outputPath, `${outputContent}\n`, "utf8");
    console.log(`Review scaffold saved to: ${outputPath}`);
    return;
  }

  console.log(outputContent);
}

main();
