# App Check Registration Evidence

Date: 2026-05-20
Source: Owner-provided Firebase Console screenshot.
Project: `wain-d2e28`

## Observed Apps

| App | Package / App ID | Provider | Status |
| --- | --- | --- | --- |
| `wain-android` | `com.wain.wain_app` | Play Integrity | Registered |
| `wain-ios` | `com.wain.wainApp` | Not configured | Register button visible |
| `wain-web` | Web App | reCAPTCHA | Registered |

## Assessment

This evidence proves App Check registration for the Android and Web apps, but it does not prove product-level enforcement for Firestore, Cloud Storage, Cloud Functions, or other Firebase resources.

The unregistered iOS app is not a blocker only if iOS is formally out of scope for the current Android production release. If iOS is in release scope, it must be registered and tested before release.

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

Status: Partial evidence.
Release blocking: Yes until product-level App Check enforcement state is recorded for sensitive products/functions, or a formal accepted exception exists.
