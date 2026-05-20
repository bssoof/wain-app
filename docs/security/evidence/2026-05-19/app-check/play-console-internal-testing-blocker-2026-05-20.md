# Play Console Internal Testing Blocker

Date: 2026-05-20
Project: `wain-d2e28`
Release scope: Android production candidate only

## Purpose

This evidence records why the preferred Play Integrity validation path is currently blocked.

The preferred validation path is:

1. Upload the signed Android App Bundle to Google Play Internal Testing.
2. Install the app from Google Play on a physical test device.
3. Perform login and Storage upload from that Play-distributed build.
4. Verify Firebase App Check metrics move to verified traffic before enabling enforcement.

## Prepared Artifact

The Android App Bundle was built locally:

```text
build/app/outputs/bundle/release/app-release.aab
```

SHA256:

```text
E77D537F43756E1FE35D3DFE8BE79C2DF2038F5E244D1C83E32DFE43694FC0D8
```

Build command:

```powershell
flutter build appbundle --release
```

## Current Blocker

Owner-provided Play Console evidence shows the developer account is not fully ready for publishing/testing. The console asks the owner to complete developer account setup, including:

- Google identity verification already submitted and awaiting Google processing.
- Contact phone number verification still required.

Until the Play developer account setup is complete, Internal Testing upload and Play-distributed App Check validation cannot proceed.

## Security Decision

Do not enable App Check enforcement for Storage, Firestore, or Authentication while this blocker remains open.

Reason:

- Direct `adb install` testing of the release APK produced invalid Storage App Check traffic.
- The installed APK signing certificate matches a Firebase Android app fingerprint, so the remaining validation gap is the Play-distributed build path.
- Enforcing before validating the Play-distributed build could block legitimate users.

## Required Follow-Up

When Google Play developer account setup is complete:

1. Upload `app-release.aab` to Internal Testing.
2. Add the test device Gmail account to the internal tester list.
3. Install from the Google Play opt-in link, not through `adb install`.
4. Repeat login and image upload.
5. Capture App Check metrics for Storage, Firestore, and Authentication.
6. Proceed toward enforcement only if new production-client traffic is verified or residual unverified traffic is accepted under policy.

## Current Verdict

Status: Blocked on external account verification.
Release impact: App Check product-level enforcement remains a release blocker or accepted-risk item.
