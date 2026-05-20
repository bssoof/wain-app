# App Check API Enforcement Evidence

Date: 2026-05-20
Source: Owner-provided Firebase Console App Check APIs table.
Project: `wain-d2e28`
Metric window shown in console: Last 7 days, May 13-May 21.

## Firebase APIs

| API | Verified requests | Unverified requests | Status |
| --- | ---: | ---: | --- |
| Cloud Storage | 60% | 40% | Monitoring |
| Cloud Firestore | 54% | 46% | Monitoring |
| Firebase Authentication | 9% | 91% | Monitoring |
| Realtime Database | Not in use | Not in use | Not enabled for App Check because product is not in use |
| Firebase AI Logic | Not in use | Not in use | Not enabled for App Check because product is not in use |
| SQL Connect | Not in use | Not in use | Not enabled for App Check because product is not in use |
| Cloud Functions | Not reported in table | Not reported in table | Enforcement not proven; console directs to Functions enforcement documentation |

## Detailed Request Metrics

Owner-provided Firebase Console detail screenshots show the following breakdowns for the same App Check metric window:

| API | Verified | Unverified: outdated client | Unverified: unknown origin | Unverified: invalid | Status |
| --- | ---: | ---: | ---: | ---: | --- |
| Cloud Storage | 60%, 6 / 10 total | 20%, 2 / 10 total | 0%, 0 / 10 total | 20%, 2 / 10 total | Monitoring |
| Cloud Firestore | 54%, 2.3K / 4.4K total | 7%, 297 / 4.4K total | 0%, 0 / 4.4K total | 40%, 1.7K / 4.4K total | Monitoring |
| Firebase Authentication | 9%, 6 / 70 total | 23%, 16 / 70 total | 51%, 36 / 70 total | 17%, 12 / 70 total | Monitoring |
| Google Identity for iOS | 0 / 0 total | 0 / 0 total | 0 / 0 total | 0 / 0 total | Unenforced; 0 / 1 OAuth clients enforced |

Interpretation:

- Cloud Storage has a small sample size, but both outdated-client and invalid request categories exist.
- Cloud Firestore has materially significant invalid requests, with approximately 1.7K invalid App Check requests in the window.
- Firebase Authentication has the highest risk for immediate enforcement because most requests are unverified and the largest category is unknown origin.
- Google Identity for iOS has no observed traffic; iOS remains out of scope for this Android release, but OAuth client enforcement must be revisited before any iOS release.

## Android APK Signing Check

After installing the current locally built Android release APK on a physical Samsung SM-A736B device and performing login plus image upload, owner-provided Storage metrics moved from 6 / 10 verified and 2 / 10 invalid to 6 / 13 verified and 5 / 13 invalid. This suggests the new Storage traffic was still counted as invalid App Check traffic.

The installed APK signing certificate was checked locally:

```powershell
apksigner verify --print-certs build\app\outputs\flutter-apk\app-release.apk
```

Observed certificate digests:

```text
SHA-256: ed673a2a3337786d31b2d6c7a23e71838fdbc430151e665853892d4a3df7cc8f
SHA-1: c3231a4a3a73b661f944fef544261ba019cdb9e1
```

These match fingerprints visible in the owner-provided Firebase Android app settings screenshot. Therefore, the current invalid Storage traffic is not explained by a missing Firebase Android SHA fingerprint for the sideloaded release APK.

Next likely cause to validate: the APK was installed directly with `adb install`, not through a Google Play internal/closed testing track. Retest App Check with a Play-distributed build before enabling enforcement.

## Google APIs

| API | Status |
| --- | --- |
| Google Identity for iOS | Unenforced |
| Maps JavaScript API | Not in use / no metrics shown |
| Places API (New) | Not in use / no metrics shown |

## Custom Backends

| Backend | Status |
| --- | --- |
| Custom backend | Not configured in App Check evidence |

## Assessment

App Check is currently in Monitoring mode for the observed Firebase APIs that are receiving traffic. Monitoring mode collects metrics but does not block unverified requests.

The current unverified request rates are high enough that enabling enforcement immediately would likely break legitimate traffic unless the source of unverified requests is understood and remediated first:

- Cloud Storage: 40% unverified.
- Cloud Firestore: 46% unverified.
- Firebase Authentication: 91% unverified.

Cloud Functions product-level enforcement state is not proven by this table and must be verified separately. Code-level callable enforcement is complete for the reviewed `functions/src` callable exports.

Recommended enforcement decision for the current evidence: do not click `Enforce` for Storage, Firestore, or Authentication yet. First isolate whether unverified traffic comes from old app builds, debug/emulator clients, web clients missing App Check configuration, server/admin traffic, or invalid/abusive clients.

## Release Impact

Status: Not release-ready for App Check enforcement.
Release blocking: Yes for sensitive financial Firebase resources and callables until either:

1. App Check enforcement is enabled and verified after reducing unverified legitimate traffic, or
2. a formal accepted risk documents why Monitoring mode is temporarily allowed with compensating controls.

## Required Next Steps

1. Identify why Android/Web clients are generating unverified requests.
2. Verify production Android release initializes App Check with Play Integrity and uses the registered package/signing certificate.
3. Verify Web App Check reCAPTCHA configuration and domain allow-list.
4. Separate emulator, debug, admin, CI, and server-side traffic from real production client metrics.
5. Capture Cloud Functions callable enforcement state separately.
6. Move sensitive products/functions from Monitoring to Enforced only after controlled QA/staging validation.
7. For Authentication specifically, investigate unknown-origin traffic before any enforcement attempt.
8. For Firestore specifically, investigate invalid App Check traffic volume before any enforcement attempt.
9. Upload the same signed Android build to Google Play Internal Testing, install it from Play on the test device, repeat login/upload, and compare the App Check metrics again.
