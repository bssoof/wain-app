# Week 2 index.ts Decomposition Map - 2026-04-13

## Objective
Prepare a backend-ready split plan for `functions/src/index.ts` without changing callable names or trigger behavior.

## Progress Update (2026-04-14)
- Completed first production extraction slice for Domain 9 (Admin Content Moderation).
- New modules now present in `functions/src`:
  - `content_governance_hashing.ts`
  - `content_governance_access.ts`
  - `admin_content.ts`
- `index.ts` now composes and re-exports admin content handlers from `admin_content.ts` while preserving callable export names.
- Validation rerun after extraction:
  - `npm run build`
  - `npm test`
  - Result: build passed and functions tests passed (12/12).
- Shared foundations progress in follow-up slice: `requireAppCheck` and `logSecurityAudit` extracted to `functions/src/shared/app-check.ts` and `functions/src/shared/audit.ts` with compatibility re-export from `index.ts`.
- Additional shared foundations extracted in follow-up slice 2: normalization helpers moved to `functions/src/shared/finance-media-normalizers.ts`, and admin access implementation moved to `functions/src/shared/admin-auth.ts` with `index.ts` wrapper compatibility preserved.
- Domain 6 progress (Admin Reviews): `listVenueReviewsForAdmin` and `moderateVenueReviewForAdmin` extracted to `functions/src/admin_reviews.ts` and re-exported through `index.ts`.
- Domain 7 progress (Admin Media Governance): `getAdminMediaInventoryReadBundle`, `mediaSoftDeleteAsset`, `mediaQuarantineAsset`, `mediaReferenceCheckAsset`, and `mediaPurgeAsset` extracted to `functions/src/admin_media.ts` and re-exported through `index.ts`.
- Domain 5 progress (Admin Venue Management): read and write-governance callables extracted to `functions/src/admin_venues.ts` and re-exported through `index.ts`:
  - Read surface: `getAdminVenueWorkspaceReadBundle`, `listVenuesForAdmin`
  - Write-governance: `adminCreateVenue`, `adminUpdateVenueProfile`, `adminUpdateVenueVisibility`, `adminUpdateVenueOperationalStatus`, `adminUpdateVenueSubscriptionStatus`
- Domain 8 progress (Admin Config Governance): `getAdminConfigGovernanceBundle`, `configUpsertDraft`, `configReviewDraft`, `configPublishDraft`, and `configRollbackVersion` extracted to `functions/src/admin_config.ts` and re-exported through `index.ts`.
- Domain 8 validation rerun:
  - `functions`: `npm run build` (pass)
  - `functions` emulator subset: config governance tests `W66|W67|W68|W69|W70` (5/5 pass)
  - `admin_web_console`: `npm test` (46/46 files, 246/246 tests pass)
  - `admin_web_console`: `npm run build` (Next.js production build pass)
- Domain 5 write-governance validation rerun:
  - `functions`: `npm run build` (pass)
  - `functions` emulator suite: venue management tests `VM01..VM21` (23/23 pass)
  - `admin_web_console`: `npm test` (46/46 files, 246/246 tests pass)
  - `admin_web_console`: `npm run build` (Next.js production build pass)
- Transitional decoupling follow-up (post Domain 8/5 verification): added `functions/src/shared/admin-surface-helpers.ts` and rewired extracted admin modules (`admin_content.ts`, `admin_config.ts`, `admin_reviews.ts`, `admin_media.ts`, `admin_venues.ts`) to consume shared helpers directly instead of importing helper symbols from `index.ts`.
- Transitional decoupling validation rerun:
  - `functions`: `npm run build` (pass)
  - `functions` emulator suite: venue management tests `VM01..VM21` (23/23 pass)
  - `functions` emulator suite: `securityCallableFlows` (97/97 pass)

## Baseline Snapshot
- Source of truth: `functions/src/index.ts`
- Monolith size: ~10k lines with mixed domains (public flows, admin callables, scheduled jobs, Firestore triggers).
- Already extracted and healthy:
  - `functions/src/menu_import.ts`
  - `functions/src/busy_times/job.ts`
  - `functions/src/transport.ts`
- Triage probe snapshot:
  - `wain_app/.tmp/probe_admin_callables_results.json`
  - 16/16 admin callables responded with `400 FAILED_PRECONDITION` (`App Check verification failed`) which is expected for unauthenticated probe traffic and confirms callable endpoints are registered.

## Shared Foundations To Extract First
Create shared modules before moving handlers:
- `functions/src/shared/admin-auth.ts`
  - move `requireAdminAccess`, `resolveAdminExecutionRole`, `resolveRequiredSecondApproverRole`
- `functions/src/shared/app-check.ts`
  - move `requireAppCheck`
- `functions/src/shared/audit.ts`
  - move `logSecurityAudit`
- `functions/src/shared/storage.ts`
  - move `getDefaultStorageBucket`, `isInternalProofStoragePath`

This keeps domain files focused on handler logic and reduces cyclic dependencies.

## Domain Split Map

### 1) Public + Merchant Engagement
Target module: `functions/src/modules/engagement.ts`

| Export | Current line | Kind |
|---|---:|---|
| `trackVenueEvent` | 1426 | callable |
| `createClaimToken` | 1490 | callable |
| `validateToken` | 1660 | callable |
| `redeemToken` | 1772 | callable |
| `searchVenuesInBounds` | 1974 | callable |
| `redeemInviteCode` | 2300 | callable |
| `promoteStory` | 2497 | callable |
| `pinOffer` | 2768 | callable |

### 2) Analytics + Venue Offer Flags
Target module: `functions/src/modules/analytics-ops.ts`

| Export | Current line | Kind |
|---|---:|---|
| `updateVenueHasOffers` | 2068 | firestore trigger |
| `checkExpiringOffers` | 2117 | scheduled job |
| `aggregateVenueAnalytics` | 2179 | scheduled job |
| `backfillMerchantAnalytics` | 2210 | callable |

### 3) Review Counters + Notifications
Target module: `functions/src/modules/reviews-events.ts`

| Export | Current line | Kind |
|---|---:|---|
| `onReviewWrite` | 2449 | firestore trigger |

### 4) Merchant Wallet + Finance Runtime
Target module: `functions/src/modules/wallet-runtime.ts`

| Export | Current line | Kind |
|---|---:|---|
| `createMerchantTopUpRequest` | 3012 | callable |
| `reviewMerchantTopUpRequest` | 3145 | callable |
| `isCurrentUserAdmin` | 3377 | callable |
| `verifyWalletOperationalReadiness` | 3383 | callable |
| `listMerchantTopUpRequestsForAdmin` | 4524 | callable |
| `listMerchantWalletLedgerEntriesForAdmin` | 4652 | callable |
| `reverseWalletEntry` | 7749 | callable |
| `approveWalletReversalRequest` | 8018 | callable |
| `walletLifecycleMaintenance` | 8193 | scheduled job |
| `walletExpiryReminderMaintenance` | 8200 | scheduled job |
| `onWalletEntryWrite` | 8207 | firestore trigger |
| `rebuildWalletReportsDaily` | 8238 | scheduled job |

### 5) Admin Venue Management
Target module: `functions/src/modules/admin-venues.ts`

| Export | Current line | Kind |
|---|---:|---|
| `getAdminVenueWorkspaceReadBundle` | 4801 | callable |
| `listVenuesForAdmin` | 5547 | callable |
| `adminCreateVenue` | 5678 | callable |
| `adminUpdateVenueProfile` | 5765 | callable |
| `adminUpdateVenueVisibility` | 5921 | callable |
| `adminUpdateVenueOperationalStatus` | 6068 | callable |
| `adminUpdateVenueSubscriptionStatus` | 6196 | callable |

### 6) Admin Reviews Moderation
Target module: `functions/src/modules/admin-reviews.ts`

| Export | Current line | Kind |
|---|---:|---|
| `listVenueReviewsForAdmin` | 6325 | callable |
| `moderateVenueReviewForAdmin` | 6425 | callable |

### 7) Admin Media Governance
Target module: `functions/src/modules/admin-media.ts`

| Export | Current line | Kind |
|---|---:|---|
| `getAdminMediaInventoryReadBundle` | 6592 | callable |
| `mediaSoftDeleteAsset` | 6836 | callable |
| `mediaQuarantineAsset` | 6998 | callable |
| `mediaReferenceCheckAsset` | 7164 | callable |
| `mediaPurgeAsset` | 7300 | callable |

### 8) Admin Config Governance
Target module: `functions/src/modules/admin-config.ts`

| Export | Current line | Kind |
|---|---:|---|
| `getAdminConfigGovernanceBundle` | 8501 | callable |
| `configUpsertDraft` | 8590 | callable |
| `configReviewDraft` | 8765 | callable |
| `configPublishDraft` | 8951 | callable |
| `configRollbackVersion` | 9199 | callable |

### 9) Admin Content Moderation
Target module: `functions/src/modules/admin-content.ts`

| Export | Current line | Kind |
|---|---:|---|
| `listOffersForAdmin` | 9749 | callable |
| `listStoriesForAdmin` | 9789 | callable |
| `contentModerateOffer` | 9829 | callable |
| `contentModerateStory` | 9998 | callable |

## Composition Root Pattern (Do Not Break Names)
Keep `functions/src/index.ts` as the Firebase export surface only:
- import/re-export handlers from domain modules
- preserve exact exported symbol names
- no URL/callable renaming in this phase

Expected shape:
- `export { trackVenueEvent, createClaimToken, ... } from "./modules/engagement";`
- same for each domain module

## Suggested Execution Order For BKD
1. Extract shared foundations (`shared/*`) with no behavior change.
2. Extract low-coupling admin modules first:
   - `admin-content`
   - `admin-reviews`
   - `admin-media`
3. Extract venue + config modules.
4. Extract wallet runtime module (largest and highest coupling).
5. Extract analytics/public engagement modules.
6. Leave `index.ts` as composition root and run full regression.

## Validation Checklist
- `functions`: `npm run build`
- `admin_web_console`: `npx tsc --noEmit`
- callable probe script still returns expected App Check failures for unauthenticated probes:
  - `node .tmp/probe_admin_callables.js`
- existing emulator security suite remains green.

## Week 2 Status Impact
- Task 2.6 (BKD map prep): ready for handoff.
- No runtime export names changed in this preparation step.
