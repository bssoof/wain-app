# Week 3 Backend Extraction Progress - 2026-04-14

## Goal
Continue safe decomposition of `functions/src/index.ts` into focused modules with zero callable/trigger rename risk.

## Completed In This Slice
- Extracted content moderation hashing utilities into `functions/src/content_governance_hashing.ts`.
- Extracted content governance access/envelope/normalization helpers into `functions/src/content_governance_access.ts`.
- Extracted admin content callable handlers into `functions/src/admin_content.ts`:
  - `listOffersForAdmin`
  - `listStoriesForAdmin`
  - `contentModerateOffer`
  - `contentModerateStory`
- Updated `functions/src/index.ts` to keep composition-root behavior and re-export these handlers.

## Completed In Follow-up Slice (same day)
- Created shared modules:
  - `functions/src/shared/app-check.ts`
  - `functions/src/shared/audit.ts`
- Moved `requireAppCheck` and `logSecurityAudit` implementations out of `index.ts` into shared modules.
- Kept compatibility by re-exporting `requireAppCheck` and `logSecurityAudit` from `index.ts`.
- Updated `functions/src/admin_content.ts` to consume shared modules directly.

## Completed In Follow-up Slice 2 (same day)
- Created `functions/src/shared/finance-media-normalizers.ts` and moved shared normalization helpers:
  - `workspaceString`
  - `financeTimestampToMillis`
  - `financeTimestampToIso`
  - `financeTimestampToIsoWithFallback`
  - `financeTimestampToOptionalIso`
  - `mediaRecordOrNull`
  - `normalizeMediaIsoTimestamp`
- Updated `index.ts` to import these helpers from shared module and keep compatibility re-exports for external consumers.
- Reduced coupling in extracted modules:
  - `functions/src/content_governance_access.ts` now imports normalizers from shared module.
  - `functions/src/admin_content.ts` now imports `workspaceString` and `mediaRecordOrNull` from shared module.
- Created `functions/src/shared/admin-auth.ts` and moved admin-access logic implementation there.
- `index.ts` now keeps a thin `requireAdminAccess` wrapper via `requireAdminAccessWithDb(context, db)` and imports shared `isEmulatorOwnerToken` for venue governance role checks.

## Completed In Follow-up Slice 3 (same day)
- Extracted Admin Reviews callables into `functions/src/admin_reviews.ts`:
  - `listVenueReviewsForAdmin`
  - `moderateVenueReviewForAdmin`
- `functions/src/index.ts` now re-exports these two handlers from `admin_reviews.ts`.
- Review-moderation helper symbols required by the extracted module are currently re-exported from `index.ts` as a transitional compatibility layer.

## Completed In Follow-up Slice 4 (same day)
- Extracted Admin Media callables into `functions/src/admin_media.ts`:
  - `getAdminMediaInventoryReadBundle`
  - `mediaSoftDeleteAsset`
  - `mediaQuarantineAsset`
  - `mediaReferenceCheckAsset`
  - `mediaPurgeAsset`
- `functions/src/index.ts` now re-exports these handlers from `admin_media.ts`.
- Added transitional exports in `index.ts` for media-governance helpers/constants used by the extracted module to preserve behavior while reducing callable-body size in the composition root.

## Completed In Follow-up Slice 5 (same day)
- Extracted Admin Venues read callables into `functions/src/admin_venues.ts`:
  - `getAdminVenueWorkspaceReadBundle`
  - `listVenuesForAdmin`
- `functions/src/index.ts` now re-exports these two handlers from `admin_venues.ts`.
- Added transitional exports in `index.ts` for venue-read helper symbols required by the extracted module.

## Completed In Follow-up Slice 6 (same stream)
- Extracted Admin Config governance callables into `functions/src/admin_config.ts`:
  - `getAdminConfigGovernanceBundle`
  - `configUpsertDraft`
  - `configReviewDraft`
  - `configPublishDraft`
  - `configRollbackVersion`
- `functions/src/index.ts` now re-exports these handlers from `admin_config.ts` to preserve callable export compatibility.
- Removed stale config constants from `index.ts` that became unused after extraction to keep strict TypeScript build checks green.

## Completed In Follow-up Slice 7 (venue write-governance verification)
- Confirmed Domain 5 write-governance callables are extracted in `functions/src/admin_venues.ts` and exported through `functions/src/index.ts`:
  - `adminCreateVenue`
  - `adminUpdateVenueProfile`
  - `adminUpdateVenueVisibility`
  - `adminUpdateVenueOperationalStatus`
  - `adminUpdateVenueSubscriptionStatus`
- Ran dedicated emulator suite `test/emulator/venueManagementCallableFlows.test.js` and passed all venue governance checks (VM01-VM21).

## Completed In Follow-up Slice 8 (transitional helper decoupling)
- Added `functions/src/shared/admin-surface-helpers.ts` to centralize shared admin-surface helper logic previously imported from `index.ts`.
- Rewired extracted admin modules to consume shared helpers directly and reduce composition-root coupling:
  - `functions/src/admin_content.ts`
  - `functions/src/admin_config.ts`
  - `functions/src/admin_reviews.ts`
  - `functions/src/admin_media.ts`
  - `functions/src/admin_venues.ts`
- Kept callable export compatibility unchanged by preserving `functions/src/index.ts` as the export surface.

## Completed In Follow-up Slice 9 (final admin media/review decoupling)
- Added `functions/src/shared/review-moderation.ts` and moved review moderation helper/constants used by `admin_reviews.ts` out of `index.ts` transitional imports.
- Added `functions/src/shared/media-governance.ts` and moved media governance helper/constants used by `admin_media.ts` out of `index.ts` transitional imports.
- Rewired extracted modules to import from shared modules directly:
  - `functions/src/admin_reviews.ts`
  - `functions/src/admin_media.ts`
- Result: no remaining `from "./index"` imports under `functions/src` extracted admin modules; composition-root coupling reduced further while callable export names remain unchanged.

## Completed In Follow-up Slice 10 (runtime hardening + regression verification)
- Hardened Firebase Admin initialization in `functions/src/index.ts` by guarding app bootstrap (`if (admin.apps.length === 0) admin.initializeApp();`) to avoid duplicate-init risk under alternate module load order.
- Kept `index.ts` as composition root and export surface; no callable/trigger export names were changed.
- Verified refactor/runtime behavior with emulator security callable suite that covers media and review governance paths.

## Completed In Follow-up Slice 11 (shared storage helper extraction)
- Added `functions/src/shared/storage.ts` and moved shared storage helper logic there:
  - `getDefaultStorageBucket`
  - `isInternalProofStoragePath`
- Rewired `functions/src/index.ts` to import storage helpers from `shared/storage.ts` instead of keeping local duplicated implementations.
- Rewired `functions/src/shared/media-governance.ts` to reuse the shared storage helper and preserve export compatibility for `admin_media.ts`.
- Result: storage bucket resolution logic is now centralized in one shared location with no behavior change.

## Completed In Follow-up Slice 12 (wallet reversal role-helper extraction)
- Moved wallet reversal admin-role helpers out of `functions/src/index.ts` into `functions/src/shared/admin-auth.ts`:
  - `resolveAdminExecutionRole`
  - `resolveRequiredSecondApproverRole`
- Rewired `functions/src/index.ts` to import/use these shared helpers directly.
- Kept reversal thresholds authoritative in `index.ts` and passed them into shared helper, preserving existing decision behavior.
- Result: reduced composition-root helper density for wallet reversal flow without changing callable export names or runtime contracts.

## Completed In Follow-up Slice 13 (index helper deduplication to shared admin surface)
- Rewired `functions/src/index.ts` to consume shared helpers from `functions/src/shared/admin-surface-helpers.ts` for:
  - `normalizeNumber`
  - `resolveWalletLedgerUiType`
- Removed duplicated local implementations of these helpers from `index.ts`.
- Kept compatibility behavior unchanged by preserving existing call sites and export surface through the same symbol names.
- Result: further reduced helper duplication inside the composition root without changing callable/trigger names.

## Completed In Follow-up Slice 14 (wallet notification preference helper extraction)
- Added `functions/src/shared/wallet-notification-preferences.ts` to centralize wallet notification preference fields/types and preference filtering helpers.
- Moved these elements out of `functions/src/index.ts` into shared module:
  - `WALLET_NOTIFICATION_PREF_FIELD`
  - `WALLET_EXPIRY_REMINDER_PREF_FIELD`
  - `ADMIN_WALLET_NOTIFICATION_PREF_FIELD`
  - `WalletNotificationPreferenceKey`
  - `isWalletNotificationPreferenceEnabled`
  - `filterUserUidsByWalletNotificationPreference`
- Rewired `index.ts` to import shared constants/type/helpers and pass `db` into the shared filtering helper.
- Result: notification preference logic is now centralized in shared layer while notification dispatch behavior remains unchanged.

## Completed In Follow-up Slice 15 (wallet notification dispatch extraction)
- Added `functions/src/shared/wallet-notifications.ts` to centralize wallet notification dispatch helpers and wallet notification currency formatter.
- Moved these helpers out of `functions/src/index.ts` into shared module:
  - `writeDedupedUserNotification`
  - `sendWalletNotificationToUsers`
  - merchant/admin UID lookup helpers for notification targeting
  - `sendWalletMerchantNotification`
  - `sendWalletAdminNotification`
  - `formatCurrencyAmount`
- Rewired `index.ts` to call shared notification helpers (passing `db`) and removed duplicated local implementations.
- Result: wallet notification preference and dispatch logic are both now in shared modules, reducing composition-root operational density while keeping behavior stable.

## Completed In Follow-up Slice 16 (remaining-domain kickoff: one safe slice per unit)
- Public/Engagement kickoff extraction:
  - Added `functions/src/public_engagement.ts` and moved `trackVenueEvent` with its local event-type normalization helpers.
  - Re-exported `trackVenueEvent` from `functions/src/index.ts` to preserve callable name compatibility.
- Analytics + Triggers kickoff extraction:
  - Added `functions/src/analytics_offer_health.ts` and moved:
    - `updateVenueHasOffers`
    - `checkExpiringOffers`
  - Re-exported both triggers from `functions/src/index.ts` with unchanged names.
- Wallet Runtime kickoff extraction:
  - Added `functions/src/wallet_runtime_readiness.ts` and moved:
    - `isCurrentUserAdmin`
    - `verifyWalletOperationalReadiness`
  - Re-exported both callables from `functions/src/index.ts` with unchanged names.
- Cleaned moved code from `index.ts` and removed now-unused local helper/constant blocks tied to moved slices.
- Result: started decomposition of the three remaining large domains while keeping `index.ts` as composition-root export surface.

## Completed In Follow-up Slice 17 (public geo-search extraction)
- Continued Public/Engagement extraction by moving geo-search callable from `functions/src/index.ts` to `functions/src/public_engagement.ts`:
  - `searchVenuesInBounds`
  - local helper `calculateDistance`
- Updated composition-root export surface in `functions/src/index.ts` to re-export:
  - `searchVenuesInBounds` (alongside existing `trackVenueEvent`)
- Removed moved implementation block from `index.ts` with no callable name change.
- Result: reduced callable-body density in `index.ts` while preserving callable compatibility and runtime behavior.

## Completed In Follow-up Slice 18 (wallet admin read callables extraction)
- Added `functions/src/wallet_admin_reads.ts` and moved admin read-only wallet callables from `functions/src/index.ts`:
  - `listMerchantTopUpRequestsForAdmin`
  - `listMerchantWalletLedgerEntriesForAdmin`
- Moved local date-bound parsing helper used by these reads into the new module and reused shared admin-surface/normalizer helpers:
  - `clampFinanceReadLimit`
  - `loadVenueDisplayLabels`
  - `resolveWalletLedgerUiType`
  - `financeTimestampToIso`
  - `financeTimestampToMillis`
- Updated `functions/src/index.ts` to re-export the two callables from `wallet_admin_reads.ts` and removed their in-file implementations.
- Result: reduced wallet admin read callable density in composition root while preserving callable names and behavior.

## Completed In Follow-up Slice 19 (analytics runtime + review trigger extraction)
- Added `functions/src/analytics_runtime.ts` and moved analytics runtime surfaces out of `functions/src/index.ts`:
  - `aggregateVenueAnalytics`
  - `backfillMerchantAnalytics`
  - internal analytics helpers previously local to `index.ts` (daily bucketing and summary/offer rollup wiring).
- Continued Public/Engagement extraction by moving the review trigger out of `index.ts` into `functions/src/public_engagement.ts`:
  - `onReviewWrite`
- Updated `functions/src/index.ts` composition-root exports to re-export moved surfaces from:
  - `functions/src/analytics_runtime.ts`
  - `functions/src/public_engagement.ts`
- Removed moved callable/trigger bodies and now-unused local helper/import leftovers from `index.ts`.
- Result: analytics + review-trigger callable density dropped further in composition root while preserving Firebase export names.

## Completed In Follow-up Slice 20 (wallet runtime mutation extraction)
- Added `functions/src/wallet_runtime_mutations.ts` and moved wallet runtime mutation callables out of `functions/src/index.ts`:
  - `createMerchantTopUpRequest`
  - `reviewMerchantTopUpRequest`
  - `reverseWalletEntry`
  - `approveWalletReversalRequest`
- Moved reversal execution logic with them (including pending second-approval branch) while preserving command/idempotency behavior.
- Updated `functions/src/index.ts` composition-root exports to re-export moved wallet runtime callables from `wallet_runtime_mutations.ts`.
- Removed moved callable bodies and now-unused reversal constants/import leftovers from `index.ts`.
- Result: wallet write/reversal callable density is now significantly reduced in composition root while preserving callable names.

## Completed In Follow-up Slice 21 (wallet maintenance extraction)
- Added `functions/src/wallet_runtime_maintenance.ts` and moved wallet maintenance runtime surfaces out of `functions/src/index.ts`:
  - `runWalletLifecycleMaintenance`
  - `runWalletExpiryReminderMaintenance`
  - `walletLifecycleMaintenance`
  - `walletExpiryReminderMaintenance`
- Moved related maintenance constants/options/result contracts and maintenance-local audit helper into the new module.
- Updated `functions/src/index.ts` composition-root exports to re-export both maintenance runner functions and scheduled triggers from `wallet_runtime_maintenance.ts`.
- Removed moved maintenance bodies and now-unused maintenance constants/import leftovers from `index.ts`.
- Result: scheduled maintenance flow is now isolated in a dedicated runtime module while keeping compatibility for existing imports/tests that consume maintenance runners from index exports.

## Compatibility Contract
- No callable export names changed.
- No trigger names changed.
- `index.ts` remains the Firebase export surface.

## Validation
Run from `wain_app/functions`:
- `npm run build`
- `npm test`

Observed result on 2026-04-14:
- Build passed.
- Test suite passed (12/12).

Additional validation for Domain 8 slice:
- `functions`: `npm run build` passed after removing stale constants from `index.ts`.
- `functions` emulator targeted config suite passed (W66, W67, W68, W69, W70).
- `admin_web_console`: `npm test` passed (46 files, 246 tests).
- `admin_web_console`: `npm run build` passed (Next.js production build).

Additional validation for Domain 5 write-governance execution:
- `functions`: `npm run build` passed.
- `functions` emulator venue governance suite passed (VM01-VM21, 23/23).
- `admin_web_console`: `npm test` passed (46 files, 246 tests).
- `admin_web_console`: `npm run build` passed (Next.js production build).

Additional validation for Follow-up Slice 8 transitional decoupling:
- `functions`: `npm run build` passed.
- `functions` emulator venue governance suite passed (VM01-VM21, 23/23).
- `functions` emulator security callable suite passed (`test/emulator/securityCallableFlows.test.js`, 97/97, 0 failures).

Additional validation for Follow-up Slice 9 final admin media/review decoupling:
- `functions`: `npm run build` passed.
- Search verification: `from "./index"` no longer present in `functions/src/**/*.ts` extracted admin modules.

Additional validation for Follow-up Slice 10 runtime hardening:
- `functions`: `npm run build` passed.
- `functions` emulator security callable suite passed (`test/emulator/securityCallableFlows.test.js`, 97/97, 0 failures).

Additional validation for Follow-up Slice 11 shared storage helper extraction:
- `functions`: `npm run build` passed.
- `functions` emulator security callable suite passed (`test/emulator/securityCallableFlows.test.js`, 97/97, 0 failures).

Additional validation for Follow-up Slice 12 wallet reversal role-helper extraction:
- `functions`: `npm run build` passed.
- `functions` emulator security callable suite passed (`test/emulator/securityCallableFlows.test.js`, 97/97, 0 failures).

Additional validation for Follow-up Slice 13 index helper deduplication:
- `functions`: `npm run build` passed.
- `functions` emulator security callable suite passed (`test/emulator/securityCallableFlows.test.js`, 97/97, 0 failures).

Additional validation for Follow-up Slice 14 wallet notification preference helper extraction:
- `functions`: `npm run build` passed.
- `functions` emulator security callable suite passed (`test/emulator/securityCallableFlows.test.js`, 97/97, 0 failures).

Additional validation for Follow-up Slice 15 wallet notification dispatch extraction:
- `functions`: `npm run build` passed.
- `functions` emulator security callable suite passed (`test/emulator/securityCallableFlows.test.js`, 97/97, 0 failures).

Additional validation for Follow-up Slice 16 remaining-domain kickoff extraction:
- `functions`: `npm run build` passed.
- `functions` emulator security callable suite passed (`test/emulator/securityCallableFlows.test.js`, 97/97, 0 failures).

Additional validation for Follow-up Slice 17 public geo-search extraction:
- `functions`: `npm run build` passed.
- `functions` emulator security callable suite passed (`test/emulator/securityCallableFlows.test.js`, 97/97, 0 failures).

Additional validation for Follow-up Slice 18 wallet admin read callables extraction:
- `functions`: `npm run build` passed.
- `functions` emulator security callable suite passed (`test/emulator/securityCallableFlows.test.js`, 97/97, 0 failures).

Additional validation for Follow-up Slice 19 analytics runtime + review trigger extraction:
- `functions`: `npm run build` passed.
- `functions` emulator security callable suite passed (`test/emulator/securityCallableFlows.test.js`, 97/97, 0 failures).

Additional validation for Follow-up Slice 20 wallet runtime mutation extraction:
- `functions`: `npm run build` passed.
- `functions` emulator security callable suite passed (`test/emulator/securityCallableFlows.test.js`, 97/97, 0 failures).

Additional validation for Follow-up Slice 21 wallet maintenance extraction:
- `functions`: `npm run build` passed.
- `functions` emulator security callable suite passed (`test/emulator/securityCallableFlows.test.js`, 97/97, 0 failures).

## Risks Noted
- Some transitional helper exports from `index.ts` remain for compatibility while decoupling is completed in small safe slices.
- Shared foundation extraction is now materially advanced; remaining high-coupling helper groups (wallet/runtime and residual venue/config helper sets) still need migration out of the composition root.

## Next Recommended Slice
1. Continue reducing `index.ts` helper density by consolidating duplicated wallet report/audit helpers into shared/runtime modules where safe.
2. Evaluate extracting remaining wallet governance triggers/read-model writers (`onWalletEntryWrite`, `onTopupRequestWrite`) into a wallet audit/runtime module while preserving export names.
3. Keep running `npm run build` and emulator callable security coverage after each extraction slice.
