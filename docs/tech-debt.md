# Tech Debt Backlog

## P3 - Audit event enrichment (step-up)
- **Status**: Resolved in B2 rollout-safety work.
- **File**: `admin_web_console/lib/auth/step-up-token.ts`
- **Event**: `step_up_previous_key_verified`
- **Issue**: Event lacks full investigation context for key-rotation analysis.
- **Acceptance**: Add `tokenIssuedAt`, `tokenAge_ms`, `currentKeyVersion`, and `previousKeyVersion`.
- **Estimated**: 2 hours
- **Related**: AWC-QA-017
- **Created**: 2026-04-30
- **Resolved**: 2026-04-30
