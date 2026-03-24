# Security Test Results

## Metadata
- Date: `2026-03-24`
- Environment: `Firestore emulator only`
- Tester: `Codex`
- App build: `functions build from local workspace`
- Backend version / deployed functions note: `local emulator execution against current workspace, including uncommitted hardening changes`
- Command:
  - `npm run build && firebase --config ../firebase.json emulators:exec --project demo-wain-security --only firestore "node --test --test-concurrency=1 test/emulator/securityCallableFlows.test.js"`

---

## Batch 1 Scope
هذه الجولة غطت أول batch قابل للتنفيذ مباشرة على الـ emulator، وركزت على:
- `A` Merchant entry security
- أجزاء من `B` Merchant authorization boundaries
- أجزاء من `C` Offer claim / redeem abuse

لم تغطِّ هذه الجولة بعد:
- Firestore rules client-side enforcement (`D`)
- Storage rules (`E`)
- replay/App Check interception tests (`F3`)
- concurrency under load (`H`)
- log review (`I`)
- revocation/state-change runtime tests (`J`)
- response leakage / auth token edge cases (`M`, `N`)

---

## Executed Tests

| Test ID | Title | Result | Evidence |
|---|---|---|---|
| A1 | Invalid Invite Code | Pass | emulator node test + Firestore state check |
| A2 | Expired Invite Code | Pass | emulator node test + Firestore state check |
| A3 | Reuse Used Invite Code | Pass | emulator node test + invite/user docs |
| A4 | Account Linked To Different Venue | Pass | emulator node test + user linkage check |
| A5 | App Check Bypass On Invite | Pass | emulator node test + missing `context.app` rejection |
| A6 | Invite Rate Limit | Pass | emulator node test + repeated failures then `resource-exhausted` |
| B2 | Redeem Claim For Another Venue | Pass | emulator node test + claim remained pending |
| B3 | Promote Story Of Another Venue | Pass | emulator node test + story unchanged |
| C1b | Guest Claim Without deviceId | Pass | emulator node test |
| C1c | Guest Reuse On Same Device | Pass | emulator node test after successful redeem |
| C2 | Validate Token Replay | Pass | emulator node test + claim stayed pending |
| C3 | Redeem Same Token Twice | Pass | emulator node test + `redeemed_count = 1` |
| C3b | Redeem Expired Token | Pass | emulator node test + claim stayed pending |
| C7 | Tampering On createClaimToken | Pass | emulator node test + no claim created |
| C8 | Tampering On redeemToken | Pass | emulator node test + invalid bill amounts rejected |
| C10 | Offer Deactivation During Active Claim | Pass | emulator node test + validate/redeem blocked |

---

## Summary
- Total executed in Batch 1: `16`
- Total pass: `16`
- Total fail: `0`
- Total blocked: `0`
- Highest severity open issue found in this batch: `None`

---

## Notes
1. `C9` لم يُنفذ بعد.
- هذا السيناريو يحتاج قرارًا واضحًا: هل QR عندنا bearer token مقبول منتجيًا، أم يجب ربطه بهوية صاحب claim؟

2. `C1d` لم يُنفذ بعد.
- واضح نظريًا من التطبيق أن `deviceId` محلي ويمكن تغييره عبر `Clear App Data`.
- لكنه لم يُثبت بعد بجولة تنفيذ فعلية ضمن هذه الدفعة.

3. `B1` لم يُنفذ بعد.
- يحتاج client/rules testing وليس admin-sdk emulator flow فقط.

4. `A5` و`C8` و`C10` أعطت نتائج جيدة على hardening الحالي.
- هذا مهم لأنه يثبت أن:
  - App Check gate شغال داخل الـ callable
  - `billAmount` validation الحالي يعمل
  - offer deactivation قبل redeem يُحترم

---

## Recommended Next Batch
1. `D` Firestore rules tests
2. `E` Storage rules tests
3. `H` Concurrency / replay under load
4. `M` / `N` callable response leakage + auth/session edge cases

---

## Batch 2 Scope
هذه الجولة غطت Firestore rules مباشرة عبر `@firebase/rules-unit-testing` على الـ emulator.

- Command:
  - `firebase --config ../firebase.json emulators:exec --project demo-wain-security-rules --only firestore "node --test --test-concurrency=1 test/rules/firestoreSecurityRules.test.js"`

## Batch 2 Results

| Test ID | Title | Result | Evidence |
|---|---|---|---|
| B1 | Merchant Reads Only Own Merchant Doc | Pass | rules unit test + denied read |
| D1 | User Profile Escalation | Pass | rules unit test + denied update |
| D2 | Direct Merchant Invite Read | Pass | rules unit test + denied read |
| D3 | Offer Claims Access Rules | Pass | rules unit test + denied read |
| D3b | Offer Claims Query / List Enumeration | Pass | rules unit test + denied unscoped query |
| D4 | Venue Write Boundary | Pass | rules unit test + denied update |
| D6 | Offer Stats Tampering | Pass | rules unit test + denied server-field update |
| D5 | navigation_clicks Spam Boundary | Needs decision | rules unit test confirmed unauthenticated create is currently allowed when `user_id == null` |

## Batch 2 Summary
- Total executed in Batch 2: `8`
- Pass: `7`
- Needs decision: `1`
- Fail: `0`

## Batch 2 Notes
1. `D5` ليس regression.
- القاعدة الحالية تسمح بهذا السلوك فعلًا.
- إذا كان غير مرغوب قبل pilot أوسع، يجب تشديد rule أو إضافة rate limiting أو كليهما.

2. قواعد `users`, `merchants`, `merchant_invites`, `offer_claims`, `venues`, `offers` أظهرت hardening جيدًا في السيناريوهات التي اختبرناها.

---

## Batch 3 Scope
هذه الجولة غطت `E` Storage rules مباشرة عبر `@firebase/rules-unit-testing` مع تشغيل:
- `FirestoreEmulator`
- `StorageEmulator`

داخل نفس العملية لضمان أن قواعد التخزين التي تعتمد على Firestore ownership تعمل فعليًا.

- Command:
  - `node --test --test-concurrency=1 test/rules/storageSecurityRules.test.js`

## Batch 3 Results

| Test ID | Title | Result | Evidence |
|---|---|---|---|
| E1 | Upload Photo To Another Venue | Pass | storage rules test + denied upload |
| E2 | Upload Story Media To Another Venue | Pass | storage rules test + denied upload |
| E3 | File Type And Size Boundaries | Pass | storage rules test + denied invalid content |
| E3b | MIME Spoof With Renamed Extension | Pass | storage rules test + rejected `text/plain` upload with image filename |
| E4 | Delete Another Venue File | Pass | storage rules test + denied delete |
| E5 | Overwrite Existing Known Filename | Pass | storage rules test + denied overwrite |
| E6 | Update Existing File Boundary | Pass | storage rules test + denied metadata update |
| E7 | Nested Path Spoof / Path Traversal Style Attempt | Pass | storage rules test + spoofed object path rejected with `storage/unauthorized` |

## Batch 3 Summary
- Total executed in Batch 3: `8`
- Pass: `8`
- Needs decision: `0`
- Fail: `0`

## Batch 3 Notes
1. `E7` أعطى نتيجة أقوى من المتوقع.
- المحاولة ذات الـ nested path segments لم تُقبل أصلًا.
- هذا يعني أنه لا يوجد tenant escape في هذا المسار ضمن القواعد الحالية.

2. تشغيل `E` احتاج emulator wiring خاصًا داخل نفس العملية.
- السبب أن `storage.rules` عندنا تعتمد على Firestore reads.
- لذلك شغّلنا Firestore وStorage programmatically داخل الاختبار نفسه بدل الاعتماد على emulator خارجي جزئي.

---

## npm audit — Accepted Risk

Packages: `firebase-admin@11` → `@google-cloud/firestore@6.8`
          → `google-gax@3.6` → `protobufjs@7.2.4`
          `firebase-admin` → `@google-cloud/storage@6.12` → `fast-xml-parser@4.5.5`

Severity: `Critical` (dependency chain, not direct exposure)

Justification:
- No user-controlled XML or protobuf input in current callable surface
- Vulnerabilities are in nested dependencies, not callable logic itself

Action: Upgrade `firebase-admin` to `v13` in dedicated maintenance window
        before any public pilot or production scaling

Status: `Accepted risk — documented 2026-03-24`

## npm audit Notes
1. Commands executed:
- `npm audit --omit=dev`
- `npm audit fix --omit=dev`
- `npm audit --omit=dev`

2. Safe fix reduced the remaining production vulnerabilities from `12` to `9`.

3. Remaining breakdown after safe fix:
- `critical`: `4`
- `high`: `1`
- `moderate`: `1`
- `low`: `3`

4. The remaining critical path is still tied to `firebase-admin@11.11.1` and cannot be closed without a major upgrade path.

---

## Batch 4 Scope
هذه الجولة غطت `J` Revocation / State Change عبر:
- callable emulator tests
- storage rules tests

## Batch 4 Results

| Test ID | Title | Result | Evidence |
|---|---|---|---|
| J1 | Full revocation blocks redeem/promote/backfill | Pass | callable emulator test + denied actions after clearing both merchant and user linkage |
| J1-storage | Full revocation blocks storage upload | Pass | storage rules test + denied upload after clearing both linkage docs |
| J1b | Partial revocation gap reproduced | Pass | callable emulator test documented that deleting only `merchants/{uid}` is insufficient; gap is now closed operationally by `revoke_merchant_link.js` |
| J1b-storage | Partial revocation storage gap reproduced | Pass | storage rules test documented that deleting only `merchants/{uid}` is insufficient; gap is now closed operationally by `revoke_merchant_link.js` |
| J2 | Inactive venue blocks validate and redeem | Pass | callable emulator test after patch + `validateToken` returned `venue_inactive` and `redeemToken` failed with `failed-precondition` |
| J2b | Inactive venue blocks story promotion | Pass | callable emulator test after patch + `promoteStory` failed with `failed-precondition` `venue_inactive` |
| J3 | In-flight revocation blocks redeem after preview | Pass | callable emulator test + `validateToken` succeeded before revocation, `redeemToken` denied after merchant doc removal |

## Batch 4 Summary
- Total executed in Batch 4: `7`
- Pass: `7`
- Needs decision: `0`
- Fail: `0`

## Batch 4 Notes
1. Full revocation is effective only when both linkage sources are cleared:
- `merchants/{uid}.venue_id`
- `users/{uid}.merchant_venue_id`

2. Current partial revocation behavior was reproduced and is operationally risky if done manually.
- If an admin deletes only `merchants/{uid}`, storage writes can still succeed.
- `backfillMerchantAnalytics` can also recreate the merchant profile from the remaining user link.
- Mitigation added:
  - `functions/scripts/revoke_merchant_link.js`
  - validated by `functions/test/emulator/revokeMerchantLinkScript.test.js`
  - this is now the supported revocation path

3. `venue.is_active` is now enforced in:
- `validateToken`
- `redeemToken`
- `promoteStory`

4. أثناء الإصلاح ظهر regression صغير في `promoteStory`:
- ترتيب checks كان يعيد `venue_inactive` قبل `permission-denied` عند محاولة التاجر على story ليست له
- تم تصحيحه بإرجاع ownership check إلى الأولوية الأعلى، ثم إعادة تشغيل batch كاملة

---

## Batch 5 Scope
هذه الجولة أضافت artifact تشغيليًا لإغلاق `J1b`:
- admin script revocation
- emulator validation against the self-heal path

- Command:
  - `npm run build && firebase --config ../firebase.json emulators:exec --project demo-wain-revoke-script --only firestore "node --test --test-concurrency=1 test/emulator/revokeMerchantLinkScript.test.js"`

## Batch 5 Results

| Test ID | Title | Result | Evidence |
|---|---|---|---|
| J1b-script | revokeMerchantLink atomically clears user link and blocks self-heal | Pass | emulator test + no merchant re-created + `backfillMerchantAnalytics` denied |

## Batch 5 Summary
- Total executed in Batch 5: `1`
- Pass: `1`
- Needs decision: `0`
- Fail: `0`

## Batch 5 Notes
1. The script reads `merchant_venue_id` before deletion and logs the captured `venueId`.
2. The script updates `users/{uid}` only if the user doc already exists, so it does not create a new user document during revocation.
3. Manual partial console deletion remains unsafe and unsupported.

---

## Running Totals
- Total executed so far: `40`
- Pass: `40`
- Needs decision: `1`
- Fail: `0`

## Current Open Items
- `D5 navigation_clicks`
  - current status: `Needs decision`
  - reason: unauthenticated create is still allowed when `user_id == null`
