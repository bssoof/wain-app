# Merchant Analytics Tracking Plan

## Current production events

| Event | Description | Source of truth | Current owner |
| --- | --- | --- | --- |
| `view` | Venue view/open | `venue_events` aggregation pipeline | Discovery / Venue |
| `call` | Call tap from venue details | `venue_events` aggregation pipeline | Venue |
| `story_view` | Story view associated with venue content | `venue_events` aggregation pipeline | Stories |
| `navigation_clicks` | Legacy navigation tap collection | Read-side compatibility source | Venue |

## Planned additive events

| Event | Launch phase | Source of truth | Notes |
| --- | --- | --- | --- |
| `nav_click` | Phase 3 | `venue_events` | Dual-write with `navigation_clicks` for one release |
| `offer_detail_view` | Phase 3 | `venue_events` | Client-side event from offer details |
| `offer_claim_click` | Phase 3 | `venue_events` | Client-side CTA tap |
| `offer_claim_created` | Phase 3 | Server-side callable | Exactly-once, only when a new claim is created in `createClaimToken` |
| `offer_redeemed` | Phase 3 | Server-side callable | Exactly-once in `redeemToken` |

## Payload defaults

- Required: `venue_id`, `event_type`, `source`, `created_at`
- Optional by explicit need only: `offer_id`, `story_id`, `user_id`, `device_id`
- `trackVenueEvent` does not write `user_id` by default
- `device_id` is opt-in only when the caller explicitly sends it

## Anti-duplication policy

- Each additive event must define a single source of truth before release.
- `nav_click` keeps dual-write for one stable release only.
- Server-side events win over client-side reconstructions for claim and redemption states.
- `offer_claim_created` must not be emitted when `createClaimToken` resumes an existing pending claim.

## Phase 4 read models

- `venue_analytics/{venueId}` expands additively with:
  - `offer_detail_views_*`
  - `claim_clicks_*`
  - `claims_created_*`
  - `redemptions_*`
  - derived 7d rates such as `contact_rate_7d` and `claim_to_redemption_rate_7d`
- `venue_analytics_daily/{venueId}/days/{dateKey}` expands additively with:
  - `offer_detail_views`
  - `claim_clicks`
  - `claims_created`
  - `redemptions`
- `venue_offer_analytics/{venueId}/offers/{offerId}` becomes the per-offer summary source for later `Top offers` and funnel UI.
- `nav_click` is stored in `venue_events` but does not feed `navs_*` yet; legacy `navigation_clicks` remains the nav source through Phase 4.
