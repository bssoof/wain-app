# App Check Registration Evidence

Date: 2026-05-20
Source: Owner-provided Firebase Console screenshot.
Project: `wain-d2e28`
Release scope: Android production candidate only. iOS is explicitly out of scope for this release and must be re-opened before any iOS production candidate.

## Observed Apps

| App | Package / App ID | Provider | Status |
| --- | --- | --- | --- |
| `wain-android` | `com.wain.wain_app` | Play Integrity | Registered |
| `wain-ios` | `com.wain.wainApp` | Not configured | Register button visible |
| `wain-web` | Web App | reCAPTCHA | Registered |

## Assessment

This evidence proves App Check registration for the Android and Web apps, but it does not prove product-level enforcement for Firestore, Cloud Storage, Cloud Functions, or other Firebase resources.

Owner confirmed on 2026-05-20 that the current production release scope is Android only. The unregistered iOS app is therefore not a blocker for this Android release. If iOS enters release scope later, `wain-ios` must be registered with DeviceCheck or App Attest, validated on a real iOS build, and added to the App Check enforcement evidence before release.

## Required Follow-Up Evidence

Capture product-level App Check enforcement state for:

- Cloud Functions, especially sensitive financial callable functions.
- Cloud Firestore.
- Cloud Storage.
- Any other Firebase product used by privileged or financial flows.

Required fields:

```text
Product:
Enforcement state: Enforced / Monitoring / Unenforced
Scope:
Evidence path or screenshot:
Owner:
Release decision:
```

## Current Verdict

Status: Scoped pass for Android app registration; product-level enforcement evidence remains incomplete.
Release blocking: Yes until product-level App Check enforcement state is recorded for sensitive products/functions, or a formal accepted exception exists.
