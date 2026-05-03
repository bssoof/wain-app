# Admin Review Affordances (AWC-QA-012)

## 1. Goal and Scope
The goal of this design document is to standardize and unify the visual and interaction affordances across all review and approval surfaces within the Admin Web Console. Currently, various domain operations (e.g., top-up approvals, reversals, content reviews) implement custom confirmation dialogs, leading to inconsistent user experiences and duplicated logic for handling loading states, errors, and step-up auth handoffs.

**In-Scope:**
- Generalizing the AWC-QA-007 top-up dialog pattern as the master reference.
- Implementing a shared React component (`ReviewAffordanceDialog`) for pre-action summaries, in-flight states, error/retry patterns, and post-action confirmations.
- Standardizing the integration of Step-Up authentication for high-privilege actions.

**Out-of-Scope:**
- Migrating existing dialogs in Phase 1 (migration will be done incrementally per surface in Phase 2).
- Redesigning the core logic of the domain callable functions.

## 2. Current State

| Review Flow | File Path | Dialog Pattern | Gaps |
|-------------|-----------|----------------|------|
| Finance Top-Up | `components/admin/top-up-confirmation-dialog.tsx` | Comprehensive (Reference) | None (Serves as the AWC-QA-007 reference model) |
| Content Review | `components/admin/review-queue/` (Various) | Ad-hoc modals | Inconsistent loading/error states, missing explicit step-up handoff |
| Reversals | `components/admin/reversal-approval/*` | Basic confirmation | Lacks robust retry mechanisms and detailed pre-action summary |

## 3. Target Affordances
To ensure a consistent and trusted administrative experience, the unified review affordance must guarantee the following states:
- **Pre-action Review Block:** A clear, read-only summary of the action about to be taken (e.g., Amount, Target User, Entity ID).
- **In-flight State:** Disabled primary buttons with a visual indicator (spinner) and clear messaging (e.g., "Processing...", "Verifying token...") to prevent double-submissions.
- **Error/Retry State:** Explicit error messaging via inline alerts or toasts. Must allow the admin to retry the action seamlessly.
- **Success Confirmation:** A visual success indicator (green badge/check) often followed by an automatic state refresh and dialog closure.
- **Step-up Integration:** Built-in capability to trigger a Step-Up Auth modal if the action requires elevated privileges (handling 401/403 transparently).

## 4. Shared Component Proposal
**Component Name:** `ReviewAffordanceDialog`

**TypeScript Signature:**
```tsx
export interface ReviewAffordanceDialogProps {
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  // Pre-action summary items
  summaryContent: React.ReactNode;
  // Execution
  onConfirm: () => Promise<void>;
  confirmLabel?: string;
  cancelLabel?: string;
  // State management (if managed externally, otherwise internal)
  isLoading?: boolean;
  loadingMessage?: string;
  error?: string | null;
  // Step-Up specific
  requiresStepUp?: boolean;
}
```

**Internal States:**
- `isSubmitting`: Tracks the inflight API call.
- `internalError`: Captures thrown errors for inline display.
- `isSuccess`: Temporary state to show a success tick before closing.

## 5. Step-up Integration
The shared component will handle high-privilege actions by integrating with the overarching Step-Up Auth provider.
- **Invocation:** When `requiresStepUp` is true, the `onConfirm` handler will first await a valid token from the `StepUpProvider`.
- **Token Passing:** The token is appended to the API request headers (`x-wain-step-up`).
- **Error Mapping:**
  - `401 Unauthenticated`: Prompts a hard login reset or session expiration message.
  - `403 Forbidden` / `422 Unprocessable`: Mapped to a permissions error displayed inline inside the dialog ("Insufficient privileges to perform this action").

## 6. i18n / RTL
- **Arabic Text Expansion:** Ensure action buttons and summary labels have flexible widths to accommodate expanded Arabic translations.
- **BiDi Support:** Status badges and inline icons must flip appropriately (e.g., arrows) based on the `dir="rtl"` attribute of the admin console layout.

## 7. Test Plan
- **Unit Tests (`ReviewAffordanceDialog.test.tsx`):**
  - Renders title, summary content, and action buttons.
  - Button disabled states when `isLoading` is true.
  - Displays `error` message when provided.
- **Integration Tests:**
  - Simulates an `onConfirm` click, asserting that the loading state toggles correctly.
  - Mocks an API failure, asserting that the retry pattern/error message appears.
  - Simulates the step-up handoff process (verifying `requiresStepUp` blocks immediate execution).

## 8. Backward Compatibility
The introduction of `ReviewAffordanceDialog` will not immediately break existing flows. 
- The AWC-QA-007 `top-up-confirmation-dialog` will remain untouched during Phase 1. 
- During Phase 2, `top-up-confirmation-dialog` and other ad-hoc modals will be iteratively swapped to use `ReviewAffordanceDialog` under the hood.

## 9. Rollout
**Phased Rollout:**
- **Phase 1:** Design approval and shared component implementation + testing.
- **Phase 2.1:** Migrate Finance Top-Up (AWC-QA-007).
- **Phase 2.2:** Migrate Content Reviews.
- **Phase 2.3:** Migrate Reversals.

## 10. Open Questions
- Should `ReviewAffordanceDialog` manage the Step-Up UI directly, or should it rely on an injected wrapper/context (`useStepUp()`)? *(Decision: It should rely on `useStepUp()` hook context to keep the component pure.)*
- How long should the "Success" state linger before auto-closing the dialog? *(Proposal: 1500ms).*

## 11. Implementation File List
**New Files:**
- `components/admin/review-affordance/review-affordance-dialog.tsx`
- `components/admin/review-affordance/review-affordance-dialog.test.tsx`

**Modified Files:**
- None in Phase 1 (No existing surfaces migrated).