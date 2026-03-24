# Firebase Admin / Functions Upgrade Assessment

## Current Baseline
- `functions/package.json`
  - `firebase-admin`: `^11.8.0`
  - `firebase-functions`: `^4.3.1`
  - `typescript`: `^4.9.0`
  - `node` engine: `22`

## What The Codebase Uses Today
### `firebase-admin`
- `functions/src/index.ts`
  - `admin.initializeApp()`
  - `admin.firestore()`
  - `admin.firestore.Timestamp`
  - `admin.firestore.FieldValue`
- `functions/src/menu_import.ts`
  - `admin.initializeApp()` context
  - `admin.app().options.credential?.getAccessToken()`
- `functions/src/busy_times/job.ts`
  - `admin.firestore()`

### `firebase-functions`
- 1st gen style imports:
  - `import * as functions from "firebase-functions";`
- Trigger styles in use:
  - `functions.https.onCall(...)`
  - `functions.pubsub.schedule(...).onRun(...)`
  - `functions.runWith(...)`
  - Firestore 1st gen trigger style in `menu_import.ts`

### Important Non-Usage Findings
- No `functions.config()` usage found.
- No removed Admin Messaging APIs found:
  - `sendAll()`
  - `sendMulticast()`
  - `sendToDevice()`
  - `sendToDeviceGroup()`
  - `sendToTopic()`
  - `sendToCondition()`
- No `admin.instanceId()` usage found.
- No `dynamicLinkDomain` usage found.

## Official Breaking Changes That Matter
### `firebase-admin` v12
- Firebase Admin Node.js SDK `v12.0.0` upgraded:
  - `@google-cloud/firestore` to `v7`
  - `@google-cloud/storage` to `v7`
- This is explicitly called out as a breaking change in the official release notes.

### `firebase-admin` v13
- Firebase Admin Node.js SDK `v13.0.0`:
  - migrated credentials handling to `google-auth-library`
  - dropped Node.js 14 and 16 support
  - upgraded TypeScript
  - removed deprecated Cloud Messaging APIs
- Local impact:
  - Node runtime is already safe because the project uses Node `22`
  - Messaging removals do not hit current code
  - the only suspicious local surface is:
    - `functions/src/menu_import.ts`
    - direct use of `admin.app().options.credential?.getAccessToken()`
  - this should be reviewed first during the code migration because credential internals are the exact area changed in `v13`

### `firebase-functions` v6 / v7
- Official release notes state:
  - `v6.0.0` defaults Cloud Functions to 2nd gen
  - `v7.0.0`:
    - drops Node 16
    - requires TypeScript `v5`
    - removes `functions.config()`
- Local impact:
  - `functions.config()` removal does not hit this project
  - Node runtime is already safe because the project uses Node `22`
  - TypeScript is not yet safe because the project is still on `4.9`
  - the codebase is still written in 1st gen style

## Migration Risk Assessment
### Low Risk
- `firebase-admin` Node runtime support
- removed Admin Messaging APIs
- `functions.config()` removal

### Medium Risk
- Firestore/Storage client upgrades that come transitively with `firebase-admin` `v12+`
- TypeScript `v5` stricter checking

### Highest Local Risk
- continuing to import 1st gen APIs from top-level `firebase-functions`
- direct credential access in:
  - `functions/src/menu_import.ts`

## Recommended Migration Order
### Phase 1: Preparation Without Behavior Change
1. Change `firebase-functions` imports to explicit 1st gen imports:
   - `firebase-functions/v1`
2. Keep trigger behavior 1st gen for now.
3. Review and harden `getGoogleAccessToken()` in:
   - `functions/src/menu_import.ts`
4. Upgrade TypeScript to `v5.x`
5. Run:
   - `npm run build`
   - emulator security suite
   - targeted smoke tests

### Phase 2: Dependency Upgrade
1. Upgrade:
   - `firebase-admin` to `v13`
   - `firebase-functions` to `v7`
2. Rebuild and fix resulting type/runtime issues.
3. Re-run:
   - `npm audit`
   - `npm run build`
   - emulator security suite
   - targeted deploy

### Phase 3: Optional Future Work
1. Evaluate selective migration from 1st gen to 2nd gen where justified.
2. Do not combine that migration with the dependency upgrade PR.

## Recommendation
Do not start by changing package versions blindly.

The safest next coding step is:
1. explicit `firebase-functions/v1` imports
2. TypeScript `v5`
3. review credential access in `menu_import.ts`
4. only then bump `firebase-admin` and `firebase-functions`

## Sources
- Firebase Admin Node.js release notes:
  - https://firebase.google.com/support/release-notes/admin/node
- Firebase overall release notes:
  - https://firebase.google.com/support/releases
- Cloud Functions 1st gen docs showing explicit `firebase-functions/v1` imports:
  - https://firebase.google.com/docs/functions/1st-gen/get-started-1st
  - https://firebase.google.com/docs/functions/1st-gen/config-env-1st
