# Merchant Analytics Release Targets

## SMART targets for the first useful release

- Adoption: raise weekly merchant opens of analytics surfaces after launch versus the current dashboard baseline.
- Usage: measure CTA usage from dashboard analytics into `/merchant/analytics` after rollout.
- Data freshness: keep the percentage of stale analytics sessions below the agreed internal SLA.

## Data quality gates

- `updated_at` must exist on analytics summaries.
- Current-period daily series must be zero-filled instead of returning sparse gaps.
- No divide-by-zero or `NaN` values may surface in client-derived summaries.
- Release validation must include stale-data, no-data, and low-volume insight suppression checks.

## Acceptance for Phase 1 + Phase 2

- Dashboard analytics use only existing aggregated data.
- `Views` remains the primary headline metric.
- `Contact Intent` and `Contact Rate` are visible and correctly derived.
- Insights are capped at 3 and obey guardrails.
