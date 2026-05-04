# Merchant Analytics Privacy And Quality Notes

## Privacy defaults

- Minimize analytics payloads to venue-level fields whenever possible.
- Do not add `user_id` or `device_id` by default.
- `trackVenueEvent` writes venue-level analytics fields only unless an identifier is explicitly required and documented.
- `nav_click` is additive analytics telemetry and does not replace legacy `navigation_clicks` in Phase 3.
- Any future use of identifiers must document:
  - business purpose
  - retention policy
  - access scope
  - rollback strategy

## Freshness and quality

- Freshness target for the merchant experience remains `hourly aggregation + explicit refresh`.
- The dashboard must always show freshness state through `updated_at`.
- `updated_at` must be written consistently on:
  - `venue_analytics/{venueId}`
  - `venue_analytics_daily/{venueId}/days/{dateKey}`
  - `venue_offer_analytics/{venueId}/offers/{offerId}`
- Missing or stale data must degrade gracefully:
  - `data_stale` insight
  - `no_recent_data` insight
  - readable fallback cards instead of broken charts
- Phase 4 per-offer docs are zeroed when stale instead of being deleted, so read models stay stable for later UI consumers.

## Compatibility

- All analytics schema changes remain additive.
- Legacy fields remain readable for at least one transition release after expansion.
- Phase 3 keeps `navigation_clicks` for compatibility while merchant analytics expands through `venue_events`.
- Phase 4 still derives `navs_*` from `navigation_clicks` only.
- Any future migration from `navigation_clicks` to `nav_click` as the nav source must be handled deliberately in Phase 5 with awareness of possible time-series discontinuity.
