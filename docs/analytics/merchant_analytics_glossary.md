# Merchant Analytics Glossary

## Current release definitions

| Metric | Definition | Notes |
| --- | --- | --- |
| Views | Current venue view events recorded for the merchant venue | This release does not claim unique reach |
| Calls | Phone call tap events from the venue surface | Intent signal, not confirmed connected calls |
| Navigation taps | Navigation tap events from the venue surface | Intent signal, not confirmed arrivals |
| Story views | Story view events tied to the merchant venue | Used as a supporting attention metric |
| Contact Intent | `calls + navigation taps` | Primary intent metric in Phase 1/2 |
| Contact Rate | `contactIntent / views` | Guarded by minimum sample size in insights |
| Stale analytics | `updated_at > 24h` | Dashboard shows freshness chip and stale insight |
| No recent data | No activity in the selected current period | Suppresses most derived insights |

## Guardrails

- `Views` stays the primary label in this release. We do not call it `Reach`.
- `Views -> Calls/Nav taps` is not presented as a funnel.
- Rate-based insights require minimum volume before surfacing.
