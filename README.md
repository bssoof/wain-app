# Wain App

Flutter application for place discovery, offers, and merchant participation.

## Getting Started

```bash
flutter pub get
flutter run
```

## Plan Review Framework (Implemented)

The repository includes a standard framework to review and improve growth-oriented plans.

- Framework guide: `docs/plan_review/README.md`
- Plan input template: `docs/plan_review/templates/plan_input_v1.template.json`
- Review output template: `docs/plan_review/templates/review_output_v1.template.json`
- Review generator script: `scripts/plan_review_scaffold.js`

### Generate A Review Scaffold

```bash
node scripts/plan_review_scaffold.js --input docs/plan_review/templates/plan_input_v1.template.json --output docs/plan_review/reviews/example_review.md
```

### JSON Output (Optional)

```bash
node scripts/plan_review_scaffold.js --input <plan.json> --format json
```

## Release Checklists

- Merchant dashboard delta release checklist:
  - `docs/release/merchant_dashboard_release_checklist.md`
- Merchant wallet execution plan:
  - `docs/release/merchant_wallet_execution_plan.md`
- Admin web console execution plan:
  - `docs/release/admin_web_console_execution_plan.md`
- Admin web console Phase 0 governance lock:
  - `docs/release/admin_web_console_phase0_governance_lock.md`
- Admin web console Phase 0 acceptance record:
  - `docs/release/admin_web_console_phase0_acceptance_record.md`
- Admin web console Phase 1 acceptance record:
  - `docs/release/admin_web_console_phase1_acceptance_record.md`
- Admin web console Phase 2 acceptance record:
  - `docs/release/admin_web_console_phase2_acceptance_record.md`
- Admin web console Phase 3 acceptance record:
  - `docs/release/admin_web_console_phase3_acceptance_record.md`
- Admin web console Phase 4 acceptance record:
  - `docs/release/admin_web_console_phase4_acceptance_record.md`
- Admin web console Phase 5 acceptance record:
  - `docs/release/admin_web_console_phase5_acceptance_record.md`
- Admin web console Phase 6 acceptance record:
  - `docs/release/admin_web_console_phase6_acceptance_record.md`
- Admin web console Phase 7 acceptance record:
  - `docs/release/admin_web_console_phase7_acceptance_record.md`
- Admin web console release checklist:
  - `docs/release/admin_web_console_release_checklist.md`
- Admin web console release runbook:
  - `docs/release/admin_web_console_release_runbook.md`
- Admin web console incident drill review:
  - `docs/release/admin_web_console_incident_drill_review.md`
- Admin web console staging evidence:
  - `docs/release/admin_web_console_staging_evidence_log.md`
  - `docs/release/admin_web_console_staging_evidence_log.json`
- Merchant wallet release runbook:
  - `docs/release/merchant_wallet_release_runbook.md`
- Merchant wallet staging checklist:
  - `docs/release/merchant_wallet_staging_checklist.md`
- Merchant wallet soft launch plan:
  - `docs/release/merchant_wallet_soft_launch_plan.md`
- Merchant wallet monitoring plan:
  - `docs/release/merchant_wallet_monitoring_plan.md`
- Merchant wallet staging evidence (Phase 16):
  - `docs/release/merchant_wallet_staging_evidence_log.md`
  - `docs/release/merchant_wallet_staging_evidence_log.json`
- Merchant wallet go/no-go checklist:
  - `docs/release/merchant_wallet_go_no_go_checklist.md`
- Merchant wallet maintenance backlog:
  - `docs/release/merchant_wallet_maintenance_backlog.md`
- Admin web console progress tracker:
  - `docs/release/admin_web_console_progress_tracker.md`

## Admin Web Notes

- Venue Directory now uses the governed admin callable `listVenuesForAdmin` for backend-linked venue reads, instead of reusing app geo-search bounds. This keeps admin venue visibility tied to the current backend state even when `lat/lng` is not populated yet.
- App venue discovery still uses `searchVenuesInBounds`; the admin venue directory is intentionally a separate read path from the mobile geosearch path.
- Venue Workspace core tabs prefer the server-backed admin callable `getAdminVenueWorkspaceReadBundle` when callable transport is configured, and label fallback sources explicitly when fixture fallback is used.
- Media Center now exists as a governed admin route at `/admin/media`, uses an Arabic RTL operator UI, and prefers the server-backed admin callable `getAdminMediaInventoryReadBundle` for proofs, venue photos, offer images, and story images.
- Admin web console surfaces now default to Arabic RTL presentation across navigation, public admin entry pages, dashboard, finance, venue, content, reviews, config, and media flows.
- Arabic localization covers the admin chrome, states, source/freshness notes, and operator error messaging; entity data such as merchant names, venue names, IDs, and record payload text still render as provided by the underlying source.
- Media Center now shows governed media action affordances only for `content_admin` and `super_admin`; read-only roles keep the baseline inventory view.
- When media callable transport env is configured, Media Center actions invoke governed backend callables (`mediaSoftDeleteAsset`, `mediaQuarantineAsset`, `mediaReferenceCheckAsset`, `mediaPurgeAsset`); otherwise the UI surfaces explicit `unavailable` state instead of fake success.
- `purge` stays blocked when `media_reference_index` health is not `healthy`, and the blocked reason remains explicit in the operator UI.
- Reviews Moderation now exists at `/admin/content/reviews`, prefers the governed callable `listVenueReviewsForAdmin`, and falls back to an explicitly labeled fixture feed when content callable transport is not configured.
- Review moderation actions (`review_publish`, `review_hide`, `review_escalate`) are visible only to `content_admin` and `super_admin`, and conflict/unavailable transport states remain explicit in the operator UI.
- Offers Management now exists at `/admin/content/offers`, prefers the governed callable `listOffersForAdmin`, and only falls back to explicitly labeled fixture data on retryable transport failures. Unauthorized or forbidden read failures stay explicit and do not downgrade to fixture success.
- Stories Management now exists at `/admin/content/stories`, prefers the governed callable `listStoriesForAdmin`, and mirrors the same explicit fallback policy and protected-field safety used by offers moderation.
- Offer/story moderation actions (`offer_*`, `story_*`) route through `contentModerateOffer` and `contentModerateStory` when content callable transport env is configured; otherwise the operator UI surfaces explicit `unavailable` state instead of fake success.
- `cd wain_app/functions && npm run admin-web:staging-rehearsal` now provides the Phase 7 service-account-backed staging callable rehearsal for config/media/content/reviews; it validates live Firestore callable logic but does not replace browser HTTP transport smoke with auth/app-check envs.

## Merchant Wallet Notes

- Merchant wallet documents and ledger entries are server-only; client writes are blocked by Firestore rules.
- Primary daily review path is now the in-app admin queue: `AppRoutes.adminTopUps` (`/admin/topups`).
- Admin authorization policy is **claims + document fallback** (single documented policy used across router/functions/rules):
  - Firebase custom claims with `admin: true` or `role: "admin"`
  - Firestore document `admins/{uid}` with `active != false`
- `promoteStory` now charges `merchant_wallets/{venueId}` inside the same Firestore transaction that updates the story.
- `pinOffer` now charges `merchant_wallets/{venueId}` inside the same Firestore transaction that updates the offer featured state in `MerchantOffers`.
- Story promotion pricing is loaded from `wallet_feature_pricing/default`, and promotion retries are deduplicated with a client-supplied `requestId`.
- Offer pin pricing is also loaded from `wallet_feature_pricing/default`, uses the same `requestId` idempotency pattern, and clamps `featured_until` to `offer.end_at`.
- Receipt proof paths are stored in `merchant_topup_requests.proof_image_url` as a Storage path (preferred) and legacy download URLs remain readable for backward compatibility.
- `createMerchantTopUpRequest` accepts a proof path only when the referenced Storage object already exists under the merchant's own `venues/{venueId}/wallet_topups/...` path.
- Wallet security coverage lives in:
  - `functions/test/rules/firestoreSecurityRules.test.js`
  - `functions/test/emulator/securityCallableFlows.test.js`
  - `functions/test/emulator/securitySurfaceFlows.test.js`
  - `functions/test/rules/storageSecurityRules.test.js`

### Receipt Lifecycle Policy

- Retention window: `180` days from upload (`proof_uploaded_at` to `proof_retention_until`).
- Rejected requests: receipt retained until retention window expires to support disputes and re-audit.
- Credited requests: receipt retained until retention window expires for audit traceability.
- Cleanup policy: hourly backend maintenance targets requests where `proof_retention_until <= now`.
  - Internal storage proofs (`venues/{venueId}/wallet_topups/...`) are deleted from Storage and then nulled in Firestore.
  - Legacy/external URLs are cleared from Firestore without Storage deletion attempts.
  - Cleanup writes `proof_deleted_at` and `proof_storage_deleted` for auditability and idempotent reruns.

### Lifecycle Maintenance (Phase 7)

- Scheduled function: `walletLifecycleMaintenance` (every 60 minutes).
- Responsibilities:
  - Expire featured offers: `offers` where `is_featured == true` and `featured_until <= now` -> set `is_featured = false`.
  - Expire promoted stories: `stories` where `is_promoted == true` and `promoted_until <= now` -> set `is_promoted = false`.
  - Cleanup retained top-up proofs using `proof_retention_until <= now` policy above.
- Safety and operations:
  - Bounded scans with per-type limits prevent runaway batch work.
  - Logic is fully idempotent: reruns do not re-charge, re-delete, or break on already-processed rows/files.
  - Derived flags are maintained server-side without dependence on client app opens.

### Wallet Audit Events

The following normalized events are emitted for monitoring/analytics:

- `topup_request_created`
- `topup_request_approved`
- `topup_request_rejected`
- `story_promotion_debited`
- `offer_pin_debited`
- `insufficient_wallet_balance`
- `offer_pin_expired`
- `story_promotion_expired`
- `topup_proof_deleted`

### Phase 8: Wallet Reporting + Audit Read Model

- Merchant read model: `merchant_wallet_reports/{venueId}`
  - `total_credited`
  - `topup_total_credited` (top-up credits only; excludes reversal credits)
  - `total_debited`
  - `last_30d_debited`
  - `debit_by_feature` (e.g. `story_promotion`, `offer_pin`)
  - `most_used_debit_feature`
  - `last_top_up_amount`
- Admin audit read model: `wallet_audit_events/{eventId}`
  - Links top-up lifecycle and ledger linkage (`request_id`, `linked_entry_id`, `reviewed_by_uid`)
  - Includes proof lifecycle fields for traceability (`proof_image_url`, `proof_retention_until`, `proof_deleted_at`, `proof_storage_deleted`)
- Aggregation strategy:
  - Rebuild per venue on wallet entry writes
  - Daily scheduled rebuild for drift resistance
  - Report model is read-only from clients (server-maintained)

### Phase 9: Refunds / Reversals (Admin Recovery)

- New admin-only callable: `reverseWalletEntry`
  - Input: `entryId`, `venueId`, `reason`, optional `adminNote`
  - Scope: only debit entries with feature keys `story_promotion` or `offer_pin`
- Financial behavior:
  - Original debit amount/balance fields remain immutable
  - A compensating credit entry is appended (`reversal_{entryId}`)
  - Wallet balance is updated in the same transaction
  - Feature state is reverted in the same transaction:
    - `story_promotion` -> `stories/{storyId}.is_promoted = false`, `promoted_until = now`
    - `offer_pin` -> `offers/{offerId}.is_featured = false`, `featured_until = now`
  - Original entry is linked with reversal metadata:
    - `reversed_at`
    - `reversed_by_uid`
    - `reversal_entry_id`
  - Reversal entry metadata includes:
    - `reversal_of_entry_id`
    - `reversal_reason`
    - `original_feature_key`
    - `original_amount`
- Safety:
  - Admin authorization uses claims + `admins/{uid}` fallback policy
  - Double reversal is blocked
  - Non-debit and unsupported feature reversals are blocked
  - Full audit linkage is written to `wallet_audit_events`

Payloads are intentionally minimal (uid/venueId/requestId/amount/balance/timestamp) and avoid unnecessary sensitive fields.

### Wallet Notifications

Wallet notifications are written server-side to `users/{uid}/notifications` and deduped through
`wallet_notification_events/{eventKey}`.

Current wallet notification events:

- Admin:
  - `wallet_topup_request_created`
- Merchant:
  - `wallet_topup_request_approved`
  - `wallet_topup_request_rejected`
  - `wallet_entry_reversed`
  - `wallet_low_balance`
  - `wallet_story_promotion_expiring`
  - `wallet_offer_pin_expiring`

Server-side notification preferences are read from `users/{uid}` and default to enabled when absent:

- `wallet_notifications_enabled`
- `wallet_expiry_reminders_enabled`
- `admin_wallet_notifications_enabled`

Expiry reminders are evaluated server-side on a 60-minute schedule and currently use a
24-hour reminder window before `promoted_until` / `featured_until`.

Dedupe policy:

- Notification writes happen only after successful wallet/top-up transactions.
- Each notification uses a deterministic event key such as:
  - `wallet_topup_created_{requestId}_{uid}`
  - `wallet_topup_approved_{requestId}_{uid}`
  - `wallet_topup_rejected_{requestId}_{uid}`
  - `wallet_reversal_{entryId}_{uid}`
  - `wallet_low_balance_story_{requestId}_{uid}`
  - `wallet_low_balance_offer_{requestId}_{uid}`
  - `wallet_story_expiring_{storyId}_{promotedUntilMillis}_{uid}`
  - `wallet_offer_expiring_{offerId}_{featuredUntilMillis}_{uid}`
- Replayed callables and idempotent retries must not create duplicate notifications for the same event key.
- Disabled server preferences prevent notification documents from being created at all.

In-app notification routing:

- Merchant wallet notifications open `MerchantWalletScreen`
  - `wallet_topup_request_approved`
  - `wallet_topup_request_rejected`
  - `wallet_entry_reversed`
  - `wallet_low_balance`
  - `wallet_story_promotion_expiring` -> `/merchant/stories` (highlights the target story and shows renew CTA)
  - `wallet_offer_pin_expiring` -> `/merchant/offers` (highlights the target offer and shows renew CTA)
- Admin wallet top-up notifications open the admin review queue
  - `wallet_topup_request_created` -> `/admin/topups`

### Phase 14: Renewal Flows for Paid Benefits

- Renewal uses the existing server-authoritative callables (no new payment path):
  - Story renewal: `promoteStory` with a fresh `requestId`
  - Offer renewal: `pinOffer` with a fresh `requestId`
- Renewal timing rule remains server-side and explicit: renewal starts from **now**.
- Merchant UI now exposes actionable renewal states:
  - Stories: active / expiring soon / expired promotion state with `Renew promotion`
  - Offers: active / expiring soon / ended feature state with `Renew feature`
  - Expired offers themselves show an explicit explanation when renewal is no longer possible, instead of dropping the CTA silently
- Expiry reminder taps land on actionable screens with highlighted target item and visible renew action.

### Required Config / Seed Data

For any new environment (staging/prod), ensure these are present:

- `wallet_feature_pricing/default`:
  - `story_promote_1d`
  - `story_promote_3d`
  - `story_promote_7d`
  - `offer_pin_1d`
  - `offer_pin_3d`
  - `offer_pin_7d`
  - `currency` (default `ILS`)
- `merchant_wallets/{venueId}.low_balance_threshold` (default created by backend: `10`)
- Admin enablement via:
  - custom claims (`admin`/`role`)
  - or `admins/{uid}` with `active != false`

### Wallet Release Readiness (Phase 15)

- Seed/verify commands (run from `functions/`):
  - `npm run wallet:seed-config`
  - `npm run wallet:verify-env`
    - `wallet:verify-env` prefers Firebase Admin ADC when available.
    - If ADC is missing, it now falls back to the active `firebase login` session for a read-only environment verification pass.
- Admin callable diagnostics:
  - `verifyWalletOperationalReadiness` (admin-only + App Check)
  - status semantics:
    - `FAIL`: hard misconfiguration such as missing/invalid pricing
    - `WARN`: environment is configured but has not produced wallet usage/read-model/reminder data yet
    - `PASS`: config is valid and representative wallet operational data exists
- Operator docs:
  - `docs/release/merchant_wallet_release_runbook.md`
  - `docs/release/merchant_wallet_staging_checklist.md`

### Staging E2E Checklist

Run this full flow before release:

1. Merchant creates top-up request with receipt proof image.
2. Admin opens `/admin/topups`, reviews pending request, and approves it.
3. Verify wallet balance increased and `merchant_wallets/{venueId}/entries` has a credit entry.
4. Verify top-up request status is `credited` with `linked_entry_id`.
5. Merchant promotes a story and verify debit entry is written.
6. Merchant features an offer from `MerchantOffers` and verify debit entry plus `is_featured/featured_until` update.
7. Verify low-balance behavior and `insufficient_wallet_balance` path when balance is not enough.
8. Verify rejected request keeps `admin_note` visible to merchant.

### Operational Top-up Review Script

Fallback only: if admin UI is unavailable, use the script below to review pending requests in production/emulator with admin credentials:

```bash
cd functions
node scripts/review_topup_request.js --requestId=<request_id> --decision=credit --adminUid=<admin_uid> --adminNote="Approved transfer"
node scripts/review_topup_request.js --requestId=<request_id> --decision=reject --adminUid=<admin_uid> --adminNote="Receipt mismatch"
```

- `credit`: creates a ledger entry under `merchant_wallets/{venueId}/entries`, updates wallet balance, and links `linked_entry_id` on the request.
- `reject`: marks request as rejected and stores the review note.
- `adminUid` must exist under `admins/{uid}` with `active != false`.

## Google Places Photos

Venue documents may opt into on-demand Google Places photos with:

```text
external_source.provider = google_places
external_source.place_id = <Google Place ID>
```

The app never persists Google photo resource names or returned media URLs. The
`getVenuePlacePhotos` callable resolves fresh, short-lived media URLs and returns
the required Google Maps and author attribution for display.

Environment setup:

1. Enable Places API (New) and billing in the Google Cloud project.
2. Store the restricted server key without committing it:
   `firebase functions:secrets:set GOOGLE_PLACES_API_KEY`
3. Deploy only the photo callable after local verification:
   `firebase deploy --only functions:getVenuePlacePhotos --project wain-d2e28`
4. Keep App Check enabled for production clients.
5. Confirm the public Terms of Use and Privacy Policy include the Google Maps
   Platform terms and privacy disclosures required by Places API policy.

Do not copy, download, or seed Google Maps photo URLs into Firestore or Firebase
Storage. The callable is read-only and falls back to the existing venue artwork
when the API is unavailable.

## Windows Development

- Windows runtime policy and Firebase plugin support matrix:
  - `docs/windows_dev.md`
