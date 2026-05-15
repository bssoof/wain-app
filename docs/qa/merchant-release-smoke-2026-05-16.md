# Merchant Release Smoke - 2026-05-16

## Scope

Final QA smoke for the merchant sign-in path after patch set `qa-final-2026-05-15-p1`.

## Build Under Test

- Source commit: `7a84f814`
- Git describe before tagging: `qa-final-2026-05-15-p1-9-g7a84f814`
- APK: `build/app/outputs/flutter-apk/wain-qa-7a84f814-release.apk`
- APK size: `98,456,277` bytes
- Firebase project namespace in emulator: `wain-d2e28`
- Android target: `emulator-5554`

## Emulator Wiring

Release APK launched with emulator dart defines:

```powershell
--dart-define=WAIN_USE_FIREBASE_EMULATORS=true
--dart-define=WAIN_FIREBASE_EMULATOR_HOST=10.0.2.2
```

Observed bootstrap log:

```text
[INFO][bootstrap] Firebase emulators enabled at 10.0.2.2 (firestore:8080, auth:9099, functions:5001, storage:9199).
```

## Smoke Path

1. Launch release APK on `emulator-5554`.
2. Complete onboarding path to the map.
3. Open `الإعدادات`.
4. Tap `تسجيل الدخول`.
5. Switch to email mode via `استخدم البريد الإلكتروني`.
6. Sign in with QA merchant account:
   - Email: `merchant.qa.01@wain.test`
   - Venue: `venue_qa_01`
7. Submit with IME enter.

## Result

`PASS_MERCHANT_DASHBOARD`

Evidence:

- Auth emulator `lastLoginAt` changed after submit.
- Logcat contained `User signed in with email: merchant.qa.01@wain.test`.
- Final screen was merchant dashboard, not consumer landing or guest profile.
- Final screenshot: `.tmp/wain-final-final.png`

Visible dashboard signals:

- `لوحة التاجر`
- `مطعم QA الأول`
- `رصيد وين`
- `إدارة العروض`
- `المنيو`
- `التقييمات`

## Fixes Covered

- Legacy `users/{uid}` profile docs missing optional auth fields no longer break `AppUser.fromDoc`.
- Merchant landing resolver now uses the signed-in UID/current user instead of racing `authStateProvider`.
- Router no longer rebuilds/reset initial route on auth-state updates.
- Generic post-auth redirects such as `/profile`, `/home`, `/results`, and `/stats` yield to merchant dashboard landing when merchant access is available.

## Notes

App Check warnings appeared in emulator logs, but they were non-blocking for Auth and Firestore emulator flows.
