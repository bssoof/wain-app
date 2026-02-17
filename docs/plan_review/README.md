# Wain Plan Review Framework

This framework standardizes how we evaluate and improve Wain plans as testable growth hypotheses.
It is optimized for merchant-led usage growth and technical/structural plans.

## North Star And Defaults

- 90-day goal: usage growth.
- Primary segment: merchants.
- Analytics baseline: basic instrumentation is available.
- Delivery capacity: 4+ team members.
- Default execution model: 2-4 week experiments, staged rollout, data-based Go/No-go.

## Interface Contracts

### PlanInputV1

Every plan must provide these fields:

1. `plan_name`
2. `problem_statement`
3. `target_segment`
4. `hypothesis`
5. `primary_metric`
6. `expected_delta`
7. `scope_in`
8. `scope_out`
9. `dependencies`
10. `risks_known`
11. `timeline` (in weeks)
12. `team_allocation`

Template: `docs/plan_review/templates/plan_input_v1.template.json`

### ReviewOutputV1

Every review must return these fields:

1. `verdict` (`Go`, `Go with changes`, `No-go`)
2. `impact_score` (1-10)
3. `effort_score` (1-10)
4. `risk_score` (1-10)
5. `key_failure_modes`
6. `improved_plan_v2`
7. `measurement_plan`
8. `rollout_plan`
9. `kill_criteria`
10. `next_14_days_execution`

Template: `docs/plan_review/templates/review_output_v1.template.json`

## Review Workflow

1. Assess plan on 5 axes: value, speed, risk, measurability, growth alignment.
2. Detect critical blockers immediately (anything that prevents execution or measurement).
3. Rebuild the plan into `improved_plan_v2` with higher impact per unit effort.
4. Convert the plan into a 2-4 week experiment with pass/fail thresholds.
5. Prioritize work as `Must`, `Should`, `Later`.
6. Close the loop with a post-execution review and feed into the next plan.

## Scoring Rubric

- `impact_score`: expected effect on the primary growth metric.
- `effort_score`: delivery cost considering scope, dependencies, and timeline.
- `risk_score`: delivery and business risk including unknowns and instrumentation gaps.

All scores use integer values from 1 to 10.

## Decision Rules

- `Go`: no critical blocker and high impact with controlled risk.
- `Go with changes`: strong potential, but requires specific adjustments before execution.
- `No-go`: missing core assumptions, poor growth linkage, or unacceptable risk profile.

## Required Scenarios

1. Technical plan without growth effect: require metric linkage or reject.
2. Large high-risk plan: split into a small pilot for a narrow merchant slice.
3. Strong plan with weak measurement: add instrumentation as a launch gate.
4. Plan with many dependencies: reorder to remove bottlenecks.
5. Plan with delayed impact: add quick wins in first 14 days.

## Tooling

Generate a review scaffold from a plan input file:

```bash
node scripts/plan_review_scaffold.js --input docs/plan_review/templates/plan_input_v1.template.json --output docs/plan_review/reviews/example_review.md
```

Optional JSON output:

```bash
node scripts/plan_review_scaffold.js --input <plan.json> --format json
```

`docs/plan_review/reviews/` is intended for saved review artifacts.
