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

The shared component will not rely on external UI libraries (like Tailwind or Shadcn) to maintain consistency with the existing Admin Web Console architecture. Instead, it will use Semantic HTML and BEM-style CSS classes, mirroring components like `AdminBanner`.

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

## 6. i18n / RTL & Accessibility (a11y)

### Internationalization (i18n)
- **Arabic Text Expansion:** Ensure action buttons and summary labels have flexible widths to accommodate expanded Arabic translations.
- **BiDi Support:** Status badges and inline icons must flip appropriately (e.g., arrows) based on the `dir="rtl"` attribute of the admin console layout.

### Accessibility (a11y)
Since we are using raw HTML to match the project's styling pattern, strict accessibility standards must be enforced:
- **Roles and States:** The main wrapper must have `role="dialog"` and `aria-modal="true"`. It must also link to its title using `aria-labelledby`.
- **Keyboard Navigation:** The dialog must close when the user presses the `Escape` key (unless an inflight API call is happening).
- **Focus Management:** When opened, focus should trap within the modal, and the primary focus should land on the safest action (e.g., the "Cancel" button) to prevent accidental confirmations.
- **Live Regions:** Error and success states should use `aria-live="polite"` or `aria-live="assertive"` so screen readers announce them immediately.

## 7. Test Plan
To ensure the robustness of the shared component, a comprehensive test suite of 8+ tests will be implemented.

- **Rendering and State (Unit):**
  - Renders the dialog structure, title, summary content, and buttons.
  - Hides the component entirely when `isOpen` is false.
- **Interaction & In-flight (Integration):**
  - Disables buttons and shows specific loading text ("Processing..." or "Verifying...") immediately upon clicking confirm.
  - Prevents double submissions (ignores subsequent clicks while inflight).
- **Error & Retry Handling:**
  - Catches rejected promises, displays the specific error text inline, and re-enables buttons for a retry.
- **Success Flow:**
  - Triggers success state upon promise resolution, displays success UI, and auto-closes after 1500ms.
- **Accessibility (a11y) Tests:**
  - Verifies presence of `role="dialog"` and `aria-modal="true"`.
  - Asserts that pressing `Escape` triggers `onOpenChange(false)` only when *not* inflight.

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