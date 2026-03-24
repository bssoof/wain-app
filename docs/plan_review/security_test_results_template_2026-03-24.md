# Security Test Results Template

## Metadata
- Date:
- Environment: `emulator / staging / production-safe`
- Tester:
- App build:
- Backend version / deployed functions note:

---

## Result Legend
- `Pass`
- `Fail`
- `Needs decision`
- `Incomplete verification`
- `Blocked`

---

## Execution Table

| Test ID | Title | Severity | Owner | Execution Mode | Verification Method | Evidence | Result | Bug Classification | Notes | Cleanup Status |
|---|---|---|---|---|---|---|---|---|---|---|
| A1 | Invalid Invite Code | Critical | Backend + Rules | Manual + Callable script | UI + function log + users/merchants before/after |  |  |  |  |  |
| A2 | Expired Invite Code | Critical | Backend + Rules | Manual + Callable script | UI + function log + users/merchants before/after |  |  |  |  |  |
| A3 | Reuse Used Invite Code | Critical | Backend + Rules | Manual + Callable script | UI + function log + invite/user docs before/after |  |  |  |  |  |
| A4 | Account Linked To Different Venue | Critical | Backend + Rules | Manual + Callable script | UI + function log + user linkage before/after |  |  |  |  |  |
| A5 | App Check Bypass On Invite | Critical | Backend + Rules | Callable script | response + no writes + function log |  |  |  |  |  |
| A6 | Invite Rate Limit | Critical | Backend + Rules | Callable script | repeated responses + no writes + logs |  |  |  |  |  |
| B1 | Merchant Reads Only Own Merchant Doc | Critical | Backend + Rules + Storage | Rules test | denied read + unchanged state |  |  |  |  |  |
| B2 | Redeem Claim For Another Venue | Critical | Backend + Rules + Storage | Manual + Callable script | response + claim unchanged + logs |  |  |  |  |  |
| B3 | Promote Story Of Another Venue | Critical | Backend + Rules + Storage | Callable script | response + story unchanged + logs |  |  |  |  |  |
| B4 | Backfill Analytics Boundary | Critical | Backend + Rules + Storage | Callable script | response + only venue A changed |  |  |  |  |  |
| C1 | Claim Token Creation Without Auth | Critical | Backend + Mobile | Manual + Callable script | response + no unauthorized bypass |  |  |  |  |  |
| C1b | Guest Claim Without deviceId | Critical | Backend + Mobile | Callable script | invalid-argument + no claim created |  |  |  |  |  |
| C1c | Guest Reuse On Same Device | Critical | Backend + Mobile | Manual + Callable script | failed-precondition + no new redeemable claim |  |  |  |  |  |
| C1d | Guest Device Reset / Clear App Data | Critical | Backend + Mobile | Manual | second claim outcome + risk classification |  |  |  |  |  |
| C2 | Validate Token Replay | Critical | Backend + Mobile | Callable script | repeated validate + no side effect |  |  |  |  |  |
| C3 | Redeem Same Token Twice | Critical | Backend + Mobile | Manual + Callable script | first success, second fail, counters unchanged on second |  |  |  |  |  |
| C3b | Redeem Expired Token | Critical | Backend + Mobile | Callable script | failed-precondition + claim/counters unchanged |  |  |  |  |  |
| C4 | Percent Offer With Bill Amount | Critical | Backend + Mobile | Manual | claim/offer docs + UI stats before/after |  |  |  |  |  |
| C5 | Percent Offer Without Bill Amount | Critical | Backend + Mobile | Manual | claim doc + UI stats before/after |  |  |  |  |  |
| C6 | Cross-User Claim Leakage | Critical | Backend + Mobile | Manual + Rules test | B cannot read A claim/stats |  |  |  |  |  |
| C7 | Tampering On createClaimToken | Critical | Backend + Mobile | Callable script | venue_mismatch + no claim created |  |  |  |  |  |
| C8 | Tampering On redeemToken | Critical | Backend + Mobile | Callable script | invalid input rejected + no side effects |  |  |  |  |  |
| C9 | Cross-User Redeem With Borrowed QR | Critical | Backend + Mobile | Manual | bearer-token behavior documented and classified |  |  |  |  |  |
| C10 | Offer Deactivation During Active Claim | Critical | Backend + Mobile | Manual + Callable script | validate/redeem blocked after offer deactivation |  |  |  |  |  |
| D1 | User Profile Escalation | High | Rules | Rules unit test | denied update + unchanged doc |  |  |  |  |  |
| D2 | Direct Merchant Invite Read | High | Rules | Rules unit test | denied read |  |  |  |  |  |
| D3 | Offer Claims Access Rules | High | Rules | Rules unit test | denied read |  |  |  |  |  |
| D3b | Offer Claims Query/List Enumeration | High | Rules | Rules unit test | denied or scoped query only |  |  |  |  |  |
| D4 | Venue Write Boundary | High | Rules | Rules unit test | denied update |  |  |  |  |  |
| D5 | navigation_clicks Spam Boundary | High | Rules | Emulator script | actual create behavior + decision outcome |  |  |  |  |  |
| D6 | Offer Stats Tampering | High | Rules | Rules unit test | denied server fields write |  |  |  |  |  |
| E1 | Upload Photo To Another Venue | High | Storage + Rules | Manual + Emulator script | unauthorized + no object created |  |  |  |  |  |
| E2 | Upload Story Media To Another Venue | High | Storage + Rules | Manual + Emulator script | unauthorized + no object created |  |  |  |  |  |
| E3 | File Type And Size Boundaries | High | Storage + Rules | Manual | rejected file + no object created |  |  |  |  |  |
| E3b | MIME Spoof With Renamed Extension | High | Storage + Rules | Manual | contentType enforcement + no unsafe object created |  |  |  |  |  |
| E4 | Delete Another Venue File | High | Storage + Rules | Manual + Emulator script | unauthorized + object remains |  |  |  |  |  |
| E5 | Overwrite Existing Known Filename | High | Storage + Rules | Manual + Emulator script | unauthorized + object unchanged |  |  |  |  |  |
| E6 | Update Existing File Boundary | High | Storage + Rules | Manual + Emulator script | unauthorized + object unchanged |  |  |  |  |  |
| E7 | Nested Path Spoof / Path Traversal Style Attempt | High | Storage + Rules | Manual + Emulator script | no tenant path bypass |  |  |  |  |  |
| F1 | Valid App Instance | High | Backend + Infra | Manual | flows succeed + no unintended errors |  |  |  |  |  |
| F2 | Invalid/Missing App Check | High | Backend + Infra | Callable script | app check fail + no writes |  |  |  |  |  |
| F3 | Replay Of Captured Legitimate Request | High | Backend + Infra | Callable script | replay blocked or side effects prevented |  |  |  |  |  |
| G1 | Input Validation Matrix | High | Backend | Callable script + Manual | invalid input rejected + no writes |  |  |  |  |  |
| H1 | Redeem Same Token Concurrently | Critical | Backend | Callable script | one success only + counters single-applied |  |  |  |  |  |
| H2 | Validate And Redeem Simultaneously | Critical | Backend | Callable script | no corruption + final state correct |  |  |  |  |  |
| H3 | Repeated createClaimToken Under Retry | Critical | Backend | Callable script | no duplicate pending claims |  |  |  |  |  |
| H4 | Repeat Same Callable After Retry | Critical | Backend | Callable script | no extra side effects |  |  |  |  |  |
| I1 | Audit Logging Coverage | Medium | Backend + Infra | Log review | minimum fields present |  |  |  |  |  |
| J1 | Revoked Merchant Permissions | High | Rules + Backend | Manual + Emulator script | denied actions after unlink |  |  |  |  |  |
| J2 | Inactive Venue State Change | High | Rules + Backend | Manual + Emulator script | blocked actions where policy requires |  |  |  |  |  |
| J3 | In-Flight Scanner Revocation | High | Rules + Backend | Manual + Callable script | final redeem denied after unlink |  |  |  |  |  |
| M1 | Function Response Leakage | High | Backend | Callable script | no sensitive leakage in errors |  |  |  |  |  |
| N1 | Expired/Deleted Auth Token Behavior | High | Backend | Callable script | unauthenticated/permission-denied + no writes |  |  |  |  |  |

---

## Summary
- Total Pass:
- Total Fail:
- Total Needs decision:
- Total Incomplete verification:
- Highest severity open issue:
- Recommended action:
