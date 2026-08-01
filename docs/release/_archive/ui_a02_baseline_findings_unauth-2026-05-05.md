# UI-A02 Baseline Findings

Date: 2026-05-05  
Base URL: `http://127.0.0.1:3010`  
Capture command: `npm run capture:ui-a02`  
Screenshot directory: `docs/release/ui_a02_baseline_screenshots_2026-05-05`

## Capture Summary

- Total planned routes: 15
- Successful screenshots: 15
- Failed screenshots: 0
- Redirected to sign-in: 13
- Admin session JSON provided: false
- Capture note: most protected routes rendered the sign-in screen because the run did not include an authenticated admin session. Visual findings below are prepared as a route-by-route checklist, but protected-route UI judgment should be completed after a second capture with a valid admin session.

## 1. Admin Index

- Key: `admin_index`
- Planned path: `/admin`
- Final path: `/admin/sign-in?next=%2Fadmin`
- HTTP: 200
- Screenshot: [01_admin_index.png](ui_a02_baseline_screenshots_2026-05-05/01_admin_index.png)
- Capture note: redirected to sign-in.

### Visual Issues P0

- [ ] Confirm the intended authenticated redirect from `/admin` to `/admin/dashboard` after running capture with an admin session.
- [ ] Check for any blocking layout break on the final authenticated landing page.

### Visual Issues P1

- [ ] Verify that the landing page header, sidebar, and dashboard hierarchy are clear after authentication.
- [ ] Check that route transition from `/admin` does not show a blank or jarring intermediate state.

### Visual Issues P2

- [ ] Review polish details: spacing, card radius, hover states, and page entrance motion.

### Action Items

- [ ] Re-run this route with `WAIN_ADMIN_SESSION_JSON` or equivalent local admin session.
- [ ] Compare the authenticated screenshot against the previous baseline.

## 2. Sign In

- Key: `sign_in`
- Planned path: `/admin/sign-in`
- Final path: `/admin/sign-in`
- HTTP: 200
- Screenshot: [02_sign_in.png](ui_a02_baseline_screenshots_2026-05-05/02_sign_in.png)
- Capture note: public route captured directly.

### Visual Issues P0

- [ ] Check that the sign-in form is usable at 360px width with no clipped fields or buttons.
- [ ] Confirm error and loading states are visible and readable.

### Visual Issues P1

- [ ] Improve visual hierarchy between title, helper text, fields, and primary action if needed.
- [ ] Ensure focus states are clear for keyboard users.

### Visual Issues P2

- [ ] Review background treatment, card density, and motion so the page feels polished without looking like a marketing hero.

### Action Items

- [ ] Add or update screenshot notes for desktop and mobile.
- [ ] Include sign-in loading/error state screenshots in a later pass if supported by the test setup.

## 3. Access Denied

- Key: `access_denied`
- Planned path: `/admin/access-denied?route=dashboard`
- Final path: `/admin/access-denied?route=dashboard`
- HTTP: 200
- Screenshot: [03_access_denied.png](ui_a02_baseline_screenshots_2026-05-05/03_access_denied.png)
- Capture note: public error route captured directly.

### Visual Issues P0

- [ ] Confirm the denied message clearly explains what happened without exposing sensitive internals.
- [ ] Confirm the recovery action is visible and keyboard accessible.

### Visual Issues P1

- [ ] Check that the page communicates the requested route context clearly.
- [ ] Verify Arabic wording is direct and not overly technical.

### Visual Issues P2

- [ ] Review iconography, spacing, and secondary help copy.

### Action Items

- [ ] Add an authenticated denied-state capture for a role that lacks a specific permission.
- [ ] Compare visual treatment with other error and unavailable states.

## 4. Dashboard

- Key: `dashboard`
- Planned path: `/admin/dashboard`
- Final path: `/admin/sign-in?next=%2Fadmin`
- HTTP: 200
- Screenshot: [04_dashboard.png](ui_a02_baseline_screenshots_2026-05-05/04_dashboard.png)
- Capture note: redirected to sign-in.

### Visual Issues P0

- [ ] Re-capture authenticated dashboard before judging dashboard UI.
- [ ] Check that top operational signals are visible above the fold.

### Visual Issues P1

- [ ] Review KPI hierarchy, stale/unavailable states, and quick action visibility.
- [ ] Check that cards do not require long reading to identify the next action.

### Visual Issues P2

- [ ] Add or tune light page entrance and card animation.
- [ ] Review fine spacing between summary strip, KPI grid, and footer metadata.

### Action Items

- [ ] Re-run with admin session.
- [ ] Fill concrete findings from the authenticated screenshot.

## 5. Top-ups

- Key: `topups`
- Planned path: `/admin/topups`
- Final path: `/admin/sign-in?next=%2Fadmin`
- HTTP: 200
- Screenshot: [05_topups.png](ui_a02_baseline_screenshots_2026-05-05/05_topups.png)
- Capture note: redirected to sign-in.

### Visual Issues P0

- [ ] Re-capture authenticated top-up queue before judging finance workflow UI.
- [ ] Check approve/reject controls for clarity, disabled states, and confirmation safety.

### Visual Issues P1

- [ ] Review table density, sticky header need, action column stability, and export action placement.
- [ ] Check high-value or older request emphasis if visible data supports it.

### Visual Issues P2

- [ ] Review command button icon usage, pending animation, and toast feedback.

### Action Items

- [ ] Re-run with finance-capable admin session.
- [ ] Add action-state screenshots for pending, success, and blocked outcomes if practical.

## 6. Wallet Audit

- Key: `wallet_audit`
- Planned path: `/admin/wallet-audit`
- Final path: `/admin/sign-in?next=%2Fadmin`
- HTTP: 200
- Screenshot: [06_wallet_audit.png](ui_a02_baseline_screenshots_2026-05-05/06_wallet_audit.png)
- Capture note: redirected to sign-in.

### Visual Issues P0

- [ ] Re-capture authenticated wallet audit before judging table readability.
- [ ] Check that audit rows preserve critical traceability fields without crowding.

### Visual Issues P1

- [ ] Review filters for operation type, date, actor, and amount.
- [ ] Check whether a compact timeline view would reduce scan effort.

### Visual Issues P2

- [ ] Review badge tones, timestamp formatting, and row hover feedback.

### Action Items

- [ ] Re-run with admin session.
- [ ] Fill route-specific findings from authenticated screenshot.

## 7. Reversals

- Key: `reversals`
- Planned path: `/admin/reversals`
- Final path: `/admin/sign-in?next=%2Fadmin`
- HTTP: 200
- Screenshot: [07_reversals.png](ui_a02_baseline_screenshots_2026-05-05/07_reversals.png)
- Capture note: redirected to sign-in.

### Visual Issues P0

- [ ] Re-capture authenticated reversal page before judging command form safety.
- [ ] Check that destructive or corrective actions require clear confirmation.

### Visual Issues P1

- [ ] Review whether the form should become a short stepper: operation, reason, confirm.
- [ ] Check inline validation and disabled/pending states.

### Visual Issues P2

- [ ] Review field grouping, helper text, and success/error motion.

### Action Items

- [ ] Re-run with reversal-capable admin session.
- [ ] Capture form validation and blocked-command states later.

## 8. Readiness

- Key: `readiness`
- Planned path: `/admin/readiness`
- Final path: `/admin/sign-in?next=%2Fadmin`
- HTTP: 200
- Screenshot: [08_readiness.png](ui_a02_baseline_screenshots_2026-05-05/08_readiness.png)
- Capture note: redirected to sign-in.

### Visual Issues P0

- [ ] Re-capture authenticated readiness page before judging health-state clarity.
- [ ] Check that failing checks are prioritized above warnings and healthy checks.

### Visual Issues P1

- [ ] Review health summary cards, status badges, and recommended next action.
- [ ] Verify stale/unavailable data copy is easy to understand.

### Visual Issues P2

- [ ] Review iconography and subtle motion for health status changes.

### Action Items

- [ ] Re-run with admin session.
- [ ] Add concrete health-state findings after authenticated capture.

## 9. Venues Directory

- Key: `venues_directory`
- Planned path: `/admin/venues`
- Final path: `/admin/sign-in?next=%2Fadmin`
- HTTP: 200
- Screenshot: [09_venues_directory.png](ui_a02_baseline_screenshots_2026-05-05/09_venues_directory.png)
- Capture note: redirected to sign-in.

### Visual Issues P0

- [ ] Re-capture authenticated venues directory before judging venue-management UI.
- [ ] Check create/edit/action affordances for role-based visibility and safety.

### Visual Issues P1

- [ ] Review summary cards, active filter chips, table density, and action menu clarity.
- [ ] Check city/category filters on narrow screens.

### Visual Issues P2

- [ ] Review status legend, row hover polish, and icon usage.

### Action Items

- [ ] Re-run with venue-management admin session.
- [ ] Add findings for create/edit dialogs in a later focused capture.

## 10. Venue Workspace

- Key: `venues_workspace`
- Planned path: `(resolver:fallback)/admin/venues`
- Final path: `/admin/sign-in?next=%2Fadmin`
- HTTP: 200
- Screenshot: [10_venues_workspace.png](ui_a02_baseline_screenshots_2026-05-05/10_venues_workspace.png)
- Capture note: redirected to sign-in; workspace resolver fell back because no venue link was discoverable.

### Visual Issues P0

- [ ] Re-capture with admin session and a resolvable venue workspace route.
- [ ] Check that workspace header clearly shows venue identity, status, and primary next action.

### Visual Issues P1

- [ ] Review tabs, badges, media preview, and section hierarchy.
- [ ] Check empty or unavailable venue data states.

### Visual Issues P2

- [ ] Review tab transition, spacing, and image preview polish.

### Action Items

- [ ] Seed or select a known venue ID for stable workspace capture.
- [ ] Re-run after authenticated `/admin/venues` can expose a workspace link.

## 11. Media

- Key: `media`
- Planned path: `/admin/media`
- Final path: `/admin/sign-in?next=%2Fadmin`
- HTTP: 200
- Screenshot: [11_media.png](ui_a02_baseline_screenshots_2026-05-05/11_media.png)
- Capture note: redirected to sign-in.

### Visual Issues P0

- [ ] Re-capture authenticated media page before judging media workflow UI.
- [ ] Check that risky media actions are visually separated from normal preview actions.

### Visual Issues P1

- [ ] Review preview grid or preview column needs.
- [ ] Check filter toolbar, action sidebar, and modal preview sizing.

### Visual Issues P2

- [ ] Review preview modal animation, image background, and icon labels.

### Action Items

- [ ] Re-run with media-capable admin session.
- [ ] Add focused screenshots for preview and replace dialogs later.

## 12. Content Offers

- Key: `content_offers`
- Planned path: `/admin/content/offers`
- Final path: `/admin/sign-in?next=%2Fadmin`
- HTTP: 200
- Screenshot: [12_content_offers.png](ui_a02_baseline_screenshots_2026-05-05/12_content_offers.png)
- Capture note: redirected to sign-in.

### Visual Issues P0

- [ ] Re-capture authenticated offers queue before judging moderation decisions.
- [ ] Check that approve/reject/pause actions require clear reason and confirmation where needed.

### Visual Issues P1

- [ ] Review queue layout, primary decision placement, and filter chips.
- [ ] Check if offer details are scannable without opening too many nested controls.

### Visual Issues P2

- [ ] Review decision feedback animation and toast copy.

### Action Items

- [ ] Re-run with content moderation admin session.
- [ ] Capture at least one populated queue state if fixtures allow it.

## 13. Content Stories

- Key: `content_stories`
- Planned path: `/admin/content/stories`
- Final path: `/admin/sign-in?next=%2Fadmin`
- HTTP: 200
- Screenshot: [13_content_stories.png](ui_a02_baseline_screenshots_2026-05-05/13_content_stories.png)
- Capture note: redirected to sign-in.

### Visual Issues P0

- [ ] Re-capture authenticated stories queue before judging moderation UI.
- [ ] Check that media/story preview is accessible and clear.

### Visual Issues P1

- [ ] Review status badges, action hierarchy, and reason field placement.
- [ ] Check whether story-specific preview needs a richer visual treatment than table-only rows.

### Visual Issues P2

- [ ] Review hover, preview modal, and decision feedback polish.

### Action Items

- [ ] Re-run with content moderation admin session.
- [ ] Capture preview and action states later.

## 14. Content Reviews

- Key: `content_reviews`
- Planned path: `/admin/content/reviews`
- Final path: `/admin/sign-in?next=%2Fadmin`
- HTTP: 200
- Screenshot: [14_content_reviews.png](ui_a02_baseline_screenshots_2026-05-05/14_content_reviews.png)
- Capture note: redirected to sign-in.

### Visual Issues P0

- [ ] Re-capture authenticated reviews page before judging review moderation flow.
- [ ] Check that publish/hide/escalate actions are clear and not visually ambiguous.

### Visual Issues P1

- [ ] Review review text readability, action cell density, and reason input flow.
- [ ] Check App Check or blocked-command messaging if visible.

### Visual Issues P2

- [ ] Review badges, row feedback, and toast animation.

### Action Items

- [ ] Re-run with review moderation admin session.
- [ ] Add populated moderation queue findings after authenticated capture.

## 15. Config

- Key: `config`
- Planned path: `/admin/config`
- Final path: `/admin/sign-in?next=%2Fadmin`
- HTTP: 200
- Screenshot: [15_config.png](ui_a02_baseline_screenshots_2026-05-05/15_config.png)
- Capture note: redirected to sign-in.

### Visual Issues P0

- [ ] Re-capture authenticated config governance page before judging publish/rollback safety.
- [ ] Check that publish and rollback actions have strong confirmation and clear risk copy.

### Visual Issues P1

- [ ] Review workflow stepper, draft/live comparison, and pricing field grouping.
- [ ] Check command runtime messages and disabled states.

### Visual Issues P2

- [ ] Review step animation, command card spacing, and history table density.

### Action Items

- [ ] Re-run with config-governance admin session.
- [ ] Capture draft, reviewed, published, unavailable, and blocked states when fixtures allow it.

## Next Capture Recommendation

- Provide an authenticated admin session to the capture script so protected pages render their actual UI.
- Re-run `npm run capture:ui-a02`.
- Copy the authenticated screenshots into a new dated directory.
- Fill the unchecked route-specific findings above with concrete visual issues from the authenticated screenshots.
