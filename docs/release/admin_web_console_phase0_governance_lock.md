# Admin Web Console - Phase 0 Governance Lock

Document ID: AWC-P0
Related step: AWC-P0-01
Status: locked for execution review
Scope: governance only, no UI or backend implementation

## 1. Objective

Extract Phase 0 into a standalone operational contract that blocks ambiguity before any coding starts.

This document is the execution gate for:
- architecture decision,
- RBAC contract,
- sensitive command model,
- dual-approval policy,
- configuration governance,
- export governance,
- read-model health governance,
- deployment decision,
- fallback removal criteria.

## 2. Phase 0 Non-Negotiable Rules

1. Default deny for every admin action unless explicitly listed in the Policy Matrix.
2. All sensitive state-changing actions must run server-side only through approved commands.
3. Ledger remains append-only; financial correction is compensating-entry only.
4. No Phase 1 work starts before all Phase 0 done criteria are accepted.

## 3. Tech Choice Decision Rule

Primary decision:
- Admin console implementation baseline is React + Next.js.

Allowed exception to Flutter Web:
- only if the team is Flutter-only,
- and a benchmark prototype proves all acceptance points below.

Flutter exception acceptance points:
1. Wallet audit table handles at least 1000 rows with server pagination.
2. Filter + sorting p95 response time is under 800 ms on staging data.
3. Page-switch p95 response time is under 1200 ms between heavy admin screens.
4. No functional regressions in RBAC guard behavior compared to baseline requirements.

If any point fails, React + Next.js remains mandatory.

## 4. RBAC Source-of-Truth Contract

Source of truth:
- Firebase custom claims are the primary RBAC authority.
- admins/{uid} document fallback is transitional only.

Fallback usage rule:
- fallback can be used only when the required claim is missing, not when claim is explicitly restrictive.

Mandatory enforcement layers:
1. UI route/action guards.
2. Server command authorization checks.
3. Firestore/Storage rules alignment.

## 5. Claims vs Fallback Conflict Rule

Conflict handling is fail-closed.

| Claim state | admins/{uid} fallback state | Decision | Required audit action |
| --- | --- | --- | --- |
| Claim grants action | Any | Allow via claim | auth_decision_logged |
| Claim denies action | Any | Deny | rbac_conflict_detected |
| Claim missing | Fallback active | Allow via fallback (transitional) | fallback_auth_used |
| Claim missing | Fallback missing/inactive | Deny | auth_denied |
| Claim present but role mismatch with fallback | Any mismatch | Deny | rbac_conflict_detected |

Hard rule:
- fallback never overrides an explicit claim denial.

## 6. Policy Matrix Skeleton (Execution Baseline)

The following rows are mandatory in the policy matrix before coding.

| Capability | Screen/Surface | Server command | Allowed roles | Dual approval | Data scope |
| --- | --- | --- | --- | --- | --- |
| View dashboard operational cards | Dashboard | none (read only) | super_admin, finance_admin, content_admin, support_admin, ops_viewer | no | read models only |
| View pending top-ups | Top-Up Review Queue | none (read only) | super_admin, finance_admin, ops_viewer | no | merchant_topup_requests |
| Approve top-up | Top-Up Review Queue | approve_topup | super_admin, finance_admin | no | single request |
| Reject top-up | Top-Up Review Queue | reject_topup | super_admin, finance_admin | no | single request |
| View wallet audit | Wallet Audit | none (read only) | super_admin, finance_admin, ops_viewer, support_admin (read-only) | no | wallet entries + audit events |
| Create reversal <= 100 ILS | Reversals Console | reverse_wallet_entry | super_admin, finance_admin | no | single entry |
| Create reversal > 100 ILS and <= 500 ILS | Reversals Console | submit_reversal_for_approval | super_admin, finance_admin | yes | single entry |
| Approve high reversal | Reversals Console | approve_reversal | super_admin, finance_admin (second actor) | yes | pending approval queue |
| Publish finance-impacting config | System Config | publish_config | super_admin, finance_admin (publisher) | yes (reviewer != publisher) | config draft/live |
| Generate finance CSV export | Wallet Audit/Queue | generate_finance_export | super_admin, finance_admin | no | allowed financial columns only |
| Repair merchant link | Users & Merchants | repair_merchant_link | super_admin, support_admin | no | target user/merchant/venue |
| Purge media file | Media Center | purge_media_asset | super_admin, content_admin | no | media marked eligible only |
| Change admin role/claim | Admin Access | change_admin_role | super_admin | no | target admin uid |

Default deny applies to any capability not listed.

## 7. Sensitive Command Model Contract

## 7.1 Command Envelope

Every sensitive command request must include:
- command_id
- action
- actor_uid
- target_type
- target_id
- expected_state
- reason
- correlation_id
- submitted_at

Server-side guarantees:
1. actor_role is resolved on server, not trusted from request body.
2. command_id uniqueness is enforced per action + target.
3. command execution is atomic for each command transaction.

## 7.2 Replay and Conflict Behavior

| Case | Behavior | Write policy |
| --- | --- | --- |
| Same command_id + same payload replay | Return original result as idempotent replay | no new write |
| Same command_id + different payload | Reject as invalid command reuse | no write |
| New command_id but expected_state stale | Reject with conflict | no write |
| Authorization changes during execution | Fail closed | no write |

## 8. expected_state Contract per Sensitive Command

| Command | required expected_state | rejection condition |
| --- | --- | --- |
| approve_topup | status = pending, decision_state = unreviewed | request status changed or already reviewed |
| reject_topup | status = pending, decision_state = unreviewed | request status changed or already reviewed |
| reverse_wallet_entry | entry_status = posted, reversal_state = not_reversed, entry_type = debit | entry already reversed, not debit, or venue mismatch |
| approve_reversal | approval_state = pending_second_approval, request_not_expired = true | requester equals approver, state changed, or expired |
| publish_config | draft_status = reviewed, target_live_version = current_live_version | draft not reviewed, live version drift, or validation fail |
| repair_merchant_link | link_state = broken, dry_run_checksum = approved_checksum | target changed after dry run |
| purge_media_asset | media_state = quarantined, reference_count = 0, reference_index_health = healthy | reference_count > 0 or health stale/failed |
| change_admin_role | subject_state = active, session_policy = enforce_refresh | target inactive or invalid role transition |

## 9. Dual-Approval Matrix and State Machine

## 9.1 Dual-Approval Matrix

| Operation | Threshold | Required approvers |
| --- | --- | --- |
| reverse_wallet_entry | <= 100 ILS | 1 finance_admin or super_admin |
| reverse_wallet_entry | > 100 ILS and <= 500 ILS | requester + second distinct approver |
| reverse_wallet_entry | > 500 ILS | two approvers, at least one super_admin |
| publish_config affecting pricing/thresholds/reminders | any value | reviewer and publisher must be different actors |

## 9.2 State Machine (dual-approval operations)

States:
- drafted
- pending_second_approval
- approved_and_executed
- rejected
- expired
- cancelled_by_requester

Transitions:
1. drafted -> pending_second_approval on submit when threshold requires second approval.
2. drafted -> approved_and_executed on submit when threshold does not require second approval.
3. pending_second_approval -> approved_and_executed on valid second approval.
4. pending_second_approval -> rejected on explicit rejection.
5. pending_second_approval -> cancelled_by_requester by original requester only.
6. pending_second_approval -> expired after 48 hours without approval.

Hard guards:
- second approver must differ from requester.
- expired items cannot be executed.
- every transition writes an audit event.

## 10. Config Governance Contract

Sensitive config scope:
- wallet_feature_pricing/default
- low-balance defaults
- reminder windows
- operational feature flags affecting wallet operations

Mandatory lifecycle:
1. Draft creation.
2. Schema validation.
3. Business validation.
4. Reviewer approval.
5. Publish.
6. Verification.
7. Rollback snapshot retention.

Validation minimums:
- all required pricing keys exist.
- all pricing values are finite and > 0.
- currency is present and normalized.
- review actor and publish actor must be different for finance-impacting config.

Publish safety:
- publish happens server-side only.
- old and new summaries are audited.
- if post-publish verification fails, immediate rollback to latest valid snapshot.

## 11. Export Governance Contract

Scope:
- finance CSV export from wallet audit and top-up operational views only in V1.

Access:
- allowed: super_admin, finance_admin.
- denied: ops_viewer, content_admin, support_admin for finance export.

Rules:
1. Inline export hard limit is 10000 rows.
2. Above limit must use background export job.
3. Export file TTL is 24 hours.
4. Export must include filter summary and generation timestamp.
5. Every export action writes a dedicated audit event with actor, role, row_count, and correlation_id.
6. Non-financial broad PDF/export remains out of scope for V1.

## 12. Read-Model Freshness and Health Contract

Health states:
- healthy: lag <= freshness target.
- stale: lag > freshness target and <= 3x target.
- failed: lag > 3x target or writer failed 3 consecutive runs.

| Read model | Source of truth | Freshness target | Owner | UI behavior when stale/failed |
| --- | --- | --- | --- | --- |
| merchant_wallet_reports | wallet entries | near-real-time | finance backend owner | stale badge; keep read-only view |
| wallet_audit_events | command/audit writers | near-real-time | finance backend owner | stale badge; keep read-only view |
| admin_dashboard_summary | aggregate read writers | 1-5 min | ops backend owner | stale badge; disable SLA-dependent bulk actions |
| queue_sla_snapshots | top-up queue aggregation | 1-5 min | ops backend owner | warning banner; no blind SLA claim |
| config_publish_history | config publish writer | immediate | platform owner | block config publish if failed |
| media_reference_index | storage/firestore reference indexing | near-real-time | content backend owner | block purge when stale/failed |

Required health signals per model:
- last_successful_build_at
- last_failed_build_at
- consecutive_failures
- current_health_status

## 13. Deployment Strategy Decision

Decision:
- Admin web console is deployed as an independent surface from merchant/client apps.

Promotion path:
1. dev
2. staging
3. production

Deployment gate requirements:
- RBAC checks pass in staging.
- sensitive command contract tests pass.
- read-model health visibility is present in staging.
- rollback plan documented for admin web release.

Release strategy:
- progressive rollout with immediate rollback path.
- no coupling that forces mobile app release to ship admin web changes.

## 14. Fallback Removal Criteria

admins/{uid} fallback can be removed only when all are true:
1. All active admin accounts have valid claims for assigned roles.
2. No rbac_conflict_detected events for 7 consecutive days.
3. No fallback_auth_used events for 7 consecutive days.
4. Staging verification passes with fallback disabled.
5. Operational runbook for fallback disable/rollback is accepted.

Cutover policy:
- disable fallback behind controlled config flag.
- monitor for 24 hours.
- if auth regressions appear, rollback fallback flag immediately.

## 15. Phase Gate and Done Criteria

AWC-P0 is done only if all items are accepted:
1. Tech choice rule signed.
2. RBAC source-of-truth rule signed.
3. claims vs fallback conflict rule signed.
4. Policy Matrix baseline rows complete and approved.
5. Sensitive command envelope and replay/conflict rules approved.
6. expected_state contract complete for all sensitive commands.
7. Dual-approval matrix and state machine approved.
8. Config governance lifecycle approved.
9. Export governance approved.
10. Read-model freshness/health contract approved.
11. Deployment strategy approved.
12. Fallback removal criteria approved.
13. No contradictory governance rule remains in admin_web_console_execution_plan.md.
14. Phase 1 start is explicitly authorized by owner/ops reviewer.

## 16. Explicit Out of Scope for AWC-P0-01

- UI implementation
- backend implementation
- schema migrations
- deployment execution

This step is governance lock extraction only.
