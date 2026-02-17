# Review: Merchant onboarding acceleration

## Plan Snapshot
- Problem: Merchant activation is slow and limits supply growth.
- Target segment: Independent cafes in one city with 1-3 branches
- Hypothesis: If we launch guided self-serve onboarding, weekly activated merchants will increase.
- Primary metric: weekly_activated_merchants
- Expected delta: +30% within 4 weeks
- Timeline (weeks): 4

## Diagnostics
- Critical gaps: none
- Warnings: none

## ReviewOutputV1
```json
{
  "verdict": "Go",
  "impact_score": 9,
  "effort_score": 6,
  "risk_score": 5,
  "key_failure_modes": [
    "Primary metric does not move despite plan delivery.",
    "Dependency slippage delays pilot launch.",
    "Known risks materialize without mitigation in place."
  ],
  "improved_plan_v2": {
    "focus_statement": "Run a narrow pilot for Independent cafes in one city with 1-3 branches and optimize for weekly_activated_merchants.",
    "must": [
      "Guided onboarding flow",
      "Merchant profile completeness check",
      "Activation status dashboard"
    ],
    "should": [],
    "later": [
      "Full billing rework",
      "New loyalty program"
    ],
    "constraints": [
      "Keep pilot duration in 2-4 week window whenever possible",
      "Ship instrumentation before broad rollout",
      "Tie all scope directly to primary metric movement"
    ],
    "warnings_to_address": []
  },
  "measurement_plan": {
    "primary_metric": "weekly_activated_merchants",
    "expected_delta": "+30% within 4 weeks",
    "events": [
      "merchant_onboarding_acceleration_pilot_started",
      "merchant_onboarding_acceleration_activation_step_completed",
      "merchant_onboarding_acceleration_metric_checkpoint_recorded",
      "merchant_onboarding_acceleration_pilot_completed"
    ],
    "funnel": [
      "target_segment_reached",
      "pilot_flow_started",
      "pilot_flow_completed",
      "weekly_activated_merchants"
    ],
    "success_thresholds": [
      "weekly_activated_merchants improves by +30% within 4 weeks",
      "At least 80% of Must scope is delivered by day 14",
      "No P1/P2 incidents introduced by the rollout"
    ]
  },
  "rollout_plan": {
    "pilot": {
      "duration_weeks": 2,
      "segment": "Independent cafes in one city with 1-3 branches",
      "gates": [
        "Instrumentation validated",
        "Primary metric trend is positive",
        "No blocking production incidents"
      ]
    },
    "scale": {
      "duration_weeks": 2,
      "condition": "Pilot meets success_thresholds"
    }
  },
  "kill_criteria": [
    "weekly_activated_merchants improves by less than 5% by pilot end",
    "Critical instrumentation is missing by day 5",
    "More than two severe incidents occur during pilot"
  ],
  "next_14_days_execution": [
    "Deliver Must items: Guided onboarding flow, Merchant profile completeness check, Activation status dashboard",
    "Finalize Must scope and freeze non-essential items",
    "Implement and validate instrumentation events",
    "Launch pilot with daily metric review",
    "Run day-14 review and record Go/No-go decision"
  ]
}
```

## Must / Should / Later
- Must: Guided onboarding flow
- Must: Merchant profile completeness check
- Must: Activation status dashboard
- Later: Full billing rework
- Later: New loyalty program
