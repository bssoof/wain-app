# Venues 409 Investigation

Scope: read-only trace of the production smoke `POST /api/admin/command/venues` 409 observed on 2026-05-08 around 16:05 local time. No source code was changed.

## 1. Next.js route

Path: `admin_web_console/app/api/admin/command/venues/route.ts:28-191`

This route handles `POST /api/admin/command/venues`. It parses the command envelope, checks the current admin session, checks venue command authorization, builds the callable proxy transport, executes the typed venue command, and returns the normalized transport status.

Forward target: the route delegates to `createVenueAdaptersTransport`, which maps command actions to Firebase callable names in `admin_web_console/lib/venues/venue-command-adapters.ts:34-40`:

- `create_venue` -> `adminCreateVenue`
- `update_venue_profile` -> `adminUpdateVenueProfile`
- `update_venue_visibility` -> `adminUpdateVenueVisibility`
- `update_venue_operational_status` -> `adminUpdateVenueOperationalStatus`
- `update_venue_subscription_status` -> `adminUpdateVenueSubscriptionStatus`

For the observed 409, production function logs around the smoke window show the failed callable was `adminUpdateVenueVisibility` at `2026-05-08T13:02:48Z`, which is `2026-05-08 16:02:48` in Asia/Hebron local time. Subsequent venue operational/subscription callables in the same window completed successfully.

## 2. Functions callable

Path: `functions/src/admin_venues.ts:629-774`

Function: `adminUpdateVenueVisibility`

Command name: `update_venue_visibility`

The callable normalizes an `update_venue_visibility` command envelope, reads `venues/{venueId}` in a transaction, compares the caller's expected state to the current venue document state, and writes the visibility update only if the expected state still matches.

The callable is exported from `functions/src/index.ts` as `adminUpdateVenueVisibility`.

## 3. 409 throw site

File: `functions/src/admin_venues.ts:679-686`

Code:

```ts
if (
  expectedVisibility !== currentVisibility ||
  expectedOperational !== currentOperationalStatus
) {
  throw new functions.https.HttpsError(
    "failed-precondition",
    "venue_expected_state_conflict",
  );
}
```

Condition: the UI-submitted expected visibility or expected operational status no longer matches the current `venues/{venueId}` document values at transaction time.

There is a second same-message precondition in the same callable at `functions/src/admin_venues.ts:689-693`: if the current operational status is not `active`, the callable also throws `HttpsError("failed-precondition", "venue_expected_state_conflict")`.

HTTP mapping: `failed-precondition` is normalized to `failed_precondition` and mapped to HTTP 409 in `admin_web_console/lib/finance/finance-command-transport.ts:50-56` and `:294-299`. The venues route returns that normalized status at `admin_web_console/app/api/admin/command/venues/route.ts:183-191`.

## 4. Version field

Field: there is no numeric `version`, `etag`, or `updatedAt` compare in this path. The optimistic concurrency token is a domain expected-state object.

Document path: `venues/{venueId}`

Fields compared for `update_venue_visibility`:

- `visibility_status` on the venue document versus `expectedState.current_visibility`
- `operational_status` on the venue document versus `expectedState.operational_status`

UI sends as: `expectedState` in the command request. `admin_web_console/lib/venues/build-venue-command-requests.ts:98-117` builds:

```ts
expectedState: {
  current_visibility: input.currentVisibility,
  operational_status: "active",
}
```

The route adapter forwards that expected state to the callable payload in `admin_web_console/lib/venues/venue-command-adapters.ts:127-133`.

## 5. UI origin

Component: `admin_web_console/components/venues/venue-directory-shell.tsx`

Action: the row-level venue action dropdown's visibility toggle.

User intent: hide a currently visible venue or show a currently hidden venue from `/admin/venues`.

The handler is `handleVisibilityChange` at `admin_web_console/components/venues/venue-directory-shell.tsx:402-414`. It builds the `update_venue_visibility` request using the row's current `item.visibilityStatus` and sends it through `commandContext.runCommand`.

The row action is registered at `admin_web_console/components/venues/venue-directory-shell.tsx:848-860` with labels `إخفاء` / `إظهار`, and the button click is wired at `admin_web_console/components/venues/venue-directory-shell.tsx:922-929`.

The UI displays the conflict chip/message without breaking at `admin_web_console/components/venues/venue-directory-shell.tsx:933-940`.

## 6. Arabic message origin

File: `admin_web_console/lib/admin/admin-localization.ts:421-423`

Message mapping:

```ts
if (normalized.includes("venue_expected_state_conflict")) {
  return "تعذر تنفيذ العملية لأن حالة الجهة تغيّرت قبل اعتماد الطلب.";
}
```

Added in commit: `df779c823` (`feat(admin): add protected operations console`, 2026-04-28). This is pre-existing relative to M-03 and the later security deploys.

Related backend throw site was added in commit `acc0289fd` (`feat(functions): add admin and wallet governance flows`, 2026-04-28).

## 7. Verdict

[x] Working as designed
[ ] Bug
[ ] Regression

Reasoning: the source chain is consistent with an intended optimistic concurrency guard. The UI submitted an `update_venue_visibility` command with expected venue state, the callable compared that expected state to the live `venues/{venueId}` document inside a transaction, threw `HttpsError("failed-precondition", "venue_expected_state_conflict")`, the Next.js proxy mapped that callable code to HTTP 409, and the UI rendered the localized conflict state gracefully.

There is no evidence this was caused by the recent M-01/M-02/M-03 security deploys. The venues callable, expected-state request builder, and Arabic conflict localization all predate those deploys. The only nuance is that the same conflict message is also used when the venue is no longer operationally `active`, so the observed user-facing message can mean either a real row state drift or a visibility action attempted after the venue became non-active.
