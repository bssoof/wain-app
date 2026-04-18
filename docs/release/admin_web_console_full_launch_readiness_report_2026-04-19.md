# Admin Web Console - Full Launch Readiness Report

Date: 2026-04-19
Author: AI Engineering Review
Scope: Admin web console + backend callable readiness evidence for go-live decision.

## 1. Executive Summary

This review confirms strong progress and high baseline quality, but the current release state remains **NO-GO (temporary)** until remaining launch blockers are closed.

Current state:
- Admin frontend test and build gates passed.
- Functions build and core test suite passed.
- Emulator hardening gate rerun is green (`191/191` passed in latest direct emulator execution).
- Former P0 compatibility/readiness blockers (`P0-1`, `P0-2`) were resolved in the latest patch set.

Decision:
- Current recommendation: **NO-GO** until remaining launch blockers (notably production-safe transport completion and checklist automation discipline) are closed.

## 2. Validation Evidence Collected

Validation runs performed during this review:
- Admin web regression suite: PASS (`63 files`, `312 tests passed`).
- Admin web production build: PASS.
- Functions TypeScript build: PASS.
- Functions base test suite (`npm test`): PASS (`12/12`).
- Emulator aggregate command: failed to start due to occupied Firestore emulator port 8080.
- Direct emulator execution against active emulator host (latest rerun): `191 total`, `191 passed`, `0 failed`.

Interpretation:
- Core quality is high.
- Release confidence is no longer blocked by emulator hardening failures.
- Release remains blocked by remaining launch-governance/security workflow items.

## 3. Findings by Severity

## P0-1 - Compatibility export gap breaks security emulator flow (Resolved 2026-04-19)

Summary:
- Emulator security flow expects `rebuildWalletReportForVenue` from composition root imports.
- The symbol now exists in mutations module and is exported from composition root.

Status:
- Resolved.

Impact:
- Security callable flow test no longer fails in the wallet/report path.
- Readiness signal is restored for this path.

Evidence:
- Missing re-export context: [../../functions/src/index.ts](../../functions/src/index.ts#L64)
- Symbol implementation exists: [../../functions/src/wallet_runtime_mutations.ts](../../functions/src/wallet_runtime_mutations.ts#L104)
- Imported by emulator test: [../../functions/test/emulator/securityCallableFlows.test.js](../../functions/test/emulator/securityCallableFlows.test.js#L43)
- Called in failing scenario: [../../functions/test/emulator/securityCallableFlows.test.js](../../functions/test/emulator/securityCallableFlows.test.js#L1666)
- Fixed re-export in composition root: [../../functions/src/index.ts](../../functions/src/index.ts#L68)
- Latest rerun of `W25` passes.

## P0-2 - verify_wallet_env check is stale after module decomposition (Resolved 2026-04-19)

Summary:
- Script previously checked maintenance schedules by reading `functions/src/index.ts` text directly.
- Verification now reads `wallet_runtime_maintenance` module artifacts (with source fallback), removing mismatch and false-fail behavior.

Status:
- Resolved.

Impact:
- Operational readiness script no longer fails on decomposed-but-valid setup.
- Go/no-go signal is now aligned to the actual maintenance module.

Evidence:
- Text-coupled check source: [../../functions/scripts/verify_wallet_env.js](../../functions/scripts/verify_wallet_env.js#L326)
- Reads index.ts content directly: [../../functions/scripts/verify_wallet_env.js](../../functions/scripts/verify_wallet_env.js#L331)
- Check name marker: [../../functions/scripts/verify_wallet_env.js](../../functions/scripts/verify_wallet_env.js#L341)
- Actual maintenance schedules are here: [../../functions/src/wallet_runtime_maintenance.ts](../../functions/src/wallet_runtime_maintenance.ts#L333)
- Daily rebuild schedule declaration: [../../functions/src/wallet_runtime_maintenance.ts](../../functions/src/wallet_runtime_maintenance.ts#L348)
- Failing test expectation: [../../functions/test/emulator/walletConfigScripts.test.js](../../functions/test/emulator/walletConfigScripts.test.js#L99)
- Status assertion that currently breaks: [../../functions/test/emulator/walletConfigScripts.test.js](../../functions/test/emulator/walletConfigScripts.test.js#L117)
- Updated schedule-source verification: [../../functions/scripts/verify_wallet_env.js](../../functions/scripts/verify_wallet_env.js#L343)
- Regression test for maintenance module schedule source: [../../functions/test/emulator/walletConfigScripts.test.js](../../functions/test/emulator/walletConfigScripts.test.js#L120)

## P1-1 - Venue loaders can fallback to development fixture on callable failure

Summary:
- Venue directory/workspace loaders fallback to `development_fixture` when callable read fails.

Impact:
- Operators may see fallback data during backend outage instead of explicit hard-unavailable state.
- Raises operational clarity risk in production.

Evidence:
- Fixture fallback in directory loader path: [../../admin_web_console/lib/venues/venue-directory-read-loader.ts](../../admin_web_console/lib/venues/venue-directory-read-loader.ts#L543)
- Test explicitly accepts callable -> fixture fallback: [../../admin_web_console/lib/venues/venue-directory-read-loader.test.ts](../../admin_web_console/lib/venues/venue-directory-read-loader.test.ts#L112)
- Fixture channel in workspace loader: [../../admin_web_console/lib/venues/venue-workspace-read-loader.ts](../../admin_web_console/lib/venues/venue-workspace-read-loader.ts#L37)
- Workspace fallback source wiring: [../../admin_web_console/lib/venues/venue-workspace-read-loader.ts](../../admin_web_console/lib/venues/venue-workspace-read-loader.ts#L86)
- Workspace test accepts fallback source: [../../admin_web_console/lib/venues/venue-workspace-read-loader.test.ts](../../admin_web_console/lib/venues/venue-workspace-read-loader.test.ts#L88)

## P1-2 - Release checklist snapshot is stale versus latest test reality

Summary:
- Release checklist still carries an older pass-count baseline (`219/219`) and earlier date snapshot.
- Current execution evidence is newer and differs in totals plus emulator outcomes.

Impact:
- Audit trail drift between declared readiness and current measured status.
- May cause incorrect release communication.

Evidence:
- Decision snapshot marked ready: [admin_web_console_release_checklist.md](admin_web_console_release_checklist.md#L6)
- Legacy test count reference: [admin_web_console_release_checklist.md](admin_web_console_release_checklist.md#L25)
- Stage status matrix with accepted-with-follow-up records: [admin_web_console_progress_tracker.md](admin_web_console_progress_tracker.md#L124)

## P2-1 - Transport token model documentation includes NEXT_PUBLIC auth tokens

Summary:
- Runbook and transport env references include `NEXT_PUBLIC_*_AUTH_TOKEN` values.
- Callable transport can use current signed-in user token fallback, but static public token usage remains a governance concern if used in production.

Impact:
- If teams rely on static NEXT_PUBLIC auth tokens in live deployment, exposure risk increases.
- Security posture should enforce per-user token path and least privilege.

Evidence:
- Finance/content/media token prerequisites in runbook: [admin_web_console_release_runbook.md](admin_web_console_release_runbook.md#L22)
- Content token prerequisite: [admin_web_console_release_runbook.md](admin_web_console_release_runbook.md#L27)
- Media token prerequisite: [admin_web_console_release_runbook.md](admin_web_console_release_runbook.md#L35)
- Transport uses env token input: [../../admin_web_console/lib/finance/finance-command-transport.ts](../../admin_web_console/lib/finance/finance-command-transport.ts#L270)
- Transport can fallback to Firebase user idToken: [../../admin_web_console/lib/finance/finance-command-transport.ts](../../admin_web_console/lib/finance/finance-command-transport.ts#L90)

## 4. What Is Already Strong

- UI modernization/backlog work appears fully closed in the active UI improvement plan.
- Core admin route and capability architecture is stable and test-covered.
- Build pipeline for admin web and functions is healthy.

Reference:
- UI backlog closure table: [admin_web_console_ui_improvement_master_plan.md](admin_web_console_ui_improvement_master_plan.md#L209)

## 5. Remaining Work Before Go-Live

Mandatory before final GO:
1. Resolve P0-1 compatibility gap:
   - Either re-export `rebuildWalletReportForVenue` from composition root.
   - Or adjust emulator test import contract to match intended public surface.
2. Resolve P0-2 readiness script drift:
   - Update `verify_wallet_env` schedule checks to inspect the maintenance module contract instead of brittle index text scanning.
3. Re-run hardening gates on clean emulator session:
   - `npm run test:emulator:aggregate` with no occupied-port conflict.
   - Confirm full green status.
4. Update release checklist snapshot to current evidence:
   - New date, real pass counts, and explicit statement about emulator gate status.

Strongly recommended before final GO:
1. Production policy decision for venue fallback behavior:
   - Disable fixture fallback in production and return explicit unavailable states.
2. Security posture hardening for transport auth tokens:
   - Prefer user session token acquisition path over static NEXT_PUBLIC auth token in production environments.

## 6. Exit Criteria for Final GO

Final go-live can be considered only when all criteria below are met:
1. Emulator hardening suite is fully green with no failing tests.
2. Release checklist and progress tracker reflect current evidence date and totals.
3. P0 findings are marked closed with verifiable commit/test evidence.
4. No unresolved blocker remains in auth, callable transport, or wallet readiness checks.

## 7. Final Decision (At Report Time)

- Decision: **NO-GO (temporary)**
- Reason: Two unresolved P0 blockers impact trust in hardening and readiness evidence.
- Re-evaluation trigger: immediate after P0 closure + full emulator re-run.
